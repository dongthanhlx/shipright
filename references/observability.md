# Observability — Logging, Tracing, Alerting

## Integration with Shipright state

When adding observability to a project, update CLAUDE.md Shipright state:
```markdown
## Shipright state
Level: L4
Active: observability setup
Next: verify Correlation ID flows end-to-end (curl request → check logs → find requestId)
Last updated: [date]
```

Observability is a L4 concern — only add when production signal demands it.
See SKILL.md L4 signals table for when each layer (Correlation ID / Sentry / OpenTelemetry) is appropriate.

---

## The core principle

Observability is not "add monitoring later."
It is designing your system so that when something breaks in production,
you can answer: what happened, where, when, why, with what input.

Without observability: "YouTube API is failing" → hours of guessing.
With observability: "YouTube API call at 14:32:01 with symbol=AAPL returned 429,
requestId=abc-123, after 2 retries, circuit breaker opened" → minutes to diagnose.

---

## Stage-based: add only what you need

```
MVP stage     → Correlation ID + structured error logging
Traction      → Structured logging everywhere + Sentry/Bugsnag
Growth        → OpenTelemetry distributed tracing + alerting on SLOs
Scale         → Full observability platform (Datadog, Grafana, etc.)
```

Do NOT add OpenTelemetry in MVP. Correlation ID costs 30 minutes to add
and gives 80% of the debugging value at 1% of the operational cost.

---

## Correlation ID — add from day one, always

A Correlation ID is a unique identifier attached to every request.
It flows through every log line, every service call, every third-party API call.
When something breaks, you search logs for the ID and see the complete picture.

### Node.js implementation

```typescript
// shared/request-context.ts
import { AsyncLocalStorage } from 'async_hooks'
import { randomUUID } from 'crypto'

const storage = new AsyncLocalStorage<{ requestId: string; startedAt: number }>()

export const RequestContext = {
  run: (fn: () => Promise<void>, requestId?: string) => {
    const ctx = {
      requestId: requestId ?? randomUUID(),
      startedAt: Date.now()
    }
    return storage.run(ctx, fn)
  },
  get: () => storage.getStore(),
  getRequestId: () => storage.getStore()?.requestId ?? 'no-context',
  getDuration: () => Date.now() - (storage.getStore()?.startedAt ?? Date.now())
}

// shared/logger.ts
import pino from 'pino'

const baseLogger = pino({ level: process.env.LOG_LEVEL ?? 'info' })

export const logger = {
  info: (obj: object, msg: string) =>
    baseLogger.info({ requestId: RequestContext.getRequestId(), ...obj }, msg),
  warn: (obj: object, msg: string) =>
    baseLogger.warn({ requestId: RequestContext.getRequestId(), ...obj }, msg),
  error: (obj: object, msg: string) =>
    baseLogger.error({ requestId: RequestContext.getRequestId(), ...obj }, msg),
}
```

### Wire it at entry points

```typescript
// HTTP handler (Express/Fastify)
app.use((req, res, next) => {
  const requestId = req.headers['x-request-id'] as string ?? randomUUID()
  res.setHeader('x-request-id', requestId)
  RequestContext.run(async () => next(), requestId)
})

// Cron job
async function runCrawlJob() {
  await RequestContext.run(async () => {
    logger.info({ job: 'crawl' }, 'Job started')
    await crawlerService.runAll()
    logger.info({ job: 'crawl', duration: RequestContext.getDuration() }, 'Job finished')
  })
}
```

### Python implementation

```python
# shared/request_context.py
import uuid
from contextvars import ContextVar

_request_id: ContextVar[str] = ContextVar('request_id', default='no-context')
_started_at: ContextVar[float] = ContextVar('started_at', default=0.0)

class RequestContext:
    @staticmethod
    def set(request_id: str | None = None) -> str:
        rid = request_id or str(uuid.uuid4())
        _request_id.set(rid)
        import time
        _started_at.set(time.time())
        return rid

    @staticmethod
    def get_id() -> str:
        return _request_id.get()

    @staticmethod
    def get_duration_ms() -> int:
        import time
        return int((time.time() - _started_at.get()) * 1000)

# shared/logger.py
import structlog

def get_logger():
    return structlog.get_logger().bind(request_id=RequestContext.get_id())
```

---

## Structured logging — format that humans and AI can both read

### Log format (every line must have these fields)

```json
{
  "timestamp": "2026-06-21T14:32:01.123Z",
  "level": "error",
  "requestId": "abc-123-def-456",
  "msg": "YouTube API call failed",
  "module": "sources/youtube",
  "operation": "fetchShorts",
  "input": { "query": "AI news", "maxResults": 50 },
  "error": { "code": "QUOTA_EXCEEDED", "status": 403 },
  "duration": 234,
  "attempt": 2
}
```

### What to log and where

```
Entry points (handler/job):
  → INFO: request received (method, path/job, requestId)
  → INFO: request completed (duration, status)
  → ERROR: unhandled error (full error + input context)

Service layer:
  → INFO: operation started with key inputs (not all inputs — just identifying ones)
  → INFO: operation completed with result summary
  → WARN: business rule edge case (quota low, fallback used)
  → ERROR: DomainError or InfrastructureError with context

Repository layer:
  → INFO (optional): only log slow queries (> 100ms)
  → ERROR: DB error with query context (sanitize sensitive values)

Adapter layer (third-party APIs):
  → INFO: API call started (provider, endpoint, key params)
  → INFO: API call succeeded (status, duration, items returned)
  → WARN: API call retried (attempt number, error, will retry)
  → ERROR: API call failed after all retries (full context, circuit state)
  → ERROR: Schema validation failed (what changed vs fixture)
```

### Never log

```
✗ Passwords, API keys, secrets (even in error context)
✗ PII: email, phone, SSN (use anonymized IDs instead)
✗ Full HTTP response body (log summary + requestId instead)
✗ Successful DB query content (log operation + duration only)
```

---

## Third-party API tracing — integration with Adapter layer (Boundary Rule 4)

This is where Boundary Rule 4 and observability meet.
The Adapter is the only place that knows about the external API.
Therefore, the Adapter is the only place that logs third-party API details.

```typescript
// sources/youtube/youtube.crawler.ts
export class YouTubeCrawler implements ICrawler {
  async fetch(): Promise<FeedItem[]> {
    const callId = randomUUID()  // sub-trace for this specific API call

    logger.info({
      callId,
      provider: 'youtube',
      operation: 'fetchShorts',
      quotaAvailable: await this.quotaService.isAvailable('youtube', 100)
    }, 'YouTube API call started')

    const startedAt = Date.now()
    let attempt = 0

    try {
      const raw = await this.httpClient.get(YOUTUBE_API_URL, {
        params: { part: 'snippet', type: 'video', ... },
        headers: { Authorization: `Bearer ${this.apiKey}` }
      })

      const items = youtubeNormalizer(raw.data)

      logger.info({
        callId,
        provider: 'youtube',
        duration: Date.now() - startedAt,
        itemsReturned: items.length,
        quotaConsumed: 100
      }, 'YouTube API call succeeded')

      return items

    } catch (error) {
      logger.error({
        callId,
        provider: 'youtube',
        duration: Date.now() - startedAt,
        attempt,
        errorCode: error.response?.status,
        errorMessage: error.response?.data?.error?.message,
        // DO NOT log: API key, full response body, user PII
      }, 'YouTube API call failed')

      throw new ExternalAPIError('YouTube API call failed', 'YOUTUBE_API_ERROR')
    }
  }
}
```

### Log schema validation failures (contract test alternative)

```typescript
// youtube.normalizer.ts
export function youtubeNormalizer(raw: unknown): FeedItem[] {
  const result = YouTubeResponseSchema.safeParse(raw)

  if (!result.success) {
    // This is your early warning system: schema changed
    logger.warn({
      provider: 'youtube',
      validationErrors: result.error.issues.map(i => ({
        path: i.path.join('.'),
        expected: i.code,
        message: i.message
      })),
      receivedFields: Object.keys((raw as any)?.items?.[0] ?? {})
    }, 'YouTube API response schema mismatch — provider may have changed API')
    return []  // degrade gracefully
  }

  return result.data.items.map(mapToFeedItem)
}
```

This log fires before contract tests run — it's your real-time schema drift detector.

---

## Sentry / error tracking (traction stage)

Add when: you want to be notified of errors before users report them.

```typescript
// shared/errors.ts — add Sentry capture
import * as Sentry from '@sentry/node'

export function captureError(error: Error, context: object) {
  // Only capture infrastructure errors — domain errors are expected
  if (error instanceof InfrastructureError) {
    Sentry.captureException(error, {
      extra: {
        requestId: RequestContext.getRequestId(),
        ...context
      }
    })
  }
  logger.error({ error: error.message, ...context }, error.message)
}
```

```
// Add to CLAUDE.md tech debt log when skipping Sentry in MVP:
| No error tracking | MVP, watching logs manually | TODO[team>3]: add Sentry
```

---

## OpenTelemetry — distributed tracing (growth stage)

Add only when: "we don't know where the request is slow" signal fires.
That signal means: latency problem exists but logs don't tell you where.

```typescript
// shared/tracer.ts (add at growth stage)
import { trace, SpanStatusCode } from '@opentelemetry/api'
import { NodeSDK } from '@opentelemetry/sdk-node'
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http'

// Initialize once at startup
const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT,
  }),
})
sdk.start()

// Use in Adapter layer for external API calls
const tracer = trace.getTracer('shipright-app')

async function tracedApiCall<T>(name: string, fn: () => Promise<T>): Promise<T> {
  return tracer.startActiveSpan(name, async (span) => {
    try {
      const result = await fn()
      span.setStatus({ code: SpanStatusCode.OK })
      return result
    } catch (error) {
      span.setStatus({ code: SpanStatusCode.ERROR, message: error.message })
      span.recordException(error)
      throw error
    } finally {
      span.end()
    }
  })
}

// In YouTubeCrawler:
const items = await tracedApiCall('youtube.fetchShorts', () =>
  this.httpClient.get(YOUTUBE_API_URL, { params })
)
```

OpenTelemetry adds correlation between: HTTP request → service call → DB query → external API call.
One trace ID shows the entire journey with timing for each step.
Pairs with: Jaeger (self-hosted, free) or Honeycomb/Datadog (managed, paid).

---

## Alert rules — when to be notified

```
MVP (manual monitoring — check logs daily):
  No alerts. Check Sentry daily if installed.

Traction (add these):
  Error rate > 1% in 5 min window → Sentry alert
  Third-party API error rate > 10% → Slack/email
  Quota usage > 80% of daily limit → Slack/email

Growth (add these):
  p95 latency > 500ms for 10 min → PagerDuty
  Circuit breaker opened → immediate alert
  Schema validation failure (provider changed API) → immediate alert
  Job failed to run on schedule → alert
```

---

## Add to CLAUDE.md when setting up observability

```markdown
## Observability conventions

### Correlation ID
Every HTTP request and cron job runs inside RequestContext.run().
requestId flows through all log lines automatically.
Pass requestId in: X-Request-Id response header, cross-service calls.

### Log levels
ERROR: infrastructure failures, unhandled exceptions → needs human attention
WARN:  degraded behavior, fallback used, quota low → monitor
INFO:  operation lifecycle (started/completed), key state changes
DEBUG: only in development, never in production

### Third-party API logs
Adapters log: callId, provider, operation, duration, itemsReturned
Adapters log on error: callId, errorCode, attempt, circuit state
Adapters NEVER log: API keys, full response body, user PII

### Schema drift detection
Normalizers log WARN when schema validation fails.
Alert on this log: provider changed their API → update fixture + normalizer.
```

---

## Reference: log search patterns for common issues

```bash
# Find all logs for a specific request
grep '"requestId":"abc-123"' logs/app.log | jq .

# Find all failed YouTube API calls in last hour
grep '"provider":"youtube"' logs/app.log | grep '"level":"error"' | jq .

# Find schema validation failures (API changed)
grep 'schema mismatch' logs/app.log | jq .validationErrors

# Find slow DB queries (> 100ms)
grep '"duration"' logs/app.log | jq 'select(.duration > 100)'

# Find circuit breaker events
grep 'circuit' logs/app.log | jq .
```

---

## Retrofitting observability into existing projects

> This section is for projects already running with no observability.
> Different from greenfield — must be surgical, not a big bang rewrite.

### Step 0 — Audit before touching anything

```
Run this first, read output before writing any code:

1. Find all current logging:
   grep -rn "console\.log\|console\.error\|logger\." src/ | wc -l
   grep -rn "console\.log\|console\.error\|logger\." src/ | head -20

2. Find entry points (where requests/jobs start):
   grep -rn "app\.use\|app\.get\|app\.post\|router\.\|cron\." src/ | head -20

3. Find third-party API calls:
   grep -rn "axios\.\|fetch(\|httpClient\." src/ | head -20

4. Find error handling:
   grep -rn "catch\|\.catch(" src/ | wc -l

Output a report:
  - Current logging: [N] console.log calls
  - Entry points: [list]
  - Third-party calls: [N] calls in [files]
  - Error handling: [N] catch blocks
  - Assessment: [what's missing, what's already there]
```

### Step 1 — Add shared infrastructure (zero behavior change)

**This step changes zero existing files. Pure addition.**

```typescript
// CREATE: shared/request-context.ts  (new file)
// CREATE: shared/logger.ts           (new file, wraps existing console.log if needed)
// DO NOT: change any existing file yet
```

```typescript
// shared/logger.ts — designed to coexist with existing logging
import pino from 'pino'
import { RequestContext } from './request-context'

const base = pino({ level: process.env.LOG_LEVEL ?? 'info' })

// Drop-in replacement for console.log with requestId enrichment
export const logger = {
  info:  (obj: object | string, msg?: string) => {
    const enriched = typeof obj === 'string'
      ? { msg: obj, requestId: RequestContext.getRequestId() }
      : { ...obj, requestId: RequestContext.getRequestId() }
    msg ? base.info(enriched, msg) : base.info(enriched)
  },
  warn:  (obj: object, msg: string) =>
    base.warn({ ...obj, requestId: RequestContext.getRequestId() }, msg),
  error: (obj: object, msg: string) =>
    base.error({ ...obj, requestId: RequestContext.getRequestId() }, msg),
}
```

**Commit:** `chore: add shared logger + request context infrastructure`
**Risk:** zero — no existing files changed, nothing can break.

### Step 2 — Wire Correlation ID at entry points ONLY

**Touch only entry point files. Nothing else.**

```
Entry points are:
  HTTP: the file where app.use/app.get/app.post is defined
  Cron: the file where cron.schedule() is called
  CLI: the main() function
  Queue consumer: the worker.on('completed') handlers
```

```typescript
// BEFORE (HTTP handler — existing code):
app.use((req, res, next) => {
  next()
})

// AFTER (add 4 lines, zero other changes):
import { RequestContext } from '../shared/request-context'
import { randomUUID } from 'crypto'

app.use((req, res, next) => {
  const requestId = req.headers['x-request-id'] as string ?? randomUUID()
  res.setHeader('x-request-id', requestId)
  RequestContext.run(() => next(), requestId)  // ← wrap, not replace
})
```

**Test:** existing tests must still pass. Add 1 new test:
```typescript
it('sets x-request-id header on response', async () => {
  const res = await request(app).get('/any-route')
  expect(res.headers['x-request-id']).toBeDefined()
})
```

**Commit:** `feat(observability): wire correlation ID at entry points`
**Risk:** low — entry points rarely have unit tests, easy to verify manually.

### Step 3 — Replace console.log incrementally (module by module, not all at once)

**Never do all files in one PR. One module per PR.**

```
Priority order (highest value first):
  1. Third-party API Adapters (most debugging value)
  2. Error handling / catch blocks (most critical)
  3. Service layer operations (business logic state)
  4. Handler layer (request/response lifecycle)
  5. Repository layer (optional — only slow queries)
```

**Prompt for each module:**
```
Module: [name], file: [path]

Replace console.log/console.error with structured logger imports.
Rules:
  - Import logger from shared/logger (do NOT change logger.ts itself)
  - console.log → logger.info({ [relevant context fields] }, '[message]')
  - console.error → logger.error({ error: e.message, [context] }, '[message]')
  - Add fields that identify WHAT and WHERE: module name, operation name
  - Do NOT add fields that expose secrets or PII
  - Do NOT change any function signatures
  - Do NOT change any logic — only the log calls

Run tests after. If any test fails: revert this file, investigate separately.
Commit: "refactor([module]): structured logging"
```

**One module, one commit. Never batch.**

### Step 4 — Add observability to third-party API calls (highest priority)

After Step 3 reaches the Adapter files, add the full API tracing pattern.
This is the highest-value observability addition for any project with external APIs.

```
For each Adapter/Crawler/HTTP-client wrapper file:

1. Wrap API calls with try/catch if not already wrapped
2. Add callId = randomUUID() at start of each API call method
3. Log before call: { callId, provider, operation, params (sanitized) }
4. Log after success: { callId, duration, itemsReturned/responseSize }
5. Log on error: { callId, errorCode, attempt, willRetry }
6. In normalizer: add schema validation log if not present

Do NOT restructure the Adapter. Only add logging.
Existing behavior must be identical.
```

### Step 5 — Verify end-to-end (before declaring done)

```bash
# Make a test request to any endpoint
curl -X GET http://localhost:3000/api/whatever -v

# Check logs contain requestId flowing through all layers
grep "requestId" logs/app.log | head -20

# Verify third-party API logs appear with callId
grep "API call" logs/app.log | jq '{requestId, callId, provider, duration}'

# Verify no secrets in logs
grep -i "password\|apikey\|api_key\|secret\|token" logs/app.log && echo "SECRET LEAK" || echo "Clean"
```

### Step 6 — Clean up old console.log (after all modules done)

```bash
# Find any remaining raw console calls
grep -rn "console\.log\|console\.error" src/ | grep -v ".test."

# Each remaining one: either replace with logger or add comment explaining why it stays
# (e.g., startup scripts that run before logger is initialized are OK as console.log)
```

### What NOT to do when retrofitting

```
✗ Refactor the entire codebase in one PR — impossible to review, high risk
✗ Change function signatures to pass requestId explicitly — too disruptive
   (Use AsyncLocalStorage/ContextVar instead — it flows automatically)
✗ Add OpenTelemetry at the same time — one thing at a time
✗ Skip characterization tests before touching Adapter files
   (Adapters have external dependencies — easy to break subtle behavior)
✗ Remove console.log before verifying structured logs work
   (Keep both temporarily, remove old only after verification)
```

### CLAUDE.md additions after retrofit complete

```markdown
## Observability conventions (added [date])

Logger: import from shared/logger — never use console.log directly
requestId: flows automatically via RequestContext — never pass manually
All API calls: log callId, provider, duration (see references/observability.md)
Secrets/PII: never in logs — use anonymized IDs
```

### Typical timeline for retrofit

```
Day 1: Step 0 (audit) + Step 1 (infrastructure)     — zero risk
Day 2: Step 2 (entry points) + verify manually       — low risk
Day 3–5: Step 3 module by module                      — medium, one at a time
Day 5: Step 4 (API adapters)                          — highest value
Day 6: Step 5 (verify end-to-end) + Step 6 (cleanup) — low risk
```

Total: ~1 week of careful, incremental work.
Not a sprint, not a big-bang rewrite. Surgical.
