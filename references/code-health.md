# Code Health — SOLID + Fowler Enforcement

Shipright loads this file at 3 specific moments:
1. L2 — when designing interfaces (OCP, LSP, ISP checks)
2. L3 — before every commit (SRP signals, Fowler 7 smells)
3. Branch D — when refactoring (Fowler catalog)

This is not theory. Every check is concrete, binary, and actionable.

---

## Uncle Bob — SOLID: where each principle is enforced

### DIP — Dependency Inversion (enforced via 4 boundary rules — already in shipright)
Source code dependencies point INWARD only.
Service depends on IRepository interface, never on concrete PostgresRepository.
This is shipright's existing boundary rules. Nothing to add here.

### SRP — Single Responsibility (enforce at L3, per class/method)

"A module should have one, and only one, reason to change."
Not "one thing" — one REASON TO CHANGE. Who triggers a change to this class?

```
SRP signals — check before writing each class:

□ File > 200 lines?
  → likely doing 2 jobs → extract one responsibility

□ Class has > 7 public methods?
  → too many responsibilities for one class → split

□ Method name contains "and" / "or" / "also"?
  processAndSave()     → split into process() + save()
  validateOrThrow()    → acceptable (one decision)
  fetchAndNormalize()  → split into fetch() + normalize()

□ "I need to change this class when X changes AND when Y changes"?
  → 2 reasons = 2 classes

□ Constructor takes > 4 dependencies?
  → class is doing too much → extract sub-services

Action: if any signal fires → extract before implementing logic.
Extracting after is 3x harder.
```

### OCP — Open/Closed (enforce at L2, when designing interfaces)

"Open for extension, closed for modification."
Adding a new type = adding a new class. Zero changes to existing code.

```
OCP gate — ask when designing each interface at L2:

"If I need to add a new [type], do I modify existing code?"

YES → design is wrong. Fix before implementing.
NO  → OCP respected. Proceed.

Concrete test:
□ Adding new source (YouTube, Reddit) = new class, zero changes to CrawlerService?
□ Adding new payment method = new class, zero changes to CheckoutService?
□ Adding new notification channel = new class, zero changes to NotificationHandler?

Bad design (violates OCP):
  class CrawlerService {
    async fetch(type: 'google' | 'youtube') {  // ← must modify this when adding Reddit
      if (type === 'google') ...
      if (type === 'youtube') ...
    }
  }

Good design (respects OCP):
  interface ICrawler { fetch(): Promise<FeedItem[]> }
  class GoogleCrawler implements ICrawler { ... }
  class YouTubeCrawler implements ICrawler { ... }
  class RedditCrawler implements ICrawler { ... }  // ← add new class, touch nothing else
```

### LSP — Liskov Substitution (enforce at L2 via contract tests)

"Subtypes must be fully substitutable for their base types."
If I swap implementation A for implementation B, behavior must be identical.
Violation: implementation throws where interface says it should return empty.

```typescript
// LSP contract test template — write once, run for ALL implementations
// Add to L2 when defining each interface

function contractTest(impl: ICrawler, name: string) {
  describe(`LSP contract: ${name}`, () => {
    it('fetch() always returns FeedItem[] — never null or undefined', async () => {
      const result = await impl.fetch()
      expect(Array.isArray(result)).toBe(true)
      expect(result).not.toBeNull()
    })

    it('fetch() on quota exceeded → returns [] not throws', async () => {
      // Arrange: exhaust quota
      const result = await impl.fetch()  // with mocked quota service returning 0
      expect(result).toEqual([])         // degrade gracefully — never throw
    })

    it('fetch() items conform to FeedItem schema', async () => {
      const items = await impl.fetch()
      items.forEach(item => {
        expect(item.id).toBeDefined()
        expect(typeof item.title).toBe('string')
        expect(item.publishedAt).toBeInstanceOf(Date)
      })
    })
  })
}

// Run for every implementation — same tests, different class
contractTest(new GoogleCrawler(mockQuota), 'GoogleCrawler')
contractTest(new YouTubeCrawler(mockQuota), 'YouTubeCrawler')
contractTest(new MockCrawler(), 'MockCrawler')
```

LSP violation signals:
```
□ Any implementation throws NotImplementedError for interface method?
  → Interface too fat (ISP violation) OR wrong hierarchy (LSP violation)

□ Implementation returns null where interface promises FeedItem[]?
  → LSP violation — fix return type or change to return []

□ Caller needs to check which implementation before calling method?
  if (crawler instanceof GoogleCrawler) ...  → LSP violation
  → All implementations must behave identically from caller's perspective
```

### ISP — Interface Segregation (enforce at L2, before finalizing interfaces)

"Clients should not be forced to depend on interfaces they do not use."
Fat interface = implementations must implement methods they don't need.

```
ISP signals — check every interface at L2:

□ Any implementation has methods that:
  - throw NotImplementedError
  - return null/empty with no logic
  - have a TODO comment
  → Interface is too fat → split it

□ Different callers use completely different subsets?
  AdminService uses: createUser, deleteUser, suspendUser
  AuthService uses: findById, validatePassword, updateLastLogin
  → Split: IUserAdmin + IUserAuth

□ Interface has > 5 methods?
  → Examine: do all callers need all methods? If not → split

Before split:
  interface IUserService {
    createUser(data): Promise<User>    // used by admin
    deleteUser(id): Promise<void>      // used by admin
    findById(id): Promise<User>        // used by auth
    validatePassword(id, pw): boolean  // used by auth
    generateReport(): Report           // used by analytics ONLY
  }

After split (ISP respected):
  interface IUserAdmin { createUser, deleteUser }
  interface IUserAuth { findById, validatePassword }
  interface IUserReporting { generateReport }
  // UserService implements all three
  // AdminController depends only on IUserAdmin
  // AuthController depends only on IUserAuth
```

---

## Martin Fowler — Refactoring: smell detection + catalog

### The 7 smells AI coding agents create most often

These are Fowler's smells that Claude Code generates most frequently.
Check these before every commit at L3.

```
Fowler commit gate — review code just written through these 7 lenses:

□ 1. Long Method
  Any method > 20 lines in this commit?
  → Extract Method: give each chunk a meaningful name
  → Test: can you describe the method in one sentence without "and"?

□ 2. Feature Envy
  Any method that uses other class's data more than its own?
  calculateOrderTotal() in CustomerService using Order.items, Order.discount
  → Move method to Order where the data lives

□ 3. Data Clumps
  Same 2-3 fields always appearing together across multiple places?
  (street, city, zipCode) in User, in Order, in Invoice
  → Extract Value Object: Address { street, city, zipCode }
  Fowler: "If you always pass these together, they belong together."

□ 4. Primitive Obsession
  Using string/number/boolean for domain concepts?
  userId: string        → UserId value object
  price: number         → Money { amount: number, currency: Currency }
  status: string        → OrderStatus enum or value object
  email: string         → Email value object with validation

□ 5. Shotgun Surgery
  This change required modifying > 3 files?
  → Design problem: responsibility scattered across too many places
  → Consolidate: extract class/module that owns this concept

□ 6. Divergent Change
  This class changes for multiple different reasons?
  OrderService changes when: pricing rules change AND shipping rules change AND tax rules change
  → Split: PricingService, ShippingService, TaxService

□ 7. Comments explaining WHAT (not WHY)
  // iterate through items and sum prices
  → Remove comment, rename to make it self-documenting:
    calculateSubtotal(items)
  Comments that explain WHY are valuable:
  // Using optimistic locking here to avoid deadlock under high concurrent writes
```

### Fowler refactoring catalog — use in Branch D

When Branch D is active, name the specific Fowler refactoring being applied.
Not "clean up" or "restructure" — use precise language.

```
Extract Method      → moving code into named method
  When: long method, duplicated code, comment-worthy block
  How: identify chunk, give it meaningful name, extract

Extract Class       → moving cohesive set of fields + methods to new class
  When: class doing 2 jobs, too many fields, SRP violation
  How: define new class, move fields + methods, update references

Move Method         → moving method to class where it belongs
  When: Feature Envy detected, method uses other class's data more than own
  How: copy to target class, redirect original to delegate, then remove

Introduce Value Object → replacing primitives with domain type
  When: Primitive Obsession detected, validation scattered
  How: create immutable class, add validation in constructor, update callers

Replace Conditional with Polymorphism → remove if/switch on type
  When: switch(type) or if(type === X) appearing multiple times
  How: extract interface, create subclass per case, caller uses interface

Inline Method       → when method body is as clear as its name
  When: method adds no clarity, simple delegation only

Extract Interface   → when multiple classes share same methods
  When: OCP violation spotted, testing needs mock
```

---

## How shipright uses this file — by level

### At L2 (interface design)
After defining each interface, run through:
- OCP gate: "adding new type = new class, no changes to existing?"
- ISP check: "any method that implementations won't need?"
- LSP template: generate contract tests for this interface

### At L3 (before each commit)
After writing code, before `git commit`, run:
- SRP signals on every new class/method
- Fowler 7 smells on every changed file
- If any signal fires → fix before committing, not after

### At Branch D (refactoring)
- Name the specific Fowler refactoring being applied
- Write characterization tests before using any catalog item
- Commit message format: `refactor: Extract Method [methodName] from [ClassName]`

---

## CLAUDE.md additions when code health issues found

When any signal fires and is fixed, record in CLAUDE.md:

```markdown
## Code health patterns (learned from this project)

### SRP signals found
- [ClassName] was split because it handled both X and Y — keep separate
- Methods > 20 lines in this project: [list known exceptions with reason]

### OCP patterns applied
- All [Crawler/Notifier/PaymentMethod] use interface pattern — never if/switch on type

### Primitives we turned into Value Objects
- UserId: string → UserId (validates format, never null)
- Money: number → Money { amount, currency } (prevents float precision issues)

### Fowler smells recurring in this codebase
- Feature Envy: [specific class] tends to be tempted to access [OtherClass] data — resist
```
