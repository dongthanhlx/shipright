## Branch A — New project

> Read CLAUDE.md and ARCHITECTURE.md if they exist — skip intake if state section found.
> Language: respond in user's language. CLAUDE.md/ARCHITECTURE.md content stays English.

---

## Step 0 — Check existing state

If `## Shipright state` section exists in CLAUDE.md:
```
Read state section. Ask: "I see this project is at [Level], working on [module].
Continue from there, or start fresh intake?"
```
If no state → proceed to Step 1.

---

## Step 1 — Mode decision

```
"Validating an idea (ship fast, real users ASAP)?
 Or building a production-ready solution (team, timeline, requirements clear)?"

[A] Validate (MVP mode) — days, not weeks
[B] Production mode — planned sprints, full architecture
```

---

## Step 2 — Intake (one question at a time)

```
Q1: "Project name?"

Q2: "One sentence: '[Who] struggles with [what]'"

Q2b: "3–5 key terms your domain experts use?"
     → These become the Ubiquitous Language in CLAUDE.md
     → Claude uses ONLY these terms for class/method/variable names
     → Example: not 'User' but 'Subscriber'; not 'Item' but 'FeedArticle'

Q3: "Existing solution? Why build new?"

Q4: "How does it run?
     [A] HTTP API  [B] Cron/scheduled  [C] CLI  [D] Background worker  [E] Mix"

Q4b: "Uses LLMs or AI models?
     → YES: load references/registry.md — find rag-pipeline, chatbot-telegram-discord,
             or ai-agent entry. Load that entry only (~300 tokens)."

Q5 (MVP): "What must a user DO in version 1? One journey: '[User] does [X] to [achieve Y]'"
Q5 (Production): "Data profile: volume? read/write ratio? multi-tenant?"

Q5b: "Does the project integrate any third-party APIs?
     (e.g. RapidAPI, Stripe, Twilio, YouTube, OpenAI, SearchAPI, blockchain RPC...)
     → If YES: BEFORE writing any integration code, do Layer 1 Exploration:

     Phase A — Read docs first (before any API call):
       Create: api-exploration/[provider]/API-NOTES.md
       Document: auth method, every param (name/location/type/required/default/notes),
       what each key param does, response shape, error codes, rate limits.
       Question to answer: "What params control what I need? What are valid values?"

     Phase B — Setup Bruno + build request from docs knowledge:
       mkdir -p api-exploration/[provider-name]
       (Bruno: https://usebruno.com — local, git-friendly)
       Build request with REALISTIC test values from docs understanding.
       Not placeholder strings — actual values that test your use case.

     Phase C — Call sandbox, compare docs vs reality:
       Scenarios: happy path, missing optional params, each error case, rate limit
       Save responses: tests/fixtures/[provider]-success.json
                       tests/fixtures/[provider]-minimal.json
                       tests/fixtures/[provider]-error-[code].json
                       tests/fixtures/[provider]-rate-limit.json
       Note discrepancies: fields in response not in docs, type mismatches

     Phase D — Update API-NOTES.md with "Reality vs Docs" findings:
       Undocumented fields, wrong types, truly optional vs documented-optional

     Phase E — THEN write Adapter using fixtures as source of truth:
       Adapter normalizes raw response → domain type
       Unit tests use fixtures (no real API calls, runs offline)

     Load: references/third-party-apis.md for full Layer 1→2→3 strategy"

Q5c: "Need observability from day one?
     → Recommended for all projects with external APIs or async flows
     → YES: Correlation ID setup in references/observability.md"

Q6: "Stack? (Node.js/TS, Python, Go, undecided?)"
    → Load matching stack file for concrete prompts

Q7: "Most important constraint? (deadline, team size, must-have integration)"
```

After Q7 — synthesize with judgment, not just echo:
```
Project: [name] | Stack: [stack] | Mode: MVP/Production
Problem: [one sentence]
Domain terms: [list from Q2b — these go in CLAUDE.md]

[MVP] Walking skeleton = "[user journey from Q5]"
      Everything else → backlog

[Production] Irreversible decisions to get right upfront:
             core domain model, module boundaries, dependency direction

Risk I see: [specific]
Recommendation: [scope cut if deadline tight]

Ready to generate CLAUDE.md and ARCHITECTURE.md?
```

---

## Step 3 — Load registry entry

```
Identify project type from references/registry.md:
  web-api | rag-pipeline | chatbot-telegram-discord |
  browser-extension | ai-agent | full-stack-web | cli-tool

Load that entry only. Note:
  - Required skills to install
  - Shipright-adds-to-CLAUDE rules specific to this type
  - Tested-with versions for compatibility awareness
  - Project-type-specific debt signals
```

If skills required are not installed → mention once:
```
"Note: [skill] recommended for this project type.
 Install: [command]
 Proceeding without it — I'll guide manually for those parts."
```

---

## Step 4 — Generate constitution

### CLAUDE.md (always generated, content varies by mode)

**MVP version (~60 lines):**
```markdown
# CLAUDE.md — [project-name] (MVP v0.1)

## Project
[One sentence from Q2]

## Ubiquitous Language
| Term | Meaning | Not |
|---|---|---|
| [from Q2b] | [definition] | [generic alias to avoid] |

## The 4 boundaries (non-negotiable)
1. Dependencies inward only: [specific banned import for this project]
2. Each layer one job: [concrete example for this project]
3. No shared databases: [module names that must not share]
4. Adapter layer: [if external APIs — what the adapter is named]

## Clean Code rules
- Functions max 20 lines. Extract if longer.
- Names from Ubiquitous Language above. Never: Manager, Helper, Utils, Processor.
- No comment explaining WHAT — rename instead.

## Tech stack
[Stack, DB, test runner, key libs]

## Environment variables
[VAR_NAME] # description

## Tech debt log (MVP shortcuts — pay when trigger fires)
| Shortcut | Trigger |
|---|---|
| [from registry entry] | TODO[signal]: [action] |

## When to ask before doing
- Changing module's public interface (index.ts / __init__.py exports)
- Adding dependency not in stack above
- Creating module not in ARCHITECTURE.md

## Shipright state
Level: L0
Active: constitution created
Next: create L1 skeleton
Last updated: [date]
Skills active: [installed skills]
```

**Production version:** Full CLAUDE.md per `references/l0-templates.md`
(adds: error taxonomy, idempotency decisions, all ADRs, module ownership)

### ARCHITECTURE.md (generated per mode)

**MVP version (~40 lines):**
- ASCII flow diagram (core path only)
- 2–3 modules max with public API
- Core domain type (Entity/VO — must be right, irreversible)
- 1 ADR for hardest decision

**Production version:** Full per `references/l0-templates.md`

---

## Step 5 — After constitution

### MVP mode → Walking Skeleton

```
1. Walking skeleton = the one user journey from Q5

2. [addyosmani installed] → activate incremental-implementation + test-driven-development
   [not installed] → implement inside-out: repository → service → handler
   Tests: enough to prove skeleton works. Not edge cases.

3. SHIP GATE:
   "Can a real user complete [journey from Q5] right now?"
   YES → deploy, put in front of real users
   NO  → skeleton not done, no new features

4. Update Shipright state in CLAUDE.md:
   Level: L1 (skeleton) or L3 (skeleton+validate)
   Next: [specific action]
```

### Production mode → Full tree

L0 → L1 Skeleton → L2 Interfaces + RED tests → L3 Implement loop

[addyosmani installed]:
- L1: incremental-implementation
- L2: api-and-interface-design → test-driven-development
- L3: incremental-implementation + test-driven-development per task
- Review: code-review-and-quality before merge
- Ship: shipping-and-launch

---

## Gate — constitution done when:

- [ ] Both files project-specific (not generic template)
- [ ] Ubiquitous Language section has 3+ domain terms
- [ ] 4 boundary rules with project-specific banned examples
- [ ] Core domain type defined (Entity vs Value Object — must be right)
- [ ] Registry entry loaded, required skills noted
- [ ] Shipright state section written to CLAUDE.md
- [ ] MVP: walking skeleton identified as 1 user journey
- [ ] Production: all modules, error taxonomy, idempotency decisions

> Example: `references/examples/news-crawler-CLAUDE.md` + `references/examples/news-crawler-ARCHITECTURE.md`
