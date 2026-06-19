# Claude Code Prompts — Copy-Paste Library

All prompts follow the same pattern:
1. **Orient**: tell Claude Code what files to read first
2. **Scope**: say exactly what to create/change and nothing more
3. **Order**: specify the sequence (inside-out, test-first)
4. **Gate**: state what "done" looks like

---

## L1 Prompts

### Start any new project from scratch
```
Read CLAUDE.md and ARCHITECTURE.md first.

Create the project skeleton following the module list in ARCHITECTURE.md:
- Each module: index.ts (public API only), types.ts, [name].service.ts with stub methods
- Stub methods throw NotImplementedError — do not implement any logic
- shared/: db.ts (connection pool), logger.ts (structured JSON), errors.ts (AppError base class), http-client.ts (with retry)
- config/env.ts: zod schema validating all env vars listed in CLAUDE.md
- package.json, tsconfig.json (strict: true), jest.config.ts
- docker-compose.yml: app + database

Verify: npm run build must pass with zero TypeScript errors.
Do not implement any business logic — stubs only.
```

---

## L2 Prompts

### Define interfaces + write test specs for one module
```
Read CLAUDE.md and ARCHITECTURE.md.
Module: [module-name].

Create in this exact order:
1. I[Name]Repository interface in [name].repository.ts
   - Method signatures only, no implementation
   - Return types must be domain objects from types.ts, not raw DB types
2. [Name]Repository class implementing the interface
   - All methods throw NotImplementedError
3. [Name]Handler with routes
   - Parse and validate request with zod
   - Call service methods (not repository directly)
   - Return typed HTTP responses
4. Write test cases in [name].service.test.ts
   - Mock I[Name]Repository (do not use real DB)
   - Cover: happy path, empty/null input, not-found case, dependency failure

Do NOT implement any business logic or SQL queries.
Run npm test — tests should be RED (this is correct at L2).
Run npm run build — must still pass.
```

### Define the ICrawler interface pattern (for source-based projects)
```
Read CLAUDE.md and ARCHITECTURE.md.

Define the core interface that all sources will implement:
1. ICrawler interface with: source: string, fetch(): Promise<[MainEntity][]>, isQuotaAvailable(): Promise<boolean>
2. MockCrawler class implementing ICrawler — returns hardcoded test data
3. [Orchestrator]Service using ICrawler[] via constructor injection
   - Use Promise.allSettled (not Promise.all) so one failure doesn't block others
4. Test cases for [Orchestrator]Service:
   - Two crawlers run in parallel
   - One crawler throws — other still succeeds
   - Quota unavailable — crawler is skipped

Do not create any real source implementations yet.
Tests must be RED. Build must pass.
```

---

## L3 Prompts

### Implement one feature (standard service+repository)
```
Read CLAUDE.md. Module: [module-name]. Feature: [feature-name].

The test cases for this feature already exist in [name].service.test.ts.

Implement in this order:
1. [Name]Service.[methodName]()
   - Business logic only
   - Calls repository via the I[Name]Repository interface
   - Does NOT import db directly
2. [Name]Repository.[methodName]()
   - SQL query returning a typed domain object (not a raw row)
   - Use parameterized queries (no string interpolation)
3. Migration file if schema change needed (filename: [timestamp]-[description].sql)

Run npm test after each step.
Implement ONLY enough to make the test cases green.
Do not add anything not covered by a test.
```

### Implement a pure normalizer (transform external data)
```
Read CLAUDE.md. Module: [source-name].

Implement [Source]Normalizer as a pure function (not a class):
- Input: [RawAPIResponse type from types.ts]
- Output: [MainEntity][]
- No side effects, no imports from shared/db or other modules
- Handle missing/null fields gracefully (external APIs are unreliable)

Write tests in [source].normalizer.test.ts:
- Pass a fixture (copy-paste a real API response sample here: [paste sample])
- Verify all fields map correctly
- Test missing optional fields don't crash
- Test malformed data returns empty array (not throws)

No mocks needed — normalizer is a pure function.
```

### Implement a crawler (external API call)
```
Read CLAUDE.md. Module: modules/sources/[source-name].

Implement [Source]Crawler implements ICrawler:
1. fetch() method: call [API endpoint] using shared/http-client
2. Call this.quotaService.isAvailable(this.source, [units]) before fetching
3. On success: call this.quotaService.consume(this.source, [units])
4. Pass raw response to [Source]Normalizer, return FeedItem[]
5. On any API error: log with logger, throw so Promise.allSettled catches it

Test using a fixture (mock axios, do NOT call the real API):
- Mock returns sample API response → verify correct FeedItem[] output
- Mock returns 429 (rate limit) → verify error is thrown and logged
- QuotaService.isAvailable returns false → verify fetch is skipped

Do not call the real API in tests.
```

### Implement a scheduled job entry point
```
Read CLAUDE.md.

Create jobs/crawl.job.ts:
1. node-cron schedule: '*/[interval] * * * *' (interval from env)
2. On each tick:
   a. Generate jobId = uuid()
   b. Call feedService.logJobStart(jobId)
   c. Run crawlerService.runAll() → collect PromiseSettledResult
   d. For fulfilled results: call feedService.deduplicateAndSave(items, jobId)
   e. Call feedService.logJobEnd(jobId, result)
   f. Log structured summary: { jobId, sources, itemsSaved, errors }
3. Handle SIGTERM gracefully: stop cron, finish current run, exit 0

Wire up dependency injection here:
- Instantiate all crawlers with their dependencies
- Pass to CrawlerService constructor
- Do NOT use any global singletons

Test: mock the cron trigger, verify logJobStart and logJobEnd are called.
```

---

## Boundary Check Prompts

### Run after every feature
```
Review the code just written in modules/[module-name].

Check each violation specifically:
1. Does any service file contain `import.*shared/db`? (service must not touch DB directly)
2. Does any service import from another module's internal files? (must go through index.ts)
3. Does any repository method return the raw query result instead of a typed domain object?
4. Does any handler contain business logic (domain if/else, not just HTTP status codes)?
5. Does any file violate the naming convention from CLAUDE.md?

For each violation found: show the exact line, explain why it's a violation,
provide the corrected version.
If zero violations: confirm "Boundary check passed — ready to commit."
```

### Run when adding a new module
```
Read ARCHITECTURE.md.

New module being added: [name].
Verify it follows all rules before writing any implementation:
1. Is this module in the module list in ARCHITECTURE.md? If not, stop and ask.
2. Does its proposed dependency list violate any forbidden dependency?
3. Does its public API (index.ts) expose only what other modules need?
4. Does it create any circular dependency?

If any answer is "no": explain what needs to change first.
If all pass: proceed with L2 setup for this module.
```

---

## Refactor Prompts

### Safe refactor (behavior unchanged)
```
Read CLAUDE.md.

Refactor [describe what to restructure] in [module]:
- Do NOT change any public interface (index.ts exports must stay identical)
- Do NOT change any test (tests define behavior — if tests need changing, stop)
- Keep all tests GREEN throughout

Run tests before starting. Run tests after each change.
If any test goes RED during refactor: revert that change, explain why.
```

### Extract a module from monolith (Strangler Fig)
```
Read CLAUDE.md and ARCHITECTURE.md.

Extract [module-name] into a standalone service using Strangler Fig pattern:
1. Define I[Name]Service interface (likely already exists in index.ts)
2. Create Http[Name]Service implementing the interface — calls the new service via HTTP
3. Create Local[Name]Service — the existing implementation, renamed
4. Add feature flag: [FLAG_NAME] in config/features.ts
5. In the injection point (usually jobs/ or app entry): switch on flag
6. Both implementations must pass the SAME test suite

Do NOT remove Local[Name]Service until the HTTP version is stable in production.
Do NOT change any caller of I[Name]Service.
```

---

## Debug Prompts

### Debug without breaking architecture
```
Read CLAUDE.md.

Bug: [describe the bug — what happens vs what should happen].
Reproduce: [steps or failing test].

Fix following these constraints:
- Fix in the correct layer (service bug → fix service, not handler)
- Write a failing test that reproduces the bug BEFORE fixing it
- Fix only what the test requires — no extra changes
- Do not add logic to handler to bypass service
- Do not add direct DB calls to service to bypass repository

After fix: run full test suite, confirm no regression.
```

### Diagnose a slow query (L4 trigger)
```
Signal: [metric] = [value], target = [target].

Slow code/query:
[paste the code or query here]

Analyze:
1. What is the likely cause? (missing index, N+1, full table scan, etc.)
2. Propose fixes ordered by: highest impact, lowest risk first
3. Which fix can be implemented without changing the service interface?

Implement the top fix:
- Stay inside the repository layer
- Write a benchmark test: measure time before and after with [N] rows of test data
- If fix requires a migration, write it as a separate file

Do not change any service or handler code.
```
