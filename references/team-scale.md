# Team scale — the module boundary IS the team API

> When multiple developers each own one or more modules, a boundary stops being "clean architecture"
> and becomes the **coordination protocol between people**. Same primitive, bigger job.
>
> **Load this ONLY on the multi-dev signal** — more than one person building in parallel, each
> owning module(s). Solo projects skip it entirely: the boundaries already serve you (you are the
> only "team", team = 1). Applying team machinery to a solo MVP is over-engineering (judgment.md).
>
> Masters: **Conway** (systems mirror the org), **Parnas** (information hiding → independent
> development), **Eric Evans** (Context Mapping), **Skelton & Pais — Team Topologies** (team API,
> cognitive load, inverse Conway), **DORA/Accelerate** (loosely-coupled teams+architecture = the
> top predictor of delivery performance).

---

## The one idea: solo and team use the SAME boundary, differently

```
                        Solo                          Team (each dev owns 1+ modules)
index.ts (public API)   seam between YOUR modules     the TEAM API — the contract N devs build on
boundary-guard hook     stops future-you reaching in  stops dev A reaching into dev B's internals
ownership               implicit (you own all)        explicit (owner + interface-change approval)
contract tests          LSP, within a module          + consumer-driven, BETWEEN modules/teams
```

Both draw module boundaries identically. At team scale the *same* boundary additionally carries
ownership, a stable team API, cognitive-load sizing, and cross-team contract tests. These are
**additive and signal-driven — not a different mode.** Solo → team is a dial, not a switch.
(The reframe helps solo too: your future self is "the other dev"; the boundary protects you from
your past self.)

---

## Inverse Conway maneuver — do this at L0 for a multi-dev project

Conway's Law: the system will mirror your org whether you plan it or not. So plan it. **Design the
module boundaries to match the team structure you intend** — then the architecture follows (Skelton
& Pais). This is the strongest possible case for strategic-first (judgment.md): the interfaces
between modules are contracts N people build against, so getting them wrong costs N× the rework.
The design-payoff line (Fowler) arrives *earlier* with more developers.

```
At L0, for a multi-dev project — record in ARCHITECTURE.md:
  Module → owner (a person/team) → its public API (the team API) → who it depends on.
  A module with no clear owner is owned by no one. One owner per module.
  Each module fits ONE owner's head (cognitive load — see below). If it doesn't, split it.
```

---

## Cognitive load — the real module-sizing criterion at team scale (Team Topologies)

SRP tells you *why* to split; cognitive load tells you *how big* a module may be for a team to own
it well. A module a team can't hold in their heads produces bugs and slow changes regardless of how
clean its boundaries are.

```
Size a module so ONE owner (dev or small team) can hold its domain + its dependencies' APIs in head.
Too big / too many dependencies to reason about → split, or introduce a platform module that hides
the complexity behind a simple API (a "platform team" in Team Topologies terms).
Prefer stream-aligned modules (own a slice end-to-end, minimal cross-dependencies) as the default.
```

---

## The team API — the public interface is now a contract

The module's `index.ts` / `__init__.py` is a promise other developers depend on. Changing it is a
**coordination event**, not a local edit.

```
□ The public API is small, stable, and documented (Parnas: hide everything else). Internals change
  freely; the API changes deliberately.
□ Interface-change protocol: a change to a module's public API needs the OWNER's approval (and the
  known consumers'). Add/deprecate — don't break: add the new method, mark the old @deprecated,
  migrate callers, then remove. (Expand–contract; see references/requirement-drift.md.)
□ boundary-guard.sh (references/enforcement.md) IS the team-seam enforcer — it blocks dev A from
  importing dev B's internals, so teams can only couple through the agreed API. Enable it for teams.
```

---

## Context map — how modules/teams relate (Eric Evans)

For each dependency between modules/teams, name the relationship — it sets the coordination cost:

```
Customer–Supplier  — downstream's needs are prioritized in upstream's plan (the common healthy case).
Conformist         — downstream just accepts upstream's model as-is (no leverage to negotiate).
Anti-Corruption Layer — downstream wraps upstream behind an adapter so its model can't leak in
                     (Boundary 4 — use when upstream is messy/external/unstable).
Published Language / Open-Host — upstream offers a stable documented contract many consumers use
                     (a platform module). Shared Kernel — two teams co-own a small shared piece
                     (high coordination cost — keep it tiny, or avoid).
```
Record the map in ARCHITECTURE.md. It tells each dev who they must coordinate with, and how tightly.

---

## Consumer-driven contract tests — parallel teams without breakage

LSP contract tests (code-health.md) check a module's own implementations. At team scale you also
need contracts BETWEEN teams:

```
The consumer (dev A) writes a contract describing what it needs from the provider's (dev B) API.
The provider (dev B) runs that contract in ITS CI. Result:
  • B cannot silently break A — B's CI goes red if it violates the contract.
  • A cannot depend on undocumented behavior — only what the contract states.
Tools: Pact (consumer-driven), or plain shared interface + tests against a fake that both sides use.
This is what lets N teams evolve N modules in parallel without a merge/integration crisis.
```

---

## Parallel-work mechanics (keep it loosely coupled — DORA)

```
□ Trunk-based development + short-lived branches (< 1–2 days). Long branches = merge hell across modules.
□ Feature flags to merge unfinished work safely behind the flag (integrate continuously, release later).
□ Module-level CI: each module's tests run independently — a red module blocks only itself (scaling-guide Stage 2).
□ Internal event bus for cross-module NOTIFY (fire-and-forget) instead of synchronous coupling
  (scaling-guide Stage 1) — reduces the number of interfaces devs must coordinate on.
□ Separate DB schemas per module (not separate DBs) — data isolation without operational cost.
```
DORA's finding: *loosely-coupled architecture + teams* (independent test & deploy) is the strongest
predictor of delivery performance — bigger than any tool choice. Optimize for that, not for microservices.

---

## Don't extract to services prematurely (scaling-guide governs this)

A well-bounded **modular monolith serves most multi-team products** (Shopify, Basecamp). Extract a
module to its own service only when ALL of: it has a dedicated team, a different deploy cadence, and
a 10x-different scaling profile (scaling-guide.md Stage 3 + Strangler Fig). Team Topologies + Conway,
not raw code size, decide extraction. Microservices solve *organizational* scale, not technical scale
alone.

---

## Add to CLAUDE.md / ARCHITECTURE.md for a multi-dev project

```markdown
## Module ownership (ARCHITECTURE.md)
| Module | Owner | Public API (team API) | Depends on | Context-map relation |
|--------|-------|-----------------------|------------|----------------------|
Rule: changing a module's public API needs the owner's + known consumers' approval. Add–deprecate,
never break. boundary-guard hook enabled — cross-module coupling only through the public API.

## Team conventions (CLAUDE.md)
- Trunk-based; branches < 2 days; feature-flag unfinished work.
- Consumer-driven contract test for every cross-module dependency; provider runs it in CI.
- Size modules to one owner's cognitive load; split or add a platform module when it exceeds that.
```

---

## What this file does NOT do (hand off)

```
✗ Org design / hiring / team charters — that's leadership, not a coding skill (Team Topologies the book).
✗ Distributed transactions / service mesh — see scaling-guide.md "does not cover" + specialists.
```
shipright makes the module boundary work as both the architecture and the team API. Beyond team-of-teams
org design, you need Team Topologies practitioners and engineering leadership — say so.
