# Capacity — scaling the system, one rung at a time

> Every rung of this ladder removes one specific limit and adds a cost you will operate from then on.
> Climb on a measured signal, one rung at a time. The order is not fixed: profiling tells you which
> limit you are hitting. `scaling-guide.md` scales the TEAM and the modules; this file scales the LOAD.
>
> Master anchors: AWS re:Invent, **Scaling up to your first 10 million users** (the rung-by-rung
> reference architecture, 2014–2024) · **Kleppmann**, *DDIA* ch. 5–6 (replication and its anomalies,
> partitioning) · Google **SRE book** ch. 19–22 (load balancing, handling overload, cascading failures)
> · **Dean & Barroso**, *The Tail at Scale* (CACM 2013) · **Little's Law** and **Neil Gunther's**
> Universal Scalability Law · **David Yanacek**, *Implementing health checks* (Amazon Builders'
> Library) · **Martin Fowler**, *MonolithFirst*.

Load this when one box or one database can't keep up, when you are about to add instances, replicas, a
load balancer, autoscaling or a CDN, or when designing file upload/download at any scale.

---

## The two laws you size with

- **Little's Law:** `concurrency = throughput × latency`. At 200 req/s with a 50 ms DB call, you need
  about 10 DB connections busy on average. Size pools, worker counts and instance counts from this
  number, not by guessing. When latency doubles under load, the concurrency you need doubles too.
  That is how pools run dry during incidents.
- **Universal Scalability Law (Gunther):** adding nodes gives less than linear gain, because of
  contention (shared locks, one hot row, one primary) and coherency (nodes keeping each other in
  sync). Past some point, more nodes make it **slower**. When "add servers" stops helping, look for
  the shared thing they all wait on. It is usually the database.

**Tail latency** (Dean & Barroso): if a request fans out to 100 backends whose p99 is 1 s, about **63%**
of requests wait at least 1 s (1 − 0.99¹⁰⁰). Fan-out turns rare slowness into the common case. Remedies:
- keep fan-out small;
- set tight per-call timeouts (Boundary 5);
- send **hedged requests**: a second copy after the p95 delay, use whichever answers first, only for
  idempotent reads;
- degrade gracefully (`resilience.md`).

---

## Rung 0 — one server, but no state in the process (do this at SEED)

The rung every later rung depends on, and the cheapest to get right on day one:
```
✗ uploaded files on local disk           → object storage (S3, GCS, R2, MinIO)
✗ sessions in process memory             → the database or Redis (caching.md §6)
✗ an in-memory map as the record of truth → the database
✗ scheduled jobs that assume one instance → a job queue / a DB-backed scheduler with locking
```
A process holding state can't be replaced, restarted freely or multiplied. Moving state out later
touches every feature, which makes it a quiet **one-way door** (`judgment.md`). The app may still run
on one box for a long time, but it should be able to run on two.

Also from day one: a **managed database with automated backups and point-in-time restore**. A backup is
only real once a restore has actually been tested.

---

## Rung 1 — scale up (vertical)

A bigger instance. It needs no architecture change and no code change, so it is often the right first
answer. The limits are real:
- the hardware tops out, and each size step costs more for less (diminishing returns);
- it is still one machine, a **single point of failure**.

Scale up while it's cheap; don't mistake it for redundancy.

## Rung 2 — make the database survive a failure

- Primary + synchronous standby in another availability zone (Multi-AZ or equivalent).
- The standby is for **failover, not for reads**.
- What the app must do:
  - connect through the provider's endpoint or DNS name, never a node IP;
  - retry connection errors with backoff during the failover window, typically tens of seconds;
  - make writes idempotent so a retried commit doesn't double-apply.
- Practice a failover before you need one.

## Rung 3 — scale out the app behind a load balancer

Several stateless instances (Rung 0 made this possible) behind a load balancer, spread across zones.
Minimum two instances, in two zones.

**Health checks** (Yanacek) decide which instances get traffic, which makes them a frequent cause of
outages:
```
Liveness   "is this process alive?" → restart it if not. SHALLOW: never call dependencies.
Readiness  "should this instance get traffic right now?" → it may check what THIS instance needs
           (warmed up, pool connected), but NOT shared dependencies.
✗ readiness that checks the shared database: the DB has a blip → every instance fails readiness →
  the LB removes all of them → a total outage caused by the health check.
  (Many LBs fail open when every target is unhealthy, but don't rely on it.)
✓ dependency trouble shows up as errors + circuit breakers + alerts, not as instances leaving the pool.
```
**Graceful shutdown:** on SIGTERM, fail readiness, stop accepting new work, finish in-flight requests
within a deadline, then close pools. Deploys and scale-in drop requests without it.

**Balancing algorithm:** round robin assumes every request costs the same, and a 2 GB upload doesn't
cost what a metadata read does. Use **least outstanding requests** / least connections when request
cost varies. **Avoid sticky sessions.** They exist to cover for state that should have left the
process (Rung 0), and they break on instance loss anyway.

**Connection math:**
- Instances × pool size per instance must stay below the database's connection limit.
- Autoscaling from 4 to 40 instances multiplies connections by 10, the classic way autoscaling takes
  down the database.
- Put a pooler in between (PgBouncer, RDS Proxy, or the provider's) before the instance count grows.

## Rung 4 — get heavy bytes and static content off the app

- **Static assets → object storage + CDN** with hashed filenames (`caching.md` §5). App servers stop
  spending bandwidth and CPU on bytes.
- **User files → direct upload with presigned URLs.** The bytes never pass through the app:
```
1. Client → API: "I want to upload {name, size, content_type}"          (validate against policy)
2. API: insert the file record (status = PENDING, server-generated id/key), then return a presigned
   upload URL/form that expires in minutes and is bound to that key.
3. Client → object storage directly.
4. Storage "object created" event → queue → worker: verify size/type from the stored object (never
   trust the client's claim), scan if users upload arbitrary files, set status = READY.
5. Downloads: short-lived presigned GET URLs or a CDN with signed URLs/cookies. Not public buckets.
```
- **Limits:**
  - A presigned PUT alone **does not cap the size**. Use a POST policy with a size range (S3
    `content-length-range`) or the provider's equivalent, and re-check on completion.
  - Anyone holding the URL can use it until it expires, so keep expiry short and scope it to one key.
- The file record and the object can diverge, for example on an abandoned upload. Sweep PENDING
  records older than N hours. Bucket lifecycle rules handle orphaned objects.

## Rung 5 — scale reads: cache, then replicas

Do `caching.md` first for repeated hot reads. Add **read replicas** when read volume itself is the
limit. Replicas are asynchronous, and **replication lag** produces anomalies users notice (DDIA ch. 5):
```
Read-your-writes  a user saves, reloads, and sees the old value → route that user's reads to the
                  primary for a short window after a write (or until the replica has caught up to the
                  write's position).
Monotonic reads   consecutive reads hit different replicas → data appears to go backwards → pin a
                  user/session to one replica.
Consistent prefix an answer is visible before its question → keep causally related writes on one
                  partition, or read them from the primary.
```
- Anything that reads in order to then write (checks, balances, uniqueness) reads from the **primary**.
- Monitor replica lag. When lag passes a threshold, take that replica out of rotation; don't serve
  minutes-old data silently.

## Rung 6 — move work out of the request path

Anything the user doesn't need before the response goes to a queue: email, thumbnails, reports,
webhooks, search indexing. Answer with `202 Accepted` and a status the user can check. The queue absorbs
bursts (load levelling), and workers scale separately from the web tier. The cost is eventual
consistency plus everything in `messaging.md`, starting with the outbox and idempotent consumers.

## Rung 7 — autoscaling

- **Preconditions:** stateless instances, fast startup, correct readiness, graceful shutdown, and
  dashboards.
- **Scale on the metric that saturates first:**
  - CPU for CPU-bound services;
  - in-flight requests per instance for I/O-bound ones;
  - **age of the oldest message** for workers.
- Set cooldowns and scale-in protection, keep `min ≥ 2` across zones, and pre-scale for known events.
  Reactive scaling is minutes too slow for a launch spike.
- **Autoscaling protects your app, not what sits behind it.** It can turn your fleet into a load test
  against your own database and third-party quotas. Cap the max, and keep connection math (Rung 3) and
  downstream rate limits in the plan.

## Rung 8 — scale writes: partition by function, then by key

When the primary's write capacity is the limit, after query and index work, batching, and moving
non-critical writes to async:
1. **Functional partitioning (federation):** each module moves onto its own database. **Boundary 3**
   (modules don't share tables) is what makes this a configuration change instead of a rewrite. If you
   kept it, cross-module joins don't exist and this rung is cheap. If you didn't, this is where the
   bill arrives.
2. **Sharding:** split one table's rows across databases by a **shard key**.
   - The key needs high cardinality, even distribution, and should match the dominant access path.
     Tenant id is a common, good key.
   - Costs: cross-shard queries and transactions get hard; re-sharding needs a plan (directory-based
     placement or consistent hashing); one big tenant can make a hot shard.
   - Prefer a managed distributed database or a sharding layer (Vitess, Citus, cloud distributed SQL)
     over hand-rolled routing.
3. **Move a dataset to NoSQL** when its access pattern is a known key-value or single-partition lookup
   at very high write rates. Design the access patterns first; the schema follows from them.

Past this point (multi-region active-active, cell-based architecture) is outside shipright's scope.
Bring in people who have operated it.

---

## The rung table — signal, rung, ongoing cost

| Signal (measured) | Rung | What you take on |
|---|---|---|
| Restart loses data; can't run 2 instances | 0 — state out of process | object storage, session store |
| CPU/RAM pegged on one box, low traffic variance | 1 — scale up | cost; still a single point of failure |
| A DB host failure = outage | 2 — standby + failover | reconnect/retry logic, failover drills |
| One instance saturates; need zero-downtime deploys | 3 — LB + N instances | health checks, graceful shutdown, pooler |
| App bandwidth/CPU spent on files, timeouts on uploads | 4 — object storage, CDN, presigned | pending/orphan sweeps, signed URLs |
| Repeated reads dominate DB load | 5a — cache | invalidation, stampede, cold start |
| Read volume itself exceeds the primary | 5b — read replicas | lag anomalies, routing rules |
| Slow non-essential work inside requests | 6 — queue + workers | outbox, idempotency, DLQ, backlog SLO |
| Traffic swings daily or seasonally | 7 — autoscaling | connection/quota caps, pre-scaling |
| Primary write-bound after all the above | 8 — federation → sharding | cross-partition queries, re-sharding |

## Add to CLAUDE.md as rungs are climbed

```markdown
## Capacity
- Stateless app: no files, sessions or record-of-truth in process memory. [Rung 0 since <date>]
- Health: liveness shallow; readiness never checks shared dependencies. Graceful shutdown on SIGTERM.
- DB connections: instances(max N) × pool(M) ≤ limit(L) — pooler: [PgBouncer/RDS Proxy].
- Uploads: presigned, size-capped by policy, verified on completion; downloads via signed URLs.
- Replicas: reads after a user's own write go to the primary for [N]s; read-then-write → primary.

## Debt signals
- TODO[p95 > target after query fixes]: next rung per capacity.md table — measure which limit first
- TODO[instances × pool > 80% of DB max_connections]: add a pooler before scaling out further
- TODO[replica lag > Ns]: pull replica from rotation; investigate write volume
```
