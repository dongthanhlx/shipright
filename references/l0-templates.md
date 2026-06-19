# L0 Templates — CLAUDE.md and ARCHITECTURE.md

Two versions: MVP (minimal) and Production (full).
Use MVP for validate mode. Use Production for scale mode.
The 3 boundary rules appear in BOTH — they are never optional.

---

## CLAUDE.md — MVP version

```markdown
# CLAUDE.md — [project-name] (MVP)

## Project
[One sentence: Input → Process → Output]

## The 3 boundaries — always enforced, even in MVP

1. Dependencies point inward only
   [ModuleA] never imports [ModuleB]'s internals.
   Cross-module calls go through index.ts / __init__.py only.
   Example banned: `import { X } from '../other-module/other.service'`
   Example correct: `import { X } from '../other-module'`

2. Each layer has one job
   Handler: parse → call service → format. No domain if/else.
   Service: business logic only. No db imports, no HTTP imports.
   Repository: queries only. Returns typed domain object, not raw row.

3. Modules do not share databases
   If module A needs data from B → call B's public interface.
   `import { db } from '../../shared/db'` is BANNED in service files.

## Stack
[Runtime, database, test runner, key libs]

## Environment variables
[VAR_NAME] # description

## Tech debt log (MVP shortcuts — with triggers)
| Shortcut | Trigger to fix |
|---|---|
| [shortcut] | TODO[[metric]]: [what to do] |

## When to ask before doing
- Changing any module's public interface (index.ts exports)
- Adding a new npm/pip dependency
- Creating a module not in ARCHITECTURE.md
```

---

## CLAUDE.md — Production version

Same as MVP, plus:

```markdown
## Error taxonomy

Domain errors (client caused → 4xx):
- ValidationError → 400
- NotFoundError → 404
- ConflictError → 409
- ForbiddenError → 403

Infrastructure errors (our problem → 5xx):
- DatabaseError → 503 + alert
- ExternalAPIError → 502 + circuit breaker

Rule: Service throws these. Service has ZERO HTTP knowledge.
      Handler maps error class → status. Handler has ZERO business logic.

## Idempotency decisions
| Operation | If called twice | Solution |
|---|---|---|
| [mutation] | [what breaks] | [approach] |

## Pre-commit checklist
grep -r "shared/db" src/modules/    # must be empty
grep -r "\.service" src/modules/*/index  # must be empty
[build check command]               # must pass
```

---

## ARCHITECTURE.md — MVP version

```markdown
# ARCHITECTURE.md — [project-name] (MVP)

## Core flow

[ASCII diagram — only what exists in MVP]
Entry → [Module A] → [Module B] → Storage

## Modules (MVP only — add more when needed)

### [module-name]
Job: [one sentence — what it does and nothing else]
Public interface: [what it exports — types and functions/classes]
Depends on: [what it needs]
Must NOT depend on: [explicit list]

## Core domain type

[The central type flowing through the system]
[Include comments explaining WHY each field exists, especially id generation]

## Database (MVP)

[Minimal schema — only tables needed for skeleton]
[Include the indexes you know you'll need]

## ADR (1 entry minimum — the hardest decision)

### ADR-001: [The decision you almost got wrong]
Decision: [what]
Options rejected: [what and why]
Consequence: [what you're accepting]
Trigger to revisit: [specific condition]
```

---

## ARCHITECTURE.md — Production version

Same as MVP, plus:

```markdown
## All modules (full map)
[All bounded contexts with full dependency rules]

## Dependency rules
[Explicit: what CAN import what, what is FORBIDDEN]

## How to add a new [extensible thing]
[Proves extensibility: adding X = N steps, zero changes to existing code]

## ADR (minimum 3 — for non-obvious decisions only)
[Each with: Context, Options considered, Decision, Consequences, Trigger to revisit]
[Only write ADR if there were real alternatives considered]
```

---

## ADR quality gate (before writing any ADR)

- [ ] Were at least 2 real options considered?
- [ ] Is each rejected option explained with a specific reason?
- [ ] Does the "trigger to revisit" name a real condition?
- [ ] Does the consequence section acknowledge what's being given up?

If any unchecked → this decision doesn't need an ADR. Document inline in code.
