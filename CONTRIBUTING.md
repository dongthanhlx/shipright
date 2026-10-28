# Contributing to shipright

## Adding to the registry

The most impactful contribution is a new project-type pack: `references/registry/<type>.md`, plus a
row in the pack table of `references/registry.md`:
- Define: project type name, required skills, tested-with versions
- Add: shipright-adds-to-CLAUDE rules (boundaries, debt signals, CLAUDE.md additions)
- Include: Ubiquitous Language examples for this domain
- Include: test-first setup for this stack/framework

See existing packs (`references/registry/web-api.md`, `rag-pipeline.md`, `blockchain-dapp.md`) as templates.

## Adding a new stack

Equally valuable: a stack file for a language not yet covered.

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

- Enterprise compliance (SOC2, HIPAA, PCI-DSS) — needs humans and specialized tools
- Multi-repo / monorepo > 500k LOC — see Anthropic's enterprise guidance
- Org design for its own sake — `team-scale.md` covers the module boundary as a team API (Conway,
  Team Topologies) only as far as it shapes the code
- Running an SRE function — `observability.md` covers SLOs and error budgets as a design input; on-call,
  incident tooling and paging are out of scope

Don't open issues for these — they're outside scope by design.

## Improving existing content

PRs welcome for:
- Clearer explanations of existing concepts
- Better examples in branch files
- Fixes to stale prompts in `references/prompts.md`
- Additional entries in `references/ui-design.md` page type map

Keep PRs focused — one concern per PR.

## Editing SKILL.md safely

SKILL.md is **templated, then shelled, then loaded every session** — three different ways to break it.
These notes used to live inside its working-context block, where every session paid for them.

- **Argument placeholders.** Claude Code substitutes a dollar sign followed by a digit (0-based:
  `$` + `0` is the first argument) and the all-caps ARGUMENTS token before any shell runs. An awk
  positional print became `print <a word the user typed>` and crashed the skill (v1.24.1). Use `sed`,
  `cut` or a named variable; never a positional parameter. `tests/check-content.sh` enforces this.
- **`grep -R`, not `-r`.** `npx skills add` symlinks skills into `~/.claude/skills`; lowercase `-r`
  does not follow symlinked directories, so every correctly installed skill reads as missing.
- **Probe the `name:` field, never a path.** `npx skills add` (flat, by install name) and `git clone`
  (`repo/skills/<name>/`) produce different layouts; a path-shaped probe returns NO forever under the
  other one. Probes LIST what is present (dispatch needs the name); taste-skill folder names ≠ install
  names (`references/ui-design.md`).
- **Read sections by range, not line count.** `sed -n '/^## X/,/^## /p'` — a fixed `-A<n>` silently drops
  every field past line n. End a probe in `grep .` so "no match" is a failure the `|| echo` fallback sees.
- **Every `` !`…` `` must exit 0.** A failing injected command aborts the whole skill invocation, not just
  its line. Give each one an `|| echo …` fallback, or make it a test that ends in `echo`.
- **Budgets.** The body is a recurring cost in every session that loads shipright. The spec recommends
  < 5,000 tokens; `tests/check-content.sh` holds the line as a ratchet — lower it when you cut.

## Before you open a PR — the same gate CI runs

```bash
bash tests/run-all.sh
```

| Script | What it guards |
|---|---|
| `tests/check-content.sh` | frontmatter; required branch/example files; no broken `references/…` links; no orphaned reference files; **one version** across SKILL.md (frontmatter + H1), README H1 and the top CHANGELOG entry; no argument placeholders (dollar sign + digit, or the ARGUMENTS token) in SKILL.md or `commands/` — Claude Code substitutes them before any shell runs; the skill lists in SKILL.md and `commands/version.md` name the same skills; **size budgets** for SKILL.md and its description |
| `tests/hooks.test.sh` | `boundary-guard.sh` self-test (unit + end-to-end through the real stdin-JSON path), `check-update.sh` against a real bare remote with annotated tags, `install.sh` against a clone at the install path and a foreign directory |
| `claude plugin validate .` | the plugin + marketplace manifests, with the official validator (CI pins the CLI version). Two warnings are expected: `CLAUDE.md` at the root (this repo's own Git policy, not plugin context) and no listing icon |
| shellcheck (`-S warning`) | every `*.sh` — CI uses the ubuntu image's **0.9.0**, and versions disagree (0.11 misses SC2120, which 0.9 fails on). Match it locally: `pip install shellcheck-py==0.9.0.6` |

CI runs the script tests on Linux, Windows (Git Bash), **bash 3.2** in a container, and macOS
(`/bin/bash` 3.2 + BSD tools, best effort: GitHub's macOS pool is often empty), because those are
different bugs: v1.27.1 fixed one per platform. To reproduce the macOS run locally:
`BASH_BIN=/bin/bash bash tests/hooks.test.sh`.

The budgets in `check-content.sh` are a ratchet. When you slim the core, lower them in the same PR;
never raise one to make a PR pass. If SKILL.md really must grow, say why in the PR.

## Releasing

1. Bump `version:` in SKILL.md, `"version"` in `.claude-plugin/plugin.json` (it pins plugin users),
   the README H1, and the SKILL.md H1 if major.minor changed. `check-content.sh` fails on any mismatch.
2. Add the `## [X.Y.Z] — YYYY-MM — summary` entry at the top of CHANGELOG.md.
3. Runtime finding? Add an EVALS.md row.
4. Merge. `.github/workflows/release.yml` tags `vX.Y.Z` on the release branch's tip, with the
   CHANGELOG heading as the message. `hooks/check-update.sh` reads those tags: an untagged release
   is invisible to every git-installed user.
