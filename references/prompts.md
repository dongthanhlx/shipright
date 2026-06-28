# Claude Code Prompts — Copy-Paste Library

Current as of v0.7.2. Aligned with complexity tiers and ecosystem delegation.

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
1. CLAUDE.md — include:
   - Ubiquitous Language table (3-5 domain terms from Q2b)
   - 4 boundary rules specific to this project with banned examples
   - Clean Code rules (functions max 20 lines, no AND/OR names)
   - Tech stack
   - Core modules for skeleton only
   - Tech debt log with TODO[trigger]
   - Registry entry loaded: [project type]
   - Shipright state section at end:
     Level: L0 | Active: constitution | Next: L1 skeleton | Skills active: [list]
2. ARCHITECTURE.md — ASCII flow diagram, 2-3 modules max,
   core domain type with comments, 1 ADR for hardest decision

After generating: load references/registry.md entry for this project type.
Note which skills to install + which CLAUDE.md additions to copy.

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


---

## Financial / Custodial wallet prompts

### Generate accounts (multi-chain)
```
Read CLAUDE.md and ARCHITECTURE.md.
Generate [N] accounts for network: [EVM/SOL/TRON/TON/SUI]

Rules:
- Use battle-tested library for key generation (ethers.js, @solana/web3.js, etc.)
- NEVER self-implement cryptographic key generation
- Encrypt private key immediately after generation using Crypt service
- Private key must NOT exist in plaintext anywhere after encryption
- Store encrypted key + public address only
- Log: "Generated N accounts for [network]" — never log key material
```

### Sign and send transaction (payout)
```
Read CLAUDE.md payout signing rules.
Implement sendTransaction(ticket, account) for [network]:

Rules (Boundary 6 — private key lifecycle):
  1. Decrypt private key INSIDE this function only
  2. Create wallet/signer from decrypted key
  3. Build transaction
  4. Sign and broadcast
  5. Clear decrypted key from memory (account.privateKey = '')
  6. Return transaction hash ONLY

Never: return account object with decrypted key, log key material, pass key as argument
Gate: grep for 'privateKey' in payout provider — should appear in exactly one place
```

### Financial state machine (ticket lifecycle)
```
Add explicit state machine to [PayoutTicket/PayinLog/Entity]:

States: [list all states]
Transitions (explicit, no skipping):
  [FromState] → [ToState]: condition + action + log

Rules:
- Validate current state before transitioning
- Log every transition with: from_state, to_state, reason, actor, timestamp
- Terminal states ([Processed/Failed]) must throw if transition attempted
- State stored in DB — never derive from other fields
```

### Idempotency for financial operation
```
Add persistent idempotency to [operation]:

Pattern (DB-based):
  1. Check: existing = await db.findUnique({ where: { idempotencyKey: ticket.id } })
  2. If exists: return existing result (do NOT process again)
  3. Process operation
  4. Mark: await db.create({ data: { idempotencyKey: ticket.id, result } })

Rules:
- idempotencyKey = ticket/operation ID (not random UUID each call)
- Check-and-mark must be atomic where possible (use DB transaction)
- Never use in-memory Map or boolean — lost on restart
- For blockchain: use txHash as additional idempotency check after broadcast
```

### Scheduler with distributed lock
```
Add distributed lock + session audit to [SchedulerName]:

Pattern:
  1. Check lock: if (await settings.isLocked(LockKey.[NAME])) return
  2. Acquire lock: await settings.lock(LockKey.[NAME])
  3. Open session: session = await this.openSession('[name]', 0)
  4. Process in chunks: CHUNK_SIZE = [N], never process all at once
  5. Close session: await this.closeSession(session)
  6. Release lock in finally: await settings.unlock(LockKey.[NAME])

Rules:
- Lock key must be unique per scheduler
- Chunk size configured via settings table, not hardcoded
- Always release lock in finally block (even on error)
- Log chunk progress: 'Processing batch N of M accounts'
```

### Blockchain nonce management (EVM, concurrent payouts)
```
Add sequential payout processing to prevent nonce conflicts:

For low-medium volume (recommended):
  - Ensure only ONE payout scheduler runs at a time (DB lock)
  - Process payout queue sequentially, not concurrently
  - Fetch fresh nonce (eth_getTransactionCount 'pending') before each tx

For high volume (advanced):
  - Maintain pending nonce counter in Redis per sender address
  - INCR before signing, DECR on failure/timeout
  - Reconcile with on-chain count on startup

Never: fetch nonce 'latest' and process multiple payouts in parallel from same address
```

## Blockchain tests (Foundry / Anchor)

### EVM — Foundry test template
```
Write Foundry tests for [contract name]:

test/[ContractName].t.sol:
  setUp(): deploy contract, set up accounts
  test_[function]_happyPath(): expected success case
  test_[function]_revertWhen_[condition](): vm.expectRevert(...)
  test_[function]_emitsEvent(): vm.expectEmit(...)
  test_[function]_edgeCase_zero(): zero amount behavior
  test_[function]_edgeCase_max(): max uint256 behavior
  testFuzz_[function](uint256 amount): fuzz with bound(amount, 1, MAX)

Run: forge test -vvv
Coverage: forge coverage --report lcov
All tests must pass before: forge script / forge create
```

### Solana — Anchor test template
```
Write Anchor tests for [program name]:

tests/[program-name].ts:
  before(): create wallets, airdrop SOL, initialize program
  it("[instruction] — happy path"): ...
  it("[instruction] — fails when unauthorized"): try/catch, check error code
  it("[instruction] — handles zero amount"): edge case
  it("[instruction] — idempotent"): call twice, assert same state

Run: anchor test
All tests must pass before: anchor deploy
```

---


## Third-party API exploration (Layer 1 — do before Adapter)

```
Before writing Adapter code for [provider name]:

Phase A — Study docs (do before any API call):
  Create api-exploration/[provider]/API-NOTES.md
  Document each endpoint:
    - Auth: type, header name, how to get test credentials
    - Params: name | location (body/query/header) | type | required | default | constraints
    - What each key param does and valid values
    - Documented response shape (paste from docs)
    - Error codes and how to handle each
    - Rate limits: N req/window, headers for remaining quota

Phase B — Build Bruno request from docs:
  api-exploration/[provider]/[endpoint-name].bru
  Use REALISTIC test values — not placeholder strings.
  Values should exercise the specific behavior you need.

Phase C — Call sandbox, document reality:
  Run each scenario and save responses:
    tests/fixtures/[provider]-success.json        (happy path)
    tests/fixtures/[provider]-minimal.json        (only required params)
    tests/fixtures/[provider]-error-401.json      (auth failure)
    tests/fixtures/[provider]-empty.json          (valid but no results)
    tests/fixtures/[provider]-rate-limit.json     (429 response)
  For each: note fields present but not in docs, type mismatches

Phase D — Update API-NOTES.md with "Reality vs Docs":
  - Fields in response not in docs
  - Type surprises (price is string not number)
  - Params that ARE optional despite docs saying required
  - Undocumented error codes encountered

Phase E — Write Adapter using fixtures as source of truth:
  Normalizer: raw response fixture → domain type
  Unit tests: feed fixtures, assert output shape
  Zero real API calls in test suite — runs offline, no quota consumed
```

---
## Strangler Fig (extract module from monolith)

> Full 4-phase playbook with prompt templates in `references/scaling-guide.md`.
> Only attempt extraction when ALL THREE signals are present:
> dedicated team for module + different deploy cadence + different scaling profile.

```
Quick reference — 4 phases:
Phase 1: Shadow (run alongside, compare outputs, no user impact)
Phase 2: Canary (1–5% real traffic, circuit breaker ready)
Phase 3: Migration (5% → 25% → 50% → 100%, monitor at each step)
Phase 4: Remove from monolith (only after 2 weeks stable at 100%)

For full prompt templates: read references/scaling-guide.md
```
