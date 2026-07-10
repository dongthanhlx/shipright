# Testing — the strategy (not a religion), and why shipright's boundaries already are one

> The goal of a test is **confidence + good design** — not a test-first ritual, not a coverage number.
> Even shipright's TDD master says so: Kent Beck wrote his **Test Desiderata** precisely to counter
> the dogma of "one true kind of test", and in the *Is TDD Dead?* debate concluded *"almost no
> question in CS can be answered A or B — the answer starts with 'it depends'."*
>
> Masters: **Kent Beck** (TDD + Test Desiderata), **Martin Fowler** (Test Pyramid, *Mocks Aren't
> Stubs*, coverage-is-a-guide), **Mike Cohn** (the Pyramid), **Kent C. Dodds** (the Testing Trophy —
> *"write tests, not too many, mostly integration"*), **DHH** (test-induced design damage),
> **Gerard Meszaros** (xUnit test smells). Load this whenever writing or reviewing tests. Mechanics
> (the RED→GREEN loop, framework setup) → dispatch to addyosmani `test-driven-development`.

---

## TDD: the strong default for logic — a tool, not a religion

Test-first is the default for any code with logic or behavior, because it buys three real things:
**design pressure** (hard-to-test code is usually badly-designed code), a **safety net** (change
without fear), and **confidence**. shipright keeps RED→GREEN→Refactor as the default.

But hold it as Beck himself does — pragmatically, not absolutely:
```
Test-first (default)        — anything with a decision, a rule, a calculation, a transformation.
Spike / exploration         — you don't yet know the shape → spike WITHOUT tests to learn, then
                              THROW IT AWAY and redo test-first. Never ship the spike.
Genuinely trivial           — config/copy/one-line wiring with no logic → a test adds no confidence.
                              Don't perform the ritual on code that can't meaningfully fail.
Never for money/side-effects — test-first is non-negotiable where a bug is irreversible (payments,
                              migrations, smart contracts).
```
The honest exception is narrow — it is not "skip tests when busy". The goal is confidence; if a test
gives none, it's ceremony; if it gives confidence, write it first.

---

## The keystone: shipright's boundaries ARE the test strategy

Two rules prevent the brittle, over-mocked tests that make people abandon testing — and shipright's
architecture already hands them to you:

```
1. Test BEHAVIOR through the public interface (index.ts / __init__.py), NOT the implementation.
   A test that pokes at internals breaks every time you refactor — that brittleness is why people
   quit TDD (and why DHH felt "test-induced damage"). Test what the module PROMISES, not how it
   keeps the promise. shipright's public API is exactly that promise → test through it. (This is also
   why the boundary is the team API in v1.8: the same seam you test through, teams build against.)

2. Mock only at the SEAMS — never internal collaborators (Fowler's classicist position).
   Mock the things the boundaries already isolate: the repository interface, the Adapter/ACL, and
   external systems (DB, HTTP, LLM, gateway). Do NOT mock domain objects or a service's internal
   helpers — that couples the test to the implementation and warps the design to make mocking
   possible (exactly DHH's test-induced damage). Over-mocking is the #1 test smell.
```
So: **test outside-in through the public API; mock at the boundary seams; leave the inside alone.**
The boundaries tell you precisely where those seams are.

---

## Shape: pyramid by default, trophy when it fits (both are tools, not commandments)

```
Test Pyramid (Cohn — default):     many fast solitary UNIT tests (domain logic, services with mocked
                                   repo) · fewer INTEGRATION tests (real DB/adapters) · few E2E.
                                   Optimizes speed + isolation. Best for logic-heavy backends.

Testing Trophy (Dodds):            static analysis (types/lint) as the base, INTEGRATION as the
                                   biggest layer, fewer unit, few E2E. "The more your tests resemble
                                   the way the software is used, the more confidence they give."
                                   Best for thin services / glue / UI where units are trivial and the
                                   value is in the collaboration.
```
Pick by where the risk lives: rich domain logic → pyramid; thin orchestration / UI → trophy-shaped.
Don't argue the taxonomy — put tests where a bug would actually hurt, at the level that catches it cheapest.

---

## What makes a GOOD test (Kent Beck's Test Desiderata — as sliders, not laws)

Trade these consciously; give one up only for more of another:
```
Fast · Isolated (order-independent) · Deterministic (same input → same result) · Readable (states its
intent) · Writable (cheap vs the code it covers) · Behavioral (tests behavior, not structure) ·
Structure-insensitive (survives refactoring) · Specific (one failure → one cause) · Automated ·
Composable · Predictive (green ⇒ prod works) · Inspiring (green earns trust).
```
The two that matter most for durability — **behavioral + structure-insensitive** — are bought by the
keystone above (test through the public interface). A test that fails when you rename a private method
has neither.

## What NOT to test
```
✗ Getters/setters, trivial mappers, framework internals, third-party library internals.
✗ The same logic at three levels (test it once, at the level that owns it).
✗ Exact LLM output strings (non-deterministic — assert structure/constraints; see ai-rag.md).
✗ 100% coverage as a target — coverage is a GUIDE not a goal (Fowler); chasing it produces
  low-value tests. Untested critical paths matter; untested getters don't.
```

---

## The map — shipright's testing tactics, unified under this strategy

Each existing piece is a specialized application of the rules above:
```
RED interface tests (L2)             → levels.md — behavior specs before implementation (test-first).
LSP contract tests (a module's impls)→ code-health.md — all implementations honor the interface.
Consumer-driven contract tests       → team-scale.md — cross-team: provider can't break consumer.
Characterization tests               → branches/d-refactor.md — pin current behavior before refactor.
Fault-injection tests                → resilience.md — prove degradation, not just the happy path.
Property-based / invariant tests     → stacks/blockchain.md — fuzz thousands of sequences (Foundry/Echidna).
Eval-as-tests (probabilistic)        → stacks/ai-rag.md, ai-agent.md — trajectory/faithfulness, not strings.
Fixtures from real API responses     → third-party-apis.md — offline, deterministic adapter tests.
Bug-reproduction test (RED first)    → branches/c-fix-bug.md — prove the bug, then fix (Prove-It).
```
All obey: test behavior through the seam, mock only at the seams, put the test where the risk is.

---

## Add to CLAUDE.md
```markdown
## Testing conventions
- Test-first for logic (RED → GREEN → Refactor). Goal = confidence + design, not coverage %.
- Test BEHAVIOR through the module's public interface — never its internals (survives refactoring).
- Mock only at the seams: repository interface, Adapter/ACL, external systems. Never internal collaborators.
- Shape: [pyramid | trophy] because [where the risk lives]. Put the test at the level that catches the bug cheapest.
- Non-deterministic (LLM): assert structure/constraints, never exact output.
```

## Hand-off
Test mechanics (framework config, the RED→GREEN loop, runners) → addyosmani `test-driven-development`.
Deep test-smell refactoring → Meszaros's *xUnit Test Patterns*. This file owns the STRATEGY; the skill owns the HOW.
