## Branch D — Refactor / improve architecture

Highest-risk operation. Most "refactors" become unplanned rewrites.

### Step 1 — Define the pain (reject vague goals)

```
Q1: "Điều gì đang gây pain cụ thể, đo được?
     [A] Add feature X mất [N ngày] — nên mất [M giờ]
     [B] Bug mất [N giờ] để tìm vì code không rõ
     [C] Test suite chạy [N phút] — quá chậm cho CI
     [D] Performance: [metric] = [value], target = [target]
     [E] Chuẩn bị cho: team lớn hơn / data volume / service split"

Q2: "Module / file cụ thể nào đang là vấn đề?"
```

Nếu answer là "code trông không clean" hoặc "muốn restructure":
→ Redirect: "Refactor không có pain cụ thể thường không ship được và không cải thiện gì đo được. Hãy dùng codebase vài ngày nữa và note lại pain points thật sự."

### Step 2 — Define DONE (mandatory before starting)

```
DONE là gì? Chọn một, phải đo được hoặc binary:

□ "Add feature [X] sẽ mất < [N giờ]" — đo được
□ "npx madge --circular trả empty" — binary
□ "Coverage paths bị touch > 80%" — binary
□ "Cyclomatic complexity < 10 mỗi function" — binary
□ "Refactor xong trong [N ngày] — time-boxed, không extend"

Nếu không define được DONE → dừng, không refactor bây giờ.
```

### Step 3 — Characterization tests (non-negotiable)

Xem định nghĩa đúng của characterization test ở Branch B.

```
Viết characterization tests cho code sẽ bị touch.
Coverage target: 100% code paths sẽ thay đổi (không phải 60% overall).
Chạy tests → GREEN.
Từ đây không được để test đỏ tại bất kỳ thời điểm nào.
```

### Step 4 — Refactor in atomic steps

```
Rules không thể phá vỡ:
□ Một thay đổi nhỏ, atomic mỗi lần
□ Chạy tests SAU MỖI thay đổi — không batch
□ Test đỏ trong refactor = revert NGAY, tìm cách khác
□ Commit sau mỗi step xanh: "refactor([module]): [mô tả thay đổi nhỏ]"
□ Không implement feature mới trong refactor commit
□ Không đổi public interface mà không update callers ngay

Khi DONE condition đạt được → STOP.
Không tiếp tục "vì còn chỗ này chưa clean".
```

---
