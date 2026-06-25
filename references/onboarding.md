# Onboarding Router v0.7

## Before asking anything — check state

```bash
grep -A6 "## Shipright state" CLAUDE.md 2>/dev/null || echo "no state"
```

If state found → show it to developer, ask to continue or restart.
If no state → ask the question below.

---

## Opening question

```
What is the current state of your project?

  [A] New — nothing exists yet
  [B] Existing code — need to add a feature
  [C] Existing code — need to fix a bug
  [D] Existing code — want to refactor or improve
  [E] Existing code — need to re-orient or continue after a break
  [F] Production issue — slow, crashing, or data problem
```

## Route to branch file

| Answer | Load |
|---|---|
| [A] | `references/branches/a-new-project.md` |
| [B] | `references/branches/b-add-feature.md` |
| [C] | `references/branches/c-fix-bug.md` |
| [D] | `references/branches/d-refactor.md` |
| [E] | `references/branches/e-resume.md` |
| [F] | `references/branches/f-incident.md` |

Load ONE. Do not pre-load others.

## Language note

Respond in user's language. Skill files are English for GitHub discoverability.
CLAUDE.md and ARCHITECTURE.md content stays in English (project convention).
