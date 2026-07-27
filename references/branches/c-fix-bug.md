## Branch C — Fix bug

> **L0→L4 tree does NOT apply here.** Dedicated workflow below.
> Working directory: all files in directory shown in SKILL.md context.

---

## Step 0 — Understand the bug (ask what only the user knows)

Let the user describe it first — don't front-load a classification menu. Ask for the facts only
they have:
```
"Describe the bug: steps to reproduce, what actually happens, what you expected."
"Error message / stack trace, if any?"
"Did it start after a recent deploy or change?"
```

Then shipright INFERS the type from the description (don't quiz — diagnose):
```
reproduces every time                → the flow below
intermittent / production-only / grows over time (memory/resource leak)
                                     → load references/debug-intermittent.md
VISUAL / UX bug — the code "works" but the screen is wrong: broken layout, overflow, unreadable
  contrast, wrong spacing/hierarchy, unusable on mobile, no focus ring, missing loading/empty/error
  state, keyboard trap
                                     → load references/ui-design.md. The failing "test" is the FLOOR
                                       (a11y / responsive / state-floor), not a unit test — Step 1 below
                                       becomes: capture the broken state (screenshot at 360px, contrast
                                       number, keyboard path) as the repro, using
                                       browser-testing-with-devtools if installed (real runtime beats
                                       reading the CSS). [skill/taste = YES] →
                                       redesign-existing-projects (its audit covers hierarchy/contrast/
                                       spacing; there is no separate visual-diagnostic skill). If it's a
                                       whole-screen redesign, not one defect → Branch D EXPERIENCE track.
```
Play it back if unsure: "This sounds production-only — visible in prod but not locally, right?"

**[if addyosmani debugging-and-error-recovery installed]** → activate for all bug types.
Their 5-step (reproduce → localize → reduce → fix → guard) is more thorough than this built-in flow.
This built-in is the fallback when addyosmani is not installed.

---

## Step 1 — Reproduce with a failing test FIRST

```
Write a failing test before touching any code.
Test FAILS with current code → confirms the bug exists.
Test describes EXPECTED behavior, not current behavior.

No reproducible case = no fix.
Find a way to reproduce, or document exact manual steps.
```

---

## Step 2 — Locate (strategy, not random reading)

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

## Step 3 — Root cause, not symptom

```
Before fixing, ask: "Is this the root cause or a symptom?"

Test: "If I fix here, what prevents the same bug elsewhere with similar data?"
If nothing → fixing a symptom. Find the root cause first.

Fix root cause. Add test at both root cause location and symptom location.
```

> Classify the error before deciding how to handle it (`references/error-handling.md`):
> Operational (expected — return to caller, don't "fix") · Infrastructure (retry/circuit
> breaker) · Programmer (real bug — fix the defect). Mixing these up is the #1 cause of
> either swallowing real bugs or over-handling normal conditions.

---

## Step 4 — Fix and verify

```
Fix in the correct layer (service bug → fix service, not handler).
Minimal change — only enough to make the failing test pass.
No refactoring in the same commit.
Run full test suite — no regression.
Commit: "fix([module]): [description]"

After fix: could this same pattern occur elsewhere?
  Yes → add test or lint rule to prevent recurrence
  No  → done

Did the bug live in auth / session / a permission check / money / PII / anything user-controlled?
  → A passing test is NOT the finish line. Load references/security.md and run /security-review
    (bundled, free) on the change. A bug in that code is evidence the invariant was never enforced,
    so ask what ELSE that same gap exposes — don't just close the one report.
```

---

## After fix — quality gate + update constitution

**Quality gate** (same as Branch B — run before committing fix):
```
DDD:    Does the fix use correct Ubiquitous Language terms?
SOLID:  Is fix in the correct layer? (service bug → fix service, not handler)
Fowler: Does fix address root cause, not symptom?
Tests:  Is the originally failing test now GREEN? No new RED tests?
```

**Update CLAUDE.md if structural cause:**

If the bug happened because of a boundary violation (service importing db directly):
fix the boundary AND update CLAUDE.md boundary checklist.
If caused by an external API schema change: add TODO[api-version-pin] to tech debt log.
