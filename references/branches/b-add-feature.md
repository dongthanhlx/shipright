## Branch B — Existing project, add feature

> **Working directory**: all files in directory shown in SKILL.md context.
> If CLAUDE.md or ARCHITECTURE.md exist → read them BEFORE asking anything.
> L0→L4 tree: L0 already exists. L1 done (project runs). Entry point is L2.

---

## Step 1 — Intake (one at a time)

```
Q1: "Project name and one sentence describing what it does?"
Q2: "Feature needed: 'User can [do what] to [achieve what]'"
Q3: "Does this feature need a new module, or extend an existing one?"
Q4: "Do CLAUDE.md and ARCHITECTURE.md exist?"
     → If not → create them first (Branch A Production mode), then return here
```

---

## Step 2 — Read codebase (structured report required)

```
Read the codebase. Do NOT modify anything. Report in this format:

## Codebase report: [name]
Entry points:    [file → what it starts]
Module map:      [module] → [1-sentence job] → [depends on]
Data flow:       Request → [A] → [B] → [C] → Response
Patterns:        [what patterns exist, where]
Landmines:       [dangerous areas — global state, tight coupling]
Feature touches: [which modules affected and why]
Unknowns:        [what needs clarification before coding]
```

---

## Step 3 — Health check (tiered)

```
TIER 1 — Blockers (fix before adding feature):
□ Global mutable state? (module-level variables being mutated)
□ Circular dependencies? (run: npx madge --circular src/)
□ Empty catch blocks swallowing errors silently?
□ Race condition risk with the new feature?

TIER 2 — Warnings (proceed with caution, document):
□ Test coverage of modules being touched?
□ Service importing db directly?
□ Business logic in handler?

Verdict: [SAFE / TIER1-BLOCKER / TIER2-CAUTION] with specific reason.
```

**TIER1-BLOCKER** → estimate effort first:
```
Effort < 20% of remaining deadline → fix first, separate commit
Effort > 20% deadline             → workaround + TODO[fix-before-scale]
Effort > 50% deadline             → escalate before doing anything
```

---

## Step 4 — Classify complexity (mandatory before touching code)

```
Files this feature will touch:
  1 file, obvious change       → Tier S (trivial)
  2–5 files, clear scope       → Tier M (simple)
  5–10 files OR unclear reqs   → Tier L (complex)
  10+ files OR multiple devs   → Tier XL (system-level)
```

**Tier S — Trivial** (1 file, < 30 min):
```
No agent-skills needed.
Shipright handles: write code → boundary check → commit.
Exception: if it's a bug → always activate debugging-and-error-recovery.
```

**Tier M — Simple** (2–5 files, scope is clear):
```
[if test-driven-development installed]:
  → activate for this change
[if code-review-and-quality installed]:
  → activate before merging

[if neither installed]:
  Shipright built-in: write test (RED) → implement → GREEN → boundary check
```

**Tier L — Complex** (5–10 files, requirements need clarification):
```
[if spec-driven-development installed]:
  → activate FIRST, get spec approved
  → then: /build auto
  → activate code-review-and-quality before merge

[if not installed]:
  1. Write acceptance criteria explicitly
  2. Break into sub-tasks, implement one at a time
  3. Test after each sub-task, not at the end
```

**Tier XL — System-level** (10+ files, days of work):
```
→ Update ARCHITECTURE.md FIRST (shipright constitution step)
→ [if addyosmani installed]: spec → planning → /build auto → security → review
→ Feature flag all incomplete work before merging
```

**Gate for all tiers:** tests GREEN + boundary check pass + no regression

---

## Step 5 — Implement

**Extend existing module:**
```
[Tier M+] Write test cases for new behavior (RED — Outside-In TDD)
Interface emerges from what the test needs to call.
Implement inside-out: repository → service → handler
Boundary check before every commit.
```

**New module needed:**
```
1. Update ARCHITECTURE.md first:
   - Add module: responsibility (1 sentence), public API, forbidden deps
   - Verify: no circular dependency introduced
   - Commit: "docs: add [module] to ARCHITECTURE.md"

2. Then L2 → L3 for new module
   [delegate to addyosmani if installed for Tier L/XL]
```

---

## Boundary checklist (run after every feature)

```bash
grep -r "shared/db" src/modules/          # must be empty
grep -r "\.service" src/modules/*/index   # must be empty
npx tsc --noEmit                          # must pass
```

Manual:
- [ ] Repository returns typed object, not raw row
- [ ] Handler has zero domain if/else
- [ ] Mutation is idempotent (if applicable)

---

## taste-skill (if installed, UI features only)

Read `references/ui-design.md` first — pick the right variant for the page type.
Skip entirely for: backend API, CLI, background jobs, data tables.
