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

## Must-fire manifest (CI-enforced)

The scenario table above is run by hand. The refs below are the **subset that must never go DARK** —
each surfaces *mid-session* (a realization or a signal), so it needs a concrete situation-trigger in the
**reachable** context, not just a line in the reference index. CI (`validate.yml`) enforces this on every
PR: for each path here, its basename must appear in the **trigger zone** = SKILL.md *above* the
"Reference files — load on demand" index, **or** in any `references/branches/*.md`. Appearing only in the
index (the catalogue) = DARK = hard fail. This is the v1.17 finding turned into a permanent fitness function.

**To enforce a new deep ref: add its path to this list.** It then cannot merge until it has a live trigger.

```must-fire
references/evolutionary-architecture.md
references/requirement-drift.md
references/stacks/mcp.md
references/security.md
references/performance.md
references/resilience.md
references/observability.md
references/team-scale.md
references/testing.md
references/code-quality.md
references/code-health.md
references/third-party-apis.md
```

## The lesson

shipright's runtime power = **retrieval + timing**, not content depth. The always-loaded core's real job
is to be an excellent **trigger map** (concrete situation → ref), not a knowledge store. Keep this file
current: a new deep ref is not "done" until a scenario here proves it FIRES.
