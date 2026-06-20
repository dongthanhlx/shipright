# Changelog

## [0.5.3] — 2025-06
### Added
- `references/observability.md`: "Retrofitting observability into existing projects" section
  6-step surgical approach: audit → shared infra → entry points → modules → API adapters → verify
  Key principles: one module per PR, never batch, AsyncLocalStorage flows automatically
  Typical timeline: ~1 week careful incremental work
  "What NOT to do" list: no big-bang rewrite, no signature changes, no OTel at same time

### Changed
- Branch B: added special case trigger for observability retrofit
  "If feature being added is observability → load observability.md retrofit section"

## [0.5.2] — 2025-06
### Added
- `references/observability.md` (415 lines) — full observability guide:
  Correlation ID pattern (Node.js + Python), wired at entry points
  Structured logging conventions — format, what to log, what to never log
  Third-party API tracing — connects Adapter layer (Boundary Rule 4) to logging
  Schema drift detection via normalizer WARN logs (real-time contract test alternative)
  Sentry integration (traction stage), OpenTelemetry (growth stage)
  Alert rules by stage, log search patterns for common production issues
- `references/scaling-guide.md` (389 lines) — 3-stage scaling playbook:
  Stage 1 (team < 20): module ownership, architecture tests, internal events, separate schemas
  Stage 2 (team 10–30): modular monolith patterns, async events, module-level CI
  Stage 3 (team 20–50): Strangler Fig with 4-phase extraction + 4 prompt templates
  "Do not split what you can strengthen" as guiding principle

### Changed
- SKILL.md: added observability L4 signals, Q5b now mentions Correlation ID
- l0-templates.md: observability conventions section added to CLAUDE.md template
- third-party-apis.md: observability integration section added
- prompts.md: Strangler Fig now points to scaling-guide.md for full templates
- Version: 0.5.2

## [0.5.0] — 2025-06 — PUBLISH READY
### Breaking changes
- All user-facing content converted to English (Option B decision)
- Onboarding question: Vietnamese → English
- All branch intake questions: English throughout

### Added
- Language rule in SKILL.md: "Respond in the user's language throughout"
  Skills are English for GitHub discoverability; Claude responds in user's language
- CONTRIBUTING.md — how to add new stacks, report bugs, guiding principles
- README completely rewritten: correct tagline, full ecosystem table, token usage

### Removed
- references/domain-thinking.md (orphaned, 0 references)
- references/error-handling.md (orphaned, 0 references)

### Changed
- README tagline: "Build any software project like a senior engineer" → "Ship your MVP fast. Grow it right."
- README description: honest about scope (not "zero to production-ready" oversell)
- SKILL.md taste-skill section: slimmed from 30 lines to 6, pointer to ui-design.md
- prompts.md: rewritten to align with complexity tiers, ecosystem delegation, Adapter pattern
- Q5b added to Branch A: detect third-party APIs in intake flow

## [0.5.3] — 2025-06
### Added
- `references/observability.md`: "Retrofitting observability into existing projects" section
  6-step surgical approach: audit → shared infra → entry points → modules → API adapters → verify
  Key principles: one module per PR, never batch, AsyncLocalStorage flows automatically
  Typical timeline: ~1 week careful incremental work
  "What NOT to do" list: no big-bang rewrite, no signature changes, no OTel at same time

### Changed
- Branch B: added special case trigger for observability retrofit
  "If feature being added is observability → load observability.md retrofit section"

## [0.5.2] — 2025-06
### Added
- `references/observability.md` (415 lines) — full observability guide:
  Correlation ID pattern (Node.js + Python), wired at entry points
  Structured logging conventions — format, what to log, what to never log
  Third-party API tracing — connects Adapter layer (Boundary Rule 4) to logging
  Schema drift detection via normalizer WARN logs (real-time contract test alternative)
  Sentry integration (traction stage), OpenTelemetry (growth stage)
  Alert rules by stage, log search patterns for common production issues
- `references/scaling-guide.md` (389 lines) — 3-stage scaling playbook:
  Stage 1 (team < 20): module ownership, architecture tests, internal events, separate schemas
  Stage 2 (team 10–30): modular monolith patterns, async events, module-level CI
  Stage 3 (team 20–50): Strangler Fig with 4-phase extraction + 4 prompt templates
  "Do not split what you can strengthen" as guiding principle

### Changed
- SKILL.md: added observability L4 signals, Q5b now mentions Correlation ID
- l0-templates.md: observability conventions section added to CLAUDE.md template
- third-party-apis.md: observability integration section added
- prompts.md: Strangler Fig now points to scaling-guide.md for full templates
- Version: 0.5.2

## [0.5.0] — 2025-06 — English-first release
### Breaking change
- All user-facing content converted to English (was mixed Vietnamese/English)
- Shipright still responds in the user's language — skill language ≠ response language
- Opening question, all branch files, onboarding router: now English

### Added
- Language note in onboarding.md: "responds in user's language automatically"
- CONTRIBUTING.md: how to add new stacks, report issues, what's out of scope

### Removed
- references/domain-thinking.md (orphaned, 0 references)
- references/error-handling.md (orphaned, 0 references)

### Changed
- README: tagline → "Ship your MVP fast. Grow it right."
- README: description → honest scope (not "from empty folder to production-ready")
- SKILL.md: taste-skill section slimmed (duplicated ui-design.md)
- README: added "Works in your language" note

## [0.4.4] — 2025-06
### Added
- Feature complexity classification in Branch B (Tier S/M/L/XL)
  Tier S (1 file): no agent-skills needed
  Tier M (2–5 files): test-driven + code-review
  Tier L (5–10 files): spec-driven → /build auto → review
  Tier XL (10+ files): full lifecycle

### Fixed
- Shipright was controlling WHEN TO INSTALL agent-skills (stage-based) but not
  WHEN TO ACTIVATE each skill (complexity-based). Now both are controlled.
- addyosmani already documented "When NOT to use" per skill —
  shipright now exposes this decision tree at the right moment in Branch B.

## [0.4.3] — 2025-06
### Added
- `references/ui-design.md` — complete taste-skill ecosystem mapping:
  10+ specialized skills, page type → correct skill → dials → anti-slop rules
  Includes pages OUTSIDE taste-skill scope (dashboard → vercel-labs, forms → addyosmani)
- vercel-labs/agent-skills added to ecosystem for dashboard/admin/data UI

### Changed
- SKILL.md: taste-skill section replaced with precise mapping table
  Was: "activate taste-skill for UI modules" (vague, wrong)
  Now: page type → specific skill → dial settings + anti-slop rules summary
- Clarified taste-skill scope: landing/portfolio/redesign only
  NOT dashboards, NOT multi-step forms, NOT data tables

### Fixed
- taste-skill was being suggested generically for "any UI module"
  taste-skill v2 explicitly excludes dashboards and multi-step product UI

## [0.4.2] — 2025-06
### Added
- Boundary rule 4: "No raw external response passes the Adapter layer"
  Added to SKILL.md, l0-templates.md, and CLAUDE.md template
- `references/third-party-apis.md` — complete third-party API strategy:
  3-layer testing (exploration → unit with fixtures → contract),
  Adapter/Normalizer pattern, resilience patterns, tool stack by stage
- `references/levels.md`: Conway's Law team growth signals + graduate checklist
- `references/branches/d-refactor.md`: CLAUDE.md evolution guide
  (.claude/rules/ split, path scoping, compound engineering pattern)
- Stage-based addyosmani/agent-skills install guide (not all 24 at once)
- Q5b in Branch A: detect third-party APIs upfront, trigger strategy

### Changed
- SKILL.md ecosystem section: install by stage (MVP/Traction/Growth), not monolithic
- Identified 3 addyosmani skills to skip when using shipright (interview-me, idea-refine, frontend-ui-engineering)

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

## [0.5.3] — 2025-06
### Added
- `references/observability.md`: "Retrofitting observability into existing projects" section
  6-step surgical approach: audit → shared infra → entry points → modules → API adapters → verify
  Key principles: one module per PR, never batch, AsyncLocalStorage flows automatically
  Typical timeline: ~1 week careful incremental work
  "What NOT to do" list: no big-bang rewrite, no signature changes, no OTel at same time

### Changed
- Branch B: added special case trigger for observability retrofit
  "If feature being added is observability → load observability.md retrofit section"

## [0.5.2] — 2025-06
### Added
- `references/observability.md` (415 lines) — full observability guide:
  Correlation ID pattern (Node.js + Python), wired at entry points
  Structured logging conventions — format, what to log, what to never log
  Third-party API tracing — connects Adapter layer (Boundary Rule 4) to logging
  Schema drift detection via normalizer WARN logs (real-time contract test alternative)
  Sentry integration (traction stage), OpenTelemetry (growth stage)
  Alert rules by stage, log search patterns for common production issues
- `references/scaling-guide.md` (389 lines) — 3-stage scaling playbook:
  Stage 1 (team < 20): module ownership, architecture tests, internal events, separate schemas
  Stage 2 (team 10–30): modular monolith patterns, async events, module-level CI
  Stage 3 (team 20–50): Strangler Fig with 4-phase extraction + 4 prompt templates
  "Do not split what you can strengthen" as guiding principle

### Changed
- SKILL.md: added observability L4 signals, Q5b now mentions Correlation ID
- l0-templates.md: observability conventions section added to CLAUDE.md template
- third-party-apis.md: observability integration section added
- prompts.md: Strangler Fig now points to scaling-guide.md for full templates
- Version: 0.5.2

## [0.5.0] — 2025-06 — PUBLISH READY
### Breaking changes
- All user-facing content converted to English (Option B decision)
- Onboarding question: Vietnamese → English
- All branch intake questions: English throughout

### Added
- Language rule in SKILL.md: "Respond in the user's language throughout"
  Skills are English for GitHub discoverability; Claude responds in user's language
- CONTRIBUTING.md — how to add new stacks, report bugs, guiding principles
- README completely rewritten: correct tagline, full ecosystem table, token usage

### Removed
- references/domain-thinking.md (orphaned, 0 references)
- references/error-handling.md (orphaned, 0 references)

### Changed
- README tagline: "Build any software project like a senior engineer" → "Ship your MVP fast. Grow it right."
- README description: honest about scope (not "zero to production-ready" oversell)
- SKILL.md taste-skill section: slimmed from 30 lines to 6, pointer to ui-design.md
- prompts.md: rewritten to align with complexity tiers, ecosystem delegation, Adapter pattern
- Q5b added to Branch A: detect third-party APIs in intake flow

## [0.5.3] — 2025-06
### Added
- `references/observability.md`: "Retrofitting observability into existing projects" section
  6-step surgical approach: audit → shared infra → entry points → modules → API adapters → verify
  Key principles: one module per PR, never batch, AsyncLocalStorage flows automatically
  Typical timeline: ~1 week careful incremental work
  "What NOT to do" list: no big-bang rewrite, no signature changes, no OTel at same time

### Changed
- Branch B: added special case trigger for observability retrofit
  "If feature being added is observability → load observability.md retrofit section"

## [0.5.2] — 2025-06
### Added
- `references/observability.md` (415 lines) — full observability guide:
  Correlation ID pattern (Node.js + Python), wired at entry points
  Structured logging conventions — format, what to log, what to never log
  Third-party API tracing — connects Adapter layer (Boundary Rule 4) to logging
  Schema drift detection via normalizer WARN logs (real-time contract test alternative)
  Sentry integration (traction stage), OpenTelemetry (growth stage)
  Alert rules by stage, log search patterns for common production issues
- `references/scaling-guide.md` (389 lines) — 3-stage scaling playbook:
  Stage 1 (team < 20): module ownership, architecture tests, internal events, separate schemas
  Stage 2 (team 10–30): modular monolith patterns, async events, module-level CI
  Stage 3 (team 20–50): Strangler Fig with 4-phase extraction + 4 prompt templates
  "Do not split what you can strengthen" as guiding principle

### Changed
- SKILL.md: added observability L4 signals, Q5b now mentions Correlation ID
- l0-templates.md: observability conventions section added to CLAUDE.md template
- third-party-apis.md: observability integration section added
- prompts.md: Strangler Fig now points to scaling-guide.md for full templates
- Version: 0.5.2

## [0.5.0] — 2025-06 — English-first release
### Breaking change
- All user-facing content converted to English (was mixed Vietnamese/English)
- Shipright still responds in the user's language — skill language ≠ response language
- Opening question, all branch files, onboarding router: now English

### Added
- Language note in onboarding.md: "responds in user's language automatically"
- CONTRIBUTING.md: how to add new stacks, report issues, what's out of scope

### Removed
- references/domain-thinking.md (orphaned, 0 references)
- references/error-handling.md (orphaned, 0 references)

### Changed
- README: tagline → "Ship your MVP fast. Grow it right."
- README: description → honest scope (not "from empty folder to production-ready")
- SKILL.md: taste-skill section slimmed (duplicated ui-design.md)
- README: added "Works in your language" note

## [0.4.4] — 2025-06
### Added
- Feature complexity classification in Branch B (Tier S/M/L/XL)
  Tier S (1 file): no agent-skills needed
  Tier M (2–5 files): test-driven + code-review
  Tier L (5–10 files): spec-driven → /build auto → review
  Tier XL (10+ files): full lifecycle

### Fixed
- Shipright was controlling WHEN TO INSTALL agent-skills (stage-based) but not
  WHEN TO ACTIVATE each skill (complexity-based). Now both are controlled.
- addyosmani already documented "When NOT to use" per skill —
  shipright now exposes this decision tree at the right moment in Branch B.

## [0.4.3] — 2025-06
### Added
- `references/ui-design.md` — complete taste-skill ecosystem mapping:
  10+ specialized skills, page type → correct skill → dials → anti-slop rules
  Includes pages OUTSIDE taste-skill scope (dashboard → vercel-labs, forms → addyosmani)
- vercel-labs/agent-skills added to ecosystem for dashboard/admin/data UI

### Changed
- SKILL.md: taste-skill section replaced with precise mapping table
  Was: "activate taste-skill for UI modules" (vague, wrong)
  Now: page type → specific skill → dial settings + anti-slop rules summary
- Clarified taste-skill scope: landing/portfolio/redesign only
  NOT dashboards, NOT multi-step forms, NOT data tables

### Fixed
- taste-skill was being suggested generically for "any UI module"
  taste-skill v2 explicitly excludes dashboards and multi-step product UI

## [0.4.2] — 2025-06
### Added
- Boundary rule 4: "No raw external response passes the Adapter layer"
  Added to SKILL.md, l0-templates.md, and CLAUDE.md template
- `references/third-party-apis.md` — complete third-party API strategy:
  3-layer testing (exploration → unit with fixtures → contract),
  Adapter/Normalizer pattern, resilience patterns, tool stack by stage
- `references/levels.md`: Conway's Law team growth signals + graduate checklist
- `references/branches/d-refactor.md`: CLAUDE.md evolution guide
  (.claude/rules/ split, path scoping, compound engineering pattern)
- Stage-based addyosmani/agent-skills install guide (not all 24 at once)
- Q5b in Branch A: detect third-party APIs upfront, trigger strategy

### Changed
- SKILL.md ecosystem section: install by stage (MVP/Traction/Growth), not monolithic
- Identified 3 addyosmani skills to skip when using shipright (interview-me, idea-refine, frontend-ui-engineering)

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
