# Onboarding Router

ALWAYS run this first. Ask ONE question, wait for answer, then load the correct branch file.

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

## After answer — load exactly one file

| Answer | Load this file | Do NOT load others |
|---|---|---|
| [A] | `references/branches/a-new-project.md` | B, C, D, E, F |
| [B] | `references/branches/b-add-feature.md` | A, C, D, E, F |
| [C] | `references/branches/c-fix-bug.md` | A, B, D, E, F |
| [D] | `references/branches/d-refactor.md` | A, B, C, E, F |
| [E] | `references/branches/e-resume.md` | A, B, C, D, F |
| [F] | `references/branches/f-incident.md` | A, B, C, D, E |

## Language note

Shipright responds in the user's language automatically.
If the user writes in Vietnamese → respond in Vietnamese.
If the user writes in English → respond in English.
The skill files are English. The responses adapt to the user.

## Project name convention

Normalize to kebab-case: "News Crawler" → `news-crawler`
Use in: folder name, CLAUDE.md title, Docker Compose service name.
Confirm with developer before proceeding.
