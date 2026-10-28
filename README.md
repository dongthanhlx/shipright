# shipright v1.29.1

> **Ship your MVP fast. Grow it right.**

The Project Brain OS for AI coding workflow. Sets up the minimal irreversible architecture decisions, judges what to build now versus defer, enforces a roster of software-craft masters across two hemispheres (construction + operation), hardens for fault tolerance, orchestrates community skills at the right moment, and tracks project state across sessions.

Works in your language. Write Vietnamese, English, or any language — shipright responds accordingly.

```
/shipright              # installed as a skill folder
/shipright:shipright    # installed as a plugin
```
Or just describe the task: shipright loads itself when a task matches. Install: [below](#install).

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
- **Asks whether** — before *how much* comes *whether at all*: which outcome this serves, what
  happens if you **don't** build it, and the cheapest thing that would tell you it's worth it.
  One answer refuses to proceed: unproven value + expensive build.
- **Closes the loop** — an agent can verify *feasibility* just by building, so "it works" feels
  complete. It isn't. Every ship names the signal that would say it actually **mattered**, and the
  next session asks it *before* the next feature — output ≠ outcome.

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
Last shipped: checkout journey → signal "ops stops asking in Slack", check by Aug 20
Last updated: 2025-06-21
```

Branch E reads this instantly. Resume in 30 seconds, not 5 minutes — and `Last shipped` carries the
pending *"did it actually work?"* into that session, so it gets asked before the next feature starts.

---

## Registry — curated skill packs per project type

`references/registry.md` maps project type → a pack in `references/registry/` (required skills + CLAUDE.md
additions). Only the matching pack is loaded:

| Project type | Pack | Key installs |
|---|---|---|
| REST API / backend | web-api | addyosmani/agent-skills |
| RAG / knowledge base | rag-pipeline | RAGAS + addyosmani |
| Telegram/Discord bot | chatbot-telegram-discord | grammy/discord.js + addyosmani |
| Browser extension | browser-extension | WXT + Vitest (fakeBrowser) + Playwright |
| AI agent | ai-agent | DeepEval + addyosmani |
| Full-stack web | full-stack-web | addyosmani + taste-skill |
| CLI tool | cli-tool | optional |
| Desktop / PC app (Electron / Python) | desktop-app | Electron + TypeScript (default) · PySide6 · Python sidecar + addyosmani |
| Blockchain / DApp | blockchain-dapp | Foundry + Slither + addyosmani |

---

## Ecosystem

Shipright orchestrates. These execute.

| Skill | Stage | What it handles |
|---|---|---|
| addyosmani/agent-skills | Traction+ | Implementation, TDD, code review, security |
| taste-skill | When UI needed | Landing pages, portfolios, product UI, redesign audit, brand kit. An ecosystem — install per page type, and **`--skill` takes the install name, not the folder name** (`soft-skill/` → `high-end-visual-design`). See `references/ui-design.md` |
| RAGAS | RAG projects | Evaluation metrics (Hit Rate, Faithfulness) |
| LangSmith / Arize | AI projects | LLM tracing and observability |
| vercel-labs/agent-skills | Dashboards, React/Next | `web-design-guidelines` (data-heavy UI, a11y, UX correctness) · `vercel-react-best-practices` (waterfalls, bundle size, re-renders) |
| browser-testing-with-devtools | Any browser UI | Seeing it actually run — 360px render, console, network, screenshots (needs the chrome-devtools MCP server) |

**Never install all addyosmani skills at once.** Context budget is finite.
Registry tells you exactly which skills to install for your project type.

**shipright offers to install a skill the moment you need it — and uses it in the same session.**
Claude Code watches the skill directories, so a skill added mid-session works immediately without a
restart. When a trigger fires and the skill is missing, shipright asks once (~10s to install), then uses
it right away. It never installs without your yes — and that yes has to come from shipright asking,
because nothing else may: `allowed-tools` pre-approves Bash for the turn shipright is invoked in, and
auto mode never prompts. Say no and it falls back to its built-in guidance and moves on.

---

## Install

**As a Claude Code plugin (recommended)** — updates through `/plugin`, the version command and the
boundary guard come with it:
```
/plugin marketplace add dongthanhlx/shipright
/plugin install shipright@shipright
```
(One step on Claude Code 2.1.275+: `/plugin install shipright --marketplace dongthanhlx/shipright`.)
As a plugin, the skill is `/shipright:shipright` and the status check is `/shipright:version`. It also
loads by itself when a task matches; you rarely need to type either.

**As a skill folder — git** (the same skill, invoked as `/shipright`; updates by `git pull`):
```bash
git clone https://github.com/dongthanhlx/shipright ~/.claude/skills/shipright
git -C ~/.claude/skills/shipright pull     # update
```

**As a skill folder — copy** (no git history, no update check), from any checkout:
```bash
./install.sh            # personal: ~/.claude/skills/shipright
./install.sh --project  # this repo only: ./.claude/skills/shipright (commit it for the team)
```
It copies only the runtime files (`SKILL.md`, `references/`, `hooks/`), and refuses to overwrite a
directory that isn't a shipright install. Running it inside a clone that already *is* the install is a no-op.

**Pick one.** A plugin install and a skill-folder install side by side are two skills with the same
description: both compete for every trigger.

**Session start update check (optional, git installs only)** — plugin installs update through `/plugin`
instead. One line when a newer release or upstream commits exist, otherwise silent; one network call
capped at 5s (`SHIPRIGHT_UPDATE_TIMEOUT`):
```json
// ~/.claude/settings.json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/shipright/hooks/check-update.sh"
      }]
    }]
  }
}
```

**Boundary enforcement (optional) — block violations as they're written.** As a plugin, the hook is
already registered and does nothing until you turn it on: `/plugin configure shipright@shipright` →
**Boundary guard**. As a skill folder, add it to settings:
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
Details + bypass: `references/enforcement.md`. Verify on each machine: `hooks/boundary-guard.sh --self-test`
— it names the JSON parser it found (`jq`, else a Python that actually runs). With none, the end-to-end
cases show as *skipped*: the guard is installed but inert, which on Windows usually means only the
Microsoft Store `python3` alias is on PATH.

---

## Structure

```
shipright/
  SKILL.md                    # Project Brain OS core (always loaded): executive + 5 boundaries + spine + dispatch
  .claude-plugin/             # plugin.json + marketplace.json — the repo root is also a Claude Code plugin
  commands/version.md         # /shipright:version — version + ecosystem skill status
  hooks/hooks.json            # plugin hook registration (boundary guard, opt-in via the plugin's option)
  hooks/boundary-guard.sh     # PreToolUse hook — BLOCKS boundary violations as written (--self-test)
  hooks/check-update.sh       # SessionStart update checker (git installs)
  install.sh                  # copy-install into ~/.claude/skills or ./.claude/skills
  tests/                      # what CI runs: content checks + behaviour tests for hooks and install.sh (run-all.sh)
  references/
    registry.md               # Capability/signal → skill (trigger dispatch) + install recipes + pack table
    registry/                 # one project-type pack per file (web-api, rag-pipeline, desktop-app, …) — load ONE
    branches/
      a-new-project.md        # MVP/Production + registry integration + state tracking
      b-add-feature.md        # Health check + complexity tiers + quality gate
      c-fix-bug.md            # Classify → reproduce → root cause
      d-refactor.md           # Fowler smells + characterization tests
      e-resume.md             # State-first orient (30s resume) + git fallback
      f-incident.md           # Triage → mitigate → investigate
    git.md                    # the CONSENT LADDER: what the agent just does / does per the Git policy / must ask;
                              #   commits, messages, branches, PRs, merges, conflicts, releases, recovery
    judgment.md               # EXECUTIVE: one-way/two-way doors, MVP matrix, when to break each rule
    resilience.md             # Nygard 8 stability patterns, Boundary 5, fault-injection tests
    performance.md            # Measure-first optimization ladder, N+1, mechanical sympathy, budgets
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
    desktop.md                # PC apps, modern Node/Python: shape choice (Electron+TS default · PySide6 · Python sidecar),
                              #   OPERATE vs ACT, UI thread, process model, OS secret store, signing + verified updates, multi-account
    ui-design.md              # EXPERIENCE floor + UI/UX judgment (Norman/Nielsen/Krug/Refactoring UI/Tufte/
                              #   Tidwell/Wroblewski/Walter/Rand): a11y-as-correctness, state-floor, mobile,
                              #   archetype + audience tone, landing anatomy, admin patterns → THEN dispatch
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
      php.md                  # PHP 8.3+: PHPStan-as-compiler, Deptrac boundary fitness function, exception taxonomy, PHP security footguns
      ai-projects.md          # AI entry point + the LLM boundary (Boundary 4 for AI)
      ai-rag.md               # RAG deep dive: eval loop, vector DB, metrics
      mcp.md                  # Model Context Protocol: server=adapter/ACL, tool=interface, security, resilience
      ai-agent.md             # agents & multi-agent: workflow-vs-agent, 5 patterns, state machines, eval
      chatbot-platforms.md    # Telegram/Discord: adapter, state, security
      blockchain.md           # EVM/Solana/TON/SUI: security, audit gate, chain patterns
      browser-extension.md    # MV3 with WXT: contexts, typed messaging, storage boundaries, least privilege, Vitest + Playwright
      electron.md             # the default desktop shape: main/preload/renderer, typed zod IPC, utilityProcess, partitions + WebContentsView, fuses, Forge
      python-desktop.md       # PySide6 + Python as a supervised stdio JSON-RPC sidecar behind Electron (Nuitka, tufup)
    examples/
      orders-api-CLAUDE.md      # canonical example: e-commerce orders + payments API
      orders-api-ARCHITECTURE.md
```

---

## What's in it, and what's next

The full history, release by release, with the reasoning: **[CHANGELOG.md](CHANGELOG.md)**. What each
release verified at runtime, and what it found broken: **[EVALS.md](EVALS.md)**.

In one screen:
- **Executive layer:** one-way / two-way doors, the discipline of stopping, and the WHETHER half:
  Cagan's four risks, the riskiest assumption, the outcome loop that asks "did it work?" next session.
- **Construction:** 5 boundaries, a quality gate, testing strategy, domain modelling, error handling,
  security, the git consent ladder.
- **Operation, on signal:** resilience (Nygard), observability and SLOs, performance, scaling.
- **Experience:** the UI/UX floor (a11y, responsive, state-floor) and design-brief judgment.
- **Stacks:** Node, Python, Go, PHP, browser extensions, AI/RAG/agents/MCP/chatbots, blockchain, and
  desktop apps (Electron, PySide6).
- **Enforcement and CI:** an opt-in boundary-guard hook; every script tested on Linux, Windows and
  bash 3.2; version, size and spec limits checked on every PR.

Next:
- [ ] Runtime evals as an automated suite (`claude plugin eval`), so the always-loaded core can be
      slimmed toward the spec's ~5k tokens without darkening a trigger
- [ ] Project-type packs from the community (`references/registry/<type>.md`, see CONTRIBUTING)

---

## License

MIT — see [LICENSE](LICENSE).
