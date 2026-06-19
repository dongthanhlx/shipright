## Branch A — New project

> **Working directory**: all files in the directory shown in SKILL.md context.
> If CLAUDE.md or ARCHITECTURE.md already exist → read them first, skip intake.

---

## Step 1 — MVP or Production? (ask first)

```
"Mục tiêu ngay bây giờ là validate idea hay build production-ready solution?"

[A] Validate — muốn có thứ gì đó user dùng được nhanh nhất
[B] Production — team, timeline, requirements đã rõ
```

---

## Step 2 — Intake (one question at a time, wait for each answer)

```
Q1: "Tên project là gì?"

Q2: "Một câu: '[Ai] đang gặp khó khăn với [gì]'"

Q3: "Đã có solution nào chưa? Tại sao build mới?"

Q4: "System chạy như thế nào?
     [A] HTTP API  [B] Cron/scheduled  [C] CLI  [D] Background worker  [E] Mix"

Q5 (MVP mode only): "User cần làm được gì CỤ THỂ trong version đầu tiên?
     Mô tả 1 journey: '[User] làm [X] để [đạt được Y]'"

Q5 (Production mode): "Về data: volume? read hay write heavy? multi-tenant?"

Q6: "Stack? (Node.js/TS, Python, Go, chưa quyết định?)"

Q7: "Constraint quan trọng nhất? (deadline, team size, must-have integration)"
```

After Q7, synthesize WITH judgment — not just echo:
```
Tóm tắt:
- Project: [name], Stack: [stack]
- Bài toán: [one sentence]
- Mode: MVP / Production

[MVP]: Walking skeleton = "[user journey từ Q5]"
       Mọi thứ khác → backlog, không phải MVP

[Production]: Irreversible decisions cần đúng ngay:
              core domain model, module boundaries, dependency direction

Risk tôi thấy: [specific, not generic]
Đề xuất: [scope recommendation nếu cần]

OK không? Nếu có, tôi tạo CLAUDE.md và ARCHITECTURE.md.
```

---

## Step 3 — Generate constitution

### MVP Constitution (validate mode)

**CLAUDE.md MVP** — tối thiểu, đủ để không tạo irreversible debt:
- Project in one sentence
- **3 boundary rules** (không bao giờ bỏ dù MVP)
- Tech stack
- Core modules chỉ cần cho walking skeleton
- Tech debt log: ghi shortcut + TODO[trigger] ngay khi tạo

**ARCHITECTURE.md MVP** — chỉ những gì cần cho skeleton:
- 1 ASCII diagram cho core flow
- 2–3 modules tối thiểu
- Core domain type (shape cần đúng — irreversible)
- 1 ADR cho quyết định khó nhất

**Không tạo cho MVP:** full error taxonomy, idempotency cho mọi operation,
tất cả ADRs, full module map, performance specs.

### Production Constitution (production mode)

Full CLAUDE.md + ARCHITECTURE.md theo template trong `references/l0-templates.md`.
Bao gồm: error taxonomy, idempotency decisions, tất cả modules, ADRs đầy đủ.

---

## Step 4 — What happens after constitution

### MVP mode → Walking Skeleton

```
Sau khi CLAUDE.md + ARCHITECTURE.md xong:

1. Identify walking skeleton = 1 user journey end-to-end (từ Q5)
   Ví dụ: "User paste URL → crawl → thấy article list"

2. [nếu addyosmani installed] → activate spec-driven-development cho skeleton only
   [nếu không] → describe skeleton spec inline

3. [nếu addyosmani installed] → activate incremental-implementation + test-driven-development
   [nếu không] → implement inside-out: repository → service → handler
   Test: đủ để skeleton chạy. Không phải edge cases.

4. SHIP GATE: "npm start + [action] → user thấy [result]?"
   YES → deploy ngay, đưa cho real users
   NO  → skeleton chưa xong, không thêm feature

5. [Developer validates với real users]
   Users quay lại → feature loop (Branch B cho từng feature)
   Users không quay lại → pivot, không thêm feature
```

### Production mode → Full tree

L0 (done) → L1 Skeleton → L2 Interfaces + tests (RED) → L3 Implement loop

[nếu addyosmani installed]:
- L1: describe skeleton → activate incremental-implementation
- L2: activate api-and-interface-design → test-driven-development
- L3: activate incremental-implementation + test-driven-development per task
- Review: activate code-review-and-quality trước merge
- Ship: activate shipping-and-launch

---

## Gate — L0 done when:

- [ ] Both files are project-specific (not generic template)
- [ ] 3 boundary rules written with specific banned import examples
- [ ] Core domain type defined (shape is irreversible — must be right)
- [ ] Tech debt log has at least the obvious MVP shortcuts with triggers
- [ ] MVP: walking skeleton identified as 1 user journey
- [ ] Production: all modules listed, error taxonomy defined

> **Example output**: `references/examples/news-crawler-CLAUDE.md` +
> `references/examples/news-crawler-ARCHITECTURE.md`
