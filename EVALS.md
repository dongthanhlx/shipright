# Runtime evals — does the right knowledge FIRE at the right moment?

> Everything else in this repo verifies the **artifact** (files exist, are linked, are consistent —
> checked by CI greps). This file verifies the **runtime**: at moment X in a real session, does the
> needed knowledge actually get pulled into context and applied? That is a *behavioral* property greps
> cannot prove — only running the scenarios can. This is shipright's own eval-driven philosophy
> (references/testing.md, ai-rag eval) applied to shipright itself.

## How to run (dogfood)

For each scenario: start from what's actually in-context — **SKILL.md (always loaded)** + **the one
branch that routing loads** — and trace whether a **concrete situation-trigger** points to the ref the
scenario needs. Verdict:
- **FIRES** — a concrete "when you see X → load Y" exists in the always-loaded core or the routed branch.
- **WEAK** — the trigger exists only in a secondary ref (registry/judgment) that must already be loaded.
- **DARK** — the ref is only *catalogued* (in the reference index); no situation-trigger surfaces it.

A DARK ref is beautifully-written knowledge that won't fire when needed — the exact failure mode this
file exists to catch. Re-run this each version; treat any DARK/WEAK on a high-value scenario as a bug.

**A second failure mode, added v1.20:** a trigger can fire perfectly and still dead-end, because it
dispatches to a skill **name that does not exist** or probes an **install path that never appears**.
Firing is necessary but not sufficient — the target has to be real. Verdicts extend with:
- **BROKEN-TARGET** — the trigger fires, but the skill name / install command / detection path is wrong,
  so nothing is actually reachable. Indistinguishable from DARK at runtime, invisible to greps.

Check targets against reality, not against this repo's memory of it. The CLI's own `--list` is
authoritative — it prints the **install names**, which is exactly what `--skill` accepts (the GitHub
folder listing shows folder names, which differ and do not work):
```bash
npx -y skills@latest add https://github.com/addyosmani/agent-skills --list
npx -y skills@latest add https://github.com/Leonxlnx/taste-skill    --list
```

## Scenarios + last run (v1.17)

| # | Situation (the prompt) | Needs | Firing path | Verdict |
|---|---|---|---|---|
| 1 | "add a payment feature" | security.md, Boundary 5 | Branch B security block + Branch A Q5d (auth/payments) | FIRES |
| 2 | "the app is slow, p95 = 2s" | performance.md | SKILL L4 signal table (always-loaded) | FIRES |
| 3 | "a dependency keeps timing out and takes us down" | resilience.md | SKILL L4 table + Branch F | FIRES |
| 4 | "we're 4 devs, each owns a module" | team-scale.md | Branch A "solo or a team?" question | FIRES |
| 5 | "build a Telegram chatbot" | chatbot-platforms.md | Branch A Q4b (AI/LLM) → registry entry | FIRES |
| 6 | "refactor this messy service" | code-health.md, code-quality.md | Branch D diagnoses the smell | FIRES |
| 7 | "how do I know when it's done / stop polishing?" | judgment.md §3b | SKILL executive question (2nd: good-enough) | FIRES |
| 8 | "which framework for my Python API?" | python.md | Branch A stack recommendation | FIRES |
| 9 | "production incident, users getting 500s" | f-incident, resilience, error-handling | routing → Branch F | FIRES |
| 10 | "these tests break every refactor / what should I test?" | testing.md | Branch B quality gate + registry trigger | FIRES (branch) |
| **11** | **"we were WRONG about the domain model — it must change"** | **evolutionary-architecture.md** (recovery path) | none — only catalogued + judgment.md §1 | **DARK → fixed v1.17** |
| **12** | **"the requirements changed under us mid-build"** | **requirement-drift.md** (expand-contract) | none — only catalogued | **DARK → fixed v1.17** |
| **13** | **"we're exposing tools/data to an AI host (MCP)"** | **stacks/mcp.md** | registry mcp-server entry only (weak) | **WEAK → fixed v1.17** |

## Re-run + new scenarios (v1.20) — the UI/UX layer and the ecosystem targets

Two audits: (a) does the v1.18/v1.19 UI/UX hemisphere fire, (b) do the skills shipright dispatches to
actually exist under the names it uses. **Scenario 5's v1.17 "FIRES" verdict was wrong** — re-verified.

| # | Situation (the prompt) | Needs | Firing path (before) | Verdict → fix |
|---|---|---|---|---|
| 14 | *"design a landing page"* / *"the dashboard looks amateur"* | ui-design.md | **shipright's own description had no UI vocabulary** — the skill never woke up | **DARK → fixed v1.19.2** (description triggers) |
| 15 | "redesign this page / make it look better" (existing code) | ui-design.md redesign track | Branch D had no experience fork; its "no measurable pain" guard bounced the request | **DARK → fixed v1.19.2** (Branch D Step 0) |
| 16 | "the layout breaks on mobile / contrast is unreadable" | ui-design.md floor | Branch C classified only reproducible-vs-intermittent | **DARK → fixed v1.19.2** (Branch C visual/UX row) |
| 17 | mid-build: "this screen has no empty state" | ui-design.md state-floor | none — a construction realization | **DARK → fixed v1.19.2** (Mid-work rows) |
| 18 | "install the skill for a SaaS landing page" | taste-skill | trigger fired, but **6 of 8 install commands named folder names or skills that don't exist** | **BROKEN-TARGET → fixed v1.20** |
| 19 | any session where a community skill IS installed | Check-2 dispatch | probes assumed one install layout; `skill/taste` probed a path a correct install never creates | **BROKEN-TARGET → fixed v1.20** (probe the `name:` field) |
| 20 | "build a Telegram chatbot" (re-run of #5) | chatbot-platforms.md | registry entry listed installs but had **no `load:` line** — the architecture content was unreachable | **WEAK → fixed v1.20** (`load:` added to all 6 entries missing it) |
| 21 | "add an endpoint" in an existing Go/PHP project | stacks/go.md, php.md | only Branch A ("load the matching stack file") — Branch B/C/D never did, so `internal/`, context timeouts, PHPStan/Deptrac and the language security footguns never fired for existing code | **DARK → fixed v1.20** (Mid-work row) |
| 22 | "is this an aggregate? where does this invariant live?" | domain-thinking.md | one parenthetical in Branch A | **WEAK → fixed v1.20** (Mid-work row) |
| 23 | "what should this failure path return / roll back?" | error-handling.md | Branch C/F only — classify an existing failure, never write a new one | **WEAK → fixed v1.20** (Mid-work row) |
| 24 | "does this violate a boundary? show me in real code" | boundaries.md | **catalogue only** — the sole other mention was a sample `.claude/rules/` listing inside Branch D, i.e. a project's own file, not shipright's ref | **DARK → fixed v1.20** |
| 25 | "give me a copy-paste prompt for X" | prompts.md | catalogue only | **DARK — accepted** (passive library, pulled by hand; no trigger needed) |

### Capability scenarios (v1.21) — a real need with no executor at all

The audit's other half: not a wrong name, but **no name**. These fired into shipright's own prose and
stopped there.

| # | Situation | Needs | Before | Verdict → fix |
|---|---|---|---|---|
| 26 | "is this actually responsive / accessible?" | a real browser | shipright mandated "verify at 360px with a real thumb" and had **no way to run a page** — verdicts came from reading code | **NO-EXECUTOR → fixed v1.21** (`browser-testing-with-devtools`, + a ban on code-only a11y/responsive verdicts) |
| 27 | "the React app is slow" | React/Next specifics | `performance.md` ladder only (deliberately stack-agnostic) | **NO-EXECUTOR → fixed v1.21** (`vercel-react-best-practices`) |
| 28 | "we just decided the money type / public API shape" | a durable record | judgment.md named the one-way door; nothing recorded it | **NO-EXECUTOR → fixed v1.21** (`documentation-and-adrs` Mid-work row) |
| 29 | "now remove the old path" (contract phase) | migration discipline | requirement-drift.md described the phase, named no executor | **NO-EXECUTOR → fixed v1.21** (`deprecation-and-migration`) |

### Acquisition scenarios (v1.22) — the executor exists, is named correctly, and still isn't there

| # | Situation | Before | Verdict → fix |
|---|---|---|---|
| 30 | trigger fires, the right skill is simply not installed | shipright printed an install command and dropped to fallback — treating "not installed" as permanent | **NOT-ACQUIRED → fixed v1.22.** Claude Code watches the skill dirs, so a skill added mid-session works immediately (no restart). Now: offer once → install on consent → use it this turn. |
| 31 | the user installs a skill mid-session, as shipright told them to | the `skill/*` probes are rendered **once**, when shipright is invoked; Claude Code does not re-run them on later turns. shipright kept saying "not installed" for the rest of the session and kept using the fallback | **STALE-SNAPSHOT → fixed v1.22** (re-run the grep after any install or when the user says they installed something) |

A third failure mode, then: the knowledge fires, the target is real — and the target isn't *present*.
Treating absence as permanent is its own dead end when acquisition costs ten seconds.

### Runtime bugs the eval scenarios cannot catch (v1.24.1)

Every scenario in this file traces *whether a trigger points at the right ref*. Neither of these was a
trigger problem — the always-loaded block itself was broken, and only running it revealed that.

| # | Symptom | Cause | Lesson |
|---|---|---|---|
| 36 | shipright crashed on invoke: `awk: unexpected character` | a dollar-sign followed by a digit is an **argument placeholder**, substituted before the shell runs — the awk program became `{print <a user word>}` | skill content is templated first, shelled second. No positional params in `` !`…` `` blocks. |
| 37 | `skill/ui` reported `NONE` while three taste skills were installed | `npx skills add` **symlinks** into `~/.claude/skills`; `grep -r` skips symlinked dirs | the probe must match how the tool actually installs, not how the test fixture was built |

**The verification lesson, which is the point.** v1.20 replaced a path-shaped probe with a `name:`-based
one and verified it against a synthetic tree built with `mkdir -p`. Real directories — so the symlink
case *could not appear*. The fixture was shaped like the fix rather than like reality, and the bug
survived two more releases of "verified" work. **Test detection against a real install, or you are only
testing your own assumption.**

### Backend / system / security scenarios (v1.24)

| # | Situation | Before | Verdict → fix |
|---|---|---|---|
| 32 | "fix this bug in the payment flow" / "refactor the auth module" | security fired from Branch A intake + one Branch B checklist item only — **Branches C, D, F had no security trigger at all** | **DARK → fixed v1.24.** The moments a vulnerability moves while every test stays green were the ones with no signal. Mid-work row fires in any branch, plus Branch C and D specifically. |
| 33 | the merge gate on a change touching auth | shipright offered to install a third-party skill; `/security-review` ships with Claude Code, free, and reviews the actual diff | **BUNDLED-IGNORED → fixed v1.24** |
| 34 | "is this reviewed?" on Tier M+ | no dispatch to `/code-review`, which is **user-invoke-only** — a wrong assumption here turns a missing check into a false assurance | **BUNDLED-IGNORED → fixed v1.24** (ask the user; never claim the gate closed) |
| 35 | Branch B full-stack: "define the API contract first" | `api-and-interface-design` was mapped to multi-step forms, an optional registry line and Branch A's ladder — never the moment itself | **WEAK → fixed v1.24** |

**BUNDLED-IGNORED** — a fifth failure mode, and the cheapest to fix: the capability is already installed,
free, and always present, and shipright reached past it for a third-party skill. It got worse the moment
v1.22 taught shipright to *offer installs*: an unnecessary install is now an active cost, not just a
missed shortcut. Before dispatching anywhere, check the bundled set.

### Product / outcome scenarios (v1.25) — the loop that never closed

| # | Situation | Before | Verdict → fix |
|---|---|---|---|
| 38 | user resumes after shipping the MVP two weeks ago | Branch E re-oriented on git, level and tests, and never asked whether the shipped thing worked. Nothing anywhere asked. | **NO-LOOP → fixed v1.25.** `Last shipped` in state + Branch E **Step 1b**, asked before `Next`. |
| 39 | "add feature X" on an existing project | Branch B went from "what's the job" straight to tiering; `Next:` could become another feature while the previous one's outcome was unknown | **NO-LOOP → fixed v1.25.** Step 6 schedules the check and blocks stacking on an unanswered one. |
| 40 | constitution generated at L0 | "success" lived in `## Project` prose — unmeasurable, and no session ever re-read it | **DARK → fixed v1.25.** `## Outcome` is a durable field with a signal, a riskiest assumption (UNTESTED) and a check-by; it is in the L0 gate. |
| 41 | shipright reports "done — tests pass, journey works" | that is an **output** check presented as a done-check; value was never assessed at all | **HALF-ANSWERED → fixed v1.25.** SHIP GATE split: output now, outcome next session. |
| 42 | "add a notifications system" on a project with 3 users | Branch B went from "what's the job" straight to tiering — the expensive-and-unproven case had no gate at all | **NO-GATE → fixed v1.25.** Step 2b value fork, before sizing. Only that one quadrant refuses to proceed. |
| 43 | user asks "should I build X?" without saying "build" or "add feature" | the skill description carried no *whether-to-build* vocabulary — the same failure v1.20 found for the UI hemisphere | **DARK → fixed v1.25.** Description + a Mid-work row + 4 more entry points. |
| 44 | integration that costs money per call, on a free product | viability was nowhere in shipright — not in intake, not in the registry, not in `third-party-apis.md` | **DARK → fixed v1.25.** `product-judgment.md` §1, reached from Branch A's third-party bullet + the Mid-work API row, gated on ongoing cost / PII / support obligation. |

**Row 44 was written before the trigger existed** — the section was there, nothing routed to it, and the
row said "fixed". Caught in the pre-commit audit by grepping for the *word* rather than re-reading the
file, which is the only check that would have found it. **A verdict of "fixed" is a claim about a
firing path, not about a section existing.** Write the row after the grep, not before.

**NO-LOOP** — a sixth failure mode, and the only one that is invisible from inside a single session:
every trigger fires, every ref is correct, every gate passes, and the project still ships things that
change nothing. It is invisible precisely *because* the machinery works. The tell is a state block whose
`Next` is always another feature.

**Why this class was structurally easy to miss, and worth writing down.** An agent verifies
**feasibility** simply by building — the proof arrives for free, as a side effect of the work. **Value**
has no such side effect: nothing about a green test suite reports on it, so unless it is asked
explicitly, it is never asked at all, and its absence produces no error. Every other verdict in this
file describes a trigger that failed to fire. This one describes a question that was never in the file.

### Consistency pass (v1.25.1) — the old failure modes, recurring in files nobody re-read

| # | Situation | Before | Verdict → fix |
|---|---|---|---|
| 45 | full-stack product UI, dispatched from the registry | `full-stack-web` named `minimalist-skill` — the folder name, which `--skill` rejects. v1.20 fixed every other occurrence | **BROKEN-TARGET → fixed v1.25.1** (`minimalist-ui`) |
| 46 | "Core Web Vitals are bad" | `performance.md` handed off to `agent-skills:webperf` / web-performance-auditor — absent from every repo's `--list` | **BROKEN-TARGET → fixed v1.25.1** (measure first, then `vercel-react-best-practices` / `vercel-optimize`, both verified) |
| 47 | Branch B Tier M+ merge gate | the core and v1.24 said the gate closes with `/security-review` + asking for `/code-review`; Branch B — where most merges happen — mentioned neither | **BUNDLED-IGNORED → fixed v1.25.1** (Step 5 "Close the gate") |
| 48 | Branch B/C/D dispatch on an installed skill | branches still read `skill/tdd`, `skill/review`, `skill/taste` — probes v1.23 collapsed into `skill/core` / `skill/ui`. Nothing emits those names any more, so every condition read as absent | **STALE-SNAPSHOT (by name) → fixed v1.25.1** |

Row 48 is the v1.23 slim's own leftover: the probes were renamed in the core and never in the files that
branch on them. **When you rename a probe, grep for its old name across every ref** — the same lesson
as v1.20's install names, one level up.

### Desktop scenarios (v1.26) — a whole project shape with no home

| # | Situation | Before | Verdict → fix |
|---|---|---|---|
| 49 | "build a PC app to manage 10 TikTok accounts" | no registry type, no desktop ref, no description vocabulary — shipright woke only on "build" and routed a desktop app through web-api defaults (no UI-thread rule, secrets in `.env`, no packaging/signing/updates) | **DARK → fixed v1.26.** Description + Mid-work row + registry `desktop-app` + Branch A → `references/desktop.md` |
| 50 | "which stack for our desktop app?" | nothing — the choice would default to whatever the model reached for first, though it's a rewrite to change | **DARK → fixed v1.26.** `desktop.md` §1: decided at L0, team skill first, then OS/UI/footprint; recorded as ADR-001 |
| 51 | "the window freezes when I click Start" (existing project) | the UI-thread contract appeared nowhere | **DARK → fixed v1.26.** Mid-work row (always loaded) + `python.md` / `nodejs.md` pointers → `desktop.md` §2 |
| 52 | "keep each account signed in" | secrets guidance was server-shaped (vault/env); nothing for secrets on the user's disk | **DARK → fixed v1.26.** `desktop.md` §4 (OS secret store + envelope, honest limits) + `security.md` §5 line |
| 53 | "automate posting — there's no button for it" | no viability gate on automating a third-party UI; evasion requests had no stated boundary | **NO-GATE → fixed v1.26.** `desktop.md` §10: official API first → `product-judgment.md` §1; NEEDS_ATTENTION as a human-in-the-loop state; evasion out of scope with the reason |
| 54 | "ship it to the client as an exe" | no packaging, signing or update guidance — unsigned, self-extracting, hand-rolled updates were the silent default | **DARK → fixed v1.26.** `desktop.md` §7 per stack + CI launches the packaged build |

Verified by grep before writing these rows: `references/desktop.md` is reached from SKILL.md (description
vocabulary, a Mid-work row, the map), registry (trigger rows + `desktop-app` entry), Branch A, `python.md`,
`nodejs.md`, `judgment.md` §5b, `ui-design.md` and `security.md`; `python-desktop.md` from SKILL.md,
registry, `desktop.md` and `python.md`.

**A first draft of this release was Python-only** — a whole desktop stack file written as if the language
were given. It wasn't: the user asked for desktop apps and gave one example that happened to be in Python.
The fix was structural, the same shape as `judgment.md` vs the stack files: the *rules* live in a
language-agnostic `desktop.md`, and each stack gets only its mechanics. Choosing the stack is itself the
first desktop decision, so it cannot live inside one stack's file.

### Finding (v1.20) — the trigger can be perfect and still dead-end

v1.17's lesson was *retrieval + timing*. v1.20 adds: **the target must exist**. shipright's UI dispatch
table had been rewritten twice for content quality while pointing at `bugbuster` and
`elite-frontend-design-2026` (never in the repo) and at folder names (`soft-skill`) where the CLI wants
install names (`high-end-visual-design`). Every review passed because the *prose* was excellent and CI
greps only check internal links. The failure is only visible by resolving external names against the
external source — hence the curl commands above, now part of the method.

Second lesson: **detection must not encode an install layout.** Probing
`~/.claude/skills/<repo>/skills/<name>/SKILL.md` works for `git clone` and fails forever for
`npx skills add`; the reverse is also true. Probe the `name:` field inside SKILL.md instead — it is what
the skill *is*, independent of how it got there.

## Finding (v1.17) — and the fix

The "**you were wrong / it changed under you**" family (evolutionary-architecture, requirement-drift)
was **DARK**, and MCP was **WEAK**. Why: these needs surface *mid-construction* — a realization, not a
routing moment and not an operation signal. shipright's triggers were strong at intake (routing) and at
L4 operation signals, but had **no trigger for a construction-time realization**. 16 versions of content
review + CI greps never caught this, because it's a retrieval/timing property, not a content property —
exactly why dogfooding is necessary.

**Fix:** added a **"Mid-work signals"** table to SKILL.md (always-loaded) — a trigger map for realizations
that arise while building, mirroring the L4 operation-signal table. This gives the dark knowledge a
concrete in-session firing path.

## The lesson

shipright's runtime power = **retrieval + timing**, not content depth. The always-loaded core's real job
is to be an excellent **trigger map** (concrete situation → ref), not a knowledge store. Keep this file
current: a new deep ref is not "done" until a scenario here proves it FIRES.
