#!/bin/bash
# Install shipright skill into Claude Code

set -e

SKILL_NAME="shipright"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing ${SKILL_NAME}..."

# Personal install (all projects)
if [ "${1}" = "--personal" ] || [ "${1}" = "" ]; then
  TARGET="${HOME}/.claude/skills/${SKILL_NAME}"
  mkdir -p "${HOME}/.claude/skills"
  rm -rf "${TARGET}"
  cp -r "${SCRIPT_DIR}" "${TARGET}"
  echo "✓ Installed to ${TARGET}"
  echo "  Works across all your projects."
fi

# Project install
if [ "${1}" = "--project" ]; then
  TARGET=".claude/skills/${SKILL_NAME}"
  mkdir -p ".claude/skills"
  rm -rf "${TARGET}"
  cp -r "${SCRIPT_DIR}" "${TARGET}"
  echo "✓ Installed to ${TARGET}"
  echo "  Commit .claude/skills/ to share with your team."
fi

echo ""
echo "Restart Claude Code, then type: /shipright"
