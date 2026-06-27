# The 4 Boundary Rules

> These 4 rules are the non-negotiable foundation of every shipright project.
> Cheap to follow from day one. Expensive to retrofit. Never optional — even in MVP.

These are the only 4 rules that matter for long-term maintainability.
Everything else is preference. These are not.

Violating any of these makes the codebase progressively harder to change,
test, and eventually split into services. They're cheap to follow. Expensive to fix.

---

## Rule 1 — Modules talk through index.ts, not internal files

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

## Rule 2 — Services never touch the database directly

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

If yes: Rule 2 is respected.
If no: there's direct DB access in a service layer.

---

## Rule 3 — Repositories hide persistence details

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

If yes: Rule 3 is respected.
If no: a repository is leaking raw rows.

---

## Why these 3 rules = no rewrite when scaling

When the system needs to scale and you want to split `users` into its own service:

**Without the 3 rules**:
- Other modules import `users.service.ts` directly → must find and update all imports
- Services use `db` directly → can't split without copying DB logic
- Repositories return raw rows → services contain SQL column knowledge → everything breaks

**With the 3 rules**:
- Other modules import from `users/index.ts` → change index.ts to call HTTP instead of local → zero changes elsewhere
- Services use `IUserService` interface → the HTTP client implements the same interface → zero changes to service logic
- Repositories are already isolated → can be moved entirely to the new service

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
