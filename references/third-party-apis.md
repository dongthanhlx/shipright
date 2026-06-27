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

### Layer 1 — Exploration (do once, before writing code)

Purpose: learn the API. This is NOT testing — it is discovery.
Tool: Bruno (local, git-friendly) or Hoppscotch. Never Postman if you want git history.

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
