## Branch A — New project

Ask ONE AT A TIME. Wait for each answer. Never dump multiple questions.

```
Q1: "Tên project là gì?"

Q2: "Một câu mô tả bài toán:
     '[Ai] đang gặp khó khăn với [vấn đề gì]'
     Ví dụ: 'Dev team mất 30 phút tìm log mỗi khi có bug production'"

Q3: "Đã có solution nào cho bài toán này chưa?
     (tool có sẵn, competitor, manual process hiện tại...)
     Tại sao cần build mới thay vì dùng cái đó?"

Q4: "System chạy như thế nào?
     [A] HTTP API — được gọi từ client/mobile
     [B] Cron job / scheduled task tự động
     [C] CLI — dev chạy tay
     [D] Background worker / queue consumer
     [E] Kết hợp nhiều loại"

Q5: "Về data — trả lời ngắn:
     - Sẽ có khoảng bao nhiêu records? (100 / 10k / 1M+)
     - Đọc nhiều hay ghi nhiều?
     - Nhiều user riêng biệt (multi-tenant) hay dùng chung?"

Q6: "Stack công nghệ nào?
     (Node.js/TypeScript, Python, Go, hay chưa quyết định?)"

Q7: "Constraint nào quan trọng nhất?
     (deadline, team size, must integrate với system X, ...)"
```

After Q7, synthesize WITH senior judgment — not just echo back:

```
Tóm tắt:
- Project: [name]
- Bài toán: [one sentence]
- Stack: [chosen] | Recommendation: [if undecided, suggest based on trigger+data]
- Trigger: [how it runs]
- Data: [volume estimate + read/write pattern]

Risk tôi thấy: [specific risk from their answers, not generic]

Với constraint [X], đề xuất MVP scope:
  ✓ Làm ngay: [list]
  → Defer: [list] — thêm sau khi validate core works

Đồng ý không? Nếu OK, tôi tạo CLAUDE.md và ARCHITECTURE.md.
```

> **Example output**: Xem `references/examples/news-crawler-CLAUDE.md` và
> `references/examples/news-crawler-ARCHITECTURE.md` để biết output tốt trông như thế nào.

---
