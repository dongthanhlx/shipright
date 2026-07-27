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

**What separates professional mobile from "crude" (the polish that's actually rules, not luck):**
- **Type & spacing:** body text ≥ 16px (smaller triggers iOS auto-zoom on focus and reads cheap); line
  length ~35–40 chars on phones; one consistent spacing scale (arbitrary margins are what read as "phèn").
- **Safe areas:** respect the notch / home indicator with `env(safe-area-inset-*)`; sticky top/bottom bars
  sit *above* the home indicator, content never hides under it. Ignoring this is the #1 crude tell.
- **Navigation by context:** app-like product → bottom tab bar (thumb-reachable, 3–5 items); content/
  marketing → top bar + hamburger for the long tail, but keep the 1 primary action always visible. Don't
  bury everything behind a hamburger.
- **Forms (Wroblewski):** set the right `inputmode`/`type` so the correct keyboard opens (email, numeric,
  tel); `autocomplete` on; labels stay visible; big tap targets; single column. Bad mobile forms are where
  products feel most amateur.
- **Performance IS the polish:** no layout shift (reserve image/space — CLS), lazy-load below the fold,
  lighter motion. A page that jumps while loading reads as broken no matter how nice the pixels.

**Per industry / audience (same structure, different emphasis — this is where "appropriate" comes from):**
- **E-commerce:** sticky add-to-cart / buy bar in the thumb zone; big product imagery; one-thumb checkout.
- **Fintech / banking:** clarity + trust on a small screen; big legible numbers; never cram; biometric-friendly.
- **Content / editorial / docs:** reading comfort first — ≥16px, generous line-height, comfortable measure,
  code blocks scroll horizontally instead of wrapping.
- **Dashboard / admin:** the hard case above — cards + progressive disclosure + tap-through, never a squeezed grid.
- **Consumer / social:** gesture-rich and quick; delight is allowed here (where an enterprise tool would restrain).
- **Dev tool:** responsive docs, copyable commands, code blocks that scroll, dark-capable.

**Verify at 360px with a real thumb** — not a resized desktop window — and at 200% text zoom (a11y + reflow
overlap).

> **Verification is a step, not a hope.** The floor above is only real if someone looks. Execute it with
> **`browser-testing-with-devtools`** (addyosmani; needs the chrome-devtools MCP server): render at 360px,
> capture console errors, check the network waterfall, and screenshot the result. If it is not installed,
> say so and ask the user to check the screen themselves — do NOT declare a UI "responsive" or "accessible"
> from reading the code alone. Reviewing the markup is `web-design-guidelines`' job; seeing it run is this.

---

## Icons — SVG icon sets, never emoji

> Emoji as UI icons is the fastest way to look amateur: they render differently on every OS/browser, can't
> be recoloured or sized to match, aren't accessible, and clash with any real visual system. **Use SVG
> icons.** Grounded in Material / SF Symbols icon guidelines + Refactoring UI (consistency).

**Rules:**
- **No emoji in product UI** (buttons, nav, status, empty states). SVG only. (Emoji is fine only as literal
  user content — a chat message, a reaction — never as chrome.)
- **Pick ONE set and stay in it.** Mixing icon families (different stroke weights / corner radii) is
  instantly incoherent. One set = one visual voice.
- **Curated free sets (living sources — pick one):** **Lucide** (the community-standard, huge, clean),
  **Heroicons** (Tailwind team), **Phosphor** (flexible weights), **Tabler**, **Radix Icons**, **Material
  Symbols**, Feather, Bootstrap Icons. Prefer a set with matching weights to your type.
- **Consistent stroke width + size**, snapped to the type scale (16 / 20 / 24). Optically align to text,
  don't just box-align. An icon that's a different weight than its neighbours reads as "off".
- **Icon + label for navigation** (Nielsen: recognition over recall — icon-only nav fails; a bare
  hamburger/kebab is the exception). Icons *support* words, they rarely replace them.
- **SVG uses `currentColor`** so icons theme with text (dark mode free). Size in `em` to track the type.
- **Accessibility:** decorative icon → `aria-hidden`; meaningful icon → `aria-label` (or a visible label).

Dispatch: the execution skill uses the chosen set; shipright's job is to *pick the set + enforce the rules*.

---

## Logo — use it well (Paul Rand); don't invent a brand identity here

> Scope: shipright handles **implementing and using** a logo professionally. Inventing a brand identity
> (the mark itself) is a designer / brand skill — say so, don't fake it. Grounded in **Paul Rand** (IBM,
> UPS, NeXT; *A Designer's Art*).

**Paul Rand's bar for a mark:** simple, memorable, works at any size, works in **one colour**, timeless.
"A logo derives its meaning from the quality of the thing it symbolises, not the other way around" — so
don't over-invest in a mark before the product is real (MVP-first: a clean wordmark in the product's
typeface is a perfectly professional day-one logo; a bespoke identity is deferred scope).

**Practical rules for using one in a build:**
- **SVG**, so it's crisp from a 16px favicon to a hero. Provide a proper favicon + app-icon set (multiple sizes).
- Must survive **monochrome** and **tiny** (favicon) — if it dies at 16px or in one colour, it's too complex.
- Provide **light + dark** variants (or a single currentColor mark); never a white logo on a white surface.
- **Clear space** around it; never stretch, rotate, recolour arbitrarily, add shadows/gradients, or place on
  a busy background. Lock the aspect ratio.

Dispatch: need an actual mark designed → **`brandkit`** (logo directions, palettes, type, identity boards
— see the dispatch section) or a human designer for the final mark. shipright advises placement, formats,
favicon, and the day-one "clean wordmark" default.

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

## Audience & emotional tone — design for WHO it's for (Norman's *Emotional Design*)

> A second axis, orthogonal to the archetype. The **archetype** (above) is set by *what the product does*;
> the **tone** is set by *who it's for and how they should feel*. Same category, different audience →
> different tone (a fitness app and a meditation app are both "consumer" but must feel opposite). Grounded
> in **Norman — *Emotional Design*** (visceral → behavioral → reflective) and **brand archetypes**
> (Jung / Mark & Pearson, *The Hero and the Outlaw*). This is the "thấu hiểu cảm xúc đối tượng" layer.

**Read the emotional GOAL and CONTEXT, not the demographic.** This is the professional bar and it matters:
"women → pink & soft, men → dark & bold" is dated and usually *wrong* (many of the strongest brands for
women are bold; much of men's grooming/premium is soft and quiet). Demographics are a **weak starting
hypothesis to confirm**, never a rule — stereotype-pandering reads as cheap; designing for the specific
emotional job reads as professional. Always confirm the intended feeling with the user before committing.

**The levers that actually produce a tone:**
- **Color temperature** — warm = energetic/friendly; cool = calm/trusted/clinical (meaning is partly
  cultural — verify per market, e.g. red, white).
- **Type personality** — geometric sans = modern/clean; humanist/rounded = friendly/soft; serif =
  trustworthy/editorial; heavy condensed grotesk = bold/strong.
- **Motion** — snappy/springy = energetic; slow/eased = calm/premium.
- **Density & whitespace** — airy = premium/calm; dense = utilitarian/serious.
- **Shape & imagery** — rounded + human photography = approachable; sharp + abstract = precise/serious.

**Emotional goal → tone (archetype lens; examples, not laws):**

| The audience should FEEL… | Tone (archetype) | Levers |
|---|---|---|
| strong, capable, high-energy (sport/fitness/performance — "khỏe khoắn") | Hero | high contrast, heavy/condensed type, dynamic motion, dark + bold accent |
| cared-for, calm, gentle (wellness/beauty/health — "dịu dàng") | Caregiver / Lover | warm muted palette, rounded humanist type, generous space, soft motion |
| fresh, playful, optimistic (youth/social/creative — "tươi tắn năng động") | Innocent / Explorer | bright saturated color, friendly rounded type, lively motion, illustration |
| assured, credible, in-control (office/enterprise/B2B — "clean chuyên nghiệp") | Sage / Ruler | restrained cool palette, neutral grotesk, structured grid, minimal motion |
| refined, exclusive, quiet luxury | Lover / Ruler | lots of whitespace, thin sans or elegant serif, muted/mono, slow elegant motion |

**Compose, don't pick one.** Final direction = **category archetype (what) × audience tone (who) × the
brand's own positioning**. E.g. a *fintech app for Gen-Z* = fintech's trust/legibility base, warmed and
brightened toward Innocent/Explorer — not the sober Ruler tone a private bank would use. State the
composition to the user and, when unsure, show two directions and let them point.

---

## Emotional design — make it FELT, not the sterile "AI-slop" look (Aaron Walter)

> The tone table says *which* feeling; this says *how* a design comes to feel human at all instead of the
> dry, generic, soulless output that screams "an AI made this." Grounded in **Aaron Walter — *Designing
> for Emotion*** and Norman's **reflective** level. The antidote to AI-slop is not more decoration — it's
> **specificity, voice, and earned delight.**

**Walter's hierarchy (emotion sits at the TOP — earn the base first):** functional → reliable → usable →
**pleasurable**. Delight is added *on top of* a solid, usable base — never instead of it. A charming empty
state on a broken flow is lipstick; get the floor (a11y, states, responsive) right, then add soul.

**Why AI design feels dead, and the fix (each is a rule, not a vibe):**
- **Specificity beats generic.** Real copy and real data, never lorem ipsum; real photography or
  intentional illustration, never generic stock-y "diverse team pointing at a laptop"; a concrete point of
  view over safe blandness. Genericness is the #1 source of the soulless feel.
- **Voice is where personality lives** (Walter). The microcopy — buttons, empty states, errors,
  onboarding, confirmations — carries the brand's personality. "Something went wrong" is dead; a line in
  the product's actual voice is alive. This is exactly where AI output is blandest, so it's the highest-leverage fix.
- **Earned delight in the details.** One considered moment — a thoughtful empty state, a satisfying
  micro-interaction, a human touch — beats decoration everywhere. Restrained and intentional; a serious
  enterprise tool earns less than a consumer app (tie it back to the audience tone).
- **Intentional over uniform.** Perfect symmetry and default-everything read as machine-made. A deliberate
  point of view — an asymmetric hero, a signature color, a real illustration — reads as human.

**The honest boundary (don't fake soul).** Emotion ultimately comes from real human inputs — real content,
an actual brand voice, real photos/stories, a genuine point of view. shipright's job is to (1) **refuse
the generic defaults** that cause the dead feeling, (2) **mandate specificity + voice + earned delight** in
the brief, and (3) **prompt the human for the irreplaceable bits** ("what's your product's voice? do you
have real photos/copy?") rather than paper over them with stock and lorem. A machine can remove the
soulless tells and demand the human inputs; it can't manufacture the soul from nothing — so ask for it.

---

## Eliciting the design brief — what to ASK vs INFER (same intake philosophy)

> The audience-tone and emotional sections need inputs shipright can't read from code — so intake has to
> gather them, or all that judgment stays dark. Gather them the shipright way (SKILL.md "How shipright
> asks"): **infer what you can, state it as an assumption to confirm, ask ONLY the irreplaceable.** Never a
> design questionnaire, never a cold quiz.

**INFER from the product + market, then confirm (don't ask cold):**
- Likely **audience + emotional tone** — derive it and play it back: "A fitness app for young athletes —
  I'd aim energetic / Hero: high contrast, bold type, dynamic motion. That fit, or is your crowd different?"
- **Category archetype** — from what the product does.

**ASK — only the user knows these, and they're what create soul (skip for a throwaway/internal tool):**
- **Who is it really for, and how should they feel using it?** (the emotional goal — confirms or corrects
  the inference above; this is the "hiểu cảm xúc đối tượng" input.)
- **Brand voice / personality** — is there one already? Show an example, or should shipright propose one?
- **Real content & assets** — real copy, real photos, a real logo? Or placeholders for now? This drives
  specificity vs the generic AI-slop look. **If none exist, say so honestly**: "with placeholder content
  it'll look generic until real copy/photos land" — flag it, don't paper over it with stock + lorem.
- **Hard brand constraints** — existing colours, typeface, brand guidelines to honour.

**Calibrate to stakes:** a public, brand-facing product → gather all of the above; an internal CRUD admin
→ none of it (don't over-interview). Depth of the design intake tracks how much the feeling matters.

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

> **`--skill` takes the INSTALL NAME, not the folder name.** The taste-skill repo's folder and install
> name differ for most skills (`soft-skill/` installs as `high-end-visual-design`) and the repo's README
> is the source of truth for that column. Using the folder name makes the install command **fail** — so
> the names below are install names. Verify against the repo README before adding a new one here.

### SaaS landing page (B2B, serious but modern)
```
Skill: design-taste-frontend   (folder: taste-skill — the general default; currently v2, experimental)
Install: npx skills add https://github.com/Leonxlnx/taste-skill --skill "design-taste-frontend"
Pin to v1 if v2 breaks your workflow: --skill "design-taste-frontend-v1"

Dials: DESIGN_VARIANCE: 7 / MOTION_INTENSITY: 6 / VISUAL_DENSITY: 3
Tell Claude: "SaaS B2B landing page, serious but modern, conversion-focused"
```

### Agency / creative portfolio (Awwwards-level)
```
Skill: design-taste-frontend at high dials — it is the variance/motion skill, no separate "elite" skill exists.
Install: npx skills add https://github.com/Leonxlnx/taste-skill --skill "design-taste-frontend"

Dials: DESIGN_VARIANCE: 9 / MOTION_INTENSITY: 7 / VISUAL_DENSITY: 2
Tell Claude: "agency portfolio, Awwwards-level, experimental layout"

If the direction is already chosen, swap in the committed variant instead:
  hard / Swiss / mechanical / experimental → industrial-brutalist-ui   (folder: brutalist-skill)
  you want stricter anti-slop + heavier GSAP motion enforcement → gpt-taste  (folder: gpt-tasteskill)
```

### SaaS product UI (Notion/Linear feel)
```
Skill: minimalist-ui   (folder: minimalist-skill)
Install: npx skills add https://github.com/Leonxlnx/taste-skill --skill "minimalist-ui"

Dials: DESIGN_VARIANCE: 5 / MOTION_INTENSITY: 4 / VISUAL_DENSITY: 6
Tell Claude: "editorial product UI, Linear-style, restrained palette"
```

### Premium consumer app (Apple-y, calm, expensive feel)
```
Skill: high-end-visual-design   (folder: soft-skill)
Install: npx skills add https://github.com/Leonxlnx/taste-skill --skill "high-end-visual-design"

Dials: DESIGN_VARIANCE: 6 / MOTION_INTENSITY: 5 / VISUAL_DENSITY: 2
Tell Claude: "premium, generous whitespace, calm feel, spring motion"
```

### Blog / editorial site
```
Skill: minimalist-ui   (folder: minimalist-skill)
Dials: DESIGN_VARIANCE: 4 / MOTION_INTENSITY: 3 / VISUAL_DENSITY: 5
Tell Claude: "editorial, typography-first, content-heavy"
```

### Redesigning existing UI (already has code) — and visual/hierarchy defects in shipped UI
```
Entry point: Branch D Step 0 → EXPERIENCE track (audit → confirm direction → floor-vs-scope → execute).
The steps below are that track's execution half; the audit is mandatory with or without the skill.

Step 1: redesign-existing-projects — AUDIT before touching anything   (folder: redesign-skill)
Install: npx skills add https://github.com/Leonxlnx/taste-skill --skill "redesign-existing-projects"
→ Audits current UI, names the generic/AI-slop patterns, then fixes layout, spacing, hierarchy, styling
  without breaking functionality. This is also the right skill for specific visual defects (contrast,
  spacing, broken hierarchy) — there is no separate diagnostic skill.

Step 2: apply the appropriate skill from above based on target aesthetic
DO NOT jump straight to a taste-skill on existing projects — audit first.
```

### No visual direction yet (blank canvas)
```
Step 1: generate reference images first
  web pages   → imagegen-frontend-web
  mobile app screens/flows → imagegen-frontend-mobile
Install: npx skills add https://github.com/Leonxlnx/taste-skill --skill "imagegen-frontend-web"
→ Generates visual references, AI analyzes them, then implements
→ Costs one extra step but produces much clearer direction

Step 2: implement with the appropriate skill from above.
Alternative one-shot pipeline: image-to-code (folder: image-to-code-skill) does generate → analyze →
implement in one skill; use it instead of Step 1 + Step 2 when the visual is the whole point.
```

### Brand identity / logo system / palette + type board
```
Skill: brandkit   (image-generation, not code)
Install: npx skills add https://github.com/Leonxlnx/taste-skill --skill "brandkit"
→ Brand-guideline boards: logo directions, palettes, type, identity applications.
→ This is the "dedicated design/brand skill" the §Logo section defers to. It produces DIRECTIONS to
  choose from — it does not replace a human designer for a final mark, and MVP-first still says a clean
  wordmark is a fine day-one logo.
```

---

## Pages OUTSIDE taste-skill scope → other skills

### Dashboard / admin panel with data tables
```
Judgment (design decisions): "Admin panels & dashboards" section above — shipright owns this.
Execution rules: vercel-labs/agent-skills — web-design-guidelines
Install: npx -y skills@latest add https://github.com/vercel-labs/agent-skills -y -g --skill "web-design-guidelines"
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
Also activate: full-output-enforcement   (folder: output-skill)
→ Forces complete, non-lazy output, no "// TODO" comments
```

---

## Install summary

```bash
# Core taste skills — INSTALL NAMES (folder names in comments; passing the folder name FAILS)
npx skills add https://github.com/Leonxlnx/taste-skill --skill "design-taste-frontend"      # taste-skill
npx skills add https://github.com/Leonxlnx/taste-skill --skill "high-end-visual-design"     # soft-skill
npx skills add https://github.com/Leonxlnx/taste-skill --skill "minimalist-ui"              # minimalist-skill
npx skills add https://github.com/Leonxlnx/taste-skill --skill "redesign-existing-projects" # redesign-skill

# For pages outside taste-skill scope
npx skills add https://github.com/vercel-labs/agent-skills --skill "web-design-guidelines"
#   (or: git clone https://github.com/vercel-labs/agent-skills ~/.claude/skills/vercel-skills)

# Utility
npx skills add https://github.com/Leonxlnx/taste-skill --skill "full-output-enforcement"    # output-skill
```

Verify a name before adding it here — folder names and install names differ, and only install names work:
```bash
npx -y skills@latest add https://github.com/Leonxlnx/taste-skill --list   # prints install names, installs nothing
```
Don't just print these commands at the user. When a page-type trigger fires and the skill is missing,
**offer to install it and use it in the same session** (SKILL.md Check 3) — a skill added mid-session
takes effect without a restart. Ask first, always.

Do NOT install all taste skills at once — context budget is finite.
Install only what your current page type needs.

**How detection works (do not "fix" it back into a path check):** the repo name never appears on disk,
and the on-disk layout differs between `npx skills add` (flat, by install name) and `git clone` (nested
under `<repo>/skills/<name>/`). So SKILL.md's `skill/taste` probe matches the **`name:` field inside
SKILL.md** — what the skill *is*, independent of how it got installed — and lists which taste skills are
actually present, because dispatch depends on the specific one. **Adding a new sibling skill here means
adding its install name to that probe**, or it will read as "not installed" forever.

**Already available — do not tell the user to install these:** `dataviz` and `artifact-design` ship with
Claude Code. Invoke them directly for charts and for Artifact pages.
