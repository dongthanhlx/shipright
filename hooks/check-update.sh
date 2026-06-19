#!/bin/bash
# Shipright update checker — runs at SessionStart
# Compares local version with GitHub latest tag/commit
# Fast, silent on success, notifies only when update available

SKILL_DIR="${HOME}/.claude/skills/shipright"
SKILL_MD="${SKILL_DIR}/SKILL.md"

# Must be installed as git repo to check updates
if [ ! -d "${SKILL_DIR}/.git" ]; then
  exit 0  # Installed as zip — can't check, skip silently
fi

# Get local version from SKILL.md
LOCAL_VERSION=$(grep "^version:" "${SKILL_MD}" 2>/dev/null | awk '{print $2}')

# Check GitHub for latest (timeout 3s — don't slow down session start)
REMOTE=$(git -C "${SKILL_DIR}" ls-remote origin refs/tags/v* 2>/dev/null \
  | awk '{print $2}' \
  | sed 's|refs/tags/v||' \
  | sort -V \
  | tail -1)

# Also check if local commit is behind remote main
LOCAL_COMMIT=$(git -C "${SKILL_DIR}" rev-parse --short HEAD 2>/dev/null)
REMOTE_COMMIT=$(git -C "${SKILL_DIR}" ls-remote origin HEAD 2>/dev/null | awk '{print substr($1,1,7)}')

# Notify only when actually behind
if [ -n "$REMOTE" ] && [ "v${LOCAL_VERSION}" != "v${REMOTE}" ] 2>/dev/null; then
  echo "┌─────────────────────────────────────────────┐"
  echo "│  shipright update available                 │"
  echo "│  Local:  v${LOCAL_VERSION:-unknown}                           │"
  echo "│  Latest: v${REMOTE}                                │"
  echo "│                                             │"
  echo "│  Update: cd ~/.claude/skills/shipright      │"
  echo "│          git pull && git checkout v${REMOTE}     │"
  echo "└─────────────────────────────────────────────┘"
elif [ -n "$REMOTE_COMMIT" ] && [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
  echo "[shipright] new commits on remote — run: git -C ~/.claude/skills/shipright pull"
fi

exit 0  # Never block session start
