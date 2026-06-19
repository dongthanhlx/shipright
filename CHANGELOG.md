# Changelog

## [0.4.1] — 2025-06
### Added
- `hooks/check-update.sh` — SessionStart hook, compares local version with GitHub tags
  Notifies when update available, silent when up to date, never blocks session start
- Companion skill `shipright-version` (separate install):
  Checks version + git status + ecosystem skills + project constitution
- README: install via git clone (recommended for update checks) vs zip

### Changed
- Removed `.claude/commands/` (wrong location — Claude Code doesn't find it there)
- Update flow: `git pull` replaces zip download

## [0.4.0] — 2025-06
### Mission reframe
- Tagline: "Ship your MVP fast. Grow it right."
- Shipright is now explicitly the conductor — delegates execution to addyosmani/agent-skills
- 3 boundaries clarified as the ONLY non-negotiable (Uncle Bob + Fowler backed)

### Added
- MVP mode vs Production mode — Branch A now asks "validate or scale?" first
- Walking skeleton pattern: 1 user journey end-to-end before adding features
- Ecosystem section: addyosmani/agent-skills + taste-skill delegation with exact skills to activate
- 2-mode decision in SKILL.md with irreversible vs signal-driven decision framework

### Changed
- SKILL.md: 388 → 248 lines (removed content duplicating addyosmani)
- Branch A: now generates MVP constitution (minimal) or Production constitution (full)
- Branch B: ecosystem delegation — "if addyosmani installed → activate X" pattern
- Branch C: delegates to debugging-and-error-recovery when addyosmani installed
- Branch D: delegates to code-simplification when addyosmani installed
- l0-templates.md: two versions — MVP (minimal) and Production (full)
- Boundary checklist: kept as grep-able commands (shipright unique value)

### Philosophy
- Fowler's insight applied: 3 boundaries = internal quality that pays off in weeks
  Everything else is signal-driven, not upfront
- Uncle Bob's Dependency Rule = the 3 boundaries in concrete form
- "Irreversible decisions now, everything else when signal comes"

## [0.3.2] — 2025-06
### Fixed
- **Tree mapping clarified**: added explicit table in SKILL.md showing which branch uses which levels
- Branch A: full L0→L1→L2→L3 always
- Branch B: L0 already exists, L1 done — entry point is L2 only. Added clear "Extend vs New module" paths
- Branch C/F: added note "L0→L4 tree không áp dụng" — these have dedicated workflows
- Branch D: added note "đọc L0 nhưng không follow tree sequence — follow refactor workflow"
- Branch E: added Step 4b to detect which level the project is currently at before resuming

## [0.3.1] — 2025-06
### Changed
- Renamed from `senior-dev-workflow` to `shipright`
- Slash command: `/shipright`

## [0.4.1] — 2025-06
### Added
- `hooks/check-update.sh` — SessionStart hook, compares local version with GitHub tags
  Notifies when update available, silent when up to date, never blocks session start
- Companion skill `shipright-version` (separate install):
  Checks version + git status + ecosystem skills + project constitution
- README: install via git clone (recommended for update checks) vs zip

### Changed
- Removed `.claude/commands/` (wrong location — Claude Code doesn't find it there)
- Update flow: `git pull` replaces zip download

## [0.4.0] — 2025-06
### Mission reframe
- Tagline: "Ship your MVP fast. Grow it right."
- Shipright is now explicitly the conductor — delegates execution to addyosmani/agent-skills
- 3 boundaries clarified as the ONLY non-negotiable (Uncle Bob + Fowler backed)

### Added
- MVP mode vs Production mode — Branch A now asks "validate or scale?" first
- Walking skeleton pattern: 1 user journey end-to-end before adding features
- Ecosystem section: addyosmani/agent-skills + taste-skill delegation with exact skills to activate
- 2-mode decision in SKILL.md with irreversible vs signal-driven decision framework

### Changed
- SKILL.md: 388 → 248 lines (removed content duplicating addyosmani)
- Branch A: now generates MVP constitution (minimal) or Production constitution (full)
- Branch B: ecosystem delegation — "if addyosmani installed → activate X" pattern
- Branch C: delegates to debugging-and-error-recovery when addyosmani installed
- Branch D: delegates to code-simplification when addyosmani installed
- l0-templates.md: two versions — MVP (minimal) and Production (full)
- Boundary checklist: kept as grep-able commands (shipright unique value)

### Philosophy
- Fowler's insight applied: 3 boundaries = internal quality that pays off in weeks
  Everything else is signal-driven, not upfront
- Uncle Bob's Dependency Rule = the 3 boundaries in concrete form
- "Irreversible decisions now, everything else when signal comes"

## [0.3.2] — 2025-06
### Fixed
- **Tree mapping clarified**: added explicit table in SKILL.md showing which branch uses which levels
- Branch A: full L0→L1→L2→L3 always
- Branch B: L0 already exists, L1 done — entry point is L2 only. Added clear "Extend vs New module" paths
- Branch C/F: added note "L0→L4 tree không áp dụng" — these have dedicated workflows
- Branch D: added note "đọc L0 nhưng không follow tree sequence — follow refactor workflow"
- Branch E: added Step 4b to detect which level the project is currently at before resuming

## [0.3.1] — 2025-06
### Fixed
- **Working directory confusion**: SKILL.md now injects `pwd`, `ls`, `git status`, and presence of CLAUDE.md/ARCHITECTURE.md at runtime via `!\`command\`` syntax — Claude always knows exactly which folder it's operating in
- Added `allowed-tools: Read, Write, Bash, Glob, Grep` to frontmatter
- Added explicit rule: "ALL file operations happen in current working directory shown above"
- Added working directory reminder to all 6 branch files
- If CLAUDE.md or ARCHITECTURE.md already exist in CWD, Claude reads them before asking questions

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
