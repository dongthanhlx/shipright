## Branch F — Production incident

> **L0→L4 tree does NOT apply here.**
> High pressure. Speed matters. But mistakes here are expensive.
> Working directory: all files in directory shown in SKILL.md context.

---

## Step 1 — Triage (2 minutes max)

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
External dependency issue → check status page, activate circuit breaker

Rule: stopping damage from spreading is more important than finding root cause.
Do NOT spend 30 minutes investigating while users keep getting hurt.
```

---

## Step 3 — Investigate with production data (no guessing)

```
Read logs in order:
1. Error logs → find first occurrence timestamp
2. Pattern: all users? specific group? specific data shape?
3. Access logs → traffic spike? unusual endpoint pattern?

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
