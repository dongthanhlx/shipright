#!/usr/bin/env bash
# Shipright update checker — SessionStart hook (optional)
#
# Says one line when a NEWER shipright release (a vX.Y.Z tag above your SKILL.md version) exists,
# or when the remote default branch has commits your checkout does not contain. Otherwise silent.
#
#   • Never blocks a session: one network call, hard 5s limit (SHIPRIGHT_UPDATE_TIMEOUT; works without coreutils `timeout`),
#     no credential prompts, and `exit 0` on every path.
#   • Never suggests a downgrade: versions compare numerically, peeled `^{}` tag refs are ignored,
#     and "behind" means the remote commit is not in your history — not merely "a different hash".
#   • Only for git installs. A copied or `npx skills` install has no .git → skipped silently.
#
# Install (settings.json):
#   { "hooks": { "SessionStart": [ { "hooks": [ { "type": "command",
#       "command": "~/.claude/skills/shipright/hooks/check-update.sh" } ] } ] } }

TIMEOUT_S="${SHIPRIGHT_UPDATE_TIMEOUT:-5}"

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)"
[ -f "${SKILL_DIR}/SKILL.md" ] || SKILL_DIR="${HOME}/.claude/skills/shipright"
git -C "$SKILL_DIR" rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Run a command with a time limit, its stdout into a file (arg 2). coreutils `timeout` kills the
# whole process group; the fallback (stock macOS has no `timeout`) kills the command and its children.
# A file, not a pipe: an orphaned grandchild (git-remote-https) would hold a pipe open past the limit.
with_timeout() {
  local secs="$1" out="$2"; shift 2
  if command -v timeout >/dev/null 2>&1; then timeout "$secs" "$@" >"$out" 2>/dev/null; return $?; fi
  "$@" >"$out" 2>/dev/null &
  local pid=$!
  ( sleep "$secs"; pkill -P "$pid"; kill "$pid" ) >/dev/null 2>&1 &
  local watcher=$!
  wait "$pid" 2>/dev/null
  local rc=$?
  kill "$watcher" >/dev/null 2>&1
  return $rc
}

# "is $1 a strictly higher X.Y.Z than $2?" — numeric per field, no `sort -V` (not portable).
version_gt() {
  [ "$1" = "$2" ] && return 1
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)" = "$1" ]
}

LOCAL_VERSION=$(sed -n 's/^version: *//p' "${SKILL_DIR}/SKILL.md" 2>/dev/null | head -1 | tr -d '\r ')

export GIT_TERMINAL_PROMPT=0
TMP_OUT=$(mktemp 2>/dev/null) || exit 0
trap 'rm -f "$TMP_OUT"' EXIT
with_timeout "$TIMEOUT_S" "$TMP_OUT" git -C "$SKILL_DIR" ls-remote origin HEAD 'refs/tags/v*' || exit 0
REFS=$(cat "$TMP_OUT")
[ -z "$REFS" ] && exit 0

LATEST_TAG=$(printf '%s\n' "$REFS" | sed -n 's#^[0-9a-f]*[[:space:]]*refs/tags/v##p' \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)
REMOTE_HEAD=$(printf '%s\n' "$REFS" | sed -n 's#^\([0-9a-f]*\)[[:space:]]*HEAD$#\1#p' | head -1)

UPDATE="git -C ${SKILL_DIR} pull"

if [ -n "$LATEST_TAG" ] && [ -n "$LOCAL_VERSION" ] && version_gt "$LATEST_TAG" "$LOCAL_VERSION"; then
  echo "[shipright] v${LATEST_TAG} is available (installed: v${LOCAL_VERSION}) — update: ${UPDATE}"
elif [ -n "$REMOTE_HEAD" ]; then
  # Behind = the remote commit is missing locally, or present but not an ancestor of HEAD.
  if ! git -C "$SKILL_DIR" cat-file -e "${REMOTE_HEAD}^{commit}" 2>/dev/null \
     || ! git -C "$SKILL_DIR" merge-base --is-ancestor "$REMOTE_HEAD" HEAD 2>/dev/null; then
    echo "[shipright] new commits upstream (installed: v${LOCAL_VERSION:-unknown}) — update: ${UPDATE}"
  fi
fi

exit 0  # never block session start
