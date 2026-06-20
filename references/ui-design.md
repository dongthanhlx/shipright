# UI Design — Page Type to Skill Mapping

taste-skill is not one skill — it is an ecosystem of 10+ specialized skills.
Using the wrong skill for the wrong page type produces worse output than no skill at all.

---

## Scope of taste-skill (what it covers and what it doesn't)

**taste-skill covers:**
- Landing pages (SaaS, consumer, agency, event)
- Portfolio sites (developer, designer, creative studio)
- Redesigns of existing marketing/landing sites
- Editorial / blog pages

**taste-skill explicitly does NOT cover:**
- Dashboards with data tables, charts, filters
- Admin panels
- Multi-step product UI (wizards, onboarding flows, complex forms)
- Data-heavy applications

For pages outside taste-skill scope → see "Other skills" section below.

---

## Page type → correct skill → dial settings

### SaaS landing page (B2B, serious but modern)
```
Skill: design-taste-frontend (v2)
Install: npx skills add https://github.com/Leonxlnx/taste-skill --skill "design-taste-frontend"

Dials: DESIGN_VARIANCE: 7 / MOTION_INTENSITY: 6 / VISUAL_DENSITY: 3
Tell Claude: "SaaS B2B landing page, serious but modern, conversion-focused"
```

### Agency / creative portfolio (Awwwards-level)
```
Skill: elite-frontend-design-2026
Install: npx skills add https://github.com/Leonxlnx/taste-skill --skill "elite-frontend-design-2026"

Dials: DESIGN_VARIANCE: 9 / MOTION_INTENSITY: 7 / VISUAL_DENSITY: 2
Tell Claude: "agency portfolio, Awwwards-level, experimental layout"
```

### SaaS product UI (Notion/Linear feel)
```
Skill: minimalist-skill
Install: npx skills add https://github.com/Leonxlnx/taste-skill --skill "minimalist-skill"

Dials: DESIGN_VARIANCE: 5 / MOTION_INTENSITY: 4 / VISUAL_DENSITY: 6
Tell Claude: "editorial product UI, Linear-style, restrained palette"
```

### Premium consumer app (Apple-y, calm, expensive feel)
```
Skill: soft-skill
Install: npx skills add https://github.com/Leonxlnx/taste-skill --skill "soft-skill"

Dials: DESIGN_VARIANCE: 6 / MOTION_INTENSITY: 5 / VISUAL_DENSITY: 2
Tell Claude: "premium, generous whitespace, calm feel, spring motion"
```

### Blog / editorial site
```
Skill: minimalist-skill
Dials: DESIGN_VARIANCE: 4 / MOTION_INTENSITY: 3 / VISUAL_DENSITY: 5
Tell Claude: "editorial, typography-first, content-heavy"
```

### Redesigning existing UI (already has code)
```
Step 1: redesign-skill first — audit before touching anything
Install: npx skills add https://github.com/Leonxlnx/taste-skill --skill "redesign-skill"
→ 6-category audit, identifies what's wrong

Step 2: apply appropriate skill from above based on target aesthetic
DO NOT jump straight to taste-skill on existing projects — audit first.
```

### UI has specific visual bugs / hierarchy problems
```
Skill: bugbuster (diagnostic mode)
Install: npx skills add https://github.com/Leonxlnx/taste-skill --skill "bugbuster"
→ Detects and fixes visual hierarchy, contrast, spacing in existing code
→ Run before applying other taste skills
```

### No visual direction yet (blank canvas)
```
Step 1: imagegen-frontend-web — generate reference images first
Install: npx skills add https://github.com/Leonxlnx/taste-skill --skill "imagegen-frontend-web"
→ Generates visual references, AI analyzes them, then implements
→ Costs one extra step but produces much clearer direction

Step 2: implement with appropriate skill from above
```

---

## Pages OUTSIDE taste-skill scope → other skills

### Dashboard / admin panel with data tables
```
Use: vercel-labs/agent-skills — web-design-guidelines
Install: git clone https://github.com/vercel-labs/agent-skills ~/.claude/skills/vercel-skills
→ 100+ rules covering accessibility, performance, UX correctness
→ Focused on correctness, not aesthetic creativity
```

### Multi-step forms, wizards, onboarding flows
```
Use: addyosmani/agent-skills — api-and-interface-design
→ Component contract thinking, interaction patterns
→ taste-skill has no rules for multi-step UX
```

### Accessibility-critical UI
```
Use: vercel-labs/agent-skills — web-design-guidelines
→ Proper a11y checks, WCAG compliance
→ taste-skill only says "don't regress" — not enough for compliance
```

---

## The 3 dials — how to override conversationally

**DO NOT edit SKILL.md to change dials.**
Override in conversation — taste-skill infers and adjusts.

```
DESIGN_VARIANCE (1–10)
  1–3: Centered, symmetric, standard grids (corporate, banking)
  4–7: Varied sizes, some overlap (SaaS, startup)
  8–10: Asymmetric, bold whitespace, experimental (agency, portfolio)
  ⚠ VARIANCE > 4: centered hero/H1 automatically BANNED

MOTION_INTENSITY (1–10)
  1–3: Hover effects only (corporate, accessibility-first)
  4–7: Fade-ins, scroll transitions (standard modern)
  8–10: Magnetic cursor, spring physics, GSAP scroll (agency)
  ⚠ Performance rule: transform/opacity ONLY — never top/left/width/height

VISUAL_DENSITY (1–10)
  1–3: Spacious, one element at a time (portfolio, hero)
  4–6: Balanced content and whitespace (SaaS)
  7–10: Packed — taste-skill not designed for this range (use dashboard tools)
```

Conversational overrides (no dial number needed):
- "Make it calmer" → MOTION_INTENSITY drops
- "More breathing room" → VISUAL_DENSITY drops
- "More experimental" → DESIGN_VARIANCE increases
- "Linear-style" → minimalist direction, VARIANCE: 5, DENSITY: 6
- "Awwwards-level" → VARIANCE: 9, MOTION: 7

---

## Anti-slop rules taste-skill enforces (know these)

**Hard banned (fail = rewrite):**
- Em-dash (—) anywhere in output — zero tolerance, binary rule
- Centered hero/H1 when DESIGN_VARIANCE > 4
- AI-purple gradients (#6366f1, #8b5cf6) as primary color
- Dark mesh/noise backgrounds as default
- Three equal-width feature cards in a row
- Section-number eyebrows ("01. About", "02. Services")
- Decorative dots/blobs as design elements
- Fake screenshots built from styled divs

**Performance (animation):**
- animate ONLY transform and opacity
- Never animate top, left, width, height, margin
- All animations: hardware-accelerated, will-change: transform

**Output-skill pairing:**
If Claude keeps generating placeholders or skips sections:
```
Also activate: output-skill
→ Forces complete, non-lazy output, no "// TODO" comments
```

---

## Install summary

```bash
# Core taste skills (install the ones for your project type)
npx skills add https://github.com/Leonxlnx/taste-skill --skill "design-taste-frontend"
npx skills add https://github.com/Leonxlnx/taste-skill --skill "soft-skill"
npx skills add https://github.com/Leonxlnx/taste-skill --skill "minimalist-skill"
npx skills add https://github.com/Leonxlnx/taste-skill --skill "redesign-skill"
npx skills add https://github.com/Leonxlnx/taste-skill --skill "bugbuster"

# For pages outside taste-skill scope
git clone https://github.com/vercel-labs/agent-skills ~/.claude/skills/vercel-skills

# Utility
npx skills add https://github.com/Leonxlnx/taste-skill --skill "output-skill"
```

Do NOT install all taste skills at once — context budget is finite.
Install only what your current page type needs.
