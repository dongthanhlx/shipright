# Changelog

## [0.8.0] — 2026-06 — BrainOS: executive layer + operation hemisphere
### The reframe
Shipright was a strong CONSTRUCTION-phase OS (Evans + Uncle Bob + Fowler + Beck) but lopsided:
it modeled and structured code well, yet treated fault tolerance, performance, and judgment as
scattered footnotes. v0.8 makes it a full-lifecycle brain: two hemispheres + an executive that
decides how much of each to apply, by stage × risk × reversibility.

### Added — Executive layer (the "veteran mindset")
- references/judgment.md — one-way vs two-way doors (Bezos); the MVP cost×reversibility matrix
  (ship fast WITHOUT breaking architecture); the rule-of-three / YAGNI / cost-of-carry gate;
  explicit "when to break each shipright rule" (20-line, TDD, boundaries, DRY).
  Promotes "Senior judgment = knowing when NOT to apply a pattern" from footnote to top tier.

### Added — Operation hemisphere (fault tolerance + performance + measurement)
- references/resilience.md — Michael Nygard's 8 stability patterns (timeout, retry+backoff+jitter
  +budget, circuit breaker, bulkhead, graceful degradation, backpressure/load shedding,
  idempotency, steady state), the anti-patterns they defend against, and fault-injection tests
  that PROVE resilience instead of assuming it.
- Boundary 5 — "Every integration point has a timeout + a deliberate fallback" (failure
  isolation). Added to SKILL.md, boundaries.md (full Rule 5 with code + dial-by-phase).
- references/performance.md — measure-first optimization ladder (profile → query → reduce →
  cache → scale), N+1 + bounded result sets as structural early choices, mechanical sympathy
  (Martin Thompson), performance budgets, benchmark-before/after.
- observability.md — SLO / error budget / four golden signals (Google SRE, Charity Majors) +
  DORA delivery metrics as an architecture-health signal.

### Added — Ousterhout as deliberate counterweight to Uncle Bob
- code-health.md — deep modules over many shallow ones; define errors out of existence;
  complexity = change amplification + cognitive load + unknown unknowns; explicit guidance for
  when Bob and Ousterhout disagree. SRP/20-line signals reframed as PROMPTS to look, not laws.

### Changed — One lifecycle spine, trigger-based dispatch
- SKILL.md — reframed as two hemispheres + executive; 6+ master roster; the executive question
  ("Is this a one-way door, and is the need real today?"); unified lifecycle spine
  (SEED → VALIDATE → HARDEN → SCALE) mapping L0–L4 / Stage 1–3 / MVP–Scale.
- SKILL.md ecosystem dispatch — shifted from STAGE-based to TRIGGER-based ("activate
  security-and-hardening the moment auth/payments/untrusted input appears — not 'at Growth'").
  Conductor principle hardened: never self-execute a skill's job; never load skills a small
  project doesn't need yet (context budget = reasoning quality).
- levels.md — lifecycle spine table added at top (the one model the four vocabularies map onto).
- L4 signal table — resilience, performance, and SLO signals added with their reference files.

### Fixed
- code-health.md: corrupted first line ("ipright loads this file" → "Shipright loads this file").
- README.md: garbled blockchain.md structure comment (Telegram/Discord fragment was merged in).
- README.md: "5th boundary rule" mislabel on ai-projects.md (it's the LLM boundary, not Boundary 5).

## [0.7.9] — 2025-06 — Rate limit decision point
### Problem fixed
Rate limits were mentioned in docs but never enforced as a decision point.
Developer would discover rate limits only after getting 429 in production.

### Changed
- third-party-apis.md Phase A: 6 mandatory rate limit questions
  Q1: exists? Q2: behavior on exceed? Q3: track remaining? Q4: recovery?
  Q5: sandbox limits? Q6: cost implications?
- third-party-apis.md: new "Rate limit setup" section after Layer 1
  Decision tree: per-second → Bottleneck, per-day → QuotaTracker, unknown → retry+backoff
  Code templates: Node.js Bottleneck, DB quota tracker, Retry-After aware retry
  Python: async rate limiter with sliding window
- Branch A Q5b Phase A: rate limit Q&A added as mandatory before writing code
  "If NO documented rate limit: ask provider or assume 60 req/min"
- l0-templates.md: CLAUDE.md external APIs table now includes limit/scope/implementation
  + rate limit rules (check before call, respect Retry-After, alert at 80%)
- registry.md: rate limit check note added to web-api entry

## [0.7.8] — 2025-06 — Docs study before API calls
### Problem fixed
v0.7.7 triggered API exploration (Layer 1) but jumped straight to calling.
Without reading docs first, Bruno requests use wrong params, wrong auth format,
or test wrong scenarios — wasting API quota and getting wrong fixtures.

### Changed
- third-party-apis.md Layer 1: restructured into 4 phases:
  Phase A — Study docs: create API-NOTES.md with params, types, error codes, rate limits
  Phase B — Build Bruno request with REALISTIC values from docs understanding
  Phase C — Call and compare: docs vs reality, save all scenario fixtures
  Phase D — Update API-NOTES.md with "Reality vs Docs" discrepancies
  (Phase E was already there: write Adapter using fixtures)
- Branch A Q5b: Phase A (docs study) explicitly added as first step
- prompts.md: API exploration prompt restructured into same 5-phase flow
  Key addition: "Build request with REALISTIC test values — not placeholder strings"

### Why docs + real calls together
Docs tell you: what params exist, what they do, valid values, expected errors
Real calls tell you: actual response shape, field optionality, type mismatches,
undocumented errors, actual rate limit behavior
Together: Adapter is grounded in both intent AND reality

## [0.7.7] — 2025-06 — API exploration trigger (Layer 1)
### Problem fixed
Layer 1 Exploration (Bruno → call API → save fixture) existed in third-party-apis.md
but was NEVER triggered by Branch A or B. Claude would skip it and write Adapters
from documentation alone — docs are often wrong, incomplete, or outdated.

### Changed
- Branch A Q5b: now explicitly triggers Layer 1 Exploration with 4 concrete steps
  before any Adapter code is written
- Branch B Q3b: checks "do fixtures exist?" — if NO, explore first
- third-party-apis.md Layer 1: added "most skipped step in AI coding" warning
  + "When to do / When NOT needed" guidance
  + Claude Code prompt for exploration workflow
- prompts.md: API exploration prompt template added
- registry.md: exploration note for rag-pipeline (LLM API shape changes by model)

## [0.7.6] — 2025-06 — Full file upgrade pass (18/18 checks)
### Updated files (15 files upgraded)
- boundaries.md: Ubiquitous Language + boundaries work together section
- branches/c-fix-bug.md: quality gate before commit after fix
- branches/d-refactor.md: Shipright state update in Step 5
- code-health.md: Kent Beck TDD note at top
- examples/news-crawler-ARCHITECTURE.md: Ubiquitous Language reference
- observability.md: Shipright state integration note
- scaling-guide.md: Ubiquitous Language at each scale stage
- prompts.md: Foundry and Anchor blockchain test templates added
- stacks/ai-rag.md: eval question set framed as TDD test suite
- stacks/browser-extension.md: test-first in walking skeleton
- stacks/chatbot-platforms.md: Ubiquitous Language for chatbot domain
- third-party-apis.md: Ubiquitous Language at Adapter boundary
- ui-design.md: Ubiquitous Language for UI component naming
- stacks/nodejs.md: Jest/Vitest test setup + Red→Green→Refactor example
- stacks/python.md: pytest setup + Red→Green→Refactor example
- CONTRIBUTING.md: registry.md contribution guide added

### Audit result: 18/18 checks pass

## [0.7.5] — 2025-06 — Precise skill detection and suggestion
### Problem fixed
Shipright used `ls ~/.claude/skills/` to detect skills — this gives folder names only.
`agent-skills` folder could contain 0 or 24 sub-skills — shipright couldn't tell.
Result: wrong skill suggestions, suggesting skills user doesn't have.

### Changed: SKILL.md working context
- Replaced vague `ls` detection with granular per-skill checks
- Checks both ~/.claude/skills/ AND .claude/skills/ (project-scoped)
- 7 specific skills checked: spec-driven, incremental, tdd, review, debug, security, taste
- Each shows YES or NO — no ambiguity

### Changed: SKILL.md session checks
- "Check 2" now maps each skill YES/NO to specific behavior
- skill=NO: explicit fallback behavior defined, not "suggest to install"
- Always says "X not installed — using shipright's built-in guidance instead"
- Never skips the workflow step, never pretends skill is available

### Changed: Branch B tier suggestions
- Tier M/L now split into PHASE: before/implementing/after
- Spec-driven: only triggered BEFORE implement starts (not mid-feature)
- TDD: triggered DURING implementation (all tiers with logic)
- Review: triggered BEFORE merge (all tiers M+)
- Each phase shows: if skill=YES → action, if skill=NO → fallback

## [0.7.4] — 2025-06 — Test-first enforcement (Kent Beck)
### Critical fix
Shipright was not enforcing test-first in MVP mode.
"Tests: enough to prove skeleton works" was passive — Claude skipped tests entirely.

### Changed
- Branch A MVP skeleton: now mandates RED test FIRST before any implementation
  "Write the failing test FIRST. This applies in MVP and production. No exceptions."
  Added blockchain-specific note: "No undo button → test before testnet deploy"
- Branch B Tier S: clarified — config/copy changes no test, logic changes test first
- SKILL.md quality system: Kent Beck TDD added at L1 level
  "Never Green → Red. Always Red → Green → Refactor."
- l0-templates.md: CLAUDE.md template now includes "Test runner configured at L0"
  + "Test first, implement second — no exceptions for speed"
- code-quality.md: new Kent Beck TDD section before SOLID
  Red→Green→Refactor, when to write tests in L0→L4, narrow exceptions defined
- blockchain.md: walking skeleton now test-first with Foundry/Anchor examples
  Minimum coverage: happy path + failure case + edge case + revert case
- registry.md: blockchain-dapp entry has test-first mandate

### Why this matters
Kent Beck: "TDD is not about testing. It's about design."
Code written after tests is harder to test — it wasn't designed to be testable.
Uncle Bob: "The only way to go fast is to go well."
Fowler: Internal quality pays off in weeks. Test-first IS internal quality investment.

## [0.7.3] — 2025-06 — Full file audit pass
### Fixed
- code-health.md: was orphaned (not in SKILL.md) — now referenced in Core references
- code-health.md: clarified relationship with code-quality.md (tactical vs strategic)
- boundaries.md: added Boundary Rule 4 detailed explanation + code example
- levels.md: added Ubiquitous Language requirement before L0
- examples/news-crawler-CLAUDE.md: added Ubiquitous Language table + Shipright state section
- prompts.md: L0 prompt now includes UbiqLang + registry + state section steps
- stacks/nodejs.md: added Ubiquitous Language guidance
- stacks/python.md: added Ubiquitous Language guidance

### Audit result: 14/14 checks passing after fixes

## [0.7.2] — 2025-06 — Learned from real production custodial wallet
### Research source
Real multi-chain custodial payment hub (EVM/SOL/TRON/TON/SUI/NEAR) analysis.

### Added
- blockchain.md: Custodial wallet deep section — 6th boundary rule (private key lifecycle)
- blockchain.md: Idempotency is structural (DB/Redis, never in-memory Map)
- blockchain.md: Financial state machine pattern (explicit states, logged transitions)
- blockchain.md: Scheduler as domain operation (lock + session audit + chunk processing)
- blockchain.md: Blockchain RPC = third-party API (IPayoutProvider + factory pattern)
- blockchain.md: Confirmation strategy per chain (EVM/SOL/TRON/TON/SUI)
- blockchain.md: Nonce management for concurrent EVM payouts
- blockchain.md: Fund sweep pattern with edge cases
- registry.md: custodial-wallet-specific rules block in blockchain-dapp entry
- prompts.md: Financial/custodial wallet prompts (signing, state machine, idempotency, scheduler, nonce)
- boundaries.md: Rule 4 — Adapter/ACL pattern with examples and detection signals

### Fixed
- prompts.md: version updated to v0.7.2 (was stuck at v0.5.9)
- CHANGELOG: rebuilt to remove duplicated entries

---

## [0.7.1] — 2025-06 — Blockchain projects
### Added
- references/stacks/blockchain.md (338 lines) — blockchain project support
  Chain-specific: EVM/Solidity, Solana/Anchor, TON/Tact, SUI/Move
  Security: OWASP Smart Contract Top 10, mandatory tools, audit strategy by TVL
  Walking skeleton with testnet phases and audit gate
  Honest limit: "No AI tool replaces formal security audit. $3.35B lost 2025."
- registry.md: blockchain-dapp entry

---

## [0.7.0] — 2025-06 — Project Brain OS
### Added
- references/registry.md — Layer 2: project type → curated skill pack
  Entries: web-api, rag-pipeline, chatbot-telegram-discord, browser-extension, ai-agent, full-stack-web, cli-tool
- CLAUDE.md Shipright state section — persistent state across sessions
- Working context: detect installed skills + project state + last commit
- Session-start: 3 checks (read constitution, assess skills, note missing)
- Branch E: 30-second resume when state exists

### Changed
- SKILL.md: complete rewrite as "Project Brain OS" (354→276 lines, ~2,600 tokens)
- Branch A: registry integration + state writing + Q2b Ubiquitous Language
- Branch B: state check first + domain term drift detection + quality gate expanded
- Branch E: state-first orient vs git-fallback
- stacks/ai-projects.md: slimmed 490→60 lines (registry routing)
- onboarding.md: state check before question

---

## [0.6.1] — 2025-06 — Three masters: Evans + Uncle Bob + Fowler
### Added
- references/code-quality.md (391 lines) — unified quality enforcement
  Evans (DDD): Ubiquitous Language, Entities, Value Objects, Aggregates, ACL = Boundary Rule 4
  Uncle Bob (SOLID): 5 checkpoints with AI tendency notes
  Fowler: 7 smell catalog, compound engineering
  Quality Gate: DDD + SOLID + Fowler checklist before every commit

### Changed
- Branch A: Q2b extracts Ubiquitous Language at intake
- Branch B: quality gate extended with DDD + SOLID + Fowler
- Branch D: Q3 identifies specific Fowler smell before refactoring
- SKILL.md: code quality section added, Evans/DDD in boundaries rationale
- l0-templates.md: Ubiquitous Language section added to CLAUDE.md template

---

## [0.6.0] — 2025-06 — Clarified agent-skills fit for AI projects
### Changed
- SKILL.md: addyosmani covers infrastructure code (adapters, handlers, CI/CD)
  addyosmani does NOT cover: evaluation loop, RAG metrics, LLM cost tracking
  Shipright AI files fill this gap
- Research: RAGAS, datadog-labs/dd-llmo-* for AI-specific concerns

---

## [0.5.9] — 2025-06 — Audit & sync pass
### Fixed
- CRITICAL: ai-projects.md existed but never referenced in SKILL.md
- ai-projects.md and ai-rag.md overlap resolved (ai-projects.md = entry point + routing)
- Discord Gateway vs HTTP webhook confusion clarified in chatbot-platforms.md
- l0-templates.md: AI/LLM conventions section added
- prompts.md: version number updated

---

## [0.5.8] — 2025-06 — AI Chatbot Telegram/Discord
### Added
- references/stacks/chatbot-platforms.md (643 lines)
  Platform Adapter Pattern, NormalizedMessage, BotResponse, ConversationState
  TelegramAdapter (grammy) + DiscordAdapter (discord.js)
  Conversation state in Redis, security rules, rate limits, auto-switch polling/webhook

---

## [0.5.7] — 2025-06 — AI/RAG project support
### Added
- references/stacks/ai-rag.md (429 lines)
  Framework decision tree, evaluation loop (replaces L2), RAGAS metrics
  3-layer testing, observability for AI, L4 signals, walking skeleton

---

## [0.5.6] — 2025-06 — Browser Extension MV3
### Added
- references/stacks/browser-extension.md (237 lines)
  Component model, extension boundary rules, MV3 gotchas (state/listeners/timers)
  L1 skeleton prompt, L2 tests with jest-webextension-mock, walking skeleton

---

## [0.5.5] — 2025-06 — Consistency pass
### Fixed
- SKILL.md: "3 boundaries" → "4 boundaries" throughout
- SKILL.md: observability.md + scaling-guide.md added to reference list
- Branch A gate: "3 boundary rules" → "4 boundary rules"
- l0-templates.md: Boundary 4 added to MVP CLAUDE.md template
- README: observability.md + scaling-guide.md added to structure list

---

## [0.5.4] — 2025-06 — Better auto-trigger
### Changed
- SKILL.md description field: more specific triggers/anti-triggers for auto-invoke

---

## [0.5.3] — 2025-06 — Observability retrofit
### Added
- observability.md: "Retrofitting observability into existing projects" section
  6-step surgical approach, one module per PR, AsyncLocalStorage auto-flow
- Branch B: observability retrofit special case trigger

---

## [0.5.2] — 2025-06 — Observability + scaling
### Added
- references/observability.md (638 lines): Correlation ID, structured logging, API tracing, alerts
- references/scaling-guide.md (389 lines): 3-stage playbook + Strangler Fig templates

---

## [0.5.0] — 2025-06 — English-first + publish-ready
### Breaking change
- All user-facing content converted to English
- Language note: "Respond in user's language" — skill language ≠ response language

### Added
- CONTRIBUTING.md

### Removed
- references/domain-thinking.md (orphaned)
- references/error-handling.md (orphaned)

### Changed
- README: tagline → "Ship your MVP fast. Grow it right."
- taste-skill section slimmed, pointer to ui-design.md

---

## [0.4.4] — 2025-06 — Complexity-based activation
### Added
- Feature complexity classification in Branch B: Tier S/M/L/XL
  Tier S (1 file): no agent-skills
  Tier M (2–5 files): tdd + review
  Tier L (5–10 files): spec → /build auto → review
  Tier XL (10+ files): full lifecycle

---

## [0.4.3] — 2025-06 — taste-skill ecosystem mapping
### Added
- references/ui-design.md: page type → correct skill → dials → anti-slop rules

---

## [0.4.2] — 2025-06 — Third-party API + Boundary 4
### Added
- references/third-party-apis.md: Adapter pattern, 3-layer testing, resilience
- Boundary rule 4 added throughout
- Q5b in Branch A: detect third-party APIs at intake

---

## [0.4.1] — 2025-06 — Update system
### Added
- hooks/check-update.sh: SessionStart update checker
- Install via git clone (enables update notifications)

---

## [0.4.0] — 2025-06 — Mission reframe
### Changed
- Tagline: "Ship your MVP fast. Grow it right."
- MVP mode vs Production mode in Branch A
- Stage-based addyosmani/agent-skills install guide
- Walking skeleton pattern

---

## [0.3.2] and earlier — Initial development
- Basic 6-branch routing, L0→L4 tree, boundary rules, example outputs
