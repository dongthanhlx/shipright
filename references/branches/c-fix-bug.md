## Branch C — Fix bug

> **L0→L4 tree does NOT apply here.** Dedicated workflow below.
> Working directory: all files in directory shown in SKILL.md context.

---

## Step 0 — Classify bug type first

```
"How does the bug occur?
 [A] Every time — reproduces consistently
 [B] Intermittently — no clear trigger
 [C] Production only — not visible locally
 [D] After running for a while — suspected memory/resource leak"
```

→ [A]: flow below
→ [B][C][D]: load `references/debug-intermittent.md`

**[if addyosmani debugging-and-error-recovery installed]** → activate for all bug types.
Their 5-step (reproduce → localize → reduce → fix → guard) is more thorough than this built-in flow.
This built-in is the fallback when addyosmani is not installed.

---

## Step 1 — Understand precisely

```
Q1: "Steps to reproduce + actual result + expected result"
Q2: "Error message / stack trace if available"
Q3: "Did this appear after a recent deploy or change?"
```

---

## Step 2 — Reproduce with failing test FIRST

```
Write a failing test before touching any code.
Test FAILS with current code → confirms the bug exists.
Test describes EXPECTED behavior, not current behavior.

No reproducible case = no fix.
Find a way to reproduce, or document exact manual steps.
```

---

## Step 3 — Locate (strategy, not random reading)

```
Bug appeared after recent deploy → git bisect:
  git bisect start
  git bisect bad HEAD
  git bisect good [last-known-good-commit]

Not deploy-related → binary search in call stack:
  1. Add log/assert at MIDDLE of call stack
  2. Determine: bug in top half or bottom half?
  3. Repeat → find exact function in O(log N) steps

Data-specific bug → find the pattern:
  What data triggers it vs doesn't?
  Reproduce with minimal dataset.

Stop when: "Function X receives correct input but returns wrong output"
That's where to fix — not where the exception is thrown.
```

---

## Step 4 — Root cause, not symptom

```
Before fixing, ask: "Is this the root cause or a symptom?"

Test: "If I fix here, what prevents the same bug elsewhere with similar data?"
If nothing → fixing a symptom. Find the root cause first.

Fix root cause. Add test at both root cause location and symptom location.
```

---

## Step 5 — Fix and verify

```
Fix in the correct layer (service bug → fix service, not handler).
Minimal change — only enough to make the failing test pass.
No refactoring in the same commit.
Run full test suite — no regression.
Commit: "fix([module]): [description]"

After fix: could this same pattern occur elsewhere?
  Yes → add test or lint rule to prevent recurrence
  No  → done
```

---

## After fix — update constitution if structural

If the bug happened because of a boundary violation (service importing db directly):
fix the boundary AND update CLAUDE.md boundary checklist.
If caused by an external API schema change: add TODO[api-version-pin] to tech debt log.
