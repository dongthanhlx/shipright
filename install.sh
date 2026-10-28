#!/usr/bin/env bash
# Install shipright into Claude Code by COPYING the runtime files (SKILL.md, references/, hooks/).
#
#   ./install.sh              personal install → ~/.claude/skills/shipright (all your projects)
#   ./install.sh --personal   same
#   ./install.sh --project    project install  → ./.claude/skills/shipright (commit it for the team)
#
# Prefer `git clone https://github.com/dongthanhlx/shipright ~/.claude/skills/shipright` for a
# personal install: it updates with `git pull` and enables hooks/check-update.sh. A copy does not.
#
# Safety: refuses to run from inside the target (a clone already IS the install — copying over it
# used to `rm -rf` the very directory being copied from), and refuses to replace a target that is
# not a shipright install. The new copy is staged first, so a failed copy leaves the old one intact.

set -euo pipefail

SKILL_NAME="shipright"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
RUNTIME=(SKILL.md references hooks)

case "${1:-}" in
  ""|--personal) TARGET_PARENT="${HOME}/.claude/skills"; SCOPE=personal ;;
  --project)     TARGET_PARENT="$(pwd)/.claude/skills";   SCOPE=project ;;
  -h|--help)     sed -n '2,7p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *)             echo "Unknown option: $1 (use --personal or --project)" >&2; exit 1 ;;
esac
TARGET="${TARGET_PARENT}/${SKILL_NAME}"

for f in "${RUNTIME[@]}"; do
  [ -e "${SCRIPT_DIR}/${f}" ] || { echo "Missing ${f} next to install.sh — run it from a shipright checkout." >&2; exit 1; }
done

mkdir -p "$TARGET_PARENT"
if [ -e "$TARGET" ]; then
  target_real="$(cd "$TARGET" && pwd -P)"
  if [ "$target_real" = "$SCRIPT_DIR" ]; then
    echo "shipright is already installed here (${TARGET}) — this checkout IS the install."
    echo "Update it with: git -C \"${TARGET}\" pull"
    exit 0
  fi
  if ! grep -qsE "^name: *\"?${SKILL_NAME}\"?[[:space:]]*$" "${TARGET}/SKILL.md"; then
    echo "Refusing to replace ${TARGET}: it is not a shipright install (no SKILL.md with name: ${SKILL_NAME})." >&2
    exit 1
  fi
fi

echo "Installing ${SKILL_NAME} (${SCOPE})..."
STAGE="$(mktemp -d "${TARGET_PARENT}/.${SKILL_NAME}.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
for f in "${RUNTIME[@]}"; do cp -R "${SCRIPT_DIR}/${f}" "${STAGE}/"; done
chmod +x "${STAGE}"/hooks/*.sh 2>/dev/null || true

rm -rf "$TARGET"
mv "$STAGE" "$TARGET"
trap - EXIT

echo "✓ Installed to ${TARGET}"
[ "$SCOPE" = project ] && echo "  Commit .claude/skills/ to share it with your team."
echo ""
echo "Type /shipright in Claude Code. (If it isn't listed yet, start a new session — a skills"
echo "directory that did not exist when the session started is not watched.)"
