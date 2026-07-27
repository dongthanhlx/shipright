# shipright v1.24.0

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
it right away. It never installs without your yes: its `allowed-tools` pre-approves Bash, so the harness
shows no permission prompt of its own. Say no and it falls back to its built-in guidance and moves on.

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
- [x] **v1.13.0: PHP stack file (PHP 8.3+): PHPStan-as-compiler, Deptrac boundary fitness function, Doctrine/Eloquent, exception taxonomy, and the PHP-specific security footguns (unserialize object injection, mass assignment, `==` type juggling)**
- [x] **v1.14.0: consistent framework guidance for backend stacks (Node/Python/Go/PHP) — recommend a default + when to pick another + "keep the framework at the edge so it stays a two-way door (swappable)"; python.md no longer hard-assumes FastAPI**
- [x] **v1.15.0: staleness/consistency propagation — removed stale version strings (prompts.md "v0.7.2", go.md "v0.9 hook"), fixed leftover Boundary-5/6 collisions (blockchain + prompts + registry), updated prompts build-order to the v1.10 outside-in/vertical model, noted the expanded master roster in code-quality.md**
- [x] **v1.16.0: slim the always-loaded core (SKILL.md 461→347 lines) BY PRINCIPLE not by number — cut duplication (ecosystem-dispatch↔registry, quality-system↔refs) + re-read explanation; kept every load-bearing instruction; reframed shipright's own "<200 lines" advice (size is a consequence, not a Goodhart target)**
- [x] **v1.17.0: RUNTIME evals — dogfooded shipright against 13 real scenarios to verify knowledge FIRES at the right moment (the artifact↔runtime gap greps can't see). Found the "we were wrong / requirements changed / MCP" family was DARK (catalogued but no in-session trigger, because they surface mid-construction — neither a routing moment nor an L4 operation signal). Fixed with a "Mid-work signals" trigger table in the always-loaded core; captured the suite as a reusable fitness function in `EVALS.md`**
- [x] **v1.18.0: UI/UX judgment layer — the one domain with zero master grounding now has a full hemisphere. `references/ui-design.md` rebuilt from a pure taste-skill dispatch table into judgment (Norman/Nielsen/Krug/Refactoring UI/Tufte/Tidwell/Wroblewski + WCAG-as-correctness + state-floor), an MVP-first floor-vs-scope split, mobile/responsive (incl. data-tables-on-mobile), durable style archetypes + living reference sources, landing anatomy (Krug/Cialdini) and an admin/dashboard pattern language. Wired to FIRE from Branch A + B + session-start (dogfooded). Judgment decides; taste-skill/dataviz/vercel execute**
- [x] **v1.19.0: UI/UX judgment layer + system-vs-experience balance — `ui-design.md` rebuilt into a masters-grounded hemisphere (Norman/Nielsen/Krug/Refactoring UI/Tufte/Tidwell/Wroblewski/Walter + brand archetypes + Paul Rand): principles, MVP-first floor-vs-scope, deep mobile/responsive, SVG icons (no emoji), logo, style archetypes + audience emotional tone + emotional design (anti-AI-slop), and design-brief intake. The executive layer (judgment.md §5b) now balances the SYSTEM floor vs the EXPERIENCE floor — by project shape AND per task (Branch B forks on task KIND before complexity). Wired to fire from Branch A/B + session-start**
- [x] **v1.20.0: system-wide firing audit — (a) the UI/UX layer now actually fires: the description carried zero UI vocabulary so the whole v1.18/v1.19 hemisphere only loaded if the user said "build", Branch D had no redesign track (its "no measurable pain" guard was bouncing legitimate UI work), Branch C didn't recognize visual/UX bugs, and there was no mid-work UI signal. (b) Then the harder question — do the dispatch targets exist? **6 of 8 taste-skill install commands were broken** (folder names where the CLI wants install names) and two named skills were never in the repo at all; every skill probe encoded one install layout and returned NO forever under the other; `/shipright-version` probed a root SKILL.md that multi-skill repos don't have. Plus `boundaries.md` was DARK, stack files fired only from Branch A, and 6 registry entries had no `load:` line. EVALS.md gains a **BROKEN-TARGET** verdict — a trigger that fires into a name that doesn't exist is indistinguishable from no trigger**
- [x] **v1.21.0: capability additions, curated by trigger — the audit's second half surfaced capable skills shipright had never mapped at all (a quieter failure than a broken name, same outcome: a real need with no executor). Added `browser-testing-with-devtools` (shipright mandated "verify at 360px with a real thumb" but had no way to actually see a page run — now wired into the mobile rule, Branch D's before/after capture, and Branch C's visual repro, with an explicit ban on calling a UI responsive/accessible from reading code), `vercel-react-best-practices` (React/Next execution detail under performance.md's stack-agnostic ladder), `documentation-and-adrs` (a one-way door nobody recorded gets re-litigated next session), `deprecation-and-migration` (the contract phase of expand→migrate→contract), `ci-cd-and-automation` (a fitness function only guards you if it runs). Explicitly NOT added, and recorded so it isn't re-proposed: code-simplification and planning-and-task-breakdown (duplicate shipright), composition-patterns (empty description — unverifiable)**
- [x] **v1.22.0: acquisition — a missing skill is a 10-second problem, not a permanent one. shipright printed an install command and resigned to its fallback, on the untested assumption that a mid-session install wouldn't help. It does: Claude Code watches the skill directories, so a skill added under `~/.claude/skills/` takes effect immediately without a restart. Check 3 goes from *note it* to *offer → install on consent → use it this session* (verified: the CLI detects an agent environment and runs non-interactively; `--list` prints the exact install names). Consent is mandatory and must come from shipright, since its own `allowed-tools` pre-approves Bash and the harness prompts for nothing. Also fixed a bug that existed under the old policy: the `skill/*` probes are rendered **once** per session, so a user who installed the skill mid-session — as shipright told them to — kept being told it wasn't installed**
- [x] **v1.23.0: slim the core again, by principle — three releases of firing fixes put 56 net lines back into the always-loaded core, pushing it toward the ~460 v1.16 deliberately cut. Took back 35 lines / ~740 tokens with **no trigger removed**: 8 skill probes collapse to 2 that *list what's present* (six fewer subprocesses per session, and more information than a boolean), install commands stop living in three places, and the reference index — the largest always-loaded block, which by shipright's own doctrine causes nothing to fire — becomes a role-grouped map with all 42 filenames kept. Deliberately untouched: the Mid-work and L4 tables, the executive question, "How shipright asks", the boundaries, and every fallback-judgment column — that prose is where shipright reasons rather than checklists. Verified nothing load-bearing left: the first draft dropped 9 stack files off the map and the check caught it before commit**
- [x] **v1.24.0: backend/system/architecture/security firing audit — the refs held (resilience, observability, performance, error-handling, domain-thinking, team-scale, evolutionary-architecture, third-party-apis, scaling-guide all keep trigger rows; the v1.20 stack-file fix survived v1.23's slim). Two things didn't. (a) **shipright dispatched to zero bundled Claude Code skills** while telling users to install third-party ones for the same jobs — worse since v1.22 made it *offer* installs. `/security-review` is the missing execution arm of `security.md` (the old "manual OWASP" fallback was selling shipright short); `/code-review` is the merge gate and is **user-invoke-only**, so shipright must ask rather than claim the gate closed; plus `/run`, `/debug`, `/claude-api`. (b) **Security fired at intake and nowhere else** — a bug fix in a payment path or a refactor of auth triggered nothing, which is exactly where a vulnerability moves while every test stays green. Now fires in any branch, plus Branch C and D specifically. Added `doubt-driven-development` (adversarial review of irreversible/security-sensitive decisions — shipright's one-way door in someone else's words) and wired `api-and-interface-design` to Branch B's contract fork**
- [ ] references/registry.md community contributions (ongoing)
- [x] **v0.9: PreToolUse boundary-enforcement hook (blocks service→db + deep cross-module imports; opt-in, fails open, self-test)**

---

## License

MIT
