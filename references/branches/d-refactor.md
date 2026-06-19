## Branch D — Refactor / improve architecture

> **L0→L4 tree: read L0 docs to understand intent, do NOT follow tree sequence.**
> Refactor uses characterization tests + atomic steps — not L1/L2/L3.
> Working directory: all files in directory shown in SKILL.md context.

---

## Step 1 — Define the pain (reject vague goals)

```
Q1: "Điều gì đang gây pain CỤ THỂ, ĐO ĐƯỢC?
     [A] Thêm feature X mất [N ngày] — nên mất [M giờ]
     [B] Bug mất [N giờ] tìm vì code phức tạp
     [C] Test suite chạy [N phút] — quá chậm cho CI
     [D] Performance: [metric] = [value], target = [target]
     [E] Chuẩn bị cho: team lớn hơn / data volume / service split"

Q2: "Module / file cụ thể nào đang là vấn đề?"
```

If answer is "code trông không clean" or "muốn restructure":
→ Redirect: "Refactor không có pain cụ thể thường không deliver value đo được.
   Dùng codebase thêm vài ngày, note lại pain points thật sự."

---

## Step 2 — Define DONE (mandatory before starting)

```
Pick one — must be measurable or binary:
□ "Add feature [X] will take < [N hours]" — measurable
□ "npx madge --circular returns empty" — binary
□ "Coverage of touched paths > 80%" — binary
□ "Refactor done in [N days] — time-boxed, no extension"

Cannot define DONE → do not refactor now.
```

---

## Step 3 — Characterization tests FIRST

```
Write tests that capture CURRENT behavior (even if wrong):

// CORRECT — snapshot captures exactly what it does NOW
it('CHARACTERIZATION: current behavior', () => {
  expect(result).toMatchSnapshot()  // fails if ANYTHING changes
})

// WRONG — this tests expected behavior, not current
it('should return correct fields', () => {
  expect(result.id).toBe(1)
})

Coverage target: 100% of code paths THAT WILL BE TOUCHED.
Not 60% overall — just the paths changing.
Run tests → GREEN. From here: tests must never go RED.
```

---

## Step 4 — Atomic steps, always green

```
Rules (unbreakable):
□ One small change at a time
□ Run tests AFTER EACH change — never batch
□ Test goes RED during refactor → REVERT that step immediately
□ Commit after each green step: "refactor([module]): [small description]"
□ No new features in refactor commits
□ No interface changes without updating all callers in same commit

When DONE condition is met → STOP.
"This other part also looks messy" is not a reason to continue.
```

**[if addyosmani installed]** → activate `code-simplification` for Chesterton's Fence
analysis and complexity reduction within the refactor scope.

---

## Step 5 — Update constitution after

If refactor revealed a boundary violation that was in CLAUDE.md as acceptable:
update tech debt log (trigger met, removed).
If refactor changed module structure: update ARCHITECTURE.md.
