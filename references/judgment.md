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

**Temper this with evolutionary humility (you can't perfectly predict, and you WILL be wrong):**
- **Bias toward reversibility.** Bezos: most decisions are two-way doors. A seam (repository behind
  an interface, an Adapter/ACL, a module behind its index) TURNS a one-way door into a two-way one —
  so the cheapest move is often "make it reversible", not "get it perfect". The boundaries are an
  evolvability technique, not just a cleanliness one.
- **For the genuinely irreversible, decide at the LAST RESPONSIBLE MOMENT** (Poppendieck) — "as long
  as you can, but no longer". Delaying buys information that reduces the chance of being wrong; that
  is not procrastination. "Decide early" is right only when the decision heavily constrains others.
- **When a one-way-door decision turns out wrong** (the domain model often does): evolve it under
  guard — don't freeze, don't big-bang rewrite. See `references/evolutionary-architecture.md` (fitness
  functions + the recovery path). The seam you built to get it right is what lets you fix being wrong.

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

### "MVP-first" is a speed *consequence*, not a licence to be sloppy — two real modes

The masters are split on MVP-first for a reason: it depends on which mode you're in. Distinguish them.

```
VALIDATION mode (Eric Ries) — you don't yet know if anyone wants this.
  The MVP is a LEARNING vehicle, expected to be thrown away. Minimum to test the hypothesis.
  Here, trading design for speed is correct — you may delete it next week.

FOUNDATION mode (most projects) — the direction is known; this will live and grow.
  This is NOT "hack an MVP". It is Alistair Cockburn's *walking skeleton done right*: the thinnest
  slice that runs end-to-end, with the load-bearing architecture correct. Thin ≠ tactical.
```

**Why Foundation is not "ship dirty" (Fowler's Design Stamina Hypothesis):** the "design payoff
line" — where good design overtakes no-design on *cumulative delivered features* — arrives "in weeks,
not months". Above it, skipping design ships you *later*, not sooner. So for anything that lasts,
strategic-on-the-irreversible is the *faster* path, not a tax. shipright's mechanism is strategic;
its "MVP-first" name oversells the speed story — read it as *"strategic where it's irreversible,
tactical only where it's genuinely reversible AND cheap."*

### The Ousterhout guard — boundaries stop STRUCTURAL rot, not LOCAL complexity

Getting the one-way doors right is necessary, not sufficient. A 200-line tangled service that
respects every boundary is still a mess — the "tactical tornado" ships fast and leaves a wake
(Ousterhout). Complexity accumulates from many small tactical choices, none individually wrong.
So even in the "hack the rest" column, keep the *strategic-programming* habit: deep modules, clear
names, define errors out of existence (references/code-health.md). "Working code isn't enough."
This is a continuous ~10–15% investment, not a phase — it is what keeps the payoff line in your favor.

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

## 3b. The discipline of STOPPING — Definition of Done + "good enough"

The executive layer must decide not just *what to build* but *when a thing is DONE*. Knowing when
good-enough is good enough — and shipping — is the most senior discipline of all, and the natural
counterweight to everything else in this file. Masters: **Hunt & Thomas** (*The Pragmatic Programmer*
— "Good-Enough Software"), **Ryan Singer** (*Shape Up* — appetite, scope hammering), **Pareto** (80/20),
**Kent Beck** (make-it-work → make-it-right → make-it-fast), the Poppendiecks (gold-plating = waste).

```
"Done" = good enough for its purpose and stakes — NOT perfect. Decide the quality bar UP FRONT,
with the user (it's a requirements decision — Hunt & Thomas), so "good enough" is an explicit target,
not an excuse. "Good" is relative: better than what they have now, not an imaginary ideal.
```

**The keystone — cut SCOPE, not QUALITY** (this is what keeps "good enough" from becoming "sloppy"):
```
The quality FLOOR is never hammered:  the 5 boundaries · the one-way doors · the quality gate ·
                                      test-through-the-public-interface. These hold, always.
The VARIABLE is scope:                features, edge cases, polish, nice-to-haves. HAMMER these to
                                      fit the appetite. Ship a smaller COMPLETE thing, never a larger
                                      half-broken one (Shape Up + the McBreen guard).
```
This is Shape Up's *scope hammering* — and shipright already has the structure for it: the boundaries
and one-way doors ARE the floor; everything else is hammerable. Naming it completes the discipline.

**Appetite is a fixed budget** (Shape Up): *"appetite starts with a number and ends with a design."*
When the budget is spent, mark the rest nice-to-have and ship — don't blow the budget to gold-plate.
Done = the core journey works + the appetite is spent, NOT "every feature is built".

**Stop at the right point — via feedback, not feel.** Hunt & Thomas: stopping TOO EARLY (misses the
need) is actually *more common* than gold-plating — and both are corrected the same way: **real user
feedback** (the SHIP GATE). Ship to learn; don't polish in the dark.

**The stopping tests — ask before the next hour of work:**
```
□ Does this next hour add CONFIDENCE or VALUE — or only POLISH? (Pareto: the last 20% costs the most.)
□ Is the JOB done (the one from intake) — or am I building past it?
□ Am I gold-plating — covering cases no real user has, "just in case"? (YAGNI / waste — §3.)
□ Would a real user call this "a clear improvement over what they have"? If yes → ship, then iterate.
```

shipright already stops in many places — name them as this one discipline: **L4 is signal-driven**
(don't optimize without data), the **tech-debt log with triggers** is a *deliberate* stop ("we stop
here on purpose, revisit on [trigger]" — not a failure), **rule-of-three** stops premature abstraction,
the **SHIP GATE** is the done-check, and **Beck's sequence** stops most work after "right" (make-it-fast
only on an L4 signal). The floor holds; the scope flexes; you ship.

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
Static / marketing / landing site?           → the UI/UX floor is the job; the backend 5-boundaries mostly
                                               don't apply — don't over-architect it (see §5b).
Otherwise                                     → use shipright.
```

Applying the full tree to a 50-line script is the same mistake as skipping it on a
payment system — both are failures of judgment, in opposite directions.

---

## 5b. Which FLOOR does this project need? — balancing system vs experience by shape

The two hemispheres (construction + operation) are the CODE dials. But a project also has a SHAPE, and
the shape decides the mix of **two floors** — both are "do it right", neither is optional *when it
applies*, and the classic mistake is developing one while neglecting the other:

- **System floor** (architecture): the 5 boundaries, layering, domain model, resilience, tests. Backend-shaped.
- **Experience floor** (UI/UX — `references/ui-design.md`): a11y, responsive/mobile, information
  architecture, audience/emotion fit, the state-floor. Front-of-house-shaped.

```
Backend / API / CLI / data pipeline    → System floor IS the job. No experience floor (nothing to design).
Static / marketing / landing / brochure→ Experience floor IS the job. The backend 5-boundaries mostly
                                         DON'T apply — service/repo/module-db on a static site is
                                         over-engineering. (The frontend still holds its LIGHT architecture:
                                         components carry no business logic, data-fetching in hooks — no more.)
Full-stack product (SaaS, marketplace) → BOTH floors, integrated. The API gets the 5 boundaries; the UI
                                         gets the experience floor; the API contract is the seam where they
                                         meet. Neither is a bolt-on to the other.
```

The failure is imbalance in EITHER direction: over-architecting a landing page (system machinery it will
never need), OR treating a product's UI as an afterthought once the "real" backend is done. On a
full-stack product the experience floor is **not** lower-priority than the architecture floor — it is the
other half of the same product. A veteran weights both by shape, not by which one they find more fun.

**Per task, not just per project — the two alternate over time.** A full-stack build is not "do all the
system, then all the UI." You switch between them task by task (an API endpoint, then its screen, then a
background job, then a landing section). So detect the CURRENT task's mode every time and switch what you
ask and how you handle it: a **system task** gets the system questions (domain, boundaries, API contract,
data identity) and the system floor; an **experience task** gets the design brief (audience, feeling,
voice, content — `references/ui-design.md`) and the UI/UX floor. Don't run a UI task through a
boundaries-and-repository intake, or interrogate an API endpoint about brand voice. Branch B's Step 3
makes this the first fork of every feature.

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

> **Before you build it:** "Is this a one-way door, and is the need real today?"
>
> One-way + real → do it right, now.
> One-way + not yet → design the seam so it stays reversible, defer the rest.
> Two-way + real → do the simplest thing that works, move on.
> Two-way + not yet → don't build it. Write it down as a debt signal and ship.
>
> **Before you keep polishing it:** "Is this good enough for the appetite — or am I gold-plating?"
>
> Job done + core works → ship it, get feedback (the floor held; hammer the rest to nice-to-have).
> Not yet good enough → cut SCOPE to reach done, never cut the quality floor.
> Still polishing past the job → stop. The last 20% costs the most and no user asked for it.
