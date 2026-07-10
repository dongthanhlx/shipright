# Evolutionary architecture — you WILL be wrong; build to evolve, guard with fitness functions

> shipright's one-way-door thesis (judgment.md) says "get the irreversible decisions right up front."
> True — but over-confident about two things: that you can reliably *predict* what's irreversible,
> and that "decide early" is the answer. You will be wrong about some of them (the domain model is a
> one-way door, and it's often wrong once you learn more). This file tempers the thesis — it does not
> replace it — with the discipline of building for change and recovering when you're wrong.
>
> Masters: **Ford, Parsons & Kua** (*Building Evolutionary Architectures* — "guided, incremental
> change across multiple dimensions"; fitness functions), **Bezos** (most decisions are two-way doors),
> **the Poppendiecks** (the last responsible moment), **Fowler** (evolutionary design), **Conway**.

Load this when a "settled" architectural decision turns out wrong, when setting up CI architecture
governance, or at L0 for anything you expect to learn your way into (Validation mode — judgment.md §2).

---

## Temper the one-way-door thesis (don't drop it — refine it)

```
1. Bias toward REVERSIBILITY. Bezos: most decisions are two-way doors. shipright's boundaries EXIST
   to make change local — a repository behind an interface, an Adapter/ACL at the edge, a module
   behind its index — that is turning "irreversible" into "reversible". Design the seam and most
   one-way doors become two-way. (Parnas information hiding is an evolvability technique.)

2. For the GENUINELY irreversible: decide at the LAST RESPONSIBLE MOMENT — "as long as you can, but
   no longer" (Poppendieck). Delaying buys information that reduces the chance of being wrong; it is
   NOT procrastination. Decide EARLY only for decisions that heavily constrain other choices or are a
   critical success factor. Deciding early with too little information is how one-way doors go wrong.

3. Design for EVOLVABILITY as a first-class quality. The old belief — "architectural elements are hard
   to change later" — is the thing to defeat, not accept. Make incremental change the default, then
   guard it (below) so quality can't silently degrade while you evolve.
```
The one-way-door heuristic still governs *where to spend design budget*. Evolutionary architecture is
*how you execute it*: make it reversible where you can, decide late where you can't, and guard the rest.

---

## Fitness functions — shipright already has them; name and generalize them

A **fitness function** is an objective, automatable integrity check of an architectural characteristic
(Ford/Parsons) — implemented as a test, a metric, monitoring, or a lint. They let the architecture
*evolve* while proving the important qualities don't degrade. shipright ships several already, unnamed:

```
Already fitness functions in shipright:
  boundary-guard.sh (enforcement.md)        → coupling / no cross-module internals  (atomic, triggered)
  dependency-cruiser / arch tests in CI     → dependency direction, layering         (atomic, triggered)
  the quality gate (b-add-feature.md)       → SOLID / Fowler smells                   (atomic, triggered)
  performance budgets (performance.md)      → latency/throughput within target        (atomic, continual)
  SLO + error budget (observability.md)     → reliability                              (holistic, continual)
  fault-injection tests (resilience.md)     → survives a failing dependency            (holistic, triggered)
  consumer-driven contract tests (team-scale)→ teams don't break each other's API      (atomic, triggered)

Generalize — add the ones you're missing (cheap in CI):
  □ no cyclic dependencies (madge --circular / depcruise)      □ max coupling / fan-out per module
  □ layering (handler→service→repo only)                       □ bundle-size / cold-start budget (frontend)
```

Categories (Ford/Parsons), so you place them right:
```
Atomic  — one aspect in isolation (coupling, complexity). A unit-test-style check.
Holistic— a COMBINATION (e.g. security × scalability): caching makes the scalability check pass but
          the security check fail on stale data. Test the important interactions, not every combo.
Triggered — runs on an event (commit, pipeline). Continual — runs constantly (latency, SLO monitor).
```
The mechanism (Ford/Parsons 3 steps): **identify the dimensions change threatens → define a fitness
function per dimension → automate them in the deployment pipeline.** This is "automated software
governance": the architecture may change; the fitness functions keep it honest.

---

## The recovery path — "a one-way-door decision turned out wrong. Now what?"

You will hit this. Don't freeze (paralysis) and don't YOLO-rewrite (chaos). **Evolve under guard** —
shipright already has every tool; this is them, named as one discipline:

```
Wrong INTERFACE / public API        → Expand–Contract (add the new, deprecate the old, migrate, remove).
                                       references/requirement-drift.md.
Wrong MODULE boundary / needs split → Strangler Fig — grow the replacement alongside, route gradually,
                                       remove the old. references/scaling-guide.md Stage 3.
Wrong DOMAIN MODEL (the hard one)    → characterization tests pin current behavior, then refactor toward
                                       the corrected model in small steps. references/branches/d-refactor.md.
During ANY of the above              → the fitness functions above stay green — that's what makes the
                                       evolution safe instead of a big-bang gamble.
```
This is also why the boundaries were worth it: a wrong decision behind a good seam is a *local* change,
not a system-wide rewrite. The seam you built to "get it right" is the same seam that lets you recover
when you were wrong. (Validation mode expected this — judgment.md §2 — you build to learn.)

---

## Add to CLAUDE.md / ARCHITECTURE.md

```markdown
## Fitness functions (ARCHITECTURE.md) — the characteristics CI must keep green
| Characteristic | Check | Cadence | Where |
|---|---|---|---|
| no cross-module internals | boundary-guard / depcruise | triggered (CI) | ... |
| dependency direction / layering | depcruise / import-linter | triggered (CI) | ... |
| p95 latency < [target] | benchmark test | triggered | ... |
| [reliability SLO] | monitor + alert | continual | ... |

## Evolvability stance (CLAUDE.md)
- Bias toward reversibility: put a seam in; most decisions are two-way doors.
- Genuinely irreversible → decide at the last responsible moment, not early.
- When a settled decision is wrong: evolve under guard (expand-contract / Strangler Fig /
  characterization) with the fitness functions green. Never a big-bang rewrite.
```

## What this does NOT cover (hand off)
```
✗ Data evolution at scale (schema migration strategy, evolutionary DB) → dedicated study + DBA.
✗ Org-scale governance / fitness-function platforms → Building Evolutionary Architectures (the book) + architects.
```
shipright makes the *code* architecture evolvable and names the fitness functions you already have.
Beyond a single deployable's governance, you need the book and senior architects — say so.
