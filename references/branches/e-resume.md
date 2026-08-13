## Branch E — Resume / re-orient after a break

> This branch leverages Shipright state in CLAUDE.md for instant re-orientation.
> With state: 30-second resume. Without state: 5-minute orient.

---

## Step 1 — Read state first

```bash
grep -A7 "## Shipright state" CLAUDE.md 2>/dev/null
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

### Step 1b — the outcome check (ask BEFORE the next action, not after)

`Last shipped` in the state carries a pending outcome check from the session that shipped it.
Read it, and read CLAUDE.md `## Outcome`. **If a check is unanswered, that question comes first —
ahead of `Next`.** Resuming is the one moment the loop can close; skip it and it never closes.

```
"Last session shipped [X]. What we said would tell us it worked: [signal].
 Did that happen?"

→ YES  → record it: mark the riskiest assumption in `## Outcome` VALIDATED (with the date and what
         you actually saw), clear `Last shipped`, proceed to Next. A validated assumption is now a
         fact the project can build on — that is what makes the next scope decision cheap.
→ NO   → STOP. Do not proceed to Next. The riskiest assumption has evidence AGAINST it, and the
         next feature would stack on an unvalidated one. **Load `references/product-judgment.md`** —
         the diagnosis and the cheapest next test are there. Ask what actually happened, then route:
         nobody used it → the value assumption was wrong → re-open intent (Branch A Step 1–2a),
         don't build more; they used it but it didn't help → the job was misread → re-open the job;
         they couldn't use it → usability, not value → Branch B on the UI (references/ui-design.md).
→ DON'T KNOW → the signal was unmeasurable, so fix the signal before building anything else.
         Replace it in `## Outcome` with something you can actually observe this week. An outcome
         you cannot check is the same as not having one.
```

**Only the user can answer this — never guess it, and never infer it from the code.** Tests passing,
a clean build, and a successful deploy say the OUTPUT worked; none of them say the outcome did.
If `Last shipped: nothing yet` or the field is absent (project predates this), skip to Step 2.

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
Last shipped: [carry forward unchanged if its check is still unanswered; clear it once answered]
Last updated: [today]
```

This ensures next session resumes in 30 seconds, not 5 minutes.
