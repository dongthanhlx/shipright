# Claude Code Prompts — Copy-Paste Library

Current as of v0.5.0. Aligned with complexity tiers and ecosystem delegation.

All prompts follow this pattern:
1. **Orient** — tell Claude Code what to read first
2. **Scope** — exactly what to create/change
3. **Order** — sequence (inside-out, test-first)
4. **Gate** — what "done" looks like

---

## L0 — Generate project constitution

### New project (MVP mode)
```
Read CLAUDE.md and ARCHITECTURE.md if they exist.

Create MVP constitution for project: [name]
Problem: [one sentence]
Walking skeleton: [one user journey]
Stack: [stack]
Third-party APIs: [list or none]

Generate:
1. CLAUDE.md — 4 boundary rules specific to this project,
   tech stack, core modules for skeleton only, tech debt log with TODO[trigger]
2. ARCHITECTURE.md — ASCII flow diagram, 2-3 modules max,
   core domain type with comments, 1 ADR for hardest decision

Do NOT include: full error taxonomy, all ADRs, performance specs.
MVP constitution must fit under 80 lines each.
```

### New project (production mode)
```
Create full production constitution following references/l0-templates.md.
Project: [name], Stack: [stack], Modules: [list]

Generate complete CLAUDE.md and ARCHITECTURE.md including:
error taxonomy (Domain/Infrastructure split), idempotency decisions,
all modules with public APIs and forbidden deps, ADRs for non-obvious decisions.
```

---

## L1 — Project skeleton

### Node.js + TypeScript
```
Read CLAUDE.md and ARCHITECTURE.md.

Create project skeleton — module list from ARCHITECTURE.md:
- Each module: index.ts (public API only), types.ts, [name].service.ts (stubs throw NotImplementedError)
- shared/: db.ts (pg.Pool), logger.ts (pino), errors.ts (AppError hierarchy), http-client.ts (axios + axios-retry)
- config/env.ts: zod schema, throws on startup if required vars missing
- package.json, tsconfig.json (strict: true), jest.config.ts (80% coverage threshold)
- docker-compose.yml: app + postgres

Gate: npx tsc --noEmit must pass with zero errors.
Do NOT implement any logic — stubs only.
```

### Python + FastAPI
```
Read CLAUDE.md and ARCHITECTURE.md.

Create project skeleton:
- Each module: __init__.py (explicit __all__), types.py (Pydantic models), [name]_service.py (stubs raise NotImplementedError)
- shared/: db.py (SQLAlchemy async), logger.py (structlog), errors.py (exception hierarchy), http_client.py (httpx + tenacity)
- config/settings.py: pydantic BaseSettings, fails on startup if required vars missing
- pyproject.toml, mypy.ini (strict), pytest.ini

Gate: mypy --strict src/ must pass with zero errors.
```

---

## L2 — Interfaces + test specs (Outside-In TDD)

```
Module: [name]. Read CLAUDE.md and [name]/types.ts.

Write failing test cases for [Name]Service FIRST:
- Write tests AS IF the service already works
- Do NOT define repository interface first — let it emerge from what tests need to call
- Cover: happy path, not-found, validation failure, dependency failure
- If module has mutations: include idempotent retry test case

After test cases exist:
- Extract I[Name]Repository interface from what tests mocked
- Create [Name]Repository class (stubs throw NotImplemented)
- Create [Name]Handler: parse → validate → call service → format (no domain logic)

Run tests — they MUST be RED. RED = correct at L2.
Build must still pass.
```

---

## L3 — Implement features (by complexity tier)

### Tier S — Trivial (1 file, < 30 min)
```
Change: [describe single-file change]
Read CLAUDE.md for boundary rules.
Implement. Run boundary check. Commit.
No additional skills needed.
```

### Tier M — Simple (2–5 files, clear scope)
```
Feature: [name]. Test cases exist in [name].service.test.ts.

Implement in order:
1. [Name]Service.[method]() — business logic, calls repository via interface
2. [Name]Repository.[method]() — SQL query, returns typed domain object (not raw row)
3. Migration if schema change needed

Run tests after EACH step. Implement ONLY enough to make tests GREEN.
After GREEN: run boundary checklist and report violations.
```

### Tier L — Complex (5–10 files)
```
[if addyosmani spec-driven-development installed]:
  Activate spec-driven-development for this feature.
  After spec approved: /build auto

[if not installed]:
  1. Write acceptance criteria: what must be true when done?
  2. Break into sub-tasks, ordered by dependency
  3. Implement one sub-task at a time: test → implement → GREEN → commit
  4. Feature flag if incomplete work needs to merge
```

---

## Boundary check (run after every feature)

```
Review code just written in modules/[module-name]:

1. Any service file contain `import.*shared/db`? (must be empty)
2. Any service import another module bypassing index.ts?
3. Any repository return raw DB row instead of typed domain object?
4. Any handler contain domain if/else (not just HTTP status codes)?
5. Any raw third-party response pass beyond the Adapter?

List each violation with exact line and corrected version.
If zero violations: confirm "Boundary check passed — ready to commit."
```

---

## Third-party API integration

### Layer 1 — Exploration (do once)
```
Create Bruno collection in api-exploration/[provider-name]/
Call sandbox endpoint: [endpoint]
Save responses to:
  tests/fixtures/[provider]-success.json
  tests/fixtures/[provider]-error-[code].json
Note: which fields are optional, what types vary, pagination shape.
```

### Layer 2 — Adapter + unit tests
```
Create [provider].normalizer.ts as pure function:
  Input: raw API response (typed as unknown)
  Output: [InternalType][]

Use zod to validate response shape before normalizing.
Handle missing/null fields gracefully — return null or [] not throw.

Create [provider].normalizer.test.ts:
  Feed fixtures from tests/fixtures/
  Assert: field types correct, optional fields handled, empty result = [] not throw
  No HTTP calls. No mocks. Pure function test. Must run offline < 100ms.
```

### Layer 3 — Contract test (scheduled)
```
Create [provider].contract.test.ts tagged @group contract:
  Call real sandbox API
  Compare response SHAPE (not data) with saved fixture
  Fail = provider changed schema → update fixture → update normalizer

Run: daily via CI cron, NOT on every commit.
Alert on failure: "Provider [name] API schema changed."
```

---

## Safe refactor

```
Refactor [describe what to restructure] in [module]:
- Do NOT change any public interface (index.ts exports stay identical)
- Do NOT change any test (tests define behavior)
- Keep all tests GREEN throughout

Run tests before starting. Run tests after each change.
If any test goes RED: revert that step, find a different approach.
```

---

## Strangler Fig (extract module from monolith)

```
Extract [module] into standalone service:
1. Define I[Name]Service interface (likely already in index.ts)
2. Create Http[Name]Service implementing interface — calls new service via HTTP
3. Create Local[Name]Service — rename existing implementation
4. Feature flag [FLAG_NAME] to switch between implementations
5. Both implementations must pass the SAME test suite

Do NOT remove Local[Name]Service until HTTP version is stable in production.
Do NOT change any caller of I[Name]Service.
```
