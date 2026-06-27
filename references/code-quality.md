# Code Quality — Uncle Bob, Fowler, and Eric Evans

## Why three masters, not one

Uncle Bob defines **how code should be structured** (SOLID, Clean Code).
Fowler defines **how code should evolve** (Refactoring, patterns, internal quality).
Eric Evans defines **what code should model** (DDD — the domain, the language, the boundaries).

Three different dimensions. A project can fail at any one of them independently:
- Perfect SOLID but wrong domain model → technically clean but solving wrong problem
- Perfect domain model but spaghetti implementation → correct intent, unmaintainable code
- Both correct but accumulated smells → starts clean, rots over time

Shipright enforces all three, in order: domain model first (Evans), then structure (Uncle Bob), then evolution (Fowler).

---

## Layer 1: Eric Evans — Domain-Driven Design

### Why DDD comes first

"The heart of software is its ability to solve problems in a subject area. Everything else is auxiliary." — Evans

Before writing code, the team must agree on the domain model. If the model is wrong,
no amount of SOLID principles or refactoring will save it. AI makes this worse:
Claude generates code fast — if domain model is vague, it generates vague code fast.

### Ubiquitous Language — the most important DDD concept for AI coding

Ubiquitous Language is a shared vocabulary used by everyone: domain experts, developers,
and crucially — Claude Code. When the language is consistent, Claude doesn't hallucinate
terms. When it's inconsistent, Claude invents its own terms.

**Add to CLAUDE.md at L0 (always):**
```markdown
## Ubiquitous Language — terms used everywhere in this codebase

| Term | Meaning | NOT |
|---|---|---|
| [domain term] | [precise definition] | [technical alias to avoid] |

Rules:
- Class names, method names, variable names MUST use these terms
- Never use generic names (Manager, Handler, Processor, Helper, Utils)
  when a domain term exists
- If Claude uses a term not in this list → wrong, stop and align
- When domain expert uses a new term → add here before coding it
```

**Why this matters for AI:** Claude generates names based on patterns it has seen.
Without Ubiquitous Language in CLAUDE.md, it defaults to generic technical names
(UserManager, DataProcessor) that don't reflect the domain. With the language defined,
it generates domain-expressive code (OrderFulfillmentPolicy, CrawlQuotaGuard).

### Tactical DDD — building blocks (use selectively, not everywhere)

**Entity:** Has unique identity that persists over time. Identity matters, not attributes.
```typescript
// Entity — identified by id, not by its fields
class Order {
  readonly id: OrderId  // identity
  status: OrderStatus   // can change
  items: OrderItem[]    // can change

  // Wrong: equals by value
  // Right: equals by id only
  equals(other: Order): boolean { return this.id.equals(other.id) }
}
```

**Value Object:** Defined by its attributes. No identity. Immutable.
```typescript
// Value Object — no id, immutable, equality by value
class Money {
  constructor(
    readonly amount: number,  // integer cents — never float
    readonly currency: Currency
  ) { Object.freeze(this) }

  add(other: Money): Money {
    if (!this.currency.equals(other.currency)) throw new CurrencyMismatchError()
    return new Money(this.amount + other.amount, this.currency)
  }
  // No setters. Returns new instance for any "change."
}
```

**Aggregate:** Cluster of objects treated as a unit. One Aggregate Root controls access.
```typescript
// Aggregate — Order is the root, OrderItem cannot exist without Order
class Order {  // ← Aggregate Root
  private items: OrderItem[] = []  // internal, not exposed directly

  addItem(product: Product, quantity: Quantity): void {
    // invariant: Order has at most 50 items
    if (this.items.length >= 50) throw new OrderTooLargeError()
    this.items.push(new OrderItem(product.id, product.price, quantity))
  }

  // Repository only saves/loads Order (root), never OrderItem directly
}
```

**Repository:** Provides collection-like interface to Aggregate. Hides persistence.
```typescript
// Repository — domain interface, not a DB wrapper
interface IOrderRepository {
  findById(id: OrderId): Promise<Order | null>
  save(order: Order): Promise<void>
  findByCustomer(customerId: CustomerId): Promise<Order[]>
}
// Implementation in infrastructure layer — never in domain
```

**Domain Service:** Stateless operation that doesn't fit on a single Entity.
```typescript
// Domain Service — when operation spans multiple Aggregates
class QuotaEnforcementService {
  canCrawl(source: Source, requestedUnits: number): boolean {
    // spans QuotaAggregate and SourceAggregate
    // not on either one — belongs to a service
  }
}
```

### When NOT to use DDD

DDD is not a silver bullet. Evans himself warned against over-engineering.

```
Use DDD tactical patterns when:
  □ Domain has complex business rules and invariants
  □ Multiple concepts interact with distinct lifecycles
  □ Domain experts have rich vocabulary worth preserving

Skip DDD tactical patterns when:
  □ Simple CRUD (Create, Read, Update, Delete) — just use repository + plain types
  □ Script / CLI / utility — flat functions are fine
  □ Data pipeline / ETL — functional composition is better
  □ Project < 3 domain entities with no complex rules

Over-engineering signal: you have AbstractEntityFactoryRepository
for something that's just a list of users. Stop.
```

### Bounded Context — strategic DDD (for larger projects)

A Bounded Context is a linguistic boundary where a specific model applies.
The same word can mean different things in different contexts.

```
Example: "Account"
  In Billing context: Account = payment method, credit balance
  In Auth context:    Account = user credentials, permissions
  → Same word, completely different models

Shipright's modules (from ARCHITECTURE.md) ARE Bounded Contexts.
Module boundary = Bounded Context boundary.
Each module has its own model, its own Ubiquitous Language section.
```

**Anti-Corruption Layer (ACL):** Translation layer between Bounded Contexts.
This is exactly what Shipright's Boundary Rule 4 (Adapter layer) implements.

```
Evans (Jan 2026) on LLMs: "When we call an LLM, we're bridging between
our deterministic application and a probabilistic system — fundamentally
different computational models. An ACL is appropriate here."

→ Shipright's ResponseAdapter in ai-rag.md IS the ACL Evans describes.
→ PlatformAdapter in chatbot-platforms.md IS the ACL for Telegram/Discord.
```

---

## Kent Beck's TDD — precedes everything else

"Test-Driven Development is not about testing. It's about design."

Write the test first. This is not optional, not a best practice — it is the workflow.
A test written after implementation is a test for code that was not designed to be tested.

### Red → Green → Refactor

```
RED:     Write a test that fails (the desired behavior doesn't exist yet)
GREEN:   Write minimum code to make it pass (no more, no less)
REFACTOR: Clean up without breaking the test (apply SOLID + Fowler)
```

### When to write tests in shipright's L0→L4

```
L0 (constitution): configure test runner (Jest/pytest/Foundry/Anchor)
L1 (skeleton):     1 end-to-end test that proves skeleton works → RED → implement → GREEN
L2 (interfaces):   all interface contracts as tests → RED → implement → GREEN
L3 (each feature): test each behavior before coding it
Branch B (add feature): test before implement, regardless of complexity tier
Branch D (refactor): characterization tests FIRST, before changing anything
```

### What counts as "written first"

The test must FAIL before you write the implementation.
If you can't run the test and see it fail → you haven't written it first.

### Exceptions (narrow, specific)

```
Config change (env var, constant): no test needed
Pure UI layout change (no logic): no test needed
Exploratory spike (throw-away): no test needed — but delete the spike
```

Everything else: test first.

---

## Layer 2: Uncle Bob — SOLID + Clean Code

### 5 SOLID principles as checkpoints (enforce at every L3 commit)

**S — Single Responsibility Principle**
```
Signal: function > 20 lines, method name has AND/OR, class > 200 lines
Check: "Can you explain this function in one sentence without AND?"
Fix: extract to separate function with domain-expressive name

AI tendency: combines responsibilities in one function "for completeness"
Prevention in CLAUDE.md: "Functions do ONE thing. Max 20 lines.
Names describe what they do — never processAndSave(), fetchAndNormalize()."
```

**O — Open/Closed Principle**
```
Signal: adding new type requires changing existing switch/if-else
Check: "Does adding [new thing] require modifying existing code?"
Fix: extract interface, create new class implementing it

AI tendency: adds to existing switch "it's simpler"
Prevention in CLAUDE.md: "New source type = new class implementing ICrawler.
Zero changes to existing crawlers."
```

**L — Liskov Substitution Principle**
```
Signal: instanceof check before method call, throws NotImplementedError
Check: "Can all implementations of this interface pass the same test suite?"
Fix: split interface (see ISP) or redesign contract

AI tendency: generates partial implementations that throw
Prevention: write same tests for all interface implementations — LSP test pattern
```

**I — Interface Segregation Principle**
```
Signal: interface has methods some implementations don't need
Check: "Is every method used by every caller of this interface?"
Fix: split into smaller focused interfaces

AI tendency: generates "complete" fat interfaces upfront
Prevention in CLAUDE.md: "Interfaces are small and focused.
IReader and IWriter are separate. No god interfaces."
```

**D — Dependency Inversion Principle**
```
Signal: service imports concrete db/http class directly
Check: "Does high-level module depend on low-level detail?"
This IS Boundary Rule 1 (dependencies point inward) — already enforced.
But explicitly: service depends on IOrderRepository (interface), not PostgresOrderRepository
```

### Clean Code rules (encode in CLAUDE.md at L0)

```markdown
## Clean Code rules (Uncle Bob)

Functions:
- Max 20 lines. Extract if longer.
- Names are verbs describing ONE action (never fetchAndNormalize)
- Arguments: 0–2 preferred, max 3. Use object/config for 4+

Names:
- Variables/functions: reveal intent (never: d, tmp, data, info, manager)
- Booleans: is/has/can prefix (isActive, hasPermission, canProcess)
- No abbreviations unless universally known (URL, ID, HTTP are OK)

Comments:
- NO comment that explains WHAT (rename the code instead)
- YES to comments explaining WHY (non-obvious business reason)
- No commented-out code — use git history instead

Files:
- Max 300 lines. If longer → split module.
- One concept per file. Not "utils.ts" with 30 unrelated functions.
```

---

## Layer 3: Fowler — Refactoring and Internal Quality

### 7 smells to detect at every commit (Fowler's catalog)

```
After every feature implementation, scan for these before committing:

□ Long Method (> 20 lines)
  → Extract Method: give it a domain-expressive name

□ Feature Envy (method uses more from another class than its own)
  → Move Method: it belongs to the class it envies

□ Primitive Obsession (string/int where domain type should be)
  → Replace Primitive with Value Object: Money, Email, OrderId

□ Divergent Change (one class changes for many different reasons)
  → Extract Class: SRP violation at class level

□ Shotgun Surgery (one change requires edits in many files)
  → Move Field/Method: consolidate related behavior

□ Data Clumps (same 3+ fields always appear together)
  → Extract Class or Value Object: they belong together

□ Comments explaining WHAT (not why)
  → Rename: the name should make the comment unnecessary
```

### Internal quality pays off in weeks, not months (Fowler)

```
Fowler's finding: high internal quality leads to FASTER delivery.
"The only way to go fast is to go well." — Uncle Bob

With AI coding: debt compounds even faster.
Claude generates code at 10x human speed.
Without quality gates, technical debt accumulates at 10x speed too.

Signal: "Adding features is getting slower" → Fowler smells have accumulated
Action: refactoring session (Branch D) — characterization tests first, always
```

---

## Quality Gate — run before every commit

### Automated checks (add to CI)

```bash
# Boundary checks (Shipright original)
grep -r "shared/db" src/modules/ && exit 1      # Boundary Rule 1
grep -r "from.*modules/.*/(?!index)" src/ && exit 1  # Boundary Rule 2
npx tsc --noEmit                                # Type safety

# SOLID + Clean Code checks
find src/ -name "*.ts" -exec awk 'END{if(NR>300) print FILENAME": "NR" lines"}' {} \;
# (flag files > 300 lines for review — not auto-fail, needs human judgment)
```

### Manual checklist (Claude Code runs before suggesting commit)

```
DDD checks:
□ All new class/method/variable names from Ubiquitous Language in CLAUDE.md?
□ New Entity has id field and equals-by-id?
□ New Value Object is immutable (Object.freeze or readonly)?
□ Repository interface in domain, implementation in infrastructure?
□ Any cross-module direct import (not via index.ts)?

SOLID checks:
□ Any function > 20 lines? → extract
□ Any AND/OR in function name? → split
□ Any instanceof check in business logic? → redesign contract
□ New type added by modifying existing switch? → new class instead
□ Any fat interface with unused methods? → split

Fowler smell checks:
□ Feature Envy? (method uses another class's data more than own)
□ Primitive Obsession? (string/int where domain type belongs)
□ Shotgun Surgery risk? (this change required edits in 3+ files)
□ Any "// what" comment? → rename instead
```

---

## Compound Engineering — CLAUDE.md learns from mistakes

After every violation caught by quality gate → add specific rule to CLAUDE.md:

```markdown
## Learned rules (added from quality gate violations)

[DATE] AI generated: processOrderAndNotifyUser()
→ Rule: "Order processing and notifications are always separate methods.
   processOrder() and notifyUser() are never combined."

[DATE] AI used string for money amount
→ Rule: "Money is always Money value object with integer cents.
   Never string, never float, never number for money."

[DATE] AI added new Source type by modifying switch in CrawlerFactory
→ Rule: "New source type = new class implementing ICrawler.
   CrawlerFactory uses registry pattern — never switch on type."
```

This is how shipright enables Compound Engineering:
CLAUDE.md starts minimal at L0, grows smarter with each project session.
By month 3, CLAUDE.md encodes all project-specific patterns.
AI makes the same mistake twice: extremely rare.

---

## Evans + Uncle Bob + Fowler together

The three masters complement without conflict:

```
Evans asks: "Are we modeling the right thing?"
  → Ubiquitous Language, Bounded Contexts, Aggregates

Uncle Bob asks: "Is the code structured correctly?"
  → SOLID, Clean Code, dependency direction

Fowler asks: "Is the code staying clean as it evolves?"
  → Smell detection, refactoring discipline, internal quality investment

Shipright enforces:
  L0: Evans (Ubiquitous Language in CLAUDE.md, domain types in ARCHITECTURE.md)
  L2: Uncle Bob (interfaces follow SOLID, ISP in design)
  L3: Uncle Bob + Fowler (quality gate before every commit)
  Branch D: Fowler (smell-driven refactoring with characterization tests)
  Compound Engineering: all three (CLAUDE.md learns from every violation)
```
