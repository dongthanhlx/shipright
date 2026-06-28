# ARCHITECTURE.md — orders-api

> **Ubiquitous Language** (from CLAUDE.md): Order, OrderLine, Money, Payment, Stock, Fulfilment
> All module names, type names, and method names below use these domain terms.
>
> Real output example from following the shipright skill.

## System diagram

```
                         POST /orders   GET /orders/:id
                                │
                                ▼
                    ┌────────────────────────┐
                    │     OrderHandler       │   parse → zod → service → HTTP
                    └───────────┬────────────┘
                                ▼
                    ┌────────────────────────┐
                    │     OrderService       │   orchestrates the Order lifecycle
                    │  (Order aggregate root │   enforces its own invariants)
                    └───┬───────────────┬────┘
            IStockService│               │IPaymentService
                         ▼               ▼
              ┌──────────────┐   ┌──────────────────┐
              │ StockService │   │  PaymentService  │
              │ (inventory)  │   │   (payments)     │
              └──────┬───────┘   └────────┬─────────┘
                     │ shared/db          │ IPaymentGateway
                     │                    ▼
                     │           ┌──────────────────┐
                     │           │ StripeGateway    │  Adapter (Boundary 4+5)
                     │           │ timeout + idemp. │  raw Stripe ⇄ domain Payment
                     │           └────────┬─────────┘
                     ▼                    ▼
              ┌─────────────────────────────────────────┐
              │               PostgreSQL                 │
              │   orders | order_lines | payments | stock│
              └─────────────────────────────────────────┘
```

---

## Modules

### `modules/orders`
**Responsibility**: own the Order aggregate and its lifecycle. The Order object enforces every
invariant; the service orchestrates stock + payment. ONLY module writing `orders` / `order_lines`.

**Public API** (`index.ts`):
```typescript
interface IOrderRepository {
  save(order: Order): Promise<void>
  findById(id: OrderId): Promise<Order | null>
  findByIdempotencyKey(key: string): Promise<Order | null>
}
class OrderService {
  constructor(orders: IOrderRepository, stock: IStockService, payments: IPaymentService) {}
  placeOrder(cmd: PlaceOrderCommand, idempotencyKey: string): Promise<Order>
  getOrder(id: OrderId): Promise<Order>
}
```
**Depends on**: `IStockService`, `IPaymentService` (both via interface), `IOrderRepository`
**Does NOT depend on**: the gateway, the `stock` table, payment internals

---

### `modules/payments`
**Responsibility**: charge Money for an Order idempotently; translate the gateway's world into a
domain `Payment`. ONLY module that imports the Stripe SDK. ONLY module writing `payments`.

**Public API** (`index.ts`):
```typescript
interface IPaymentService {
  charge(orderId: OrderId, amount: Money, idempotencyKey: string): Promise<Payment>
}
// Internal only (not exported): IPaymentGateway + StripeGateway adapter
```
**Depends on**: `IPaymentGateway` (injected), `shared/db`
**Does NOT depend on**: orders, inventory
**Boundary 4+5**: raw Stripe responses never leave `StripeGateway`; every call has a timeout +
the Order's idempotency key, so a retry after a timeout never double-charges.

---

### `modules/inventory`
**Responsibility**: reserve and release Stock atomically. Single source of truth for availability.

**Public API** (`index.ts`):
```typescript
interface IStockService {
  reserve(productId: ProductId, qty: number): Promise<void>  // throws OutOfStockError
  release(productId: ProductId, qty: number): Promise<void>  // compensating action
}
```
**Depends on**: `shared/db`
**Does NOT depend on**: orders, payments

---

### `shared/`
```
db.ts            # pg.Pool singleton + transaction(fn) helper
logger.ts        # pino structured logger (requestId via AsyncLocalStorage)
http-client.ts   # axios; gateway calls use timeout 4s + retry on 5xx/timeout only
errors.ts        # AppError hierarchy (see CLAUDE.md error taxonomy)
money.ts         # Money value object: add/subtract/sameCurrency, integer minor units
```
**Rule**: shared/ never imports from modules/

---

## Domain model

```typescript
// Value Object — immutable, validates on construction, no float, no mixed currency
class Money {
  private constructor(readonly amountMinor: number, readonly currency: Currency) {}
  static of(amountMinor: number, currency: Currency): Money {
    if (!Number.isInteger(amountMinor)) throw new ValidationError('Money must be integer minor units')
    return new Money(amountMinor, currency)
  }
  add(other: Money): Money {
    if (other.currency !== this.currency) throw new ValidationError('currency mismatch')
    return new Money(this.amountMinor + other.amountMinor, this.currency)
  }
}

// Aggregate Root — the ONLY entry point for changing OrderLines; protects invariants
class Order {
  readonly id: OrderId
  private status: OrderStatus        // DRAFT → PENDING_PAYMENT → PAID → FULFILLED | CANCELLED
  private lines: OrderLine[]

  // INVARIANT: cannot modify a paid/fulfilled order
  addLine(line: OrderLine): void {
    if (this.status !== 'DRAFT') throw new ConflictError('cannot modify a non-draft order')
    this.lines.push(line)
  }
  // INVARIANT: total is always the sum of lines, in one currency
  total(): Money { return this.lines.reduce((sum, l) => sum.add(l.subtotal()), Money.zero(this.currency)) }
  // INVARIANT: cannot fulfil an unpaid order  ← the classic "can't ship unpaid"
  markFulfilled(): void {
    if (this.status !== 'PAID') throw new ConflictError('cannot fulfil an unpaid order')
    this.status = 'FULFILLED'
  }
}
```

Invariants live in the `Order` aggregate, never in the service — they cannot be bypassed.

---

## Database schema

```sql
CREATE TABLE orders (
  id              VARCHAR(36) PRIMARY KEY,            -- uuid
  customer_id     VARCHAR(36) NOT NULL,
  status          VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  currency        CHAR(3) NOT NULL,
  total_minor     BIGINT NOT NULL DEFAULT 0,          -- integer minor units, never float
  idempotency_key VARCHAR(64) UNIQUE,                 -- one order per key (dedupe double-submit)
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE order_lines (
  order_id     VARCHAR(36) REFERENCES orders(id),
  product_id   VARCHAR(36) NOT NULL,
  qty          INTEGER NOT NULL CHECK (qty > 0),
  unit_minor   BIGINT NOT NULL,
  PRIMARY KEY (order_id, product_id)
);
CREATE TABLE payments (
  id              VARCHAR(36) PRIMARY KEY,
  order_id        VARCHAR(36) REFERENCES orders(id),
  status          VARCHAR(20) NOT NULL,               -- SUCCEEDED | DECLINED | FAILED
  amount_minor    BIGINT NOT NULL,
  idempotency_key VARCHAR(64) UNIQUE NOT NULL,        -- gateway never double-charged
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE stock (
  product_id VARCHAR(36) PRIMARY KEY,
  available  INTEGER NOT NULL CHECK (available >= 0)  -- atomic reserve via UPDATE ... RETURNING
);
```

---

## Dependency rules

```
api/            → modules/* (wire everything here, nowhere else)
modules/orders  → modules/inventory (IStockService), modules/payments (IPaymentService)
modules/payments→ IPaymentGateway (internal), shared/db
modules/inventory→ shared/db
shared/*        → nothing in modules/
config/         → nothing
```

**Explicitly forbidden:**
```
orders   → stock table / payments internals   # use the public interfaces
payments → orders                             # payments doesn't know order rules
any service → Stripe SDK                       # only payments/gateway may import it
any module → bare number for Money             # always the Money value object
```

---

## How to add a new payment provider (e.g. PayPal)

1. Implement `PayPalGateway implements IPaymentGateway` in `modules/payments/gateway/`
2. Map raw PayPal responses → domain `Payment` inside the adapter (raw never leaks out)
3. Select provider via config/factory — `PaymentService` is unchanged
4. **Zero changes** to OrderService, inventory, or any handler

This works because of Boundary 4 (one adapter per external system) + OCP (new class, not an edit).

---

## ADR

### ADR-001: Modular monolith, not microservices
**Decision**: single deployable, strong module boundaries (orders / payments / inventory).
**Options**: microservices (rejected: operational overhead before value proven).
**Consequence**: splitting later = Strangler Fig per module (boundaries make it a config flip).
**Trigger to revisit**: separate teams own payments vs orders, or 10x different scaling.

### ADR-002: Money as a Value Object, integer minor units (one-way door)
**Decision**: all amounts are `Money { amountMinor, currency }` — never a float, never bare number.
**Why one-way door** (judgment.md): money representation is baked into the schema and every
calculation; changing it later is a data migration + audit. Get it right on day one.
**Consequence**: no floating-point rounding bugs; currency mismatches fail loudly at construction.

### ADR-003: Order is the consistency boundary; invariants live in the aggregate
**Decision**: OrderLines are only mutated through `Order` methods; "can't ship unpaid" etc. are
`Order` methods, not service checks.
**Consequence**: invariants cannot be bypassed by a new caller. Service orchestrates, never validates.

### ADR-004: Idempotent charge + Boundary 5 on the gateway (resilience)
**Decision**: each Order carries one idempotency key; `StripeGateway` calls have a 4s timeout and
pass that key, so a retry after a timeout never double-charges.
**Options**: no timeout (rejected: a slow gateway hangs every request thread — cascading failure);
in-memory dedupe (rejected: lost on restart, invisible across instances).
**Consequence**: safe retries; a gateway outage leaves orders `PENDING_PAYMENT`, not 500s.
**Trigger to revisit**: `TODO[gateway-error-rate>2%]` → add a circuit breaker (references/resilience.md).

### ADR-005: Synchronous charge inside the request (deliberate MVP shortcut)
**Decision**: charge the gateway during `POST /orders` rather than via a queue + webhook.
**Why a two-way door** (judgment.md): moving to async later is an internal change behind
`IPaymentService` — reversible, so we defer it. Not worth the queue infrastructure at MVP volume.
**Trigger to revisit**: `TODO[p95>800ms]` → move charge to a queue, confirm via gateway webhook.
