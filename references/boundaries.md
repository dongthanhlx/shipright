# The 5 Boundary Rules

> Rules 1–4 are the non-negotiable foundation of every shipright project.
> Cheap to follow from day one. Expensive to retrofit. Never optional — even in MVP.
> Rule 5 (failure isolation) is the operation-hemisphere boundary: timeouts + idempotency
> from day one, full resilience patterns on signal (HARDEN phase). See references/resilience.md.

These are the rules that matter for long-term maintainability and fault tolerance.
Everything else is preference. These are not.

> **Solo and team use the same boundaries — differently.** For one developer, a boundary keeps your
> future self sane. When multiple devs each own modules, the *same* boundary becomes the **team API**
> — the contract they build against — and boundary-guard.sh becomes the team-seam enforcer. That
> layer is signal-driven: `references/team-scale.md` (load only when it's actually multi-dev).

Violating any of these makes the codebase progressively harder to change,
test, and eventually split into services. They're cheap to follow. Expensive to fix.

---

> Numbering matches SKILL.md (the source of truth). Rule 2 has two concrete halves (2a/2b) because
> "each layer has one job" is violated in two distinct ways — a service touching the DB, and a
> repository leaking raw rows.

## Rule 1 — Dependencies point inward only: modules talk through index.ts, not internal files

**The rule**: When module A needs something from module B,
it imports from `modules/b/index.ts` only — never from `modules/b/b.service.ts` directly.

**Why**: `index.ts` is the contract. What's in `index.ts` is stable.
What's in `b.service.ts` is implementation detail that can change any time.
If A imports directly from `b.service.ts`, refactoring B's internals breaks A.

```typescript
// ✅ CORRECT — import through public API
import { IUserService, UserNotFoundError } from '../users'

// ❌ WRONG — deep import into another module's internals
import { UserService } from '../users/users.service'
import { hashPassword } from '../users/users.utils'
```

**The test**: Can you completely rewrite `modules/users/users.service.ts`
(changing class names, extracting helpers, restructuring methods)
without touching any file outside `modules/users/`?

If yes: the boundary is respected.
If no: there's a deep import somewhere that needs fixing.

---

## Rule 2 — Each layer has one job

Handler: parse → call service → format (zero domain logic). Service: business rules only (no HTTP,
no DB). Repository: queries only, returns typed domain objects. The two violations that matter most:

### 2a — Services never touch the database directly

**The rule**: Service files cannot import `shared/db`.
The only path to the database is through a repository interface.

**Why**: This is what makes services 100% unit-testable.
A service that imports `db` requires a running database to test.
A service that takes `IUserRepository` in its constructor can be tested
with a mock that returns whatever you need in 0ms.

```typescript
// ✅ CORRECT — service uses repository interface
class OrderService {
  constructor(
    private orders: IOrderRepository,
    private users: IUserService,     // ← another service via interface
  ) {}

  async createOrder(userId: string, items: Item[]): Promise<Order> {
    const user = await this.users.findById(userId)  // ← via interface
    if (!user) throw new NotFoundError('user', userId)
    return this.orders.save({ userId, items, total: calcTotal(items) })
  }
}

// ❌ WRONG — service accesses DB directly
class OrderService {
  async createOrder(userId: string, items: Item[]) {
    const user = await db.query('SELECT * FROM users WHERE id = $1', [userId])
    // ... now this can only be tested with a real database
  }
}
```

**The test**: Can you run `OrderService.spec.ts` with `jest` and zero database connections?

If yes: Rule 2a is respected.
If no: there's direct DB access in a service layer.

### 2b — Repositories hide persistence details

**The rule**: Repositories return typed domain objects.
Nothing outside the repository knows what SQL looks like or what columns exist.

**Why**: If your service receives `{ user_id: string, created_at: string }`
(a raw postgres row), it's coupled to your current schema.
Change a column name → fix it in every service that uses it.
Use a domain object → change only the repository mapping.

```typescript
// ✅ CORRECT — repository maps to domain object
class UserRepository implements IUserRepository {
  async findById(id: string): Promise<User | null> {
    const row = await this.db.query(
      'SELECT id, email, created_at FROM users WHERE id = $1',
      [id]
    )
    if (!row) return null
    return {               // ← maps raw row to domain type
      id: row.id,
      email: row.email,
      createdAt: new Date(row.created_at),  // ← converts types
    }
  }
}

// ❌ WRONG — leaks raw DB row
class UserRepository {
  async findById(id: string) {
    return this.db.query('SELECT * FROM users WHERE id = $1', [id])
    // caller now depends on postgres column names and types
  }
}
```

**The test**: Can you change the database table's column names
(e.g., `created_at` → `createdAt`) without changing any service file?

If yes: Rule 2b is respected.
If no: a repository is leaking raw rows.

---

## Rule 3 — Modules do not share databases

**The rule**: Each table is owned by exactly one module. When module A needs data that module B
owns, it calls B's public interface — it never queries B's tables, not even read-only.

**Why**: A shared table is a hidden dependency that no import statement shows. B renames a column,
adds a soft-delete flag, or changes an invariant — and A breaks silently, because A never went
through B's rules. It also makes extraction impossible: B cannot move to its own database while A
still joins against its tables.

```typescript
// ✅ CORRECT — orders asks inventory through its public interface
class OrderService {
  constructor(private orders: IOrderRepository, private stock: IStockService) {}

  async placeOrder(cmd: PlaceOrderCommand) {
    await this.stock.reserve(cmd.productId, cmd.qty)   // inventory enforces its own rules
    // ...
  }
}

// ❌ WRONG — orders' repository reads inventory's table directly
class OrderRepository {
  async availableStock(productId: string) {
    return this.db.query('SELECT available FROM stock WHERE product_id = $1', [productId])
    // bypasses inventory's reservation logic; breaks when inventory changes its schema
  }
}
```

**The test**: For each table, can you name the ONE module that reads and writes it?
Grep every other module's repositories for that table name — the result must be empty.

If yes: Rule 3 is respected.
If no: two modules share a table — route the access through the owner's interface.

(Cheapest enforcement as you grow: one DB schema per module, no cross-schema queries —
`references/scaling-guide.md` Stage 1, Step 5.)

---

## Why rules 1–3 = no rewrite when scaling

When the system needs to scale and you want to split `users` into its own service:

**Without rules 1–3**:
- Other modules import `users.service.ts` directly → must find and update all imports
- Services use `db` directly → can't split without copying DB logic
- Repositories return raw rows → services contain SQL column knowledge → everything breaks
- Other modules query the `users` table → the table can't move without breaking them

**With rules 1–3**:
- Other modules import from `users/index.ts` → change index.ts to call HTTP instead of local → zero changes elsewhere
- Services use `IUserService` interface → the HTTP client implements the same interface → zero changes to service logic
- Repositories are already isolated → can be moved entirely to the new service
- Only `users` touches its tables → the tables move with it

The split becomes: create new service, implement `IUserService` as HTTP client,
flip a feature flag. One day of work instead of weeks of untangling.

---

## Quick reference — what goes where

| Logic type | Where it lives | Example |
|---|---|---|
| HTTP parsing, status codes | Handler | 400 if validation fails |
| Business rules | Service | can't order if stock = 0 |
| Domain calculations | Service | calculate order total |
| SQL queries | Repository | SELECT * WHERE id = $1 |
| Schema mapping | Repository | row.created_at → new Date() |
| External API calls | Crawler/Adapter | fetch from YouTube API |
| Data transformation | Normalizer | YouTube response → FeedItem |
| Config/env | config/ | PORT, DATABASE_URL |
| Shared utilities | shared/ | logger, http-client |

**If you're not sure where something goes**: ask "what is the smallest layer
that needs to know about this?" — put it there.

---

## Rule 4 — No raw external response passes the Adapter layer

**The rule**: Every external system (third-party API, blockchain RPC, LLM, payment gateway)
has exactly one Adapter/Normalizer. Raw external responses never enter service or domain logic.

**Why**: External systems change without warning. When YouTube changes their API schema,
you fix one file (the Adapter). Without this boundary, you fix everywhere the raw response is used.
This is Eric Evans's Anti-Corruption Layer (ACL) in practice.

```typescript
// ✅ CORRECT — Adapter translates, service gets domain types
class YouTubeAdapter implements ICrawler {
  async fetch(): Promise<FeedItem[]> {
    const raw = await this.httpClient.get(YOUTUBE_API_URL)
    return youtubeNormalizer(raw.data)  // raw never leaves here
  }
}

class FeedService {
  async ingest(items: FeedItem[]) { ... }  // receives FeedItem, not raw YouTube response
}

// ❌ WRONG — raw response leaks into domain
class FeedService {
  async ingest(youtubeResponse: YouTubeRawResponse) {
    const title = youtubeResponse.items[0].snippet.title  // domain knows YouTube schema
  }
}
```

**Applies to**:
- Third-party REST APIs (Stripe, Twilio, YouTube, RapidAPI)
- Blockchain RPCs (eth_getTransaction, getSignatureStatuses)
- LLM responses (OpenAI, Anthropic) — ResponseAdapter before domain logic
- Payment gateways (raw gateway response → domain PaymentResult)
- Platform webhooks (raw Telegram/Discord message → NormalizedMessage)

**The test**: Can you swap YouTube for a different news source
without touching FeedService? If yes, Rule 4 is followed.

**Signal that Rule 4 is violated**:
- Service file imports from external SDK (e.g., `import { AlchemySDK } from 'alchemy-sdk'`)
- Domain types have fields named after external API fields (`snippet`, `items[0]`, `contractRet`)
- Multiple files updated when provider changes schema

---

## Rule 5 — Every integration point has a timeout + a deliberate fallback

**The rule**: No outbound call (HTTP, DB, queue, RPC, LLM) waits forever, and every one has
a defined behavior for when it fails. One slow or dead dependency must not stall the system.

**Why**: Large systems die from failure *propagation*, not logic bugs (Michael Nygard,
*Release It!*). A dependency with no timeout holds a thread hostage; enough hostage threads
and the whole service is down — a slow dependency is worse than a dead one. A timeout converts
a slow failure into a fast, contained one. A fallback keeps partial service alive.

```typescript
// ✅ CORRECT — bounded wait + defined fallback
async getRecommendations(userId: string): Promise<Item[]> {
  try {
    return await this.recs.fetch(userId, { timeout: 800 })   // bounded
  } catch (e) {
    logger.warn({ userId, err: e.code }, 'recs degraded → popular items')
    return this.popularItems()                                // graceful degradation
  }
}

// ❌ WRONG — unbounded wait, no fallback
async getRecommendations(userId: string): Promise<Item[]> {
  return await this.recs.fetch(userId)   // hangs forever if recs is slow → cascades
}
```

**Dial by phase** (do NOT add full resilience at SEED — that's over-engineering):
- SEED: timeouts on outbound calls + idempotency keys for side effects. Nothing more.
- VALIDATE: + retry (backoff+jitter) + graceful degradation on the calls that fail most.
- HARDEN: + circuit breakers + bulkheads, Rule 5 enforced on every integration point.
- SCALE: + backpressure / load shedding.

**The test**: kill or hang each dependency in a test — does the request fail fast (within the
timeout) with a defined fallback, or does it hang and cascade? See fault-injection tests in
`references/resilience.md`.

**Signal that Rule 5 is violated**:
- An outbound call with no timeout option set
- A `catch` that only logs and rethrows on a non-critical dependency (no fallback)
- Your latency/thread count spikes when a *downstream* dependency slows down
- Idempotency tracked in an in-memory Map (lost on restart — must be DB/Redis)

Full patterns (8 stability patterns, retry budgets, steady state): `references/resilience.md`.

---

## Ubiquitous Language and boundaries work together

Boundaries define WHERE code can go.
Ubiquitous Language defines HOW code is named.
Both must be set at L0 — neither works well without the other.

```
Without Ubiquitous Language: boundaries are followed but code is hard to read.
Without boundaries: Ubiquitous Language is consistent but architecture rots.
With both: Claude generates code that is correctly structured AND domain-expressive.
```

Add to CLAUDE.md at L0:
1. Ubiquitous Language table (domain terms)
2. Boundary rules 1–4 (with specific banned examples for THIS project)
3. Boundary 5 timeouts for any integration point (full resilience deferred to HARDEN)
