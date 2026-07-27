## Branch B — Existing project, add feature

> Read CLAUDE.md and ARCHITECTURE.md FIRST. Check Shipright state section.
> Ubiquitous Language in CLAUDE.md → use those terms, not generic names.

---

## Step 0 — Check state & registry

If Shipright state exists in CLAUDE.md:
```
"Last session: [Level], [module], next: [action]. Work on that, or a new feature?"
```

If no state → the project already exists: READ CLAUDE.md + ARCHITECTURE.md first (don't ask "what
does it do?" — read it). Then ask only what you can't read:
```
Ask the user (the intent only they know):
  "What should a user be able to do after this feature — and why does it matter?" (the job)
  → Dig one level if the ask is a solution ("add a dashboard") rather than a need ("see X to decide Y").

DO NOT ask "new module or extend existing?" — that is shipright's call. Decide it AFTER the
codebase report (Step 1) and PROPOSE it: "I'll extend [module] / add module [X] because […] — ok?"

Third-party API in scope? → shipright detects it from the feature, doesn't quiz. If it needs one:
  check tests/fixtures/ — no fixtures → do Layer 1 exploration FIRST (docs → Bruno → sandbox →
  save fixtures → then Adapter). references/third-party-apis.md §Layer-1.
```

If project type unknown → check registry for matching entry, load it.
Required skill not installed → offer it once at the moment it's needed, install on consent, and use it
this session (SKILL.md Check 3). Refused or failed → fallback, proceed, never block.

---

## Step 1 — Read codebase (structured report)

```
Read without modifying. Report:

## Codebase report: [name]
Entry points:    [file → what it starts]
Module map:      [module] → [1-sentence job] → [depends on]
Data flow:       Request → [A] → [B] → [C] → Response
Ubiquitous Lang: [domain terms actually used in code vs CLAUDE.md list]
Drift:           [any generic names where domain term should be used]
Landmines:       [global state, tight coupling, boundary violations]
Feature touches: [which modules affected]
```

Domain term drift = immediate fix before new feature.
Generic `OrderManager` when `FulfillmentPolicy` exists in Ubiquitous Language → rename.

From the report, PROPOSE the placement (don't ask the user to decide it):
"This feature belongs in [extend module X / a new module Y] because [evidence from the report].
 It touches [modules]. Agree, or did I misread the structure?" → proceed on confirmation.

---

## Step 2 — Health check

```
TIER 1 — Blockers (fix before feature):
□ Boundary violations? (service imports db, module imports module internals)
□ Circular deps? (npx madge --circular src/)
□ Empty catch blocks swallowing errors?

TIER 2 — Warnings (proceed with care, document):
□ Tests covering touched modules?
□ File > 300 lines?
□ Function > 20 lines in area being changed?

Verdict: SAFE / TIER1-BLOCKER / TIER2-CAUTION
```

TIER1-BLOCKER effort > 20% deadline → workaround + TODO[fix-before-scale], proceed.

---

## Step 3 — Classify: KIND first, then complexity

**First, the task's KIND — system or experience?** They need different questions and a different floor,
and on a full-stack product you ALTERNATE between them task by task. Detect it every time; don't carry
system-mode questions into a UI task or design questions into an API.
```
System task (API, data, domain logic, module, job)  → SYSTEM floor. Ask the system questions (domain
                                                       terms, one-way doors, API contract, data identity,
                                                       idempotency). Continue below.
   ↳ integrates a NEW 3rd-party API (including an LLM/AI API)? → Layer 1 exploration is MANDATORY before any
     Adapter code: call the real API/sandbox → save real responses as tests/fixtures/ → THEN write the
     Adapter + unit tests (from fixtures) + a contract test. Docs alone are wrong/incomplete.
     references/third-party-apis.md (LLM specifics — token/cost/streaming/errors: references/stacks/ai-projects.md).
Experience task (page, screen, flow, form, dashboard)→ EXPERIENCE floor. Load references/ui-design.md NOW
                                                       (not the appendix afterthought). Ask the DESIGN BRIEF
                                                       (audience + how they should feel, voice, real
                                                       content) and apply the UI/UX floor. Details: "UI
                                                       features" section below. Then size it.
Full-stack feature (spans both)                      → BOTH, at their seam: define the API contract first
                                                       (system), then build the UI against it (experience).
                                                       Ask each half its own questions. The contract is a
                                                       ONE-WAY door once a consumer exists → activate
                                                       api-and-interface-design (addyosmani) if installed;
                                                       otherwise hold the contract yourself: name the
                                                       resources in Ubiquitous Language, fix error shapes
                                                       and pagination now, version from the first consumer.
```

**Then size the complexity:**
```
1 file, obvious change            → Tier S (trivial, < 30 min)
2–5 files, clear scope            → Tier M (simple, < 2 hrs)
5–10 files OR unclear reqs        → Tier L (complex, 2–8 hrs)
10+ files OR multiple devs        → Tier XL (system-level, days)
```

> Executive check before sizing (`references/judgment.md`): does any part touch a ONE-WAY
> door (public interface, data identity, money, persisted state)? That part gets full design
> care regardless of tier. Two-way-door parts: simplest thing that works, don't gold-plate.

**Tier S — Trivial (1 file, < 30 min)**
```
Does change affect business logic?
  NO (config change, copy update, rename) → implement → commit
  YES → write test first (RED) → implement → GREEN → commit

No external skills needed for Tier S.
Exception: bug → activate debugging-and-error-recovery if installed.
```

**Tier M — Simple (2–5 files, < 2 hrs)**
```
PHASE: before implement
  [skill/spec-driven = YES] → NOT needed for Tier M (scope already clear)
  → Write acceptance criteria inline (2-3 sentences)

PHASE: implementing
  [skill/tdd = YES] → activate test-driven-development NOW
  [skill/tdd = NO]  → write RED test manually → implement → GREEN

PHASE: before commit/merge
  [skill/review = YES] → activate code-review-and-quality
  [skill/review = NO]  → run quality gate checklist in Step 5 below
```

**Tier L — Complex (5–10 files, 2–8 hrs)**
```
PHASE: before implement (required — do not skip)
  [skill/spec-driven = YES] → activate spec-driven-development FIRST
    Wait for spec approved before writing any code.
  [skill/spec-driven = NO]  → write spec manually:
    File: SPEC-[feature-name].md
    Include: problem, acceptance criteria, risks, out-of-scope
    Gate: SPEC reviewed before coding starts

PHASE: implementing
  [skill/incremental = YES + skill/tdd = YES] → /build auto
  [skill/incremental = YES only] → activate incremental-implementation
  [skill/tdd = YES only] → activate test-driven-development
  [neither] → implement subtask by subtask, RED→GREEN per subtask

PHASE: before merge
  [skill/review = YES] → activate code-review-and-quality (mandatory for Tier L)
  [skill/review = NO]  → full quality gate checklist (Step 5) + 2nd human review if team
```

**Tier XL — Architecture update first**
```
1. Update ARCHITECTURE.md (module added/changed)
2. Note in Shipright state: "architecture updated for [feature]"
3. [addyosmani]: spec → planning → /build auto → security → review
4. Feature flag always
```

---

## Step 4 — Implement

**Extend existing module:**
```
[Tier M+] DRIVE outside-in: write the RED test from the behavior first — the interface emerges
  from what the test needs to call (GOOS "interface discovery").
SLICE vertical: one feature end-to-end, not a horizontal layer.
IMPLEMENT the pieces domain-first for convenience: repository → service → handler
  (a default order, not a law — see levels.md L3 "three axes").
```

**New module:**
```
1. Update ARCHITECTURE.md: module name, job, public API, forbidden deps
2. Commit: "docs: add [module] to ARCHITECTURE.md"
3. Create module skeleton (index.ts + types.ts + stubs)
4. L2: define interface + write RED tests
5. L3: implement
```

---

## Step 5 — Quality gate (before every commit)

**Automated:**
```bash
grep -r "shared/db\|shared/database" src/modules/ # must be empty
npx tsc --noEmit 2>/dev/null || python -m mypy src/  # must pass
```

**DDD (Evans):**
- [ ] All new names from Ubiquitous Language in CLAUDE.md?
- [ ] New Entity has id + equals-by-id?
- [ ] New Value Object immutable (readonly / Object.freeze)?
- [ ] Repository interface in domain, implementation in infrastructure?

**SOLID (Uncle Bob):**
- [ ] Function > 20 lines? → extract with domain name
- [ ] AND/OR in function name? → split
- [ ] New type added by modifying existing switch? → new class instead
- [ ] Interface method no implementation uses? → split interface

**Fowler smells:**
- [ ] Feature Envy? (method uses another class's data more) → move it
- [ ] Primitive Obsession? (string/int where Value Object belongs) → create type
- [ ] Comment explaining WHAT? → rename instead

**Resilience (Nygard — only if this feature adds an integration point):**
- [ ] Boundary 5: new external call (HTTP/DB/queue/RPC) has a timeout + a defined fallback?
- [ ] Side effect idempotent — safe on retry/double-submit, key in DB/Redis (never in-memory)?
- [ ] HARDEN phase → `references/resilience.md` for circuit breaker / bulkhead

**Performance (structural — cheap now, expensive later):**
- [ ] No N+1 query (a loop issuing one query per item)? → batch / JOIN
- [ ] Result sets bounded (LIMIT / paginate), not unbounded SELECT?
- [ ] Any latency signal → `references/performance.md` (profile first, don't guess)

**Security (if this feature touches auth / data / untrusted input — `references/security.md`):**
- [ ] AuthZ enforced in the SERVICE, deny-by-default? (A01 — the #1 real breach)
- [ ] All input validated at the boundary; queries parameterized (no string-built SQL/HTML/shell)? (A05)
- [ ] No secret in code, logs, or error messages? (A04/A09)
- [ ] auth/payments/untrusted-input present → activate security-and-hardening skill

**Violation found:** fix → add specific rule to CLAUDE.md (compound engineering)
**Load** `references/code-quality.md` for fix guidance on specific violation.

---

## Step 6 — Update state

After feature complete, update CLAUDE.md Shipright state:
```markdown
## Shipright state
Level: L3
Active: [module just completed]
Next: [next feature or "validate with users"]
Last updated: [date]
```

---

## UI features

Any user-facing surface — page, flow, form, **or dashboard/admin**. Load `references/ui-design.md`: it is
the UI/UX judgment layer (floor = a11y + responsive/mobile + IA; structure = landing anatomy / admin
data-table patterns; archetype for the feel), which THEN dispatches execution to the right skill
(taste-skill / vercel-labs / dataviz). Apply the floor even if no design skill is installed.
Skip for: backend API, CLI, background jobs (no user-facing surface).
