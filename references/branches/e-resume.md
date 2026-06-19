## Branch E — Resume / re-entry

> Working directory: all files in directory shown in SKILL.md context.

---

## Step 1 — Orient (5 minutes, no code yet)

```bash
git log --oneline -20    # what happened last?
git status               # uncommitted changes?
git stash list           # forgotten stash?
git branch -a            # which branch, any WIP branches?
```

---

## Step 2 — Read docs if exist

Read CLAUDE.md and ARCHITECTURE.md (already detected in context above).
If neither exists → use Branch A (Production mode) to reconstruct from codebase first.

---

## Step 3 — Find last position

```
Look for "where did I stop?":
- TODO/FIXME nearest to last commit area
- Last commit message: what was being built?
- Open PRs or issues if any
- RED tests in uncommitted changes (WIP indicator)
```

---

## Step 4 — Detect which level project is at

```
[ ] No L0 (no CLAUDE.md / ARCHITECTURE.md)
    → Use Branch A to create before anything else

[ ] L0 exists, L1 not done (project doesn't compile or run)
    → Return to L1: fix build, no new features

[ ] L1 done, L2 incomplete (interfaces missing, tests not written yet)
    → Return to L2: define interfaces, write test cases

[ ] L2 done, L3 in progress (tests RED correctly, feature being built)
    → Continue L3: find which test is RED, implement to make it GREEN

[ ] Normally in L3 loop (tests GREEN, need next feature)
    → Use Branch B for next feature

[ ] Production signal needs L4
    → Read SKILL.md Step 6 (L4 hardening section)
```

---

## Step 5 — Health check

```bash
npm test / pytest / go test
```

GREEN → continue from detected level
RED → fix tests before doing anything else
(Who broke them? WIP from before? Or someone else?)

---

## Step 6 — State next action clearly

```
Write: "Project is at [Level]. Next action: [verb + object + acceptance criteria]"
Do not start coding until this sentence is clear.

Good: "Project at L3. Next: implement OrderService.cancelOrder()
       — test cases exist in service.test.ts, currently RED"
Good: "Project at L0 missing. Next: create CLAUDE.md + ARCHITECTURE.md
       using Branch A Production mode"
Bad:  "Continue the orders module"
Bad:  "Fix remaining stuff"
```
