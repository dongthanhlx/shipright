---
name: shipright-version
description: Check shipright version and ecosystem skill status
user-invocable: true
disable-model-invocation: true
allowed-tools: Bash
---

Run this and report the results cleanly:

```bash
echo "=== Shipright ==="
grep "^version:" "${CLAUDE_SKILL_DIR}/../SKILL.md" 2>/dev/null \
  || grep "^version:" ~/.claude/skills/shipright/SKILL.md 2>/dev/null \
  || echo "version: unknown (cannot locate SKILL.md)"

echo ""
echo "=== Ecosystem skills ==="

# addyosmani/agent-skills
if [ -f ~/.claude/skills/agent-skills/SKILL.md ]; then
  ver=$(grep "^version:" ~/.claude/skills/agent-skills/SKILL.md 2>/dev/null | awk '{print $2}')
  echo "addyosmani/agent-skills: installed (${ver:-unknown version})"
else
  echo "addyosmani/agent-skills: NOT installed"
  echo "  Install: npx skills add https://github.com/addyosmani/agent-skills"
fi

# taste-skill
if [ -f ~/.claude/skills/taste-skill/SKILL.md ]; then
  ver=$(grep "^version:" ~/.claude/skills/taste-skill/SKILL.md 2>/dev/null | awk '{print $2}')
  echo "taste-skill: installed (${ver:-unknown version})"
else
  echo "taste-skill: NOT installed"
  echo "  Install: npx skills add https://github.com/Leonxlnx/taste-skill"
fi

echo ""
echo "=== Project constitution ==="
if [ -f CLAUDE.md ]; then
  echo "CLAUDE.md: found"
  head -3 CLAUDE.md | grep -E "^#|Project" | head -1
else
  echo "CLAUDE.md: NOT found — run /shipright to create"
fi

if [ -f ARCHITECTURE.md ]; then
  echo "ARCHITECTURE.md: found"
else
  echo "ARCHITECTURE.md: NOT found — run /shipright to create"
fi
```
