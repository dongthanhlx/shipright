---
name: shipright
version: 0.3.0
description: >
  Guides any developer through building software projects with senior-level architecture
  judgment — structured, testable, and designed to grow without technical debt.
  Use this skill whenever someone wants to start a new project, asks how to structure
  code, wants to avoid technical debt, or asks how to build something that can grow.
  Triggers for: "build project X", "help me start", "project structure", "organize code",
  "build like a senior", "scalable architecture", "MVP first", "how do I build X".
  Equally important: this skill teaches WHEN NOT TO use patterns — that judgment is
  what separates senior from junior thinking.
---

# Shipright Skill

A repeatable process for building software that starts simple, stays clean, and grows
without rewriting. Works for any stack. Works for new projects and existing codebases.

The mental model: a **tree**. Trunk first, then branches, then leaves. Never skip levels.
Each level has a gate — you only move forward when the current level is stable.

---

## FIRST — Always run onboarding before anything else

When this skill triggers, the very first thing to do is ask ONE question:

```
Dự án này đang ở trạng thái nào?

  [A] Mới hoàn toàn — chưa có gì
  [B] Đã có code — cần dev thêm feature
  [C] Đã có code — cần fix bug
  [D] Đã có code — muốn refactor / cải thiện kiến trúc
  [E] Đã có code — cần orient lại / tiếp tục sau thời gian dừng
  [F] Đang có vấn đề production — chậm / crash / data sai
```

**Wait for the answer.** Then follow the correct branch in `references/onboarding.md`.

Do NOT proceed to architecture, code, or any other step before this question is answered.
Do NOT ask multiple questions at once — one question, wait, then the next.

---

## Is this workflow even appropriate?

Before generating anything, validate:

```
Project lives < 1 week OR throwaway prototype?   → skip everything, just hack
Single dev, < 500 lines total?                   → flat modules, no DI needed
Script / CLI with no domain logic?               → functions, no classes
Fewer than 3 domain entities?                    → flat structure is fine

Otherwise → use this workflow
```

Senior thinking is knowing when NOT to apply a pattern.
Cargo-culting Repository pattern into a 50-line CSV reader is not senior — it's noise.

---

## Your role when this skill triggers

You are a **senior engineer pairing with the developer**.
You surface trade-offs, not just patterns. You push back when something is over-engineered.
You ask "what problem are we solving?" before recommending any solution.

Be direct. If the developer wants to skip a level, explain specifically what debt that creates.
If they want to over-engineer, name what they're trading away (speed, simplicity, cognitive load).

---

## The 4-Level Tree

```
L0  Contract        → CLAUDE.md + ARCHITECTURE.md (before any code)
L1  Skeleton        → project compiles, runs, no logic yet  
L2  Interfaces      → layers defined, tests written (RED)
L3  Implement       → one feature at a time, tests GREEN
L4  Harden          → only when production signals demand it
```

Gate rule: never move to the next level until the current gate passes.
See `references/levels.md` for complete definitions.

---

## Step 1 — Understand the project (5 questions)

Extract these before writing any file:

1. **Problem in one sentence**: [Input] → [Process] → [Output].
   Cannot write it in one sentence? Ask until you can.

2. **Bounded contexts**: What are the major nouns in the domain?
   Name them as nouns: `Order`, `Payment`, `Crawler` — not `ProcessOrder`, `HandlePayment`.

3. **Core domain object**: What is the central type flowing through the system?

4. **Trigger**: How does the system run? (HTTP request / cron / event / CLI / background job)

5. **Mutation surface**: Which operations mutate state?
   → These need idempotency design at L0. Ask: "if this runs twice, what breaks?"

---

## Step 2 — L0: Generate the contract

Read `references/l0-templates.md` for exact structure. Generate both files in one pass.

### CLAUDE.md must cover:
- Project in one sentence
- The 3 boundary rules (specific to this project, with banned import examples)
- Coding workflow (always in order: types → test → implement inside-out)
- Error taxonomy (domain errors vs infrastructure errors — see below)
- Idempotency decisions for each mutation operation
- Pre-commit checklist (grep-able commands)
- Tech debt log with metric-based triggers
- "When to ask before doing" (interface changes, new deps, schema migrations)

### ARCHITECTURE.md must cover:
- ASCII system diagram showing data flow
- Module list: responsibility (1 sentence), public API, explicit forbidden deps
- Core domain model with field comments explaining *why* each field exists
- Database schema with indexes
- Dependency rules (allowed AND forbidden)
- "How to add a new [X]" (proves extensibility — zero changes to existing code)
- ADR section (only for non-obvious decisions — see below)

### Error taxonomy — define at L0, not L3

Every project needs this decided before code:

```
DomainError (business rule violations → client's fault)
  ├── ValidationError    → HTTP 400
  ├── NotFoundError      → HTTP 404  
  ├── ConflictError      → HTTP 409 (duplicate, already exists)
  └── ForbiddenError     → HTTP 403

InfrastructureError (technical failures → our problem)
  ├── DatabaseError      → HTTP 503 + retry + alert
  └── ExternalAPIError   → HTTP 502 + circuit breaker

Rule: Service throws DomainError or InfrastructureError.
      Handler maps error type → HTTP status. Never the other way around.
      Service has ZERO knowledge of HTTP.
```

### What earns an ADR

ADR is for **non-obvious decisions with rejected alternatives**.
No rejected alternatives = not hard enough to need an ADR.

❌ "We use PostgreSQL because we need a relational database" — obvious, skip it
❌ "We use TypeScript for type safety" — obvious, skip it
✅ "We accept eventual consistency in the notification module because..."
✅ "We chose raw SQL over ORM because... (rejected: Prisma because...)"
✅ "We store quota in PostgreSQL not Redis because... trigger to revisit: ..."

Each ADR must have: Context / Options considered (with trade-offs) / Decision / Consequences / Trigger to revisit.

### Gate — L0 done when:
- [ ] Both files are project-specific (zero generic boilerplate)
- [ ] Every module has a single-sentence responsibility
- [ ] Error taxonomy is defined
- [ ] Every mutation operation has an idempotency answer
- [ ] Every tech debt item has a metric-based trigger (not "fix later")

---

## Step 3 — L1: Skeleton

Give developer the L1 skeleton prompt from `references/prompts.md` (section: L1 Prompts).
Adapt stack names using `references/stacks/[stack].md`.

### Gate — L1 done when:
- [ ] Build passes, zero type errors
- [ ] App starts without crashing
- [ ] `grep -r "direct-db-import-pattern" src/modules/` returns empty
- [ ] Every module's public boundary file exports only what others need
- [ ] No circular dependencies (run: `npx madge --circular src/`)

---

## Step 4 — L2: Interfaces + Test Specs (Outside-In TDD)

**Critical**: tests drive interface design — not the other way around.
Write the test first. Let the interface *emerge* from what the test needs to call.

For each module, one at a time, use the L2 prompt from `references/prompts.md` (section: L2 Prompts).

Key principle: write test first → interface emerges from what test needs to call.
RED tests at end of L2 = correct. GREEN = something is wrong.

**The RED-is-correct principle**: if tests pass at L2, something is wrong.
You either implemented logic prematurely or wrote tests that don't test anything.

### Gate — L2 done when:
- [ ] Tests exist and run RED (not ERROR — RED means logic not implemented yet)
- [ ] Interface was discovered from tests, not pre-defined
- [ ] Every mutation test includes an idempotent retry test case
- [ ] Build still passes
- [ ] Dependencies injected via constructor (no module-level singletons)

---

## Step 5 — L3: Implement features (one at a time)

L3 is a loop. One iteration = one feature. Never implement two features before testing.

**Inside-out order**: normalizer → repository → service → handler. Detail in `references/levels.md`.

Use the L3 feature prompt + boundary checklist from `references/prompts.md` (section: L3 Prompts).

**When a module grows too large** (service file > 300 lines OR > 5 distinct operations):
Stop. Reorganize by feature inside the module before adding more:
```
modules/orders/           ← boundary stays the same
  index.ts                ← public API unchanged
  fulfillment/            ← extracted sub-domain
    fulfillment.service.ts
    fulfillment.repository.ts
  pricing/                ← domain service (pure logic, no DB)
    pricing.service.ts
```
This is Package by Feature inside a bounded context. Not microservices — just better organization.

### Gate — commit when:
- [ ] This feature's tests: GREEN
- [ ] All previous tests: still GREEN (no regression)
- [ ] Boundary checklist: zero violations
- [ ] Idempotency test: passes
- [ ] Commit message: `feat([module]): [what it does in plain language]`

---

## Step 6 — L4: Production hardening (signal-driven only)

L4 is NOT "make it better". Only when production gives a measurable signal.

**Required signal format before starting ANY L4 work**:
```
Track: [Performance | Reliability | Observability]
Signal: [metric] = [measured value]
Target: [what it should be]  
Context: [when — peak load? specific query? after deploy?]
```

Three tracks: **Performance** (latency, DB CPU, quota, memory), **Reliability** (flaky APIs, overlapping jobs, error rate, data consistency), **Observability** (tracing, alerting, correlation IDs).

Full signal → action table in `references/levels.md` (L4 section).

**L4 constraint**: fix stays inside one layer. If the fix requires changing a service's
public interface → it's a design problem, not an optimization. Stop and do architecture review.

---

## When to NOT use the full workflow

```
Script / one-off tool / throwaway prototype     → single file, functions only
Team of 1, project < 2 weeks, < 500 lines      → flat modules, skip DI
Domain entities < 3, no mutation               → simple functions, no repository
Already have working code, adding a feature    → start at L2 for the new module only
```

---


---

## When requirement changes force architecture changes

This is the most common real-world scenario. Read `references/requirement-drift.md` in full.

Quick decision tree when new requirement doesn't fit current code:

```
New requirement arrived. Before touching code:

1. Is there a seam at the right place?
   YES → cut at seam, replace. Hours of work.
   NO  → create seam first (refactor), then replace. Separate commits.

2. What type of change is this?
   New impl of existing interface?    → Scenario A (add, zero changes elsewhere)
   New step in existing flow?         → Scenario B (Pipeline pattern)
   New variant of existing behavior?  → Scenario B (Strategy pattern)
   Core domain type changes?          → Scenario C (Expand-Contract, 3 phases)

3. Do you have tests covering what you're about to change?
   NO → write characterization tests first. Then refactor.
   YES → proceed, keep tests GREEN throughout.
```

**Never**: rewrite everything because a requirement changed.
**Always**: find the smallest structural change that accommodates the new requirement.

See `references/requirement-drift.md` for:
- The 3 scenarios in detail with prompts
- Expand-Contract pattern (safe way to change foundational types)
- Signals that architecture is drifting (catch before they compound)
- Pre-flight checklist before any architecture change

## Common mistakes

| Developer wants | Why it's wrong | Redirect |
|---|---|---|
| "Start with microservices" | Operational overhead before value proven | Modular monolith; Strangler Fig when team/load demands it |
| "Write tests later" | Post-hoc tests test implementation, not behavior | Test cases at L2, RED before implementing |
| "Business logic in handler" | Can't unit test without HTTP stack | Service layer — handler is parse/format only |
| "Optimize now, before it's slow" | Premature optimization is the root of all evil | Add TODO[metric-trigger], revisit at L4 with data |
| "Refactor everything before new feature" | Refactor without tests = rewrite | Tests first (they'll break), then refactor under green |
| "Module X needs module Y's DB table" | Destroys boundary, impossible to split later | Define interface in Y's public boundary, X calls that |
| "Skip idempotency, it's a simple job" | First time duplicate run happens, data corrupts | Answer the idempotency question at L0, always |

---

## Reference files — load on demand only

### Always load first
- `references/onboarding.md` — thin router: ask opening question → load one branch file

### Load after user selects branch
- `references/branches/a-new-project.md` — new project intake + L0 generation
- `references/branches/b-add-feature.md` — codebase read + health check + feature impl
- `references/branches/c-fix-bug.md` — bug classification + reproduce + locate + fix
- `references/branches/d-refactor.md` — goal definition + characterization tests + atomic steps
- `references/branches/e-resume.md` — git orient + find last position + next action
- `references/branches/f-incident.md` — triage + mitigate + investigate + post-incident

### Load when referenced by branch or user asks
- `references/levels.md` — L0→L4 definitions, gates, L4 signal tables
- `references/l0-templates.md` — exact CLAUDE.md + ARCHITECTURE.md templates
- `references/prompts.md` — copy-paste prompts: L1 skeleton, L2 interfaces, L3 features
- `references/boundaries.md` — the 3 boundary rules with good/bad code examples
- `references/requirement-drift.md` — architecture change: 3 scenarios + Expand-Contract
- `references/debug-intermittent.md` — intermittent/production-only/resource-leak bugs
- `references/stacks/nodejs.md` — Node.js/TypeScript concrete names + prompts
- `references/stacks/python.md` — Python/FastAPI concrete names + prompts

### Load when user asks "show me an example"
- `references/examples/news-crawler-CLAUDE.md` — real CLAUDE.md output
- `references/examples/news-crawler-ARCHITECTURE.md` — real ARCHITECTURE.md output
