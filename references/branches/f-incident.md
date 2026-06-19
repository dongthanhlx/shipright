## Branch F — Production incident

High-pressure scenario. Speed matters but mistakes are expensive.

### Step 1 — Triage (2 phút, không hơn)

```
□ Severity: bao nhiêu user/requests bị ảnh hưởng? (số thật)
□ Blast radius: đang lan rộng hay stable?
□ Started: khi nào? Sau event nào? (deploy, config change, data spike)
□ Can we reproduce? Hay chỉ thấy trên prod?
```

### Step 2 — Mitigate TRƯỚC investigate

```
Nếu có deploy gần đây + triệu chứng match → rollback trước
Nếu không chắc về deploy → feature flag off (nếu có) → rollback
Nếu data corruption đang xảy ra → stop writes ngay (read-only mode)
Nếu external dependency → check status page, circuit breaker

Rule: dừng damage lan rộng quan trọng hơn tìm root cause.
Không mất thêm 30 phút "investigate" trong khi users tiếp tục bị ảnh hưởng.
```

### Step 3 — Investigate với data prod (không guess)

```
Đọc logs theo thứ tự:
1. Error logs → tìm first occurrence timestamp
2. Xác định pattern: tất cả users? Specific user group? Specific data?
3. Access logs → traffic spike? Unusual endpoint?

Không sửa production code trong khi investigate.
Không chạy ad-hoc queries trên prod DB mà không backup.
```

### Step 4 — Fix với safety net

```
Fix nhỏ + confident + có rollback plan → deploy to prod
Fix lớn / không chắc → reproduce on staging → test → deploy
Không bao giờ:
  □ Sửa thẳng DB prod không có backup
  □ Deploy hotfix không qua staging nếu fix > 10 lines
  □ Merge thẳng vào main mà không có ai review
```

### Step 5 — Post-incident (sau khi system stable)

```
Viết incident report (trong vòng 24h):
  Timeline: [thời điểm] → [gì xảy ra]
  Root cause: [1 câu]
  Fix: [gì đã làm]
  Prevention: [monitoring/alert/code change để không tái diễn]

Thêm test hoặc alert để detect sớm hơn lần sau.
```

---
