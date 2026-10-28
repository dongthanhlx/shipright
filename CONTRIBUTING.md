# Contributing to shipright

## Adding to the registry

The most impactful contribution is adding a new project type to `references/registry.md`:
- Define: project type name, required skills, tested-with versions
- Add: shipright-adds-to-CLAUDE rules (boundaries, debt signals, CLAUDE.md additions)
- Include: Ubiquitous Language examples for this domain
- Include: test-first setup for this stack/framework

See existing entries (web-api, rag-pipeline, blockchain-dapp) as templates.

## Adding a new stack

The most impactful contribution: stack-specific prompts for languages not yet covered.

**What a stack file needs** (see `references/stacks/nodejs.md` as reference):
1. Generic → concrete name mapping (e.g. "schema validation" → "pydantic v2")
2. Project init prompt for that stack
3. Error hierarchy in that language
4. Boundary check commands (grep equivalents)
5. Idempotency pattern example

**File location:** `references/stacks/[language].md`
**Open an issue first** using the "New stack" template to avoid duplicate work.

## Reporting incorrect guidance

Use the Bug report issue template. The most useful reports include:
- Which branch was triggered (A/B/C/D/E/F)
- What shipright suggested
- What the correct behavior should have been
- Your stack and project type

## What shipright intentionally doesn't cover

- Enterprise compliance (SOC2, HIPAA, PCI-DSS) — needs human + specialized tools
- Multi-repo / monorepo > 500k LOC — see Anthropic's enterprise guidance
- Team topology design — organizational, not technical
- SRE practices (SLO, error budget) — dedicated tooling required

Don't open issues for these — they're outside scope by design.

## Improving existing content

PRs welcome for:
- Clearer explanations of existing concepts
- Better examples in branch files
- Fixes to stale prompts in `references/prompts.md`
- Additional entries in `references/ui-design.md` page type map

Keep PRs focused — one concern per PR.

## Before you open a PR — the same gate CI runs

```bash
bash tests/run-all.sh
```

| Script | What it guards |
|---|---|
| `tests/check-content.sh` | frontmatter; required branch/example files; no broken `references/…` links; no orphaned reference files; **one version** across SKILL.md (frontmatter + H1), README H1 and the top CHANGELOG entry; no argument placeholders (dollar sign + digit, or the ARGUMENTS token) in SKILL.md or `.claude/commands/` — Claude Code substitutes them before any shell runs; the skill lists in SKILL.md and `/shipright-version` name the same skills; **size budgets** for SKILL.md and its description |
| `tests/hooks.test.sh` | `boundary-guard.sh` self-test (unit + end-to-end through the real stdin-JSON path), `check-update.sh` against a real bare remote with annotated tags, `install.sh` against a clone at the install path and a foreign directory |
| shellcheck (`-S warning`) | every `*.sh` |

CI runs the script tests on Linux, macOS with **`/bin/bash` 3.2**, and Windows (Git Bash), because
those are three different bugs: v1.27.1 fixed one of each. To reproduce the macOS run locally:
`BASH_BIN=/bin/bash bash tests/hooks.test.sh`.

The budgets in `check-content.sh` are a ratchet. When you slim the core, lower them in the same PR;
never raise one to make a PR pass. If SKILL.md really must grow, say why in the PR.

## Releasing

1. Bump `version:` in SKILL.md, the README H1, and the SKILL.md H1 if major.minor changed.
2. Add the `## [X.Y.Z] — YYYY-MM — summary` entry at the top of CHANGELOG.md.
3. Runtime finding? Add an EVALS.md row.
4. Merge. `.github/workflows/release.yml` tags `vX.Y.Z` on the release branch's tip, with the
   CHANGELOG heading as the message. `hooks/check-update.sh` reads those tags: an untagged release
   is invisible to every git-installed user.
