# Resilience — the operation hemisphere (Michael Nygard, *Release It!*)

> Large systems rarely die from a logic bug. They die from **failure propagation** —
> one slow dependency stalls every thread, which stalls every caller, until the whole
> system is down. Nygard's stability patterns stop the spread.
>
> **Boundary 5 (failure isolation):** every integration point must have a timeout +
> a deliberate fallback. No exceptions once you reach the HARDEN phase.

Load this file on the resilience L4 signals, or whenever a feature adds a new integration
point (external API, DB, queue, another service) at VALIDATE+ phase.

---

## When this hemisphere turns on (the dial)

Resilience is mostly OFF at SEED — adding it early is over-engineering (see
`references/judgment.md` §2, the "expensive + reversible" quadrant). It turns on by signal:

```
SEED (MVP)     → only timeouts on outbound calls + idempotency for side effects.
                 Everything else: NO. A circuit breaker with 3 users is theater.
VALIDATE       → + retry with backoff+jitter + graceful degradation on the 1-2 calls
                 that fail most.
HARDEN         → + circuit breakers + bulkheads + Boundary 5 enforced everywhere.
SCALE          → + backpressure + load shedding + steady-state guarantees.
```

The trigger is always a real integration point or a measured failure — never a stage label
alone.

---

## The anti-patterns Nygard names (what you are defending against)

```
Integration points      Every call to another system is a crack failure enters through.
                        Most outages start at an integration point. Default to suspicion.
Chain reactions         One node fails → its load shifts to peers → they fail too.
Cascading failures      A failure in dependency B brings down caller A brings down caller of A.
                        Circuit breakers exist to stop exactly this.
Slow responses          Worse than fast failures: a slow dependency holds your threads
                        hostage. A timeout converts a slow failure into a fast one.
Unbounded result sets   "SELECT * " with no LIMIT works in dev (10 rows), OOMs in prod
                        (10M rows). Always bound what a query / API page can return.
```

---

## The 8 stability patterns

### 1. Timeout — never wait forever
Every outbound call (HTTP, DB, queue, RPC) has an explicit timeout. The default of "no
timeout" means "wait until the OS gives up," often minutes, while a thread is held hostage.

```typescript
// Outbound HTTP — always set timeout. Connect + total separately if the client allows.
const res = await httpClient.get(url, { timeout: 3000 })  // 3s, not infinite
// DB pools: statement_timeout + pool acquire timeout. Queues: visibility/ack timeout.
```
Signal it's missing: a dependency slows down and YOUR latency/thread count explodes with it.

### 2. Retry with backoff + jitter + budget — recover without a stampede
Retry only **transient** failures (timeout, 503, connection reset). NEVER retry
non-idempotent writes without an idempotency key, and NEVER retry 4xx validation errors.

```typescript
async function retry<T>(fn: () => Promise<T>, max = 3): Promise<T> {
  for (let attempt = 0; ; attempt++) {
    try { return await fn() }
    catch (e) {
      if (attempt >= max || !isTransient(e)) throw e
      const base = 200 * 2 ** attempt              // exponential: 200, 400, 800ms
      const jitter = Math.random() * base          // jitter prevents synchronized retries
      await sleep(base + jitter)
    }
  }
}
```
**Retry budget:** cap retries to a fraction (e.g. 10%) of total requests. Unbounded retries
during an outage = a self-inflicted DDoS on a dependency that's already struggling.

### 3. Circuit Breaker — stop hammering a dead dependency
After N failures in a window, OPEN the circuit: fail fast (or fall back) without calling.
After a cool-down, allow one HALF-OPEN trial; success → CLOSE, failure → OPEN again.

```
CLOSED  → calls pass through, failures counted
OPEN    → calls fail instantly (or use fallback), no load on the sick dependency
HALF-OPEN → one trial call decides whether to close or re-open
```
Use a library (opossum for Node, pybreaker/tenacity for Python) — don't hand-roll the state
machine. The breaker is what converts a chain reaction into a contained, observable event.

### 4. Bulkhead — isolate resources so one failure can't sink the ship
Named after ship compartments. Give each dependency its own resource pool so exhausting one
doesn't starve the others.

```
✗ One shared connection/thread pool for DB + payment API + email:
   payment API hangs → pool exhausts → DB calls can't get a connection → whole app down.
✓ Separate pools per dependency (or per criticality tier):
   payment API hangs → only the payment pool exhausts → DB + email keep serving.
```
Cheapest bulkhead: separate connection pools. Stronger: separate worker queues, separate
deployments for the most critical path.

### 5. Graceful degradation — partial service beats no service
When a non-critical dependency is down, degrade the feature, don't fail the request.

```
Recommendations service down → show popular items, not a 500.
Avatar CDN down → show initials placeholder.
Search ranking model down → fall back to keyword search.
```
Decide per feature at design time: *what is the acceptable degraded state?* Pair every
circuit breaker with a fallback — an open breaker with no fallback is just a faster error.

### 6. Backpressure / load shedding — protect yourself from too much demand
When you can't keep up, reject early and cheaply rather than collapse for everyone.

```
Bounded queues: drop or reject when full instead of growing memory until OOM.
Shed load: return 429 + Retry-After under overload — fail 5% fast, serve 95% well,
           instead of failing 100% slowly.
Admission control: protect the critical path (checkout) by shedding the optional (analytics).
```

**The other side: a queue consumer whose dependency is struggling.** A normal worker is greedy: when
it has a free slot, it polls another message. If the downstream degrades, the worker keeps pulling at
full speed. Every message burns its retries against a dependency that can't answer, then lands in the
DLQ. The usual tools don't fit this case well:
- A fixed rate limit is wrong whenever capacity changes.
- An open/closed breaker swings between full speed and nothing, and its re-close is a new spike.
- Per-message backoff spaces out one message but not the fleet's total pressure.

What works is letting the consumer **throttle its own intake**. After each message, record ok or failed.
Keep a failure-rate **set point**, the error rate you accept as normal, say 5%. Below it, change
nothing. Above it, cut the permits the worker may poll at once, a step at a time. When failures fall
back under the set point, step them back up. Work waits in the queue, which is the cheap place for it
to wait, and no message is retried to death. Canva's shared queue library does this per instance,
with no coordinator. Over a 32-hour downstream quota overload they saw ~1.8M failed attempts and
only 22 messages in the DLQ. The cost is honest: throughput drops while the dependency is sick, and
that hurts more if workers normally run at full capacity. This is what SKILL.md's L4 signal "retries
storm a struggling dependency" looks like when the caller is a queue consumer; the signal to watch is
DLQ growth during a dependency incident.

### 7. Idempotency — make retries safe (structural, not in-memory)
Any operation with a side effect must be safe to call twice (retries, at-least-once queues,
user double-clicks all cause duplicates). The dedup store is the DB or Redis — **never an
in-memory Map**, which is lost on restart and invisible to other instances.

```
client sends Idempotency-Key → server checks store → seen? return prior result
                                                    → new? execute, persist key+result
```
This is the same rule the blockchain custodial-wallet stack enforces; it generalizes to all
payments, webhooks, and queue consumers.

### 8. Steady state — the system must run unattended
Anything that grows without bound will eventually take you down. Cap it.

```
Logs → rotation + retention. Sessions/temp rows → TTL + cleanup job.
Caches → max size + eviction. Connections → pooled + reaped.
Result sets → always LIMIT / paginate. Queues → max length + dead-letter.
```
The test: *could this run for 90 days with no human touching it?* If any resource only grows,
the answer is no.

---

## Fault-injection tests — PROVE resilience, don't assume it

Correctness tests prove the happy/edge/error path of one unit. They do NOT prove the system
survives a failing dependency. Add failure-mode tests when you add resilience (HARDEN phase):

```typescript
describe('PaymentService resilience', () => {
  it('dependency timeout → request fails fast, not hung', async () => {
    gateway.charge = () => new Promise(() => {})        // never resolves
    const start = Date.now()
    await expect(service.pay(order)).rejects.toThrow(TimeoutError)
    expect(Date.now() - start).toBeLessThan(3500)        // timeout fired, no hang
  })

  it('circuit open → returns fallback, makes zero downstream calls', async () => {
    breaker.forceOpen()
    const spy = vi.spyOn(gateway, 'charge')
    const r = await service.pay(order)
    expect(r.status).toBe('queued_for_retry')             // graceful degradation
    expect(spy).not.toHaveBeenCalled()                    // no load on sick dependency
  })

  it('same idempotency key twice → charged once', async () => {
    await service.pay(order, { key: 'k1' })
    await service.pay(order, { key: 'k1' })               // retry / double-click
    expect(gateway.charge).toHaveBeenCalledTimes(1)
  })
})
```

---

## Add to CLAUDE.md when resilience is introduced

```markdown
## Resilience conventions (Nygard — added [date])

Boundary 5: every integration point has an explicit timeout + a defined fallback.
Outbound timeouts: HTTP [N]ms, DB statement [N]ms, queue ack [N]s.
Retries: transient errors only, backoff+jitter, max [N], retry budget [X]% of traffic.
Circuit breakers on: [list of dependencies]. Fallback for each: [defined behavior].
Bulkheads: separate pool per [dependency]. Critical path: [name] never shares a pool.
Idempotency: keys stored in [DB/Redis] — never in-memory. Applies to: [operations].
Steady state: [resource] capped by [rotation/TTL/eviction/LIMIT].
```

---

## What this file does NOT cover (hand off when you reach it)

```
✗ Distributed consensus / quorum (Raft, Paxos) — specialized, consult an expert.
✗ Saga ORCHESTRATION at scale (workflow engines, durable execution, cross-service compensation
  infrastructure) — needs dedicated study + tooling. The basic saga shape (compensating actions in
  code) IS covered: references/error-handling.md §Saga Pattern.
✗ Multi-region failover, chaos engineering platforms (Gremlin) — SRE org practice.
✗ Service mesh retry/circuit config (Istio/Linkerd) — infrastructure, not app code.
```
Shipright gets the application-level stability patterns right. Beyond that you need
distributed-systems specialists and SRE practice (see `references/levels.md` graduate list).
