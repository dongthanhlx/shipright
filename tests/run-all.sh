#!/usr/bin/env bash
# Everything CI checks, in one local command:  bash tests/run-all.sh
# (CI runs the same scripts; shellcheck is skipped here if it isn't installed, never in CI.)

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
rc=0

echo "== content";     bash tests/check-content.sh || rc=1
echo "== scripts";     bash tests/hooks.test.sh    || rc=1
echo "== shellcheck"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -S warning hooks/*.sh install.sh tests/*.sh && echo "✓ shellcheck clean" || rc=1
else
  echo "- shellcheck not installed — skipped locally (CI runs it)"
fi

echo; [ "$rc" -eq 0 ] && echo "ALL GREEN" || echo "FAILED"
exit "$rc"
