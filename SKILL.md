---
name: shipright
version: 1.27.0
description: >
  Ship your MVP fast. Grow it right. The Project Brain OS for AI coding workflow —
  sets up constitution, enforces boundaries, judges what to build now vs defer,
  hardens for fault tolerance, and orchestrates community skills at the right moment.
  Use when: starting ANY project, adding features (2+ files), fixing unclear bugs,
  refactoring, resuming after break, production incidents, integrating APIs,
  adding observability/tracing/resilience, scaling, building AI/RAG/chatbot projects,
  AND deciding WHETHER to build something / what to build next / whether what shipped worked,
  AND designing or redesigning ANY user-facing surface (page, landing, dashboard, admin,
  form, flow, mobile/responsive layout) — shipright carries the UI/UX floor and design brief,
  AND desktop/PC apps (Electron, Python), AND git (commit, push, PR, merge — when to ask first).
  Triggers: "build", "start project", "add feature", "bug", "refactor",
  "production down", "back on this", "integrate API", "add tracing", "make it resilient",
  "build chatbot",
  "should I build", "is this worth building", "what should I build next", "did it work",
  "nobody uses it", "prioritize",
  "design a page/screen/UI", "landing page", "dashboard", "admin panel", "frontend",
  "redesign", "make it look better", "improve the UI/UX", "responsive",
  "accessibility", "desktop app", "Windows app", "Electron", "PySide6", "multi-account".
  Skip for: single-line fixes, knowledge questions, mid-implementation steps.
  Manual invoke: /shipright — always reliable.
allowed-tools: Read, Write, Bash, Glob, Grep
---

## Working context — injected every session

```
# Two traps in these commands, both silent:
#  1) A dollar-sign followed by a digit is an ARGUMENT placeholder, substituted before the shell runs —
#     an awk positional print became `print <a word the user typed>` and crashed the skill. Use sed/cut
#     or a named variable instead; never a positional param. (Same for the all-caps ARGUMENTS token.)
#  2) grep -R, not -r: `npx skills add` SYMLINKS skills into ~/.claude/skills by default, and lowercase
#     -r does not follow symlinked directories — every correctly installed skill reads as missing.
Shipright:     !`grep "^version:" "${CLAUDE_SKILL_DIR}/SKILL.md" 2>/dev/null | sed 's/^version: *//'`
Directory:     !`pwd`
Git branch:    !`git branch --show-current 2>/dev/null || echo "no git"`
Last commit:   !`git log --oneline -1 2>/dev/null || echo "no commits"`
CLAUDE.md:     !`test -f CLAUDE.md && echo "EXISTS — read first" || echo "MISSING"`
ARCHITECTURE:  !`test -f ARCHITECTURE.md && echo "EXISTS — read first" || echo "MISSING"`
# -A5, not -A3: the state block gained `Last shipped` (the pending outcome check). At -A3 it falls
# off the end and the outcome loop never fires. Widen this if the block ever grows again.
Project state: !`grep -A5 "## Shipright state" CLAUDE.md 2>/dev/null | tail -5 || echo "no state tracked"`
# Consent for git lives in the project, not in the model's mood: read the recorded policy every session.
Git policy:    !`grep -A7 "## Git policy" CLAUDE.md 2>/dev/null | tail -7 | grep . || echo "none recorded — propose commits; ask before push/PR/merge (references/git.md §2)"`
Uncommitted:   !`git status --porcelain 2>/dev/null | wc -l | tr -d ' '` file(s) — never discard without asking (git.md Tier 2)
# Granular skill detection — match the SKILL.md `name:` field, NOT a guessed path: `npx skills add`
# (flat, by install name) and `git clone` (repo/skills/<name>/) produce different layouts, and a
# path-shaped probe silently returns NO forever under the other one. Personal + project scope.
# Each probe LISTS what is present (not YES/NO) — dispatch needs the specific name, and one grep
# beats six. taste-skill is an ecosystem whose folder names ≠ install names; see ui-design.md.
skill/core:  !`grep -RhsE '^name: *"?(spec-driven-development|incremental-implementation|test-driven-development|code-review-and-quality|debugging-and-error-recovery|security-and-hardening)"? *$' ~/.claude/skills .claude/skills --include=SKILL.md | sed 's/^name: *//; s/"//g' | sort -u | paste -sd',' | grep . || echo NONE`
skill/ui:    !`grep -RhsE '^name: *"?(design-taste-frontend(-v1)?|minimalist-ui|high-end-visual-design|redesign-existing-projects|industrial-brutalist-ui|gpt-taste|image-to-code|stitch-design-taste|imagegen-frontend-(web|mobile)|brandkit|full-output-enforcement|web-design-guidelines|browser-testing-with-devtools)"? *$' ~/.claude/skills .claude/skills --include=SKILL.md | sed 's/^name: *//; s/"//g' | sort -u | paste -sd',' | grep . || echo NONE`
Tests:         !`if [ -f package.json ] && grep -q '"test":' package.json; then echo "npm test"; elif [ -f pytest.ini ] || [ -f pyproject.toml ] || [ -d tests ]; then echo "pytest"; else echo "none detected"; fi`
```

---

# Shipright v1.27 — Project Brain OS

An executive layer over two hemispheres. The executive decides how much of each hemisphere to
apply, by stage × risk × reversibility (construction is ON from day one — the irreversible quadrant;
operation turns on by signal), and it closes the loop after shipping: build right → ship → find out
whether it mattered. The roster grows — the reference files are the source of truth, not a count.

```
EXECUTIVE  — HOW MUCH: Bezos (doors) + the discipline of stopping       → references/judgment.md
             WHETHER:  Cagan (4 risks) · Perri (output≠outcome) · Torres
                       (riskiest assumption) · Rumelt (diagnosis)       → references/product-judgment.md
CONSTRUCTION (day one) — Evans · Uncle Bob · Ousterhout · Fowler · Kent Beck
             → code-quality.md · code-health.md · testing.md
OPERATION (on signal)  — Nygard (resilience.md) · SRE/Majors (observability.md)
```

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

The rules above are the whole contract, but they are stated abstractly. **The moment you are about to
write or review layered code and "does this violate a boundary?" is not obvious from the rule alone →
load `references/boundaries.md`** — the same 5 rules as concrete violation/fix pairs in real code.
Language-specific enforcement (Go `internal/`, PHP Deptrac, Python import rules) lives in the stack file.

Optional **enforcement**: `hooks/boundary-guard.sh` is a PreToolUse hook that BLOCKS the two
highest-confidence violations (service→db import, deep cross-module import) before they're written —
boundaries that block, not just advise. Opt-in, fails open. See `references/enforcement.md`.

---

## The executive question — ask before every non-trivial decision

```
Before you BUILD it at all:  "Is the need real — and what happens if we DON'T?"
  Real need                → proceed to the door question below.
  "Nothing much, it'd be nice" → that IS the answer. Log it, don't build it.
  Unproven AND expensive   → STOP. Cheapest test first (`references/product-judgment.md`).
  Unproven AND cheap       → build it; the build is the test. Then check the outcome.

Before you BUILD it:  "Is this a one-way door, and is the need real today?"
  One-way + real      → do it right, now (domain model, boundaries, data identity, money units)
  One-way + not yet   → design the seam so it stays reversible, defer the rest
  Two-way + real      → simplest thing that works, move on (cache, log format, retry count)
  Two-way + not yet   → don't build it. Write a debt signal and ship.

Before you keep POLISHING it:  "Is this good enough for the appetite — or am I gold-plating?"
  Job done + core works → SHIP, get feedback. Cut SCOPE to nice-to-have; never cut the quality FLOOR
  (boundaries, one-way doors, the quality gate). Ship a smaller COMPLETE thing, not a bigger broken one.

After you SHIP it:  "Did it work — and how would I know?"
  The OUTPUT check (it builds, tests pass, a user can complete the journey) is not the OUTCOME check.
  Both can diverge completely. Name the signal AT ship time (CLAUDE.md `## Outcome` + Shipright state
  `Last shipped`), and ANSWER it at the next session — before the next feature (Branch E Step 1b).
```

This defeats three failure modes: over-engineering (two-way door treated as one-way, or polishing past
"good enough"), architecture rot (one-way door treated as two-way, or cutting the quality floor to
ship), and the **build trap** — feature after feature that changes nothing, while every quality gate
passes (Perri). Building verifies feasibility for free; it never verifies value, so value must be
asked on purpose. Matrix + stopping + "when to break each rule": `references/judgment.md` (load at L0
and at every "should I add X?" / "am I done?"). Value, the four risks, the cheapest test:
`references/product-judgment.md`.

---

## Lifecycle spine — SEED → VALIDATE → HARDEN → SCALE

One model; the older vocabularies (L0–L4, Stage 1–3, MVP/Production, Traction/Growth/Scale) map onto
it. Construction ramps up early (irreversible quadrant); operation turns on by signal. Full phase
table + which masters/dial per phase: `references/levels.md` + `references/judgment.md`.

⚠ **"VALIDATE" here validates the CODE, not the need** — tests GREEN, boundaries clean. A project can
reach SCALE having never once checked that anyone wants it. Value runs on its own loop, orthogonal to
this spine: `## Outcome` → the SHIP GATE's outcome half → Branch E Step 1b.

---

## Session start — 3 checks before anything else

**Check 1: Read existing constitution**
If CLAUDE.md and ARCHITECTURE.md exist → read both completely before asking anything.
Project state section in CLAUDE.md shows where things left off last session.
**`Last shipped` carrying an unanswered outcome check → ask it before starting anything new**
(Branch E Step 1b). Read `## Outcome` too: it outranks `Next` when the two disagree.

**Check 2: Read the skill lists above, then adapt precisely** — a skill counts as available only if its
name appears in `skill/core` or `skill/ui`.

| skill | activate when | if absent → shipright's built-in fallback |
|---|---|---|
| spec-driven-development | Tier L/XL, before implementation | write acceptance criteria as markdown |
| incremental-implementation | Tier M+ multi-file features | outside-in drive, vertical slice (levels.md L3) |
| test-driven-development | any feature with logic | RED test manually first |
| code-review-and-quality | before merge on Tier M+ | manual quality gate (code-quality.md) |
| debugging-and-error-recovery | all bugs (Branch C) | Branch C 5-step flow |
| security-and-hardening | auth/payments/untrusted input appears | `security.md` spine + **`/security-review` on the diff** (bundled, free — this is a real review, not "manual OWASP"). Still not enough for smart contracts: those need an audit |
| a taste-skill | UI/UX pages, flows, forms — activate the one matching the PAGE TYPE (`ui-design.md` §Page type), not whichever happens to be installed | apply ui-design.md UI/UX principles — Norman/Nielsen/Refactoring UI/WCAG + the state-floor (real judgment, not hand-waving). Charts → dataviz skill |
| web-design-guidelines | dashboard/admin/data-heavy UI, a11y-critical UI | apply ui-design.md §Admin patterns + §WCAG-as-correctness manually (judgment is shipright's either way; only the rule-set is missing) |
| browser-testing-with-devtools | verifying a UI actually renders/works (360px, console, network) | capture the state manually and say the check was by eye, not measured — never call a UI responsive or accessible from reading code |

When a skill = NO: never pretend it's available and never skip the step — but don't just resign to the
fallback either. **Offer to install it (see Check 3), because a skill installed now works NOW.**

**Check 3: Missing skill → offer once, install on consent, use it this session**

**First: is it already there?** Nothing gets installed until you have ruled that out. "Already there" is
three things, and only the second is on disk:
```
1. Skills listed in THIS SESSION's available-skills list — the authority, and it is already in your
   context. Read it. Bundled skills (/security-review, /code-review, /run, /debug, /claude-api,
   dataviz, artifact-design, /simplify …) normally appear there, but the set varies by Claude Code
   version and `disableBundledSkills` / `skillOverrides` can remove any of them. Treat the names in
   §Ecosystem dispatch as what to LOOK FOR, never as a guarantee that it is present.
2. Already installed on disk — `skill/core` and `skill/ui` above list these (stale after any
   mid-session install; re-check per §Install recipes).
3. Served by a connected MCP server or plugin — those appear in the session list too.
```
Offering to install over something in that list is a straight downgrade: it spends the user's consent
and disk on capability they already had. Only when nothing there covers the job does the flow below apply.

Claude Code **watches the skill directories**: a skill added under `~/.claude/skills/` during a session
takes effect immediately, no restart. So the useful move at the moment a trigger fires is not "here's a
command, run it sometime" — it's "want it? 10 seconds, and I'll use it right now."

```
1. OFFER — one line, at the moment the trigger fires (not a wall of options at session start):
   "This needs [skill] for [the specific job]. Install it now (~10s, global) and I'll use it —
    or I proceed with shipright's built-in fallback. Your call."
   Say what it does and what changes if you skip it. Offer ONCE per skill per session; if the user
   says no, drop it and don't re-ask.

2. NEVER install without that yes. shipright's own `allowed-tools` pre-approves Bash, so the harness
   will NOT show a permission prompt — the consent has to come from shipright asking. This is
   third-party code from GitHub landing in the user's home directory, and a skill can grant itself
   broad tool access. Silence is not consent.

3. ON YES — `--list` for the exact install name (folder names fail), install, then RE-VERIFY: never
   assume it worked. Commands + the -g/project-scope nuance: `references/registry.md` §Install recipes.

   ⚠ The skill lists in the working context above are a snapshot taken ONCE, when shipright was invoked —
   Claude Code does not re-run them on later turns. After any install, and whenever the user says they
   installed something, re-run the grep from §Install recipes instead of trusting the stale snapshot.

4. FAILS or REFUSED → say so plainly, use the fallback, continue. Never block on a missing skill.
```

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

## How shipright asks — all branches

Intake in every branch is a conversation, not a form. shipright carries the technical judgment
and talks like a veteran, not a questionnaire. (Full intent-discovery flow: Branch A. Model branch: E.)

```
1. Read/infer BEFORE you ask — anything derivable from CLAUDE.md, the codebase, git, or the user's
   own words, DETERMINE it. Don't ask for what you can read.
2. Ask only what ONLY the user knows — the real pain, business intent, bug repro steps, priorities,
   constraints. NEVER make the user do a technical classification that is shipright's job
   (which code smell, which module, new-vs-extend, bug class, stack).
3. Diagnose, then CONFIRM — don't menu-quiz. State the diagnosis with its evidence
   ("I read X, Y, Z → this is Feature Envy") and invite correction. (Branch A's playback, generalized.)
4. Open questions over menus — except where speed matters (Branch F incident triage) or the option
   set is genuinely the user's stable choice.
5. Calibrate depth to stakes (references/judgment.md): trivial → 1–2 questions; high-stakes → dig.
```

---

## Registry — project type → curated skills

After routing, if project type is identifiable, load:
`references/registry.md` — find the project type entry (~300 tokens per entry)

Registry tells: what to install, what shipright adds to CLAUDE.md, tested-with versions.
Load only the relevant entry, not the full file.

---

## Quality system — construction hemisphere

Enforced across the lifecycle; the detail lives in the refs (load on demand):
- **L0** — Ubiquitous Language + domain types in CLAUDE.md/ARCHITECTURE.md (Evans); Clean Code rules;
  test runner set up now. → `references/code-quality.md`, `references/l0-templates.md`.
- **L1–L3** — **test-first is the default for logic** (goal = confidence + design, not ritual or a
  coverage number; narrow honest exceptions; never for money). Pyramid, test-through-the-public-
  interface, mock only at the seams: `references/testing.md`. Build order (drive outside-in · slice
  vertical · implement domain-first): `references/levels.md` L3.
- **Before every commit — the quality gate**: tests? names from Ubiquitous Language? function > 20
  lines? Feature Envy / Primitive Obsession? Full gate: `references/code-quality.md` + `code-health.md`.
  On Tier M+, close it with a real review, not a self-assessment: run `/security-review` if the change
  touched auth/payments/untrusted input, and ask the user to run `/code-review` (it is user-invoke-only).
  Both are bundled — recommending an install here would be wrong. Committing, pushing and opening the PR
  follow the Git policy and the consent ladder (`references/git.md`) — a passing gate is not consent.

**Compound engineering**: a repeated mistake → a rule that prevents it. Durable architectural rule →
CLAUDE.md / `.claude/rules/`; incidental learning (build cmd, debug insight) → Claude Code's native
auto memory. Keep CLAUDE.md the lean constitution, not a dumping ground.

---

## Persistent state — tracking across sessions

Shipright writes a state section to CLAUDE.md after significant milestones.
This survives across sessions. Working context above reads it automatically.

```markdown
## Shipright state
Level: L3
Active: [module name]
Next: [specific action — verb + object + acceptance criteria]
Last shipped: [what shipped] → signal [X], check by [when]   (or "nothing yet")
Last updated: [date]
Skills active: [comma-separated list]
```

When state exists: skip intake, start from "Next" action.
When state missing: full intake flow.
Branch E (resume) uses this to re-orient in seconds instead of minutes.

`Last shipped` is the **outcome loop's memory**: it carries a pending "did it work?" to the next
session (Branch E Step 1b asks it). Only the user can answer it — carry it forward until they do.

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
| "p95 latency / DB CPU over target" | Profile → fix query/N+1 → cache → replica | `references/performance.md` (React/Next front end → also `vercel-react-best-practices`; deployed on Vercel and it's the BILL → `vercel-optimize`) |
| "Need SLOs / error budget" | Golden signals + SLO + alerting | `references/observability.md` |
| "API changed silently" | Schema validation + contract tests | `references/third-party-apis.md` |
| "Can't reproduce prod issues" | Correlation ID missing | `references/observability.md` |
| Team > 10, merge conflicts rising | Module ownership + arch tests | `references/scaling-guide.md` |
| Adding features getting slower | Fowler smells accumulated | `references/code-quality.md` |

---

## Mid-work signals — load the moment you realize it, not just at routing

Routing (intake) and the L4 table (operation) cover session-start and production. But some needs
surface *mid-construction* — a **realization**, not a route. These have no other firing path, so catch
them here: when the thought below crosses your mind while building, load the ref immediately.

| You realize, while building… | Load |
|---|---|
| "I'm writing code in this project's language for the first time this session" | `references/stacks/<language>.md` — ONCE, before the first implementation. Not just a Branch A concern: the stack file carries compile-time boundary enforcement, timeout/context idioms, the error taxonomy and the language's security footguns, and existing projects (Branch B/C/D) need them just as much. |
| "What's the right shape for this domain concept — entity, value object, aggregate? Where does this invariant live?" | `references/domain-thinking.md` (Evans tactical: aggregate roots, invariants, domain events, "DDD or not?") |
| "I'm writing the failure path — what should this return / throw / retry / roll back?" | `references/error-handling.md` (taxonomy, Result type, saga, race conditions, idempotency) — decide it while writing, not after an incident |
| "I'm touching auth, a session, a permission check, money, PII, file paths, or anything a user controls" — **in ANY branch, not just a new feature** | `references/security.md` (Saltzer & Schroeder, OWASP → layer map). Then EXECUTE the review: `/security-review` (bundled, free) and `security-and-hardening` if installed. Refactoring auth or fixing a payment bug is exactly when this gets skipped — and exactly when it costs most. |
| "Should this feature exist at all?" · "nobody has said why they want this" · an outcome check came back NO / DON'T KNOW · we've shipped a lot and nothing changed for anyone | `references/product-judgment.md` — the OTHER half of the executive question. Cagan's four risks (building proves feasibility for free and value never), the riskiest assumption + the cheapest test that could kill it, cost-of-NOT and opportunity cost, Rumelt's diagnosis. **Skip it for a bug fix, a config change, or a request the user already reasoned about** — asking there is friction, not judgment. |
| "This decision is irreversible, security-sensitive, or I'm confident in unfamiliar code" | `references/judgment.md` (one-way door) — and if `doubt-driven-development` is installed, that IS the adversarial second opinion the one-way door deserves |
| "A settled decision / the domain model is wrong — it must change" | `references/evolutionary-architecture.md` (evolve under guard, recovery path). A fitness function only guards you if it RUNS on every commit → `ci-cd-and-automation` |
| "The requirements changed under us mid-build" | `references/requirement-drift.md` (expand → migrate → contract). Removing the old path / moving users off it is the contract phase → `deprecation-and-migration` |
| "I just decided a ONE-WAY door (public interface, data identity, money, persisted state)" | Record it before it becomes folklore — shipright decides *what* is irreversible, `documentation-and-adrs` records it properly (ARCHITECTURE.md / ADR). An unrecorded one-way door gets re-litigated by the next session. |
| "We're exposing tools/data to an AI host (MCP server/client)" | `references/stacks/mcp.md` (lethal-trifecta boundary) |
| "This runs as a desktop app on the user's PC" — a window, an .exe, an installer, or many accounts/browser sessions on one machine | `references/desktop.md` — modern Node/Python only: Electron+TS by default, Python via PySide6 or a sidecar; choose the shape at L0 (a rewrite to change) · OPERATE (N live sessions in one window) vs ACT (the app acts via API) · the UI thread never blocks · risky work in supervised processes · OS secret store · signed build + verified updates. Mechanics: `stacks/electron.md` / `stacks/python-desktop.md`. Many accounts on a third-party platform → official API first; UI automation is a viability question (`product-judgment.md` §1), and evasion (anti-detect, captcha bypass) is out of scope. |
| "I'm about to commit, push, open/merge a PR, tag a release, discard changes, rewrite history, or resolve a conflict" | `references/git.md` — the **consent ladder**: read-only = just do it · local + recoverable = per the project's Git policy · destroys uncommitted work = ALWAYS ask, with what would be lost · outward (push/PR/tag) = ask unless the policy grants it · shared history (merge to main, force-push) = ALWAYS explicit confirmation. A "yes" covers that action on that branch, not the next one. No policy recorded → offer to write `## Git policy` into CLAUDE.md once. |
| "This module got too big for one person to hold in their head" | `references/team-scale.md` (cognitive load → split) |
| "I keep threading the same 3 fields / a string stands in for a domain concept" | `references/code-quality.md` (smells → extract) |
| "I'm about to write / touch a user-facing surface — a page, screen, form, table, dashboard" | `references/ui-design.md` — the EXPERIENCE floor is not optional and not an afterthought: a11y + responsive/mobile + IA + the state-floor (loading / empty / error / success are *designed*). Then dispatch execution (taste-skill / vercel-labs / dataviz). |
| "This screen only has a happy path / this table is unusable at 360px / these are emoji icons" | `references/ui-design.md` (state-floor · §Mobile & responsive · §Icons — SVG, never emoji) |
| "I'm about to call / integrate a NEW 3rd-party API (YouTube, Stripe, **or an LLM API**, …)" | `references/third-party-apis.md` §Layer-1 — MANDATORY before the Adapter: call the real API/sandbox → save real responses as `tests/fixtures/` → THEN write the Adapter + unit tests (fixtures) + a contract test. Never code an Adapter from docs alone. **LLM APIs count** — also capture token-usage / cost / streaming / error shapes (`references/stacks/ai-projects.md`). Anything carrying an ONGOING cost or obligation (per-call billing, PII, a support burden) also raises **viability**, which is not an architecture question and has no other trigger: what does this bill at 100 users, not 3 · who answers the mail it generates · may we legally hold this data → `references/product-judgment.md` §1. |

---

## Ecosystem dispatch — shipright is the conductor

Shipright owns WHEN/WHAT (constitution · 5 boundaries + quality gate + executive layer · lifecycle ·
routing · irreversible decisions). Community skills own HOW. Two hard rules:
1. Never self-execute work a dedicated skill already covers.
2. Never load a skill you'd duplicate, or a heavy skill a small project doesn't need yet — every
   loaded skill spends context budget and dilutes reasoning (few-skills-when-small = correctness).

**Dispatch by TRIGGER, not stage label** (a payment MVP needs security day one; a read-only app may
never). The full capability/signal → skill table (addyosmani, taste-skill, AI-eval) is the **trigger
index in `references/registry.md`** — load it after routing. Default ladder if no trigger fires:
SEED=debug · VALIDATE=+tdd/incremental/review · HARDEN=+spec/security/observability · SCALE=+specialized.

**Reach for the BUNDLED skills first — they ship with Claude Code and need no install.** Never offer to
install something these already cover (Check 3 exists for what is genuinely missing). They are normally
present but **not guaranteed**: the set varies by version, and `disableBundledSkills` / `skillOverrides`
can remove any of them. Confirm against this session's available-skills list before promising one; if it
isn't there, say so and fall back rather than inventing it.

| Bundled | Use it when |
|---|---|
| `/security-review` | Security review of the branch's pending changes — the EXECUTION arm of `security.md`. Run it whenever auth / payments / untrusted input was touched, before the merge gate. This is not "manual OWASP"; it is a real review and it is free. |
| `/code-review` | The quality gate on Tier M+. **User-invoke-only** — shipright cannot run it, so ASK the user to run it rather than claiming the gate is done. |
| `/run` | See the system actually work — the counterpart to `browser-testing-with-devtools` for anything that isn't a browser UI (CLI, server, job). Verifying by running beats asserting from the diff. |
| `/debug` | Branch C, alongside shipright's own flow |
| `/claude-api` | ANY work against an LLM API — model ids, pricing, params, streaming, tool use, token counting. Load it before writing the LLM Adapter (Boundary 4), never answer from memory |

**SKIP (shipright already covers):** interview-me / idea-refine → Branch A intent discovery (dispatch
only when the idea is genuinely vague + installed); frontend-ui-engineering → taste-skill; performance-
optimization → L4 signal-driven; code-simplification → code-quality.md + code-health.md (and `/simplify`);
planning-and-task-breakdown → Branch B tiers + spec-driven. For AI/RAG: addyosmani covers infra code, shipright AI files cover
AI-specific code (eval loop, LLM boundaries) — use both, no overlap.

---

## When workflow is not appropriate

Throwaway/<1wk · script <200 lines no domain · solo <3 entities read-only → skip the machinery, hack
freely (flat functions, no layers/DI). Otherwise use shipright. Senior judgment = knowing when NOT to
apply a pattern (over-applying to a 50-line script = under-applying on a payment system). `judgment.md` §5.

**Match the FLOOR to the project shape — don't skew system vs UI/UX.** Backend/API/CLI → system floor (5
boundaries), no UI. Static/marketing/landing → the UI/UX floor (`references/ui-design.md`), NOT the backend
boundaries (that's over-engineering). Full-stack product → BOTH floors, integrated (neither a bolt-on).
`judgment.md` §5b.

---

## Reference files — the map, not the trigger

The tables above (routing · L4 signals · Mid-work) are what MAKES these load, and they carry the *when*.
This list is the map: reach for it when a situation matches none of them. A file appearing here is not a
reason to load it. All paths under `references/`.

**Branches** (load ONE per session): `branches/` a-new-project · b-add-feature · c-fix-bug · d-refactor ·
e-resume · f-incident · **`registry.md`** — trigger index + project-type packs + install recipes (one entry).

**Executive & construction** — `judgment.md` (one-way/two-way doors, MVP matrix, when to break each rule,
system-vs-experience floors) · `product-judgment.md` (is the need real: 4 risks, riskiest assumption +
cheapest test, value fork, Rumelt) · `code-quality.md` (Fowler smells, Clean Code, the quality gate) ·
`code-health.md` (SOLID + Ousterhout deep modules) · `testing.md` (strategy: pyramid, test through the
public interface, mock only at seams) · `domain-thinking.md` (Evans tactical: aggregates, invariants,
"DDD or not?") · `error-handling.md` (taxonomy, Result, saga, idempotency) · `boundaries.md` (the 5 rules
as real code) · `enforcement.md` (the blocking hook) · `l0-templates.md` · `levels.md` (lifecycle + gates) ·
`git.md` (the consent ladder, Git policy, commits, branches, PRs, merges, recovery).

**Operation** — `resilience.md` (Nygard, Boundary 5) · `observability.md` (Correlation ID, SLO) ·
`performance.md` (measure-first ladder) · `scaling-guide.md` (Stage 1→2→3, Strangler Fig) ·
`debug-intermittent.md` · `security.md` (Saltzer & Schroeder, OWASP → layer map, threat modeling).

**Change under you** — `evolutionary-architecture.md` (you were wrong: fitness functions, recovery path) ·
`requirement-drift.md` (expand → migrate → contract) · `team-scale.md` (boundary = team API) ·
`third-party-apis.md` (Adapter + 3-layer testing).

**Experience & platform** — `ui-design.md` (the UI/UX floor + judgment hemisphere, then dispatch by page type) ·
`desktop.md` (PC apps, modern Node/Python: shape choice, UI thread, process model, secrets, signing, updates, multi-account).

**Stacks** — `stacks/`: `nodejs.md` · `python.md` · `go.md` (`internal/`, context timeouts) · `php.md`
(PHPStan, Deptrac, footguns) · `browser-extension.md` · `ai-projects.md` (the LLM boundary) · `ai-rag.md` ·
`mcp.md` (lethal trifecta) · `ai-agent.md` · `chatbot-platforms.md` · `blockchain.md` ·
`electron.md` (the default desktop shape — main/preload/renderer, typed IPC, sessions, fuses) ·
`python-desktop.md` (PySide6, and Python as a sidecar behind Electron — the rules live in `desktop.md`).

**Passive** — `prompts.md` (copy-paste prompts; pulled by hand, deliberately has no trigger) ·
`examples/` orders-api-CLAUDE.md · orders-api-ARCHITECTURE.md.`

---

## Language rule
Respond in the user's language. These files are English for GitHub discoverability.
CLAUDE.md and ARCHITECTURE.md content stays in English (project convention).
