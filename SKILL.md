---
name: shipright
version: 0.5.9
description: >
  Ship your MVP fast. Grow it right.
  Use when: starting ANY new project or codebase, adding a non-trivial feature
  (touches 2+ files), debugging a bug with unclear root cause, refactoring a module,
  returning to a project after a break, or dealing with a production incident.
  Triggers on phrases like: "build", "start a new project", "add feature to my app",
  "there's a bug", "fix this issue", "refactor", "production is down", "I'm back on this",
  "help me structure", "I want to create", "integrate API", "add logging/tracing".
  Do NOT trigger for: single-line fixes, knowledge questions, mid-implementation steps,
  writing README, generating commit messages.
  Manual invoke: /shipright (most reliable — always works).
allowed-tools: Read, Write, Bash, Glob, Grep
---

## Working context (injected at runtime)

Shipright version: !`grep "^version:" "${CLAUDE_SKILL_DIR}/SKILL.md" 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown"`
Current directory: !`pwd`
Project files: !`ls -1 2>/dev/null | head -20`
Git status: !`git status --short 2>/dev/null || echo "not a git repo"`
CLAUDE.md: !`test -f CLAUDE.md && echo "YES — read before asking anything" || echo "NO"`
ARCHITECTURE.md: !`test -f ARCHITECTURE.md && echo "YES — read before asking anything" || echo "NO"`
addyosmani/agent-skills: !`test -d "${HOME}/.claude/skills/agent-skills" && grep "^version:" "${HOME}/.claude/skills/agent-skills/SKILL.md" 2>/dev/null | head -1 | awk '{print $2}' || echo "not installed"`
taste-skill: !`test -d "${HOME}/.claude/skills/taste-skill" && echo "installed" || echo "not installed"`

---

# Shipright

**Shipright is the conductor. External skills are the musicians.**
Shipright knows: which piece to play, what order, which musician plays what.
addyosmani/agent-skills knows: how to execute each part excellently.
taste-skill knows: how to make UI not look like slop.
These roles never overlap. Shipright does NOT duplicate their instructions.

---

## The one rule that never changes

**4 boundaries. Absolute. Non-negotiable. In MVP and in production.**

Based on Uncle Bob's Dependency Rule and Fowler's internal quality research:
these are the only things that are cheap to do right from day one
and expensive to fix later — even with AI coding fast.

```
1. Dependencies point inward only
   Service never imports db directly. Module never imports another module's internals.
   Cross-module calls go through index.ts / __init__.py only.

2. Each layer has one job
   Handler: parse → call service → format. No domain logic.
   Service: business rules only. No HTTP, no DB.
   Repository: DB queries only. Returns typed domain objects, not raw rows.

3. Modules do not share databases
   If module A needs data from module B → call B's public interface.
   Never query B's table directly. This is the seam for future service extraction.

4. No raw external response passes the Adapter layer  [applies when using third-party APIs]
   Every external API has exactly one Adapter (Normalizer).
   Raw response never enters service or domain logic directly.
   When provider changes schema → fix Adapter only, service untouched.
   See `references/third-party-apis.md` for full pattern.
```

Why these and nothing else as non-negotiable:
Fowler showed internal quality pays off in weeks, not months.
Uncle Bob showed the dependency rule is what makes systems testable and swappable.
With AI coding fast, these boundaries are even cheaper to maintain —
but the cost of violating them is unchanged: data model migrations still hurt,
tangled dependencies still make AI generate wrong code at scale.

Everything else — test coverage level, error taxonomy completeness, caching,
full ADR set, idempotency on every operation — is signal-driven. Do it when
the trigger condition is met, not upfront.

---

## FIRST — One question, then branch

Ask exactly this, wait for the answer, load ONE branch file:

```
What's the current state of your project?

  [A] Brand new — nothing exists yet
  [B] Existing code — add a feature
  [C] Existing code — fix a bug
  [D] Existing code — refactor
  [E] Existing code — re-orient / continue after a break
  [F] Production issue
```

| Answer | Load | Do NOT load others |
|---|---|---|
| A | `references/branches/a-new-project.md` | B–F |
| B | `references/branches/b-add-feature.md` | A,C–F |
| C | `references/branches/c-fix-bug.md` | A,B,D–F |
| D | `references/branches/d-refactor.md` | A–C,E,F |
| E | `references/branches/e-resume.md` | A–D,F |
| F | `references/branches/f-incident.md` | A–E |

---

## Is this workflow appropriate?

```
Throwaway prototype, < 1 week lifespan?    → skip everything, just hack
Script / CLI, < 200 lines, no domain?      → flat functions, no layers needed
Solo, < 3 domain entities, read-only?      → simple modules, no DI needed
Otherwise                                   → use shipright
```

Senior thinking is knowing when NOT to apply a pattern.

---

## The 2-mode decision (ask in Branch A)

```
"Building to VALIDATE an idea, or SCALE a proven solution?"

VALIDATE (MVP mode):
  Goal: working software in front of real users, fastest possible.
  Constitution: minimal — 4 boundary rules + core modules only + debt log.
  Process: walking skeleton first, validate, then feature loop.
  Timeline: days, not weeks.

SCALE (Production mode):
  Goal: architecture that supports team growth and load.
  Constitution: full — all modules, error taxonomy, idempotency, ADRs.
  Process: full L0 → L1 → L2 → L3.
  Timeline: planned sprints.
```

The irreversible decisions that need to be right in BOTH modes:
core domain model shape, module boundary map, dependency direction.
These are cheap to do right now. Expensive to fix with 10k users and live data.

---

## The 4-Level Tree (Branch A only — new projects)

```
L0  Constitution  → CLAUDE.md + ARCHITECTURE.md
L1  Skeleton      → compiles, runs, no logic
L2  Interfaces    → layers defined, tests written (RED)
L3  Implement     → one feature at a time, tests GREEN
L4  Harden        → only when production signal demands it
```

Which branch uses which levels:

| Branch | L0 | L1 | L2 | L3 | L4 |
|---|---|---|---|---|---|
| A — New project | ✓ Create | ✓ Create | ✓ Create | ✓ Loop | Signal |
| B — Add feature | ✓ Read/update | — | ✓ Feature only | ✓ | Signal |
| C — Fix bug | — | — | — | — | — |
| D — Refactor | ✓ Read | — | — | — | — |
| E — Resume | ✓ Read | Detect level | Resume at level | Continue | Signal |
| F — Incident | — | — | — | — | — |

Branch C and F: tree does NOT apply. Dedicated workflows in branch files.
Branch D: read L0 docs for intent, follow refactor workflow (characterization tests first).

---

## Ecosystem — install by stage, not all at once

Shipright orchestrates. External skills execute specific parts.
Do NOT install all 24 addyosmani skills upfront — context budget is finite.
Install only what your current pain requires. Addy Osmani himself: "pick 4–5 closest to your pain."

### Stage-based install guide

**MVP stage** (validate idea, team 1–3):
```
Install: debugging-and-error-recovery   ← bugs happen from day one
Skip everything else                    ← overhead > value at this stage
```

> **Complexity control:** Even when skills ARE installed, Branch B classifies
> each feature as Tier S/M/L/XL and activates only the right skills.
> Simple features (1 file) never trigger incremental-implementation or spec-driven.
> addyosmani documented "When NOT to use" for every skill — shipright enforces it.

**Traction stage** (feature loop active, team 3–8):
```
Add: incremental-implementation         ← features now span multiple files
Add: test-driven-development            ← prevent regression as features grow
Add: code-review-and-quality            ← team consistency matters now
```

**Growth stage** (proven product, pre-enterprise):
```
Add: spec-driven-development            ← complex features need specs
Add: security-and-hardening            ← real users with real data
Add: observability-and-instrumentation ← need visibility before incidents
```

### Skills to skip (shipright already covers or taste-skill does better)

- `interview-me` → shipright Branch A onboarding does this
- `idea-refine` → shipright Q2/Q3 in Branch A does this
- `frontend-ui-engineering` → use taste-skill instead (more focused)
- `using-agent-skills` → only needed if you have 10+ skills installed
- `performance-optimization` → L4 signal-driven, never install proactively

### addyosmani/agent-skills
Install: `git clone https://github.com/addyosmani/agent-skills ~/.claude/skills/agent-skills`
Then load only the skills you need — see stage guide above.

### taste-skill (30k★ — anti-slop frontend)
Install: `git clone https://github.com/Leonxlnx/taste-skill ~/.claude/skills/taste-skill`
Read `references/ui-design.md` for page type → correct skill mapping.
Skip entirely for: backend API, CLI, background jobs, dashboards.

---

## Language rule

**Respond in the user's language throughout the session.**
These skill files are written in English for GitHub discoverability,
but if the user writes in Vietnamese, French, or any other language,
conduct the entire conversation in that language.
CLAUDE.md and ARCHITECTURE.md content stays in English (project convention).

## Working directory rule

ALL file operations happen in the current directory shown in the context above.
If CLAUDE.md or ARCHITECTURE.md exist → read them BEFORE asking any questions.
If developer mentions a path → confirm: "You mean `[path]` relative to `[pwd]`?"

---

## L4 — Production hardening signals

L4 is NOT "make it better." Only when production gives a measurable signal.

**Performance:** p95 latency > target, DB CPU > 60%, API quota exhausted, memory growth over time
**Reliability:** external API flaky > 1 week → circuit breaker; cron jobs overlapping → distributed lock; error rate > 1%
**Observability signals (load `references/observability.md`):**
- "We don't know where it's slow" → add OpenTelemetry distributed tracing
- "We find out about errors from users" → add Sentry + structured error logging
- "Can't reproduce prod issues locally" → Correlation ID missing
- "Third-party API changed silently" → schema validation logs not in place

L4 constraint: fix stays inside one layer. Interface change needed → design problem, not optimization.

---

## When project grows and architecture needs to evolve

When project is growing and team is expanding, read `references/scaling-guide.md`:
- Stage 1 (team < 20): enforce boundaries harder, module ownership, architecture tests
- Stage 2 (team 10–30): modular monolith patterns, async events, module-level CI
- Stage 3 (team 20–50): selective extraction via Strangler Fig — only when 3 signals appear

Signal to check: if any graduate checklist item fires → read scaling-guide.md immediately.

---

## When requirements change architecture

Read `references/requirement-drift.md` when:
- New requirement doesn't fit current module structure
- Developer wants to add a completely new bounded context
- Core domain type needs to change

3 scenarios: new implementation of existing interface (add, zero changes elsewhere),
wrong abstraction revealed (refactor to new pattern under green tests),
foundational type change (Expand-Contract: optional → migrate → required, 3 commits).

---

## Common mistakes — redirect these

| Wants to do | Why wrong | Redirect |
|---|---|---|
| Microservices from day 1 | Operational overhead before value proven | Modular monolith, split when team/load demands |
| Build all features before shipping | Invalidated direction costs everything | Walking skeleton → validate → feature loop |
| Skip the 4 boundaries "just for MVP" | Cheap now, rewrite later | 4 boundaries take minutes, save weeks |
| "Optimize it later" (vague) | "Later" = never | Add TODO[metric-trigger] with specific condition |
| Refactor everything before new feature | Refactor without tests = rewrite | Characterization tests first, then refactor |
| Module A queries module B's DB directly | Breaks the seam, impossible to split | Define interface in B's public boundary |

---

## Reference files — load on demand only

### Always load
- `references/onboarding.md` — thin router with branch table

### Load after user selects branch
- `references/branches/a-new-project.md` — MVP vs production, walking skeleton, L0 generation
- `references/branches/b-add-feature.md` — codebase read, health check, feature implementation
- `references/branches/c-fix-bug.md` — classify, reproduce, locate, root cause, fix
- `references/branches/d-refactor.md` — define done, characterization tests, atomic steps
- `references/branches/e-resume.md` — git orient, detect level, find position, next action
- `references/branches/f-incident.md` — triage, mitigate first, investigate, post-incident

### Load when needed
- `references/boundaries.md` — 4 boundary rules with good/bad code examples
- `references/levels.md` — L0→L4 definitions, gates, Conway's Law signals, graduate checklist
- `references/l0-templates.md` — CLAUDE.md + ARCHITECTURE.md templates (MVP and production)
- `references/requirement-drift.md` — architecture change: 3 scenarios + Expand-Contract
- `references/debug-intermittent.md` — intermittent / production-only / resource-leak bugs
- `references/third-party-apis.md` — 3-layer testing, Adapter pattern, fixture workflow, resilience
- `references/observability.md` — Correlation ID, structured logging, API tracing, retrofit guide
- `references/scaling-guide.md` — 3-stage scaling playbook + Strangler Fig extraction templates
- `references/ui-design.md` — taste-skill page type → correct skill → dials → anti-slop rules
- `references/stacks/nodejs.md` — Node.js/TypeScript concrete prompts
- `references/stacks/python.md` — Python/FastAPI concrete prompts
- `references/stacks/browser-extension.md` — Browser Extension MV3: manifest, components, chrome.* APIs, MV3 gotchas
- `references/stacks/ai-projects.md` — AI projects entry point: project type routing, 5th boundary rule, eval-first mindset
- `references/stacks/ai-rag.md` — RAG deep dive: framework decision, evaluation loop, vector DB, chunking, metrics
- `references/stacks/chatbot-platforms.md` — AI Chatbot for Telegram/Discord: Platform Adapter pattern, conversation state, polling vs webhook, security

### Load when user asks "show me an example"
- `references/examples/news-crawler-CLAUDE.md`
- `references/examples/news-crawler-ARCHITECTURE.md`
