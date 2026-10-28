#!/usr/bin/env bash
# Shipright boundary guard — PreToolUse hook (matcher: "Edit|Write")
#
# Turns shipright's boundary rules from advice into enforcement: it inspects the code
# Claude is about to write and BLOCKS the two highest-confidence boundary violations
# BEFORE they land — exactly the grep checks shipright already documents:
#   Boundary 2: a service-layer file importing the shared DB module
#   Boundary 1: a deep import into another module's internals (bypassing its index)
#
# Design principles (match references/judgment.md — know when NOT to fire):
#   • Conservative: only blocks near-zero-false-positive cases. Project-specific rules
#     stay in CLAUDE.md; this guard enforces the universal two.
#   • Fails OPEN: any internal error (no working jq/python, parse failure, unknown shape)
#     → allow the edit. A guard must never brick editing.
#   • Opt-in + escapable: disable with SHIPRIGHT_GUARD=off; bypass one line with a
#     `shipright-ignore` comment on the offending import (name the exception, like a senior).
#   • Portable: bash 3.2 (macOS) through 5.x, Linux / macOS / Windows (Git Bash) — Windows
#     paths are normalized, and a python is used only if it actually RUNS (the Microsoft Store
#     `python3` alias exists on PATH and fails, which used to turn the guard into a silent no-op).
#
# Install (settings.json):
#   { "hooks": { "PreToolUse": [ { "matcher": "Edit|Write",
#       "hooks": [ { "type": "command",
#         "command": "~/.claude/skills/shipright/hooks/boundary-guard.sh" } ] } ] } }
#
# Verify without Claude Code:  hooks/boundary-guard.sh --self-test
# (unit cases on inspect() + end-to-end cases through the real stdin-JSON path)

set -uo pipefail

MODULE_DIRS='modules|domains|features|services'
INTERNAL_SUFFIX='\.(service|repository|controller|store|gateway|usecase)([^[:alnum:]_]|$)'

# ----------------------------------------------------------------------------- helpers
# Pick a JSON parser once: jq, else the first python that actually executes. Empty → fail open.
PARSER=""
pick_parser() {
  if command -v jq >/dev/null 2>&1; then PARSER=jq; return 0; fi
  local c
  for c in python3 python; do
    if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import json' >/dev/null 2>&1; then
      PARSER="$c"; return 0
    fi
  done
  return 1
}

# Extract a string field from $INPUT. Arg: a jq-style path, e.g. .tool_input.file_path
json_field() {
  case "$PARSER" in
    "") return 0 ;;
    jq) printf '%s' "$INPUT" | jq -r "$1 // empty" 2>/dev/null ;;
    *)  printf '%s' "$INPUT" | SR_PATH="$1" "$PARSER" -c '
import sys, json, os
path = os.environ["SR_PATH"].lstrip(".").split(".")
try:
    v = json.load(sys.stdin)
    for p in path: v = v.get(p, "") if isinstance(v, dict) else ""
    sys.stdout.write(v if isinstance(v, str) else "")
except Exception:
    pass' 2>/dev/null ;;
  esac
  return 0
}

# Collapse . and .. segments of a /-separated path (no filesystem access).
normpath() {
  printf '%s' "$1" | awk -F/ '{
    n = 0; lead = ""
    for (i = 1; i <= NF; i++) {
      if ($i == "" || $i == ".") { if (i == 1 && $i == "") lead = "/"; continue }
      if ($i == "..") { if (n > 0 && s[n] != "..") n--; else s[++n] = ".."; continue }
      s[++n] = $i
    }
    out = lead
    for (i = 1; i <= n; i++) out = out (i > 1 ? "/" : "") s[i]
    print out
  }'
}

# The module a path belongs to: the segment after the FIRST modules-like dir, provided something
# lies inside it. First, not last — a module may contain its own services/ folder. Paths are made
# project-relative first (see run_hook), so a workspace dir named services/ above the repo is gone.
module_of() {
  printf '%s' "$1" | awk -F/ -v dirs="^($MODULE_DIRS)\$" '{
    for (i = 1; i < NF - 1; i++) if ($i ~ dirs && $(i + 1) != "") { print $(i + 1); exit }
  }'
}

capitalize() { printf '%s' "$1" | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }'; }

# Inspect one block of code for violations. Echoes a reason and returns 1 if a violation
# is found, else returns 0. Args: file path (project-relative, / separators), code content.
inspect() {
  local file="$1" code="$2"
  case "$file" in
    *.ts|*.tsx|*.js|*.jsx|*.mts|*.cts|*.py) ;;   # source files only
    *) return 0 ;;
  esac

  local curmod
  curmod=$(module_of "$file")
  [ -z "$curmod" ] && return 0

  # is this a service-layer file? (TS: *.service.* ; Py: *_service.py / service.py)
  local is_service=0
  case "$file" in
    *.service.*|*Service.ts|*Service.js|*_service.py|*/service.py|service.py) is_service=1 ;;
  esac

  local filedir="${file%/*}"
  [ "$filedir" = "$file" ] && filedir="."

  local line trimmed spec target omod
  while IFS= read -r line; do
    # only consider import-ish lines; skip comments and explicit opt-outs
    printf '%s' "$line" | grep -Eq '(^|[^[:alnum:]])(import|require|from)([^[:alnum:]]|$)' || continue
    trimmed=$(printf '%s' "$line" | sed 's/^[[:space:]]*//')
    case "$trimmed" in '//'*|'/*'*|'*'*|'#'*) continue ;; esac
    printf '%s' "$line" | grep -q 'shipright-ignore' && continue

    # --- Boundary 2: service must not import the shared DB module ---
    if [ "$is_service" -eq 1 ] && printf '%s' "$line" | grep -Eq "shared[./](db|database)([^[:alnum:]_]|$)"; then
      echo "Boundary 2 violation — a service must not import the database directly."
      echo "  file: $file"
      echo "  line: $trimmed"
      echo "  fix:  inject a repository interface (I$(capitalize "$curmod")Repository) via the constructor;"
      echo "        the only path to the DB is through a repository. (references/boundaries.md Rule 2a)"
      echo "  bypass (only with a real reason): add a 'shipright-ignore' comment on this line."
      return 1
    fi

    # --- Boundary 1: no deep import into ANOTHER module's internals ---
    # Only internal-file suffixes (.service/.repository/...) count: they exist only inside modules,
    # so shared/ and config/ never trip it. The specifier is resolved before modules are compared:
    # `../orders.service` from orders/http/ is the SAME module, not a sibling.
    spec=$(printf '%s' "$line" | sed -nE "s/.*['\"\`]([^'\"\`]+)['\"\`].*/\1/p")
    [ -z "$spec" ] && continue
    printf '%s' "$spec" | grep -Eq "$INTERNAL_SUFFIX" || continue
    case "$spec" in
      ./*|../*) target=$(normpath "$filedir/$spec") ;;
      *)        target="$spec" ;;     # alias or root-style: @/modules/x/..., src/modules/x/...
    esac
    omod=$(module_of "$target")
    if [ -n "$omod" ] && [ "$omod" != "$curmod" ]; then
      echo "Boundary 1 violation — deep import into another module's internals (module '$omod')."
      echo "  file: $file"
      echo "  line: $trimmed"
      echo "  fix:  import from the module's public API (its index) only — never its .service /"
      echo "        .repository / internal files. Internals can change any time. (boundaries.md Rule 1)"
      echo "  bypass (only with a real reason): add a 'shipright-ignore' comment on this line."
      return 1
    fi
  done <<EOF
$code
EOF
  return 0
}

# The hook proper: reads $INPUT (the PreToolUse JSON). Returns 0 = allow, 2 = block.
run_hook() {
  [ -z "$INPUT" ] && return 0
  [ -z "$PARSER" ] && return 0

  local tool file cwd code lf lc reason
  tool=$(json_field '.tool_name')
  case "$tool" in Edit|Write) ;; *) return 0 ;; esac

  file=$(json_field '.tool_input.file_path' | tr '\\' '/')
  [ -z "$file" ] && return 0

  # Make the path project-relative (case-insensitive prefix match: Windows drive letters vary).
  cwd=$(json_field '.cwd' | tr '\\' '/')
  cwd="${cwd%/}"
  if [ -n "$cwd" ]; then
    lf=$(printf '%s' "$file" | tr '[:upper:]' '[:lower:]')
    lc=$(printf '%s' "$cwd" | tr '[:upper:]' '[:lower:]')
    case "$lf" in "$lc"/*) file="${file:$(( ${#cwd} + 1 ))}" ;; esac
  fi

  # Edit → new_string ; Write → content. Grab whichever exists.
  code=$(json_field '.tool_input.new_string')
  [ -z "$code" ] && code=$(json_field '.tool_input.content')
  [ -z "$code" ] && return 0

  if reason=$(inspect "$file" "$code"); then
    return 0
  fi
  {
    echo "BLOCKED by shipright boundary-guard:"
    echo "$reason"
  } >&2
  return 2   # block; stderr is fed back to Claude to self-correct
}

# ----------------------------------------------------------------------------- self-test
if [ "${1:-}" = "--self-test" ]; then
  pass=0; fail=0; skip=0
  check() {  # desc ; expect(BLOCK|ALLOW) ; file ; code
    local got=ALLOW
    inspect "$3" "$4" >/dev/null 2>&1 || got=BLOCK
    if [ "$got" = "$2" ]; then pass=$((pass+1)); echo "  ok   [$2] $1";
    else fail=$((fail+1)); echo "  FAIL [exp $2 got $got] $1"; fi
  }
  e2e() {    # desc ; expect(BLOCK|ALLOW) ; json — through run_hook, exactly as Claude Code calls it
    if [ -z "$PARSER" ]; then skip=$((skip+1)); echo "  skip [$2] $1 (no working jq/python)"; return; fi
    local got=ALLOW rc=0
    INPUT="$3"; run_hook 2>/dev/null || rc=$?
    [ "$rc" -eq 2 ] && got=BLOCK
    if [ "$got" = "$2" ]; then pass=$((pass+1)); echo "  ok   [$2] e2e: $1";
    else fail=$((fail+1)); echo "  FAIL [exp $2 got $got] e2e: $1"; fi
  }
  pick_parser
  echo "shipright boundary-guard self-test (parser: ${PARSER:-none}, bash ${BASH_VERSION}):"
  check "service imports shared/db"               BLOCK "src/modules/orders/orders.service.ts" "import { db } from '../../shared/db'"
  check "service imports shared/database"          BLOCK "src/modules/orders/orders.service.ts" "import { pool } from '../../shared/database'"
  check "service imports @/shared/db alias"        BLOCK "src/modules/orders/orders.service.ts" "import { db } from '@/shared/db'"
  check "python service imports shared db"         BLOCK "app/modules/orders/orders_service.py" "from shared.db import pool"
  check "repository may import db (not service)"   ALLOW "src/modules/orders/orders.repository.ts" "import { db } from '../../shared/db'"
  check "service with shipright-ignore bypass"     ALLOW "src/modules/orders/orders.service.ts" "import { db } from '../../shared/db' // shipright-ignore: migration shim"
  check "comment line mentioning an import"        ALLOW "src/modules/orders/orders.service.ts" "// we import from the shared/db layer only in repositories"
  check "python comment line"                      ALLOW "app/modules/orders/orders_service.py" "# from shared.db import pool  (old code)"
  check "deep import into other module internals"  BLOCK "src/modules/orders/orders.service.ts" "import { PaymentService } from '../payments/payment.service'"
  check "deep import via modules path"             BLOCK "src/modules/orders/orders.service.ts" "import { X } from 'src/modules/payments/payment.repository'"
  check "deep import via @/ alias"                 BLOCK "src/modules/orders/orders.service.ts" "import { X } from '@/modules/payments/payment.repository'"
  check "deep import from a nested subdir"         BLOCK "src/modules/orders/http/orders.controller.ts" "import { X } from '../../payments/payment.service'"
  check "import other module index is fine"        ALLOW "src/modules/orders/orders.service.ts" "import { IPaymentService } from '../payments'"
  check "import own module internals is fine"      ALLOW "src/modules/orders/orders.service.ts" "import { Money } from './orders.types'"
  check "own module from a nested subdir"          ALLOW "src/modules/orders/http/orders.controller.ts" "import { OrdersService } from '../orders.service'"
  check "own module via ../../modules/<self>"      ALLOW "src/modules/orders/order.service.ts" "import { X } from '../../modules/orders/orders.repository'"
  check "own module, nested services/ dir"         ALLOW "src/modules/orders/services/sub/x.ts" "import { X } from 'src/modules/orders/orders.repository'"
  check "climb into shared/ is not a module"       ALLOW "src/modules/orders/orders.controller.ts" "import { X } from '../../shared/mail.service'"
  check "non-source file ignored"                  ALLOW "src/modules/orders/README.md" "import { db } from '../../shared/db'"
  check "file outside modules ignored"             ALLOW "src/index.ts" "import { db } from './shared/db'"
  e2e "Write, posix path, service→db"              BLOCK '{"tool_name":"Write","cwd":"/repo","tool_input":{"file_path":"/repo/src/modules/orders/orders.service.ts","content":"import { db } from \"../../shared/db\""}}'
  e2e "Edit new_string, service→db"                BLOCK '{"tool_name":"Edit","cwd":"/repo","tool_input":{"file_path":"/repo/src/modules/orders/orders.service.ts","old_string":"x","new_string":"import { db } from \"../../shared/db\""}}'
  e2e "Windows path, service→db"                   BLOCK '{"tool_name":"Write","cwd":"D:\\proj","tool_input":{"file_path":"D:\\proj\\src\\modules\\orders\\orders.service.ts","content":"import { db } from \"../../shared/db\""}}'
  e2e "Windows path, drive-letter case differs"    BLOCK '{"tool_name":"Write","cwd":"d:\\proj","tool_input":{"file_path":"D:\\proj\\src\\modules\\orders\\orders.service.ts","content":"import { X } from \"../payments/payment.service\""}}'
  e2e "Windows path, own module nested subdir"     ALLOW '{"tool_name":"Write","cwd":"D:\\proj","tool_input":{"file_path":"D:\\proj\\src\\modules\\orders\\http\\orders.controller.ts","content":"import { S } from \"../orders.service\""}}'
  e2e "workspace dir named services/ above repo"   ALLOW '{"tool_name":"Write","cwd":"/home/u/services/billing","tool_input":{"file_path":"/home/u/services/billing/src/modules/orders/x.ts","content":"import { X } from \"src/modules/orders/orders.repository\""}}'
  e2e "other tools are ignored"                    ALLOW '{"tool_name":"Bash","tool_input":{"command":"echo import shared/db"}}'
  e2e "malformed JSON fails open"                  ALLOW '{"tool_name":'
  echo "  ---"; echo "  passed: $pass  failed: $fail  skipped: $skip"
  [ "$fail" -eq 0 ] && exit 0 || exit 1
fi

# ----------------------------------------------------------------------------- main
[ "${SHIPRIGHT_GUARD:-on}" = "off" ] && exit 0
INPUT="$(cat 2>/dev/null)"
pick_parser
run_hook
exit $?
