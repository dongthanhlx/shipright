# shipright v1.12.0

> **Ship your MVP fast. Grow it right.**

The Project Brain OS for AI coding workflow. Sets up the minimal irreversible architecture decisions, judges what to build now versus defer, enforces a roster of software-craft masters across two hemispheres (construction + operation), hardens for fault tolerance, orchestrates community skills at the right moment, and tracks project state across sessions.

Works in your language. Write Vietnamese, English, or any language — shipright responds accordingly.

```
/shipright
```

---

## Why shipright?

AI coding agents are great at writing code and bad at deciding *what* to build, *when*, and
*what not to*. The community skills you already have (addyosmani/agent-skills, taste-skill,
RAGAS…) each do one job well — but nothing decides which to use, when, or stops you
over-building. shipright is the **conductor**, not another player:

- **Decides** — one executive question (one-way vs two-way door) sizes every choice, so an MVP
  ships fast *without* painting the architecture into a corner you pay for three features later.
- **Guards** — 5 boundary rules + a quality gate that hold from day one to millions of users,
  and an optional PreToolUse hook that *blocks* the worst violations before they're written.
- **Orchestrates** — activates the right community skill at the right trigger, and refuses to
  load the ones a small project doesn't need yet (context budget = reasoning quality).
- **Remembers** — a living constitution (CLAUDE.md) that gets smarter every session, plus
  project state so you resume in 30 seconds.

If you've ever watched an AI agent confidently build the wrong thing, over-engineer a
prototype, or break the architecture later — that's the gap shipright fills.

---

## What it does

**Layer 0 — Executive:** judgment layer (one-way/two-way doors) sets the dial on everything else
**Layer 1 — Always active:** 5 boundary rules + two-hemisphere quality system + lifecycle spine + 6-branch routing
**Layer 2 — Registry:** Project type → curated skill pack (dispatched by trigger) + CLAUDE.md additions
**Layer 3 — On demand:** Branch files (one per session), reference files (load on signal)

| You say | Shipright does |
|---|---|
| New project | Check state → intake + registry → constitution → skeleton |
| Add feature | Read CLAUDE.md → health check → complexity tier → quality gate |
| Fix bug | Classify → reproduce → locate → root cause → fix |
| Refactor | Fowler smell → define done → characterization tests → atomic steps |
| Resume after break | Read state section → continue in 30 seconds |
| Production incident | Triage → mitigate first → investigate → post-incident |

---

## The 5 boundaries — never negotiable

```
1. Dependencies point inward only
2. Each layer has one job (handler / service / repository)
3. Modules do not share databases
4. No raw external response passes the Adapter layer
5. Every integration point has a timeout + a deliberate fallback (failure isolation)
```

Backed by Uncle Bob's Dependency Rule, Fowler's internal quality research,
Eric Evans's Anti-Corruption Layer, and Michael Nygard's stability patterns.

---

## A brain with two hemispheres and an executive

| Tier | Master | Dimension | When |
|---|---|---|---|
| **Executive** | Bezos (reversibility) | Decide what to build now vs defer | Every non-trivial decision |
| Construction | Evans (DDD) | Model the right domain | L0: Ubiquitous Language, domain types |
| Construction | Uncle Bob (SOLID) | Structure it correctly | L3: quality gate before every commit |
| Construction | Ousterhout | Deep modules, define errors out of existence | L2: interface design (counterweight to Bob) |
| Construction | Fowler (Refactoring) | Keep it clean as it evolves | Branch D: smell-driven refactoring |
| Construction | Kent Beck (TDD) | Prove it works | L1–L3: Red → Green → Refactor |
| Operation | Nygard (Release It!) | Survive failure | HARDEN: timeouts, circuit breakers, bulkheads |
| Operation | SRE / Majors | Stay observable + measured | HARDEN: SLO, error budget, golden signals |

The **executive** sets the dial: construction is ON from day one (irreversible quadrant),
operation turns on by signal (adding it at MVP is over-engineering).

Compound Engineering: every AI violation → specific rule added to CLAUDE.md.
CLAUDE.md gets smarter every session.

---

## Persistent state

Shipright writes a state section to CLAUDE.md after milestones:
```markdown
## Shipright state
Level: L3
Active: payments module
Next: implement PaymentService.charge() — RED test exists line 47
Last updated: 2025-06-21
```

Branch E reads this instantly. Resume in 30 seconds, not 5 minutes.

---

## Registry — curated skill packs per project type

`references/registry.md` maps project type → required skills + CLAUDE.md additions:

| Project type | Registry entry | Key installs |
|---|---|---|
| REST API / backend | web-api | addyosmani/agent-skills |
| RAG / knowledge base | rag-pipeline | RAGAS + addyosmani |
| Telegram/Discord bot | chatbot-telegram-discord | grammy/discord.js + addyosmani |
| Browser extension | browser-extension | jest-webextension-mock |
| AI agent | ai-agent | DeepEval + addyosmani |
| Full-stack web | full-stack-web | addyosmani + taste-skill |
| CLI tool | cli-tool | optional |
| Blockchain / DApp | blockchain-dapp | Foundry + Slither + addyosmani |

---

## Ecosystem

Shipright orchestrates. These execute.

| Skill | Stage | What it handles |
|---|---|---|
| addyosmani/agent-skills | Traction+ | Implementation, TDD, code review, security |
| taste-skill | When UI needed | Landing pages, portfolios, product UI |
| RAGAS | RAG projects | Evaluation metrics (Hit Rate, Faithfulness) |
| LangSmith / Arize | AI projects | LLM tracing and observability |
| vercel-labs/agent-skills | Dashboards | Data-heavy UI, a11y, UX correctness |

**Never install all addyosmani skills at once.** Context budget is finite.
Registry tells you exactly which skills to install for your project type.

---

## Install

**Personal — git (enables update notifications):**
```bash
git clone https://github.com/dongthanhlx/shipright ~/.claude/skills/shipright
```

**Update:**
```bash
git -C ~/.claude/skills/shipright pull
```

**Session start update check (optional):**
```json
// ~/.claude/settings.json
{
  "hooks": {
    "SessionStart": [{
      "type": "command",
      "command": "~/.claude/skills/shipright/hooks/check-update.sh"
    }]
  }
}
```

**Boundary enforcement (optional) — block violations as they're written:**
```json
// ~/.claude/settings.json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/shipright/hooks/boundary-guard.sh"
      }]
    }]
  }
}
```
Opt-in, fails open, safe to enable globally (no-ops outside module-structured projects).
Details + bypass: `references/enforcement.md`. Verify: `hooks/boundary-guard.sh --self-test`.

---

## Structure

```
shipright/
  SKILL.md                    # Project Brain OS core (always loaded): executive + 5 boundaries + spine + dispatch
  hooks/check-update.sh       # SessionStart update checker
  hooks/boundary-guard.sh     # PreToolUse hook — BLOCKS boundary violations as written (--self-test)
  references/
    registry.md               # Capability/signal → skill (trigger dispatch) + project-type packs
    branches/
      a-new-project.md        # MVP/Production + registry integration + state tracking
      b-add-feature.md        # Health check + complexity tiers + quality gate
      c-fix-bug.md            # Classify → reproduce → root cause
      d-refactor.md           # Fowler smells + characterization tests
      e-resume.md             # State-first orient (30s resume) + git fallback
      f-incident.md           # Triage → mitigate → investigate
    judgment.md               # EXECUTIVE: one-way/two-way doors, MVP matrix, when to break each rule (NEW v0.8)
    resilience.md             # Nygard 8 stability patterns, Boundary 5, fault-injection tests (NEW v0.8)
    performance.md            # Measure-first optimization ladder, N+1, mechanical sympathy, budgets (NEW v0.8)
    code-quality.md           # Evans + Uncle Bob + Fowler: full quality system
    code-health.md            # SOLID tactical + Ousterhout (deep modules, define errors out of existence)
    testing.md                # testing STRATEGY: pyramid, test-through-public-interface, mock-only-at-seams, Test Desiderata
    domain-thinking.md        # Evans tactical: aggregate roots, invariants, domain events, "DDD or not?"
    error-handling.md         # Error taxonomy, Result type, saga, race conditions, idempotency
    observability.md          # Correlation ID, logging, API tracing, SLO/error budget, DORA, retrofit
    scaling-guide.md          # Stage 1→2→3 + Strangler Fig templates
    team-scale.md             # multi-dev/parallel-module: boundary = team API, cognitive load, contract tests (signal-driven)
    evolutionary-architecture.md # when you were WRONG: fitness functions, last responsible moment, the recovery path (Ford/Parsons)
    third-party-apis.md       # Adapter pattern, 3-layer testing, resilience
    ui-design.md              # taste-skill: page type → correct skill → dials
    l0-templates.md           # CLAUDE.md + ARCHITECTURE.md templates + state section
    levels.md                 # Lifecycle spine + L0→L4, gates, Conway's Law, graduate checklist
    boundaries.md             # 5 boundary rules with code examples
    enforcement.md            # the PreToolUse boundary-guard hook: install, bypass, guarantees, limits
    security.md               # architectural security spine: Saltzer&Schroeder + OWASP 2025→layer map + per-language pitfalls
    requirement-drift.md      # Expand-Contract + 3 architecture scenarios
    debug-intermittent.md     # Intermittent / production-only / resource leak bugs
    prompts.md                # Copy-paste Claude Code prompts
    stacks/
      nodejs.md
      python.md
      go.md                   # packages + internal/ (compile-time Boundary 1), context timeouts, pgx/sqlc
      ai-projects.md          # AI entry point + the LLM boundary (Boundary 4 for AI)
      ai-rag.md               # RAG deep dive: eval loop, vector DB, metrics
      mcp.md                  # Model Context Protocol: server=adapter/ACL, tool=interface, security, resilience
      ai-agent.md             # agents & multi-agent: workflow-vs-agent, 5 patterns, state machines, eval
      chatbot-platforms.md    # Telegram/Discord: adapter, state, security
      blockchain.md           # EVM/Solana/TON/SUI: security, audit gate, chain patterns
      browser-extension.md    # MV3: manifest, components, chrome.* APIs
    examples/
      orders-api-CLAUDE.md      # canonical example: e-commerce orders + payments API
      orders-api-ARCHITECTURE.md
```

---

## Roadmap

- [x] 6-branch routing
- [x] MVP mode vs production mode
- [x] 4 boundary rules (non-negotiable)
- [x] Three masters quality system (Evans + Uncle Bob + Fowler)
- [x] Complexity-based skill activation (Tier S/M/L/XL)
- [x] Observability: Correlation ID, tracing, API tracing, retrofit
- [x] Scaling guide: Stage 1→2→3 + Strangler Fig
- [x] AI/RAG/chatbot/browser-extension stack support
- [x] **v0.7: Registry (project type → curated skill pack)**
- [x] **v0.7: Persistent state (CLAUDE.md state section)**
- [x] **v0.7: Session-start state check (30-second resume)**
- [x] **v0.7: Ecosystem dispatch (who owns what)**
- [x] **v0.8: Executive/judgment layer (one-way/two-way doors, MVP matrix, when to break each rule)**
- [x] **v0.8: Operation hemisphere — Nygard resilience (Boundary 5, 8 stability patterns, fault-injection tests)**
- [x] **v0.8: Ousterhout counterweight (deep modules, define errors out of existence)**
- [x] **v0.8: Lifecycle spine (unifies L0–L4 / Stage 1–3 / MVP–Scale)**
- [x] **v0.8: Trigger-based skill dispatch + SLO/error budget/DORA**
- [x] **v0.9.1: Go stack file (packages + internal/ compile-time boundaries, context timeouts, pgx/sqlc, error taxonomy)**
- [x] **v0.8.2: registry capability/signal → skill trigger index**
- [x] **v1.1.0: MCP stack (server=adapter/ACL, tool=interface contract, lethal-trifecta security, Boundary-5 resilience)**
- [x] **v1.2.0: agents & multi-agent stack (workflow-vs-agent judgment, Anthropic/Ng patterns, LangGraph state machines, trajectory eval + tracing)**
- [x] **v1.3.0: security spine (Saltzer&Schroeder + OWASP 2025→layer map + Shostack threat modeling) + per-stack security depth (Node/Python/Go/extension/RAG)**
- [x] **v1.4.0: chatbot AI threat model (prompt-injection done right, abuse/cost control, moderation, isolation) + smart-contract defense patterns (CEI/reentrancy, access control, EIP-712 replay, upgradeable) + invariant/fuzz testing**
- [x] **v1.5.0: intake reimagined — adaptive intent discovery (Mom Test / JTBD / Shape Up / interview-me) replaces the mechanical questionnaire; understand-before-advising, playback step, shipright carries technical judgment; still MVP-first**
- [x] **v1.6.0: conversational intake across ALL branches — shared "How shipright asks" principle in SKILL.md (read/infer before asking; diagnose-then-confirm, not menu-quiz); B/C/D reworked, F kept as deliberate speed exception**
- [x] **v1.7.0: constitution as a lean, distilled, confirmed contract (aligned to Anthropic's CLAUDE.md guidance: <200 lines, @import for deep conventions, auto-memory split, distill-from-discovery, generate→confirm, Nygard-format ADRs, /init for existing code)**
- [x] **v1.8.0: team scale — the module boundary as a team API (Conway/Parnas/Evans/Team Topologies/DORA): cognitive load, inverse Conway at L0, context maps, consumer-driven contract tests; signal-driven (solo skips) + sharpened MVP framing (Validation vs Foundation, Fowler payoff line, Ousterhout local-complexity guard)**
- [x] **v1.9.0: testing strategy spine (Beck Test Desiderata / Fowler pyramid & mocks / Cohn / Dodds trophy / DHH damage) — anti-dogma; boundaries ARE the test strategy (test through the public interface, mock only at seams); de-dogmatized the TDD framing**
- [x] **v1.10.0: build-loop disentangled (GOOS/Cockburn) — fixed the adjacent outside-in/inside-out contradiction into three separate axes: DRIVE outside-in · SLICE vertical · IMPLEMENT domain-first for convenience (not "always"); reconciled with testing.md**
- [x] **v1.11.0: the discipline of STOPPING — completes the executive layer (judgment.md) with Definition-of-Done + good-enough (Hunt & Thomas / Shape Up scope-hammering / Pareto): cut SCOPE not QUALITY, appetite as a fixed budget, ship-then-feedback; a second executive question ("good enough, or gold-plating?")**
- [x] **v1.12.0: evolutionary architecture — tempers the one-way-door thesis (Ford/Parsons/Bezos/Poppendieck): bias toward reversibility, last responsible moment, and NAMES shipright's existing fitness functions (boundary-guard, arch tests, budgets, SLOs) + the recovery path for when a settled decision was wrong**
- [ ] references/registry.md community contributions (ongoing)
- [x] **v0.9: PreToolUse boundary-enforcement hook (blocks service→db + deep cross-module imports; opt-in, fails open, self-test)**

---

## License

MIT
