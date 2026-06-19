## Branch F — Production incident

> **L0→L4 tree does NOT apply here.**
> High pressure. Speed matters. But mistakes are expensive.
> Working directory: all files in directory shown in SKILL.md context.

---

## Step 1 — Triage (2 minutes, not more)

```
□ Severity: how many users/requests affected? (real number)
□ Blast radius: spreading or stable?
□ Started when? After which event? (deploy, config change, data spike)
□ Reproducible? Or only on prod?
```

---

## Step 2 — MITIGATE BEFORE INVESTIGATE

```
Recent deploy + symptoms match → rollback first
Not sure about deploy → feature flag OFF (if exists) → then rollback
Data corruption happening now → stop writes, READ-ONLY mode
External dependency issue → check status page, circuit breaker

Rule: stop damage spreading > finding root cause.
Do NOT spend 30 minutes investigating while users keep getting hurt.
```

---

## Step 3 — Investigate with production data (no guessing)

```
Read logs in order:
1. Error logs → find first occurrence timestamp
2. Pattern: all users? specific group? specific data shape?
3. Access logs → traffic spike? unusual endpoint?

Do NOT modify production code while investigating.
Do NOT run ad-hoc queries on prod DB without backup.
```

**[if addyosmani installed]** → after mitigation, activate `debugging-and-error-recovery`
for structured root cause analysis.

---

## Step 4 — Fix with safety net

```
Small fix + confident + rollback plan ready → deploy to prod
Large fix / uncertain → reproduce on staging → test → deploy
Never:
  □ Edit prod DB directly without backup
  □ Deploy hotfix > 10 lines without staging
  □ Merge to main without review
```

---

## Step 5 — Post-incident (within 24 hours, when stable)

```
Write incident report:
  Timeline: [time] → [what happened]
  Root cause: [one sentence]
  Fix: [what was done]
  Prevention: [monitoring/alert/code change to detect earlier next time]

Add test or alert so this is detected faster next time.
Update CLAUDE.md tech debt log if structural cause found.
```
