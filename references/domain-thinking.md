# Domain Thinking — Before You Name a Module

> Evans tactical companion to `references/code-quality.md` (strategic DDD) and Branch A intake
> (the Ubiquitous Language step). The "DDD or not?" decision is itself a judgment call —
> see `references/judgment.md` (don't apply DDD machinery to a CRUD app or a glue script).

The biggest mistake in early architecture: naming modules after technical layers
(DataFetcher, Processor, Storage) instead of domain concepts.

Domain thinking asks: what does the BUSINESS do here? What are the rules that
can never be broken? What changes together?

---

## Step 1: Find Aggregate Roots

An Aggregate is a cluster of objects treated as a single unit for data changes.
The Aggregate Root is the entry point — only it can be modified directly.

Ask: "If I change X, what else MUST change at the same time to stay consistent?"

```
Order Aggregate:
  OrderRoot (root)
    OrderLineItem[]  <- always changed through Order, never directly
    ShippingAddress  <- belongs to this order only
    
NOT in Order Aggregate:
  Product           <- has its own lifecycle, own rules
  Customer          <- exists independently of orders
```

**News Crawler example:**
- FeedItem is an Aggregate Root (dedup by URL, has its own identity)
- JobRun is an Aggregate Root (tracks a crawl session, owns its result)
- QuotaUsage is a Value Object (no identity, just a number per source per day)

**Rule**: If two things always change together, they're in the same aggregate.
If they can change independently, they're separate aggregates.

---

## Step 2: Identify Invariants

An invariant is a business rule that must ALWAYS be true. Never violated.
Invariants live in the Aggregate Root, not in the service.

```typescript
// WRONG: invariant in service (can be bypassed)
class OrderService {
  async addItem(orderId: string, item: Item) {
    const order = await this.repo.findById(orderId)
    if (order.status === 'shipped') throw new Error('cannot modify') // easy to forget
    await this.repo.addItem(orderId, item)
  }
}

// CORRECT: invariant in domain object (cannot be bypassed)
class Order {
  addItem(item: Item): void {
    if (this.status === 'shipped') {
      throw new DomainError('Cannot modify shipped order')
    }
    this.items.push(item)
    this.recalculateTotal()
  }
}
```

**How to find invariants:** Ask "what can NEVER happen in this domain?"
- Order cannot be shipped if not paid
- Quota cannot go negative
- FeedItem URL must be unique per source
- Job cannot finish before it starts

Write these as domain object methods, not service checks.

---

## Step 3: Find Domain Events

Domain Events answer: "What just happened that other parts of the system care about?"

```
OrderPlaced     -> trigger: send confirmation email, reserve inventory
OrderShipped    -> trigger: notify customer, update fulfillment
PaymentFailed   -> trigger: notify customer, release inventory
FeedItemCreated -> trigger: notify downstream consumers (if any)
```

At MVP: domain events can be simple function calls or Promise.allSettled chains.
Later: domain events become the backbone of async messaging (Kafka, EventBridge). When one
leaves the process, publish it through a transactional outbox, never straight after the DB write:
`references/messaging.md` §2.

**Key insight**: If module A needs to react to something in module B,
that's a domain event — not a direct service call.

```typescript
// WRONG: OrderService calls EmailService directly (tight coupling)
class OrderService {
  async createOrder(dto: CreateOrderDTO) {
    const order = await this.repo.save(dto)
    await this.emailService.sendConfirmation(order)  // <- coupled
    return order
  }
}

// CORRECT: emit event, let handlers react
class OrderService {
  async createOrder(dto: CreateOrderDTO) {
    const order = await this.repo.save(dto)
    this.events.emit('OrderCreated', order)  // <- decoupled
    return order
  }
}
```

At MVP, a simple EventEmitter works. Don't over-engineer until you need persistence.

---

## Step 4: Decide — DDD or not?

Not every project needs DDD. Use this to decide:

| Project type | Recommendation |
|---|---|
| CRUD app, clear schema, few business rules | Simple service + repository, no domain objects |
| Complex business rules, many invariants | Domain objects with invariants, maybe DDD |
| Data pipeline, ETL, crawlers | Functional style, pure functions, no OOP needed |
| Financial, medical, legal | DDD with strict invariants, audit events mandatory |

**News Crawler verdict**: Not DDD. FeedItem is simple data. CrawlerService is
orchestration. Use service + repository + pure normalizer functions. No domain objects needed.

**E-commerce verdict**: DDD makes sense. Order has invariants (can't ship unpaid).
Payment has complex state machine. Customer has loyalty rules.

---

## When Claude Code asks "what module should this go in?"

Answer these in order:
1. Does it represent a domain concept? (noun, has identity, has lifecycle) -> module
2. Does it enforce a business rule? -> domain object method or service
3. Does it transform data? -> pure function (normalizer, mapper)
4. Does it talk to external systems? -> adapter/crawler, not service
5. Is it infrastructure? -> shared/ or config/
