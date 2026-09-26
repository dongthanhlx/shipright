# Stack Reference: Node.js + TypeScript

Use these concrete names when SKILL.md says generic terms.

> Building a **desktop app with Electron**? Load `references/desktop.md` (the rules) and
> `references/stacks/electron.md` (main/preload/renderer, typed IPC, the security baseline, packaging).

## Mapping: generic → Node.js specific
```
public boundary file    → index.ts (barrel export)
schema validation       → zod
runtime                 → Node.js 24 LTS (active LTS; 26 becomes LTS late Oct 2026). Never an EOL line (20 ended Apr 2026)
test runner             → Vitest (TS/ESM-native; same API shape as Jest)
build check             → tsc --noEmit (TypeScript 7 — the native compiler)
dev runner              → tsx watch
http validation         → zod + express/fastify
db client               → Drizzle ORM or Kysely (type-safe SQL) · Prisma · plain pg
migration tool          → drizzle-kit · Prisma migrate (versioned SQL, committed)
http client             → built-in fetch + AbortSignal.timeout() (Boundary 5 in one line); axios + axios-retry if you want interceptors/retry built in
structured logging      → pino
env validation          → zod (parse process.env at startup)
scheduler               → node-cron
```

## Framework — pick a default, keep it at the edge

shipright is framework-agnostic: the domain/service/repository never import the framework, so it
stays a TWO-WAY door — swappable, and choosing "wrong" is cheap to fix (judgment.md +
references/evolutionary-architecture.md). Recommend with a reason; don't agonize.
```
Default: Fastify — fast, schema-first (pairs with zod), minimal ceremony.
NestJS — opinionated structure + DI + decorators out of the box (larger teams / many modules).
Express — when the team/ecosystem already lives there (biggest middleware ecosystem; older, slower).
Hono — edge / serverless runtimes.
```
Confine it to the handler layer only. If a service or repository imports the framework, that's a
Boundary 2 violation — and it also nails you to the framework (a one-way door you didn't need).

## Project init prompt
```
Read CLAUDE.md and ARCHITECTURE.md.
Create Node.js + TypeScript project skeleton:
- tsconfig.json: strict: true, noUncheckedIndexedAccess: true, exactOptionalPropertyTypes: true
- package.json: "type": "module"; engines.node ">=24"; scripts: build (tsc), test (vitest run), dev (tsx watch src/index.ts), lint (eslint .)
- vitest.config.ts: coverage (v8) threshold 80%
- eslint.config.js (flat config): typescript-eslint recommendedTypeChecked + no-floating-promises
- Each module: index.ts, types.ts, [name].service.ts (stub — throws NotImplementedError)
- shared/: db.ts (Drizzle/pg pool singleton), logger.ts (pino), errors.ts (error hierarchy), http-client.ts (fetch + AbortSignal.timeout + retry with backoff+jitter on transient errors only)
- config/env.ts: zod schema, z.object({...}).parse(process.env) at top — throws on startup
- docker-compose.yml: app (node:24-alpine) + postgres:18
Gate: npx tsc --noEmit must pass.
```

## Error hierarchy (Node.js)
```typescript
// shared/errors.ts
export class AppError extends Error {
  constructor(message: string, public readonly code: string) {
    super(message)
    this.name = this.constructor.name
  }
}
export class DomainError extends AppError {}
export class ValidationError extends DomainError { readonly httpStatus = 400 }
export class NotFoundError extends DomainError { readonly httpStatus = 404 }
export class ConflictError extends DomainError { readonly httpStatus = 409 }
export class ForbiddenError extends DomainError { readonly httpStatus = 403 }
export class InfrastructureError extends AppError {}
export class DatabaseError extends InfrastructureError { readonly httpStatus = 503 }
export class ExternalAPIError extends InfrastructureError { readonly httpStatus = 502 }
export class NotImplementedError extends Error {}
```

## Idempotency pattern (Node.js + PostgreSQL)
```typescript
// For cron jobs: advisory lock prevents overlap
async function runWithLock(lockId: number, fn: () => Promise<void>) {
  const { rows } = await db.query('SELECT pg_try_advisory_lock($1)', [lockId])
  if (!rows[0].pg_try_advisory_lock) {
    logger.warn({ lockId }, 'Job already running, skipping')
    return
  }
  try { await fn() }
  finally { await db.query('SELECT pg_advisory_unlock($1)', [lockId]) }
}

// For API endpoints: idempotency key in header
// INSERT INTO ... ON CONFLICT (idempotency_key) DO NOTHING RETURNING *
```

## Boundary grep commands
```bash
# Run these before every commit:
grep -r "from.*shared/db" src/modules/ && echo "VIOLATION: service importing db directly"
grep -rE "from.*\.(service|repository)" src/modules/*/index.ts && echo "VIOLATION: bypassing index.ts"
npx tsc --noEmit && echo "Type check passed"
npx vitest run --passWithNoTests && echo "Tests passed"
```

## Circular dependency check
```bash
npx madge --circular --extensions ts src/
# Must return: No circular dependency found!
```

---

## Security — top Node.js pitfalls (see references/security.md for the spine)

The mistakes Claude makes most in Node/TS, with the safe pattern. Grounded in OWASP + the OWASP
Node.js Security Cheat Sheet.

```
A05 Injection
  ✗ child_process.exec(`convert ${userFile}`)        → command injection
  ✓ execFile('convert', [userFile])                   // args array, no shell
  ✗ db.query(`SELECT * FROM u WHERE id = ${id}`)      → SQLi
  ✓ db.query('SELECT * FROM u WHERE id = $1', [id])   // parameterized, always
  ✗ eval(x) / new Function(x) on any input; res.send(userHtml) unescaped (XSS)

A01 Broken Access Control (the #1 real breach)
  ✓ Authorize in the SERVICE, on every call, deny-by-default. Never trust a client-sent role/id.
  ✗ handler checks nothing and passes req.body.userId straight through (IDOR).

A07 Auth
  ✓ verify JWT with an explicit algorithm allow-list — reject alg:"none". Rate-limit login.
  ✓ argon2/bcrypt for passwords; httpOnly+secure+sameSite cookies.

A10 SSRF (outbound from an adapter)
  ✗ axios.get(userSuppliedUrl) → SSRF into internal network
  ✓ allow-list host/scheme before fetching; block private IP ranges. (Boundary 4 is where this lives.)

Other Node-specific
  ✓ Guard prototype pollution: reject __proto__/constructor keys when merging untrusted objects.
  ✓ helmet() for security headers; validate every request body with zod at the handler boundary.
  ✓ Secrets from env only — never in code, logs, or error messages.

A03 Supply chain
  ✓ commit package-lock.json; `npm audit --audit-level=high` in CI; review postinstall scripts.
```

Boundary check:
```bash
grep -rEn "child_process|exec\(|eval\(|new Function" src/modules/ && echo "review: injection surface"
grep -rEn "\$\{[^}]+\}.*(SELECT|INSERT|UPDATE|DELETE)" src/ && echo "review: string-built SQL"
```

---

## Ubiquitous Language for this stack

Define domain terms in CLAUDE.md BEFORE naming any class/function.
Claude will use these terms for all generated code in this project.

Common mistake: letting Claude default to generic names:
- `UserService` → should be `SubscriberEnrollmentService` (domain term)
- `DataProcessor` → should be `FeedNormalizer` (domain term)
- `ItemRepository` → should be `ArticleRepository` (domain term)

Add to CLAUDE.md:
```markdown
## Ubiquitous Language
| Term | Meaning | Not |
|---|---|---|
| [your term] | [precise definition] | [generic alias Claude would default to] |
```
