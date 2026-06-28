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
#   • Fails OPEN: any internal error (missing jq/python, parse failure, unknown shape)
#     → allow the edit. A guard must never brick editing.
#   • Opt-in + escapable: disable with SHIPRIGHT_GUARD=off; bypass one line with a
#     `shipright-ignore` comment on the offending import (name the exception, like a senior).
#
# Install (settings.json):
#   { "hooks": { "PreToolUse": [ { "matcher": "Edit|Write",
#       "hooks": [ { "type": "command",
#         "command": "~/.claude/skills/shipright/hooks/boundary-guard.sh" } ] } ] } }
#
# Verify the logic without Claude Code:  hooks/boundary-guard.sh --self-test

set -uo pipefail

# ----------------------------------------------------------------------------- helpers
# Extract a string field from the stdin JSON. Try jq, then python3. Fail open (empty).
json_field() {  # $1 = jq path e.g. .tool_name ; reads $INPUT
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r "$1 // empty" 2>/dev/null
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$INPUT" | SR_PATH="$1" python3 -c '
import sys, json, os
path = os.environ["SR_PATH"].lstrip(".").split(".")
try:
    v = json.load(sys.stdin)
    for p in path: v = v.get(p, "") if isinstance(v, dict) else ""
    sys.stdout.write(v if isinstance(v, str) else "")
except Exception:
    pass' 2>/dev/null
    return 0
  fi
  return 0  # neither available → fail open (empty)
}

# Inspect one block of code for violations. Echoes a reason and returns 1 if a violation
# is found, else returns 0. Args: $1 = file path, $2 = code content.
inspect() {
  local file="$1" code="$2"
  case "$file" in
    *.ts|*.tsx|*.js|*.jsx|*.mts|*.cts|*.py) ;;   # source files only
    *) return 0 ;;
  esac

  # current module = segment right after a modules-like dir; skip if not in one
  local curmod
  curmod=$(printf '%s' "$file" | sed -nE 's#.*/(modules|domains|features|services)/([^/]+)/.*#\2#p')
  [ -z "$curmod" ] && return 0

  # is this a service-layer file? (TS: *.service.* ; Py: *_service.py / service.py)
  local is_service=0
  case "$file" in
    *.service.*|*Service.ts|*Service.js|*_service.py|*/service.py) is_service=1 ;;
  esac

  local line
  while IFS= read -r line; do
    # only consider import-ish lines; skip explicit opt-outs
    printf '%s' "$line" | grep -Eq '(^|[^[:alnum:]])(import|require|from)([^[:alnum:]]|$)' || continue
    printf '%s' "$line" | grep -q 'shipright-ignore' && continue

    # --- Boundary 2: service must not import the shared DB module ---
    if [ "$is_service" -eq 1 ] && printf '%s' "$line" | grep -Eq "shared[./](db|database)([^[:alnum:]_]|$)"; then
      echo "Boundary 2 violation — a service must not import the database directly."
      echo "  file: $file"
      echo "  line: $(printf '%s' "$line" | sed 's/^[[:space:]]*//')"
      echo "  fix:  inject a repository interface (I${curmod^}Repository) via the constructor;"
      echo "        the only path to the DB is through a repository. (references/boundaries.md Rule 2)"
      echo "  bypass (only with a real reason): add a 'shipright-ignore' comment on this line."
      return 1
    fi

    # --- Boundary 1: no deep import into ANOTHER module's internals ---
    # Key on internal-file suffixes (.service/.repository/...) which only exist inside modules —
    # this avoids false positives on shared/ and config/ (which have no such files).
    local internal='\.(service|repository|controller|store|gateway|usecase)\b'
    local hit="" omod=""
    # (a) absolute-style path into another module's internal file
    omod=$(printf '%s' "$line" | sed -nE "s#.*(modules|domains|features|services)/([^/'\"]+)/[^'\"]*\.(service|repository|controller|store|gateway|usecase).*#\2#p")
    if [ -n "$omod" ] && [ "$omod" != "$curmod" ]; then hit="modules/$omod"; fi
    # (b) relative climb-out (../) into a sibling module's internal file
    if [ -z "$hit" ] && printf '%s' "$line" | grep -Eq "\.\./[^'\"]*${internal}"; then hit="a sibling module"; fi
    if [ -n "$hit" ]; then
      echo "Boundary 1 violation — deep import into another module's internals ($hit)."
      echo "  file: $file"
      echo "  line: $(printf '%s' "$line" | sed 's/^[[:space:]]*//')"
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

# ----------------------------------------------------------------------------- self-test
if [ "${1:-}" = "--self-test" ]; then
  pass=0; fail=0
  check() {  # $1 desc ; $2 expect(BLOCK|ALLOW) ; $3 file ; $4 code
    local got=ALLOW
    inspect "$3" "$4" >/dev/null 2>&1 || got=BLOCK
    if [ "$got" = "$2" ]; then pass=$((pass+1)); echo "  ok   [$2] $1";
    else fail=$((fail+1)); echo "  FAIL [exp $2 got $got] $1"; fi
  }
  echo "shipright boundary-guard self-test:"
  check "service imports shared/db"               BLOCK "src/modules/orders/orders.service.ts" "import { db } from '../../shared/db'"
  check "service imports shared/database"          BLOCK "src/modules/orders/orders.service.ts" "import { pool } from '../../shared/database'"
  check "python service imports shared db"         BLOCK "app/modules/orders/orders_service.py" "from shared.db import pool"
  check "repository may import db (not service)"   ALLOW "src/modules/orders/orders.repository.ts" "import { db } from '../../shared/db'"
  check "service with shipright-ignore bypass"     ALLOW "src/modules/orders/orders.service.ts" "import { db } from '../../shared/db' // shipright-ignore: migration shim"
  check "deep import into other module internals"  BLOCK "src/modules/orders/orders.service.ts" "import { PaymentService } from '../payments/payment.service'"
  check "deep import via modules path"             BLOCK "src/modules/orders/orders.service.ts" "import { X } from 'src/modules/payments/payment.repository'"
  check "import other module index is fine"        ALLOW "src/modules/orders/orders.service.ts" "import { IPaymentService } from '../payments'"
  check "import own module internals is fine"      ALLOW "src/modules/orders/orders.service.ts" "import { Money } from './orders.types'"
  check "non-source file ignored"                  ALLOW "src/modules/orders/README.md" "import { db } from '../../shared/db'"
  check "file outside modules ignored"             ALLOW "src/index.ts" "import { db } from './shared/db'"
  echo "  ---"; echo "  passed: $pass  failed: $fail"
  [ "$fail" -eq 0 ] && exit 0 || exit 1
fi

# ----------------------------------------------------------------------------- main
[ "${SHIPRIGHT_GUARD:-on}" = "off" ] && exit 0

INPUT="$(cat 2>/dev/null)"
[ -z "$INPUT" ] && exit 0

TOOL=$(json_field '.tool_name')
case "$TOOL" in Edit|Write) ;; *) exit 0 ;; esac

FILE=$(json_field '.tool_input.file_path')
[ -z "$FILE" ] && exit 0

# Edit → new_string ; Write → content. Grab whichever exists.
CODE=$(json_field '.tool_input.new_string')
[ -z "$CODE" ] && CODE=$(json_field '.tool_input.content')
[ -z "$CODE" ] && exit 0

if REASON=$(inspect "$FILE" "$CODE"); then
  exit 0   # no violation → allow
else
  {
    echo "BLOCKED by shipright boundary-guard:"
    echo "$REASON"
  } >&2
  exit 2   # block; stderr is fed back to Claude to self-correct
fi
