# UI/UX — judgment first, then dispatch

Two layers, like the rest of shipright: **judgment** (durable principles — decide what "good" means) and
**dispatch** (vendor skills — execute the pixels). The principles below are shipright's own UI/UX
hemisphere: they apply even with NO design skill installed (capability, not vendor). The tables further
down route to the right skill when one IS installed. Ground every UI/UX call in a principle, not a trend.

---

## MVP-first applies here too — cut scope, never the floor

Same executive question as the rest of shipright (one-way vs two-way door). MVP-first is about **scope, not
quality**: an MVP UI is a *smaller, complete, floor-solid* UI — never a sloppy one. "Chuẩn chỉ from day
one" is TRUE for the floor and OVER-engineering for the scope. When unsure which a concern is, ask: *is it
expensive or risky to add later?* Yes → floor (do it now). No → scope (defer).

**Floor — one-way doors, do right on day one (this IS "proper from the start"):**
- **Accessibility** (WCAG) — bolting it on later is expensive
- **Responsive / mobile foundation** — retrofitting mobile onto a desktop layout always loses
- **Information architecture + semantic HTML** — wrong structure means a rewrite
- A **minimal scale + semantic colors** *if hand-rolling CSS* — but a framework (Tailwind / shadcn / a
  design system) gives you this professional token foundation **free from line one**, so there's nothing to defer

**Scope — two-way doors, defer until the need is real (deferring is NOT sloppiness):**
- Heavy token / theming pipeline, multi-brand theming
- Full component library, elaborate motion / micro-interactions
- Aesthetic polish beyond the archetype's floor

---

## UI/UX judgment — the durable principles (apply BEFORE and WITHOUT any vendor skill)

**Norman — *The Design of Everyday Things* (the conceptual floor).** Every interactive element must make
itself obvious with no manual:
- **Affordance + signifier** — it looks like what it does (a button looks pressable; a link, clickable).
  If users can't tell it's interactive, the design failed, however pretty.
- **Feedback** — every action gets an immediate visible response (loading / success / error). No silent actions.
- **Mapping** — control layout matches the mental model (next → right; destructive = danger color).
- **Constraints** — make the wrong action hard: disable, confirm-destructive, validate inline.
Fires on ANY interactive UI. This is the floor, not the ceiling.

**Nielsen — 10 heuristics (the usability checklist).** The load-bearing few: visibility of system status;
match system↔real world (user's words, not jargon); user control (undo / cancel / back); **error
prevention beats error messages**; recognition over recall (show options, don't make them remember);
help users recover (say what happened + how to fix, in plain language). Run this list on any flow.

**Krug — *Don't Make Me Think* (cognitive load).** Every question the UI forces ("is this clickable?
where am I? what does this do?") is a tax. Self-evident > self-explanatory > needs-explanation. Omit
needless words. Users satisfice — they click the first reasonable thing — so make it obvious.

**Wathan & Schoger — *Refactoring UI* (how to look good mechanically, not by "taste").** Hierarchy comes
from **weight and color, not size alone**; **spacing** creates grouping — start with too much whitespace,
then remove; **design in grayscale first** (fix hierarchy/spacing before color); limit the palette;
borders are a last resort (separate with background / shadow / spacing). Rules, not vibes — usable with
zero design skill installed.

**Fitts's Law + Gestalt (layout math).** Primary actions bigger and closer (Fitts). Group by proximity /
similarity / common-region (Gestalt), not by drawing boxes. Alignment is invisible when right, screams
when wrong.

**Tufte — data & dashboards.** Maximize data-ink, kill chartjunk (3D, heavy gridlines, decoration),
small-multiples over one busy chart, direct-label over legend. For real charts/dashboards, **dispatch to
the `dataviz` skill** (a purpose-built color + layout system) — don't hand-roll chart colors.

**Accessibility (WCAG) is correctness, not polish** — same status as a boundary or a failing test.
Contrast ≥ 4.5:1; every interactive element keyboard-reachable with a visible focus ring; color is never
the ONLY signal; semantic HTML (real `<button>` / `<label>`), alt text, form labels. Treat an a11y
regression like a red test.

**The UX floor every screen owes (beyond the happy path).** Loading, empty, error, and success states are
*designed*, not afterthoughts. Destructive actions confirm. Forms validate inline with recoverable
messages. This is where "UX" (not just "UI") lives — and exactly what landing-page skills stay silent on.

> Fallback rule: if no design/taste skill is installed, shipright does NOT hand-wave — it applies the
> principles above explicitly (name the heuristic, state the decision) and says which skill would sharpen
> the result. Never pretend a vendor skill is present.

---

## Mobile & responsive — design the smallest screen first (it's usually the majority)

> Mobile is often most of the traffic, yet it's the easiest thing to forget on a desktop monitor. Durable
> — grounded in Wroblewski (*Mobile First*) and platform touch guidelines. Not a separate design: the same
> design that reflows gracefully. This cuts across every section below (landing AND admin).

**Mobile-first, not desktop-shrunk.** Design the smallest screen first — it forces you to rank content, so
only the essential survives; then progressively enhance for width. Retrofitting mobile onto a desktop
layout always loses.

**Breakpoints follow the content, not devices.** Add a breakpoint where the layout actually *breaks* (line
length too long, grid cramped), not at fixed "phone/tablet/desktop" widths — device sizes churn, content
reflow is stable. Common anchors ~640 / 768 / 1024 / 1280, but let the content decide.

**Touch targets (Fitts for fingers).** ~44×44px minimum tappable area with spacing so neighbours aren't
mis-hit. Primary actions in the thumb zone (bottom third on phones), not top corners. **Hover is not
available on touch** — never hide an essential action behind hover; hover is enhancement only.

**Reflow patterns:** multi-column → single column; side nav → bottom bar or hamburger (keep the top 1–2
actions visible, don't bury everything); horizontal group → vertical stack; fixed sidebar → drawer.

**The two hard cases:**
- **Landing on mobile:** section stack collapses to one column; hero shortens; the CTA stays reachable (a
  sticky bottom CTA is fine); images/motion lighten (data + battery).
- **Admin / data tables on mobile** (the real problem): a wide table must NOT just scroll into the void.
  Best → worst: show 2–3 key columns + tap-through to detail; card-per-row with labelled fields; horizontal
  scroll with a frozen first column as a last resort. Never a 12-column table crushed into 360px.

**Verify at 360px with a real thumb** — not a resized desktop window — and at 200% text zoom (a11y + reflow
overlap).

---

## Style archetypes — match the aesthetic to the project's JOB (not to a trend)

> What's durable is the *archetype*: a product category has a native aesthetic because of WHO uses it and
> WHAT it's for. Specific pixels churn; the archetype and its exemplars are stable. shipright reads the
> archetype from the project's job, confirms with the user, briefs the vendor skill with it, and
> calibrates against the reference sources below. This is "gu" (taste) you can *reason about* — not vibes,
> and not a frozen snapshot of what's trendy this year.

| Project / topic | The job → aesthetic language | Exemplars to study | Dials (start) |
|---|---|---|---|
| Dev tool / infra / API | technical credibility: dark-capable, dense-but-precise, restrained palette, mono accents, keyboard-first | Linear, Vercel (Geist), Stripe, Railway | VAR 5 / MOT 4 / DEN 6 |
| Fintech / banking / payments | trust & legibility: conservative color, high contrast, data-first, zero whimsy | Stripe, Mercury, Ramp | VAR 3 / MOT 3 / DEN 5 |
| Enterprise B2B SaaS / dashboards | scannable density, consistent components, data-viz discipline | Tailwind UI, IBM Carbon, Shopify Polaris, Atlassian | VAR 4 / MOT 3 / DEN 7 → dataviz |
| Consumer / lifestyle / wellness | warm & calm: generous whitespace, rounded, soft motion, human imagery | Apple HIG, Airbnb, Calm, Headspace | VAR 6 / MOT 5 / DEN 2 |
| Creative / agency / portfolio | expressive: asymmetric, bold type, motion-rich, experimental | Awwwards, Godly, Land-book | VAR 9 / MOT 7 / DEN 2 |
| AI / chat product | conversational clarity: streaming feedback, visible model state, modern-restrained | Claude, ChatGPT, Perplexity | VAR 5 / MOT 4 / DEN 4 |
| Docs / content / editorial | typography-first: readable measure, minimal chrome, great code blocks | Stripe Docs, Tailwind, Nextra | VAR 4 / MOT 2 / DEN 5 |
| E-commerce / marketplace | product-first: imagery, conversion clarity, trust signals | Shopify, Apple Store | VAR 5 / MOT 4 / DEN 5 |
| Crypto / web3 | two poles — infra → fintech-serious; consumer/NFT → bold-expressive. Match the sub-segment; do NOT default to neon | (infra) Stripe-like · (consumer) OpenSea, Blur | depends |

Rule: pick the archetype from the JOB, **confirm with the user**, then brief taste-skill/dataviz with it
as the direction. Unsure between two → show the two exemplars and let the user point. The dials map to the
"3 dials" section below.

---

## Reference sources — where to calibrate taste (living galleries, not frozen in this file)

> shipright does NOT copy trends into itself (they rot). It knows WHERE the authoritative, living examples
> live and studies the *principle* behind them when needed. Calibrate direction; never clone pixels.

**Real-product pattern libraries — how shipping products actually solve UX (best for flows/states):**
- **Mobbin** — real iOS / Android / web flows, searchable by pattern (onboarding, settings, empty states)
- Page galleries: **Land-book**, **SaaS Landing Page**, **Godly** (godly.website), **Awwwards** (aspirational/experimental), Httpster

**Design systems — how strong teams codify taste + accessibility (the gold standard for RULES):**
- **Apple HIG**, **Material 3**, **Shopify Polaris**, **IBM Carbon**, **Atlassian**, **Vercel Geist**,
  **GitHub Primer**, Adobe Spectrum, Salesforce Lightning

**Component / template sources — production-ready good defaults:**
- **Tailwind UI**, **shadcn/ui**, **Radix**, Vercel templates, Once UI

**How to use them (the shipright way):** identify the archetype → open the matching **design system** for
rules (spacing / color / a11y) + a **gallery** for direction → extract *why it works*, not the pixels →
brief the execution skill. Studying > copying: a layout lifted without its reason breaks on the next screen.

---

## Landing pages — anatomy + conversion (the structure the archetype fills)

> The archetype gives the *feel*; this gives the *structure*. A landing page has ONE job: move a specific
> visitor to a specific action. Durable — grounded in Krug (clarity), Cialdini (persuasion / social proof),
> and conversion practice. The archetype styles it; this decides what goes on it.

**Section stack (default order — you cut sections, you don't reorder them):**
1. **Hero** — one headline stating the *outcome* (not the feature), one subhead, one primary CTA. Passes
   the 5-second test: a stranger knows what this is and what to do. No carousel, no competing CTAs.
2. **Social proof** — logos / numbers / a testimonial high up (Cialdini: proof lowers risk *before* the ask).
3. **Value blocks** — features framed as user *outcomes*, one idea per block, alternating layout.
4. **Objection handling** — the top 2–3 reasons this visitor won't convert, answered (security, price, lock-in).
5. **Deeper proof** — a case study / metric / testimonial with a face + name.
6. **Pricing** (if relevant) — clear, no dark patterns, recommended tier marked.
7. **FAQ** — the real questions sales/support hear, not filler.
8. **Final CTA** — repeat the *same* primary action. One primary action per page, repeated.

**Copy hierarchy:** outcome > benefit > feature. Answer "what's in it for me" above the fold.

**Per-industry emphasis (shifts weight, not the structure):**
- Fintech / enterprise → lead with trust: compliance/security, real logos, ROI numbers.
- Dev-tool → proof-by-doing: code sample, quickstart, `install` line, docs link above the fold.
- Consumer / wellness → emotion + imagery, benefit-first, softer CTA.
- Agency / portfolio → lead with the work itself, minimal copy.
- AI product → show it *working* (a real example/demo), honest about what it does — avoid hype words.

Then brief the matching taste-skill (dispatch tables below) with this structure as the spec.

---

## Admin panels & dashboards — the pattern language (taste-skill does NOT cover this; shipright does)

> Admin UX is a *durable* discipline — patterns barely churn. Grounded in **Tidwell (*Designing
> Interfaces*)**, **Wroblewski (*Web Form Design*)**, **Tufte** (dashboards), and the data-table specs of
> Material / Carbon / Polaris. This is the judgment vacuum neither vendor fills (taste-skill excludes admin;
> vercel-labs gives a11y/correctness *rules*, not pattern judgment). Design it here, then dispatch.

**Information architecture:** overview → drill-down. Most-important top-left (F-pattern). Progressive
disclosure — summary first, detail on demand. One primary object per screen; don't fuse list + detail + edit
into one wall.

**Data tables (the core admin primitive):**
- Right-align numbers (tabular/monospace figures), left-align text, align units — so columns compare at a glance.
- One attribute per column; hide secondary data behind a detail view or a column toggle, not 20 columns.
- Sortable headers; sticky header on scroll; sticky first column for wide tables.
- Row actions revealed on hover/row-end; **bulk actions** via row-select for any repeated operation.
- Pagination with a total count for data you audit; infinite scroll only for feeds, never for records.
- Every table has loading (skeleton), empty (with a next action), and error states — never a blank grid.
- Offer a compact density mode for power users; don't force it on everyone.

**Filtering & search:** faceted filters for known dimensions, free-text for the unknown. Show active filters
as removable chips. **Saved / named views** for workflows run daily. Keep filter state in the URL
(shareable, back-button-safe).

**Forms & editing (Wroblewski):** label *above* the field; single column (not multi-column forms); group
related fields; inline validation with recoverable messages; mark required vs optional explicitly; inline
edit for a single field, full form for creation; optimistic UI with rollback for perceived speed.

**CRUD & actions:** list → detail → edit as distinct, navigable, linkable states. Destructive actions
confirm *and* are undoable where possible (soft-delete + undo toast beats a modal gauntlet). Show status for
long/async actions (progress, background-job state).

**Dashboards (Tufte + chart selection):** each view answers ONE question — not "show all the data." Pick the
chart from the question *before* rendering: trend → line; comparison → bar; part-of-whole → stacked bar /
treemap (never pie for >5 slices); single number → big stat + sparkline; distribution → histogram;
correlation → scatter. Then hand color + layout to **dataviz**. Kill chartjunk; direct-label over legend.

**The admin state-floor:** empty (first-run guidance), loading (skeletons, not layout-shifting spinners),
error (what failed + retry), permission (what you can't do + why), and zero-results-after-filter (distinct
from true-empty).

Dispatch: **vercel-labs/agent-skills** for the a11y + correctness rule-set · **dataviz** for every chart.

---

## Ubiquitous Language for UI

UI component names should reflect domain terms, not generic UI patterns.

```
Wrong: UserCard, DataTable, InfoModal
Right: SubscriberProfile, OrderHistory, CancellationConfirmation

Domain terms from CLAUDE.md Ubiquitous Language apply to:
  - Component names (FeedItemCard, not ArticleCard if FeedItem is the domain term)
  - Event names (onFeedItemSelected, not onItemClick)
  - Prop names (feedItem: FeedItem, not data: any)
```

taste-skill handles visual quality. Ubiquitous Language handles naming.
Both must be defined before writing UI components.

---

## Dispatch — which skill executes (judgment above decides; these produce the pixels)

taste-skill is not one skill — it is an ecosystem of 10+ specialized skills. Using the wrong skill for
the wrong page type produces worse output than no skill at all. Match the page type precisely.

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
Judgment (design decisions): "Admin panels & dashboards" section above — shipright owns this.
Execution rules: vercel-labs/agent-skills — web-design-guidelines
Install: git clone https://github.com/vercel-labs/agent-skills ~/.claude/skills/vercel-skills
→ 100+ rules covering accessibility, performance, UX correctness
→ Focused on correctness, not aesthetic creativity
Charts: dataviz skill (color + layout). shipright picks WHICH chart; dataviz renders it.
```

### Charts, graphs, data visualization (any medium)
```
Use: dataviz skill
→ Purpose-built color formula (light + dark, accessible), mark specs, dashboard layout
→ Applies Tufte's data-ink discipline. Read it BEFORE writing any chart code or picking chart colors.
→ This is the right tool for the "dashboard data cells" that vercel-labs covers structurally.
```

### Claude Artifact (HTML/Markdown page hosted on claude.ai)
```
Use: artifact-design skill (design calibration) + artifact-capabilities (if it needs live/stateful data)
→ Load before building the artifact — it calibrates how much design investment the request warrants.
```

### Multi-step forms, wizards, onboarding flows
```
Use: addyosmani/agent-skills — api-and-interface-design
→ Component contract thinking, interaction patterns
→ taste-skill has no rules for multi-step UX
→ UX judgment (Nielsen error-prevention, the state-floor above) comes from shipright, not this skill
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

## Anti-slop rules taste-skill enforces on the copy/markup IT generates (know these)

> Scope: these are taste-skill's rules for the marketing copy and markup **it produces** — the tells that
> scream "AI-made". They do NOT govern this reference file or shipright's own prose (which use em-dashes
> and commentary freely). Apply them to generated landing/marketing output, not to reasoning or docs.

**Hard banned in generated output (fail = rewrite):**
- Em-dash as an AI-slop tell in generated body/marketing copy — taste-skill bans it in what it writes (a
  binary anti-slop signal, not a typography law). Generated copy uses commas / periods instead.
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
