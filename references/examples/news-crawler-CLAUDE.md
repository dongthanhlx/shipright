# CLAUDE.md — news-crawler

> This is a real output example from following the shipright skill.
> Use it as a reference for what a good CLAUDE.md looks like.

## Ubiquitous Language
| Term | Meaning | Not |
|---|---|---|
| FeedItem | A normalized article/video from any source | Article, Post, Content |
| Crawler | Component that fetches raw data from a source | Fetcher, Scraper |
| Normalizer | Pure function: raw API response → FeedItem | Parser, Transformer |
| Source | External data provider (Google, YouTube) | Provider, Channel |
| Quota | API usage allowance per day/month | Limit, Budget |

---

## Project in one sentence
Crawl latest news from Google (SearchAPI) and YouTube Shorts (YouTube Data API v3),
normalize to unified FeedItem shape, deduplicate by URL hash, persist every 10 minutes.

---

## Architecture rules — NEVER violate

### Module boundaries
- `sources/*` NEVER import from each other
- `sources/*` NEVER import `shared/db` directly
- `crawler` communicates with sources ONLY via `ICrawler` interface
- `feed` is the ONLY module allowed to call `FeedRepository`
- Cross-module calls go through `modules/[name]/index.ts` — never deep imports

### Layer rules
- **Handler**: parse → validate → call service → format response. NO business logic
- **Service**: business logic only. NO direct DB. NO HTTP framework imports
- **Repository**: DB queries ONLY. Returns typed domain objects, NOT raw rows
- **Crawler**: API calls ONLY. Normalization is NOT the crawler's job
- **Normalizer**: raw API → FeedItem. Pure function, NO side effects

### Banned imports — will fail code review
```
// In service files:
import { db } from '../../shared/db'               // ← BANNED

// In source files:
import { FeedRepository } from '../feed/...'        // ← BANNED

// Deep import bypassing index.ts:
import { SomeType } from '../feed/feed.service'     // ← BANNED, use '../feed'
```

### Integration resilience (Boundary 5)
- Every `Crawler` HTTP call has a timeout (axios `timeout: 5000`) — no call waits forever
- SearchAPI/YouTube down → crawler returns `[]` (degrade), never throws into the cron loop
- Cron crawl is idempotent: `pg_try_advisory_lock` + `ON CONFLICT DO NOTHING` (see below)
- HARDEN signal `TODO[error-rate>5%]`: add circuit breaker per source → references/resilience.md

---

## Coding workflow — always in this order

1. Read this file + ARCHITECTURE.md before any action
2. Write types/interfaces first
3. Write test cases before implementation (tests must be RED first)
4. Implement inside-out: normalizer → repository → service → handler/job
5. Run tests after each layer
6. Run boundary checklist before commit
7. Commit small: 1 feature = 1 commit. Never commit RED tests

## Pre-commit boundary checklist
```bash
grep -r "from.*shared/db" src/modules/     # must be empty
grep -r "from.*feed" src/modules/sources/  # must be empty
npx tsc --noEmit                           # must pass
npx jest --passWithNoTests                 # must pass
npx madge --circular src/                 # must show no cycles
```

---

## Error taxonomy

### Domain errors (client caused this → 4xx)
- `ValidationError`  → HTTP 400 — input doesn't meet rules
- `NotFoundError`    → HTTP 404 — resource doesn't exist
- `ConflictError`    → HTTP 409 — duplicate
- `QuotaExceededError` → HTTP 429 — API quota hit

### Infrastructure errors (our problem → 5xx)
- `DatabaseError`    → HTTP 503 + alert
- `ExternalAPIError` → HTTP 502 + circuit breaker log

### Rules
- Service throws Domain or Infrastructure errors. Service has ZERO HTTP knowledge.
- Handler maps error class → HTTP status. Handler has ZERO business logic.
- Every InfrastructureError must be logged with full context.

---

## Idempotency decisions

| Operation | If called twice | Solution |
|---|---|---|
| Cron crawl job | Two jobs overlap | `pg_try_advisory_lock(1)` at job start |
| Save feed items | Duplicate items | `INSERT ... ON CONFLICT (id) DO NOTHING` |

---

## Tech debt log

| Shortcut | Accepted because | Trigger to fix |
|---|---|---|
| node-cron in-process scheduler | Simple, 1 instance | `TODO[multi-instance]`: migrate to BullMQ |
| No retry queue for failed crawls | Logs are enough, next run retries | `TODO[error-rate>5%]`: add dead-letter queue |
| Quota tracking in PostgreSQL | Fine for 1 instance | `TODO[multi-instance]`: migrate to Redis INCR |
| No REST API to query feed | Not needed yet | `TODO[consumer-needed]`: add feed API module |
| No data retention/cleanup | DB small now | `TODO[DB>5GB]`: add partition by month + cleanup |

Mark new shortcuts: `// TODO[trigger]: description`

---

## Tech stack
```
Runtime:    Node.js 20 LTS + TypeScript strict
Database:   PostgreSQL 16 (pg + node-postgres)
Migrations: db-migrate (SQL files)
Scheduler:  node-cron
Testing:    Jest + ts-jest (coverage threshold: 80%)
Validation: zod (env vars + request bodies)
HTTP:       axios + axios-retry (3x, exponential backoff)
Logging:    pino (structured JSON)
Dev:        Docker Compose (app + postgres)
```

## Environment variables
```
DATABASE_URL            # postgres connection string
SEARCHAPI_KEY           # SearchAPI.io key
YOUTUBE_API_KEY         # Google Cloud key with YouTube Data API v3 enabled
YOUTUBE_QUOTA_LIMIT     # default: 10000 (units/day)
SEARCHAPI_QUOTA_LIMIT   # check your plan dashboard
CRAWL_INTERVAL_MINUTES  # default: 10
LOG_LEVEL               # default: info
```

---

## When to ask before doing
- Changing any `index.ts` public exports
- Adding a new npm dependency
- Changing DB schema requiring data migration
- Creating a module not in ARCHITECTURE.md
- Any change touching > 2 modules simultaneously

---

## Shipright state
Level: L0
Active: constitution created
Next: create L1 skeleton — src/ folder structure + compiles with npx tsc --noEmit
Last updated: 2025-06
Skills active: debugging-and-error-recovery
Registry: web-api
