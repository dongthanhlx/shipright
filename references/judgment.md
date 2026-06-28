# Judgment — the executive layer (when NOT to apply a pattern)

> This is the prefrontal cortex of shipright. Boundaries and the quality gate tell you
> WHAT good looks like. This file tells you HOW MUCH of it to apply right now.
> A veteran is defined by judgment, not by knowing more rules.
>
> **The core principle, promoted from a footnote to the top:**
> Senior judgment = knowing when NOT to apply a pattern.

Load this file: at L0 (mode/scope decisions), at every "should I add X?" moment,
and whenever you are tempted to build for a problem that does not exist yet.

---

## 1. The decision that governs everything: reversibility

Every architecture decision is one of two kinds (Bezos's doors):

```
TWO-WAY DOOR (reversible)        ONE-WAY DOOR (irreversible / expensive to undo)
- cheap to change later          - building on it makes it permanent
- decide fast, move on           - get it RIGHT before building on top
- e.g. cache TTL, log format,    - e.g. domain model, ID identity, money units,
  which validation lib, folder     module boundaries, dependency direction,
  names, retry count               public API shape, where state lives (DB vs memory)
```

**Rule:** spend your "do-it-right" budget on one-way doors. Move fast on two-way doors.
Treating a two-way door like a one-way door = over-engineering.
Treating a one-way door like a two-way door = architecture that breaks at scale.

When unsure which kind a decision is, ask: *"If this is wrong, what does fixing it cost
in 6 months — an afternoon, or a migration?"*

---

## 2. The MVP matrix — ship fast WITHOUT breaking architecture

The most common false tradeoff is "fast vs good." It is false because **"good" is not one
thing.** Only a small load-bearing subset must be right at MVP. Classify every candidate
piece of work by **cost-to-do-now × reversibility-later**:

```
                  TWO-WAY DOOR (add later = cheap)   ONE-WAY DOOR (retrofit = expensive)
            ┌────────────────────────────────────┬────────────────────────────────────┐
 CHEAP now  │  DO IF IT HELPS NOW                 │  ALWAYS — even in a rushed MVP       │
            │  • Correlation ID                   │  • The 4 (+1) boundaries             │
            │  • .env schema validation (zod)     │  • Ubiquitous Language / naming      │
            │  • 1 walking-skeleton test          │  • Adapter seam (boundary 4)         │
            ├────────────────────────────────────┼────────────────────────────────────┤
 EXPENSIVE  │  DEFER until a signal fires         │  DO MINIMALLY BUT CORRECTLY          │
 now        │  • full test suite                  │  • core domain model (2–3 entities)  │
            │  • observability stack (OTel)       │  • ID identity, money/units (Decimal)│
            │  • resilience (circuit breaker,     │  • where state lives (DB not memory) │
            │    bulkhead, backpressure)          │  • idempotency key (if side effects) │
            │  • caching, perf tuning             │                                      │
            └────────────────────────────────────┴────────────────────────────────────┘
```

The two right-hand columns are your entire MVP discipline. Hack the rest freely.
An MVP missing a circuit breaker does NOT break architecture (cheap to add).
An MVP leaking raw API responses into the service layer DOES (touches everything to fix).

**Why the boundaries are non-negotiable even at MVP:** they sit in the top-right quadrant —
cheap to follow (just import discipline), permanent if violated. That is the rare
combination that makes them worth enforcing when nothing else is.

---

## 3. The "do I need this yet?" gate — defeating over-engineering

Before adding any abstraction, layer, pattern, or dependency, pass all three:

```
□ Rule of Three (Fowler): is this the THIRD time I'm writing this?
  1st time: write it inline. 2nd time: note the duplication, still inline.
  3rd time: NOW extract the abstraction — you finally know its real shape.
  Abstracting on the 1st instance guesses the shape and usually guesses wrong.

□ YAGNI: is there a CONCRETE need today, or am I building for an imagined future?
  "We might need multi-tenancy someday" → not today → don't build it today.
  A two-way-door decision deferred costs nothing. Build it when the need is real.

□ Cost of carry: does this abstraction cost more to maintain than the duplication it removes?
  An interface with one implementation, a factory that builds one thing,
  a config option no one sets → negative value. Delete / inline it.
```

Exception: the gate does NOT apply to one-way doors. For those, design for change UP FRONT
because retrofitting is the expensive path. (Domain model, boundaries, data identity.)

---

## 4. When to BREAK shipright's own rules

Rules are defaults, not laws. Each has a legitimate exception. Naming the exception
out loud (in a comment or ADR) is the senior move; breaking it silently is not.

```
20-line function    → break it for a flat, linear sequence with no branching that reads
                       top-to-bottom (e.g. a builder, a fixed pipeline). Cohesion > length.
                       Ousterhout: a deep 40-line method with a tiny interface can beat
                       four shallow 10-line methods that fragment one idea.

TDD test-first      → break it for a genuine spike/exploration where you don't yet know the
                       shape. Spike to learn → THROW IT AWAY → re-do test-first. Never ship
                       the spike. (Never break test-first for code with side effects/money.)

4 boundaries        → essentially never. If you think you must, you've found a missing module,
                       not a reason to break the rule. The cost of breaking compounds silently.

Layered architecture → skip it entirely for the "not appropriate" cases below.

DRY                 → prefer a little duplication over the WRONG abstraction. Two things that
                       look similar today but change for different reasons are NOT duplication
                       (that's coincidental similarity — coupling them is the real bug).
```

---

## 5. When the whole workflow is overkill

Senior judgment includes knowing when shipright itself should step back:

```
Throwaway prototype, < 1 week lifespan?     → skip everything, hack freely, delete after.
Script / CLI, < 200 lines, no domain?       → flat functions, no layers, no DI.
Solo, < 3 domain entities, read-only data?   → simple modules, no repository indirection.
One-off data migration / glue script?        → correctness + idempotency only; ignore structure.
Otherwise                                     → use shipright.
```

Applying the full tree to a 50-line script is the same mistake as skipping it on a
payment system — both are failures of judgment, in opposite directions.

---

## 6. How the executive layer drives the two hemispheres

Shipright has two hemispheres (construction + operation). This file decides the **dial**
on each, per lifecycle phase. The resilience/perf dial is almost off at SEED and full at
SCALE; the construction dial (boundaries, naming, domain model) is ON from day one because
it lives in the irreversible quadrant.

```
Phase     Construction dial            Resilience/Operation dial
SEED      boundaries + naming +        OFF — except one-way-door items
(MVP)     core domain model ON         (idempotency, money units, state location)
VALIDATE  + TDD + quality gate         MINIMAL — timeouts + Correlation ID
HARDEN    + Fowler refactoring         FULL Nygard patterns + SLO/error budget (on signal)
SCALE     + Ousterhout deep modules    + bulkheads, backpressure, Strangler Fig
```

See `references/levels.md` for the full lifecycle spine, `references/resilience.md` for the
operation hemisphere, `references/code-health.md` for construction (Bob × Ousterhout).

---

## The one question that encodes this whole file

Before any non-trivial decision, ask:

> **"Is this a one-way door, and is the need real today?"**
>
> One-way + real → do it right, now.
> One-way + not yet → design the seam so it stays reversible, defer the rest.
> Two-way + real → do the simplest thing that works, move on.
> Two-way + not yet → don't build it. Write it down as a debt signal and ship.
