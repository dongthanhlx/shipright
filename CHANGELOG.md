# Changelog

## [0.3.1] — 2025-06
### Changed
- Renamed from `senior-dev-workflow` to `shipright`
- Slash command: `/shipright`

## [0.3.0] — 2025-06
### Added
- Branch E: resume/re-entry flow (returning to project after break)
- Branch F: production incident response flow
- `references/branches/` — 6 separate files, one per scenario (lazy loading)
- `references/examples/` — real CLAUDE.md + ARCHITECTURE.md from news-crawler project
- `references/debug-intermittent.md` — intermittent/production-only/resource leak bugs
- `references/stacks/python.md` — Python/FastAPI concrete prompts

### Changed
- onboarding.md → thin router (401 tokens, was 5028)
- SKILL.md cleaned: long prompts moved to references/prompts.md
- Opening question now has 6 options (was 4)
- Branch A: added data questions + synthesis now includes risk assessment
- Branch B: health check now tiered (Tier1 blockers / Tier2 warnings / Tier3 notes)
- Branch C: added bug classification step (consistent/intermittent/prod-only/leak)
- Branch D: added mandatory DONE definition before refactor starts

## [0.2.0] — 2025-06
### Added
- `references/requirement-drift.md` — 3 scenarios when architecture must change
- Expand-Contract pattern for foundational type changes
- Error taxonomy as L0 first-class concern
- Idempotency design questions at L0

### Changed
- TDD order fixed: test-first → interface emerges (was: define interface → write test)
- Stack-specific prompts extracted to `references/stacks/`
- L4 expanded to 3 tracks: Performance, Reliability, Observability

## [0.1.0] — 2025-06
### Added
- Initial 4-level tree process (L0 → L4)
- `references/levels.md`, `references/boundaries.md`, `references/l0-templates.md`
- `references/prompts.md` — copy-paste Claude Code prompts
- `references/stacks/nodejs.md`
- Onboarding flow with 4 branches (A/B/C/D)
