# Third-Party API Integration

Every external API is a liability, not just a feature.
It can change schema, go down, rate-limit you, or return invalid data.
The goal is not "how to call the API" — it is "how to isolate your system from it."

---

## Ubiquitous Language at the Adapter boundary

Domain terms should be used inside the Adapter output (normalized type),
not the provider's field names.

```typescript
// Wrong: leaks provider's language into domain
interface YouTubeItem {
  snippet: { title: string }  // YouTube's language
}

// Right: Adapter translates to Ubiquitous Language
interface FeedItem {          // project's Ubiquitous Language
  title: string
  source: 'youtube'
  publishedAt: Date
}
```

---

## The 4th boundary rule (add to CLAUDE.md when project has external APIs)

```
Boundary 4 — No raw external response passes the Adapter layer
  Raw API response NEVER enters service or domain logic directly.
  Every external API has exactly one Adapter (Normalizer/Transformer).
  Adapter maps raw response → internal domain type.
  Service layer never knows which provider was called.
```

Why this is non-negotiable (even in MVP):
- Provider changes schema → fix one file (Adapter), zero others
- Swap provider → implement new Adapter, service unchanged
- Test service logic → mock Adapter output, no real API needed
- Add caching → cache at Adapter boundary, service unaware

---

## 3-Layer testing strategy

### Layer 1 — Exploration (mandatory, BEFORE writing Adapter code)

> **This is the most skipped step in AI coding.** Claude will happily write an Adapter
> from documentation alone — but docs are often wrong, incomplete, or outdated.
> Real API responses reveal: optional fields, actual types (string vs int), pagination shape,
> error response structure, rate limit headers. You cannot safely write an Adapter without this.

Purpose: understand the API deeply from both docs AND real responses.
Docs tell you what params exist. Real calls tell you what responses actually look like.
You need both — docs alone miss reality, real calls alone miss intent.
Tool: Bruno (local, git-friendly) or Hoppscotch. Never Postman if you want git history.

**When to do Layer 1:**
- New third-party API being integrated for the first time
- Provider claims to have changed their API (re-explore changed endpoints)
- Adapter is failing in production with unexpected data (re-explore to update fixture)

**When NOT needed:**
- Adding a new endpoint from the same provider (existing fixture shows structure)
- Mocking for tests when real fixture already exists

### Phase A — Study docs first (before making any API call)

Read the official API documentation for each endpoint you will integrate.
Extract and document:

```markdown
# api-exploration/[provider]/API-NOTES.md

## Endpoint: [METHOD] [path]

### Authentication
- Type: [Bearer / API-Key / OAuth2 / HMAC]
- Header: [exact header name and format]
- Where to get test credentials: [link]

### Request params
| Param | Location | Type | Required | Default | Notes |
|---|---|---|---|---|---|
| [name] | body/query/header | string/int/bool | yes/no | [default] | [constraints, enums] |

### What each key param does
- [param]: [what it controls] — [valid values / range / format]
- [param]: [side effects when set] — [what changes in response]

### Response shape (from docs)
[paste the documented response structure]
- Field [x]: [when is it present? when null/missing?]
- Field [y]: [is this actually a string even though docs say int?]

### Error codes to handle
| Code | Meaning | How to handle |
|---|---|---|
| 400 | [description] | validate params before calling |
| 401 | [description] | refresh token / check key |
| 429 | [description] | backoff + retry |
| [N] | [description] | [handling] |

### Rate limits (MUST answer all questions before writing any code)

```
Q1: Does this API have rate limits?
    → YES: document exactly
      - Limit: [N requests] per [second / minute / hour / day / month]
      - Scope: per API key? per IP? per user? per endpoint?
      - Multiple tiers: [free vs paid vs burst limits]
    → NOT DOCUMENTED: assume it has limits, probe carefully
    → NO: rare — verify by checking terms of service

Q2: What happens when limit is exceeded?
    - HTTP status code: [429? 403? 200 with error in body?]
    - Response body: [error message format]
    - Headers returned: [Retry-After, X-RateLimit-Reset, X-RateLimit-Remaining]
    - Behavior: hard block? soft throttle? queue?

Q3: How to track remaining quota?
    - Response headers: [X-RateLimit-Remaining, X-RateLimit-Limit, X-RateLimit-Reset]
    - Separate quota endpoint: [URL if exists]
    - Must track client-side: [if no headers provided]

Q4: What is the recovery mechanism?
    - Retry-After: [seconds] fixed? or dynamic per response?
    - Reset time: [absolute timestamp? relative seconds?]
    - Exponential backoff: needed? or fixed retry interval?

Q5: Is there a sandbox with separate limits?
    - Sandbox limits: [often more generous, sometimes unlimited]
    - Sandbox vs production: [different keys? different limits?]

Q6: Cost implications?
    - Free tier: [N calls/day or month] — when does it reset?
    - Overage: [blocked? charged? throttled?]
    - TODO[quota>80%]: alert and review usage
```
```

### Phase B — Build request in Bruno using docs knowledge

```
api-exploration/[provider]/[endpoint-name].bru

# Set auth headers exactly as docs specify
headers {
  Authorization: Bearer {{API_KEY}}
  Content-Type: application/json
}

# Body built from docs — use realistic test values, not placeholder strings
body:json {
  "param1": "realistic-test-value",   # not "string" or "test"
  "param2": 10,                        # use value that exercises the logic you need
  "param3": true
}
```

### Phase C — Call and compare: docs vs reality

Call each scenario and note discrepancies between docs and actual response:

```
Scenario 1 — Happy path (all required params, realistic values):
  → Save: tests/fixtures/[provider]-success.json
  → Note any fields present in response but NOT in docs
  → Note any fields in docs but ABSENT in response
  → Note any type mismatches (docs say int, response gives string)

Scenario 2 — Missing optional params (omit one optional at a time):
  → Save: tests/fixtures/[provider]-minimal.json
  → Reveals: which params are truly optional vs documented-optional-but-actually-required

Scenario 3 — Edge case values (zero, empty string, max value):
  → Save: tests/fixtures/[provider]-edge-[description].json
  → Reveals: how API handles boundary conditions

Scenario 4 — Each error case:
  → Save: tests/fixtures/[provider]-error-[code].json
  → Compare error response structure — often undocumented

Scenario 5 — Rate limit trigger (if sandbox allows):
  → Save: tests/fixtures/[provider]-rate-limit.json
  → Note: retry-after header format, response body when limited
```

### Phase D — Update API-NOTES.md with reality

Add "Reality vs Docs" section:
```markdown
## Reality vs Docs (discovered from real calls)
- Field [x]: docs say required, actually optional (null when not set)
- Field [y]: docs say string, actually returns integer
- Field [z]: undocumented field appears in all responses — use it for [purpose]
- Error 422: not in docs, appears when [condition]
- Rate limit: docs say X req/min, actually enforced per IP not per key
```

This document becomes the team's canonical reference — more accurate than official docs.

```bash
# Setup Bruno collection in your project
mkdir -p api-exploration/[provider-name]
# Create request files, call sandbox endpoints
# Try: happy path, missing params, invalid auth, rate limit trigger
```

What to capture and save:
- Successful response → save as `tests/fixtures/[provider]-success.json`
- Error responses → save as `tests/fixtures/[provider]-error-401.json`, etc.
- Note: which fields are optional, what types can vary, pagination shape

```bash
tests/fixtures/
  google-news-success.json      ← real sandbox response
  google-news-empty.json        ← when no results
  youtube-success.json
  youtube-quota-exceeded.json   ← 403 response shape
  rapidapi-[name]-success.json
```

**These fixtures are source of truth for all unit tests. Never delete them.**

---

## Rate limit setup — implement immediately after Phase A

Once rate limit profile is known from docs, set up defensive code BEFORE Adapter logic.

### Decision tree

```
Per-second tight (< 10 req/s):
  → npm install bottleneck (Node.js) or asyncio throttle (Python)
  → Sequential, not concurrent calls

Per-minute moderate (10–100 req/min):
  → axios-retry + exponential backoff (already in shared/http-client)
  → Proactive quota check before call

Per-day/month quota (YouTube, RapidAPI, OpenAI):
  → Persist quota in DB — NOT in memory (lost on restart)
  → Check BEFORE every call, record AFTER success
  → Alert at 80%: TODO[provider-quota>80%] in CLAUDE.md

Undocumented limits:
  → Treat as unknown — add retry with backoff anyway
  → Log all 429/503 responses to discover real limits
  → TODO[first-429]: document limit and add proper tracking
```

### Node.js — per-second limiter (Bottleneck)

```typescript
// shared/rate-limiter.ts
import Bottleneck from 'bottleneck'

export const youtubeLimiter = new Bottleneck({
  maxConcurrent: 1,
  minTime: 100,  // 10 req/sec max
})

// In Adapter:
const raw = await youtubeLimiter.schedule(() =>
  httpClient.get(YOUTUBE_API_URL, { params })
)
```

### Node.js — per-day/month quota tracker

```typescript
// shared/quota-tracker.ts
export class QuotaTracker {
  constructor(
    private db: PrismaClient,
    private provider: string,
    private dailyLimit: number,
  ) {}

  async canCall(units = 1): Promise<boolean> {
    const today = new Date().toISOString().split('T')[0]
    const usage = await this.db.apiQuota.findUnique({
      where: { provider_date: { provider: this.provider, date: today } }
    })
    const used = usage?.unitsUsed ?? 0
    if (used + units > this.dailyLimit) {
      logger.warn({ provider: this.provider, used, limit: this.dailyLimit },
        'Quota limit reached — skipping call')
      return false
    }
    return true
  }

  async record(units = 1): Promise<void> {
    const today = new Date().toISOString().split('T')[0]
    await this.db.apiQuota.upsert({
      where: { provider_date: { provider: this.provider, date: today } },
      update: { unitsUsed: { increment: units } },
      create: { provider: this.provider, date: today, unitsUsed: units }
    })
  }
}
// Prisma schema: ApiQuota { provider String, date String, unitsUsed Int }

// In Adapter:
if (!await this.quotaTracker.canCall(100)) {
  throw new QuotaExceededError('YouTube daily quota reached')
}
const raw = await httpClient.get(YOUTUBE_API_URL, { params })
await this.quotaTracker.record(100)
```

### Retry respecting Retry-After header

```typescript
// shared/http-client.ts (extend existing)
axiosRetry(httpClient, {
  retries: 3,
  retryCondition: (error) =>
    error.response?.status === 429 || error.response?.status === 503,
  retryDelay: (retryCount, error) => {
    const retryAfter = error.response?.headers['retry-after']
    if (retryAfter) {
      const seconds = parseInt(retryAfter, 10)
      if (!isNaN(seconds)) return seconds * 1000  // respect header
    }
    return axiosRetry.exponentialDelay(retryCount) + Math.random() * 1000
  },
})
```

### Python — async rate limiter

```python
# shared/rate_limiter.py
import asyncio, time
from collections import deque

class RateLimiter:
    def __init__(self, calls_per_minute: int):
        self.calls_per_minute = calls_per_minute
        self.calls: deque = deque()

    async def acquire(self):
        now = time.monotonic()
        while self.calls and self.calls[0] < now - 60.0:
            self.calls.popleft()
        if len(self.calls) >= self.calls_per_minute:
            await asyncio.sleep(self.calls[0] + 60.0 - now)
        self.calls.append(time.monotonic())

limiter = RateLimiter(calls_per_minute=60)
async def fetch(url):
    await limiter.acquire()
    return await client.get(url)
```

### Add to CLAUDE.md

```markdown
## API rate limits
| Provider | Limit | Scope | Implementation | Alert |
|---|---|---|---|---|
| [name] | [N/window] | [per-key] | [QuotaTracker/Bottleneck/retry] | TODO[>80%] |

Rules: check quota BEFORE call, record AFTER success.
On 429: respect Retry-After header. On exhaustion: degrade gracefully.
```

### Layer 1 prompt for Claude Code

When shipright detects a third-party API integration, use this prompt:

```
Before writing any Adapter code for [provider]:

1. Create Bruno collection: api-exploration/[provider]/
2. Create request file: get-[endpoint].bru
   Set headers: Authorization, X-Api-Key, etc. from .env
   Set params matching the endpoint documentation

3. Run the request against sandbox/test environment
4. Save actual response to: tests/fixtures/[provider]-success.json
5. Run with missing/invalid params → save error responses
6. Note in CLAUDE.md:
   [provider] explored: [date]
   Fixture location: tests/fixtures/[provider]-*.json
   Fields noted as optional: [list]
   Types that differ from docs: [list]

Only AFTER fixtures are saved: write the Adapter and unit tests.
```

---

### Layer 2 — Unit tests with fixtures (run in CI on every commit)

Purpose: verify your Adapter maps correctly. Zero real API calls.

```typescript
// [provider].normalizer.test.ts
import { readFileSync } from 'fs'
import { googleNormalizer } from './google.normalizer'

const successFixture = JSON.parse(
  readFileSync('tests/fixtures/google-news-success.json', 'utf-8')
)
const emptyFixture = JSON.parse(
  readFileSync('tests/fixtures/google-news-empty.json', 'utf-8')
)

describe('GoogleNormalizer', () => {
  it('maps response to FeedItem[]', () => {
    const result = googleNormalizer(successFixture)
    expect(result[0]).toMatchObject({
      source: 'google',
      title: expect.any(String),
      url: expect.stringMatching(/^https?:\/\//),
      publishedAt: expect.any(Date),
    })
  })

  it('returns empty array on empty results (not throws)', () => {
    expect(googleNormalizer(emptyFixture)).toEqual([])
  })

  it('handles missing optional fields gracefully', () => {
    const partial = { ...successFixture, news_results: [{ title: 'x' }] }
    expect(() => googleNormalizer(partial)).not.toThrow()
  })
})
```

Rules for Layer 2:
- Mock HTTP client — never call real API
- Test normalizer as pure function — no side effects to mock
- Cover: happy path, empty result, missing optional fields, malformed data
- Must run offline. Must complete in < 100ms per test.

### Layer 3 — Contract tests (run scheduled, NOT on every commit)

Purpose: detect when the real API changes its schema.

```typescript
// [provider].contract.test.ts
// @group contract  ← tagged separately, not in default CI run

it('CONTRACT: google news response shape unchanged', async () => {
  // Calls real sandbox API
  const live = await axios.get(SANDBOX_URL, { headers: { 'X-Api-Key': SANDBOX_KEY } })
  const fixture = JSON.parse(readFileSync('tests/fixtures/google-news-success.json', 'utf-8'))

  // Compare SHAPE, not data
  expect(Object.keys(live.data)).toEqual(Object.keys(fixture))
  expect(Object.keys(live.data.news_results[0])).toEqual(
    Object.keys(fixture.news_results[0])
  )
})
```

Schedule: run daily via CI cron, or manually before each release.
When it fails → the provider changed their schema → update fixture → update normalizer.
Add alert (Slack/email) when contract test fails — this is production risk.

---

## Adapter pattern — code structure

```
modules/sources/[provider]/
  [provider].crawler.ts      ← HTTP call only, returns raw response
  [provider].normalizer.ts   ← pure function: raw → InternalType
  [provider].adapter.ts      ← optional: schema validation before normalizing
  [provider].normalizer.test.ts  ← unit tests with fixtures
  [provider].contract.test.ts    ← contract tests (tagged @contract)
  index.ts                   ← exports [Provider]Crawler only
tests/
  fixtures/
    [provider]-success.json
    [provider]-error-*.json
api-exploration/
  [provider]/
    *.bru                    ← Bruno request files (committed to git)
```

---

## Resilience — always implement in Crawler, not Service

### MVP minimum (implement from day one)
```typescript
// shared/http-client.ts
const client = axios.create({
  timeout: 8000,  // hard timeout — never let external call hang
})
axiosRetry(client, {
  retries: 3,
  retryDelay: axiosRetry.exponentialDelay,  // 1s, 2s, 4s
  retryCondition: (error) =>
    axiosRetry.isNetworkError(error) || error.response?.status === 429,
})
```

### Traction stage (add when error rate signal appears)
```typescript
// Circuit breaker: stop hammering a failing API
// TODO[error-rate>5%]: add opossum circuit breaker
const breaker = new CircuitBreaker(fetchFn, {
  timeout: 8000,
  errorThresholdPercentage: 50,  // open after 50% errors
  resetTimeout: 60000,           // try again after 60s
})
breaker.fallback(() => [])  // return empty, not crash
```

---

## Schema validation at boundary (recommended)

Before normalizing, validate the shape you received is what you expect.
This catches API changes early with clear error messages.

```typescript
// [provider].adapter.ts
import { z } from 'zod'

const GoogleNewsResponseSchema = z.object({
  news_results: z.array(z.object({
    title: z.string(),
    link: z.string().url(),
    date: z.string().optional(),
  })).optional().default([])
})

export function parseGoogleResponse(raw: unknown) {
  const result = GoogleNewsResponseSchema.safeParse(raw)
  if (!result.success) {
    logger.warn({ errors: result.error.issues }, 'Google API response schema mismatch')
    return { news_results: [] }  // degrade gracefully
  }
  return result.data
}
```

---

## Tool recommendations

| Purpose | Tool | Why |
|---|---|---|
| Exploration & collection | Bruno | Local, git-friendly, free, no cloud sync |
| HTTP client | axios + axios-retry | Retry built-in, widely supported |
| Schema validation | zod | Already in shipright stack for env vars |
| Mock server (growth) | MSW (Node) / WireMock | Intercept at network level |
| Contract testing (growth) | Pact | Consumer-driven, multi-language |
| Circuit breaker (growth) | opossum (Node) | Battle-tested |

---

## Observability integration — connect Adapter to logging

The Adapter layer is the only place that should log third-party API details.
This is where Boundary Rule 4 and observability meet.

```typescript
// Every API call in Adapter must log:
logger.info({ callId, provider, operation, params: sanitized }, 'API call started')
logger.info({ callId, duration, itemsReturned }, 'API call succeeded')
logger.error({ callId, errorCode, attempt, circuitState }, 'API call failed')

// Normalizer must log schema drift:
if (!schema.safeParse(raw).success) {
  logger.warn({ provider, validationErrors }, 'API schema mismatch — provider may have changed')
}
```

Full patterns: `references/observability.md`
