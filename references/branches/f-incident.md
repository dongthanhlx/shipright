## Branch F — Production incident

> **L0→L4 tree does NOT apply here.**
> High pressure. Speed matters. But mistakes here are expensive.
> Working directory: all files in directory shown in SKILL.md context.

---

## Step 1 — Triage (2 minutes max)

> Deliberate exception to "How shipright asks" (SKILL.md): under incident pressure, a fast
> structured checklist beats an open conversation. Speed > rapport here.

```
□ Severity: how many users/requests affected? (real number)
□ Blast radius: spreading or stable?
□ Started: when? After which event? (deploy, config change, traffic spike)
□ Reproducible? Or production-only?
```

---

## Step 2 — MITIGATE BEFORE INVESTIGATE

```
Recent deploy + symptoms match → rollback first
Not sure about deploy → toggle feature flag OFF if available → then rollback
Data corruption in progress → stop writes immediately (read-only mode)
External dependency issue → check status page, activate circuit breaker / shed load

Rule: stopping damage from spreading is more important than finding root cause.
Do NOT spend 30 minutes investigating while users keep getting hurt.
```

> Most incidents are failure PROPAGATION through an integration point, not a logic bug.
> If a slow/dead dependency is stalling the system → `references/resilience.md` for the
> containment patterns to apply now (timeout, circuit breaker, bulkhead) and Boundary 5.

---

## Step 3 — Investigate with production data (no guessing)

```
Read logs in order:
1. Error logs → find first occurrence timestamp
2. Pattern: all users? specific group? specific data shape?
3. Access logs → traffic spike? unusual endpoint pattern?

Classify the failure (decides the fix — `references/error-handling.md`):
  Operational (expected: quota/429, not-found)  → degrade gracefully, not a code change
  Infrastructure (timeout, conn refused)         → retry/circuit breaker, check the dependency
  Programmer (null deref, logic bug)             → the deploy/code is the cause → rollback/fix

Do NOT modify production code while investigating.
Do NOT run ad-hoc queries on prod DB without a backup.
```

**[if addyosmani debugging-and-error-recovery installed]** →
after mitigation, activate for structured root cause analysis.

---

## Step 4 — Fix with safety net

```
Small fix + confident + rollback plan ready → deploy to prod
Large fix / uncertain → reproduce on staging → test → deploy

Never:
  □ Edit prod DB directly without backup
  □ Deploy a hotfix > 10 lines without staging verification
  □ Merge to main without at least one reviewer
  □ Undo a bad deploy by resetting + force-pushing main — `git revert` the commit (a new commit, history
    intact, reviewable). Rewriting shared history mid-incident loses the evidence you need for Step 5.
  □ Push, merge or deploy on the agent's own initiative — pressure raises the stakes of every door;
    each one is the user's explicit call (references/git.md Tier 3–4), stated in one line so it's fast.
```

---

## Step 5 — Post-incident (within 24 hours, after system is stable)

```
Write incident report:
  Timeline: [time] → [what happened]
  Root cause: [one sentence]
  Fix: [what was done]
  Prevention: [monitoring / alert / code change to catch this earlier next time]

Add a test or alert so this is detected faster next time.
Update CLAUDE.md tech debt log if a structural cause was found.
```

**Prevention — close the resilience gap, not just the bug:**
```
Ask: "which Nygard stability pattern would have CONTAINED this?"
  Dependency stalled us         → timeout + circuit breaker was missing (Boundary 5)
  One failure took down the rest → bulkhead was missing (shared pool)
  Retries made it worse          → retry budget / backoff+jitter was missing
  Duplicate processing on retry  → idempotency key was missing (DB/Redis)
  Unbounded growth / OOM         → steady-state cap was missing
Add the pattern + a fault-injection test that proves it → references/resilience.md.
This is how an incident permanently raises the system's fault tolerance.
```
