# Stack Reference: Node.js + TypeScript

Use these concrete names when SKILL.md says generic terms.

## Mapping: generic → Node.js specific
```
public boundary file    → index.ts (barrel export)
schema validation       → zod
test runner             → jest + ts-jest
build check             → tsc --noEmit
http validation         → zod + express/fastify
db client               → pg (node-postgres) or Prisma
migration tool          → db-migrate (SQL files) or Prisma migrate
http client             → axios + axios-retry
structured logging      → pino
env validation          → zod (parse process.env at startup)
scheduler               → node-cron
```

## Project init prompt
```
Read CLAUDE.md and ARCHITECTURE.md.
Create Node.js + TypeScript project skeleton:
- tsconfig.json: strict: true, noUncheckedIndexedAccess: true, exactOptionalPropertyTypes: true
- package.json: scripts: build (tsc), test (jest), dev (ts-node-dev), lint (eslint)
- jest.config.ts: ts-jest preset, coverage threshold 80%
- .eslint.config.js: @typescript-eslint/recommended + no-floating-promises rule
- Each module: index.ts, types.ts, [name].service.ts (stub — throws NotImplementedError)
- shared/: db.ts (pg Pool singleton), logger.ts (pino), errors.ts (error hierarchy), http-client.ts (axios + axios-retry 3x exp backoff)
- config/env.ts: zod schema, z.object({...}).parse(process.env) at top — throws on startup
- docker-compose.yml: app (node:20-alpine) + postgres:16
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
npx jest --passWithNoTests && echo "Tests passed"
```

## Circular dependency check
```bash
npx madge --circular --extensions ts src/
# Must return: No circular dependency found!
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
