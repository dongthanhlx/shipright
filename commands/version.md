---
description: Check shipright version and ecosystem skill status
user-invocable: true
disable-model-invocation: true
allowed-tools: Bash
---

Run this and report the results cleanly:

```bash
echo "=== Shipright ==="
# As a plugin, the plugin-root variable is substituted with the install dir; otherwise it is empty.
grep "^version:" "${CLAUDE_PLUGIN_ROOT}/SKILL.md" 2>/dev/null \
  || grep "^version:" ~/.claude/skills/shipright/SKILL.md 2>/dev/null \
  || grep "^version:" .claude/skills/shipright/SKILL.md 2>/dev/null \
  || echo "version: unknown (cannot locate SKILL.md)"

echo ""
echo "=== Ecosystem skills ==="

# Detect by the SKILL.md `name:` field, never by a guessed path: `npx skills add` installs flat by
# install name, `git clone` nests under repo/skills/<name>/. A path-shaped probe breaks under one of them.
# NOTE: neither addyosmani/agent-skills nor Leonxlnx/taste-skill has a ROOT SKILL.md — they are
# multi-skill repos. Probing for one always reports "not installed".
# NOTE 2: no shell positional params anywhere here (that rules out helper functions) — a dollar-sign
# followed by a digit is substituted with the invocation's arguments BEFORE the shell runs.
# NOTE 3: grep -R, not -r — `npx skills add` symlinks into ~/.claude/skills and -r skips symlinked dirs.
installed=$(grep -RhsE '^name: *"?[A-Za-z0-9_-]+"? *$' ~/.claude/skills .claude/skills \
  --include=SKILL.md 2>/dev/null | sed 's/^name: *//; s/"//g' | sort -u)

# addyosmani/agent-skills — the 6 shipright dispatches to
echo "addyosmani/agent-skills (shipright dispatches to these 6):"
missing=0
for s in spec-driven-development incremental-implementation test-driven-development \
         code-review-and-quality debugging-and-error-recovery security-and-hardening; do
  if printf '%s\n' "$installed" | grep -qx "$s"; then echo "  ✓ $s"; else echo "  ✗ $s"; missing=1; fi
done
[ "$missing" = 1 ] && echo "  Install: npx skills add https://github.com/addyosmani/agent-skills"

# taste-skill — an ECOSYSTEM, and its FOLDER names differ from its INSTALL names.
# The values below are install names (what `--skill` accepts and what lands in the frontmatter).
echo "taste-skill family (install names, not folder names):"
found=$(grep -RhsE '^name: *"?(design-taste-frontend(-v1)?|minimalist-ui|high-end-visual-design|redesign-existing-projects|industrial-brutalist-ui|gpt-taste|image-to-code|stitch-design-taste|imagegen-frontend-(web|mobile)|brandkit|full-output-enforcement)"? *$' \
  ~/.claude/skills .claude/skills --include=SKILL.md 2>/dev/null | sed 's/^name: *//; s/"//g' | sort -u | paste -sd', ')
if [ -n "$found" ]; then
  echo "  installed: ${found}"
else
  echo "  none installed"
  echo "  Install per page type: npx skills add https://github.com/Leonxlnx/taste-skill --skill \"design-taste-frontend\""
  echo "  (see references/ui-design.md — install names ≠ folder names; do NOT install all of them)"
fi

# vercel-labs/agent-skills — dashboards, admin, a11y-critical UI
if printf '%s\n' "$installed" | grep -qx web-design-guidelines; then
  echo "vercel-labs web-design-guidelines: installed"
else
  echo "vercel-labs web-design-guidelines: NOT installed"
  echo "  Install: npx skills add https://github.com/vercel-labs/agent-skills --skill \"web-design-guidelines\""
fi

echo "dataviz + artifact-design: bundled with Claude Code (no install needed)"

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
