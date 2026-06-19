## Branch E — Resume / re-entry (returning to project after a break)

### Step 1 — Orient trước khi làm bất cứ thứ gì (5 phút)

```
git log --oneline -20        # last 20 commits — hiểu last state
git status                   # có uncommitted changes?
git stash list               # có stash bị quên?
git branch -a                # đang ở branch nào, có WIP branch?
```

### Step 2 — Read docs nếu có

```
Đọc CLAUDE.md và ARCHITECTURE.md.
Nếu không có → dùng Branch D để reconstruct từ codebase trước.
```

### Step 3 — Find last position

```
Tìm "where did I stop?":
- TODO/FIXME gần nhất trong code
- Commit message cuối: đang làm gì?
- Open PRs / issues nếu có
- Test failures nếu có uncommitted changes
```

### Step 4 — Health check nhanh

```
Chạy: npm test / pytest / go test
GREEN → tiếp tục từ last position
RED   → fix tests trước khi làm gì khác (ai đó broke? hay WIP?)
```

### Step 5 — Xác định next action rõ ràng

```
Viết ra: "Next action cụ thể là: [verb + object + acceptance criteria]"
Không bắt đầu code cho đến khi câu này rõ ràng.
Ví dụ tốt: "Implement OrderService.cancelOrder() — test cases đã có ở L2"
Ví dụ xấu: "Tiếp tục orders module"
```

---
