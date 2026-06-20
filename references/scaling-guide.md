# Scaling Guide — When and How to Grow Architecture

## The most important rule

**Do not split what you can strengthen.**

The cheapest decomposition is the one you never need to do.
Most "project is too big" problems are solved by better boundaries, not new architecture.
Split only when organizational structure demands it — not when codebase is large.

2026 data: modular monolith comfortably serves 100k–1M users.
Shopify: billions in transactions, 1 modular monolith.
Basecamp: 20-person team, single Rails app, zero microservices.

---

## How to read this guide

Three stages. Each has: the signal that triggers it, what to do, what NOT to do.
Do not jump to Stage 3 because it sounds more "senior". Work the stages in order.

---

## Stage 1 — Enforce harder (team < 20, any codebase size)

### Signal to enter Stage 1
Any of these appearing:
```
□ Merge conflicts happening in same module between different devs
□ "I didn't know that module did that" — surprise dependencies
□ Adding a feature touches > 3 modules without good reason
□ Tests slow because everything imports everything
□ CLAUDE.md approaching 150 lines
```

### What to do

**Step 1: Module ownership matrix**
Add to ARCHITECTURE.md:
```markdown
## Module ownership

| Module       | Primary owner | Approves interface changes |
|---|---|---|
| crawler      | @dev-alice    | @dev-alice + @tech-lead  |
| feed         | @dev-bob      | @dev-bob + @tech-lead    |
| quota        | @dev-alice    | everyone                 |

Rule: PRs that change index.ts exports require owner approval.
PRs that change internal logic only need standard review.
```

**Step 2: Split CLAUDE.md into .claude/rules/**
When CLAUDE.md > 150 lines → see Branch D section "CLAUDE.md evolution".
Path-scoped rules load only when Claude works in that directory.

**Step 3: Architecture tests in CI**

```bash
# Install dependency-cruiser (Node.js)
npm install --save-dev dependency-cruiser

# .dependency-cruiser.js
module.exports = {
  forbidden: [
    {
      name: 'no-cross-module-internals',
      comment: 'Modules must communicate through index.ts only',
      severity: 'error',
      from: { path: 'src/modules/([^/]+)/' },
      to: {
        path: 'src/modules/(?!$1/)([^/]+)/(?!index\\.ts)',
      }
    },
    {
      name: 'no-service-db-import',
      comment: 'Services must not import db directly',
      severity: 'error',
      from: { path: 'src/modules/.*\\.service\\.ts' },
      to: { path: 'src/shared/db' }
    }
  ]
}

# Add to CI (package.json):
"check:architecture": "depcruise src --config .dependency-cruiser.js"
```

**Step 4: Internal event bus for cross-module communication**

```typescript
// shared/events.ts
// When module A needs to NOTIFY module B (not query it)
// Use events instead of direct import

type AppEvent =
  | { type: 'feed.item.saved'; payload: { itemId: string; source: string } }
  | { type: 'quota.consumed'; payload: { source: string; units: number } }

// Module emits event — does not know who listens
eventBus.emit({ type: 'feed.item.saved', payload: { itemId, source } })

// Module subscribes — does not know who emitted
eventBus.on('quota.consumed', ({ source, units }) => { ... })
```

Why: decouples modules without the operational overhead of actual message queues.
When to add real queue (BullMQ/RabbitMQ): when event processing must survive restarts.

**Step 5: Separate DB schemas per module (not separate DBs)**

```sql
-- Still one PostgreSQL instance, but isolated schemas
CREATE SCHEMA feed;
CREATE SCHEMA quota;
CREATE SCHEMA crawler;

-- Tables namespaced to module
CREATE TABLE feed.items (...);
CREATE TABLE quota.usage (...);

-- No cross-schema queries allowed
-- quota schema cannot SELECT from feed schema
-- Feed service cannot see quota tables
```

This mimics microservices data isolation without the operational cost.
Extraction later becomes: point module at its own DB instance, done.

### What NOT to do in Stage 1
```
✗ Extract a module to a service because it's "big"
✗ Add a message queue because "it's more scalable"
✗ Split into microservices because a tech blog said to
✓ Fix the boundaries, run the architecture tests, own the modules
```

---

## Stage 2 — Modular Monolith patterns (team 10–30, proven product)

### Signal to enter Stage 2
All of these true:
```
□ Team > 10 people actively committing
□ Module ownership matrix from Stage 1 is in place
□ Product-market fit confirmed (users pay or return consistently)
□ Deployment frequency > 3 times/week and causing coordination pain
□ A specific module has measurably different load than the rest
```

### What to do

**Step 1: Module-level CI gates**

```yaml
# .github/workflows/module-tests.yml
# Each module must pass its tests independently

jobs:
  test-crawler:
    runs-on: ubuntu-latest
    steps:
      - run: npm test -- --testPathPattern="crawler"
  test-feed:
    runs-on: ubuntu-latest
    steps:
      - run: npm test -- --testPathPattern="feed"

# If crawler tests pass but feed tests fail → only feed is blocked
# Modules are independent units of stability
```

**Step 2: Public API versioning between modules**

```typescript
// modules/feed/index.ts — version the public interface
export interface IFeedService {
  // v1 — stable, never change signature
  saveBatch(items: FeedItem[]): Promise<SaveResult>

  // v2 — added in Stage 2, backward compatible
  saveBatchWithDedup(items: FeedItem[], options?: DedupOptions): Promise<SaveResult>
}

// When you change a module's public interface:
// 1. Add new method (don't change old one)
// 2. Mark old method @deprecated
// 3. Migration period: both exist
// 4. Remove old method only when all callers updated
```

**Step 3: Async by default for cross-module writes**

```typescript
// Stage 1 (synchronous — fine for small team):
await feedService.save(items)
await notificationService.notify(items)  // blocks

// Stage 2 (async — modules decouple):
await feedService.save(items)
eventBus.emit('feed.items.saved', items)  // fire and forget
// NotificationService subscribes independently
```

**Step 4: Load test individual modules**

```bash
# k6 or Artillery — test each module's endpoint independently
# Goal: know which module is the bottleneck BEFORE it becomes a crisis
k6 run --vus 100 --duration 30s tests/load/crawler-load.js
k6 run --vus 100 --duration 30s tests/load/feed-load.js
```

### What NOT to do in Stage 2
```
✗ Extract anything before Stage 2 signals appear
✗ Add Kubernetes "because we'll need it"
✗ Split database before schemas are stable
✓ Strengthen isolation, add versioning, make modules independently testable
```

---

## Stage 3 — Selective extraction via Strangler Fig (team 20–50)

### Signal to enter Stage 3

Must have ALL THREE — not just one:
```
□ The module has a dedicated team (>= 2 people, works on it full time)
□ The module has genuinely different deployment cadence than the rest
□ The module has demonstrably different scaling profile (10x more load)
```

If only 1 or 2 are true → stay in Stage 2. Extraction is NOT the answer yet.

### Strangler Fig — extraction without stopping the world

The Strangler Fig plant grows around a tree, eventually replacing it.
You never stop the old system. You route traffic gradually.

**4-phase extraction:**

```
Phase 1 — Shadow (no user impact)
  New service runs alongside monolith
  Monolith handles all traffic
  New service processes same traffic as shadow (write to separate DB)
  Compare outputs — do they match?

Phase 2 — Canary (1–5% traffic)
  Route 1% of real traffic to new service
  Monitor error rates, latency, data consistency
  Monolith still handles 99%
  If anything wrong → revert to 0% instantly

Phase 3 — Migration (5% → 50% → 100%)
  Gradually shift traffic
  Monitor at each step: 5%, 10%, 25%, 50%, 90%, 100%
  Keep monolith code live until 100% stable for 2 weeks

Phase 4 — Strangled (remove from monolith)
  Only after: 100% traffic, 2 weeks stable, zero rollbacks needed
  Remove module from monolith
  Remove feature flag
```

### Strangler Fig prompt templates

**Phase 1 — Define the interface boundary:**
```
Read CLAUDE.md and ARCHITECTURE.md.
We are extracting module: [name]

Step 1: Interface audit
Review modules/[name]/index.ts public exports.
List every function/class/type that other modules import.
This is the contract that must remain stable during extraction.

For each export, document:
- Current callers (which modules import it)
- Current signature
- Expected call volume (rough estimate)

Output: interface-audit-[name].md
Do NOT change any code yet.
```

**Phase 2 — Create the seam:**
```
Read interface-audit-[name].md.

Create IService interface mirroring current module's public API:
  src/interfaces/I[Name]Service.ts

Create LocalImpl wrapping current implementation:
  src/modules/[name]/local-impl.ts
  Implement I[Name]Service, delegates to existing code

Create HttpImpl (stub, not implemented yet):
  src/modules/[name]/http-impl.ts
  Implement I[Name]Service, throws NotImplementedError

Add feature flag:
  config/env.ts: USE_[NAME]_SERVICE: 'local' | 'http'

Wire factory:
  src/modules/[name]/factory.ts
  Returns LocalImpl when flag='local', HttpImpl when flag='http'

Update all callers to use I[Name]Service interface.
Run full test suite — all tests must pass.
Commit: "refactor([name]): introduce seam for service extraction"
```

**Phase 3 — Implement the new service:**
```
New service: [name]-service (separate repository)

Implement I[Name]Service as HTTP API.
Mirror the exact same interface — same inputs, same output shapes.
Add: health check, structured logging, request tracing.

Test strategy:
  Unit tests: same test cases as monolith's module tests
  Contract tests: same I[Name]Service interface, different impl
  Integration tests: deploy locally alongside monolith, verify parity

Do NOT deploy to production until contract tests pass for 3 days straight.
```

**Phase 4 — Traffic migration:**
```
Read interface-audit-[name].md and current error rate metrics.

Configure HttpImpl with retry + circuit breaker + fallback to LocalImpl:
  timeout: 5000ms
  retries: 3 with exponential backoff
  circuit breaker: open after 5 failures in 60s
  fallback: call LocalImpl if circuit open

Deploy with USE_[NAME]_SERVICE=local (no change to users).
Verify: LocalImpl still handling all traffic, HttpImpl cold standby.
Commit: "feat([name]): add http-impl with circuit breaker fallback"

Traffic migration plan:
  Day 1: 1% → monitor 24h → no errors → continue
  Day 2: 5% → monitor 24h
  Day 3: 25% → monitor 48h
  Day 5: 50% → monitor 48h
  Day 7: 100% → monitor 2 weeks
  Day 21: remove LocalImpl from monolith
```

---

## What shipright does and does not cover

```
Shipright covers:
  ✓ Setting up boundaries correctly from day one (L0)
  ✓ Detecting when Stage 1 signals appear (levels.md signals)
  ✓ CLAUDE.md evolution for growing team (Branch D)
  ✓ Tech debt triggers that fire at right time
  ✓ Strangler Fig prompt templates (this file)

Shipright does NOT cover:
  ✗ Event storming workshops (domain expert work, not Claude Code work)
  ✗ Kubernetes / service mesh setup (infrastructure, not architecture)
  ✗ Distributed transaction handling (needs dedicated study)
  ✗ SRE practices: SLO, error budget (organizational, not code)
  ✗ Multi-region architecture (very specialized, consult expert)
```

When you reach Stage 3 and need the above → shipright's job is done.
You need: senior architects, DDD consultants, or Anthropic's enterprise guidance.

---

## The actual success metric

A project architected with shipright from day one should be able to:
- Add a new module in < 1 day without touching existing modules
- Extract any module via Strangler Fig in < 4 weeks when signal demands
- Onboard a new developer in < 1 day using CLAUDE.md + ARCHITECTURE.md
- Know exactly what each module owns and what it doesn't

If all four are true → the architecture is healthy at any scale.
