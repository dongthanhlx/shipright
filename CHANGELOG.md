# Changelog

## [1.25.1] — 2026-09 — Consistency pass: renamed probes, dead targets, and a gate Branch B never closed
A full read of every live file against the core. No new ideas — every fix brings a ref back in line with
what SKILL.md already says. Two of them are the repo's own documented failure modes, recurring.

### Fixed — BROKEN-TARGET, again
- `registry.md` `full-stack-web` dispatched product UI to `minimalist-skill` — the folder name, which
  `--skill` rejects. v1.20 fixed every other occurrence and missed this one. Now `minimalist-ui`.
- `performance.md` sent Core Web Vitals to `agent-skills:webperf` / web-performance-auditor. Neither
  exists in any repo's `--list`. Now: measure first (Lighthouse, or `browser-testing-with-devtools`), run
  the same ladder, then `vercel-react-best-practices` (React/Next) or `vercel-optimize` (on Vercel) —
  both confirmed against `--list`. `vercel-optimize` in the core was checked the same way and is real.

### Fixed — branches still read probe names v1.23 removed
v1.23 collapsed eight probes into `skill/core` and `skill/ui`. Branch B (`skill/tdd`, `skill/review`,
`skill/spec-driven`, `skill/incremental`), Branch C and D and `ui-design.md` (`skill/taste`) still branched
on the old names — which nothing emits any more, so every condition read as "not installed". Rewritten to
test for the skill's install name inside the list the core actually produces.

### Fixed — Branch B's merge gate never closed with a real review
The core and v1.24 say Tier M+ closes with `/security-review` (when auth/payments/untrusted input was
touched) and by asking the user to run `/code-review`, which is user-invoke-only. Branch B — where most
merges happen — mentioned neither. Step 5 gains "Close the gate", and both tier paths point to it.

### Fixed — boundary numbering disagreed with the core
`boundaries.md` numbered Rule 2 = "services never touch the DB" and Rule 3 = "repositories hide
persistence"; the core's Rule 2 is "each layer has one job" and Rule 3 is "modules do not share
databases" — which had no worked example anywhere. Now 2a/2b under Rule 2, plus a real Rule 3 with a
correct/wrong pair and a test. Hook message, `levels.md`, `judgment.md`, `browser-extension.md` follow.
`judgment.md`'s "4 boundaries → essentially never" became "the 5 boundaries", with Boundary 5's
phase-dialled *depth* stated explicitly — "1–4" would have read as permission to skip timeouts.

### Fixed — the CI grep in `code-quality.md`
Used a lookahead `grep` doesn't support, labelled the two checks with each other's numbers, and flagged
repositories for importing the DB (which they must). Now the same suffix pattern as `boundary-guard.sh`,
honouring `shipright-ignore`, verified against a fixture: `'../payments'` and `'../payments/index'` pass,
`'../payments/payment.service'` fails. A first draft of this fix false-positived on intra-module
sub-folders — caught in review; a guard that false-positives gets disabled (`enforcement.md`).

### Smaller
- Restored the `## [1.24.1]` heading, lost when v1.25 was written above it.
- `code-health.md` had two H1s; `debug-intermittent.md` still used Branch C's retired `[B][C][D]` labels
  and had one untranslated line; `resilience.md` said sagas were out of scope while `error-handling.md`
  covers them (only orchestration *at scale* is out); Branch E's `-A7` vs the core's `-A5` documented as
  deliberate (whole block vs. up to `Last shipped`), so nobody "fixes" it.

### Noted, not changed
`composition-patterns` (rejected in v1.21 for an empty description) now ships as
`vercel-composition-patterns` with a real one. Worth re-evaluating on its own merits — not in a
consistency pass.

## [1.25.0] — 2026-08 — The outcome loop: shipright could tell you the code was right, never that it mattered
A product-management audit of shipright, against Cagan (the four risks), Perri (build trap), Torres
(riskiest assumption) and Rumelt (diagnosis before policy). The finding was structural, not cosmetic.

shipright's executive question is *"is this a one-way door, and **is the need real today**?"* — and it
only ever answered the first half. The need was taken on faith at intake and never revisited. Of
Cagan's four risks it hard-covers **feasibility** (the whole construction hemisphere) and part of
**usability** (`ui-design.md`); **value** and **viability** were absent. The reason is worth naming,
because it is specific to an agent: a coding agent verifies feasibility *simply by building*, so
feasibility feels like the whole of "it works". Value cannot be verified that way — so it has to be
asked explicitly, or it silently never gets asked. shipright was, in Perri's exact sense, a very
sophisticated feature factory: superb at *build it right*, one thin moment of *build the right thing*
at intake, and **no feedback loop closing back**.

Concretely, before this release: the CLAUDE.md template had no outcome field (success lived in `##
Project` prose — unmeasurable, never re-read); the SHIP GATE asked *"can a user complete the journey?"*,
an **output** check dressed as a done-check; Branch B went straight from "what's the job" to tiering;
and Branch E — the resume branch, the one moment the loop could close — re-oriented on git, level and
tests and never once asked whether the last thing shipped had worked.

### Added — `## Outcome` in CLAUDE.md, a durable field with a riskiest assumption
Who changes · what CHANGE (not what feature) · the **signal you would actually SEE** · the **riskiest
assumption, marked UNTESTED** · a check-by date or trigger. Deliberately not a KPI: a small real signal
("ops stopped asking in Slack") beats a metric nobody will measure. Filled from intake — Branch A Step 1
now pushes one step past "done" to the change and its signal, and asks which belief being wrong would
make the whole thing pointless (usually about the user, not the tech). In the constitution gate, the
MVP + Production templates, and the orders-api example worked through end to end.

### Added — the SHIP GATE is now two checks, and the second is scheduled, not answered
`OUTPUT` (it builds, tests pass, the journey completes) is answerable at ship time, by you, from the
code. `OUTCOME` (did it work) is answerable by neither — only real usage answers it, and only the user
can report it. So it is **scheduled at ship time and answered at the next session**: the signal goes into
`## Outcome`, the pending check parks in Shipright state as `Last shipped`, and Branch E asks it.
Applies to Branch B too — most shipping happens there, and Step 6 now refuses to set `Next:` to another
feature while the previous check is unanswered. That rule is the build trap in its exact mechanical form.

### Added — Branch E Step 1b, where the loop actually closes
Before `Next`, not after: *"Last session shipped X. What we said would tell us it worked was Y. Did it?"*
Three routed answers — **yes** → mark the assumption VALIDATED and proceed; **no** → stop, do not build
the next feature on an invalidated one, and route by *why* (nobody used it → value, re-open intent;
used but didn't help → the job was misread; couldn't use it → usability, not value); **don't know** →
the signal was unmeasurable, so fix the signal before building anything. Passing tests, a clean build
and a green deploy all report on the output; none of them report on the outcome.

### Fixed — the working-context state probe would have truncated the new field
`grep -A3 … | tail -3` cut off at `Next`, so `Last shipped` never reached session-start context and the
loop would have silently never fired. Widened to `-A5 | tail -5`, with the constraint recorded in the
block itself and in `l0-templates.md`: keep `Last shipped` inside the first 5 lines of the state block.

### Added — `references/product-judgment.md`, the WHETHER half of the executive layer
The loop above closes after shipping; this closes the gap before it. Not a new hemisphere — the
executive layer splits into **HOW MUCH** (`judgment.md`: doors, MVP matrix, stopping — it assumes the
thing is worth building) and **WHETHER** (`product-judgment.md`: is the need real). Contents: the
asymmetry in §0 that makes the whole file necessary; **Cagan's four risks** with shipright's honest
coverage marked per row, including the **viability** questions a solo builder always skips (who answers
the support mail, what does the API bill look like at 100 users, can you legally hold this data —
these rarely kill an idea, they change its shape); **Perri** on output≠outcome with the mechanical tell;
the **riskiest assumption as a product one-way door** plus a four-rung cheapest-test ladder that
explicitly excludes A/B tests and funnels (they need traffic an MVP doesn't have) and one rule that
makes it a test at all — *it must be able to come back NO*; the value fork in full; and **Rumelt's
kernel** mapped onto what shipright already produces (the 5 boundaries and the mode ARE a guiding
policy; ARCHITECTURE.md, ADRs and the debt triggers ARE coherent action — what's missing is one line
of **diagnosis**, since `## Project` is a goal statement, Rumelt's #2 bad-strategy tell).

Every section carries its own "don't apply this here": the file opens by refusing bug fixes, config
changes and decisions the user already reasoned about. Interrogating the value of a 30-minute fix is
the same failure as over-architecting a landing page.

### Added — Branch B Step 2b, the value fork
The last point at which the answer can still be *don't*. Placed after the health check and **before**
tiering, because everything from Step 3 onward answers *how to build it well* — previously Branch B
went from "what's the job" straight to sizing, which is where the build trap enters an existing
project. Four questions (which outcome · **what happens if we DON'T** · the cheapest test · what we're
not building instead), and a routing table where exactly one quadrant refuses to proceed: **unproven
value + expensive build**. Unproven + cheap proceeds — the build *is* the test. Skipped entirely for
Tier-S-shaped work. shipright must state a verdict rather than hide behind a question, and must drop
it once the user answers.

### Firing — the v1.20 lesson applied preemptively
That release's finding was that a whole hemisphere sat dark because the skill description carried none
of its vocabulary. So the description now covers deciding *whether* to build, what to build next, and
whether what shipped worked ("should I build", "is this worth building", "what should I build next",
"did it work", "nobody uses it", "prioritize"), and `product-judgment.md` is reachable from five
places: a Mid-work row, the executive question, Branch A (assumption is load-bearing + build is
expensive), Branch B Step 2b, and Branch E's NO route. Core grew ~30 lines, nearly all of it trigger.

### Caught in the pre-commit audit — three of them, and one was this release's own failure mode
Reviewing the release against the repo's own verdicts before committing, rather than after:
- **BROKEN-TARGET, self-inflicted.** EVALS #44 claimed viability was "fixed v1.25 → `product-judgment.md`
  §1" — and **nothing routed there**. `grep -n "viability"` across the core, Branch A and
  `third-party-apis.md` returned zero. The section existed; no trigger reached it, which by v1.20's own
  definition is indistinguishable from not having written it. Now fires at the moment it's actionable
  (Branch A's third-party bullet + the Mid-work API row), gated on *ongoing cost / PII / support
  obligation* so it stays quiet for an ordinary read-only API. Writing the eval row before verifying the
  trigger is precisely the trap this file has documented three times.
- **The spine says VALIDATE and never validates the need.** SEED → **VALIDATE** → HARDEN → SCALE, where
  VALIDATE = L2–L3 = tests GREEN. A reader would reasonably conclude value validation was already
  covered — the phase name actively argues against the release. Disambiguated in both the core and
  `levels.md`: a project can reach SCALE having never once checked that anyone wants it. Also added
  `## Outcome` to L0's "what done looks like", which was defined in two places and updated in one.
- **`prompts.md` would have generated the old shape.** The passive copy-paste L0 prompt emitted a
  CLAUDE.md with no `## Outcome` and a state block with no `Last shipped` — so anyone using the prompts
  instead of the branches got a silently dead loop. Fixed. Passive files still have to be correct;
  "deliberately has no trigger" is not "deliberately unmaintained".

### Deliberately NOT added
RICE, WSJF, Cost of Delay as a formula, Kano, MoSCoW — org-scale backlog-triage artifacts; for a solo
or small builder they are ceremony producing a number nobody trusts, and a scoring rubric is exactly
the over-engineering shipright warns about everywhere else. The useful residue is kept as *questions*:
cost-of-NOT and opportunity cost. Also out: full opportunity solution trees (need a product trio and
weekly interviews — the reasoning chain is kept, the diagram isn't), the Amazon PR/FAQ (Branch A Step
2a's playback already is the light version, and `## Outcome` is its durable half), and pre-mortems as a
standing ritual (Branch A's "the risk I see" plus the riskiest-assumption question already are one, at
the moment it's useful). Recorded in `product-judgment.md` §6 so none of it gets re-proposed. And no
new master roster — what was missing was a **loop and a gate**, not more frameworks.

## [1.24.1] — 2026-07 — Two runtime bugs found by actually using it
Both caught in a real session, not by review — and both in the working-context block that every session
depends on. The first crashed the skill outright; the second had been silently reporting every correctly
installed skill as missing since v1.20.

### Fixed — a dollar-sign followed by a digit is an ARGUMENT placeholder, not shell syntax
The version probe used an `awk` positional print. Claude Code substitutes `$N` with the invocation's Nth
argument **before the shell runs**, so invoking shipright with any arguments rewrote the awk program into
`{print <a word the user typed>}` and the skill died with `awk: unexpected character`. Replaced with
`sed`. Audited every dollar-digit and the ARGUMENTS token across all skill content: `/shipright-version`
had the same latent bug in a `present()` helper whose `$1` would have been eaten the same way — the
helper is gone, replaced by one listing grep plus membership tests on named variables. The warning
comments themselves had to be rewritten too: written literally, they contained the very tokens that get
substituted.

### Fixed — `grep -r` does not follow symlinked directories, and `npx skills add` symlinks by default
The bigger one. `npx skills add` installs by **symlinking** into `~/.claude/skills/` (that is what
`--copy` exists to opt out of), and lowercase `-r` skips symlinked directories. So every skill installed
the way shipright itself recommends read as **not installed** — `skill/ui` said `NONE` while three taste
skills sat right there, and Check 3 would have offered to install what was already present. All five
probes switched to `-R`.

This is the third revision of this detection and the first one verified against a real install. v1.20
replaced a path-shaped probe with a `name:`-based one; that was right, but it was tested against a
synthetic tree built with `mkdir -p` — **real directories, so the symlink case could not appear**. The
test was shaped like the fix instead of like reality. Both bugs are now exercised against the actual
`~/.claude/skills` and both warnings are recorded in the block itself, where the next edit will see them.

## [1.24.0] — 2026-07 — Backend / system / architecture / security: the bundled skills, and the branches security never reached
A firing audit of the system-side domains, run the same way as the UI one. The refs themselves came out
well — resilience, observability, performance, error-handling, domain-thinking, team-scale,
evolutionary-architecture, third-party-apis and scaling-guide all hold trigger-table rows, and the stack
files fixed in v1.20 survived v1.23's slim intact. Two things did not hold.

### Fixed — shipright was recommending installs for capability it already had
**Claude Code ships bundled skills. shipright dispatched to exactly none of them** (beyond `dataviz` /
`artifact-design`), while telling users to install third-party skills for the same jobs. Since v1.22 this
got actively worse: shipright now *offers to install* things — so it could offer an install for work a
free, always-present skill does better. Now mapped, with a standing rule to reach for them first:
- **`/security-review`** — a real review of the branch's pending changes. This is the missing *execution*
  arm of `security.md`, which owns where security lives but cannot catch what actually got written. The
  old fallback text ("manual OWASP") was selling shipright short: the review was there all along, free.
- **`/code-review`** — the Tier M+ merge gate. **User-invoke-only**, so shipright must *ask the user to
  run it* and must not claim the gate is closed on its own — recorded, because getting that wrong turns
  a missing check into a false assurance.
- **`/run`** — see the system actually work; the non-browser counterpart to the
  `browser-testing-with-devtools` added in v1.21. **`/debug`** for Branch C. **`/claude-api`** before any
  LLM Adapter (Boundary 4) — model ids, pricing, params, token counting, never answered from memory.

### Fixed — security fired at intake and nowhere else
- **Branches C, D and F had no security trigger at all.** Security fired from Branch A's intake and one
  Branch B checklist item — so *fixing a bug in a payment path* or *refactoring auth* triggered nothing.
  That is backwards: those are the moments a vulnerability moves while every test stays green.
  Added a Mid-work signal that fires in **any** branch ("touching auth, a session, a permission check,
  money, PII, file paths, or anything user-controlled"), plus Branch C (a passing test is not the finish
  line — ask what else that gap exposes) and Branch D (characterization tests capture *behavior*, never
  whether the behavior was *safe*).
- The quality gate now closes with a real review on Tier M+ rather than a self-assessment.

### Added — two skills that land squarely in this domain
- **`doubt-driven-development`** — a fresh-context adversarial review of high-stakes decisions, explicitly
  for "security-sensitive logic, irreversible operations". That is shipright's one-way door in someone
  else's words; it is the second opinion the executive question deserves.
- **`api-and-interface-design`** now fires where it matters. It was mapped only to multi-step forms, an
  optional registry line, and Branch A's ladder — never at Branch B's "define the API contract first",
  the exact moment. The fallback also spells out what holding a contract means without the skill.
- **`source-driven-development`** mapped in the trigger index with its tension to `third-party-apis.md`
  §Layer-1 stated honestly: for a third-party API, official docs are the *starting* point — you still
  call the real sandbox and save fixtures. Not added: `git-workflow-and-versioning` (outside shipright's
  spine — it owns architecture decisions, not git hygiene) and `context-engineering`.

### Cost, stated plainly
Core goes **390 → 406 lines, 6113 → 6663 tokens** — one release after v1.23 slimmed it. The bundled table
earns its place in the always-loaded core specifically because Check 3 (offer-to-install) lives there:
the "don't offer an install for something bundled" guard is useless if it only loads after routing. The
security Mid-work row buys in-session coverage for the highest-stakes domain. Both are firing machinery,
which is the part v1.23 said was worth its weight.

## [1.23.0] — 2026-07 — Slim the core again — by principle, and only where it was clearly waste
Three releases of firing fixes put 56 net lines back into the always-loaded core (369 → 425), pushing it
toward the ~460 that v1.16 deliberately cut. This pass takes back 35 lines / ~740 tokens **without
removing a single trigger** — and deliberately leaves the thinking alone.

**What was NOT touched, on purpose.** The Mid-work signals table, the L4 signal table, the executive
question, "How shipright asks", the 5 boundaries, §When workflow is not appropriate, and every
fallback-judgment column. That prose is where shipright *reasons* rather than checklists — compressing it
into fragments would make the skill dumber, not lighter. v1.16's rule still governs: size is a
consequence, not a Goodhart target. Only clear waste was cut.

### Slimmed
- **8 skill probes → 2.** Six near-identical `grep … && echo YES || echo NO` lines for the addyosmani
  skills collapse into one probe that **lists what is present**, matching the pattern already used for
  taste-skill; the taste and vercel probes merge into `skill/ui`. Fewer bytes, six fewer subprocesses per
  session start, and *more* information — dispatch needs the specific name, not a boolean. Check 2's
  table now keys on install names, so it reads directly against the probe output.
- **Install commands lived in three places** (SKILL.md Check 3 + registry.md + ui-design.md) — exactly the
  duplication v1.16 cut between the core and the registry, re-introduced by v1.22 a day earlier. The core
  keeps the *rule* (offer → consent → `--list` for the exact name → install → re-verify) and the
  stale-snapshot warning; the commands live once, in `registry.md` §Install recipes.
- **The reference index was the single largest block in the always-loaded core** (~4.4KB) — and by
  shipright's own doctrine (EVALS: "catalogued but no trigger = DARK") it *causes nothing to fire*. It is
  now a map grouped by role, with descriptions that duplicated the trigger tables cut and **all 42 file
  names kept** so nothing becomes undiscoverable. It opens by saying what it is: reach for it when a
  situation matches none of the tables; a file appearing there is not a reason to load it.
  `prompts.md` is now filed under **Passive** — deliberately trigger-free, not an oversight.

### Verified (the point of a slim pass is proving you took nothing load-bearing)
- All 42 reference files still named in the core. The first draft of the stacks line dropped the `.md`
  extensions and the check caught 9 files falling off the map — fixed before commit.
- No trigger-table row removed: every removed line is an index description, a probe, or a moved command.
- The three instructions whose loss would re-break v1.20/v1.22 all survive: the `--list` discipline
  (wrong install name = the whole dispatch fails), the stale-snapshot warning, and "silence is not consent".
- Probes exercised against both install layouts, present and absent. Check 3's pointer resolves.

Core: **425 → 390 lines, 6851 → 6113 tokens.** Still above v1.19.1's 5313 — the difference is the
firing machinery those releases added, which is the part worth its weight.

## [1.22.0] — 2026-07 — Acquisition: a missing skill is a 10-second problem, not a permanent one
The third firing failure mode. v1.17 found knowledge that never fired. v1.20 found triggers that fired
into names that didn't exist. This one: the trigger fires, the target is real — and it simply isn't
installed, so shipright printed a command and resigned to its fallback. That policy rested on an
assumption nobody had checked.

### Fixed — "not installed" was being treated as permanent
- **Claude Code watches the skill directories.** Per the docs, a skill added under `~/.claude/skills/`
  during a session *"takes effect within the current session without restarting"* (only creating a
  top-level skills dir that didn't exist at startup needs a restart — and it always exists when shipright
  is personal-installed). So the useful move when a trigger fires is not "here's a command for later",
  it's "want it? ten seconds, and I'll use it right now."
- **Check 3 rewritten from *note it* to *offer → install on consent → use it this session*.** Verified
  the mechanics: `npx skills add` detects an agent environment and runs non-interactively (`-y`, `-g`),
  and `--list` prints the exact install names without installing anything. Branch A and Branch B's
  "mention once, then proceed" lines now route to the same flow; registry gained the command recipes.
- **Consent is mandatory and must come from shipright.** Its own `allowed-tools` pre-approves Bash, so
  the harness shows *no* permission prompt — silence would be indistinguishable from approval. This is
  third-party code from GitHub landing in the user's home directory, and the docs warn a skill can grant
  itself broad tool access. Offer once per skill per session; refused → fallback, don't re-ask.
  `-g` (user-level) is the default; project-level writes into the repo and gets committed.
  `skills use <pkg>@<skill>` noted for borrowing a skill without installing it.

### Fixed — the detection snapshot was frozen for the whole session
- The `skill/*` values are dynamic-context injections, rendered **once** when shipright is invoked;
  the docs are explicit that Claude Code does not re-read the skill file on later turns. So a user who
  followed shipright's own advice and installed the skill mid-session kept getting "X not installed —
  using the built-in fallback" for the rest of the session. shipright now re-runs the grep after any
  install and whenever the user says they installed something, instead of trusting the stale snapshot.
  This was a bug under the old policy too.

### Changed
- Name verification now uses `npx skills add <repo> --list` (authoritative — it prints **install** names,
  which is what `--skill` accepts) instead of the GitHub folder listing, which shows folder names that
  differ and fail. EVALS.md updated; the `git clone` install for vercel replaced with the `npx` form.
- EVALS.md gains **NOT-ACQUIRED** / **STALE-SNAPSHOT** verdicts and 2 scenarios.

## [1.21.0] — 2026-07 — Capability additions, curated by trigger (the audit's second half)
The v1.20 audit resolved every dispatched skill name against its real repo. That same pass surfaced
capable skills shipright had **never mapped at all** — a quieter failure than a broken name, but the same
outcome: a real need with no executor. Added only those with a genuine, non-duplicating trigger, and
wired each to a firing surface rather than a catalogue line. Every description below was read from the
skill's own SKILL.md, not inferred from its name (the v1.20 lesson).

### Added — each with the moment it fires
- **`browser-testing-with-devtools`** (addyosmani) — the biggest hole. `ui-design.md` mandates "verify at
  360px with a real thumb" and Branch D's new experience track wants before/after screenshots plus a11y
  output, but shipright had **no way to actually see the page run**. Wired into the mobile-verification
  rule, Branch D step 6, and Branch C's visual-bug repro, with an explicit ban on declaring a UI
  "responsive" or "accessible" from reading code alone. Requires the chrome-devtools MCP server.
- **`vercel-react-best-practices`** (vercel-labs) — React/Next is the `full-stack-web` default stack, and
  `performance.md` is deliberately a stack-agnostic measure-first *ladder*; this is the framework
  execution detail (waterfalls, bundle size, server-vs-client, re-renders). Wired to the L4 latency
  signal and the registry entry. `vercel-optimize` noted for the narrower "the Vercel bill is the
  problem" case.
- **`documentation-and-adrs`** (addyosmani) — shipright's whole executive layer turns on naming one-way
  doors, and an unrecorded one gets re-litigated next session. New Mid-work signal: decision made →
  shipright decides *what* is irreversible, the skill records it properly.
- **`deprecation-and-migration`** (addyosmani) — the contract phase of `requirement-drift.md`'s
  expand → migrate → contract had no executor. Named on that Mid-work row.
- **`ci-cd-and-automation`** (addyosmani) — a fitness function only guards you if it *runs*; named on the
  `evolutionary-architecture.md` Mid-work row.

### Not added (recorded so it isn't re-proposed)
- `code-simplification` → duplicates `code-quality.md` (Fowler smells) + `code-health.md` (Ousterhout
  over-extraction), and Claude Code ships `/simplify`. `planning-and-task-breakdown` → duplicates
  Branch B's complexity tiers + spec-driven. Both added to the SKIP list: loading a skill you would
  duplicate spends context and dilutes reasoning — shipright's own dispatch rule 2.
- `composition-patterns` has an **empty description** in its SKILL.md; unverifiable, so not mapped.
  react-view-transitions / react-native / deploy-to-vercel / vercel-cli / writing-guidelines /
  git-workflow / shipping-and-launch / context-engineering / doubt-driven / source-driven: no clear
  shipright trigger, or too narrow to earn always-loaded space.

### Note on detection cost
The new skills are **checked on demand when their trigger fires**, not probed at session start. Probing
everything every session would cost more context than it saves — the same budget argument shipright makes
about loading skills. Recorded explicitly in the registry so it reads as a decision, not an oversight.
Also confirmed: vercel prefixes some install names (`vercel-react-best-practices`) but not others
(`web-design-guidelines`) — verify each against its own SKILL.md `name:` field.

## [1.20.0] — 2026-07 — System-wide firing audit: the UI/UX layer fires, and the dispatch targets are real
Two audits in one release. **(a)** The hemisphere v1.18/v1.19 built had complete content and correct
judgment wiring into Branch A and Branch B — but the front door didn't open on UI vocabulary, two of six
branches had no experience path, and the taste-skill probe could never return YES. **(b)** Then a
harder question: do the skills shipright dispatches to actually *exist* under the names it uses?
Resolved every external name against the real repos. They largely did not.

A judgment layer that doesn't load is a judgment layer that doesn't exist — and a trigger that fires into
a skill name that was never in the repo is indistinguishable from no trigger at all. EVALS.md gains a
**BROKEN-TARGET** verdict and the curl commands to catch this class, which greps structurally cannot.

### Fixed (BROKEN-TARGET — dispatch pointed at things that don't exist)
- **6 of 8 taste-skill install commands were broken.** The repo's **folder names differ from its install
  names** and `--skill` takes the install name, so `--skill "soft-skill"` fails — it is
  `high-end-visual-design`. Corrected: `minimalist-skill`→`minimalist-ui`,
  `soft-skill`→`high-end-visual-design`, `redesign-skill`→`redesign-existing-projects`,
  `output-skill`→`full-output-enforcement` (`design-taste-frontend` and `imagegen-frontend-web` were
  already right). Every page-type block now carries both names.
- **Two dispatch targets never existed at all**: `elite-frontend-design-2026` (the agency/portfolio
  recommendation) and `bugbuster` (the visual-defect recommendation). Replaced with what the repo
  actually ships — `design-taste-frontend` at high dials, plus `industrial-brutalist-ui` / `gpt-taste`
  when the direction is committed; and `redesign-existing-projects`, whose audit covers hierarchy /
  contrast / spacing, for visual defects.
- **Real skills shipright never mentioned** are now mapped: `brandkit` (the §Logo section deferred to "a
  dedicated design/brand skill" — it exists), `imagegen-frontend-mobile`, `image-to-code`,
  `industrial-brutalist-ui`, `gpt-taste`, `stitch-design-taste`. Also noted that
  `design-taste-frontend` is currently v2-experimental with `-v1` pinnable.
- addyosmani/agent-skills: all 12 dispatched names verified against the repo — **correct, no change**.
  vercel-labs `web-design-guidelines`: verified, install switched to the `npx skills add` form.

### Fixed (detection encoded an install layout, so it could never succeed)
- **Every skill probe was path-shaped.** `npx skills add` installs flat by install name; `git clone`
  nests under `<repo>/skills/<name>/`. A path-shaped probe silently returns NO forever under the layout
  it wasn't written for — and the 6 addyosmani probes assumed the clone layout while README/registry tell
  users to use `npx`. All probes now match the **`name:` field inside SKILL.md**: what the skill *is*,
  independent of how it was installed. Verified against both layouts, quoted and unquoted, with no
  self-match on shipright's own SKILL.md.
- `skill/taste` additionally **lists which taste skills are present** — dispatch depends on the specific
  one, not on "some design skill exists".
- Added `skill/web-a11y` (vercel `web-design-guidelines`), previously undetected though the
  admin/dashboard and a11y-critical paths dispatch to it, plus its fallback row in the session-start table.
- **`/shipright-version` probed `~/.claude/skills/agent-skills/SKILL.md`** — a multi-skill repo has no
  root SKILL.md, so it reported "NOT installed" unconditionally. Now reports each of the 6 skills
  individually, plus the taste family by install name.

### Fixed (shipright's own refs with no firing path)
- **`boundaries.md` was DARK.** The always-loaded core states the 5 rules abstractly; the file holding
  their concrete violation/fix code examples was reachable only from the catalogue index. (Its one other
  mention was a sample `.claude/rules/boundaries.md` inside Branch D — a *project's* file, not
  shipright's ref.) Added a trigger at the boundary block: the moment "does this violate a boundary?"
  isn't obvious from the rule alone.
- **Language stack files fired only from Branch A.** v1.19.1 judged this "acceptable"; re-examined and
  rejected — Branch B/C/D work on *existing* projects, which is most work, and those files carry
  compile-time boundary enforcement (Go `internal/`, PHP Deptrac), timeout/context idioms, the error
  taxonomy and language security footguns. Added a Mid-work signal to load the stack file once before the
  first implementation, and a `load:` line to the registry entries.
- **`domain-thinking.md` (WEAK)** — one parenthetical in Branch A; a Branch B domain feature never
  reached Evans' tactical patterns. **`error-handling.md` (WEAK)** — fired only in Branch C/F to classify
  an existing failure, never while *writing* a failure path. Both now have Mid-work signals.
- **6 registry entries had no `load:` line** (web-api, rag-pipeline, chatbot-telegram-discord,
  browser-extension, full-stack-web, cli-tool) while ai-agent/mcp/blockchain did — so their stack files
  were unreachable from the registry. This also **invalidates EVALS scenario 5's v1.17 "FIRES" verdict**
  for "build a Telegram chatbot": the install list fired, `chatbot-platforms.md` did not. All 6 fixed.
- `prompts.md` remains DARK **by design** (a passive copy-paste library) — now recorded as an accepted
  verdict rather than an unexamined gap.

### Fixed (the front door — highest-leverage gap)
- **shipright's own description had zero UI vocabulary.** No "design", "UI", "landing page", "dashboard",
  "frontend", "redesign", "responsive", "accessibility" — so the entire v1.18/v1.19 UI/UX hemisphere only
  fired when the user happened to say "build" or "add feature". "Redesign this page", "the dashboard looks
  amateur", "make it responsive" didn't wake shipright at all, and `ui-design.md` was never reached.
  Added the surface + the trigger phrases to the frontmatter. Everything downstream was already correct;
  the door was locked.

### Fixed (branches with no experience path)
- **Branch D had no redesign track.** `ui-design.md` mandates "audit before touching anything — do NOT
  jump straight to a taste-skill on existing UI", but nothing routed there: redesigning shipped UI is
  Branch-D-shaped and Branch D never mentioned `ui-design.md`. The Branch-B KIND fork (system vs
  experience) now exists in D as **Step 0**, with a full EXPERIENCE track: audit (skill or manual, against
  the floor) → confirm archetype/tone → separate FLOOR fixes from SCOPE → dispatch → measurable UI DONE →
  before-screenshots as the characterization-test equivalent.
- **Branch D's "no measurable pain → redirect" guard was mis-firing on UI work.** For a brand-facing
  surface, "it looks unprofessional / unusable on my phone" IS the measurable pain — the guard exists for
  code, where tidiness has no user. Step 0 now exempts the experience track explicitly.
- **Branch C didn't recognize visual/UX bugs.** Broken layout, unreadable contrast, no focus ring, missing
  loading/empty/error state — the code "works", so the unit-test-first flow doesn't fit. Step 0 now routes
  them to `ui-design.md`, redefines the repro (360px screenshot, contrast number, keyboard path), and
  hands whole-screen cases to Branch D.
- **No mid-work UI signal.** Same gap class as the v1.19.1 LLM-API fix: realizations that surface
  *during* construction ("this screen only has a happy path", "this table dies at 360px", "these are emoji
  icons") had no firing path. Added two rows to the always-loaded Mid-work signals table.

### Fixed (detection — the probe could never succeed)
- **`skill/taste` checked a path that never exists.** It tested `~/.claude/skills/taste-skill/SKILL.md`,
  but `npx skills add <repo> --skill "X"` installs under the **sub-skill's** name
  (`~/.claude/skills/design-taste-frontend/`) — the repo name never appears on disk. So the probe returned
  NO even for a correct install, permanently. Also inconsistent with `ui-design.md`'s own model
  ("taste-skill is not one skill — it is an ecosystem of 10+"). Now matches the whole family.
- **`vercel-labs/web-design-guidelines` wasn't detected at all**, though the admin/dashboard and
  a11y-critical paths dispatch to it. Added `skill/web-a11y` + its fallback row in the session-start table.
- **`dataviz` / `artifact-design` ship with Claude Code** — documented so shipright stops implying they
  need installing.
- Registry trigger index gained the redesign, visual-defect, and chart rows; the SKILL.md index entry for
  `ui-design.md` still described it as a bare dispatch table (pre-v1.18) — now describes the judgment layer.

## [1.19.1] — 2026-07 — Firing fixes: 3rd-party + LLM API exploration now fire
Patch after a system-wide firing audit (does complete content actually load at the right moment?). The
Layer-1 API-exploration mandate — call the real API → save fixtures → then Adapter + tests — was strong
in content but weakly triggered; now unmissable for both HTTP and LLM APIs.

### Fixed (firing audit — content complete but not firing)
- **System-wide firing audit** (v1.17 dogfood method, every ref). Verdict: top-level refs mostly FIRE;
  `prompts.md` is DARK but correctly so (a passive copy-paste library, pulled by hand, needs no trigger);
  language stack files fire via Branch A's generic "load the matching stack file" + the index (acceptable).
  **One real repeat of the third-party-API gap: LLM API exploration.** An LLM is a third-party API with the
  same "explore before coding, save real responses" mandate (plus token/cost/streaming/error specifics),
  but it only fired via the `rag-pipeline` registry entry — adding an LLM feature in Branch B didn't trigger
  it. Extended the Mid-work API signal and Branch B's system-task path to name **LLM/AI APIs explicitly**
  (→ `third-party-apis.md` §Layer-1 + `stacks/ai-projects.md`).

### Fixed (3rd-party API integration — wire the mandate to fire)
- **Layer 1 API exploration now fires prominently.** `third-party-apis.md` already *mandates* it (call the
  real API/sandbox → save real responses as fixtures → THEN Adapter + unit + contract tests; "the most
  skipped step in AI coding"), but the only trigger was a single conditional line in Branch B Step 0 — not
  reinforced at implement time and with no always-loaded signal, so in practice a "add a YouTube API v3
  integration" task could skip calling the API, saving fixtures, and writing tests. Added an always-loaded
  **Mid-work signal** ("about to call/integrate a NEW 3rd-party API → §Layer-1, MANDATORY") and reinforced
  it in Branch B's Step 3 system-task path. Content was right; the trigger was weak — classic artifact↔runtime gap.

## [1.19.0] — 2026-07 — UI/UX judgment layer + system-vs-experience balance
shipright's UI/UX went from a bare taste-skill dispatch table to a full masters-grounded judgment
hemisphere (emotion, audience, icons, logo, deep mobile, design-brief intake), and the executive layer
learned to balance the system floor against the experience floor — both per project shape and per task.

### Fixed (balance — system vs UI/UX, per project AND per task)
- **Per-task mode detection.** Balancing floors by project shape (§5b) wasn't enough: a full-stack build
  *alternates* system ↔ experience task by task, and Branch B classified only by complexity (tier), with
  "UI features" bolted on as an end appendix — so a UI task ran through a system-shaped flow and hit the
  design brief late (or never). Branch B Step 3 now forks on **KIND first** (system / experience /
  full-stack-spanning) before sizing complexity, routing each to the right intake questions + floor; §5b
  gained a "per task, not just per project" note. So shipright asks the design brief for a UI task and the
  domain/contract questions for an API task — and doesn't cross them.
- **The executive layer now balances system-vs-experience, not just construction-vs-operation.** Review
  after the UI/UX build found the real imbalance: `judgment.md` (the executive) mentioned UI/UX zero times
  and modelled only two hemispheres, so it had no way to weigh architecture against UI/UX — a landing site
  would get the backend 5-boundaries (over-engineering) and a full-stack product's UI could be treated as a
  bolt-on. Added **judgment.md §5b "Which FLOOR does this project need?"**: system floor vs experience
  floor, allocated by project shape (backend → system only; static/marketing → experience only, backend
  boundaries don't apply; full-stack → BOTH, integrated at the API contract). Added a static-site row to §5
  and a "match the floor to the shape" line to SKILL.md's "When workflow is not appropriate". (UI/UX did
  NOT bloat the core — 3 lines — so the imbalance was in *framing*, not footprint.)

### Added (UI/UX — emotion, audience, icons, logo, deeper mobile) + intake wiring
- **Eliciting the design brief** — closes the loop: the audience/emotion judgment needs inputs shipright
  can't read from code (who it's for + how they should FEEL, brand voice, real content/assets), so intake
  must gather them or the judgment stays dark. Added a section teaching HOW — the shipright way (infer +
  confirm, ask only the irreplaceable, never a design questionnaire; calibrate to stakes: brand-facing →
  all, internal CRUD → none). Wired into Branch A's Phase-2b UI trigger so it fires at intake.
- **Emotional design — make it FELT, not the sterile "AI-slop" look** (Aaron Walter *Designing for
  Emotion* + Norman's reflective level). Distinct from the tone axis (which *feeling*) — this is *how* a
  design gets soul instead of dry generic AI output: Walter's hierarchy (delight sits on top of a usable
  base, never instead), and the anti-slop-at-the-soul-level rules — specificity over generic (real
  copy/photos, not lorem/stock), **voice in microcopy** (where personality lives and AI is blandest),
  earned delight, intentional over uniform. Plus the honest boundary: soul needs real human inputs, so
  shipright refuses the generic defaults + mandates specificity/voice + **prompts the human** for the
  irreplaceable bits rather than faking them.
- **Audience & emotional tone** (Norman *Emotional Design* + Jung/Mark & Pearson brand archetypes) — a
  second axis orthogonal to the category archetype: the archetype is set by *what the product does*, the
  tone by *who it's for and how they should feel*. Maps emotional goals (strong/Hero, gentle/Caregiver,
  fresh/Innocent, credible/Sage, refined/Lover) to concrete levers (color temp, type personality, motion,
  density, shape), with an explicit **anti-stereotype guard** (read the emotional job + context, not
  "women→pink"; demographics are a weak hypothesis, not a rule) and a **compose** rule (final direction =
  category × audience tone × brand positioning).
- **Icons — SVG sets, never emoji.** New section: emoji-as-UI-icon is banned (renders differently per OS,
  can't theme/size, not accessible, looks amateur); use one SVG set (Lucide / Heroicons / Phosphor /
  Tabler / Radix / Material Symbols), consistent stroke+size on the type scale, icon+label for nav
  (Nielsen), `currentColor` for theming, proper a11y. Grounded in Material / SF Symbols + Refactoring UI.
- **Logo — use it well (Paul Rand), don't invent a brand here.** Scoped section: shipright implements/uses
  a logo (SVG, favicon set, monochrome + tiny survival, light/dark, clear space, day-one clean-wordmark
  default = MVP-first) and dispatches actual mark design to a designer/brand skill.
- **Mobile-first, deepened to "professional, not crude."** The prior section was rules; added the polish
  that separates professional from phèn — ≥16px body (no iOS zoom), consistent spacing scale, **safe
  areas / notch** (`env(safe-area-inset)`), nav-by-context (bottom tab vs hamburger), mobile forms
  (`inputmode`/`type`/`autocomplete`, Wroblewski), performance-as-polish (no CLS), and **per-industry/
  audience emphasis** (e-commerce / fintech / editorial / admin / consumer / dev-tool).

## [1.18.0] — 2026-07 — UI/UX judgment layer (masters-grounded, MVP-first, wired to fire)
The one domain with zero master grounding now has a full judgment hemisphere: principles decide, vendor
skills execute, and it fires at the right moment (dogfooded, v1.17 method). Also carries the earlier
working-context `Tests:` fix.

### Added
- **UI/UX judgment layer — the one domain that had zero master grounding now has it.** `references/ui-design.md`
  was pure vendor dispatch ("which taste-skill for which page type"); if no design skill was installed the
  fallback was empty, and the whole file was visual/landing-page-centric with no UX (flows, forms, state).
  Added a masters-grounded judgment section — **Norman** (affordance/feedback/mapping/constraints),
  **Nielsen** (heuristics), **Krug** (cognitive load), **Refactoring UI** (hierarchy via weight/spacing,
  grayscale-first), **Fitts + Gestalt**, **Tufte** (→ `dataviz` skill), **WCAG as correctness**, and the
  **state-floor** (loading/empty/error/success, inline validation, confirm-destructive). Applies *even
  without any vendor skill* (capability, not vendor); vendor skills execute, principles decide.
- **Style archetypes + reference sources** — shipright can now *reason about taste*, durably: a
  project-category → native-aesthetic-language → exemplars → dial map (dev-tool / fintech / dashboard /
  consumer / agency / AI-chat / docs / e-commerce / web3), plus a curated pointer list to **living**
  sources (Mobbin, Awwwards, Land-book, Godly; design systems Apple HIG / Material 3 / Polaris / Carbon /
  Geist / Primer; Tailwind UI / shadcn / Radix). Deliberately encodes the *durable* archetype + where-to-
  look, NOT frozen trends (aesthetics churn); direction, not pixels.
- **Landing-page anatomy + conversion** (Krug + Cialdini): the durable section stack (hero → social proof →
  value → objection → proof → pricing → FAQ → repeat-CTA), copy hierarchy (outcome > benefit > feature), and
  per-industry emphasis shifts. The archetype styles it; this decides what goes on it.
- **Admin panels & dashboards — a full pattern language**, the biggest prior gap (taste-skill excludes admin;
  vercel-labs gives rules, not pattern judgment). Grounded in **Tidwell (*Designing Interfaces*)**,
  **Wroblewski (*Web Form Design*)**, **Tufte**: information architecture, data-table conventions (alignment,
  sorting, bulk actions, pagination-vs-scroll, state-floor), faceted filtering + saved views, form/inline-edit
  rules, CRUD + undoable-destructive, chart-selection (which chart for which question → then `dataviz`), and
  the admin state-floor. shipright now owns the *design decisions*; vercel-labs + dataviz execute.
- **"MVP-first applies here too" section** — makes explicit that UI/UX obeys the same one-way/two-way door
  discipline: MVP-first is scope, not quality; the *floor* (a11y, responsive/mobile, IA, semantic HTML, a
  minimal scale — free from a framework) is done day-one, the *scope* (heavy token pipeline, component lib,
  polish) is deferred. Resolves the "proper-from-the-start vs MVP-first" false dichotomy.
- **Mobile & responsive judgment** (Wroblewski *Mobile First*) — the biggest hole in the first pass:
  mobile-first (rank content on the smallest screen), content-driven breakpoints (not device widths),
  touch targets + thumb zone (Fitts for fingers, hover is enhancement-only), reflow patterns, and the two
  hard cases — landing collapse + **data tables on mobile** (key-columns/tap-through, card-per-row, frozen
  first column). Cuts across landing and admin.
- **Dispatch now knows `dataviz`** (charts/dashboards) and **`artifact-design`** (Claude Artifacts).
- SKILL.md UI fallback row rewritten to point at real judgment, not "describe manually".

### Fixed (UI/UX doc)
- **Runtime firing (dogfood, v1.17 method).** Traced whether `ui-design.md` actually loads when a UI/UX
  task happens. It fired from Branch B and session-start detection, but **Branch A (new project) had NO
  trigger** — so a new UI-centric project (landing / dashboard / web app) would never fire the UI judgment
  (a real dark spot). Added a UI trigger to Branch A's Phase-2b scope inference, framed as the day-one
  floor (a11y + mobile) with the heavy stuff MVP-deferred. Also rewrote Branch B's "UI features" trigger:
  it described `ui-design.md` as the old "page type → taste-skill variant" dispatch and wrongly told the
  model to *skip dashboards* — now it points at the judgment layer (which owns admin/dashboards) and
  dispatches from there.
- Anti-slop section re-scoped: it governs **taste-skill's generated output**, not this reference file or
  shipright's reasoning. The em-dash rule no longer reads as a universal typography law (the doc itself
  uses em-dashes) — it's a binary anti-slop signal for generated marketing copy.

### Fixed
- **Working-context `Tests:` injection no longer runs the test suite.** It executed `npm test`/`pytest`
  silently at every session start (before the model reasons, under the broad Bash grant) — slow,
  side-effecting (a suite can truncate a dev DB / spawn servers), and could **hang** the session on
  watch-mode/dev-server test scripts (no timeout — shipright breaking its own Boundary 5 in its own
  bootstrap). The `|| pytest || echo` fallback was also dead: piping to `tail` made the pipeline always
  exit 0, so it never fell through. Replaced with cheap, no-side-effect **runner detection**
  (`npm test` / `pytest` / `none detected`) via `test`/`grep` only.

## [1.17.0] — 2026-07 — Runtime evals: does the knowledge FIRE at the right moment?
Sixteen versions verified the **artifact** — files exist, are linked, are consistent (CI greps). But
the real worry was the **runtime**: shipright *writes and understands* well, yet does the knowledge
actually get pulled into context and applied *at the right moment*? That is a retrieval/timing
property no grep can prove. So this version **dogfoods** shipright: 13 representative scenarios, each
traced from what's actually in-context (SKILL.md always-loaded + the one routed branch) to whether a
**concrete situation-trigger** surfaces the ref the scenario needs.

### Found — a real firing gap 16 versions of content review never caught
Most scenarios FIRE well (L4 signal table, branch security/quality gates, intake questions, executive
questions). But the "**you were wrong / it changed under you**" family was **DARK** — beautifully
written, but with **no in-session trigger**:
- `evolutionary-architecture.md` (a settled decision / domain model turns out wrong) — SKILL match 0,
  no branch trigger. Only reachable via judgment.md §1 (must already be loaded) or the registry.
- `requirement-drift.md` (requirements changed mid-build) — catalogued only.
- `stacks/mcp.md` (exposing tools/data to an AI host) — WEAK, registry entry only.

**Why dark:** these needs surface *mid-construction* — a **realization**, not a routing moment and not
an operation signal. shipright's triggers were strong at intake (routing) and at L4 (operation) but had
**no trigger class for a construction-time realization**. Content review + greps can't see this because
it's about *when* knowledge is retrieved, not *whether* it exists. Only running the scenarios exposed it.

### Fixed
- **Added a "Mid-work signals" table to `SKILL.md`** (always-loaded) — a trigger map for realizations
  that arise while building (wrong decision → evolutionary-architecture; requirements changed →
  requirement-drift; MCP exposure → stacks/mcp; module too big → team-scale; recurring smell →
  code-quality). Sibling to the L4 operation-signal table; gives the dark refs a concrete firing path.
- **Added `EVALS.md`** at repo root — the 13-scenario suite + verdicts + the finding, as a **reusable
  fitness function** for shipright's runtime. Re-run each version; a DARK/WEAK on a high-value scenario
  is a bug. A new deep ref is not "done" until a scenario here proves it FIRES.

### The lesson
shipright's runtime power is **retrieval + timing**, not content depth. The always-loaded core's real
job is to be an excellent **trigger map** (concrete situation → ref) — which is exactly why adding a
small, load-bearing trigger table (not more explanation) is the right kind of growth, even right after
the v1.16 slim.

## [1.16.0] — 2026-07 — Slim the always-loaded core (by principle, not by number)
After 15 versions of adding, the always-loaded core (`SKILL.md`) had grown to 461 lines / ~4.4k
tokens — paid every session — while shipright's own advice says a constitution should be lean.
Applied the discipline of stopping (v1.11) + the lean-constitution principle (v1.7) to shipright itself.

**Not a hard line-count target.** (The first proposal was "cut to <200"; that's a Goodhart trap —
optimizing a proxy metric can cut load-bearing content and *reduce* effectiveness. Rejected.) The
principle instead: **every line in the always-loaded core must be OPERATIONAL (drives a route /
decision / check this session) or an index; move duplication and re-read explanation to the on-demand
refs.** Size is the consequence, not the target.

### Changed — SKILL.md 461 → 347 lines (~1k tokens/session saved), zero load-bearing loss
- Cut **duplication** (safest, highest-value): the ecosystem-dispatch section duplicated `registry.md`'s
  trigger index (−40 lines → conductor principle + pointer); the quality-system section duplicated
  `code-quality.md`/`code-health.md`/`testing.md` (−34 → principle + pointers).
- Compressed **re-read explanation**: the master-roster prose (−17 → a compact list + pointers), the
  lifecycle-spine table (−11 → phase names + pointer), the skill→behavior mapping (−14 → a tight table),
  "when not appropriate" (−5).
- **Kept intact** every load-bearing instruction: the working-context bootstrap, the 6-branch routing,
  BOTH executive questions, the 5 boundaries, skill detection, "how shipright asks", the reference
  index, the L4 signal table, trigger dispatch. Verified present after the cut.

### Changed — shipright's own advice, made consistent
- `l0-templates.md`: reframed "keep the root under 200 lines" → **"every line load-bearing; size is
  the consequence, not the target (Goodhart); move duplication/explanation to @import/rules."** shipright
  now tells users what it just applied to itself.

## [1.15.0] — 2026-07 — Staleness & consistency propagation
A sweep for spots that hadn't caught up with recent versions — the parts that "still used the old
version". Fixed the leftovers, all consistent with what shipped in v0.8–v1.10.

### Fixed
- **Stale version strings**: `prompts.md` header "Current as of v0.7.2" → version-neutral; `go.md`
  "the v0.9 hook" → "the boundary-guard hook" (won't rot). (The `MVP v0.1` in the L0 template is the
  *generated project's* version, not shipright's — left as-is.)
- **Leftover Boundary-5/6 collisions** (the same collision fixed in ai-projects.md at v1.1, missed
  elsewhere): `blockchain.md` "The 5th boundary rule for blockchain" → "Blockchain-specific boundaries
  (beyond the core 5)"; the custodial "6th boundary rule / Boundary 6" (private key) → "the private-key
  boundary (custodial-specific)". Same fix in `prompts.md` and the `registry.md` custodial key
  (`boundary-6` → `key-boundary`). Boundary 5 (v0.8) is integration timeout + fallback — nothing else.
- **Build-order framing** in `prompts.md` still said "inside-out, test-first" (pre-v1.10) → updated to
  the v1.10 model: drive OUTSIDE-IN from behavior, one VERTICAL slice, implement domain-first for convenience.
- **Master roster** in `code-quality.md` still framed as "three masters" (Evans/Uncle Bob/Fowler) →
  added a note that the construction hemisphere grew (Ousterhout, Kent Beck) and an operation hemisphere
  (Nygard, SRE) sits alongside; this file covers the three foundational construction-quality dimensions.

## [1.14.0] — 2026-07 — Framework guidance for the backend stacks
Framework suggestion was inconsistent: the AI/chatbot/blockchain stacks had full "framework decision"
trees, but the general backend stacks either assumed one (python.md was titled "Python + FastAPI") or
listed two without a decision (php.md "Symfony or Laravel"; nodejs "express/fastify"). This makes it
consistent — and states the principle that makes the choice low-stakes.

### Changed — nodejs.md, python.md, go.md, php.md
- Each gains a **"Framework — pick a default, keep it at the edge"** block: a recommended default
  with a one-line reason + when to pick an alternative.
  - Node: **Fastify** (default) · NestJS (structure/DI) · Express (ecosystem) · Hono (edge).
  - Python: **FastAPI** (default) · Django (batteries-included) · Flask/Litestar (micro). python.md no
    longer *assumes* FastAPI — it recommends it (title + framework block reframed).
  - Go: **net/http + chi** (default) · Gin/Echo (batteries) · avoid heavy frameworks.
  - PHP: **Laravel** (default: DX/ecosystem) · Symfony (stricter architecture/DDD) · Slim/Mezzio (micro).
- **The shipright-native principle** (why the choice is low-stakes): the domain/service/repository
  never import the framework, so it's confined to the edge (handler/controller + infrastructure) and
  stays a **two-way door — swappable**. Choosing "wrong" is cheap to fix (judgment.md +
  evolutionary-architecture.md). A domain entity that subclasses the ORM model, or a service that
  imports the framework, is a Boundary-2/4 violation that welds you to it. Recommend, don't agonize.

## [1.13.0] — 2026-07 — PHP stack
### Added
- `references/stacks/php.md` — PHP (8.3+) is now a first-class stack alongside Node.js, Python, and Go.
  Maps shipright's generic terms to modern PHP idioms and leans on the tools that give PHP its rigor:
  - **PHPStan/Psalm at max level = the "does it compile" gate** (PHP has no compiler; static analysis is it).
  - **Deptrac** as a **boundary fitness function** (evolutionary-architecture.md) — enforces module layers
    in CI, since PHP has no compiler-enforced `internal/` like Go.
  - Exception taxonomy (domain 4xx vs infrastructure 5xx; Result-value for expected branches, not exceptions —
    Ousterhout), idempotency (pgx advisory lock + `ON CONFLICT`, money via brick/money — never float),
    Doctrine/Eloquent + PDO prepared statements, Guzzle-with-timeout, Monolog, constructor-injection DI.
  - A **Security** section for the PHP-specific footguns that cause most real breaches: `unserialize()`
    object injection (RCE), mass assignment (`->all()` → privilege escalation), `==` type juggling → auth
    bypass (use `hash_equals` + `===` + `strict_types=1`), SQLi/XSS, `composer audit` supply chain.

### Changed
- SKILL.md reference list + README structure + roadmap.

## [1.12.0] — 2026-07 — Evolutionary architecture (you WILL be wrong)
A review of how shipright handles CHANGE and being WRONG found the core one-way-door thesis was
over-confident about *prediction*: it assumes you can reliably classify what's irreversible and "get
it right up front". The masters of evolutionary architecture challenge exactly this — you can't
predict well, and even carefully-chosen irreversible decisions (the domain model) turn out wrong.
shipright already had the *mechanism* (arch tests in CI, the boundary-guard hook, Strangler Fig,
expand-contract) but never *named* it — the canonical frame (fitness functions) was absent.

Grounded in **Ford, Parsons & Kua** (*Building Evolutionary Architectures* — "guided, incremental
change"; fitness functions), **Bezos** (most decisions are two-way doors), **the Poppendiecks** (the
last responsible moment), **Fowler** (evolutionary design), **Conway**.

### Added — `references/evolutionary-architecture.md`
- **Tempers the one-way-door thesis** (does not replace it): bias toward REVERSIBILITY (a seam turns
  a one-way door into a two-way one — the boundaries are an evolvability technique); for the genuinely
  irreversible, decide at the **LAST RESPONSIBLE MOMENT** (delay to gather information, not procrastinate);
  design for evolvability as a first-class quality.
- **Names shipright's existing fitness functions** and generalizes them: boundary-guard (coupling),
  arch tests / dependency-cruiser (dependency direction/layering), the quality gate, performance
  budgets, SLOs, fault-injection, contract tests — plus the ones to add (cyclic-dep, coupling limits).
  With categories (atomic/holistic, triggered/continual) and the 3-step mechanism (identify dimension
  → define fitness function → automate in the pipeline). "Automated software governance."
- **The recovery path — "a settled decision turned out wrong. Now what?"**: evolve under guard —
  expand-contract (interfaces), Strangler Fig (modules), characterization tests (domain model), with
  the fitness functions kept green. The seam you built to get it right is what lets you fix being wrong.

### Changed
- judgment.md §1: reversibility tempered with evolutionary humility (bias reversible, last responsible
  moment, the recovery path). scaling-guide (arch tests = fitness functions) + enforcement.md
  (boundary-guard = a fitness function) cross-linked. SKILL.md reference list + registry trigger.

## [1.11.0] — 2026-07 — The discipline of stopping (Definition of Done + "good enough")
The executive layer (`judgment.md`) was half-complete: it decided *what to build / defer* but never
*when a thing is DONE*. After many versions of deepening quality, shipright had a strong "do it right"
apparatus and no explicit "stop / good-enough / ship" discipline — ironically risking over-refinement
of the very thing that warns against over-refinement. Knowing when good-enough is good enough is the
most senior discipline of all; this adds it.

Grounded in **Hunt & Thomas** (*The Pragmatic Programmer* — "Good-Enough Software": quality is a
requirements decision; don't spoil a good program by over-refinement; stopping too early is more
common than gold-plating — fix both with feedback), **Ryan Singer** (*Shape Up* — appetite as a
fixed budget, **scope hammering**, "cutting scope is NOT lowering quality"), **Pareto** (the last 20%
costs the most), **Kent Beck** (make-it-work → right → fast), the **Poppendiecks** (gold-plating = waste).

### Changed — `judgment.md` §3b "The discipline of STOPPING"
- **Done = good enough for purpose + stakes, not perfect** — decided up front with the user.
- **The keystone — cut SCOPE, not QUALITY**: the quality FLOOR (the 5 boundaries, one-way doors, the
  quality gate, test-through-the-public-interface) is never hammered; scope/features/polish are the
  variable. Ship a smaller COMPLETE thing, not a larger half-broken one (the guard against "good
  enough" becoming "sloppy"). shipright already had this STRUCTURE — this names it.
- **Appetite as a fixed budget** (Shape Up); done = core journey works + appetite spent, not all-features-built.
- **Stop via feedback, not feel** (ship gate); the stopping tests (confidence-vs-polish, job-done, gold-plating).
- Named shipright's existing stop-mechanisms as one discipline: L4-signal-driven, tech-debt-log-with-
  triggers (a deliberate stop, not a failure), rule-of-three, the SHIP GATE, Beck's sequence.

### Changed — a second executive question (SKILL.md + judgment.md closing)
- Alongside "before you BUILD it: one-way door?" now "**before you keep POLISHING it: good enough
  for the appetite, or gold-plating?**" — the executive layer now governs both advancing and stopping.
- Branch A SHIP GATE wired to the stopping discipline (cut scope to reach done; don't gold-plate; ship + learn).

## [1.10.0] — 2026-07 — Build loop disentangled (outside-in vs inside-out)
A review of the L1→L3 build mechanics found a real internal contradiction: shipright said both
"Outside-In TDD" and "implement inside-out (always follow this)" — in adjacent lines — undistinguished,
and dogmatic ("always"). After v1.9 (testing.md says "test outside-in"), the "inside-out always" in
levels.md was inconsistent with shipright's own newer guidance.

"Outside-in" and "inside-out" name two *different* decisions. Disentangled into three separate axes,
grounded in the masters: **Freeman & Pryce (GOOS — outside-in / London school)**, **Alistair Cockburn**
(walking skeleton), **Hunt & Thomas** (tracer bullet), **Kent Beck** (classicist).

### Changed — levels.md L3 + Branch A/B + SKILL.md
- **1. What DRIVES the design → OUTSIDE-IN (default):** start each feature from its behavior at the
  boundary (an acceptance / walking-skeleton test), then TDD inward (GOOS's double loop). The behavior
  drives; interfaces are discovered. This is what L2's "Outside-In TDD" already meant.
- **2. How you SLICE → VERTICAL, always:** one thin feature end-to-end (the walking skeleton is the
  first slice). Named the horizontal-layer anti-pattern (building all repositories, then all services,
  defers integration to a big-bang and hides risk).
- **3. What order you IMPLEMENT within a slice → a CONVENIENCE, not a law:** domain-first
  (repository → service → handler) because inner pieces have no dependencies and are easiest to test.
  De-dogmatized: replaced "always follow this" — this is a default order, not a rule.
- **Reconciled with `testing.md` (v1.9):** shipright's stance stated explicitly as a deliberate
  synthesis — drive outside-in (GOOS) but mock ONLY at the seams (classicist), never internal
  collaborators. Outside-in *driving* without GOOS's over-mocking; pure mockist over-couples tests to structure.

## [1.9.0] — 2026-07 — Testing strategy spine (anti-dogma)
A foundational review found testing was all TACTICS, no STRATEGY: no test pyramid, no "what to test",
no mockist/classicist guidance, no anti-brittleness rule — scattered across ~18 files — plus a
dogmatic framing ("there is no 'skip tests for speed' mode"). The sharp finding: shipright was **more
dogmatic about TDD than Kent Beck himself**, who wrote his Test Desiderata specifically to counter
that dogma and concluded the answer is "it depends".

### Added — `references/testing.md`
The testing STRATEGY, grounded in the masters and their shared anti-dogma stance: **Kent Beck** (TDD +
Test Desiderata as sliders, not laws), **Fowler** (Test Pyramid, *Mocks Aren't Stubs*, coverage-is-a-
guide), **Cohn** (the Pyramid), **Kent C. Dodds** (the Testing Trophy), **DHH** (test-induced design
damage), **Meszaros** (test smells). Key content:
- The goal is **confidence + good design**, not a test-first ritual or a coverage number.
- **The keystone — shipright's boundaries ARE the test strategy**: test BEHAVIOR through the public
  interface (survives refactoring; kills brittleness), and mock ONLY at the seams (repository /
  Adapter / external systems) — never internal collaborators (the over-mocking that causes DHH's
  test-induced damage). The boundaries tell you exactly where to test and where to mock.
- Shape: **pyramid by default, trophy when it fits** (both tools, not commandments) — put the test
  where the risk lives.
- Kent Beck's **Test Desiderata** as the "good test" checklist; what NOT to test; coverage as a guide.
- A **map** unifying shipright's scattered testing tactics (RED interface tests, LSP contract tests,
  consumer-driven contracts, characterization, fault-injection, property-based, eval-as-tests,
  fixtures, bug-repro) as specialized applications of the same two rules.

### Changed — de-dogmatized the TDD framing (SKILL.md)
- Replaced "there is no 'skip tests for speed' mode" with Beck's own pragmatism: test-first is the
  **strong default for logic** (design pressure + safety net + confidence), but a **tool, not a
  religion** — the goal is confidence + design, not ritual or coverage. Honest narrow exceptions
  (throwaway spike; genuinely trivial no-logic code); never skipped for money/side-effects.

### Wired
- SKILL.md reference list + registry trigger index (brittle/over-mocked/"what to test" → testing.md);
  README structure + roadmap.

## [1.8.0] — 2026-07 — Team scale + sharpened MVP framing
Two threads from a foundational review of "is MVP-first actually the right strategy?" and "how does
shipright hold up when many devs each own a module?". The answer to both: shipright's *mechanism* is
sound (strategic-on-the-irreversible), but its *framing* under-served it. Same primitive, better story.

### Added — `references/team-scale.md` (signal-driven; solo projects skip it)
When multiple developers each own module(s), a boundary stops being "clean architecture" and becomes
the **coordination protocol between people**. Anchored in **Conway** (systems mirror the org),
**Parnas** (information hiding → independent development), **Eric Evans** (Context Mapping), **Skelton
& Pais — Team Topologies** (team API, cognitive load, inverse Conway maneuver), **DORA** (loosely
coupled = the top delivery-performance predictor). Covers: the module boundary AS the team API;
inverse Conway at L0 (design boundaries to match the team); **cognitive load** as the real
module-sizing criterion; context maps; **consumer-driven contract tests** between teams; parallel-work
mechanics (trunk-based, feature flags, boundary-guard as the team-seam enforcer); and when NOT to
extract to services. **One spine, not two systems** — solo and team draw boundaries identically; the
team layer is additive and loads only on the multi-dev signal.

### Changed — sharpened the MVP-first framing (`judgment.md`)
- Distinguished the two real modes the masters split on: **VALIDATION** (Eric Ries — a throwaway-OK
  learning vehicle) vs **FOUNDATION** (most projects — Alistair Cockburn's *walking skeleton done
  right*: thinnest slice, load-bearing architecture correct; thin ≠ tactical).
- **Fowler's Design Stamina Hypothesis**: the design-payoff line arrives "in weeks, not months" — for
  anything that lasts, strategic-on-the-irreversible ships you *sooner*. "MVP-first" is a speed
  consequence, read as "strategic where irreversible, tactical only where genuinely reversible AND cheap".
- **Ousterhout guard**: boundaries stop STRUCTURAL rot, not LOCAL complexity — keep the strategic-
  programming habit (deep modules, define errors out of existence) even in the "hack the rest" column.

### Wired
- Branch A intake: one team-context question (who's building it — the user knows) routes solo vs
  multi-dev; multi-dev → inverse Conway + module-ownership table at L0. Mode reframed to Validation/Foundation.
- boundaries.md reframed (boundary = team API at scale); registry trigger index + SKILL.md reference
  list + scaling-guide cross-link.

## [1.7.0] — 2026-07 — Constitution as a lean, distilled, confirmed contract
A review of how shipright generates CLAUDE.md / ARCHITECTURE.md, checked against Anthropic's own
CLAUDE.md guidance, found the L0 templates had drifted from best practice: the MVP CLAUDE.md inlined
deep conventions (observability, rate-limit, AI) — risking >200 lines and diluting the load-bearing
rules; two divergent MVP templates existed (Branch A inline vs l0-templates); the `## Project`
section was a mechanical Input→Process→Output line instead of the job surfaced in discovery; and the
constitution was generated without a confirmation step.

Grounded in **Anthropic's CLAUDE.md guidance** (keep under 200 lines for adherence; `@import` for
organization; auto memory for incidental learnings; CLAUDE.md is context, a PreToolUse hook is
enforcement) and **Michael Nygard** (the ADR format, already a shipright master).

### Changed — `references/l0-templates.md`
- New principle header: CLAUDE.md is a lean, distilled contract — **keep the root <200 lines**
  (MVP ~50–60); **distill from discovery, don't fill placeholders**; **`@import` deep/optional
  conventions** (don't inline); **CLAUDE.md = durable rules, auto memory = incidental learnings**;
  **CLAUDE.md guides, the boundary-guard hook enforces**; **`@AGENTS.md` interop**.
- MVP CLAUDE.md **leaned**: observability / external-API / AI conventions moved OUT of the inlined
  template into an `@import` block that pulls them in only when the feature exists.
- ADR sections credited to **Nygard's format** (captures the WHY of a one-way-door decision).

### Changed — Branch A (generation)
- `## Project` now distills the **job** (what the user is really hiring this to do, for whom,
  success) from discovery — not a mechanical I/O line.
- New **"Confirm before proceeding"** step: play the distilled constitution back for correction
  before building (a constitution the user didn't confirm won't be honored) — consistent with the
  v1.5/v1.6 conversational philosophy.
- Points to l0-templates.md as the single source (distillation guidance + lean/`@import` structure).

### Changed — modernized compound engineering (SKILL.md)
- Split the "every mistake → a rule" loop by durability: **durable architectural rules → CLAUDE.md /
  `.claude/rules/`**; **incidental learnings (build commands, debugging insights, preferences) → Claude
  Code's native auto memory** (`~/.claude/projects/<project>/memory/`). CLAUDE.md gets smarter
  without getting fatter.

### Added — `/init` awareness (Branch E)
- For an existing codebase with no constitution, start from Claude Code's native `/init` (it analyzes
  the code) and refine with shipright's lean-constitution rules — the code is the source of truth,
  not a from-scratch discovery (which is for new projects).

## [1.6.0] — 2026-07 — Conversational intake across all branches
v1.5.0 fixed Branch A, but the same "form / menu-quiz" anti-pattern lived in the other branches:
Branch B asked "what does it do?" though CLAUDE.md exists and "new module or extend?" (shipright's
call); Branch C front-loaded a bug-type menu before hearing the bug; Branch D — worst — asked the
user to classify their own Fowler smell from a 7-item menu. Ironically Branch E (resume) was already
the correct model (read state → confirm lightly). Rather than patch each branch forever, this makes
the fix structural.

### Added — a shared intake principle (SKILL.md, always-loaded)
- **"How shipright asks — all branches"**: (1) read/infer before you ask — anything derivable from
  CLAUDE.md, the codebase, git, or the user's words; (2) ask only what ONLY the user knows — never
  make them do a technical classification that is shipright's job; (3) diagnose, then CONFIRM with
  evidence — don't menu-quiz; (4) open questions over menus, except where speed matters; (5)
  calibrate depth to stakes. Every branch (and every future branch) inherits it.

### Changed — applied per branch
- **Branch B**: reads CLAUDE.md instead of asking "what does it do?"; asks only the feature intent
  (the job); PROPOSES new-module-vs-extend after the codebase report instead of asking it.
- **Branch C**: the user describes the bug first (repro/actual/expected/error/recent-change);
  shipright INFERS the type (every-time vs intermittent/prod-only/leak) from the description instead
  of front-loading a menu. Steps renumbered (0–4).
- **Branch D**: the user names the measurable PAIN (open); shipright READS the code and DIAGNOSES the
  Fowler smell (or the Ousterhout opposite) with evidence, then confirms — no more "which smell? [A–G]".
- **Branch F**: kept its structured triage checklist, now marked as a deliberate exception (speed
  under incident pressure beats open conversation).

## [1.5.0] — 2026-07 — Intake reimagined (conversation, not questionnaire)
The Branch A intake was mechanical: a fixed Q1→Q7 form that forced an "MVP vs production" binary
before understanding anything, quizzed the user on decisions that are shipright's job ("need
observability from day one?", "data profile: volume/read-write/multi-tenant?"), gave the actual
problem one sentence while spending seven questions on mechanics, and never played understanding
back mid-flow. It extracted what shipright needed to fill its templates instead of understanding
what the user meant.

Reframed as **adaptive intent discovery**, grounded in the masters of discovery: **Rob Fitzpatrick**
(*The Mom Test* — ask about their problem, not your solution; open, non-leading questions),
**Clayton Christensen** (Jobs To Be Done), **Eric Evans** (the early talk is domain discovery, not a
quiz), **Ryan Singer** (Shape Up — appetite sets the mode), and the **interview-me** philosophy (one
real question at a time until ~95% sure of intent).

### Changed — Branch A Steps 1–2 (`a-new-project.md`)
- **Step 1 — understand the idea and the job** (mostly listen): open with the problem, not
  mode/stack; one adaptive question at a time; reach the job-to-be-done (dig one level under the
  stated ask), who/why-now, what success looks like, and the appetite/stakes. Calibrate depth to
  stakes (trivial → 1–2 questions). Dispatch to interview-me/idea-refine if the idea is genuinely
  vague and they're installed.
- **Step 2a — play it back**: reflect the hypothesis in the user's own words and invite correction
  BEFORE any mechanics — the net that catches a misread idea before it becomes wrong code.
- **Step 2b — shipright decides the shape**: mode is INFERRED from appetite (not a cold binary);
  stack is recommended with a reason; observability is shipright's call; API exploration / security
  threat model / AI registry are TRIGGERED by what shipright learned — not asked as a cold quiz.
  Only genuinely user-answerable, load-bearing questions are asked (hard deadline, required integration).
- **Output is always an explicit MVP scope** (walking skeleton = one journey + one-way-doors-now +
  backlog) — the redesign serves MVP-first: you can't cut to the true core without understanding
  the real job. Understanding deepens (fast); build stays deferred; the conversation stays short for MVP.

### Also
- Ecosystem dispatch: interview-me/idea-refine are no longer blanket-skipped — Branch A does intent
  discovery natively and dispatches to them on the "vague idea" trigger.
- Removed stale Q-number references across levels.md, prompts.md, domain-thinking.md.

## [1.4.0] — 2026-07 — Chatbot & blockchain security depth
Deepens the two domains where security matters most, grounded in their masters — and fixes two
anti-patterns found in the existing files.

### Chatbot (`chatbot-platforms.md`)
- **Fixed** the `sanitizeUserInput` regex that stripped "ignore previous instructions" — that is
  security theater (Simon Willison): attackers rephrase infinitely. Replaced with a length cap + a
  warning pointing to the architectural defense.
- **Fixed** the per-user rate limiter that used an in-memory `Map` — it's lost on restart and
  invisible across instances, contradicting the file's own "state in Redis" rule. Now Redis INCR+EXPIRE.
- **Added** an **AI chatbot threat model** section (OWASP LLM Top 10 + Willison): prompt injection as
  an architectural problem (chat text is data, actions authorized by userId not by message content,
  filter output too); abuse & LLM-spend circuit breaker (an open bot is a cost-attack surface);
  content moderation on input+output; conversation isolation & PII/GDPR; least-privilege bot
  permissions (Discord intents, Telegram token).

### Blockchain (`blockchain.md`)
- **Added** copy-paste-correct **defense patterns** for the top vulnerabilities that were only
  named before: Checks-Effects-Interactions + `nonReentrant`, explicit access control, `msg.sender`
  not `tx.origin`, EIP-712 + per-signer nonce for signature replay, and initializer-guarded
  upgradeable proxies. Anchored in OpenZeppelin (use audited libs) + Trail of Bits + the SWC registry.
- **Added** an **invariant & property-based testing** section — Foundry invariant tests (`StdInvariant`,
  `invariant_solvency`/`invariant_accounting`), `--fuzz-runs`, Echidna, and mainnet fork testing.
  This is the Trail-of-Bits-standard defense that was previously only name-dropped.

## [1.3.0] — 2026-07 — Security spine + per-stack security depth
A review found the security coverage lopsided: blockchain / MCP / chatbot were strong, but the most
common backend stacks (Node.js, Python, Go) had almost none — just a boundary grep — and there was
no shared security foundation. This closes that gap, grounded in the field's masters.

Masters: **Saltzer & Schroeder** (the 8 design principles, 1975), **OWASP** (Top 10 2025, API
Security Top 10, Cheat Sheets), **Adam Shostack** (threat modeling). AI security stays anchored in
**Simon Willison + OWASP LLM Top 10** (mcp.md / ai-agent.md), smart contracts in Trail of Bits /
OpenZeppelin (blockchain.md).

### Added
- `references/security.md` — the **architectural security spine**, deliberately NOT a re-implementation
  of the `security-and-hardening` skill: it owns WHERE security lives and WHY (principles + which
  layer/boundary stops which threat) and dispatches implementation depth to the skill. Contains the
  8 Saltzer & Schroeder principles, Shostack's 4-question threat model, the **OWASP Top 10 2025 →
  shipright layer map** (showing the boundaries already buy A04/A05/A10 structurally), the always-on
  controls (secrets, authz-in-service, input validation, supply chain, fail-safe), a per-language
  pitfall table, and an honest "beyond shipright → graduate" list.

### Changed — per-stack security depth (was thin → concrete)
- `nodejs.md`, `python.md`, `go.md`: new **Security** section each — the language-specific mistakes
  Claude actually makes, with the safe pattern and a grep guard (command/SQL injection, insecure
  deserialization [pickle/yaml], `text/template` XSS in Go, SSRF, JWT alg confusion, secrets,
  supply-chain scanners: npm audit / pip-audit + Bandit / govulncheck).
- `browser-extension.md`: new **MV3 threat model** — content script trusts a hostile DOM, message
  sender validation, innerHTML XSS, chrome.storage is not encrypted, no secrets in the extension,
  least-privilege permissions, MV3 remote-code ban.
- `ai-rag.md`: new **RAG-specific security** — indirect prompt injection via retrieved documents,
  authz-scoped retrieval (multi-tenant), PII/secrets in the vector store, data poisoning, grounding.

### Wired to fire (not just documented)
- Branch A intake: new Q5d triggers the L0 threat model for auth/payments/PII/untrusted-input flows.
- Branch B quality gate: new Security block (authz-in-service, parameterized input, no leaked secrets).
- registry trigger index + SKILL.md reference list + README updated.

## [1.2.0] — 2026-07 — Agents & multi-agent depth
Raises agent guidance from a ~300-token registry entry to a full stack file, grounded in the field's
masters: **Anthropic — Building Effective Agents** (workflow vs agent, the 5 composable patterns,
simplicity), **Andrew Ng** (reflection · tool use · planning · multi-agent), **Harrison Chase /
LangGraph** (agents as controllable, persisted state machines with human-in-the-loop), and the
**eval school — Chip Huyen · Hamel Husain · Shreya Shankar** (trajectory evaluation, error analysis).

### Added
- `references/stacks/ai-agent.md` — full agent & multi-agent guide, shipright-native:
  - **Decision 0 — workflow or agent?** (Anthropic simplicity = judgment.md: don't build an agent
    when a workflow suffices; single agent before multi-agent).
  - The **5 workflow patterns** (prompt chaining, routing, parallelization [sectioning/voting],
    orchestrator-workers, evaluator-optimizer) and **Ng's 4 agentic patterns** mapped onto them.
  - The autonomous agent as a **controllable state machine** — explicit persisted state, deterministic
    stop conditions, human-in-the-loop checkpoints, replayable runs.
  - **When multi-agent actually helps** (and when it's over-engineering) + topologies + handoffs as
    typed interface contracts.
  - Boundaries for agents, **resilience** (compounding errors: cap iterations/cost/depth, timeouts,
    idempotent tools, no-progress detector), guardrails/security (untrusted content, least privilege,
    lethal trifecta), **evaluation** (trajectory-level, eval flywheel), and a framework decision.
- `observability.md`: **AI agent & LLM tracing** section — runId + trajectory as the Correlation ID
  of an agent; per-step tokens/cost; alert on runaway cost/looping; replay for non-deterministic bugs.

### Changed
- `ai-projects.md` and the `ai-agent` registry entry now point to the new stack file (was: registry
  entry only). SKILL.md reference list, README structure + roadmap updated.

## [1.1.0] — 2026-07 — MCP support + AI-boundary fix
Grounds the AI hemisphere in the field's masters — the MCP spec, Anthropic's *Building Effective
Agents* (simplicity: workflow before agent), and the security school (Simon Willison's "lethal
trifecta" + OWASP LLM Top 10). The unifying idea: AI isn't a special island — the same boundaries,
judgment, and resilience hold; the failure modes are just probabilistic, plus one new threat class
(prompt injection).

### Added
- `references/stacks/mcp.md` — Model Context Protocol as a first-class stack. Accurate to the spec
  (host/client/server, tools/resources/prompts, stdio vs Streamable HTTP, JSON-RPC lifecycle) and
  framed through shipright's lens: **an MCP server is an Adapter/ACL for a capability; a tool is an
  interface contract (the Agent-Computer Interface)**. Covers when NOT to build a server (judgment —
  a prompt or plain function usually wins), building one behind shipright boundaries, a full
  **security** section (lethal trifecta, prompt injection = untrusted content, least privilege /
  excessive agency, consent, OAuth, confused-deputy), **resilience** (Boundary 5 for tool calls:
  timeouts, idempotency, capped loops, tool-errors-as-data), trajectory observability, and testing
  (MCP Inspector + contract + injection tests).
- registry.md: new `mcp-server` project-type entry (SDKs, transport decision, CLAUDE.md rules).

### Fixed — Boundary-5 naming collision
- `ai-projects.md` and the `rag-pipeline` registry entry called the LLM-ACL rule "Boundary 5",
  which since v0.8 means failure isolation (timeout + fallback). Reframed correctly: the LLM rule is
  **Boundary 4 (Anti-Corruption Layer) applied to AI**, and Boundary 5 (timeout) *also* applies to
  every LLM/tool call. Renamed the registry keys (`llm-boundary`, `llm-boundary-b`, `llm-timeout`).

## [1.0.0] — 2026-06 — BrainOS, feature-complete
First stable release. Every buildable roadmap item is done; shipright is a coherent, public-ready
Project Brain OS. What "1.0" means here:

- **A brain with two hemispheres + an executive.** Construction (Evans · Uncle Bob · Ousterhout ·
  Fowler · Beck) and operation (Nygard resilience · SRE observability), governed by a judgment
  layer that decides how much of each to apply by stage × risk × reversibility (v0.8.0).
- **The pillars actually fire.** All six branches dispatch to judgment / resilience / performance /
  error-taxonomy / Ousterhout at the right moments — not just documented, wired (v0.8.1).
- **Coherent & self-protecting.** One lifecycle spine, trigger-based skill dispatch, a universally
  relatable canonical example (orders-api), and CI that hard-fails on broken links / orphans (v0.8.2).
- **Boundaries that block, not just advise.** An opt-in PreToolUse hook that stops the two worst
  violations before they're written — fails open, self-tested (v0.9.0).
- **Three first-class stacks.** Node.js, Python, and Go (Go gets compile-time Boundary 1 via
  `internal/`) (v0.9.1).

### Fixed
- Roadmap: the "registry capability/signal → skill index" item was completed in v0.8.2 but left
  unchecked — corrected.
- Release hygiene: v0.8.0–v0.9.1 were version-bumped but never git-tagged, which mislead the
  SessionStart update-checker (it compares against the latest tag). Tags backfilled and v1.0.0
  tagged so the update notification works again.

### Changed
- Version → 1.0.0 across SKILL.md + README.

## [0.9.1] — 2026-06 — Go stack support
### Added
- `references/stacks/go.md` — Go is now a first-class stack alongside Node.js and Python.
  Maps shipright's generic terms to Go idioms (package = module, exported identifiers = public API,
  constructor funcs = DI) and leans on two Go features that enforce boundaries for you:
  - **Boundary 1 is compile-time**: module internals under `internal/` cannot be imported from
    outside — the Go compiler rejects it. Stronger than a lint or the v0.9 hook.
  - **Boundary 5 is idiomatic**: `context.WithTimeout` threaded through every I/O call + an
    `http.Client{Timeout}` (never `http.DefaultClient`).
  Also: error taxonomy via sentinel + typed errors + `%w` wrapping, classified once at the HTTP
  edge (declined = operational vs gateway-down = infrastructure); idempotency via pgx advisory lock
  + `ON CONFLICT`; recommended tooling (pgx + sqlc, slog, chi/net-http, goose); `go test -race`
  concurrency note; and a Boundary 2 grep guard (service importing pgx/database/sql).
- Note in go.md: the v0.9 `boundary-guard.sh` hook targets TS/JS/Python conventions; Go gets
  compile-time Boundary 1 from `internal/` instead.

### Changed
- SKILL.md reference list, README structure + roadmap updated (Go stack item completed).

## [0.9.0] — 2026-06 — Boundaries that block, not just advise
### Added — the flagship enforcement hook
- `hooks/boundary-guard.sh` — a **PreToolUse hook** (matcher `Edit|Write`) that inspects the code
  Claude is about to write and **blocks** the two highest-confidence boundary violations before
  they land in a file:
  - **Boundary 2**: a service-layer file importing the shared DB module (`shared/db` or `shared.db`)
  - **Boundary 1**: a deep import into another module's internals (bypassing its public index),
    keyed on `.service`/`.repository`/`.controller`/`.store`/`.gateway` suffixes so `shared/` and
    `config/` never false-positive.
  On a violation it exits 2 with a reason on stderr; Claude reads it and self-corrects (import via
  index / inject a repository) — usually on the next attempt, no human needed.
- `references/enforcement.md` — install (settings.json), what it catches, configuration
  (`SHIPRIGHT_GUARD=off`, module-dir auto-detection), the `shipright-ignore` line bypass, the
  fail-open/no-op guarantees, and explicit limits (project-specific rules stay in CLAUDE.md).

### Design — restraint on purpose
- Enforces ONLY the two universal, near-zero-false-positive rules. Everything project-specific
  stays in CLAUDE.md + the Branch B quality gate. A guard that false-positives gets disabled —
  this is `references/judgment.md` applied to the guard itself (know when NOT to fire).
- **Fails open**: missing jq/python3, malformed input, or any internal error → allow, never block.
  A guard must never brick editing.
- **No-op outside module-structured projects** → safe to enable globally in `~/.claude/settings.json`.
- **Escapable**: a `shipright-ignore` comment on the offending line allows a named, deliberate
  exception (break the rule when you say why — never silently).
- Ships with a built-in **`--self-test`** (11 logic cases) plus verified end-to-end against the
  documented PreToolUse stdin/exit-code contract.

### Changed
- SKILL.md: boundaries section notes the optional enforcement hook; reference list + roadmap updated.
- README: new install block for the PreToolUse hook; "Guards" pitch now mentions blocking, not just
  documenting; structure + roadmap updated.

## [0.8.2] — 2026-06 — Consistency & public-readiness pass
### Changed
- registry.md: added a **Trigger index** (capability/signal → skill) as the PRIMARY dispatch
  path, matching SKILL.md's trigger-based narrative. Project-type packs are now the secondary
  heuristic. "Activate the moment the trigger appears, regardless of stage."
- README: new **"Why shipright?"** section — the 30-second pitch (conductor, not another
  player) answering "why this vs just installing community skills." For public communication.
- **Replaced the canonical example**: news-crawler (a niche data-pipeline shape) → **orders-api**
  (e-commerce orders + payments). More universally relatable AND consistent with the Order/Payment
  examples already used throughout boundaries.md / code-health.md / error-handling.md /
  domain-thinking.md — the example now matches the skill's running teaching domain. It exercises
  every pillar: Money Value Object (no float), Order aggregate + invariants ("can't ship unpaid"),
  payment-gateway Adapter (Boundary 4), idempotent charge + timeout (Boundary 5), error taxonomy
  (declined = operational vs gateway-down = infrastructure), and ADRs that name one-way vs two-way
  doors (judgment.md). Removed both news-crawler example files.

### Removed
- references/onboarding.md — it duplicated SKILL.md's "Route first" router verbatim (legacy
  v0.7). The router lives in the always-loaded core; the duplicate was dead weight. Updated the
  two live references (debug-intermittent.md, README structure).

### CI
- validate.yml: broken internal reference links now **hard-fail** (was a silent warning).
- validate.yml: new **orphan check** — fails if any references/*.md is referenced nowhere.
  (This is the gate that would have caught the v0.5.0 orphan landmine automatically.)

## [0.8.1] — 2026-06 — Wire the v0.8 pillars into the workflow
### Problem fixed
v0.8.0 added the executive layer + operation hemisphere as SKILL.md content and reference
files, but an audit found the 6 BRANCH files (the workflow Claude actually runs each session)
invoked NONE of them — judgment.md / resilience.md / performance.md / Boundary 5 were
documented but never dispatched. The pillars behaved like v0.7. This release threads them in.

### Changed — pillars now fire inside the branches
- Branch F (incident): mitigate → resilience.md containment patterns; investigate → error
  taxonomy (operational/infra/programmer); post-incident → "which Nygard pattern would have
  contained this?" + fault-injection test. An incident now permanently raises fault tolerance.
- Branch A (new project): mode decision → one-way-door budgeting (judgment.md MVP matrix);
  Q2b → domain-thinking.md (aggregates/invariants); MVP CLAUDE.md template gains Boundary 5.
- Branch B (add feature): sizing → executive one-way-door check; quality gate gains a
  Resilience (Boundary 5 + idempotency) block and a Performance (N+1 / bounded sets) block.
- Branch C (fix bug): classify errors by category before handling (error-handling.md).
- Branch D (refactor): Ousterhout lens — watch the OPPOSITE smell (over-extraction / shallow
  modules); fix toward deeper modules is as valid as splitting.

### Changed — resurrected two high-value orphaned files
- references/error-handling.md and references/domain-thinking.md existed on disk, were
  referenced nowhere, and were wrongly listed as "Removed" in the 0.5.0 changelog (see
  correction below). They are high-value (error taxonomy, Result type, saga, race conditions;
  aggregate roots, invariants, domain events). Re-referenced in SKILL.md, cross-linked to their
  hemisphere companions (error-handling↔resilience, domain-thinking↔code-quality/judgment),
  and wired into the branches above.

### Fixed — stale boundary counts (now 5, was drifting between 3/4)
- l0-templates.md: MVP CLAUDE.md template header said "The 3 boundaries" while listing 4 —
  fixed to a count-free header and added Boundary 5. This template generates real constitutions,
  so the stale count was propagating into projects.
- d-refactor.md (.claude/rules example), code-health.md, a-new-project.md gate, blockchain.md,
  prompts.md: genericized passing "N boundary" mentions (per the no-hardcoded-counts convention —
  the numbered list is the source of truth).

### Correction to [0.5.0]
The 0.5.0 entry claimed error-handling.md and domain-thinking.md were "Removed". They were
de-referenced from SKILL.md but never deleted — they remained on disk as orphans until v0.8.1
re-integrated them. The 0.5.0 "Removed" lines below are annotated accordingly.

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
- references/domain-thinking.md (de-referenced — NOTE: not actually deleted; re-integrated in 0.8.1)
- references/error-handling.md (de-referenced — NOTE: not actually deleted; re-integrated in 0.8.1)

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
