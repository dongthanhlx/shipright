---
name: shipright
version: 0.9.0
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
Tests:         !`(npm test --silent 2>&1 | tail -2) || (pytest -q 2>&1 | tail -2) || echo "no test runner"`
```

---

# Shipright v0.9 — Project Brain OS

Two hemispheres. One executive. One living constitution.

A brain with two hemispheres and an executive that decides how much of each to use.
The master roster grows over time — the named list below is the source of truth, not a count:

```
EXECUTIVE (prefrontal cortex) — references/judgment.md
  Bezos:  one-way vs two-way doors — get irreversible decisions right, move fast on the rest
  "Senior judgment = knowing when NOT to apply a pattern."

LEFT HEMISPHERE — construction (right structure, right model, kept clean)
  Eric Evans:    Model the right domain (Ubiquitous Language, Bounded Contexts, Aggregates)
  Uncle Bob:     Structure it correctly (SOLID, Clean Code, 20-line functions)
  John Ousterhout: Deep modules, define errors out of existence (counterweight to Uncle Bob)
  Fowler:        Keep it clean as it evolves (smell detection, compound engineering)
  Kent Beck:     Prove it (TDD: Red → Green → Refactor)

RIGHT HEMISPHERE — operation (survives failure, stays fast, stays observable)
  Michael Nygard: Survive failure (timeouts, circuit breakers, bulkheads — resilience.md)
  SRE / Majors:   Stay observable + measured (SLO, error budget — observability.md)
```

The executive sets the **dial** on each hemisphere by lifecycle phase (see spine below):
construction is ON from day one (it's the irreversible quadrant); operation turns on by signal.

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
"Is this a one-way door, and is the need real today?"

  One-way + real      → do it right, now (domain model, boundaries, data identity, money units)
  One-way + not yet   → design the seam so it stays reversible, defer the rest
  Two-way + real      → simplest thing that works, move on (cache, log format, retry count)
  Two-way + not yet   → don't build it. Write a debt signal and ship.
```

This defeats both failure modes: over-engineering (treating a two-way door as one-way) and
architecture rot (treating a one-way door as two-way). Full matrix + "when to break each rule":
`references/judgment.md`. Load it at L0 and at every "should I add X?" moment.

---

## Lifecycle spine — one model, four phases

Shipright's older vocabularies (L0–L4, Stage 1–3, MVP/Production, Traction/Growth/Scale) all
map onto one spine. Each phase declares which masters are active and the resilience dial level.

| Phase | aka | Levels / Stage | Construction dial | Operation dial |
|---|---|---|---|---|
| **SEED** | MVP | L0–L1 | boundaries + naming + core domain model | OFF — except one-way-door items (idempotency, money units, state location) |
| **VALIDATE** | Traction | L2–L3 | + TDD + quality gate | MINIMAL — timeouts + Correlation ID |
| **HARDEN** | Growth | L4 · Stage 1–2 | + Fowler refactoring | FULL Nygard + SLO/error budget (on signal) |
| **SCALE** | Scale | Stage 3 | + Ousterhout deep modules | + bulkheads, backpressure, Strangler Fig |

Detail: `references/levels.md` (spine + L0–L4 gates), `references/judgment.md` (the dial logic).

---

## Session start — 3 checks before anything else

**Check 1: Read existing constitution**
If CLAUDE.md and ARCHITECTURE.md exist → read both completely before asking anything.
Project state section in CLAUDE.md shows where things left off last session.

**Check 2: Read granular skill detection above, then adapt precisely**

```
skill/spec-driven = YES  → activate /spec for Tier L/XL BEFORE implementation starts
skill/spec-driven = NO   → guide spec writing manually (write acceptance criteria as markdown)

skill/incremental = YES  → activate for Tier M+ features with multiple files
skill/incremental = NO   → implement inside-out manually (repository → service → handler)

skill/tdd = YES          → activate for all feature implementation (all tiers with logic)
skill/tdd = NO           → write RED test manually first, then implement

skill/review = YES       → activate BEFORE every merge/commit on Tier M+
skill/review = NO        → run quality gate checklist manually (code-quality.md)

skill/debug = YES        → activate for ALL bug classifications (Branch C)
skill/debug = NO         → follow Branch C 5-step flow manually

skill/security = YES     → activate before production deploy / growth stage
skill/security = NO      → manual OWASP checklist (note: not sufficient for smart contracts)

skill/taste = YES        → activate for UI pages — read ui-design.md for correct variant
skill/taste = NO         → describe design direction manually, reference ui-design.md dials
```

When skill = NO: always say "X not installed — using shipright's built-in guidance instead."
Never pretend skill is available when it's not. Never skip the step entirely.

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

## Quality system — construction hemisphere, enforced throughout

### At L0 (constitution)
- Evans: Ubiquitous Language in CLAUDE.md (domain terms Claude must use)
- Evans: Domain types in ARCHITECTURE.md (Entity vs Value Object vs Service)
- Uncle Bob: Clean Code rules in CLAUDE.md (function max 20 lines, no AND/OR names)
- **Test runner configured** — Jest/pytest/Foundry/Anchor set up at L0, not later

### At L1 (skeleton) — test BEFORE implementation
**Kent Beck's TDD rule: Red → Green → Refactor. Never Green → Red.**
Write the failing test FIRST, then implement until it passes.
This applies in MVP mode AND production mode. There is no "skip tests for speed" mode.

```
MVP skeleton test: 1 test that proves the skeleton works end-to-end
  → test FAILS (nothing implemented) → implement → test PASSES → commit

Production L2 tests: all interface contracts as RED tests
  → tests FAIL → implement → tests PASS → commit
```

Uncle Bob: "The only way to go fast is to go well."
Fowler: "Any fool can write code that a computer can understand.
         Good programmers write code that humans can understand."
Test-first makes code understandable because it was designed to be tested.

### At L3 (before every commit)
Load `references/code-quality.md` for full gate. Quick version:
```
Tests:   New code has tests? Tests written BEFORE implementation?
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

## Ecosystem dispatch — shipright is the conductor

Shipright owns WHEN and WHAT. Community skills own HOW. Two hard rules:
1. Never self-execute work a dedicated skill already covers.
2. Never load a skill you'd duplicate, and never load heavy skills a small project doesn't
   need yet — every loaded skill spends context budget and dilutes reasoning. Few skills
   when small is a correctness concern, not minimalism.

```
Shipright owns:
  Constitution (CLAUDE.md + ARCHITECTURE.md)
  5 boundary rules + quality gate + the executive/judgment layer
  Lifecycle spine + project state + routing
  Registry-based skill suggestions (by trigger)
  Irreversible (one-way-door) architecture decisions

Dispatch by TRIGGER, not by stage label. Stage is only the default heuristic; the trigger
is the truth. A payment MVP needs security on day one; a read-only Growth app may never.

addyosmani/agent-skills — activate by trigger (detection checks each skill individually):
  debugging-and-error-recovery   ← any bug. Most valuable from day one — install at SEED.
  test-driven-development        ← any logic/behavior change (all phases).
  incremental-implementation     ← any feature touching 2+ files.
  code-review-and-quality        ← before any merge on Tier M+.
  spec-driven-development        ← before a Tier L/XL feature with unclear requirements.
  security-and-hardening         ← the MOMENT auth / payments / untrusted input appears
                                    (regardless of phase — not "at Growth").
  observability-and-instrumentation ← when prod behavior becomes invisible (HARDEN signal).
  Default ladder if no specific trigger: SEED=debug · VALIDATE=+tdd/incremental/review ·
  HARDEN=+spec/security/observability · SCALE=+specialized.
  Note: agent-skills folder ≠ all 24 skills installed. Detection checks individual skills.

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

Senior judgment = knowing when NOT to apply a pattern. Applying the full tree to a 50-line
script is the same failure as skipping it on a payment system — opposite directions, same
mistake. Full "when to break each rule" guidance: `references/judgment.md`.

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
- `references/domain-thinking.md` — Evans tactical: aggregate roots, invariants, domain events, "DDD or not?" decision
- `references/error-handling.md` — error taxonomy (operational/infra/programmer), Result type, saga, race conditions, idempotency
- `references/resilience.md` — RIGHT hemisphere: Nygard 8 stability patterns, Boundary 5, fault-injection tests
- `references/performance.md` — measure-first optimization ladder, N+1, mechanical sympathy, budgets
- `references/observability.md` — Correlation ID, logging, tracing, SLO/error budget, retrofit
- `references/scaling-guide.md` — Stage 1→2→3 playbook + Strangler Fig templates
- `references/third-party-apis.md` — Adapter pattern, 3-layer testing, resilience
- `references/ui-design.md` — taste-skill: page type → correct skill → dials
- `references/l0-templates.md` — CLAUDE.md + ARCHITECTURE.md templates
- `references/levels.md` — lifecycle spine + L0→L4 gates, Conway's Law, graduate checklist
- `references/requirement-drift.md` — Expand-Contract + 3 architecture change scenarios
- `references/debug-intermittent.md` — intermittent / production-only / resource-leak bugs
- `references/boundaries.md` — 5 boundary rules with code examples
- `references/enforcement.md` — optional PreToolUse hook that BLOCKS boundary violations (install, bypass, limits)
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
- `references/examples/orders-api-CLAUDE.md`
- `references/examples/orders-api-ARCHITECTURE.md`

---

## Language rule
Respond in the user's language. These files are English for GitHub discoverability.
CLAUDE.md and ARCHITECTURE.md content stays in English (project convention).
