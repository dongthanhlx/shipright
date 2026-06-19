## Branch C — Existing project, fix bug

### Step 0 — Phân loại bug trước (critical — determines entire workflow)

```
Q: "Bug này xảy ra như thế nào?
    [A] Mọi lúc — reproduce được ổn định
    [B] Thỉnh thoảng — không rõ trigger
    [C] Chỉ trên production, local không thấy
    [D] Sau khi chạy một thời gian — nghi memory/resource leak"
```

→ [A]: flow bên dưới (reproduce → locate → fix)
→ [B][C][D]: xem `references/debug-intermittent.md`

### Step 1 — Understand precisely (for consistent bugs)

```
Q1: "Mô tả chính xác:
     - Steps to reproduce (từng bước cụ thể)
     - Actual result: [gì xảy ra]
     - Expected result: [gì nên xảy ra]"

Q2: "Paste error message / stack trace nếu có."

Q3: "Bug này MỚI xuất hiện, hay đã có từ trước?
     Nếu mới: sau deploy nào / thay đổi gì?"
```

### Step 2 — Reproduce with failing test

```
Tìm hoặc viết test case reproduce bug:
- Test FAIL với code hiện tại → confirms bug exists
- Test describe expected behavior, không phải current behavior
- Chưa fix gì — chỉ có test đỏ

Nếu không thể write test → document exact manual steps.
Không fix bất cứ thứ gì trước khi có reproduce case.
```

### Step 3 — Locate with strategy (not random reading)

```
Chọn locate strategy dựa vào context:

Bug xuất hiện sau deploy gần đây → git bisect:
  git bisect start
  git bisect bad HEAD
  git bisect good [last-known-good-commit]
  → chạy reproduce test mỗi step, git sẽ tìm exact commit

Bug không liên quan deploy → binary search trong call stack:
  1. Thêm assert/log ở GIỮA call stack
  2. Xác định bug ở nửa trên hay dưới
  3. Chia tiếp → tìm exact function trong O(log N) steps

Bug liên quan data cụ thể → data-driven:
  1. Tìm pattern: data nào trigger bug vs không trigger?
  2. Reproduce với minimal data set

Dừng khi: "Function X nhận input đúng nhưng trả output sai"
Đó là nơi fix — không phải nơi exception được throw.
```

### Step 4 — Root cause, not symptom

```
Trước khi fix, hỏi: "Đây là root cause hay symptom?"

Test: "Nếu fix ở đây, có gì ngăn bug tương tự xảy ra ở chỗ khác không?"

Nếu không → đang fix symptom.
Tìm root cause: "Tại sao [bad value/state] tồn tại được đến đây?"
Fix root cause. Thêm test ở cả root cause location và symptom location.
```

### Step 5 — Fix minimal, verify no regression

```
Fix tại [layer] trong [file]:
- Minimal change — chỉ đủ để reproduce test pass
- Không refactor xung quanh trong cùng commit
- Chạy full test suite
- Commit: "fix([module]): [mô tả ngắn bug được fix]"

Sau fix: bug pattern này có thể xảy ra ở chỗ khác không?
  Có → thêm test hoặc lint rule để prevent
  Không → done
```

---
