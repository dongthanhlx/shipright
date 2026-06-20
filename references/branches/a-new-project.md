## Branch A — New project

> **Working directory**: all files in the directory shown in SKILL.md context.
> If CLAUDE.md or ARCHITECTURE.md already exist → read them first, skip intake.

---

## Step 1 — MVP or Production? (ask first)

```
"Is the goal right now to validate an idea, or build a production-ready solution?"

[A] Validate — get something working in front of real users as fast as possible
[B] Production — team, timeline, and requirements are already clear
```

---

## Step 2 — Intake (one question at a time, wait for each answer)

```
Q1: "What is the project name?"

Q2: "One sentence: '[Who] struggles with [what]'"

Q3: "Does a solution already exist? Why build something new?"

Q4: "How does the system run?
     [A] HTTP API  [B] Cron/scheduled  [C] CLI  [D] Background worker  [E] Mix"

Q5 (MVP mode): "What specifically must a user be able to do in the first version?
     One journey: '[User] does [X] to achieve [Y]'"

Q5 (Production mode): "About data: volume? read or write heavy? multi-tenant?"

Q5b (all modes): "Does the project integrate any third-party APIs?
     (e.g. RapidAPI, Stripe, Twilio, YouTube, OpenAI, SearchAPI...)
     → If yes: Adapter layer required in ARCHITECTURE.md from L0
     → Load: references/third-party-apis.md"

Q6: "Tech stack? (Node.js/TS, Python, Go, undecided?)"

Q7: "Most important constraint? (deadline, team size, required integrations)"
```

After Q7, synthesize WITH judgment — not just echo back:

```
Summary:
- Project: [name], Stack: [stack]
- Problem: [one sentence]
- Mode: MVP / Production

[MVP]: Walking skeleton = "[user journey from Q5]"
       Everything else → backlog, not MVP

[Production]: Irreversible decisions must be right upfront:
              core domain model, module boundaries, dependency direction

Risk I see: [specific, not generic]
Recommendation: [scope adjustment if needed]

Agreed? If so, I'll generate CLAUDE.md and ARCHITECTURE.md.
```

---

## Step 3 — Generate constitution

### MVP Constitution (validate mode)

**CLAUDE.md MVP** — minimal, enough to avoid irreversible debt:
- Project in one sentence
- **3 boundary rules** (never skip, even in MVP)
- Tech stack
- Core modules needed for walking skeleton only
- Tech debt log: record shortcuts + TODO[trigger] immediately

**ARCHITECTURE.md MVP** — only what skeleton needs:
- 1 ASCII diagram of core flow
- 2–3 modules minimum
- Core domain type (shape must be right — irreversible)
- 1 ADR for the hardest decision

**Skip for MVP:** full error taxonomy, idempotency for all operations,
all ADRs, full module map, performance specs.

### Production Constitution (production mode)

Full CLAUDE.md + ARCHITECTURE.md per templates in `references/l0-templates.md`.
Includes: error taxonomy, idempotency decisions, all modules, full ADRs.

---

## Step 4 — After constitution

### MVP mode → Walking Skeleton

```
After CLAUDE.md + ARCHITECTURE.md are done:

1. Identify walking skeleton = 1 end-to-end user journey (from Q5)
   Example: "User pastes URL → crawl → sees article list"

2. [if addyosmani installed] → activate spec-driven-development for skeleton only
   [if not] → describe skeleton spec inline

3. [if addyosmani installed] → activate incremental-implementation + test-driven-development
   [if not] → implement inside-out: repository → service → handler
   Tests: enough to prove skeleton works. Not edge cases.

4. SHIP GATE: "npm start + [action] → user sees [result]?"
   YES → deploy immediately, put in front of real users
   NO  → skeleton not done, no new features

5. [Developer validates with real users]
   Users return → feature loop (Branch B for each feature)
   Users don't return → pivot, don't add features
```

### Production mode → Full tree

L0 (done) → L1 Skeleton → L2 Interfaces + tests (RED) → L3 Implement loop

[if addyosmani installed]:
- L1: describe skeleton → activate incremental-implementation
- L2: activate api-and-interface-design → test-driven-development
- L3: activate incremental-implementation + test-driven-development per task
- Review: activate code-review-and-quality before merge
- Ship: activate shipping-and-launch

---

## Gate — L0 done when:

- [ ] Both files are project-specific (not generic template)
- [ ] 3 boundary rules written with specific banned import examples
- [ ] Core domain type defined (shape is irreversible — must be right)
- [ ] Tech debt log has obvious MVP shortcuts with trigger conditions
- [ ] MVP: walking skeleton identified as 1 user journey
- [ ] Production: all modules listed, error taxonomy defined

> **Example output**: `references/examples/news-crawler-CLAUDE.md` +
> `references/examples/news-crawler-ARCHITECTURE.md`
