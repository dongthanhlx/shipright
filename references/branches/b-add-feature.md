## Branch B — Existing project, add feature

**Rule: Never touch code before understanding what's there.**

### Step 1 — Intake (ask one at a time)

```
Q1: "Tên project và một câu mô tả nó làm gì?"

Q2: "Feature cần thêm, từ góc độ user:
     'User có thể [làm gì] để [đạt được gì]'"

Q3: "Feature này cần module mới hay extend module đang có?"

Q4: "CLAUDE.md và ARCHITECTURE.md có không?"
```

### Step 2 — Read codebase (structured report required)

```
Đọc codebase, KHÔNG sửa gì. Báo cáo theo đúng format này:

## Codebase report: [project-name]
Entry points: [file → what it starts]
Module map:   [module] → [1-sentence job] → [depends on]
Data flow:    Request → [A] → [B] → [C] → Response
Patterns:     [what patterns exist, where]
Landmines:    [files/areas dangerous to touch — global state, tight coupling, etc.]
Feature [X] touches: [which modules and why]
Unknowns:     [what needs clarification before coding]
```

### Step 3 — Health check (tiered, not flat 4 questions)

```
Đánh giá module(s) sẽ bị touch. Phân loại theo tier:

TIER 1 — Blockers (phải giải quyết trước khi thêm feature):
□ Có global mutable state không? (module-level variables bị mutate)
□ Circular dependencies? (chạy: npx madge --circular src/)
□ Có empty catch blocks không? (errors bị swallow silently)
□ Feature mới có race condition risk không? (shared resource + concurrent access)

TIER 2 — Warnings (ghi nhận, proceed with caution):
□ Test coverage của module bị touch (chạy coverage report)
□ Service import db trực tiếp không?
□ Handler có business logic không?
□ Public interface đang unstable (thay đổi thường xuyên)?

TIER 3 — Notes (log vào tech debt, không block):
□ TODO/FIXME liên quan đến feature đang thêm?
□ Naming inconsistency?

Kết luận: [SAFE / TIER1-BLOCKER / TIER2-CAUTION] với lý do cụ thể.
```

### Step 4 — Decision based on health check

**SAFE** → implement ngay:
```
Module mới hay extend module cũ?

Extend module cũ → bắt đầu L2 cho feature:
  1. Viết test cases (RED)
  2. Implement inside-out: repository → service → handler
  3. Boundary check trước commit

Module mới → update ARCHITECTURE.md trước:
  1. Add module vào ARCHITECTURE.md (responsibility, deps, forbidden deps)
  2. Confirm không tạo circular dependency mới
  3. Bắt đầu L2 cho module mới
```

**TIER1-BLOCKER** → assess effort first, then decide:
```
Estimate effort để fix blocker:
  Files cần touch: [N]
  Test coverage hiện tại: [%]
  Estimate: [X giờ]

Quyết định:
  Blocker fix < 20% deadline còn lại → Fix trước, commit riêng: "fix: remove global state in [module]"
  Blocker fix > 20% deadline → Workaround với TODO[fix-before-scale]: [description]
  Blocker fix > 50% deadline → Escalate với team/manager trước khi làm gì
```

**TIER2-CAUTION** → proceed với safety net:
```
Viết characterization tests trước (xem bên dưới).
Sau đó implement feature dưới green tests.
Ghi Tier 2 issues vào tech debt log trong CLAUDE.md.
```

### Characterization tests — đúng cách

```typescript
// MỤC ĐÍCH: capture EXACTLY what code does NOW (kể cả behavior sai)
// KHÔNG PHẢI: test expected behavior

// Cách đúng — snapshot test
it('CHARACTERIZATION: getUser current behavior', () => {
  const result = userService.getUser(1)
  expect(result).toMatchSnapshot() // fail nếu BẤT KỲ thứ gì thay đổi
})

// Cách sai — viết như unit test thường
it('should return user with correct fields', () => {
  expect(result.id).toBe(1) // test expected, không phải current
})

// Coverage cần: 100% code paths SẼ BỊ TOUCH trong feature/refactor
// Không cần: 60% overall (tùy tiện)
```

---
