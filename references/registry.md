# Shipright Registry
# Two dispatch paths: (1) the trigger index below — the PRIMARY path, activate by signal;
# (2) project-type packs — the secondary heuristic for what to pre-install for a known type.
# This file is the index and the install recipes (~2k tokens). Each pack is its own file under
# references/registry/ (~400–650 tokens) — load the ONE that matches, never all of them.

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
| About to commit / push / open or merge a PR / tag / discard changes / rewrite history / resolve a conflict | (shipright built-in: the consent ladder + the project's Git policy) — `git-workflow-and-versioning` may execute the mechanics if installed; it never decides when to ask | references/git.md |
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

## Project-type packs — load ONE

Identify the type, then load only its file. Each pack: what to install and when, tested-with
versions, what shipright adds to CLAUDE.md, and the `load:` line for the stack/architecture refs.

| Type | Use for | Pack |
|---|---|---|
| `web-api` | HTTP REST API, GraphQL, or backend service. No AI components. | `references/registry/web-api.md` |
| `rag-pipeline` | RAG system, knowledge base, document Q&A, semantic search. | `references/registry/rag-pipeline.md` |
| `chatbot-telegram-discord` | AI chatbot integrated with Telegram and/or Discord. | `references/registry/chatbot-telegram-discord.md` |
| `browser-extension` | Chrome / Firefox / Safari extension, Manifest V3, TypeScript. | `references/registry/browser-extension.md` |
| `ai-agent` | LLM-powered agent with tool calling, planning, multi-step reasoning. | `references/registry/ai-agent.md` |
| `mcp-server` | Expose tools / resources / prompts to AI hosts (Claude, Cursor, VS Code) via Model Context Protocol. | `references/registry/mcp-server.md` |
| `full-stack-web` | Web app with frontend + backend (React/Next.js + API). | `references/registry/full-stack-web.md` |
| `cli-tool` | Command-line tool or script. Minimal architecture needed. | `references/registry/cli-tool.md` |
| `desktop-app` | Desktop (PC) app — Electron + TypeScript by default, or Python (PySide6, or a sidecar behind Electron); local tools, multi-account managers | `references/registry/desktop-app.md` |
| `blockchain-dapp` | DApp, smart contract, wallet, DEX, or any project involving on-chain code. | `references/registry/blockchain-dapp.md` |

## How to use this registry

1. Dispatch by trigger first (the index above) — a pack is a starting set, not a substitute
2. Identify the project type from the table, then load only that pack's file
3. Offer the installs it lists, on consent (§Install recipes)
4. Copy its shipright-adds-to-CLAUDE rules into the project's CLAUDE.md
5. Note tested-with versions — if an installed skill is newer, behavior may differ

If your project type is not listed:
- Use `web-api` as the base pack
- Add project-specific rules to CLAUDE.md manually
- Open a PR adding `references/registry/<type>.md` and a row in the table above
