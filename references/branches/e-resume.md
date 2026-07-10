## Branch E — Resume / re-orient after a break

> This branch leverages Shipright state in CLAUDE.md for instant re-orientation.
> With state: 30-second resume. Without state: 5-minute orient.

---

## Step 1 — Read state first

```bash
grep -A6 "## Shipright state" CLAUDE.md 2>/dev/null
```

**If state exists:**
```
Report to developer:
"Welcome back. Project state:
  Level: [Level]
  Working on: [module]
  Next action: [specific action]
  Last session: [date]

Ready to continue? Or has something changed?"
```

Skip steps 2-5 if developer confirms → go directly to next action.

**If no state → continue to Step 2 (full orient)**

---

## Step 2 — Git orient (5 min, no code)

```bash
git log --oneline -10    # what happened?
git status               # uncommitted work?
git stash list           # forgotten stash?
git branch -a            # which branch? WIP branches?
```

Read CLAUDE.md + ARCHITECTURE.md fully.
If neither exists → the code already exists, so start from what the code says: run Claude Code's
native `/init` (it analyzes the codebase and drafts a CLAUDE.md), THEN refine it with shipright's
lean-constitution rules (l0-templates.md) — boundaries, Ubiquitous Language, the one-way doors.
(Branch A's discovery is for NEW projects with no code; here the code is the source of truth.)

---

## Step 3 — Detect level

```
[ ] No L0 (no CLAUDE.md / ARCHITECTURE.md)
    → Branch A to create constitution

[ ] L0 exists, L1 not done (project won't compile/run)
    → Fix build errors. No new features.

[ ] L1 done, L2 incomplete (interfaces/tests missing)
    → Write interfaces + RED tests before implementing

[ ] L2 done, L3 in progress (RED tests exist, feature being built)
    → Find which test is RED → implement to GREEN

[ ] L3 loop (tests GREEN, next feature needed)
    → Branch B for next feature

[ ] Production signals firing
    → Read L4 signals in SKILL.md
```

---

## Step 4 — Health check

```bash
npm test 2>/dev/null || pytest -q 2>/dev/null || go test ./...
```

GREEN → continue from detected level.
RED → fix failing tests before anything else.
Committed RED tests = someone left WIP. Trace via git log.

---

## Step 5 — State next action clearly

Write before coding:
```
"Project is at [Level]. Next: [verb + object + acceptance criteria]"
```

Good: "L3. Next: implement OrderService.cancelOrder() — RED test exists in service.test.ts line 47"
Good: "Missing L0. Next: Branch A constitution, production mode"
Bad:  "Continue the orders thing" / "Fix remaining stuff"

**Write state to CLAUDE.md before proceeding:**
```markdown
## Shipright state
Level: [detected level]
Active: [module]
Next: [specific action]
Last updated: [today]
```

This ensures next session resumes in 30 seconds, not 5 minutes.
