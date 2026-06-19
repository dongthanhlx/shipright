# L0 File Templates

Use these as the exact structure when generating L0 files.
Replace every `[placeholder]` with project-specific content.
Do NOT leave generic content — every section must be specific to this project.

---

## CLAUDE.md Template

```markdown
# CLAUDE.md — [Project Name] Constitution

## Project in one sentence
[Input] → [Process] → [Output].

---

## Architecture rules — NEVER violate

### Module boundaries
- [ModuleA] NEVER imports from [ModuleB]'s internal files
- [Service layer] NEVER imports `shared/db` directly
- Cross-module calls go through `modules/[name]/index.ts` only

### Layer rules
- **Handler**: parse → validate → call service → format response. NO domain logic
- **Service**: business logic only. NO direct DB. NO HTTP framework imports
- **Repository**: DB queries ONLY. Returns typed domain objects, NOT raw rows
- **[Source/Adapter]**: external calls ONLY. Normalization is NOT its job

### Imports that will FAIL code review
```
// BANNED — service accessing DB directly:
import { db } from '../../shared/db'

// BANNED — bypassing module boundary:
import { X } from '../[other-module]/[other-module].service'

// CORRECT — use index.ts:
import { X } from '../[other-module]'
```

---

## Coding workflow — follow in order

1. Read this file + ARCHITECTURE.md before any action
2. Write types/interfaces first — no implementation until shape is agreed
3. Write test cases before implementation — tests must be RED first
4. Implement inside-out: [innermost layer] → [middle] → [outer]
5. Run tests after each layer — never implement 2+ layers before testing
6. Run boundary checklist before commit
7. Commit small: 1 feature = 1 commit. Never commit with RED tests

## Pre-commit boundary checklist
```bash
# Run these — all must return empty:
grep -r "from.*shared/db" src/modules/
grep -r "from.*[banned-import-pattern]" src/modules/

# Check manually:
[ ] Repository returns typed objects (not raw query rows)
[ ] Handler has no domain if/else
[ ] New files follow naming: [module].[layer].ts
```

---

## Tech debt log

| Shortcut | Accepted because | Trigger to fix |
|---|---|---|
| [shortcut 1] | [reason] | TODO[[trigger]]: [fix description] |
| [shortcut 2] | [reason] | TODO[[trigger]]: [fix description] |

Mark new shortcuts: `// TODO[trigger]: description`

---

## Tech stack
```
Runtime:    [e.g. Node.js 20 + TypeScript strict]
Database:   [e.g. PostgreSQL 16]
Testing:    [e.g. Jest + ts-jest]
Validation: [e.g. zod]
[other decisions...]
```

## Environment variables
```
[VAR_NAME]    # description
[VAR_NAME]    # description, default: [value]
```

---

## When to ask before doing
- Changing the public interface of any `index.ts`
- Adding a new npm dependency
- Creating a new module not in ARCHITECTURE.md
- Any change touching more than 2 modules
```

---

## ARCHITECTURE.md Template

```markdown
# ARCHITECTURE.md — [Project Name]

## System diagram

```
[ASCII diagram showing main flow:
 entry point → orchestrator → modules → storage
 Keep it simple — boxes and arrows, no decoration]
```

---

## Modules

### `modules/[name]`
**Responsibility**: [One sentence. What it does and nothing else.]

**Public API** (`index.ts` exports):
```typescript
interface I[Name]... { ... }
class [Name]Service { ... }
```

**Owns**: [list of files it contains]
**Depends on**: [list of modules/shared it uses]
**Does NOT depend on**: [explicit list of what it must never import]

[Repeat for each module]

---

## Domain model

### [MainEntity] — the central type
```typescript
interface [MainEntity] {
  id: string          // [how it's generated, e.g. sha256(url)]
  [field]: [type]     // [comment explaining why]
  [field]: [type]
  metadata: Record<string, unknown>  // [why this escape hatch exists]
}
```

---

## Database schema

```sql
CREATE TABLE [table_name] (
  [column] [type] [constraints],
  ...
);
CREATE INDEX [idx_name] ON [table](column);
```

[One table per domain entity. Include indexes.]

---

## Dependency rules

```
[module-a]  → [module-b]    ✓ allowed
[module-a]  → shared/*      ✓ allowed
shared/*    → modules/*     ✗ FORBIDDEN
[module-a]  → [module-b].repository  ✗ FORBIDDEN (use index.ts)
```

---

## How to add a new [extensible-thing] (e.g. new source, new provider)

1. Create `modules/[location]/[name]/`
2. Implement `[Name]Class implements [IInterface]`
3. Register in `[entry-point-file]`
4. Add config in `config/env.ts`
5. **Zero changes** to [core orchestrator] or any other [thing]

---

## ADR (Architecture Decision Records)

### ADR-001: [Decision title]
**Decision**: [What was decided]
**Reason**: [Why — what problem does it solve]
**Trade-off**: [What you're giving up]
**Trigger to revisit**: [Specific condition that would change this decision]

[Minimum 3 ADRs covering: architecture style, main data pattern, key tech choice]
```

---

## Filling in the templates — quality checklist

Before handing L0 files to the developer, verify:

**CLAUDE.md**
- [ ] "Project in one sentence" is actually one sentence with input/process/output
- [ ] The 3 banned import patterns are specific to this project (not generic)
- [ ] Tech debt table has at least 3 rows (MVPs always have shortcuts)
- [ ] Every trigger condition is a real metric (not "when we need to", "later", etc.)
- [ ] Environment variables list is complete (missing one = broken deploy)

**ARCHITECTURE.md**
- [ ] ASCII diagram fits in 80 chars wide, shows actual flow
- [ ] Every module's "Does NOT depend on" list is filled
- [ ] Domain model has a comment explaining the `id` generation strategy
- [ ] "How to add new X" section requires zero changes to existing modules
- [ ] ADRs explain the WHY, not just the WHAT
- [ ] At least one ADR documents a shortcut taken (shows honest trade-off thinking)

---

## Error Taxonomy Template (add to CLAUDE.md)

```markdown
## Error design — defined at L0, never changed without ADR

### Domain errors (business violations — client caused this)
- ValidationError   → input doesn't meet business rules → HTTP 400
- NotFoundError     → resource doesn't exist → HTTP 404
- ConflictError     → duplicate / already exists → HTTP 409
- ForbiddenError    → authenticated but not authorized → HTTP 403

### Infrastructure errors (technical failures — our problem)
- DatabaseError     → DB unreachable / query failed → HTTP 503 + alert
- ExternalAPIError  → 3rd party call failed → HTTP 502 + circuit breaker

### Rules
- Service throws DomainError or InfrastructureError. Service has ZERO HTTP knowledge.
- Handler maps error class → HTTP status. Handler has ZERO business logic.
- Every InfrastructureError must be logged with full context before re-throwing.
```

## Idempotency Template (add to CLAUDE.md)

```markdown
## Idempotency decisions

For each operation that mutates state, answer before coding:

| Operation | If called twice | Solution |
|---|---|---|
| [POST /orders] | Creates duplicate order | Idempotency-Key header → INSERT ... ON CONFLICT DO NOTHING |
| [cron: crawl job] | Two jobs overlap | pg_try_advisory_lock(JOB_ID) at start |
| [save feed items] | Duplicate items | INSERT ... ON CONFLICT (id) DO NOTHING |

Rule: "it probably won't happen" is not an answer. Every mutation needs an answer.
```

## ADR Quality Gate

Before writing an ADR, verify it passes this gate:
- [ ] There were at least 2 real options considered (not just "we picked X")
- [ ] Each rejected option has a specific reason it was rejected
- [ ] The decision has a "trigger to revisit" that is a real condition
- [ ] The consequence section acknowledges what we're giving up

If any box is unchecked → this decision doesn't need an ADR. Document it inline in code instead.
