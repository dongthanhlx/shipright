## Branch D — Refactor / improve architecture

> **L0→L4 tree: read L0 docs to understand intent, do NOT follow tree sequence.**
> Refactor uses characterization tests + atomic steps — not L1/L2/L3.
> Working directory: all files in directory shown in SKILL.md context.

---

## Step 1 — Define the pain (reject vague goals)

```
Q1: "What specifically is causing pain, measurably?
     [A] Adding feature X takes [N days] — should take [M hours]
     [B] Bug takes [N hours] to find because code is complex
     [C] Test suite takes [N minutes] — too slow for CI
     [D] Performance: [metric] = [value], target = [target]
     [E] Preparing for: larger team / data volume / service extraction"

Q2: "Which specific module or file is the problem?"

Q3: "Which Fowler smell best describes it?
     [A] Long Method — functions > 20 lines, hard to understand
     [B] Feature Envy — code belongs in a different class
     [C] Primitive Obsession — using string/int where domain type belongs
     [D] Divergent Change — one class changes for many reasons (SRP violation)
     [E] Shotgun Surgery — one change requires edits in many files
     [F] Data Clumps — same fields always appear together, need a class
     [G] Comments explaining WHAT — rename instead"
```

Identifying the specific smell is the DONE condition for naming what to fix.
Load `references/code-quality.md` Fowler section for specific refactoring move.

If the answer is "the code looks messy" or "I want to restructure":
→ Redirect: "Refactor without measurable pain rarely delivers value.
   Use the codebase for a few more days, note the real friction points."

---

## Step 2 — Define DONE (mandatory before starting)

```
Pick one — must be measurable or binary:
□ "Adding feature [X] will take < [N hours]" — measurable
□ "npx madge --circular returns empty" — binary
□ "Coverage of touched paths > 80%" — binary
□ "Refactor complete in [N days] — time-boxed, no extension"

Cannot define DONE → do not refactor now.
```

---

## Step 3 — Characterization tests FIRST (non-negotiable)

```typescript
// PURPOSE: capture EXACTLY what the code does NOW (even if wrong)
// NOT: test expected behavior

// Correct — snapshot captures current behavior
it('CHARACTERIZATION: current behavior of getUser', () => {
  const result = userService.getUser(1)
  expect(result).toMatchSnapshot()  // fails if ANYTHING changes
})

// Wrong — this tests expected behavior, not current
it('should return correct fields', () => {
  expect(result.id).toBe(1)
})
```

Coverage target: 100% of code paths THAT WILL BE TOUCHED.
Not 60% overall — just the paths changing.
Run tests → GREEN. From here: tests must never go RED during refactor.

**[if addyosmani code-simplification installed]** → activate for Chesterton's Fence
analysis — understand why code exists before changing it.

---

## Step 4 — Atomic steps, always green

```
Unbreakable rules:
□ One small change at a time
□ Run tests AFTER EACH change — never batch
□ Test goes RED during refactor → REVERT that step immediately, find different approach
□ Commit after each green step: "refactor([module]): [small description]"
□ No new features in refactor commits
□ No interface changes without updating all callers in same commit

When DONE condition is met → STOP.
"This other part also looks messy" is not a reason to continue.
```

---

## Step 5 — Update constitution after

If refactor changed module structure → update ARCHITECTURE.md.
If a boundary violation was in tech debt log with a trigger → remove it (trigger met).
If new rules emerged from the refactor → add to CLAUDE.md or .claude/rules/.

---

## CLAUDE.md evolution — when project grows

> Read this section when: CLAUDE.md > 150 lines, multiple devs conflict on rules,
> or Claude starts ignoring rules (happens when file is too long).

### Why split

Claude reliably follows ~150 instructions. One CLAUDE.md doesn't scale.
Solution: `.claude/rules/` with path-scoped files — each file only loads when Claude
works in a matching directory.

### Structure when CLAUDE.md > 150 lines

```
.claude/
  rules/
    boundaries.md       # 3 boundary rules — always loaded
    testing.md          # test conventions — always loaded
    api-conventions.md  # only loads when working in src/api/
    payments.md         # only loads when working in src/modules/payments/
    frontend.md         # only loads when working in src/ui/
CLAUDE.md               # keep < 80 lines: project overview + @import references
```

### Path scoping syntax

```yaml
# .claude/rules/payments.md
---
globs: ["src/modules/payments/**", "src/modules/billing/**"]
---
# Rules only apply when Claude is in payments or billing module
- Never call external payment API directly — use PaymentGateway interface
- All amounts must be integer cents, never float
- Log full input/output of every payment operation
```

### Compound engineering — CLAUDE.md gets smarter over time

Every time Claude makes a repeated mistake → add rule to the correct file:
```
Claude generated float for money amount → add to payments.md:
"Amounts are always integer cents. NEVER use float for money."

Claude forgot quota check before crawling → add to crawlers.md:
"Always call isQuotaAvailable() before fetch(). Never skip this."
```

Don't add rules to root CLAUDE.md if they only apply to one module.
CLAUDE.md only contains project-wide truths.
