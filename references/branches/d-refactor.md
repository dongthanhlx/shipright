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

---

## CLAUDE.md evolution — khi project grow

> Đọc section này khi: CLAUDE.md > 150 lines, hoặc nhiều devs conflict trên cùng rules,
> hoặc Claude bắt đầu ignore rules (thường xảy ra khi file quá dài).

### Tại sao cần split

Claude chỉ follow ~150 instructions reliably. 1 CLAUDE.md duy nhất không scale.
Solution: `.claude/rules/` với path-scoped files — mỗi file chỉ load khi Claude
làm việc trong directory match.

### Cấu trúc mới khi CLAUDE.md > 150 lines

```
.claude/
  rules/
    boundaries.md          # 3 boundary rules — luôn load
    testing.md             # test conventions — luôn load
    api-conventions.md     # chỉ load khi làm việc trong src/api/
    payments.md            # chỉ load khi trong src/modules/payments/
    frontend.md            # chỉ load khi trong src/ui/
CLAUDE.md                  # giữ < 80 lines: project overview + @import references
```

### Path scoping syntax

```yaml
# .claude/rules/payments.md
---
globs: ["src/modules/payments/**", "src/modules/billing/**"]
---
# Rules chỉ apply khi Claude ở trong payments hoặc billing module
- Không gọi external payment API trực tiếp — dùng PaymentGateway interface
- Mọi amount phải là integer cents, không bao giờ float
- Log đầy đủ input/output của mọi payment operation
```

### CLAUDE.md sau khi split (lean version)

```markdown
# CLAUDE.md — [project-name]

[Project in one sentence]

## Always-on rules
- [3 boundary rules — paste trực tiếp, không @import]
- [Tech stack]
- [Tech debt log]

## Module-specific rules
Xem .claude/rules/ — tự động load theo directory context.

## When to ask before doing
[...]
```

### Compound engineering — CLAUDE.md gets smarter over time

Mỗi khi Claude mắc lỗi lặp lại → add rule vào đúng file trong .claude/rules/:
```
Claude generated float for money amount → add to payments.md:
"Amounts are always integer cents. NEVER use float for money."

Claude forgot to check quota before crawling → add to crawlers.md:
"Always call isQuotaAvailable() before fetch(). Never skip this check."
```

Không add rule vào CLAUDE.md gốc nếu nó chỉ relevant cho 1 module.
CLAUDE.md chỉ chứa project-wide truths.
