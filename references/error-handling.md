# Error Handling — Taxonomy and Patterns

> Companion to `references/resilience.md` (operation hemisphere): resilience.md covers the
> Nygard stability patterns (timeout, circuit breaker, bulkhead); this file covers how to
> CLASSIFY and SHAPE errors (taxonomy, Result type, saga, race conditions). Used by Branch C
> (bug classification), Branch F (incident triage), and at L0 to define the error taxonomy.

Sloppy error handling is the #1 cause of mystery bugs in production.
Senior engineers categorize errors before deciding how to handle them.

---

## The 3 Error Categories (never mix them up)

### Category 1: Operational Errors
Expected failures. The system is working correctly — this is just reality.
- User not found
- Invalid input
- External API returned 429
- Database record already exists
- Quota exceeded

**Handle by**: Return to caller. Log at INFO. Never page on-call.

### Category 2: Infrastructure Errors
Unexpected, but recoverable. The system is still healthy.
- Database connection refused (but DB is coming back)
- Network timeout on external API
- Redis unavailable

**Handle by**: Retry with backoff. Log at WARN. Alert if sustained.

### Category 3: Programmer Errors (Bugs)
Should never happen. Indicate a code defect.
- null.property (TypeError)
- array[-1] (logic bug)
- Missing required argument that TypeScript should have caught

**Handle by**: Let it crash. Log at ERROR with full stack. Page on-call.
Do NOT try to recover — the system is in unknown state.

---

## Error Class Hierarchy

```typescript
// Base — all domain errors extend this
export class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number,
    public readonly isOperational: boolean = true,
  ) {
    super(message)
    this.name = this.constructor.name
    Error.captureStackTrace(this, this.constructor)
  }
}

// Operational errors — expected, return to caller
export class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} not found: ${id}`, 'NOT_FOUND', 404)
  }
}

export class ValidationError extends AppError {
  constructor(message: string, public readonly fields?: Record<string, string>) {
    super(message, 'VALIDATION_ERROR', 422)
  }
}

export class ConflictError extends AppError {
  constructor(message: string) {
    super(message, 'CONFLICT', 409)
  }
}

export class QuotaExceededError extends AppError {
  constructor(source: string) {
    super(`API quota exceeded for ${source}`, 'QUOTA_EXCEEDED', 429)
  }
}

// Infrastructure errors — may retry
export class ExternalServiceError extends AppError {
  constructor(service: string, cause: Error) {
    super(`External service failed: ${service}`, 'EXTERNAL_SERVICE_ERROR', 502, true)
    this.cause = cause
  }
}
```

---

## Result Type Pattern (when throwing is wrong)

Use Result type when failure is a normal, expected branch — not an exception.

```typescript
type Result<T, E = AppError> =
  | { ok: true; value: T }
  | { ok: false; error: E }

// When to use Result instead of throw:
// - Quota check: "is quota available?" is a question, not an exception
// - Dedup check: "does this item already exist?" is data, not an error
// - Validation: returns all field errors at once, not just the first

class QuotaService {
  async checkAvailable(source: string, units: number): Promise<Result<void, QuotaExceededError>> {
    const used = await this.repo.getUsedToday(source)
    const limit = this.config.limits[source]
    if (used + units > limit * 0.8) { // 80% safety margin
      return { ok: false, error: new QuotaExceededError(source) }
    }
    return { ok: true, value: undefined }
  }
}

// Caller — explicit handling, no hidden control flow
const result = await quotaService.checkAvailable('youtube', 100)
if (!result.ok) {
  logger.warn({ source: 'youtube', error: result.error.code }, 'Quota check failed')
  return // skip this crawler gracefully
}
await crawler.fetch()
```

**Rule**: throw for unexpected errors, return Result for expected branches.

---

## Transaction Boundary and Saga Pattern

When an operation touches multiple repositories, you need a transaction boundary.

### Option A: Database Transaction (simple, same DB)
```typescript
class OrderService {
  async createOrder(dto: CreateOrderDTO): Promise<Order> {
    return this.db.transaction(async (trx) => {
      // Both operations in same transaction — atomic
      const order = await this.orderRepo.save(dto, trx)
      await this.inventoryRepo.deduct(dto.items, trx)
      return order
    })
  }
}
```

### Option B: Saga Pattern (distributed, compensating transactions)
For operations spanning multiple services/databases:

```
Step 1: Create order          -> on fail: nothing to undo
Step 2: Reserve inventory     -> on fail: no compensation needed (step 1 rolls back)
Step 3: Charge payment        -> on fail: release inventory (compensating action)
Step 4: Confirm order         -> on fail: refund payment, release inventory
```

```typescript
class CreateOrderSaga {
  async execute(dto: CreateOrderDTO) {
    const order = await this.orderService.create(dto)
    
    try {
      await this.inventoryService.reserve(dto.items)
    } catch (e) {
      await this.orderService.cancel(order.id) // compensate step 1
      throw e
    }
    
    try {
      await this.paymentService.charge(order.total, dto.paymentMethod)
    } catch (e) {
      await this.inventoryService.release(dto.items) // compensate step 2
      await this.orderService.cancel(order.id)       // compensate step 1
      throw e
    }
    
    return this.orderService.confirm(order.id)
  }
}
```

**For MVP**: Use DB transactions when possible (simpler). Use Saga only when
operations span multiple services or external APIs.

---

## Idempotency — "What if this runs twice?"

Every mutation endpoint must answer: "If called twice with same input, is the result the same?"

```typescript
// WRONG: creates duplicate orders
async createOrder(dto: CreateOrderDTO): Promise<Order> {
  return this.repo.insert(dto) // second call = second row
}

// CORRECT: idempotent via idempotency key
async createOrder(dto: CreateOrderDTO, idempotencyKey: string): Promise<Order> {
  const existing = await this.repo.findByIdempotencyKey(idempotencyKey)
  if (existing) return existing // return same result
  
  const order = await this.repo.insert({ ...dto, idempotencyKey })
  return order
}
```

**When idempotency matters most**:
- Payment processing (charge twice = very bad)
- Cron jobs (may run twice if crash mid-run)
- Webhook handlers (may be retried by caller)
- Message queue consumers (at-least-once delivery): dedup table, version checks, DLQ rules in
  `references/messaging.md` §3–4

**For news crawler specifically**: FeedItem uses `sha256(url)` as primary key.
`INSERT ... ON CONFLICT DO NOTHING` = naturally idempotent. Good design.

---

## Race Conditions — Check-Then-Act

The most common race condition: check something, then act on it.
Between check and act, the world can change.

```typescript
// WRONG: quota race condition
async fetch(source: string) {
  const available = await this.quota.isAvailable(source, 100) // check
  // <-- another process could consume quota here -->
  if (!available) return
  await this.apiClient.search()   // act — quota may be gone
  await this.quota.consume(source, 100)
}

// CORRECT: atomic check-and-consume using DB UPDATE ... RETURNING
async consumeQuota(source: string, units: number): Promise<boolean> {
  const result = await this.db.query(`
    UPDATE quota_usage 
    SET used_units = used_units + $1
    WHERE source = $2 
      AND date = CURRENT_DATE 
      AND used_units + $1 <= $3
    RETURNING used_units
  `, [units, source, this.limits[source]])
  
  return result.rowCount > 0 // true = success, false = quota exceeded
}
```

**Questions to ask about every mutation**:
1. Can this run concurrently from multiple processes?
2. Is there a check-then-act that could race?
3. Is the operation atomic at the DB level?
