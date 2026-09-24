# Debug: Intermittent & Production-Only Bugs

For bugs that don't reproduce consistently. Loaded from Branch C (c-fix-bug.md) Step 0 when the bug is
intermittent, production-only, or grows over time (a resource leak) — pick the matching section below.

---

## Intermittent (happens sometimes, unknown trigger)

### Step 1 — Add structured logging, don't guess

```
Add log context at every relevant entry point:
  logger.info({ userId, input, timestamp, requestId }, 'operation started')
  logger.info({ result, duration }, 'operation completed')
  logger.error({ error, context }, 'operation failed')

Deploy. Wait for bug to occur. Read logs around the timestamp.
```

### Step 2 — Find the pattern in occurrences

```
Collect N occurrences (N >= 5 for meaningful pattern):
  □ Time of day? (timezone issue, cron overlap)
  □ Specific user/tenant? (data-specific bug)
  □ After specific sequence of actions? (state accumulation)
  □ Under load? (race condition, connection pool exhaustion)
  □ After uptime reaches X hours? (memory leak, connection leak)
```

### Step 3 — Hypothesis → targeted test

```
Once pattern found, form hypothesis:
  "Bug occurs when [condition]"

Write test that forces the condition:
  Race condition → concurrent execution test (Promise.all with N instances)
  State accumulation → run operation N times in sequence
  Data-specific → test with exact data shape from occurrence
```

### Step 4 — Fix race conditions specifically

```typescript
// If race condition confirmed:
// Option A: Make operation idempotent (preferred)
async function processItem(id: string) {
  // Use database atomic operation instead of read-then-write
  await db.query(
    'INSERT INTO processed (id) VALUES ($1) ON CONFLICT DO NOTHING',
    [id]
  )
}

// Option B: Distributed lock
async function processItem(id: string) {
  const lock = await acquireLock(`process:${id}`, ttl: 30000)
  if (!lock) return // another instance is processing
  try { await doProcess(id) }
  finally { await lock.release() }
}
```

---

## Production-only bugs

### Likely causes (check in order)

```
1. Environment difference
   □ Compare env vars: prod vs local
   □ Compare dependency versions: prod vs local (package-lock.json)
   □ Compare data: prod data shape vs local fixtures

2. Scale difference
   □ Does bug happen only under load? → load test locally
   □ Connection pool exhausted? → check pool size vs concurrent requests
   □ Timeout different? → prod has stricter timeouts?

3. Configuration difference
   □ Feature flags different?
   □ External service credentials?
   □ TLS/SSL settings?
```

### Step 2 — Reproduce locally with prod data shape

```
Export minimal dataset from prod that triggers the bug.
Anonymize PII before using in local dev.
Run locally with prod-like config (use .env.prod-like file).
```

### Step 3 — Add production observability

```
If still can't reproduce locally → add observability to prod:
  □ Correlation ID on every request (if not already present)
  □ Log full request context when error occurs
  □ Add metrics: error rate, latency p99, memory usage

Deploy observability changes first. Wait for next occurrence.
Read traces → find exact execution path that led to error.
```

---

## Resource leak (memory growth, connection leak)

### Step 1 — Confirm it's actually a leak

```
Memory leak symptoms:
  □ Memory grows over time, doesn't drop after requests complete
  □ Process needs restart every N hours/days
  □ Garbage collection pauses getting longer

Connection leak symptoms:
  □ "Too many connections" error after uptime
  □ DB connections saturated, but low request rate
```

### Step 2 — Locate the leak

```
Memory leak:
  □ Take heap snapshot at T=0, T=1h, T=2h
  □ Compare: what object type grew? (use node --inspect, Chrome DevTools)
  □ Common causes: event listeners not removed, closures capturing large objects,
    cache without TTL or size limit, global arrays being pushed to

Connection leak:
  □ Query: SELECT count(*) FROM pg_stat_activity; — growing?
  □ Find code: every db.connect() must have a matching release()
  □ Check: try/catch/finally — connection released even on error?
```

### Step 3 — Fix and verify

```typescript
// Connection leak fix pattern:
const client = await pool.connect()
try {
  await client.query('...')
} finally {
  client.release() // ← must be in finally, not just happy path
}

// Memory leak: cache with TTL
const cache = new Map()
function setWithTTL(key, value, ttlMs) {
  cache.set(key, value)
  setTimeout(() => cache.delete(key), ttlMs) // ← cleanup
}
```

After fix: run for 24h and compare memory/connection count at same intervals.
If growth rate is 0 → fixed. If slower but still growing → partial fix, keep looking.
