#!/usr/bin/env bash
# Behaviour tests for everything in this repo that runs as code: hooks/boundary-guard.sh,
# hooks/check-update.sh, install.sh. The same script CI runs on Linux, macOS and Windows.
#
#   bash tests/hooks.test.sh
#   BASH_BIN=/bin/bash bash tests/hooks.test.sh     # run the scripts under test with macOS bash 3.2
#   REQUIRE_PARSER=1 …                              # fail (not skip) if the guard finds no JSON parser
#
# Fixtures are built the way a user's machine is, not the way the code expects: a real bare git
# remote with annotated tags, a clone sitting at the install path, a foreign directory in the way.

# assert() takes its condition as a single-quoted string and evals it later, so variables set before
# the call look unused and unexpanded to shellcheck — both on purpose here.
# shellcheck disable=SC2016,SC2034

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASH_BIN="${BASH_BIN:-bash}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
export GIT_CONFIG_NOSYSTEM=1

pass=0; fail=0
assert() {  # description ; condition (string, eval'd)
  if eval "$2"; then pass=$((pass+1)); echo "  ok   $1"; else fail=$((fail+1)); echo "  FAIL $1"; fi
}

echo "under test: $("$BASH_BIN" -c 'echo bash $BASH_VERSION')"

# ------------------------------------------------------------------ boundary-guard
echo "boundary-guard:"
guard_out=$("$BASH_BIN" "$ROOT/hooks/boundary-guard.sh" --self-test 2>&1); guard_rc=$?
echo "$guard_out" | grep -E 'FAIL|passed:|parser:' | sed 's/^/    /'
assert "self-test passes" '[ "$guard_rc" -eq 0 ]'
if [ "${REQUIRE_PARSER:-0}" = 1 ]; then
  assert "no case skipped (a JSON parser was found)" 'echo "$guard_out" | grep -q "skipped: 0"'
fi
# The plugin opt-in gate, through the real stdin path (needs a parser to see a block at all).
if ! echo "$guard_out" | grep -q "parser: none"; then
  viol='{"tool_name":"Write","cwd":"/r","tool_input":{"file_path":"/r/src/modules/orders/orders.service.ts","content":"import { db } from \"../../shared/db\""}}'
  g() { printf '%s' "$viol" | env "$@" "$BASH_BIN" "$ROOT/hooks/boundary-guard.sh" >/dev/null 2>&1; echo $?; }
  rc_settings=$(g -u CLAUDE_PLUGIN_ROOT)
  rc_plugin_off=$(g -u CLAUDE_PLUGIN_OPTION_BOUNDARY_GUARD CLAUDE_PLUGIN_ROOT=/p)
  rc_plugin_false=$(g CLAUDE_PLUGIN_ROOT=/p CLAUDE_PLUGIN_OPTION_BOUNDARY_GUARD=false)
  rc_plugin_on=$(g CLAUDE_PLUGIN_ROOT=/p CLAUDE_PLUGIN_OPTION_BOUNDARY_GUARD=true)
  assert "settings.json install (no plugin root) → blocks"       '[ "$rc_settings" = 2 ]'
  assert "plugin, boundary_guard unset → allows (opt-in)"        '[ "$rc_plugin_off" = 0 ]'
  assert "plugin, boundary_guard=false → allows"                 '[ "$rc_plugin_false" = 0 ]'
  assert "plugin, boundary_guard=true → blocks"                  '[ "$rc_plugin_on" = 2 ]'
fi
# hooks/hooks.json (the plugin's registration) must point at a script that exists.
hook_cmd=$(sed -n 's/.*"command": *"\(.*\)".*/\1/p' "$ROOT/hooks/hooks.json" | sed 's/\\"//g')
hook_path=$(printf '%s' "$hook_cmd" | sed "s#\${CLAUDE_PLUGIN_ROOT}#$ROOT#; s#^bash ##")
assert "hooks/hooks.json runs an existing script ($(basename "$hook_path"))" '[ -f "$hook_path" ]'

# ------------------------------------------------------------------ check-update
echo "check-update:"
cu() { (cd "$WORK/skill" && SHIPRIGHT_UPDATE_TIMEOUT=5 "$BASH_BIN" hooks/check-update.sh 2>&1); }
(
  cd "$WORK" || exit 1
  git init -q --bare -b main origin.git
  git init -q -b main skill && cd skill || exit 1
  git remote add origin ../origin.git
  mkdir hooks && cp "$ROOT/hooks/check-update.sh" hooks/
  printf 'name: shipright\nversion: 1.27.0\n' > SKILL.md
  git add -A && git commit -qm a
  git tag -a v1.24.1 -m x && git tag -a v1.27.0 -m x
  git push -q -u origin main --tags
) >/dev/null 2>&1
out=$(cu); assert "up to date, annotated tags present → silent" '[ -z "$out" ]'

(cd "$WORK" && git clone -q origin.git other && cd other && git commit -q --allow-empty -m b && git push -q origin main) >/dev/null 2>&1
out=$(cu); assert "untagged commit upstream → 'new commits'" 'echo "$out" | grep -q "new commits upstream"'

(cd "$WORK/skill" && git pull -q) >/dev/null 2>&1
out=$(cu); assert "after pull → silent" '[ -z "$out" ]'

(cd "$WORK/other" && git pull -q && printf 'name: shipright\nversion: 1.28.0\n' > SKILL.md \
  && git commit -qam rel && git tag -a v1.28.0 -m x && git tag -a v1.9.9 -m x \
  && git push -q origin main --tags) >/dev/null 2>&1
out=$(cu); assert "newer release → names v1.28.0 (numeric sort beats v1.9.9)" 'echo "$out" | grep -q "v1.28.0 is available"'

(cd "$WORK/skill" && git pull -q && git commit -q --allow-empty -m local) >/dev/null 2>&1
out=$(cu); assert "local ahead of remote → silent" '[ -z "$out" ]'

(cd "$WORK/skill" && git remote set-url origin "$WORK/does-not-exist.git")
out=$(cu); rc=$?; assert "missing remote → silent, exit 0" '[ -z "$out" ] && [ "$rc" -eq 0 ]'

(cd "$WORK" && mkdir plain && cp -R skill/hooks plain/ && cp skill/SKILL.md plain/)
out=$(cd "$WORK/plain" && "$BASH_BIN" hooks/check-update.sh 2>&1); rc=$?
assert "not a git install → silent, exit 0" '[ -z "$out" ] && [ "$rc" -eq 0 ]'

# ------------------------------------------------------------------ install.sh
echo "install.sh:"
inst() { HOME="$1" "$BASH_BIN" "$2" "${@:3}" >/dev/null 2>&1; }
H1="$WORK/h1"; mkdir -p "$H1"
inst "$H1" "$ROOT/install.sh"; rc=$?
T="$H1/.claude/skills/shipright"
assert "fresh personal install" '[ "$rc" -eq 0 ] && [ -f "$T/SKILL.md" ] && [ -d "$T/references" ] && [ -d "$T/hooks" ]'
assert "copies only runtime files" '[ ! -e "$T/CHANGELOG.md" ] && [ ! -e "$T/.git" ] && [ ! -e "$T/tests" ]'
inst "$H1" "$ROOT/install.sh"; rc=$?
assert "reinstall replaces cleanly, no staging dir left" '[ "$rc" -eq 0 ] && [ "$(ls -A "$H1/.claude/skills")" = shipright ]'

H2="$WORK/h2"; mkdir -p "$H2/.claude/skills"
for f in SKILL.md references hooks install.sh; do mkdir -p "$H2/.claude/skills/shipright"; cp -R "$ROOT/$f" "$H2/.claude/skills/shipright/"; done
inst "$H2" "$H2/.claude/skills/shipright/install.sh"; rc=$?
assert "run inside the install itself → no-op, nothing deleted" '[ "$rc" -eq 0 ] && [ -f "$H2/.claude/skills/shipright/SKILL.md" ]'

H3="$WORK/h3"; mkdir -p "$H3/.claude/skills/shipright"; echo precious > "$H3/.claude/skills/shipright/notes.txt"
inst "$H3" "$ROOT/install.sh"; rc=$?
assert "foreign target → refused, contents kept" '[ "$rc" -ne 0 ] && [ "$(cat "$H3/.claude/skills/shipright/notes.txt")" = precious ]'

mkdir -p "$WORK/proj"
(cd "$WORK/proj" && HOME="$WORK/h4" "$BASH_BIN" "$ROOT/install.sh" --project >/dev/null 2>&1); rc=$?
assert "--project installs into ./.claude/skills" '[ "$rc" -eq 0 ] && [ -f "$WORK/proj/.claude/skills/shipright/SKILL.md" ]'

inst "$H1" "$ROOT/install.sh" --bogus; rc=$?
assert "unknown option → non-zero" '[ "$rc" -ne 0 ]'

echo "  ---"; echo "  passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
