# L0 Templates — CLAUDE.md and ARCHITECTURE.md

Two versions: MVP (minimal) and Production (full).
Use MVP for validate mode. Use Production for scale mode.
The boundary rules appear in BOTH — they are never optional.

> **CLAUDE.md is a lean, distilled contract — not a spec dump.** It is loaded into context at the
> start of EVERY session, so how it's written decides how reliably Claude follows it (Anthropic's
> guidance). shipright's rules:
> - **Keep the root under 200 lines** — MVP ~50–60. "Longer files reduce adherence." Load-bearing
>   rules (boundaries, Ubiquitous Language) must not be diluted by conditional deep sections.
> - **Distill, don't fill** — the content comes from the discovery conversation (the job, the
>   one-way doors, the real risk), not from mechanically filling `[placeholders]`.
> - **`@import` for deep/optional conventions** — put observability / rate-limit / AI conventions
>   in their own files and `@import` them only when the feature exists. Don't inline them into MVP.
> - **CLAUDE.md = durable rules you write; auto memory = incidental learnings Claude writes itself**
>   (`~/.claude/projects/<project>/memory/`). Don't cram every learning into CLAUDE.md — keep it the
>   constitution; let auto memory hold build commands, debugging insights, discovered preferences.
> - **CLAUDE.md guides; a PreToolUse hook enforces** — the boundaries here are context, not a hard
>   gate. `hooks/boundary-guard.sh` (references/enforcement.md) is the enforcement layer.
> - **AGENTS.md interop**: if the repo already has an AGENTS.md (Cursor/Codex/other agents), make
>   CLAUDE.md `@AGENTS.md` at the top and add Claude-specific rules below — one source, both tools.

---

## CLAUDE.md — MVP version

```markdown
# CLAUDE.md — [project-name] (MVP)

## Project
[One sentence: Input → Process → Output]

## Ubiquitous Language — shared vocabulary for this codebase
All class names, method names, and variable names MUST use these terms.
Claude uses ONLY these terms — never invents generic alternatives.

| Term | Meaning in this context | NOT |
|---|---|---|
| [domain term] | [precise definition] | [generic alias to avoid] |

Signal that language is wrong: class named Manager, Helper, Processor, Utils.
When that happens: stop, define the right domain term, rename.

## The boundaries — always enforced, even in MVP

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

4. No raw external response passes the Adapter layer  [if project uses external APIs]
   Every third-party API has one Adapter (Normalizer).
   Raw API response NEVER enters service or domain logic.
   Service never knows which provider was called.

5. Every integration point has a timeout + a deliberate fallback  [if external calls exist]
   No outbound call (HTTP/DB/queue/RPC) waits forever.
   Side effects are idempotent (key in DB/Redis, never in-memory).
   Full resilience patterns deferred to HARDEN — see references/resilience.md.

## Stack
[Runtime, database, test runner, key libs]

## Environment variables
[VAR_NAME] # description

## Conventions  [import only what applies — keep the root lean]
# Deep conventions live in their own files and are pulled in with @import ONLY when the feature
# exists. This keeps the always-loaded root small (adherence) and MVP-honest (defer until needed).
@.claude/conventions/observability.md   # if async flows / external calls — Correlation ID + log rules
@.claude/conventions/external-apis.md    # if third-party APIs — rate-limit policy + fixtures + adapter
@.claude/conventions/ai.md               # if LLMs — LLM boundary, prompts-as-files, eval, cost
# (generate each file from references/observability.md / third-party-apis.md / stacks/ai-projects.md.
#  Omit the import entirely if the feature isn't in scope — don't inline these into the MVP root.)

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

> ADR = Architecture Decision Record, Michael Nygard's format (2011) — already a shipright master
> (resilience). An ADR captures the WHY of a one-way-door decision so a future session (or Branch E
> resume) understands the reasoning, not just the outcome. Format below is Nygard's, trimmed.

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

---

## Shipright state section — add at END of CLAUDE.md

```markdown
## Shipright state
Level: L0
Active: constitution created
Next: create L1 skeleton — [describe specific skeleton target]
Last updated: [date]
Skills active: [comma-separated list of installed skills]
Registry: [project type from registry.md]
```

This section is read by shipright at every session start.
Update after every significant milestone (L0 complete, L1 done, L2 done, feature shipped).
Do NOT update after every single commit — only milestones.

Shipright reads this via working context injection:
`!grep -A6 "## Shipright state" CLAUDE.md`
