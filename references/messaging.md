# Messaging & async — moving work and facts without losing or doubling them

> A broker doesn't remove failure. It moves it to places that are harder to see: the event that was
> never published, the message processed twice, the backlog nobody watched, the poison message that
> blocked a partition for a day. Each has a known cure, and most of them are cheapest the day you
> publish your first event.
>
> Master anchors: **Hohpe & Woolf**, *Enterprise Integration Patterns* (2003: guaranteed delivery,
> idempotent receiver, dead letter channel, competing consumers) · **Pat Helland**, *Life beyond
> Distributed Transactions* (2007) and *Idempotence Is Not a Medical Condition* (2012) · **Chris
> Richardson**, microservices.io (Transactional Outbox, Idempotent Consumer, Saga) · **Kleppmann**,
> *DDIA* ch. 11 + **Jay Kreps**, *The Log* (2013) · **Tyler Treat**, *You Cannot Have Exactly-Once
> Delivery* (2015) · **David Yanacek**, *Avoiding insurmountable queue backlogs* (Amazon Builders'
> Library) · **Marc Brooker**, *Timeouts, retries, and backoff with jitter* (same).

Load this when you add a queue or broker, publish an event after a database write, write a consumer,
or when messages are lost, duplicated, stuck or piling up.

---

## 0. Do you need a broker at all?

```
In-process event bus (domain-thinking.md, scaling-guide.md Stage 1)
  → until processing must SURVIVE A RESTART, cross a process boundary, absorb bursts, or fail
    independently of the request. Then a real broker.
Async moves latency, not work, and it adds eventual consistency the UI must show ("processing…",
  a status endpoint, a notification when done). If the user needs the result now, async only hides it.
```

Two different tools that get called "a queue":

| | Work queue | Log / stream |
|---|---|---|
| Examples | SQS, RabbitMQ, BullMQ/Sidekiq (Redis), Celery | Kafka, Kinesis, Redis Streams, Pulsar |
| A message is | a job, consumed then deleted | a fact, appended and retained |
| Consumers | compete for messages | each group reads the whole log at its own offset; replay is free |
| Order | none, or FIFO per group | per partition |
| Pick it for | commands to do once (send email, make thumbnail) | facts many consumers need, rebuilding read models, audit, replay |

**Prefer managed** (SQS/SNS, Pub/Sub, a managed Kafka or RabbitMQ) until operating a broker is someone's
actual job. **Keep the broker behind an adapter** (Boundary 4): no broker SDK types in the domain. A
broker is costly to swap, and the adapter keeps that swap a single-module change.

---

## 1. Delivery semantics — what is actually possible

- **At-most-once:** fire and forget. Losing a message is acceptable: metrics, best-effort analytics.
- **At-least-once:** the practical default. A message can arrive **twice**: redelivery after a crash, a
  visibility timeout, a producer retry.
- **Exactly-once delivery** across a network doesn't exist (Two Generals; Treat). What systems sell as
  "exactly-once" is **at-least-once delivery + idempotent processing**, or transactions inside one
  system (Kafka's read-process-write transactions hold only within Kafka).

**Therefore every consumer is idempotent. Not negotiable** (§3).

---

## 2. The dual write and the Transactional Outbox — decide it at the first event

The bug that ships in almost every first event-driven feature:
```
order = db.save(order)
broker.publish(OrderCreated(order))      ← crash here: the order exists, the event never does
```
Reversing the order publishes events for orders that then roll back. Publishing inside the transaction
doesn't help either: the broker isn't part of the transaction. Each variant loses or invents facts,
and downstream systems silently drift from the database.

**Transactional Outbox** (Richardson): write the event into the **same database, in the same
transaction** as the business change. A relay publishes it afterwards.
```sql
BEGIN;
  INSERT INTO orders (...) VALUES (...);
  INSERT INTO outbox (id, aggregate_type, aggregate_id, type, payload, occurred_at)
              VALUES (gen_random_uuid(), 'order', :order_id, 'OrderCreated.v1', :json, now());
COMMIT;
-- relay (polling publisher):
SELECT * FROM outbox WHERE published_at IS NULL ORDER BY occurred_at LIMIT 100 FOR UPDATE SKIP LOCKED;
--   publish each (message id = outbox.id) → UPDATE outbox SET published_at = now() WHERE id = ...
```
- **Relay options:** a polling publisher (above; `SKIP LOCKED` lets several relays run safely), or
  transaction-log tailing / CDC (Debezium's outbox event router). CDC has lower latency and no polling,
  but it is a component to operate.
- **What you get:** every committed change is published **at least once**. The relay can crash after
  publishing and before marking, so consumers must be idempotent. You never lose an event and never
  publish one for a rolled-back change.
- **Order per aggregate:** publish in `occurred_at` order per `aggregate_id`, and use `aggregate_id` as
  the partition key or message-group id.
- **Operate it:**
  - Monitor **outbox lag**, the age of the oldest unpublished row, and alert on it.
  - Archive or delete published rows on a retention schedule.
- **Generate the message id when the row is inserted**, not at publish time. A re-published row must
  carry the same id, or dedup can't work.
- **When you may skip it:** the event isn't business-critical (analytics, cache warm hints) and losing
  one is acceptable. Write that decision down.

This is a **one-way door** (`judgment.md`). Retrofitting an outbox after months of silent drift means
reconciling two systems' versions of the truth. Adding it with the first event costs one table and a
relay loop.

---

## 3. Idempotent consumers (Helland)

Make processing the same message twice produce the effect once. Cheapest technique first:
```
1. Natural idempotency — "set status = SHIPPED", upsert by business key. Not "increment balance".
2. Dedup table, same transaction as the effect (Richardson's Idempotent Consumer / the inbox):
     BEGIN; INSERT INTO processed_messages(message_id) VALUES (:id);   -- PK violation → already done
            <apply the effect>;  COMMIT;
   Keep rows at least as long as the broker can redeliver (retention ≥ redrive window).
3. Version / sequence check — each event carries the aggregate version; ignore anything ≤ the version
   already applied. This also absorbs reordering (§5).
4. External side effects — pass an idempotency key to the provider (Stripe's Idempotency-Key header).
   For email/SMS: record "sent for <key>" before or atomically with the send; accept that a crash in
   the gap can produce one duplicate, and choose which way that gap fails.
```

---

## 4. Retries, poison messages and the DLQ

- **Classify the failure** (`error-handling.md` taxonomy):
  - *transient* (timeout, 503, lock conflict): retry with exponential backoff + **jitter** (Brooker),
    using the broker's delayed redelivery or visibility timeout. Bounded attempts.
  - *permanent* (validation, unknown type, a bug): **DLQ immediately**. Retrying a deterministic
    failure five times only delays the alert.
- **Visibility timeout / ack deadline > processing p99.** Extend it with a heartbeat for long jobs. Too
  short, and every slow message gets processed twice, concurrently.
- **The DLQ is a work queue for humans, not a bin:**
  - Alert on DLQ depth > 0, or on its growth rate.
  - Store the original message, the error, the attempt count and the consumer version.
  - Have a redrive tool and a runbook ready, and keep DLQ retention longer than the time it takes
    someone to notice.
- **Poison messages in ordered streams** block everything behind them (head-of-line blocking). Either
  park the message (DLQ or a parking-lot queue) and continue, or deliberately stop that partition when
  order matters more than progress. Decide which, per stream.
- **During a dependency incident, throttle the consumer** (`resilience.md` §6: adaptive concurrency
  against a failure-rate set point). Don't burn every message's retries.

---

## 5. Ordering and concurrency

- **Global order** is expensive and almost never needed. **Order per key** is usually what the business
  means (all events of one order, one account):
  - Kafka: partition key;
  - SQS FIFO: `MessageGroupId`;
  - RabbitMQ: a single active consumer, or consistent-hash routing.
- **Competing consumers** give parallelism across keys. Within one key, process one message at a time.
- **Order still breaks** on retries, redrives and replays. The per-aggregate version check (§3.3) is
  what really protects you.
- **Parallelism is capped by partitions** (Kafka). Choose keys with even distribution, because a hot key
  makes a hot partition.

---

## 6. Backlogs — queues hide overload until it's too late (Yanacek)

```
□ The metric is AGE OF THE OLDEST MESSAGE (SQS ApproximateAgeOfOldestMessage, Kafka consumer lag in
  time), not depth. Depth without rate means nothing; age is the user-visible delay. Give it an SLO.
□ Headroom: consumers need capacity ABOVE the steady rate, or a backlog never drains. Autoscale on
  age/lag, and rate-limit toward downstream while draining so recovery doesn't cause the next outage.
□ Expire work nobody wants any more (a message TTL, or skip messages older than N): a 3-day-old
  "your export is ready" is noise. Some workloads should process newest-first after an outage.
□ Isolate workloads and tenants: separate queues (or shuffle sharding) so one tenant's flood
  doesn't delay everyone.
□ Backpressure at the edge: when the backlog passes a bound, reject new work upstream (429/503 +
  Retry-After) rather than accepting a promise you can't keep.
```

---

## 7. Message contracts and evolution

- **A message schema is a public API.**
  - Define it with JSON Schema, Avro or Protobuf, ideally in a schema registry.
  - Validate at the consumer boundary (Boundary 4): a message is external input.
- **Envelope fields:** `message_id`, `type` (with version: `OrderCreated.v1`), `occurred_at`,
  `producer`, `aggregate_id`, `aggregate_version`, `correlation_id`, `causation_id`, W3C
  `traceparent`, then `payload`.
- **Evolve additively:** new optional fields, tolerant readers that ignore what they don't know.
  - A breaking change is a new type version run side by side (expand → migrate → contract,
    `requirement-drift.md`).
  - Consumer-driven contract tests catch the break before production (`team-scale.md`).
- **Fat vs thin events:**
  - *event-carried state* (the full order in the event) spares consumers a callback, but couples them
    to your schema;
  - *notification + fetch* (just the id) keeps events small, but turns every event into a read
    against you.

  Choose per event.
- **Personal data in a retained log:** an immutable log and the right to erasure collide. Put
  references in the event rather than the PII, or encrypt per subject and delete the key
  (crypto-shredding).

---

## 8. Observability and testing

**Observe:**
- publish rate vs consume rate;
- age of the oldest message, consumer lag;
- retries per message type, DLQ depth;
- processing duration p99;
- outbox lag.

Propagate correlation id and trace context in message headers (`observability.md`), with one span for
the publish and one for each consume, so a trace crosses the broker.

**Test:**
```
□ Same message delivered twice → exactly one effect (the idempotency test every consumer needs).
□ Events for one aggregate delivered out of order → final state correct (version check).
□ A permanently failing message → lands in the DLQ after N attempts with its error; the queue moves on.
□ Outbox: kill the relay between publish and mark → after restart the event is published (again),
  and consumers still apply it once.
□ Producer/consumer schema compatibility in CI (contract tests).
□ Backlog drill: stop the consumers, build a backlog, restart → it drains within the SLO and the
  downstream is not overloaded.
```

## 9. Multi-step business processes — sagas

When a business transaction spans services, there is no distributed transaction to lean on
(Helland). Use a **saga**: a sequence of local transactions, each publishing the next step through the
outbox, with **compensating actions** for undo. Orchestration means one coordinator owns the state
machine; choreography means services react to each other's events. Orchestration is easier to reason
about once there are more than about three steps. Compensation design: `error-handling.md`.

---

## The dial

```
SEED      In-process events. Background work via a simple job library on the DB or Redis you have.
          Consumers idempotent from the first one.
VALIDATE  First real broker or job queue for work that must survive restarts. OUTBOX with the first
          event that follows a DB write. DLQ + alert. Visibility timeout > p99.
HARDEN    Age-of-oldest SLO and alerts, retry classification, redrive runbook, schema contracts,
          trace propagation across the broker, backlog drill.
SCALE     Partitioning by aggregate key, per-tenant isolation, CDC relay, consumer autoscaling on lag,
          adaptive consumer concurrency.
```

## Add to CLAUDE.md when the first broker lands

```markdown
## Messaging conventions
- Broker behind an adapter (Boundary 4); no SDK types in the domain.
- Any event that follows a DB write goes through the outbox table, same transaction. No direct publish.
- message_id is set at outbox insert; every consumer is idempotent (processed_messages, same txn).
- Envelope: message_id, type.vN, occurred_at, aggregate_id, aggregate_version, correlation_id, traceparent.
- Transient errors: backoff + jitter, max N attempts. Permanent errors: DLQ immediately.
- DLQ depth > 0 alerts; redrive runbook: [link].
- SLO: age of oldest message < [N] for [queue].

## Debt signals
- TODO[outbox-lag>1min]: relay throughput / batching
- TODO[age-of-oldest>SLO]: consumer headroom, autoscaling on lag, or work isolation
- TODO[dlq-growth]: classify the error; fix or redrive
- TODO[2nd consumer of same event needs replay]: consider a log (Kafka/Streams) over a work queue
```
