# Level Definitions

## Lifecycle spine — the one model everything maps onto

Shipright grew four overlapping vocabularies. They are the SAME timeline. Use this mapping
whenever a doc says "L2" / "Stage 1" / "Traction" / "Growth" — translate to a phase:

| Phase | aka | Levels here | Scaling stage | Masters active | Resilience dial |
|---|---|---|---|---|---|
| **SEED** | MVP | L0–L1 | — | Evans, Beck | OFF (except one-way-door items) |
| **VALIDATE** | Traction | L2–L3 | — | + Uncle Bob, Fowler | MINIMAL (timeouts, Correlation ID) |
| **HARDEN** | Growth | L4 | Stage 1–2 | + Nygard, SRE | FULL on signal (resilience.md, SLO) |
| **SCALE** | Scale | L4 | Stage 3 | + Ousterhout (deep modules) | + bulkheads, backpressure |

- The **construction** masters (Evans/Bob/Fowler/Beck) ramp up early — their work is in the
  irreversible quadrant, cheap now and expensive later (see `references/judgment.md`).
- The **operation** masters (Nygard/SRE) turn on by *signal*, not by reaching a phase label.
  Adding them at SEED is over-engineering; missing them at HARDEN is how systems fall over.
- L0–L4 below are the construction mechanics inside SEED→HARDEN. Stage 1–3 (team/scale
  growth) lives in `references/scaling-guide.md`. Both are this one spine, seen from two angles.

---

**Ubiquitous Language precedes every L0:**
  The Ubiquitous Language step in Branch A intake: extract the terms domain experts actually use
  Claude uses these terms for ALL class, method, and variable names in the project.
  Generic names (Manager, Handler, Utils) = Ubiquitous Language not yet defined.
**Extract Ubiquitous Language first** — before L0 constitution generation.

## L0 — Contract (before any code)

**What it is**: Two markdown files that define the project's constitution.
Nothing is built. No code exists. Only decisions are documented.

**Why it matters**: Claude Code reads CLAUDE.md before every action.
The clearer these files are, the more consistently Claude Code will follow
the architecture — across sessions, across features, across developers.

**Time estimate**: 30–60 minutes. Fast if the problem is clear. Slow if it isn't
(which means you need more time here, not less).

**Output**:
```
CLAUDE.md          # rules + workflow + tech debt policy
ARCHITECTURE.md    # modules + boundaries + domain model + ADR
```

**What "done" looks like**:
- You can explain every module's job in one sentence
- You can name 3 things that are explicitly forbidden
- Every tech debt shortcut has a trigger condition that is a real metric

---

## L1 — Skeleton (project compiles, runs, does nothing)

**What it is**: The entire folder structure created with stub files.
Every module exists. Every service class exists. Every method exists.
But every method throws `NotImplementedError`.

**Why it matters**: Forces you to confront import errors, circular dependencies,
and structural problems before any logic is written. Cheap to fix now.
Expensive to fix after 3 features are implemented.

**Time estimate**: 1–2 hours with Claude Code.

**Output**:
```
src/
  modules/[each-module]/
    index.ts          ← public API only
    types.ts          ← interfaces and DTOs
    [name].service.ts ← class with stub methods
  shared/
    db.ts, logger.ts, errors.ts, http-client.ts
  config/
    env.ts            ← zod schema, throws on startup if missing
package.json, tsconfig.json, jest.config.ts
docker-compose.yml
```

**What "done" looks like**:
- `npm run build` exits 0
- `npm start` logs "started" and doesn't crash
- `grep -r "from.*shared/db" src/modules/` returns nothing

---

## L2 — Interfaces + Test Specs (tests exist, all RED)

**What it is**: For each module, you define how the layers talk to each other
AND you write what each feature should do (as test cases).
No business logic or SQL yet — only shapes and expectations.

**Why it matters**: Test cases written now describe behavior, not implementation.
They become the spec that guides L3. They also catch interface design problems
before you're committed to an implementation.

**The "RED is correct" principle**: Running `npm test` at end of L2 should show
all tests failing. This means the interfaces are defined but not implemented.
If tests pass at L2, something is wrong — you've implemented without testing first.

**Time estimate**: 2–4 hours per module, depending on complexity.

**Output** (per module):
```
[name].repository.ts       ← I[Name]Repository interface + class stub
[name].handler.ts          ← routes + zod validation
[name].service.test.ts     ← test cases (mock repository)
```

**Test case template**:
```typescript
describe('FeatureService.methodName', () => {
  it('happy path: does the thing', async () => { ... })
  it('edge case: empty input returns empty array', async () => { ... })
  it('error case: not found throws NotFoundError', async () => { ... })
  it('error case: dependency fails propagates error', async () => { ... })
})
```

**What "done" looks like**:
- Every service method has at least 3 test cases
- `npm test` runs and shows RED (failures, not errors)
- `npm run build` still passes
- Repository is injected via constructor, not imported directly

---

## L3 — Implement Features (tests go GREEN one by one)

**What it is**: The loop where actual work happens.
One feature at a time. Implement → test GREEN → boundary check → commit → repeat.

**Why one feature at a time**: If you implement 5 features then run tests,
you don't know which feature broke what. One feature per commit makes
every failure immediately diagnosable.

**Inside-out order** (always follow this):
1. Normalizer (if source-specific transform) — pure function, easiest to test
2. Repository — SQL queries
3. Service — business logic using repository
4. Handler — HTTP layer (often trivial once service works)

**Time estimate**: 30–90 minutes per feature.

**The commit discipline**:
```
feat(orders): add createOrder with stock validation
feat(orders): add cancelOrder with refund trigger
fix(orders): handle concurrent order race condition
```

Never: `feat: add stuff` or `wip` or `various fixes`

**What "done" (for one feature) looks like**:
- Feature test cases: GREEN
- All previous test cases: still GREEN
- Boundary checklist: zero violations
- Commit: created with descriptive message

---

## L4 — Optimize (only with production signal)

**What it is**: Targeted fixes for measured problems.
Not "make it cleaner" or "this could be faster".
Only: "this metric is outside this target, here is the data."

**The signal format** (require this before starting any L4 work):
```
Signal: [what metric] = [measured value]
Target: [what it should be]
Context: [when does this happen — peak traffic? specific query? specific user?]
```

**Why the signal is required**: Without a signal, "optimization" is often
premature and introduces complexity for a problem that doesn't exist at scale.
The architecture from L0-L3 is designed so that L4 changes stay inside one layer.
If a fix requires changing a service interface, it's not an L4 problem — it's
a design review.

**L4 branches by signal type**:

| Signal | L4 action |
|---|---|
| Latency p95 > target | Profile → find slow query/function → cache or index |
| DB CPU > 60% | Read replica → connection pooling → query plan analysis |
| API quota exhausted early | Increase cache TTL → batch requests → request deduplication |
| Memory growth over time | Find leak → fix or add cleanup job |
| Module too large for one team | Strangler Fig → extract service with feature flag |
| Storage > threshold | Partition by date → archive policy → cleanup job |

**What "done" looks like**:
- Metric is now within target (measured, not assumed)
- Benchmark test exists proving before/after
- No public interface was changed
- No new dependencies were added without justification in ARCHITECTURE.md

---

## Team growth signals — when architecture must align with team

> Shipright focuses on technical architecture. But Conway's Law is real:
> "Your architecture will reflect your team structure."
> When team grows, these signals mean architecture decisions need team alignment.

### Signal: team > 5 people

```
Action: define module ownership explicitly
- Each module has 1 primary owner (team or person)
- Owner approves PRs that change public interface (index.ts)
- No module owned by "everyone" — that's owned by "no one"

Add to ARCHITECTURE.md:
## Module ownership
| Module    | Owner      | Reviewer for interface changes |
|-----------|------------|-------------------------------|
| crawler   | @dev-a     | @dev-a + @tech-lead           |
| feed      | @dev-b     | @dev-b + @tech-lead           |
```

### Signal: team > 8 people, multiple features in flight simultaneously

```
Risk: two devs change same module = merge conflict + coordination overhead
Action: evaluate if module should be extracted
Criteria (need ALL THREE to justify extraction):
  1. Module has dedicated owner team (>= 2 people)
  2. Module has different deploy cadence than rest of system
  3. Module has clearly different scaling requirements

If not all three → keep in monolith, improve boundary rules instead
```

### Signal: "we need microservices" conversation

```
Ask first:
  - Is Conway's Law the real driver? (teams can't coordinate)
  - Or is it scale? (one module needs 10x more resources)
  - Or is it tech diversity? (one module needs different language/runtime)

Most teams that "need microservices" actually need:
  - Better module boundaries (shipright's 3 rules)
  - Better team ownership (signal above)
  - Better deployment automation

Microservices solve organizational scale, not technical scale alone.
A well-structured modular monolith can serve millions of users (Shopify does).
```

---

## L4 Hardening tracks

Three tracks — only enter when production signal demands:

**Performance:** profile first (don't guess) → cache / index / query plan / read replica
**Reliability:** circuit breaker, retry with backoff+jitter, distributed lock for overlapping jobs
**Observability:** when "we don't know where it's slow" → add OpenTelemetry;
  when "errors found by users" → add Sentry; when "can't reproduce prod" → Correlation ID missing
  Full patterns: `references/observability.md`

---

## When shipright is no longer enough — graduate checklist

These signals mean you need tools/practices beyond shipright:

```
[ ] CLAUDE.md > 150 lines and you haven't split to .claude/rules/ yet
    → Do the split now (see Branch D — CLAUDE.md evolution)

[ ] Team > 10 people working on same repo
    → Need: team topology design, module ownership matrix, PR workflow policy

[ ] Codebase > 100 files, Claude keeps getting lost
    → Need: codebase navigation skill (ripgrep/ast-grep patterns)
    → Add to CLAUDE.md: "Before making changes, run: rg -l '[keyword]' src/"

[ ] Compliance required: SOC2, PCI-DSS, HIPAA, GDPR
    → Need: specialized compliance skills + human legal/security review
    → Shipright's security guidance is insufficient for compliance

[ ] Multiple repos or monorepo > 500k LOC
    → Need: Anthropic's enterprise Claude Code guidance
    → Shipright assumes single repo, single deployment unit

[ ] SRE practice needed: SLO, error budget, on-call rotation
    → Need: dedicated SRE tooling + process design
    → Shipright's incident guidance (Branch F) is not SRE practice
```

Shipright does not pretend to cover these.

For Stage 1→2→3 architecture evolution: `references/scaling-guide.md` When you hit these signals,
you've grown beyond what a skill can guide — you need organizational change.
