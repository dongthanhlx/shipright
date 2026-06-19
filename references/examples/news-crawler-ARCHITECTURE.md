# ARCHITECTURE.md — news-crawler

> Real output example from following the shipright skill.

## System diagram

```
┌─────────────────────────────────────────────┐
│              crawl.job.ts                   │
│         node-cron */10 * * * *              │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│            CrawlerService                   │
│      Promise.allSettled(crawlers)           │
└──────┬───────────────────────┬──────────────┘
       │ ICrawler              │ ICrawler
       ▼                       ▼
┌──────────────┐     ┌─────────────────┐
│GoogleCrawler │     │ YouTubeCrawler  │
│+Normalizer   │     │ +Normalizer     │
│+QuotaCheck   │     │ +QuotaCheck     │
└──────┬───────┘     └────────┬────────┘
       │ FeedItem[]           │ FeedItem[]
       └──────────┬───────────┘
                  ▼
┌─────────────────────────────────────────────┐
│             FeedService                     │
│      dedup → filter new → saveBatch         │
└──────────────────┬──────────────────────────┘
                   ▼
┌─────────────────────────────────────────────┐
│              PostgreSQL                     │
│  feed_items | job_runs | quota_usage        │
└─────────────────────────────────────────────┘
```

---

## Modules

### `modules/crawler`
**Responsibility**: Orchestrate all crawlers in parallel. Collect results. Does not know about Google or YouTube.

**Public API** (`index.ts`):
```typescript
interface ICrawler {
  source: string
  fetch(): Promise<FeedItem[]>
  isQuotaAvailable(): Promise<boolean>
}
class CrawlerService {
  constructor(crawlers: ICrawler[])
  runAll(): Promise<PromiseSettledResult<FeedItem[]>[]>
}
```
**Depends on**: nothing (receives crawlers via constructor injection)
**Does NOT depend on**: feed, quota, any source directly

---

### `modules/sources/google`
**Responsibility**: Call SearchAPI, return raw results, normalize to FeedItem[].

**Public API** (`index.ts`):
```typescript
class GoogleCrawler implements ICrawler {
  source: 'google'
  fetch(): Promise<FeedItem[]>
  isQuotaAvailable(): Promise<boolean>
}
```
**Internal only** (not exported): `google.normalizer.ts`
**Depends on**: `QuotaService` (injected), `shared/http-client`
**Does NOT depend on**: FeedRepository, db, other sources

---

### `modules/sources/youtube`
**Responsibility**: Call YouTube Data API v3, filter Shorts (duration < 60s), normalize.

**Public API** (`index.ts`):
```typescript
class YouTubeCrawler implements ICrawler {
  source: 'youtube'
  fetch(): Promise<FeedItem[]>
  isQuotaAvailable(): Promise<boolean>
}
```
**Depends on**: `QuotaService` (injected), `shared/http-client`
**Does NOT depend on**: FeedRepository, db, other sources

---

### `modules/feed`
**Responsibility**: Persist FeedItems. Deduplication. Job run logging. ONLY module writing to feed_items and job_runs tables.

**Public API** (`index.ts`):
```typescript
interface IFeedRepository {
  saveBatch(items: FeedItem[]): Promise<SaveResult>
  existsByIds(ids: string[]): Promise<Set<string>>
}
class FeedService {
  deduplicateAndSave(items: FeedItem[], jobId: string): Promise<SaveResult>
  logJobStart(jobId: string): Promise<void>
  logJobEnd(jobId: string, result: JobResult): Promise<void>
}
```
**Depends on**: `shared/db`
**Does NOT depend on**: any source module, crawler module

---

### `modules/quota`
**Responsibility**: Track API quota usage per source per day. Single source of truth.

**Public API** (`index.ts`):
```typescript
interface IQuotaService {
  isAvailable(source: string, requiredUnits: number): Promise<boolean>
  consume(source: string, units: number): Promise<void>
}
class QuotaService implements IQuotaService { ... }
```
**Depends on**: `shared/db`, `config/env`
**Does NOT depend on**: any source, feed module

---

### `shared/`
```
db.ts           # pg.Pool singleton
logger.ts       # pino structured logger
http-client.ts  # axios + axios-retry (3x exp backoff + jitter)
errors.ts       # AppError hierarchy (see CLAUDE.md error taxonomy)
```
**Rule**: shared/ never imports from modules/

---

## Domain model

```typescript
interface FeedItem {
  id: string                         // sha256(url) — dedup key + PK
  source: 'google' | 'youtube'
  title: string
  url: string                        // canonical URL (trimmed, lowercase scheme/host)
  publishedAt: Date
  metadata: Record<string, unknown>  // source-specific: viewCount, duration, snippet
  crawledAt: Date
  jobId: string                      // trace which job created this item
}

interface JobResult {
  jobId: string
  startedAt: Date
  finishedAt: Date
  sources: Array<{
    source: string
    status: 'success' | 'failed' | 'quota_exceeded'
    itemsFetched: number
    itemsSaved: number
    error?: string
  }>
}
```

---

## Database schema

```sql
CREATE TABLE feed_items (
  id           VARCHAR(64) PRIMARY KEY,   -- sha256(url)
  source       VARCHAR(32) NOT NULL,
  title        TEXT NOT NULL,
  url          TEXT NOT NULL,
  published_at TIMESTAMPTZ,
  metadata     JSONB DEFAULT '{}',
  crawled_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  job_id       VARCHAR(36) NOT NULL
);
CREATE INDEX idx_feed_source_crawled ON feed_items(source, crawled_at DESC);
CREATE INDEX idx_feed_published ON feed_items(published_at DESC);

CREATE TABLE job_runs (
  id           VARCHAR(36) PRIMARY KEY,  -- uuid
  started_at   TIMESTAMPTZ NOT NULL,
  finished_at  TIMESTAMPTZ,
  status       VARCHAR(16) NOT NULL DEFAULT 'running',
  result       JSONB DEFAULT '{}'
);

CREATE TABLE quota_usage (
  source     VARCHAR(32) NOT NULL,
  date       DATE NOT NULL DEFAULT CURRENT_DATE,
  used_units INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (source, date)
);
```

---

## Dependency rules

```
jobs/           → modules/* (wire everything here, nowhere else)
modules/crawler → modules/sources/* (via ICrawler interface only)
modules/sources → modules/quota (via IQuotaService interface)
modules/feed    → shared/db
modules/quota   → shared/db
shared/*        → nothing in modules/
config/         → nothing
```

**Explicitly forbidden:**
```
sources/* → feed          # sources don't know about persistence
sources/* → other sources # each source is fully independent
feed      → crawler       # feed doesn't know about crawling
shared    → modules/*     # shared is always a leaf dependency
```

---

## How to add a new source (e.g. Reddit)

1. Create `modules/sources/reddit/`
2. Implement `RedditCrawler implements ICrawler` + `reddit.normalizer.ts`
3. Register in `jobs/crawl.job.ts` alongside existing crawlers
4. Add quota config in `config/env.ts`
5. **Zero changes** to CrawlerService, FeedService, or any other source

---

## ADR

### ADR-001: Modular monolith, not microservices
**Decision**: Single deployable with clear module boundaries.
**Options**: Microservices (rejected: operational overhead before value proven), Monolith without boundaries (rejected: impossible to split later).
**Consequence**: All modules in same process. Splitting later = Strangler Fig per module.
**Trigger to revisit**: When separate teams own separate sources, or sources need different scaling.

### ADR-002: Promise.allSettled for parallel crawling
**Decision**: Use `Promise.allSettled` not `Promise.all` in CrawlerService.
**Options**: Sequential (rejected: slow, 1 failure blocks all), Promise.all (rejected: 1 failure kills all).
**Consequence**: Always collect partial results. Must check each result's status.
**Trigger to revisit**: If sources need to be coordinated (one waits for another).

### ADR-003: sha256(url) as dedup key and primary key
**Decision**: Hash the canonical URL as the `id` field and primary key.
**Options**: UUID (rejected: loses dedup property), url as PK (rejected: too long, index performance).
**Consequence**: URL normalization must be consistent. Different normalizations of same URL = duplicate.
**Trigger to revisit**: If we need to support sources with no stable URL (e.g., ephemeral content).

### ADR-004: Quota in PostgreSQL, not Redis
**Decision**: Track quota usage in a DB table with daily reset.
**Options**: In-memory (rejected: lost on restart), Redis (rejected: extra dependency for 1 instance).
**Consequence**: Works correctly for 1 instance. Race condition possible if 2 instances run simultaneously.
**Trigger to revisit**: `TODO[multi-instance]` — when running > 1 pod.

### ADR-005: Pure function normalizers, not class methods
**Decision**: `googleNormalizer(raw): FeedItem[]` — plain function, not a method on GoogleCrawler.
**Options**: Class method (rejected: ties normalization to HTTP client, harder to test).
**Consequence**: Normalizers have zero dependencies. Test with fixture JSON, no mocks needed.
**Trigger to revisit**: If normalization needs async operations (e.g., enrichment API calls).
