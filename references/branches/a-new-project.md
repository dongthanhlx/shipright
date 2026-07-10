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

> Intake is a CONVERSATION, not a form. Understand the idea before advising mechanics; carry the
> technical judgment yourself (never quiz the user on decisions that are shipright's job); reflect
> understanding back before building. Masters: Rob Fitzpatrick (*The Mom Test* — ask about their
> problem, not your solution; open, non-leading questions), Clayton Christensen (Jobs To Be Done),
> Eric Evans (the early talk is domain discovery, not a quiz), Ryan Singer (Shape Up — appetite),
> and the `interview-me` philosophy (one real question at a time until ~95% sure of intent).
>
> **This serves MVP-first, not against it.** Deep UNDERSTANDING (converges fast) ≠ deep BUILD
> (still deferred) ≠ long CONVERSATION (kept short for MVP). You can't cut to the true MVP core
> without understanding the real job — that is the whole point. The output is always an MVP scope.

---

## Step 1 — Understand the idea and the job (mostly listen)

Do NOT open with "MVP or production?" or "what stack?". Open with the problem. Ask ONE real
question at a time; the next depends on the last. Adapt. Stop when ~95% sure you understand intent.

```
Open (pick the natural one, in the user's words — not a script):
  "Tell me what you're trying to build — and what's the problem it solves for you?"

Then dig, adaptively, toward these (shipright's INTERNAL checklist — not a battery to fire):
  • Job to be done (Christensen): what is the user really hiring this to do? Dig ONE level under
    the stated ask — people ask for a solution ("a dashboard") when the job is different ("know X
    to decide Y"). Separate the request from the need.
  • Who it's for, and why now.
  • What success/"done" looks like — in their terms, concretely (a story, not an opinion).
  • Appetite / stakes (Shape Up): how much is this worth — a weekend throwaway, or a bet? This
    sets both the MODE and how deep to dig. It is inferred here, never asked as a cold binary.
  • Who's building it — solo, or a team where people own different parts? (This one you ASK — only
    the user knows.) It routes the shape: solo → keep it lean; multi-dev → the module boundaries
    become team APIs and get designed to match the team from day one (Conway). See Step 2b.

Mom Test discipline:
  • Ask about their world and problem, not your solution. Open questions, never leading ones.
    ✗ "You need observability from day one, right?"   ✗ "Should this be multi-tenant?"
    ✓ "Walk me through how someone uses this end to end."   ✓ "What happens today without it?"
  • Get specifics and stories, not hypotheticals.

Calibrate depth to stakes:
  • Clear, low-stakes idea → 1–2 questions, then move. Don't interrogate a weekend script.
  • Vague or high-stakes → dig. If the idea is genuinely fuzzy and interview-me / idea-refine is
    installed → dispatch to it; otherwise do the discovery here.
```

---

## Step 2 — Play it back, then decide the technical shape

### Phase 2a — Reflect and pressure-test (build shared understanding BEFORE any mechanics)
```
Play your hypothesis back in THE USER'S language, and invite correction:
  "Here's what I think you're really building and why: [job] for [who], and success is [X].
   The one thing that has to work is [core]. Where am I wrong?"

Surface the 1–2 assumptions or risks that actually matter (not a checklist — the real ones).
Only proceed once the mental model is confirmed. This reflection is the net that catches a
misread idea before it becomes wrong code.
```

### Phase 2b — shipright decides the shape (state assumptions, don't quiz)
Now settle mechanics — but shipright DECIDES and states assumptions the user can veto. Only ask
the few things that are genuinely the user's to answer (a hard deadline, a required integration).
```
Mode (inferred from appetite/stakes — do NOT ask a cold binary; see references/judgment.md §2):
  validating an unproven idea → VALIDATION (throwaway-OK, minimum to learn — Ries).
  known direction, will grow → FOUNDATION: the thinnest slice with the load-bearing architecture
  right (Cockburn's walking skeleton done right — thin ≠ tactical). Most projects are Foundation.
  "I'll ship the one journey and defer the rest, with the irreversible decisions right from day one."

Team shape (from Step 1 — SIGNAL-DRIVEN; skip entirely if solo):
  Multi-dev (people own different modules)? → the module boundaries are now TEAM APIs. Design them
  to match the intended team (inverse Conway), assign one owner per module, size each to one owner's
  cognitive load, and set up cross-module contract tests. Load references/team-scale.md and record a
  module-ownership table in ARCHITECTURE.md at L0. (Solo → none of this; the boundaries already serve you.)

Ubiquitous Language (Evans — extract from how they talk, don't quiz "give me 3–5 terms"):
  Pull the domain terms out of the conversation and confirm them back: "You call these X, Y, Z —
  I'll use exactly those in the code, not generic names." (Model depth: references/domain-thinking.md)

Stack (recommend, with a one-line why; only ask if it's a real user preference/constraint):
  "For this shape I'd use [stack] because [reason]. OK, or do you have a preference/constraint?"
  → Load the matching stack file for concrete prompts.

What's in scope — INFER from what you learned, and state it as an assumption to veto:
  • Third-party APIs implied? → "This needs [provider]. Before writing integration code I'll do
    Layer 1 exploration (read docs → Bruno → call sandbox → save fixtures → then Adapter).
    references/third-party-apis.md." (Trigger it — don't ask "do you use any APIs?")
  • AI/LLM implied? → load the matching registry entry (rag-pipeline / chatbot / ai-agent).
  • Auth / payments / PII / untrusted input surfaced? → "This handles [X], so I'll run the L0
    threat model (Shostack's 4 questions, references/security.md) and activate security-and-hardening.
    Insecure Design is cheapest to fix now." (Triggered by what you learned — not a cold quiz.)
  • Observability: shipright's call, not the user's. MVP → Correlation ID only; more on signal.
    Don't ask "need observability?" — decide it.
```

### Step 2 output — synthesize into an MVP scope (this is the MVP-first anchor)
```
[job] for [who]; success = [X].  Domain terms: [from the conversation].
Stack: [recommended] | Mode: MVP (or production, if they said so).

[MVP]  Walking skeleton = the ONE journey: "[user] does [X] to get [Y]".
       Get-right-now (one-way doors, judgment.md): core domain model, boundaries, data identity,
       money units, where state lives.
       Everything else → backlog (revisit at VALIDATE/HARDEN/SCALE — the lifecycle spine).

[Production] The irreversible decisions to nail upfront (same one-way-door list, fuller).

Risk I see: [the real one]. Recommendation: [cut scope if appetite < scope].
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

> DISTILL the constitution from the discovery — don't fill a template mechanically. The job, the
> one-way doors, and the real risk you surfaced in Steps 1–2 ARE the content. Keep the root lean
> (~50–60 lines MVP, <200 always): load-bearing rules only; deep conventions go to @import files.
> Full structure, the @import pattern, Nygard-format ADRs, and auto-memory split: `references/l0-templates.md`.

### CLAUDE.md (always generated, content varies by mode)

**MVP version (~60 lines):**
```markdown
# CLAUDE.md — [project-name] (MVP v0.1)

## Project
[the JOB — what the user is really hiring this to do, for whom, and what success looks like.
 Distilled from discovery (Step 1), not a mechanical Input→Process→Output line.]

## Ubiquitous Language
| Term | Meaning | Not |
|---|---|---|
| [domain term from the conversation] | [definition] | [generic alias to avoid] |

## The 5 boundaries (non-negotiable)
1. Dependencies inward only: [specific banned import for this project]
2. Each layer one job: [concrete example for this project]
3. No shared databases: [module names that must not share]
4. Adapter layer: [if external APIs — what the adapter is named]
5. Integration timeout + fallback: [each external call has a timeout; side effects idempotent]
   (full resilience patterns deferred to HARDEN — see references/resilience.md)

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

### Confirm before proceeding (the constitution is what Claude follows every session)
```
Play the distilled constitution back — don't just generate and move on:
"This is the constitution I'll follow every session: [job] · Ubiquitous Language [terms] ·
 boundaries [the project-specific banned imports] · the one-way doors I'm nailing now: [list].
 The one risk I see is [X]. Anything wrong or missing before we build?"
Fix on the user's correction. A constitution the user didn't confirm won't be trusted or honored.
```

---

## Step 5 — After constitution

### MVP mode → Walking Skeleton

```
1. Walking skeleton = the one user journey (Step 2 output)

2. [addyosmani installed] → activate incremental-implementation + test-driven-development
   [not installed] → implement inside-out: repository → service → handler
   Tests: enough to prove skeleton works. Not edge cases.

3. SHIP GATE:
   "Can a real user complete [the one journey] right now?"
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
- [ ] Boundary rules (incl. integration timeout) with project-specific banned examples
- [ ] Core domain type defined (Entity vs Value Object — must be right)
- [ ] Registry entry loaded, required skills noted
- [ ] Shipright state section written to CLAUDE.md
- [ ] MVP: walking skeleton identified as 1 user journey
- [ ] Production: all modules, error taxonomy, idempotency decisions

> Example: `references/examples/orders-api-CLAUDE.md` + `references/examples/orders-api-ARCHITECTURE.md`
