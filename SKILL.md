---
name: shipright
version: 0.7.3
description: >
  Ship your MVP fast. Grow it right. The Project Brain for AI coding workflow —
  sets up constitution, enforces boundaries, orchestrates community skills.
  Use when: starting ANY project, adding features (2+ files), fixing unclear bugs,
  refactoring, resuming after break, production incidents, integrating APIs,
  adding observability/tracing, building AI/RAG/chatbot projects.
  Triggers: "build", "start project", "add feature", "bug", "refactor",
  "production down", "back on this", "integrate API", "add tracing", "build chatbot".
  Skip for: single-line fixes, knowledge questions, mid-implementation steps.
  Manual invoke: /shipright — always reliable.
allowed-tools: Read, Write, Bash, Glob, Grep
---

## Working context — injected every session

```
Shipright:     !`grep "^version:" "${CLAUDE_SKILL_DIR}/SKILL.md" 2>/dev/null | awk '{print $2}'`
Directory:     !`pwd`
Git branch:    !`git branch --show-current 2>/dev/null || echo "no git"`
Last commit:   !`git log --oneline -1 2>/dev/null || echo "no commits"`
CLAUDE.md:     !`test -f CLAUDE.md && echo "EXISTS — read first" || echo "MISSING"`
ARCHITECTURE:  !`test -f ARCHITECTURE.md && echo "EXISTS — read first" || echo "MISSING"`
Project state: !`grep -A3 "## Shipright state" CLAUDE.md 2>/dev/null | tail -3 || echo "no state tracked"`
Skills:        !`ls ~/.claude/skills/ 2>/dev/null | tr '\n' ' ' || echo "none detected"`
Tests:         !`(npm test --silent 2>&1 | tail -2) || (pytest -q 2>&1 | tail -2) || echo "no test runner"`
```

---

# Shipright v0.7 — Project Brain OS

Three masters. Four boundaries. One living constitution.

**Eric Evans:** Model the right domain (Ubiquitous Language, Bounded Contexts, Aggregates)
**Uncle Bob:** Structure it correctly (SOLID, Clean Code, 20-line functions)
**Fowler:** Keep it clean as it evolves (smell detection, compound engineering)

---

## The 4 boundaries — absolute, all modes, all stages

```
1. Dependencies point inward only
   Service never imports db. Module never imports another module's internals.
   Cross-module: index.ts / __init__.py only.

2. Each layer has one job
   Handler: parse → call service → format. Zero domain logic.
   Service: business rules only. No HTTP, no DB.
   Repository: queries only. Returns typed domain objects, not raw rows.

3. Modules do not share databases
   Module A needs B's data → call B's public interface. Never B's table.

4. No raw external response passes the Adapter layer
   Every external API/LLM has one Adapter (Normalizer/ACL).
   Raw response never enters service or domain logic.
```

Cheap to do right from day one. Expensive to fix at 10k users. Non-negotiable in MVP.

---

## Session start — 3 checks before anything else

**Check 1: Read existing constitution**
If CLAUDE.md and ARCHITECTURE.md exist → read both completely before asking anything.
Project state section in CLAUDE.md shows where things left off last session.

**Check 2: Assess skill availability**
Skills detected in working context above → adapt behavior:
- addyosmani/agent-skills: delegate spec/implementation/review/debug tasks
- taste-skill: delegate UI tasks with correct variant
- Other skills: check registry entry for this project type

**Check 3: Note missing skills**
If registry entry requires a skill not installed → mention once at session start:
"Note: this project type works better with [skill]. Install: [command]"
Then proceed — never block on missing skills.

---

## Route first, everything else second

```
What's the current state of your project?

  [A] New — nothing exists yet
  [B] Existing code — add a feature
  [C] Existing code — fix a bug
  [D] Existing code — refactor or improve
  [E] Existing code — re-orient / continue after a break
  [F] Production issue — slow, crashing, data problem
```

Load ONE file. Do not load others until needed.

| Answer | Load | Tokens |
|---|---|---|
| A | `references/branches/a-new-project.md` | ~900 |
| B | `references/branches/b-add-feature.md` | ~900 |
| C | `references/branches/c-fix-bug.md` | ~600 |
| D | `references/branches/d-refactor.md` | ~900 |
| E | `references/branches/e-resume.md` | ~500 |
| F | `references/branches/f-incident.md` | ~500 |

---

## Registry — project type → curated skills

After routing, if project type is identifiable, load:
`references/registry.md` — find the project type entry (~300 tokens per entry)

Registry tells: what to install, what shipright adds to CLAUDE.md, tested-with versions.
Load only the relevant entry, not the full file.

---

## Quality system — 3 dimensions enforced throughout

### At L0 (constitution)
- Evans: Ubiquitous Language in CLAUDE.md (domain terms Claude must use)
- Evans: Domain types in ARCHITECTURE.md (Entity vs Value Object vs Service)
- Uncle Bob: Clean Code rules in CLAUDE.md (function max 20 lines, no AND/OR names)

### At L3 (before every commit)
Load `references/code-quality.md` for full gate. Quick version:
```
DDD:     Names from Ubiquitous Language? Value Objects immutable?
SOLID:   Function > 20 lines? AND/OR in name? New type modified existing switch?
Fowler:  Feature Envy? Primitive Obsession? Comment explaining WHAT?
```
Violation found → fix before committing + add rule to CLAUDE.md (compound engineering)

### Compound engineering (ongoing)
Every AI mistake → specific rule added to CLAUDE.md or `.claude/rules/[module].md`
CLAUDE.md gets smarter every session. AI makes the same mistake twice: rare.

---

## Persistent state — tracking across sessions

Shipright writes a state section to CLAUDE.md after significant milestones.
This survives across sessions. Working context above reads it automatically.

```markdown
## Shipright state
Level: L3
Active: [module name]
Next: [specific action — verb + object + acceptance criteria]
Last updated: [date]
Skills active: [comma-separated list]
```

When state exists: skip intake, start from "Next" action.
When state missing: full intake flow.
Branch E (resume) uses this to re-orient in seconds instead of minutes.

---

## L4 hardening — signal-driven only

Never add L4 work proactively. Only when production gives a measurable signal.

| Signal | Action | Load |
|---|---|---|
| "Don't know where it's slow" | OpenTelemetry tracing | `references/observability.md` |
| "Users report errors before us" | Sentry + structured logging | `references/observability.md` |
| "API changed silently" | Schema validation + contract tests | `references/third-party-apis.md` |
| "Can't reproduce prod issues" | Correlation ID missing | `references/observability.md` |
| Team > 10, merge conflicts rising | Module ownership + arch tests | `references/scaling-guide.md` |
| Adding features getting slower | Fowler smells accumulated | `references/code-quality.md` |

---

## Ecosystem dispatch — who does what

Shipright decides when and what. External skills execute how.

```
Shipright owns:
  Constitution (CLAUDE.md + ARCHITECTURE.md)
  4 boundary rules + quality gate
  Project state + routing
  Registry-based skill suggestions
  Irreversible architecture decisions

addyosmani/agent-skills owns (install by stage):
  MVP:      debugging-and-error-recovery
  Traction: + incremental-implementation, test-driven-development, code-review-and-quality
  Growth:   + spec-driven-development, security-and-hardening

taste-skill owns (install by page type):
  Landing/portfolio: design-taste-frontend
  Product UI:        minimalist-skill
  Premium/calm:      soft-skill
  Redesign:          redesign-skill FIRST, then above
  Dashboard/admin:   NOT taste-skill → vercel-labs/agent-skills

AI ecosystem owns (install by project type):
  RAG evaluation:    RAGAS + LangSmith / Arize Phoenix
  LLM observability: datadog-labs/dd-llmo-eval-bootstrap
  Agent evaluation:  DeepEval / Confident-AI

SKIP (shipright already covers):
  interview-me, idea-refine → Branch A intake
  frontend-ui-engineering  → taste-skill
  performance-optimization → L4 signal-driven
```

**For AI/RAG/chatbot projects:**
addyosmani covers infrastructure code (adapters, handlers, CI/CD, code review).
Shipright AI files cover AI-specific code (evaluation loop, LLM boundaries, conversation state).
Use both — they don't overlap.

---

## When workflow is not appropriate

```
Throwaway prototype, < 1 week lifespan?    → skip everything, hack freely
Script / CLI, < 200 lines, no domain?      → flat functions, no layers
Solo, < 3 domain entities, read-only data? → simple modules, no DI
Otherwise                                   → use shipright
```

Senior judgment = knowing when NOT to apply a pattern.

---

## Reference files — load on demand

### Branch files (load ONE per session start)
- `references/branches/a-new-project.md`
- `references/branches/b-add-feature.md`
- `references/branches/c-fix-bug.md`
- `references/branches/d-refactor.md`
- `references/branches/e-resume.md`
- `references/branches/f-incident.md`

### Registry (load relevant entry only)
- `references/registry.md` — project type → curated skill pack

### Core references (load on signal)
- `references/code-quality.md`
- `references/code-health.md` — SOLID tactical enforcement per level — Evans + Uncle Bob + Fowler: full quality system
- `references/observability.md` — Correlation ID, logging, tracing, API tracing, retrofit
- `references/scaling-guide.md` — Stage 1→2→3 playbook + Strangler Fig templates
- `references/third-party-apis.md` — Adapter pattern, 3-layer testing, resilience
- `references/ui-design.md` — taste-skill: page type → correct skill → dials
- `references/l0-templates.md` — CLAUDE.md + ARCHITECTURE.md templates
- `references/levels.md` — L0→L4 gates, Conway's Law, graduate checklist
- `references/requirement-drift.md` — Expand-Contract + 3 architecture change scenarios
- `references/debug-intermittent.md` — intermittent / production-only / resource-leak bugs
- `references/boundaries.md` — 4 boundary rules with code examples
- `references/prompts.md` — copy-paste Claude Code prompts

### Stack files (load on project type — slim, defer to community skills)
- `references/stacks/nodejs.md`
- `references/stacks/python.md`
- `references/stacks/browser-extension.md`
- `references/stacks/ai-projects.md`
- `references/stacks/ai-rag.md`
- `references/stacks/chatbot-platforms.md`
- `references/stacks/blockchain.md` — EVM/Solana/TON/SUI/TRON: smart contract security, chain-specific patterns, audit gate

### Examples
- `references/examples/news-crawler-CLAUDE.md`
- `references/examples/news-crawler-ARCHITECTURE.md`

---

## Language rule
Respond in the user's language. These files are English for GitHub discoverability.
CLAUDE.md and ARCHITECTURE.md content stays in English (project convention).
