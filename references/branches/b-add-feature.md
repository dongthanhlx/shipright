## Branch B — Existing project, add feature

> **Working directory**: all files in directory shown in SKILL.md context.
> If CLAUDE.md or ARCHITECTURE.md exist → read them BEFORE asking anything.
> L0→L4 tree: L0 already exists. L1 done (project runs). Entry point is L2.

---

## Step 1 — Intake (one at a time)

```
Q1: "Tên project và 1 câu mô tả nó làm gì?"
Q2: "Feature cần thêm: 'User có thể [làm gì] để [đạt gì]'"
Q3: "Feature này cần module mới hay extend module cũ?"
Q4: "CLAUDE.md và ARCHITECTURE.md có không?"
     → Nếu không có → tạo trước (Branch A Production mode), rồi quay lại đây
```

---

## Step 2 — Read codebase (structured report)

```
Đọc codebase. KHÔNG sửa gì. Report theo format:

## Codebase report: [name]
Entry points:  [file → what it starts]
Module map:    [module] → [1-sentence job] → [depends on]
Data flow:     Request → [A] → [B] → [C] → Response
Patterns:      [what patterns exist, where]
Landmines:     [dangerous areas — global state, tight coupling]
Feature touches: [which modules affected and why]
Unknowns:      [what needs clarification]
```

---

## Step 3 — Health check (tiered)

```
TIER 1 — Blockers (fix before feature):
□ Global mutable state? (module-level vars mutated)
□ Circular dependencies? (run: npx madge --circular src/)
□ Empty catch blocks swallowing errors?
□ Race condition risk with new feature?

TIER 2 — Warnings (proceed with caution):
□ Test coverage of modules being touched?
□ Service importing db directly?
□ Business logic in handler?

Verdict: [SAFE / TIER1-BLOCKER / TIER2-CAUTION]
```

**TIER1-BLOCKER** → estimate effort:
```
Effort < 20% remaining deadline → fix first, separate commit
Effort > 20% deadline → workaround + TODO[fix-before-scale]
Effort > 50% deadline → escalate to team/manager
```

---

## Step 4 — Implement

**Extend existing module:**
```
Entry: L2 for this feature only

[if addyosmani installed]:
  Simple/clear feature → activate incremental-implementation + test-driven-development
  Complex/risky feature → activate spec-driven-development first

[if not installed]:
  1. Write test cases for new behavior (RED — Outside-In TDD)
  2. Implement inside-out: repository → service → handler
  3. Run boundary checklist before commit

Gate: tests GREEN + boundary check pass + no regression
```

**New module needed:**
```
1. Update ARCHITECTURE.md first:
   - Add module: responsibility (1 sentence), public API, forbidden deps
   - Verify: no circular dependency introduced
   - Commit: "docs: add [module] to ARCHITECTURE.md"

2. Then L2 → L3 for new module
   [delegate to addyosmani if installed]
```

---

## Boundary checklist (run after every feature)

```bash
grep -r "shared/db" src/modules/       # must be empty
grep -r "\.service" src/modules/*/index # must be empty
npx tsc --noEmit                        # must pass
```

Manual:
- [ ] Repository returns typed object, not raw row
- [ ] Handler has zero domain if/else
- [ ] Mutation is idempotent (if applicable)

---

## taste-skill (if installed, UI features only)

Activate `design-taste-frontend` only when:
- Feature has user-facing UI components
- DO NOT activate for: backend API, CLI, background jobs
