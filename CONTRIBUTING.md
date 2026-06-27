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
