---
name: shipright
version: 1.17.0
description: >
  Ship your MVP fast. Grow it right. The Project Brain OS for AI coding workflow —
  sets up constitution, enforces boundaries, judges what to build now vs defer,
  hardens for fault tolerance, and orchestrates community skills at the right moment.
  Use when: starting ANY project, adding features (2+ files), fixing unclear bugs,
  refactoring, resuming after break, production incidents, integrating APIs,
  adding observability/tracing/resilience, scaling, building AI/RAG/chatbot projects.
  Triggers: "build", "start project", "add feature", "bug", "refactor",
  "production down", "back on this", "integrate API", "add tracing", "make it resilient",
  "scale this", "build chatbot".
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
# Granular skill detection (checks both personal + project-scoped)
skill/spec-driven: !`test -f ~/.claude/skills/agent-skills/skills/spec-driven-development/SKILL.md || test -f .claude/skills/agent-skills/skills/spec-driven-development/SKILL.md && echo YES || echo NO`
skill/incremental: !`test -f ~/.claude/skills/agent-skills/skills/incremental-implementation/SKILL.md || test -f .claude/skills/agent-skills/skills/incremental-implementation/SKILL.md && echo YES || echo NO`
skill/tdd:         !`test -f ~/.claude/skills/agent-skills/skills/test-driven-development/SKILL.md || test -f .claude/skills/agent-skills/skills/test-driven-development/SKILL.md && echo YES || echo NO`
skill/review:      !`test -f ~/.claude/skills/agent-skills/skills/code-review-and-quality/SKILL.md || test -f .claude/skills/agent-skills/skills/code-review-and-quality/SKILL.md && echo YES || echo NO`
skill/debug:       !`test -f ~/.claude/skills/agent-skills/skills/debugging-and-error-recovery/SKILL.md || test -f .claude/skills/agent-skills/skills/debugging-and-error-recovery/SKILL.md && echo YES || echo NO`
skill/security:    !`test -f ~/.claude/skills/agent-skills/skills/security-and-hardening/SKILL.md || test -f .claude/skills/agent-skills/skills/security-and-hardening/SKILL.md && echo YES || echo NO`
skill/taste:       !`test -f ~/.claude/skills/taste-skill/SKILL.md || test -f .claude/skills/taste-skill/SKILL.md && echo YES || echo NO`
Tests:         !`if [ -f package.json ] && grep -q '"test":' package.json; then echo "npm test"; elif [ -f pytest.ini ] || [ -f pyproject.toml ] || [ -d tests ]; then echo "pytest"; else echo "none detected"; fi`
```

---

# Shipright v1.17 — Project Brain OS

An executive layer over two hemispheres. The executive decides how much of each hemisphere to
apply, by stage × risk × reversibility (construction is ON from day one — the irreversible quadrant;
operation turns on by signal). The roster grows — the reference files are the source of truth, not a count.

```
EXECUTIVE  — Bezos (one-way/two-way doors) + the discipline of stopping   → references/judgment.md
CONSTRUCTION (day one) — Evans · Uncle Bob · Ousterhout · Fowler · Kent Beck
             → code-quality.md · code-health.md · testing.md
OPERATION (on signal)  — Nygard (resilience.md) · SRE/Majors (observability.md)
```

---

## The 5 boundaries — absolute, all modes, all stages

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

5. Every integration point has a timeout + a deliberate fallback   (failure isolation)
   No outbound call (HTTP/DB/queue/RPC) waits forever. One slow dependency must not
   stall the system. Enforced from the HARDEN phase. See references/resilience.md.
```

Boundaries 1–4: cheap to do right from day one, expensive to fix at 10k users — non-negotiable in MVP.
Boundary 5: timeouts + idempotency from day one; full resilience patterns on signal (not at SEED).

Optional **enforcement**: `hooks/boundary-guard.sh` is a PreToolUse hook that BLOCKS the two
highest-confidence violations (service→db import, deep cross-module import) before they're written —
boundaries that block, not just advise. Opt-in, fails open. See `references/enforcement.md`.

---

## The executive question — ask before every non-trivial decision

```
Before you BUILD it:  "Is this a one-way door, and is the need real today?"
  One-way + real      → do it right, now (domain model, boundaries, data identity, money units)
  One-way + not yet   → design the seam so it stays reversible, defer the rest
  Two-way + real      → simplest thing that works, move on (cache, log format, retry count)
  Two-way + not yet   → don't build it. Write a debt signal and ship.

Before you keep POLISHING it:  "Is this good enough for the appetite — or am I gold-plating?"
  Job done + core works → SHIP, get feedback. Cut SCOPE to nice-to-have; never cut the quality FLOOR
  (boundaries, one-way doors, the quality gate). Ship a smaller COMPLETE thing, not a bigger broken one.
```

This defeats both failure modes: over-engineering (treating a two-way door as one-way, or polishing
past "good enough") and architecture rot (treating a one-way door as two-way, or cutting the quality
floor to ship). Full matrix + the discipline of stopping + "when to break each rule":
`references/judgment.md`. Load it at L0 and at every "should I add X?" / "am I done?" moment.

---

## Lifecycle spine — SEED → VALIDATE → HARDEN → SCALE

One model; the older vocabularies (L0–L4, Stage 1–3, MVP/Production, Traction/Growth/Scale) map onto
it. Construction ramps up early (irreversible quadrant); operation turns on by signal. Full phase
table + which masters/dial per phase: `references/levels.md` + `references/judgment.md`.

---

## Session start — 3 checks before anything else

**Check 1: Read existing constitution**
If CLAUDE.md and ARCHITECTURE.md exist → read both completely before asking anything.
Project state section in CLAUDE.md shows where things left off last session.

**Check 2: Read granular skill detection above, then adapt precisely**

| skill (detected above) | if YES → activate | if NO → shipright's built-in fallback |
|---|---|---|
| spec-driven | Tier L/XL, before implementation | write acceptance criteria as markdown |
| incremental | Tier M+ multi-file features | outside-in drive, vertical slice (levels.md L3) |
| tdd | any feature with logic | RED test manually first |
| review | before merge on Tier M+ | manual quality gate (code-quality.md) |
| debug | all bugs (Branch C) | Branch C 5-step flow |
| security | auth/payments/untrusted input appears | manual OWASP (security.md; not enough for contracts) |
| taste | UI/UX pages, flows, forms | apply ui-design.md UI/UX principles — Norman/Nielsen/Refactoring UI/WCAG + the state-floor (real judgment, not hand-waving). Charts → dataviz skill |

When a skill = NO: say "X not installed — using shipright's built-in guidance instead." Never pretend
it's available; never skip the step.

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

## How shipright asks — all branches

Intake in every branch is a conversation, not a form. shipright carries the technical judgment
and talks like a veteran, not a questionnaire. (Full intent-discovery flow: Branch A. Model branch: E.)

```
1. Read/infer BEFORE you ask — anything derivable from CLAUDE.md, the codebase, git, or the user's
   own words, DETERMINE it. Don't ask for what you can read.
2. Ask only what ONLY the user knows — the real pain, business intent, bug repro steps, priorities,
   constraints. NEVER make the user do a technical classification that is shipright's job
   (which code smell, which module, new-vs-extend, bug class, stack).
3. Diagnose, then CONFIRM — don't menu-quiz. State the diagnosis with its evidence
   ("I read X, Y, Z → this is Feature Envy") and invite correction. (Branch A's playback, generalized.)
4. Open questions over menus — except where speed matters (Branch F incident triage) or the option
   set is genuinely the user's stable choice.
5. Calibrate depth to stakes (references/judgment.md): trivial → 1–2 questions; high-stakes → dig.
```

---

## Registry — project type → curated skills

After routing, if project type is identifiable, load:
`references/registry.md` — find the project type entry (~300 tokens per entry)

Registry tells: what to install, what shipright adds to CLAUDE.md, tested-with versions.
Load only the relevant entry, not the full file.

---

## Quality system — construction hemisphere

Enforced across the lifecycle; the detail lives in the refs (load on demand):
- **L0** — Ubiquitous Language + domain types in CLAUDE.md/ARCHITECTURE.md (Evans); Clean Code rules;
  test runner set up now. → `references/code-quality.md`, `references/l0-templates.md`.
- **L1–L3** — **test-first is the default for logic** (goal = confidence + design, not ritual or a
  coverage number; narrow honest exceptions; never for money). Pyramid, test-through-the-public-
  interface, mock only at the seams: `references/testing.md`. Build order (drive outside-in · slice
  vertical · implement domain-first): `references/levels.md` L3.
- **Before every commit — the quality gate**: tests? names from Ubiquitous Language? function > 20
  lines? Feature Envy / Primitive Obsession? Full gate: `references/code-quality.md` + `code-health.md`.

**Compound engineering**: a repeated mistake → a rule that prevents it. Durable architectural rule →
CLAUDE.md / `.claude/rules/`; incidental learning (build cmd, debug insight) → Claude Code's native
auto memory. Keep CLAUDE.md the lean constitution, not a dumping ground.

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
| "One dependency takes the system down" | Timeout + circuit breaker + bulkhead | `references/resilience.md` |
| "Retries storm a struggling dependency" | Backoff+jitter + retry budget | `references/resilience.md` |
| "Duplicate charges / double-processing" | Idempotency key (DB/Redis, structural) | `references/resilience.md` |
| "p95 latency / DB CPU over target" | Profile → fix query/N+1 → cache → replica | `references/performance.md` |
| "Need SLOs / error budget" | Golden signals + SLO + alerting | `references/observability.md` |
| "API changed silently" | Schema validation + contract tests | `references/third-party-apis.md` |
| "Can't reproduce prod issues" | Correlation ID missing | `references/observability.md` |
| Team > 10, merge conflicts rising | Module ownership + arch tests | `references/scaling-guide.md` |
| Adding features getting slower | Fowler smells accumulated | `references/code-quality.md` |

---

## Mid-work signals — load the moment you realize it, not just at routing

Routing (intake) and the L4 table (operation) cover session-start and production. But some needs
surface *mid-construction* — a **realization**, not a route. These have no other firing path, so catch
them here: when the thought below crosses your mind while building, load the ref immediately.

| You realize, while building… | Load |
|---|---|
| "A settled decision / the domain model is wrong — it must change" | `references/evolutionary-architecture.md` (evolve under guard, recovery path) |
| "The requirements changed under us mid-build" | `references/requirement-drift.md` (expand → migrate → contract) |
| "We're exposing tools/data to an AI host (MCP server/client)" | `references/stacks/mcp.md` (lethal-trifecta boundary) |
| "This module got too big for one person to hold in their head" | `references/team-scale.md` (cognitive load → split) |
| "I keep threading the same 3 fields / a string stands in for a domain concept" | `references/code-quality.md` (smells → extract) |

---

## Ecosystem dispatch — shipright is the conductor

Shipright owns WHEN/WHAT (constitution · 5 boundaries + quality gate + executive layer · lifecycle ·
routing · irreversible decisions). Community skills own HOW. Two hard rules:
1. Never self-execute work a dedicated skill already covers.
2. Never load a skill you'd duplicate, or a heavy skill a small project doesn't need yet — every
   loaded skill spends context budget and dilutes reasoning (few-skills-when-small = correctness).

**Dispatch by TRIGGER, not stage label** (a payment MVP needs security day one; a read-only app may
never). The full capability/signal → skill table (addyosmani, taste-skill, AI-eval) is the **trigger
index in `references/registry.md`** — load it after routing. Default ladder if no trigger fires:
SEED=debug · VALIDATE=+tdd/incremental/review · HARDEN=+spec/security/observability · SCALE=+specialized.

**SKIP (shipright already covers):** interview-me / idea-refine → Branch A intent discovery (dispatch
only when the idea is genuinely vague + installed); frontend-ui-engineering → taste-skill; performance-
optimization → L4 signal-driven. For AI/RAG: addyosmani covers infra code, shipright AI files cover
AI-specific code (eval loop, LLM boundaries) — use both, no overlap.

---

## When workflow is not appropriate

Throwaway/<1wk · script <200 lines no domain · solo <3 entities read-only → skip the machinery, hack
freely (flat functions, no layers/DI). Otherwise use shipright. Senior judgment = knowing when NOT to
apply a pattern (over-applying to a 50-line script = under-applying on a payment system). `judgment.md` §5.

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
- `references/judgment.md` — EXECUTIVE layer: one-way/two-way doors, MVP matrix, when to break each rule
- `references/code-quality.md`
- `references/code-health.md` — SOLID tactical enforcement + Ousterhout (deep modules) — construction quality
- `references/testing.md` — testing STRATEGY (Beck/Fowler/Cohn/Dodds/DHH): pyramid, test-through-the-public-interface, mock-only-at-seams, Test Desiderata (mechanics → addyosmani tdd)
- `references/domain-thinking.md` — Evans tactical: aggregate roots, invariants, domain events, "DDD or not?" decision
- `references/error-handling.md` — error taxonomy (operational/infra/programmer), Result type, saga, race conditions, idempotency
- `references/resilience.md` — RIGHT hemisphere: Nygard 8 stability patterns, Boundary 5, fault-injection tests
- `references/performance.md` — measure-first optimization ladder, N+1, mechanical sympathy, budgets
- `references/observability.md` — Correlation ID, logging, tracing, SLO/error budget, retrofit
- `references/scaling-guide.md` — Stage 1→2→3 playbook + Strangler Fig templates
- `references/team-scale.md` — multi-dev/parallel-module: boundary = team API (Conway/Parnas/Evans/Team Topologies), cognitive load, contract tests (signal-driven; solo skips)
- `references/evolutionary-architecture.md` — when you were WRONG: fitness functions (name shipright's existing ones), last responsible moment, the recovery path (Ford/Parsons) — tempers the one-way-door thesis
- `references/third-party-apis.md` — Adapter pattern, 3-layer testing, resilience
- `references/ui-design.md` — taste-skill: page type → correct skill → dials
- `references/l0-templates.md` — CLAUDE.md + ARCHITECTURE.md templates
- `references/levels.md` — lifecycle spine + L0→L4 gates, Conway's Law, graduate checklist
- `references/requirement-drift.md` — Expand-Contract + 3 architecture change scenarios
- `references/debug-intermittent.md` — intermittent / production-only / resource-leak bugs
- `references/boundaries.md` — 5 boundary rules with code examples
- `references/enforcement.md` — optional PreToolUse hook that BLOCKS boundary violations (install, bypass, limits)
- `references/security.md` — the architectural security spine: Saltzer & Schroeder principles, OWASP 2025 → layer map, threat modeling, per-language pitfalls (dispatches depth to security-and-hardening)
- `references/prompts.md` — copy-paste Claude Code prompts

### Stack files (load on project type — slim, defer to community skills)
- `references/stacks/nodejs.md`
- `references/stacks/python.md`
- `references/stacks/go.md` — packages + internal/ (compile-time Boundary 1), context timeouts (Boundary 5), pgx/sqlc, error taxonomy
- `references/stacks/php.md` — PHP 8.3+: PHPStan-as-compiler, Deptrac boundary fitness function, Doctrine/Eloquent, exception taxonomy, PHP security footguns (unserialize/mass-assignment/type-juggling)
- `references/stacks/browser-extension.md`
- `references/stacks/ai-projects.md` — AI entry point + the LLM boundary (Boundary 4 for AI)
- `references/stacks/ai-rag.md` — RAG deep dive: eval loop, vector DB, metrics
- `references/stacks/mcp.md` — Model Context Protocol: server = adapter/ACL, tool = interface, security (lethal trifecta), resilience
- `references/stacks/ai-agent.md` — agents & multi-agent: workflow-vs-agent, 5 patterns, state machines, resilience, trajectory eval
- `references/stacks/chatbot-platforms.md`
- `references/stacks/blockchain.md` — EVM/Solana/TON/SUI/TRON: smart contract security, chain-specific patterns, audit gate

### Examples
- `references/examples/orders-api-CLAUDE.md`
- `references/examples/orders-api-ARCHITECTURE.md`

---

## Language rule
Respond in the user's language. These files are English for GitHub discoverability.
CLAUDE.md and ARCHITECTURE.md content stays in English (project convention).
