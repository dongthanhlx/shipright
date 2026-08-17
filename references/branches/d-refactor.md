## Branch D — Refactor / improve architecture

> **L0→L4 tree: read L0 docs to understand intent, do NOT follow tree sequence.**
> Refactor uses characterization tests + atomic steps — not L1/L2/L3.
> Working directory: all files in directory shown in SKILL.md context.

---

## Step 0 — Which KIND of improvement? (fork before anything else)

Same fork as Branch B Step 3: an improvement is either **system** (architecture/code) or **experience**
(the UI a human looks at). They have different pain, different DONE, different flow. Detect it from what
the user said — don't ask them to classify.

```
System refactor (code structure, coupling, perf, tests)  → Step 1 below (smell diagnosis).
Experience redesign (a page/screen/dashboard "looks bad",
  "feels dated", "looks amateur", "not responsive",
  bad UX/flow, a11y problems)                            → EXPERIENCE track (below). Load
                                                            references/ui-design.md NOW.
Both (UI code is a mess AND the UI looks bad)            → run the EXPERIENCE track for what the user
                                                            sees; system smells go through Step 1
                                                            separately. Don't fuse them into one blob.
```

> **Refactoring auth, permissions, money or anything user-controlled?** Characterization tests capture
> current *behavior* — they do not capture whether the current behavior was SAFE, so a green suite after
> a security-adjacent refactor proves nothing about security. Load `references/security.md` and run
> `/security-review` (bundled, free) on the diff before merging; activate `security-and-hardening` if
> installed. This is the single easiest place to move a vulnerability while every test stays green.

> **The "no measurable pain" guard in Step 1 does NOT apply to the experience track.** For a
> brand-facing surface, "it looks unprofessional / users bounce / it's unusable on my phone" *is* the
> measurable pain — that's the experience floor failing, not aesthetics-for-aesthetics. Never redirect a
> UI redesign with "refactor without measurable pain rarely pays." (That guard exists for code, where
> tidiness has no user.) Do still refuse pure restyling of an internal throwaway tool — judgment.md §5.

### EXPERIENCE track — audit BEFORE you touch anything

```
1. AUDIT first — never jump straight to a taste-skill on existing UI (ui-design.md says this explicitly).
   [skill/taste lists redesign-existing-projects] → run it: it audits the current UI, names the generic/
                         AI-slop patterns, and covers hierarchy/contrast/spacing defects too
   [skill/taste = NO ] → shipright audits manually against ui-design.md: the FLOOR (a11y/WCAG contrast +
                         keyboard + semantics · responsive at 360px + 200% zoom · information architecture)
                         then the state-floor (loading / empty / error / success / permission) then
                         Nielsen's 10 + Norman (affordance, feedback) then Refactoring UI mechanics
                         (hierarchy by weight+color, spacing, grayscale-first) then icons (SVG, one set)
                         and archetype/tone fit. Name each finding with its principle + evidence.
2. Report findings and CONFIRM the target direction before editing — archetype + audience tone
   (ui-design.md §Style archetypes, §Audience & emotional tone). Show two exemplars if unsure.
3. Separate FLOOR fixes (a11y, mobile, missing states — do them, one-way doors) from SCOPE changes
   (restyle, motion, component library — MVP-first, only what the user asked for).
4. THEN execute: dispatch per ui-design.md §Page type → skill (taste-skill family · vercel-labs for
   admin/dashboards · dataviz for every chart), briefed with the archetype + the audit findings.
5. DONE is still mandatory (Step 2 below) and still measurable for UI:
   "contrast ≥ 4.5:1 everywhere · keyboard-reachable with visible focus · usable at 360px · every
   screen has loading/empty/error states · [the specific hierarchy findings] fixed."
6. The guard equivalent of characterization tests: capture BEFORE screenshots (and the current a11y
   check output) so you can prove the redesign didn't regress behavior or accessibility.
   Execute this with `browser-testing-with-devtools` (real browser, real runtime, console + network).
   Not installed → capture the before-state manually and say the comparison is by eye, not measured.
```

Then skip to Step 2 (define DONE) — Steps 1 and 3 (smell diagnosis, characterization tests) are the
system track's tools.

---

## Step 1 — The user names the PAIN; shipright diagnoses the SMELL

Ask only what the user knows — the real, measurable pain — and where it hurts. Do NOT ask them to
classify their own code smell from a menu: that is shipright's diagnostic job (read the code).

```
Ask the user (open — the pain only they experience):
  "What's the real, measurable pain — and where does it hurt most?"
    e.g. adding feature X takes [N days] (should be hours) · a bug takes [N hrs] to find ·
         test suite too slow for CI · perf: [metric]=[value], target=[target] ·
         preparing for: larger team / data volume / service extraction.
  → If the answer is "the code looks messy" / "I want to restructure" with no measurable pain:
    redirect. "Refactor without measurable pain rarely pays. Use it a few more days, note the
    real friction." (Refactoring for aesthetics alone is over-engineering — judgment.md.)
```

Then shipright READS that code and DIAGNOSES the smell — then confirms (don't menu-quiz):
```
"I read [file/module]. The smell is [Long Method / Feature Envy / Primitive Obsession /
 Divergent Change / Shotgun Surgery / Data Clumps / WHAT-comments] — evidence: [what you saw].
 Or the OPPOSITE (Ousterhout, code-health.md): over-extraction — many shallow methods /
 one-implementation interfaces that fragment one idea; the fix there is INLINE, not extract.
 Agree with the diagnosis?"
```
Naming the specific smell (with evidence, confirmed) is the DONE condition for what to fix.
Load `references/code-quality.md` Fowler section for the specific refactoring move.

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

## Step 5 — Update constitution + Shipright state

Update ARCHITECTURE.md if module structure changed.
Update tech debt log (trigger met → remove).
Add new rules to CLAUDE.md or .claude/rules/ from patterns discovered.

**Write Shipright state:**
```markdown
## Shipright state
Level: L3 (post-refactor)
Active: [module refactored]
Next: [verify DONE condition met / run perf test / next feature]
Last shipped: [carry forward UNCHANGED — a refactor changes no user outcome, so it never clears
              or answers a pending check. Dropping the line silently kills the outcome loop.]
Last updated: [date]
```

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
    boundaries.md       # 5 boundary rules — always loaded
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
