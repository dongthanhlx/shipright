# Requirement Drift — When Architecture Needs to Change

## The real problem

Requirements are never complete upfront. This is not a failure — it's the nature of software.
Users discover what they want by using what they didn't want.

The question is never "how do we get complete requirements first?"
The question is always: **"how do we make code that survives requirement change?"**

Two answers:
1. **Defer decisions** — don't decide architecture earlier than necessary
2. **Seams, not flexibility** — code doesn't need to be "flexible", it needs clear cut points

---

## Seams — the only thing that matters

A **seam** is a place where you can swap behavior without touching surrounding code.

```
Interface → seam (swap implementation)
Pure function → seam (swap logic, test independently)  
Constructor injection → seam (inject different dependency)
Feature flag → seam (swap at runtime)
Config value → seam (swap without deploy)
```

When requirement changes force architecture change, the question is:
**"Is there a seam at the right place?"**

If yes → surgery (hours)
If no  → rewrite (days/weeks)

The goal at L0-L2 is not to predict future requirements.
It is to **place seams at the most likely change points**.

---

## Decision Deferral — don't decide until forced

Common premature decisions and when to actually make them:

| Decision | Premature (avoid) | Deferred (correct) |
|---|---|---|
| Queue vs direct call | Day 1 | When: async becomes required OR processing > 2s |
| Cache layer | Day 1 | When: measured latency > target |
| Multiple notification channels | Day 1 | When: second channel is actually needed |
| Microservice split | Day 1 | When: team > 1 working on same module, or scale demands it |
| Event sourcing | Day 1 | When: audit trail or temporal queries are required |
| CQRS | Day 1 | When: read/write models diverge significantly |

**How to defer safely**: write simple code with a seam at the decision point.
When the decision is forced, cut at the seam and replace.

---

## The 3 Scenarios When Architecture Must Change

### Scenario A — Simple feature addition (low impact)
Requirement expands but stays in the same domain.

Example: "crawl Google" → "crawl Google AND YouTube AND Reddit"

**Impact**: Low. `ICrawler` seam was already there.
**Action**: Add new implementation, register it. Zero changes to existing code.
**Signal this was handled well**: adding the feature took < 2 hours.

```
Before: GoogleCrawler implements ICrawler
After:  GoogleCrawler + YouTubeCrawler + RedditCrawler all implement ICrawler
        CrawlerService unchanged. FeedService unchanged.
```

---

### Scenario B — Requirement reveals wrong abstraction (medium impact)
New requirement doesn't fit the current abstraction but fits a known pattern.

Example: "save all items" → "save items, but deduplicate AND enrich with AI AND notify subscribers"

The current linear `fetch → save` pipeline doesn't fit.
The right abstraction is a **processing pipeline / chain of responsibility**.

**Diagnose first** — run this checklist:
```
[ ] Does the new requirement add a new step to an existing flow? → Pipeline pattern
[ ] Does the new requirement add a new type of the same thing?  → Strategy pattern  
[ ] Does the new requirement add reactions to existing events?  → Observer/Event pattern
[ ] Does the new requirement add a new way to build something?  → Builder/Factory pattern
[ ] Does the new requirement make one class do 2+ unrelated things? → Split the class
```

**Action**: Identify the pattern, create the seam, migrate.
The migration MUST happen inside a green test suite — refactor under green, never blind.

```
Step 1: write test for new behavior (RED)
Step 2: refactor existing code to fit new pattern (tests stay GREEN)
Step 3: implement new behavior (test goes GREEN)
Step 4: commit
```

---

### Scenario C — Requirement reveals fundamental wrong assumption (high impact)
The core architectural assumption was wrong.

Example: "single user crawl" → "multi-tenant, each tenant has own quota and isolated feed"

This changes the domain model. `FeedItem` needs `tenantId`. `QuotaService` needs tenant scope.
Every module is affected. This is the scenario everyone fears.

**The senior response**: don't panic, don't rewrite everything at once.

**Expand-Contract pattern** (the safe way to change a foundational type):

```
Phase 1 — EXPAND (add without breaking)
  Add tenantId as optional field: FeedItem { ..., tenantId?: string }
  All existing code still works. New code uses tenantId.
  Tests: old tests still pass, new tests for tenant behavior added.
  Deploy: safe.

Phase 2 — MIGRATE (move existing data/code)  
  Backfill existing records with default tenantId = 'default'
  Update all queries to filter by tenantId
  Tests: add integration tests for tenant isolation
  Deploy: safe (default tenant = backward compatible)

Phase 3 — CONTRACT (remove the optional)
  Make tenantId required: FeedItem { ..., tenantId: string }
  TypeScript will show every place that needs updating
  Fix compile errors one by one
  Tests: all pass
  Deploy: safe.
```

Never jump straight to Phase 3. The expand step is what makes the migration survivable.
The database side (live schema changes, locks, batched backfills) is `references/deploy.md` §3.

---

## Claude Code prompts for each scenario

### Diagnose what changed
```
Requirement has changed. Original: [old requirement].
New requirement: [new requirement].

Analyze the gap:
1. Does this add a new step to an existing flow? (→ pipeline)
2. Does this add a new type of existing thing? (→ strategy/plugin)  
3. Does this add reactions to existing events? (→ observer/event)
4. Does this change a core domain assumption? (→ expand-contract)

Which pattern best fits? Show a before/after diagram of the module structure.
Do NOT write any implementation code yet.
```

### Scenario A — New implementation of existing interface
```
New source to add: [name].
The ICrawler interface already exists.
Create [Name]Crawler implementing ICrawler and [Name]Normalizer.
Register in [entry-point].
Zero changes to CrawlerService, FeedService, or any existing crawler.
Write tests: mock API response → verify FeedItem[] output matches expected shape.
```

### Scenario B — Refactor to new pattern (under green tests)
```
Current code: [describe current structure].
New requirement: [new requirement].
Pattern needed: [Pipeline / Strategy / Observer / Factory — from diagnosis].

Refactor in this order:
1. Write test for new behavior (RED — correct)
2. Refactor existing code to fit [pattern] — all OLD tests must stay GREEN during this
3. If any old test goes RED during refactor: STOP, revert that step, find different approach
4. Once structure fits pattern and old tests GREEN: implement new behavior
5. New test goes GREEN. Commit.

Do NOT implement new behavior before the structure is ready.
Do NOT break existing tests at any point.
```

### Scenario C — Core domain type change (expand-contract)
```
Core type changing: [TypeName].
New field needed: [fieldName: type].
Reason: [why this field is now required].

Execute Expand-Contract in 3 phases. Do one phase per session.

PHASE 1 — EXPAND (do this now):
- Add [fieldName] as OPTIONAL to [TypeName]: [fieldName]?: [type]
- Update all places that CREATE [TypeName] to include [fieldName] when known
- All existing code that READS [TypeName] continues to work (field is optional)
- Run full test suite — must be GREEN
- Commit: "expand([TypeName]): add optional [fieldName]"

PHASE 2 — MIGRATE (next session):
- Update all queries/factories to always populate [fieldName]
- Add tests for new behavior using [fieldName]
- Commit: "migrate([TypeName]): populate [fieldName] everywhere"

PHASE 3 — CONTRACT (final session, only after Phase 2 is stable):
- Make [fieldName] required: [fieldName]: [type]
- Fix every TypeScript/type error that appears
- Remove any compatibility shims added in Phase 1
- Commit: "contract([TypeName]): make [fieldName] required"
```

---

## Pre-flight checklist before ANY architecture change

Run this before touching a single line:

```
[ ] Do I have test coverage for the code I'm about to change?
    No → write characterization tests first (test what it CURRENTLY does)
    
[ ] Can I describe the change in one sentence?
    No → the change is too big, break it into smaller steps
    
[ ] Do I know which pattern fits the new requirement?
    No → run the diagnosis prompt first
    
[ ] Is there a seam at the right place already?
    Yes → cut at seam, replace implementation (hours)
    No  → first create the seam (refactor), then replace (separate commit)
    
[ ] Will I keep old tests GREEN during the refactor?
    No → wrong approach, find one that doesn't break existing behavior
```

---

## Signals that architecture is drifting (catch early)

Watch for these in L3 — they signal a pattern mismatch, not just tech debt:

| Signal | What it means | Action |
|---|---|---|
| Service method > 80 lines | Too much responsibility in one place | Extract to domain service or split aggregate |
| Adding `if type == 'X'` inside service | Need Strategy pattern | Extract type-specific behavior behind interface |
| New feature touches > 3 modules | Wrong module boundary | Rethink bounded context before implementing |
| Same data shape copied across modules | Missing shared domain concept | Extract to shared domain type |
| "I need to know about X to do Y" | Wrong dependency direction | Introduce domain event or invert dependency |
| Handler growing with business logic | Layer boundary eroding | Move logic to service, handler is parse/format only |

When you see these signals: **stop, diagnose, fix the structure, then continue**.
Implementing on top of wrong structure compounds the problem every feature.

---

## The mindset shift

Junior: "Requirements changed, I need to refactor everything"
Senior: "Requirements changed, let me find where the seam should have been,
         create it if it's not there, then make the change"

Junior: "I need to know all requirements before I design"  
Senior: "I need to design so that requirement changes are cheap,
         and defer decisions until I'm forced to make them"

Junior: "The architecture is wrong, let me rewrite"
Senior: "The abstraction is wrong in one place, let me Expand-Contract that type
         and refactor under green tests"
