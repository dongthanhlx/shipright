# Caching — a correctness decision disguised as a performance one

> A cache is a second copy of your data, and it starts going stale the moment you write it. Every
> production cache incident is one of four: **stale data** someone acted on, a **stampede** that
> flattened the database, a **cold cache** the database couldn't survive, or a **slow cache** that
> stalled every request. Design against all four before the first `SET`.
>
> Master anchors: **Kleppmann**, *Designing Data-Intensive Applications* (derived data, consistency) ·
> **Nishtala et al.**, *Scaling Memcache at Facebook* (NSDI 2013: look-aside, delete-on-write, leases) ·
> **Brinkley & Chhabra**, *Caching challenges and strategies* (Amazon Builders' Library: the cache as a
> dependency, cold start, negative caching, serving stale) · **Vattani, Chierichetti & Lowenstein**,
> *Optimal Probabilistic Cache Stampede Prevention* (VLDB 2015, XFetch) · **Kleppmann**, *How to do
> distributed locking* (2016) · **Tarjan**, *Scaling your API with rate limiters* (Stripe, 2017) ·
> the **Redis** documentation (eviction, memory, latency).

Load this when `performance.md`'s ladder reaches step 4, when you are about to add Redis or any cache,
when a stale-data / stampede / hot-key incident happens, or when you need rate limiting or sessions.

---

## 0. The gate — answer these before caching anything

```
□ Ladder steps 1–3 are done (performance.md): profiled, query fixed, work reduced. A cache in front
  of a missing index hides the bug and doubles the system.
□ Source of truth is named. The cache is never it. If losing the cache loses data, it's a database
  without durability, not a cache.
□ Maximum acceptable staleness is written down per data class: a PRODUCT decision, not a technical
  default. "How old may this be when a user acts on it?"
□ Hit ratio is plausible: the same keys are read many times between writes. A uniform or long-tail
  access pattern gets a low hit ratio and all the cost.
□ Cache outage plan: what happens when Redis is down or slow? (§3: the cache is a dependency.)
```

Staleness by data class: a starting point to argue with, not a rule.

| Data | Typical tolerance | Pattern |
|---|---|---|
| Static assets (hashed filenames) | forever | CDN, `Cache-Control: max-age=31536000, immutable` |
| Config, feature flags, catalog | seconds → minutes | TTL + jitter, L1 in-process OK |
| User profile, settings | the writer must see their own write | delete-on-write; writer reads bypass or invalidate |
| Permissions, roles, API keys | revocation must bite fast | short TTL + invalidate on revoke: a stale grant is a security hole |
| Balances, inventory, prices at checkout | none at the moment of decision | don't cache the authoritative check; cache only the display |

---

## 1. Patterns — cache-aside by default

```
Cache-aside (look-aside, demand-filled) — the default:
  read:  v = cache.get(k); if miss → v = db.load(k); cache.set(k, v, ttl); return v
  write: db.write(...)  → COMMIT →  cache.delete(k)        ← delete, not set
```

- **Delete on write, don't set.** Two concurrent writers that each `SET` their own value can leave the
  older one in cache forever. Delete makes the next reader load the truth. Facebook's memcache made
  this its write rule.
- **Delete after the transaction commits**, never before and never inside it. Before commit, a reader
  can reload the old row and re-cache it. If the delete itself must not be lost, publish it as an
  event through the outbox (`messaging.md` §2) or tail the DB log (CDC). Don't fire and forget.
- **The race cache-aside still has:** reader misses → loads the OLD row → writer commits + deletes →
  reader `SET`s the old value → stale until TTL. Mitigations, cheapest first:
  1. TTL is the safety net: it bounds every staleness bug. **No key without a TTL.**
  2. Versioned values: store `{version, value}` and only overwrite with a higher version (compare in a
     Lua script).
  3. Leases (Facebook): a miss hands out a lease token, a `SET` is accepted only with a valid token,
     and a delete invalidates outstanding tokens. The stale `SET` is rejected.
- **Read-through / write-through** move the same logic into a library or the cache itself. They're fine,
  with the same rules. **Write-behind** (write cache now, DB later) trades durability for latency. It is
  rarely right for business data: a crash loses acknowledged writes.

---

## 2. TTL, freshness and serving stale

- **Every key gets a TTL.** It bounds staleness, memory, and the blast radius of every bug above.
- **Add jitter** (±10–20%) so keys filled together don't expire together. A deploy that warms 1M keys
  with the same TTL schedules its own stampede for one TTL later.
- **Soft vs hard TTL** (Builders' Library): past the soft TTL, serve the value and refresh it in the
  background. Past the hard TTL, the value is unusable. Most of the latency win without serving very old
  data.
- **Serve stale on error.** If the source is down, a slightly old value beats a 500 (`resilience.md` §5
  graceful degradation). Over HTTP: `stale-if-error`, `stale-while-revalidate` (RFC 5861). Decide per
  data class. Never for permissions or money.
- **Negative caching:** cache "not found" briefly (seconds). Without it, every request for a
  missing key hits the DB. Repeated bad lookups and enumeration attacks are exactly that.

---

## 3. The four failure modes, and the fix for each

### Stampede (thundering herd, dog-pile)
A hot key expires; a thousand concurrent requests miss at once; a thousand identical queries hit the
database, which slows down, so more requests pile up. Fix in layers:
```
□ Request coalescing / single-flight: per process, one in-flight load per key; others await it.
  (Go: golang.org/x/sync/singleflight. Node: a Map<key, Promise>. Python: a per-key asyncio.Lock.)
□ One recomputer across the fleet: a short lock (SET k:lock NX PX 5000). The winner reloads; the rest
  serve stale (soft TTL) or wait briefly and re-read. This lock is for EFFICIENCY only (§6).
□ Probabilistic early expiration (XFetch): each reader recomputes early with a probability that rises
  as expiry nears:  recompute if  now − δ·β·ln(rand()) ≥ expiry
  (δ = how long the recompute takes, β ≈ 1, rand() ∈ (0,1]). No locks, no coordination.
□ TTL jitter (§2) so expiries don't line up in the first place.
```

### Hot key
One key takes a large share of traffic, and the one Redis shard that owns it saturates while the rest
idle. Fixes:
- an in-process L1 in front with a TTL of a second or two;
- replicate the key (`k#1…k#N`, read a random suffix);
- don't let one tenant's key dominate: isolate it, or rate-limit the tenant.

Find hot keys with `redis-cli --hotkeys` (needs an LFU eviction policy) or per-prefix metrics.

### Cold cache
After a flush, a new cluster, a failover or a region move, the hit ratio is 0% and the database takes
100% of the read load. **If the database can't survive a cold cache, the cache is load-bearing.**
Treat its loss as an outage scenario:
- test it under load;
- warm up gradually: ramp traffic, or pre-load the top keys;
- protect the DB with a concurrency limit while the cache refills.

### Slow cache
A cache call without a timeout is the worst kind of dependency: it is on every request.
- Timeouts in milliseconds (Boundary 5).
- Circuit-break on errors and fall through to the database behind a concurrency limit, or serve
  degraded.
- Alert on p99 latency, not just errors.

The cache exists to make things faster. It must never be able to make everything slower.

---

## 4. Redis in production — keys, values, memory, commands

**Keys:** `app:v3:user:42:profile`, meaning namespace, **shape version**, entity, id, facet.
- Bump the version when the cached shape changes: every old key becomes invisible at once, with no
  mass delete.
- Include the tenant id in multi-tenant systems.
- Normalize anything derived from user input before it becomes a key; unbounded raw input means
  unbounded keys.

**Values:**
- Cache a DTO with an explicit schema, not an ORM entity. A lazy relation inside the cached object
  turns a cache hit into N database calls.
- Keep values small (tens of KB). Large values block Redis's command thread and the network; split or
  compress them.

**Memory and eviction:**
- Always set `maxmemory` and an eviction policy.
- For a pure cache use `allkeys-lfu` or `allkeys-lru`. Use `volatile-*` only when the instance also
  holds keys that must not be evicted.
- Better: **separate instances for cache and for durable-ish data** (sessions, rate-limit counters,
  queues, locks), each with its own policy. `noeviction` is for data you can't lose, which means it is
  no longer a cache.

**Commands:** Redis runs commands on one thread per instance, so one slow command delays every client.
```
✗ KEYS pattern            → SCAN with a cursor
✗ HGETALL / SMEMBERS / LRANGE 0 -1 on huge collections → paginate (HSCAN/SSCAN), cap collection size
✗ DEL on a key with millions of members → UNLINK (frees memory in the background)
✓ Pipeline batches (fewer round-trips); MGET for multi-key reads; Lua for atomic read-modify-write
✓ A connection pool, sized like any pool (capacity.md, Little's Law)
```

**Replication and persistence:**
- Redis replication is asynchronous, so a failover can lose the last writes. That is fine for a cache
  and dangerous for locks (§6).
- A cache tier rarely needs persistence. A durable-ish tier (sessions, queues) needs AOF and a clear
  answer to what a failover loses.

**Observe:**
- hit ratio per key prefix (not a global average);
- p99 command latency, evictions per second, memory used vs `maxmemory`, connected clients, slowlog.

Alert on a hit-ratio collapse and an eviction spike. Both come before a database overload.

---

## 5. Layers — in-process → Redis → CDN

```
L1 in-process  ~µs, per instance → instances disagree. Short TTL (seconds), BOUNDED size (LRU).
               An unbounded map is a memory leak with a cache's name (performance.md).
L2 Redis       ~sub-ms to ms, shared, one network hop. The default shared cache.
HTTP / CDN     at the edge, closest to the user. Static bytes always; dynamic responses with care.
```

HTTP caching rules that prevent the classic incidents:
- **Personalized responses are `Cache-Control: private`** (or `no-store`). A shared cache that keeps
  one user's page serves it to the next user: a data leak.
- Set `Vary` for every request header that changes the response.
- Static assets carry a content hash in the filename: `max-age=31536000, immutable`, so deploys never
  need a purge.
- Use `ETag` / `If-None-Match` for cheap revalidation, and `s-maxage` to give the CDN a different TTL
  from browsers.
- Know how to purge: by URL, tag or surrogate key. Then test it, before the day you need it.

---

## 6. Redis beyond caching — each use has its own correctness rule

**Sessions:**
- An external session store is what makes app servers stateless, so no sticky sessions are needed
  (`capacity.md`, Rung 3).
- TTL = idle timeout.
- Rotate the session id on login (session fixation) and revoke on logout or password change.
- Sessions are durable-ish data: separate instance, and don't evict them under memory pressure.

**Rate limiting** (Stripe; Brandur Leach, *Rate Limiting, Cells, and GCRA*):
```
Fixed window       simple; allows 2× burst across a window boundary
Sliding window log exact; memory grows with request count
Sliding counter    approximate, cheap; good default for per-user API limits
Token bucket / GCRA  bursts up to capacity, steady refill; GCRA needs one timestamp per key
```
- **Make the check atomic.** Use a Lua script, or `INCR` + `EXPIRE` in one `MULTI`. A
  read-then-write check from the app races itself.
- **Key by the authenticated principal** (user, API key, tenant) where possible. IP-only limits punish
  shared NATs and miss distributed abuse.
- Respond `429` with `Retry-After`. Stripe ran four limiters: request rate, concurrent requests, a
  fleet-usage load shedder and a worker-utilization load shedder. Concurrency is its own limit, not a
  rate.
- **Decide what happens when Redis is down:**
  - *fail-open* (allow, with a local in-process fallback limit) for ordinary user-facing limits;
  - *fail-closed* where the limit protects money or cost: paid third-party calls, LLM spend, SMS.

**Distributed locks** (Kleppmann vs Redlock):
- `SET k NX PX ttl` is fine for **efficiency**, to stop two workers doing the same work.
- It is **not** enough for **correctness**, where two holders at once would corrupt data. A GC pause,
  clock jump or failover can leave two processes each believing they hold the lock.
- For correctness, use one of:
  - a **fencing token**: a monotonically increasing number the protected resource checks, rejecting
    older tokens;
  - the database's own guarantees: unique constraint, `SELECT … FOR UPDATE`, optimistic version column;
  - a consensus system (etcd, ZooKeeper).

Rule: if a double holder loses money or corrupts data, a Redis lock alone is not the answer.

**Idempotency keys:**
- Fine in Redis with a TTL for dedup of retries (`resilience.md` §7).
- For money, the key lives in the database under a unique constraint, in the same transaction as the
  effect. Structural, not best-effort.

**Queues on Redis** (lists, Streams, BullMQ, Sidekiq): a real broker at small scale. Every rule in
`messaging.md` applies, plus Redis's: AOF for durability, memory limits on backlog, and no eviction on
that instance.

---

## 7. Testing a cache

```
□ The cache-aside wrapper with a fake clock: TTL honoured, jitter applied, negative caching expires.
□ Read-your-writes: write → read by the same user returns the new value (invalidation actually ran).
□ The race: interleave a slow reader with a writer (or test the version / lease guard directly).
□ Fault: Redis down → requests still served within the latency budget (degraded), errors bounded.
□ Fault: Redis slow (inject latency above the timeout) → the timeout fires; no request stalls.
□ Load test with a COLD cache: the database survives the refill.
□ Stampede: N concurrent misses on one key → one load (single-flight / lock), not N.
```

---

## 8. The dial — what to add at each phase

```
SEED      No application cache. HTTP-cache static assets (hashed filenames). Fix queries instead.
VALIDATE  Cache-aside on the 1–2 reads that measurably dominate. TTL + jitter. Delete-on-write.
          Timeouts on every cache call. Hit-ratio metric for those prefixes.
HARDEN    Stampede protection on hot keys. Cold-cache and cache-outage tests. Separate instances
          for cache vs sessions/counters. Rate limiting where abuse or cost is real.
SCALE     L1 + L2 for hot paths, hot-key replication, CDN for dynamic content with
          stale-while-revalidate, invalidation via outbox / CDC.
```

## Add to CLAUDE.md when the first cache lands

```markdown
## Caching conventions
- Cache-aside. Write path: COMMIT, then DELETE the key (never SET on write).
- Every key has a TTL with ±15% jitter. Key format: app:v<shape>:<entity>:<id>[:facet].
- Staleness budget per data class: [table]. Permissions/money: never trust the cache at decision time.
- Cache calls: timeout [N]ms; on error fall through to DB behind a concurrency limit.
- Redis instances: cache (allkeys-lfu) separate from sessions/counters (noeviction).
- Locks in Redis are for efficiency only; correctness uses DB constraints or fencing tokens.

## Debt signals
- TODO[hit-ratio<80% on <prefix>]: reconsider what is cached, or the TTL
- TODO[db-cpu spike on cache flush]: cold-start protection (warm-up / concurrency limit)
- TODO[p99 cache latency > Nms]: hot key or large values — inspect
```
