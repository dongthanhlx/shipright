# Onboarding Router

ALWAYS run this first. Ask ONE question, wait for answer, then load the correct branch file.

---

## Opening question

```
Dự án này đang ở trạng thái nào?

  [A] Mới hoàn toàn — chưa có gì
  [B] Đã có code — cần dev thêm feature
  [C] Đã có code — cần fix bug
  [D] Đã có code — muốn refactor / cải thiện kiến trúc
  [E] Đã có code — cần orient lại sau thời gian dừng
  [F] Đang có vấn đề production — chậm / crash / data sai
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

## Project name convention

Normalize to kebab-case: "News Crawler" → `news-crawler`
Use in: folder name, CLAUDE.md title, Docker Compose service name.
Confirm with developer before proceeding.
