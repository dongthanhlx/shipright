# Shipright Registry
# Two dispatch paths: (1) trigger index below — the PRIMARY path, activate by signal;
# (2) project-type packs — the secondary heuristic for what to pre-install for a known type.
# Load only the trigger row(s) that fired + the one project-type entry (~300 tokens each).

---

## Trigger index — capability/signal → skill (dispatch by trigger, not by stage)

Activate a skill the MOMENT its trigger appears, regardless of lifecycle phase. Stage is only
the default heuristic (a payment MVP needs security on day one; a read-only Growth app may not).

| Trigger / signal happening now | Activate | Where |
|---|---|---|
| Any bug / unexpected behavior | debugging-and-error-recovery | addyosmani |
| Writing logic or changing behavior | test-driven-development (+ references/testing.md strategy) | addyosmani |
| Tests feel brittle / over-mocked / "what should I test?" | (shipright built-in) | references/testing.md |
| Feature touches 2+ files | incremental-implementation | addyosmani |
| Before merging Tier M+ | code-review-and-quality | addyosmani |
| Tier L/XL with unclear requirements | spec-driven-development | addyosmani |
| Auth / payments / untrusted input appears — in ANY branch, incl. a bug fix or refactor | `/security-review` (BUNDLED, free, always there) + security-and-hardening if installed + `references/security.md` spine | bundled + addyosmani |
| API/interface contract being defined (a one-way door once a consumer exists) | api-and-interface-design | addyosmani |
| Irreversible / security-sensitive decision, or confidence in unfamiliar code | doubt-driven-development — a fresh-context adversarial review; the second opinion a one-way door deserves | addyosmani + references/judgment.md |
| Need the authoritative API/framework behavior, not remembered patterns | source-driven-development (grounds decisions in official docs). Note the tension with `third-party-apis.md` §Layer-1: for a 3rd-party API, docs are the *starting* point — you still call the real sandbox and save fixtures | addyosmani |
| Prod behavior invisible ("can't tell what happened") | observability-and-instrumentation | addyosmani |
| A dependency can take the system down | (shipright built-in) | references/resilience.md |
| Multiple devs, each owning module(s), in parallel | (shipright built-in) | references/team-scale.md |
| A settled decision turned out wrong / need CI architecture governance | (shipright built-in) | references/evolutionary-architecture.md |
| p95 latency / DB CPU over target | (shipright built-in) | references/performance.md |
| Building a user-facing UI page | taste-skill (per page type) | references/ui-design.md |
| Dashboard / admin / data-heavy UI | vercel-labs/agent-skills | vercel-labs |
| Redesigning EXISTING UI ("looks bad/dated/amateur") | `redesign-existing-projects` (audit FIRST, never restyle blind) | Branch D §Step 0 EXPERIENCE track + references/ui-design.md |
| Visual defect: hierarchy / contrast / spacing in shipped UI | `redesign-existing-projects` (same skill — its audit covers this) | Branch C + references/ui-design.md |
| Need a logo / brand direction | `brandkit` (directions, not a final mark) | references/ui-design.md §Logo |
| Any chart, graph, dashboard viz | dataviz (ships with Claude Code — no install) | references/ui-design.md |
| Writing / reviewing React or Next.js code | `vercel-react-best-practices` (waterfalls, bundle size, server-vs-client, re-renders) | vercel-labs |
| Need to SEE it run: verify UI in a real browser, capture console/network, confirm a visual fix | `browser-testing-with-devtools` (needs the chrome-devtools MCP server) | addyosmani |
| A one-way door was just decided / a public API changed | `documentation-and-adrs` (shipright decides WHAT is irreversible; the skill records it properly) | addyosmani |
| Removing/sunsetting an old API, migrating users off an implementation | `deprecation-and-migration` | addyosmani + references/requirement-drift.md |
| A fitness function / arch test must actually run on every commit | `ci-cd-and-automation` | addyosmani + references/evolutionary-architecture.md |
| Building / packaging a desktop (PC) app (Electron / Python) — choosing the shape, the window, .exe/installer, auto-update | (shipright built-in) | references/desktop.md (+ stacks/electron.md or stacks/python-desktop.md) |
| Driving many accounts / browser sessions from one PC | (shipright built-in) — official API first; automation only as a fallback, raised as viability | references/desktop.md §10 + references/product-judgment.md §1 |
| RAG retrieval/prompt change to evaluate | RAGAS | `pip install ragas` |
| Agent trajectory to evaluate | DeepEval / Confident-AI | — |
| LLM tracing needed | LangSmith / Arize Phoenix | — |

**Bundled with Claude Code — never suggest installing these** (`/security-review` · `/code-review` ·
`/run` · `/debug` · `/claude-api` · `dataviz` · `artifact-design` · `/simplify`). No install, so they are
the FIRST thing to reach for. Normally present but **not guaranteed** — the set varies by version and
`disableBundledSkills` / `skillOverrides` can remove any of them, so confirm against this session's
available-skills list rather than trusting this roster. `/code-review` and `/verify` are user-invoke-only:
ask the user to run them; don't claim the gate is closed yourself. See SKILL.md §Ecosystem dispatch.

Shipright already covers — do NOT load these: interview-me, idea-refine (→ Branch A intake);
frontend-ui-engineering (→ taste-skill); performance-optimization (→ L4 + performance.md);
code-simplification (→ code-quality.md Fowler smells + code-health.md Ousterhout over-extraction, and
Claude Code ships `/simplify`); planning-and-task-breakdown (→ Branch B complexity tiers +
spec-driven-development). Loading a skill you would duplicate spends context and dilutes reasoning.

**Only the skills in the session-start probe list are detected automatically** — the long tail above is
checked on demand, at the moment its trigger fires. Probing everything at every session start would cost
more context than it saves. When a trigger fires: check, then either activate, or **offer the install and
use it this session on consent** (SKILL.md Check 3 — a skill added mid-session works immediately, no
restart). Never assume presence; never install without asking.

### Install recipes — verify the name, install, re-verify

```bash
REPO=https://github.com/addyosmani/agent-skills     # or Leonxlnx/taste-skill · vercel-labs/agent-skills

npx -y skills@latest add $REPO --list                        # exact INSTALL names — installs nothing
npx -y skills@latest add $REPO -y -g --skill "<install-name>"  # -g = user-level (default is project-level)
grep -RqsE '^name: *"?<install-name>"? *$' ~/.claude/skills .claude/skills --include=SKILL.md \
  && echo INSTALLED || echo FAILED                           # re-verify — never assume it worked
```

- **Always `--list` first for taste-skill**: its folder names differ from its install names, and passing
  the folder name fails. `--list` is the source of truth (it prints what `--skill` accepts).
- **`-g` (user-level) is the default choice** — same place shipright lives, no repo change. Drop `-g`
  only when the whole team should get the skill; that writes into `.claude/skills/` and gets committed.
- **`skills use <pkg>@<skill>`** borrows a skill's guidance without installing anything — the right
  option for a one-off when the user doesn't want another skill on disk.
- The CLI detects an agent environment and runs non-interactively; it will not hang on a prompt.

Default ladder when no specific trigger has fired yet (by lifecycle phase):
SEED debug · VALIDATE +tdd/incremental/review · HARDEN +spec/security/observability · SCALE +specialized.

---

## web-api
HTTP REST API, GraphQL, or backend service. No AI components.

```
install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, test-driven-development, code-review-and-quality]
      when: traction stage
    - addyosmani/agent-skills
      skills: [spec-driven-development, security-and-hardening]
      when: growth stage
  optional:
    - addyosmani/agent-skills
      skills: [api-and-interface-design]
      when: external consumers exist
  mvp-only:
    - addyosmani/agent-skills
      skills: [debugging-and-error-recovery]
      when: always

tested-with: addyosmani/agent-skills commit 2025-06
load: references/stacks/<language>.md — the project's language file (Node/Python/Go/PHP): compile-time
      boundary enforcement, timeout/context idioms, error taxonomy, language security footguns.
      Load it before the first implementation, not just at scaffold time.

shipright-adds-to-CLAUDE:
  boundary-1: "Service never imports db — grep check: grep -r 'shared/db' src/modules/ must be empty"
  boundary-2: "Handler zero domain if/else — only parse → call service → format"
  debt-signals:
    - "TODO[rps>500]: add Redis caching layer"
    - "TODO[p95>200ms]: add query index + connection pool"
    - "TODO[team>5]: add module ownership matrix"
  clean-code:
    - "Functions max 20 lines. Files max 300 lines."
    - "Names reveal intent. No Manager, Handler, Utils when domain term exists."
```

---

## rag-pipeline
RAG system, knowledge base, document Q&A, semantic search.

> **Exploration note:** LLM API (OpenAI/Anthropic/etc.) must be explored before writing
> LLM module. Save real responses including token usage fields, error formats,
> rate limit headers. LLM response shapes change between model versions.

```
install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, test-driven-development, code-review-and-quality]
    - RAGAS: pip install ragas
      when: evaluation needed (always — eval-first policy)
  optional:
    - LangSmith OR Arize Phoenix (LLM tracing/observability)
    - NVIDIA/rag-blueprint (NVIDIA stack)
    - datadog-labs/dd-llmo-eval-bootstrap (production LLM eval)

tested-with: RAGAS 0.2+, LangChain 0.3+, LlamaIndex 0.11+
load: references/stacks/ai-projects.md — the LLM boundary (Boundary 4 for AI), THEN
      references/stacks/ai-rag.md — RAG deep dive (eval loop, chunking, vector DB, retrieval metrics)

framework-decision:
  retrieval-first: LlamaIndex
  orchestration-first: LangChain + LangGraph
  both: LlamaIndex ingestion + LangChain orchestration
  enterprise: Haystack

shipright-adds-to-CLAUDE:
  llm-boundary: "All LLM calls in llm/ module only. Never in service or handler. (Boundary 4 for AI)"
  llm-boundary-b: "Raw LLM response never leaves ResponseAdapter. Service receives typed AIResponse."
  llm-timeout: "Every LLM call has a timeout + fallback (Boundary 5). Agents also cap max iterations."
  eval-policy: "Run eval suite before merging any retrieval or prompt changes."
  cost-tracking: "Every LLM call logs: model + input_tokens + output_tokens + cost_usd + latency_ms"
  chunking-adr: "Record in ARCHITECTURE.md: chunk_size=[N], overlap=[N], strategy=[why]"
  debt-signals:
    - "TODO[faithfulness<0.8]: tune retrieval pipeline"
    - "TODO[hit-rate<0.85]: review chunking strategy"
    - "TODO[p95>5s]: add semantic caching"
  non-determinism: "Tests assert structure/constraints, never exact LLM output strings."
```

---

## chatbot-telegram-discord
AI chatbot integrated with Telegram and/or Discord.

```
install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, security-and-hardening, code-review-and-quality]
  stack-telegram:
    nodejs: npm install grammy
    python: pip install python-telegram-bot
  stack-discord:
    nodejs: npm install discord.js
    python: pip install discord.py
  optional:
    - datadog-labs/dd-llmo-eval-bootstrap (if AI chatbot)
    - RAGAS (if RAG-powered chatbot)

tested-with: grammy 1.x, discord.js 14.x, python-telegram-bot 20.x
load: references/stacks/chatbot-platforms.md — PlatformAdapter (the ACL for Telegram/Discord),
      webhook vs polling, per-platform limits. AI-powered bot → also stacks/ai-projects.md

platform-decision:
  polling: development / no SSL / behind NAT
  webhook: production / VPS / Railway / Fly.io
  note: "Discord uses WebSocket Gateway, NOT HTTP webhook for bot messages"

shipright-adds-to-CLAUDE:
  boundary-platform: "Platform code ONLY in adapters/ folder. Never in handlers or services."
  boundary-state: "Conversation state in Redis/DB. Never module-level variables (SW terminates)."
  security:
    - "Bot token in env vars only. Never in code or logs."
    - "Admin commands: whitelist by userId (not username — usernames change)."
    - "Validate webhook signature before processing (Telegram: X-Telegram-Bot-Api-Secret-Token)"
    - "Sanitize user input before system prompt injection"
  rate-limits:
    - "Telegram: 30 msg/sec global, 1 msg/sec per chat"
    - "Discord: 5 req/sec per bot"
    - "Send typing indicator before responses > 0.5s"
  debt-signals:
    - "TODO[deployed]: switch from polling to webhook"
    - "TODO[users>100]: add Redis for conversation state persistence"
    - "TODO[messages>1000/day]: add message queue"
```

---

## browser-extension
Chrome/Firefox extension using Manifest V3.

```
install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, test-driven-development]
  testing:
    - jest-webextension-mock: npm install --save-dev jest-webextension-mock

tested-with: Chrome MV3, Firefox MV3 (via Extension.js)
load: references/stacks/browser-extension.md — MV3 architecture, message passing, storage boundaries,
      and the content-script security model (a content script trusts a hostile DOM — see security.md)

tooling:
  recommended: Extension.js (Chrome + Firefox from same source)
  install: npx extension create my-extension

shipright-adds-to-CLAUDE:
  boundary-sw: "Service Worker: NO DOM, NO module variables (state lost on terminate)"
  boundary-content: "Content Script: NO external fetch → message to service worker"
  boundary-state: "All state via chrome.storage.local/sync. Never in JS variables."
  mv3-gotchas:
    - "ALL listeners registered SYNCHRONOUSLY at top level of background.js"
    - "No setTimeout/setInterval → use chrome.alarms API"
    - "Async message response: return true from onMessage listener"
    - "No inline scripts in HTML (CSP violation)"
  debt-signals:
    - "TODO[publish]: add privacy policy URL to manifest"
    - "TODO[v2]: request minimal permissions audit"
```

---

## ai-agent
LLM-powered agent with tool calling, planning, multi-step reasoning.

```
install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, spec-driven-development, code-review-and-quality]
  evaluation:
    - DeepEval OR Confident-AI (agent trajectory evaluation)
    - Note: RAGAS is for RAG, not agent evaluation — different metrics
  optional:
    - datadog-labs/dd-llmo-eval-trace-rca (root cause analysis)
    - LangSmith (LLM tracing with agent trajectory)

tested-with: LangGraph 0.2+, AutoGen 0.4+

load: references/stacks/ai-agent.md — full guide (workflow-vs-agent, the 5 patterns, agent as a
      controllable state machine, when multi-agent helps, resilience, guardrails, trajectory eval)

framework-decision:
  single-agent: LangChain + tool calling
  multi-agent: LangGraph (state machines) or AutoGen (conversational)
  research: CrewAI (role-based agents)

shipright-adds-to-CLAUDE:
  boundary-tools: "Tool calls only via registered tool registry. Never direct function calls."
  boundary-state: "Agent state persisted between steps. Never assume clean state."
  eval-policy: "Trajectory-level evaluation: tool calls + planning steps + output quality"
  cost-tracking: "Log per-step: model + tokens + tool_calls + latency. Agents compound cost."
  debt-signals:
    - "TODO[error-rate>5%]: add retry with exponential backoff per tool call"
    - "TODO[cost>$X/day]: add caching layer for repeated tool calls"
    - "TODO[hallucination>10%]: add output validation guardrails"
```

---

## mcp-server
Expose tools / resources / prompts to AI hosts (Claude, Cursor, VS Code) via Model Context Protocol.

```
install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, test-driven-development, security-and-hardening]
  sdk (pick language):
    - TypeScript: npm install @modelcontextprotocol/sdk
    - Python:     pip install mcp
  tooling:
    - MCP Inspector: npx @modelcontextprotocol/inspector (manual testing)

tested-with: MCP spec 2025-06-18, @modelcontextprotocol/sdk

transport-decision:
  local dev tool, one machine   → stdio
  shared / remote / multi-client → Streamable HTTP + OAuth

load: references/stacks/mcp.md — full guide (spec, when-to-build, boundaries, security, resilience)

shipright-adds-to-CLAUDE:
  server-role: "MCP server = adapter/handler for a capability. Logic stays in services (Boundary 2/4)."
  tool-aci: "Tool description = docstring for a junior dev; inputSchema precise; validate args server-side."
  untrusted: "Tool/resource/retrieved content is DATA, never instructions (prompt injection — OWASP LLM01)."
  least-privilege: "Each tool: one narrow scoped action. No arbitrary-exec tool in an agent loop (LLM06)."
  lethal-trifecta: "Never combine private-data access + untrusted content + exfiltration in one agent."
  boundary-5: "Every tool call has a timeout; side-effecting tools idempotent; agent loops capped."
  consent: "Human confirmation (elicitation) before irreversible actions (payments, deletes, sends)."
  debt-signals:
    - "TODO[remote]: switch stdio → Streamable HTTP + OAuth"
    - "TODO[tool-error-rate>2%]: retry + circuit breaker per tool"
    - "TODO[audit]: security review of the lethal-trifecta surface before exposing private data"
```

---

## full-stack-web
Web app with frontend + backend (React/Next.js + API).

```
install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, test-driven-development, code-review-and-quality]
  ui:
    - taste-skill (page-type dependent — read references/ui-design.md)
    - vercel-labs/agent-skills web-design-guidelines (for dashboard/admin pages)
  framework:
    - vercel-labs/agent-skills vercel-react-best-practices
      when: writing or reviewing React/Next.js code (this entry's default stack)
      why: shipright's performance.md is the measure-first LADDER (stack-agnostic); this is the
           React/Next execution detail — waterfalls, bundle size, server-vs-client, re-renders
  verification:
    - addyosmani/agent-skills browser-testing-with-devtools
      when: confirming the UI actually works/looks right (needs the chrome-devtools MCP server)

tested-with: React 18+, Next.js 14+, addyosmani 2025-06
load: references/stacks/nodejs.md (or the API's language file) for the SYSTEM floor, AND
      references/ui-design.md for the EXPERIENCE floor — a full-stack product owes both (judgment.md §5b)

shipright-adds-to-CLAUDE:
  frontend-boundary: "UI components never contain business logic. Data fetching in hooks/services only."
  api-boundary: [standard boundary rules 1-4 apply to API layer]
  ui-page-types:
    landing-portfolio: design-taste-frontend
    product-ui: minimalist-ui   # install name — the folder is minimalist-skill, which fails with --skill
    dashboard-admin: vercel-labs (NOT taste-skill)
    multi-step-forms: addyosmani/api-and-interface-design
  debt-signals:
    - "TODO[users>1000]: add CDN + static asset optimization"
    - "TODO[team>3]: add component documentation (Storybook)"
```

---

## cli-tool
Command-line tool or script. Minimal architecture needed.

```
install:
  optional:
    - addyosmani/agent-skills
      skills: [test-driven-development]
      when: complex business logic exists

tested-with: Node.js 20+, Python 3.11+
load: references/stacks/<language>.md — the CLI's language file. A CLI has no UI/UX floor but still
      owes the system floor when it grows past a script (judgment.md §5)

note: "CLIs rarely need full DDD/SOLID treatment. Flat functions are often correct."

shipright-adds-to-CLAUDE:
  minimal: "Single responsibility per command. Parse args → validate → execute → output."
  testing: "Test each command handler independently. Mock I/O."
  debt-signals:
    - "TODO[commands>10]: extract command registry pattern"
    - "TODO[shared-logic>3-commands]: extract shared service"
```

---

## desktop-app
A desktop (PC) application built the modern way — Electron + TypeScript by default, or Python (PySide6, or a
Python sidecar behind Electron). Local tools, multi-account managers — anything whose job needs the machine: local files,
a local browser engine, offline work, per-machine state, OS integration.

```
decide-at-L0 (one-way door — record ADR-001):
  the shape: Electron+TS (default) | Electron + Python sidecar | PySide6 — and OPERATE vs ACT → desktop.md §1
  the UI-framework licence (e.g. Qt LGPL vs commercial, PyQt GPL)     → a licence is a one-way door too

install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, test-driven-development]
  when-secrets-or-accounts:
    - addyosmani/agent-skills
      skills: [security-and-hardening]      # plus /security-review (bundled) on every such diff
  per-stack tooling: desktop.md §7 (packaging + signed updates) and §9 (mechanics)

tested-with: Electron (current stable), Node 22 LTS, TypeScript 5.x, Python 3.12–3.13, PySide6 6.x, Nuitka 2.x
load: references/desktop.md — ALWAYS (stack choice, UI-thread contract, process model, secrets, signing,
      updates, resilience, multi-account apps). Then the shape's mechanics:
      Electron → stacks/electron.md + stacks/nodejs.md; Python → stacks/python-desktop.md + stacks/python.md.
      The window owes the experience floor too → references/ui-design.md (judgment.md §5b).

shipright-adds-to-CLAUDE:
  stack-adr: "Shape = [Electron+TS | +Python sidecar | PySide6] because [reason] (ADR-001). A rewrite to change."
  ui-thread: "The UI thread never blocks (> ~16 ms → worker). Workers never touch UI objects."
  ui-boundary: "view-models are the handler layer. Services/repositories never import the UI framework."
  processes: "Hang-prone or untrusted work runs in supervised worker processes; IPC is validated."
  data: "Runtime data under the per-user app-data dir via the OS API. Never the install dir."
  secrets: "OS secret store holds the key; data envelope-encrypted. Nothing sensitive in settings or logs."
  isolation: "One isolated session per account. One account's failure pauses that account only."
  ship: "Signed binaries + installer, verified auto-update, per-user install. CI launches the packaged build."
  debt-signals:
    - "TODO[freeze>100ms]: profile the UI thread"
    - "TODO[first-external-user]: code signing + signed auto-update"
    - "TODO[rss-grows-daily]: release sessions/pages/handles/listeners"
```

---

## How to use this registry

1. Identify project type from the list above
2. Load only that entry (not the full file)
3. Run install commands for required skills
4. Copy shipright-adds-to-CLAUDE rules into your CLAUDE.md
5. Note tested-with versions — if your skill is newer, behavior may differ

If your project type is not listed:
- Use web-api as base template
- Add project-specific rules to CLAUDE.md manually
- Open a PR to add your project type to this registry

---

## blockchain-dapp
DApp, smart contract, wallet, DEX, or any project involving on-chain code.

```
install:
  off-chain (always):
    - addyosmani/agent-skills
      skills: [incremental-implementation, test-driven-development, security-and-hardening]
  smart-contract tooling (install per chain):
    - EVM: Foundry (forge/cast/anvil) — forge.sh
    - EVM: Slither — pip install slither-analyzer
    - Solana: Anchor — avm install latest
    - TON: Blueprint — npm create ton@latest
    - SUI: SUI CLI — brew install sui

tested-with: Foundry 2025-06, Anchor 0.30+, OpenZeppelin 5.x

CRITICAL:
  Smart contract code requires professional audit before mainnet.
  No AI tool (including Claude Code) replaces Slither + Foundry + human auditor.
  $3.35B lost in 2025: most from security design failures.
  Plan audit timeline: 4-12 week booking queue at major firms.

shipright-adds-to-CLAUDE:
  boundary-keys: "Private keys NEVER in source code, env vars, or logs"
  boundary-oracle: "Never single oracle source for financial data — Chainlink/Pyth"
  boundary-contracts: "All contract calls validate return values — never assume success"
  money-rule: "Token amounts in native units (wei/lamports). No floats for money."
  test-first: "Write failing test BEFORE implementation. Smart contracts have no undo button."
  security-gate: "Run slither + forge test before EVERY testnet deploy. Tests must GREEN first."
  audit-gate: "No mainnet without audit report + all critical/high fixed"
  debt-signals:
    - "TODO[tvl>$10k]: engage professional audit firm"
    - "TODO[tvl>$100k]: formal verification for critical invariants"
    - "TODO[launch]: bug bounty program via Immunefi"

custodial-wallet-specific:
  key-boundary: "Private key decrypted ONLY inside signing action — never passed between layers"
  idempotency: "All dedup checks in DB/Redis — never in-memory Map (lost on restart)"
  state-machine: "Every ticket: explicit states + logged transitions + terminal states immutable"
  scheduler: "Every scheduler: distributed lock + session audit + chunk processing"
  money: "Use Decimal.js/BigNumber for all amounts — never native JS number for money"
  sweep: "Fund sweep: lock account → check pending → sweep → unlock (atomic pattern)"
  nonce: "Concurrent EVM payouts: queue sequentially or use Redis nonce tracker"
  load: references/stacks/blockchain.md — custodial wallet section
```
