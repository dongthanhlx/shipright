# Shipright Registry v0.7.0
# Project type → curated skill pack + what shipright adds to CLAUDE.md
# Load only the entry matching your project type (each entry ~300 tokens)
# Format: type | install | tested-with | shipright-adds

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

framework-decision:
  retrieval-first: LlamaIndex
  orchestration-first: LangChain + LangGraph
  both: LlamaIndex ingestion + LangChain orchestration
  enterprise: Haystack

shipright-adds-to-CLAUDE:
  boundary-5: "All LLM calls in llm/ module only. Never in service or handler."
  boundary-5b: "Raw LLM response never leaves ResponseAdapter. Service receives typed AIResponse."
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

tested-with: React 18+, Next.js 14+, addyosmani 2025-06

shipright-adds-to-CLAUDE:
  frontend-boundary: "UI components never contain business logic. Data fetching in hooks/services only."
  api-boundary: [standard boundary rules 1-4 apply to API layer]
  ui-page-types:
    landing-portfolio: design-taste-frontend
    product-ui: minimalist-skill
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

note: "CLIs rarely need full DDD/SOLID treatment. Flat functions are often correct."

shipright-adds-to-CLAUDE:
  minimal: "Single responsibility per command. Parse args → validate → execute → output."
  testing: "Test each command handler independently. Mock I/O."
  debt-signals:
    - "TODO[commands>10]: extract command registry pattern"
    - "TODO[shared-logic>3-commands]: extract shared service"
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
  security-gate: "Run slither + forge test before EVERY testnet deploy"
  audit-gate: "No mainnet without audit report + all critical/high fixed"
  debt-signals:
    - "TODO[tvl>$10k]: engage professional audit firm"
    - "TODO[tvl>$100k]: formal verification for critical invariants"
    - "TODO[launch]: bug bounty program via Immunefi"

custodial-wallet-specific:
  boundary-6: "Private key decrypted ONLY inside signing action — never passed between layers"
  idempotency: "All dedup checks in DB/Redis — never in-memory Map (lost on restart)"
  state-machine: "Every ticket: explicit states + logged transitions + terminal states immutable"
  scheduler: "Every scheduler: distributed lock + session audit + chunk processing"
  money: "Use Decimal.js/BigNumber for all amounts — never native JS number for money"
  sweep: "Fund sweep: lock account → check pending → sweep → unlock (atomic pattern)"
  nonce: "Concurrent EVM payouts: queue sequentially or use Redis nonce tracker"
  load: references/stacks/blockchain.md — custodial wallet section
```
