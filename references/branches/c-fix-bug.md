## Branch C — Fix bug

> **L0→L4 tree does NOT apply here.** Dedicated workflow below.
> Working directory: all files in directory shown in SKILL.md context.

---

## Step 0 — Classify bug type

```
"Bug này xảy ra như thế nào?
 [A] Mọi lúc — reproduce ổn định
 [B] Thỉnh thoảng — không rõ trigger
 [C] Chỉ trên production — local không thấy
 [D] Sau khi chạy lâu — nghi memory/resource leak"
```

→ [A]: flow below
→ [B][C][D]: load `references/debug-intermittent.md`

---

## Step 1 — Understand precisely

```
Q1: "Steps to reproduce + actual result + expected result"
Q2: "Error message / stack trace nếu có"
Q3: "Mới xuất hiện sau deploy/change nào không?"
```

---

## Step 2 — Reproduce with failing test FIRST

```
Write failing test before touching any code.
Test FAILS with current code → confirms bug exists.
Test describes EXPECTED behavior, not current.

No test = no fix. Find a way to reproduce, or document exact manual steps.
```

---

## Step 3 — Locate (strategy, not random reading)

```
After deploy → git bisect:
  git bisect start && git bisect bad HEAD && git bisect good [commit]

Not deploy-related → binary search:
  Add log/assert at MIDDLE of call stack
  Determine: bug in top half or bottom half?
  Repeat → find exact function in O(log N) steps

Data-specific → find pattern:
  What data triggers bug vs doesn't?
  Reproduce with minimal dataset

Stop when: "Function X receives correct input but returns wrong output"
That's where to fix — not where exception is thrown.
```

**[if addyosmani installed]** → activate `debugging-and-error-recovery` for steps 2–3.
Their 5-step (reproduce → localize → reduce → fix → guard) is more detailed.

---

## Step 4 — Root cause, not symptom

```
Before fixing: "Is this root cause or symptom?"
Test: "If I fix here, what prevents same bug elsewhere with same data?"
If no → fixing symptom. Find root cause first.
Fix root cause. Add test at both root and symptom location.
```

---

## Step 5 — Fix and verify

```
Fix in correct layer (service bug → fix service, not handler).
Minimal change — only enough to make failing test pass.
No refactoring in same commit.
Run full test suite.
Commit: "fix([module]): [description]"

After fix: same bug pattern elsewhere?
  Yes → add test or lint rule to prevent
  No → done
```

---

## After fix — update constitution if structural

If bug occurred because of boundary violation (service importing db directly):
fix the boundary, update CLAUDE.md boundary checklist.
If bug from external API change: add TODO[api-version-pin] to tech debt log.
