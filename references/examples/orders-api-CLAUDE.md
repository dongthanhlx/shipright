# CLAUDE.md — orders-api

> This is a real output example from following the shipright skill.
> Use it as a reference for what a good CLAUDE.md looks like.
> Domain: a small e-commerce Orders API (accept order → reserve stock → charge payment → fulfil).

## Ubiquitous Language
| Term | Meaning | Not |
|---|---|---|
| Order | A customer's purchase request + its lifecycle (the aggregate root) | Cart, Purchase, Transaction |
| OrderLine | One product + quantity + price within an Order | Item, Row, Entry |
| Money | Amount in integer minor units + currency (Value Object) | price, cost, amount (bare number) |
| Payment | An attempt to charge Money for an Order via the gateway | Charge, Transaction, Billing |
| Stock | Reservable quantity of a Product | Inventory count, Qty, Amount |
| Fulfilment | Shipping a paid Order to the customer | Delivery, Shipping, Dispatch |

---

## Project in one sentence
A REST API that accepts customer orders, reserves stock, charges payment through an external
gateway (idempotently), and exposes order status — built to stay correct from MVP to scale.

---

## Outcome — what must CHANGE, and how we'll know
Who: the two ops staff who currently reconcile orders against the payment dashboard by hand.
Change: they stop doing the daily manual reconciliation — order status is trustworthy enough
        that they read it instead of the gateway dashboard.
Signal: after 2 weeks live, the shared reconciliation spreadsheet has no new rows, and ops stops
        asking us "did payment X go through?" in Slack. (Both observable this month. Neither is
        a KPI, and that is fine — a signal you will actually check beats one you won't.)
Riskiest assumption: that ops trusts an order status derived from OUR record of the gateway call
        rather than the gateway's own dashboard. If they don't, the API is correct and useless.
        — UNTESTED. Cheapest test: show one day of statuses side by side before building the UI.
Check by: 2 weeks after the first real order goes through.

---

## Architecture rules — NEVER violate

### Module boundaries
- `orders` is the ONLY module that writes the `orders` / `order_lines` tables
- `payments` is the ONLY module that talks to the payment gateway
- `orders` needs payment → calls `IPaymentService` (interface), never the gateway directly
- `orders` needs stock → calls `IStockService` (interface), never the `stock` table
- Cross-module calls go through `modules/[name]/index.ts` — never deep imports

### Layer rules
- **Handler**: parse → validate (zod) → call service → map result to HTTP. NO business logic
- **Service**: business rules only (the Order aggregate enforces its own invariants). NO direct DB, NO HTTP
- **Repository**: DB queries ONLY. Returns typed domain objects (Order, Money), NOT raw rows
- **Adapter** (`payments/gateway`): the ONLY place that knows the gateway's request/response shape

### Integration resilience (Boundary 5)
- Every gateway call has a timeout (`timeout: 4000`) — a slow gateway must never hang a request
- Charge is **idempotent**: one `Idempotency-Key` per Order → the gateway is never double-charged
- Idempotency keys live in the `payments` table (DB), NEVER in an in-memory Map
- Gateway down → Order stays `PENDING_PAYMENT` and is retried; the request degrades, never 500s
- HARDEN signal `TODO[gateway-error-rate>2%]`: add circuit breaker → references/resilience.md

### Money rule (no Primitive Obsession, no float)
- All amounts are a `Money` Value Object: `{ amountMinor: integer, currency }`
- NEVER a bare `number` for money. NEVER floating point. NEVER mix currencies in arithmetic

### Banned imports — will fail code review
```
// In orders service files:
import { db } from '../../shared/db'                  // ← BANNED (use a repository)
import { StripeClient } from 'stripe'                 // ← BANNED (only payments/gateway may)
import { stockTable } from '../inventory/schema'      // ← BANNED (call IStockService)

// Deep import bypassing index.ts:
import { PaymentService } from '../payments/payment.service'  // ← BANNED, use '../payments'
```

---

## Coding workflow — always in this order
1. Read this file + ARCHITECTURE.md before any action
2. Write types/interfaces first (Order, Money, IPaymentService)
3. Write test cases before implementation (tests must be RED first)
4. Implement inside-out: domain (Order/Money) → repository → service → handler
5. Run tests after each layer
6. Run boundary checklist before commit
7. Commit small: 1 feature = 1 commit. Never commit RED tests

## Pre-commit boundary checklist
```bash
grep -r "from.*shared/db" src/modules/*/*.service.ts   # must be empty
grep -rE "from 'stripe'|require\('stripe'\)" src/modules/orders/  # must be empty
grep -rn "amount.*: number" src/modules/               # review: should be Money, not number
npx tsc --noEmit                                       # must pass
npx jest --passWithNoTests                             # must pass
npx madge --circular src/                              # must show no cycles
```

---

## Error taxonomy

### Domain / operational errors (expected → return to caller)
- `ValidationError`      → HTTP 400 — input doesn't meet rules
- `NotFoundError`        → HTTP 404 — order/product doesn't exist
- `OutOfStockError`      → HTTP 409 — requested quantity unavailable
- `PaymentDeclinedError` → HTTP 402 — gateway declined (insufficient funds, etc.) — NOT a bug

### Infrastructure errors (our problem → 5xx + alert)
- `DatabaseError`       → HTTP 503 + alert
- `PaymentGatewayError` → HTTP 502 + circuit breaker log (gateway timeout / 5xx)

### Rules
- Service throws Domain or Infrastructure errors. Service has ZERO HTTP knowledge.
- A declined payment is OPERATIONAL (don't retry, don't page) — a gateway timeout is INFRASTRUCTURE (retry).
- Every InfrastructureError is logged with full context (never the card number / gateway secret).

---

## Idempotency decisions

| Operation | If called twice | Solution |
|---|---|---|
| Create order | Customer double-clicks / client retries | `Idempotency-Key` header → unique index, return existing Order |
| Charge payment | Network retry after a timeout | One key per Order; gateway called with same key → charged once |
| Reserve stock | Re-processing a PENDING order | Atomic `UPDATE ... WHERE available >= qty RETURNING` (no check-then-act) |

---

## Tech debt log

| Shortcut | Accepted because | Trigger to fix |
|---|---|---|
| Sync charge inside request | Simple, low volume | `TODO[p95>800ms]`: move charge to a queue + webhook |
| No circuit breaker on gateway | One gateway, low error rate | `TODO[gateway-error-rate>2%]`: add breaker (resilience.md) |
| Stock in same DB as orders | One service, simpler | `TODO[team-split]`: extract inventory via Strangler Fig |
| No read model for order history | Not needed yet | `TODO[reporting-needed]`: add projection table |

Mark new shortcuts: `// TODO[trigger]: description`

---

## Tech stack
```
Runtime:    Node.js 20 LTS + TypeScript strict
Database:   PostgreSQL 16 (pg + node-postgres)
Migrations: db-migrate (SQL files)
Testing:    Jest + ts-jest (coverage threshold: 80%)
Validation: zod (env vars + request bodies)
HTTP:       Express + axios (gateway calls: timeout 4s, axios-retry 2x on 5xx/timeout only)
Payment:    Stripe (wrapped behind PaymentGateway adapter — never imported outside payments/)
Logging:    pino (structured JSON, requestId via AsyncLocalStorage)
Dev:        Docker Compose (app + postgres)
```

## Environment variables
```
DATABASE_URL            # postgres connection string
STRIPE_SECRET_KEY       # payment gateway key — never logged
STRIPE_WEBHOOK_SECRET   # verify gateway webhook signatures
DEFAULT_CURRENCY        # default: USD (ISO 4217)
PORT                    # default: 3000
LOG_LEVEL               # default: info
```

---

## When to ask before doing
- Changing any `index.ts` public exports (e.g. `IPaymentService` signature)
- Adding a new npm dependency
- Changing DB schema requiring data migration
- Creating a module not in ARCHITECTURE.md
- Touching money arithmetic or the Order invariants (one-way doors — see judgment.md)

---

## Shipright state
Level: L0
Active: constitution created
Next: create L1 skeleton — modules/{orders,payments,inventory} + compiles with npx tsc --noEmit
Last shipped: nothing yet
Last updated: 2026-06
Skills active: debugging-and-error-recovery
Registry: web-api
