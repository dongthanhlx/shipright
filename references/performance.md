# Performance — measure first, optimize the bottleneck only

> "Premature optimization is the root of all evil" (Knuth) — but the full quote ends
> "...yet we should not pass up our opportunities in that critical 3%."
> The discipline: do nothing on a guess; do everything on a measurement.
> Pairs with Martin Thompson's mechanical sympathy — know what the machine actually does.

Load this on an L4 performance signal, or when designing a data-access path that will run
hot. Most performance work is L4 (signal-driven). A few things below are cheap enough and
structural enough to get right earlier — they are marked.

---

## The iron rule: a signal before any optimization

Never optimize without this (same format as `references/levels.md` L4):

```
Signal:  [metric] = [measured value]      e.g. p95 latency = 1.8s
Target:  [what it should be]              e.g. p95 < 300ms
Context: [when — peak? a query? a user?]  e.g. on /feed during morning cron overlap
```

No signal → no optimization. "This could be faster" is not a signal; it's a guess that adds
complexity for a problem that may not exist at your scale. Profile, find the actual hot path,
fix that one thing, measure again.

---

## Structural choices to get right EARLY (cheap now, expensive later)

These are not "optimizations" — they are designed-in, and retrofitting them is costly.
Per `references/judgment.md`, they sit closer to one-way doors:

```
□ N+1 queries — the #1 silent killer. A loop that queries per item turns 1 request into
  hundreds. Fix at design time: batch (WHERE id IN (...)), JOIN, or a dataloader.
    ✗ for (const o of orders) o.user = await repo.findUser(o.userId)   // N+1
    ✓ const users = await repo.findUsers(orders.map(o => o.userId))    // 1 query, map in memory

□ Bounded result sets — always paginate / LIMIT. Unbounded reads work in dev, OOM in prod.
  (Same rule as resilience.md steady-state — performance and stability meet here.)

□ Indexes on what you filter/sort by — add the index when you write the query, not after the
  slow-query alert. A missing index on a foreign key is the most common prod latency cause.

□ Async/await placement — don't await in a loop when calls are independent.
    ✗ for (const id of ids) await fetch(id)                 // serial
    ✓ await Promise.all(ids.map(fetch))                     // parallel (mind rate limits / pool size)

□ Payload shape — don't SELECT * then drop fields in app code; don't over-fetch nested data
  the caller ignores. Move the filtering to the query.
```

Everything else below waits for a signal.

---

## When the signal fires — the optimization ladder (cheapest first)

Work top to bottom. Do not jump to caching/replicas before fixing the query.

```
1. Profile          Find the actual bottleneck. Never optimize what you didn't measure.
                    Tools: Node --prof / clinic.js / 0x; Python cProfile / py-spy;
                    DB EXPLAIN ANALYZE. The bottleneck is usually NOT where you guessed.

2. Fix the query    Missing index? N+1? Full table scan? Sequential scan on a filter column?
                    90% of "slow app" is "slow query." Fix here before touching app code.

3. Reduce the work  Do less: paginate, project fewer columns, compute incrementally,
                    move work out of the request path (defer to a job/queue).

4. Cache            Only after 1–3. Cache the expensive, frequently-read, rarely-changed.
                    Decide invalidation FIRST (the hard part). TTL is the simplest correct
                    strategy; event-based invalidation only when staleness is unacceptable.
                    Layer order: in-process → Redis → CDN. Each adds a consistency cost.

5. Scale the resource  Connection pooling → read replica → partition/shard.
                    Last resort, highest operational cost. A read replica fixes read-heavy
                    DB CPU; it does nothing for a missing index (fix that first).
```

| Signal | First thing to try (not last) |
|---|---|
| p95 latency > target | Profile → almost always a query or N+1 → fix that |
| DB CPU > 60% | EXPLAIN the top queries → add index → then connection pooling → then read replica |
| Memory grows over time | Find the leak (unbounded cache/array/listener) → cap it, don't add RAM |
| External API quota burned early | Cache responses → batch → dedup identical in-flight calls |
| Throughput ceiling | Parallelize independent work → async I/O → then horizontal scale |

---

## Mechanical sympathy — know what the machine does (Martin Thompson)

You don't need to be a systems programmer, but a few realities prevent whole classes of
slowness:

```
I/O dominates. A DB round-trip (~1ms LAN) is ~millions of CPU cycles. Cutting one query
  beats micro-optimizing a loop by orders of magnitude. Count round-trips before counting ops.

Allocation isn't free. In hot paths, avoid creating garbage per item (new objects/closures in
  a tight loop). Reuse buffers; stream instead of building giant arrays.

The event loop is single-threaded (Node). A synchronous CPU-heavy task (big JSON.parse, crypto,
  image resize) blocks EVERY request. Offload to a worker thread / separate service.

Sequential beats random. Bulk/batch operations and ordered scans are far cheaper than many
  scattered point lookups — at the DB and at the CPU cache level.
```

---

## Benchmark before/after — prove the win

An L4 fix isn't done until a benchmark proves it and guards against regression:

```typescript
// The fix must show measured improvement AND not change behavior.
it('feed query stays under budget', async () => {
  const t = await measure(() => service.getFeed({ page: 1, size: 50 }))
  expect(t.p95).toBeLessThan(300)       // the budget, now enforced in CI
})
```

`What "done" looks like` (from levels.md L4): metric within target (measured, not assumed),
benchmark exists, no public interface changed, no new dependency without an ADR.

---

## Performance budgets — make "fast enough" explicit

Vague targets never get met. Write budgets into ARCHITECTURE.md so they're enforceable:

```markdown
## Performance budgets
| Path                | Budget       | Measured at        |
|---------------------|--------------|--------------------|
| GET /feed (p95)     | < 300ms      | load test, 100 vus |
| Checkout (p99)      | < 800ms      | prod APM           |
| Cron full crawl     | < 5 min      | job duration log   |
| Bundle (initial JS) | < 200KB gzip | CI bundle check    |
```

Frontend / Core Web Vitals: that's a deep specialty — hand off to a web-performance skill
(`agent-skills:webperf` / web-performance-auditor) rather than guessing here.

---

## Add to CLAUDE.md after a performance fix

```markdown
## Performance notes (learned)
- [path] was slow due to [N+1 / missing index / unbounded set] — fixed by [what]. Budget: [target].
- Hot paths in this project: [list] — profile before changing.
- Known indexes that matter: [table.column] — do not drop.
```
