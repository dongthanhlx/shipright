# Infrastructure — an agent with its hands on real systems

> A code mistake is caught by a test and undone by git. An infrastructure mistake is not: `terraform
> apply`, `kubectl delete`, a `DROP`, a DNS record or an IAM edit acts on the world at once, and some
> of it can't be taken back. This file extends `git.md`'s consent ladder to everything that isn't a
> repository, and moves the real safety from the prompt to the credential.
>
> Two incidents frame it:
> - **Amazon S3, us-east-1, February 2017.** An authorised engineer, following an established playbook,
>   mistyped one input and removed far more servers than intended. The fix went into the tool: it
>   removes capacity slowly and refuses to go below a safe minimum.
> - **An AI coding agent, 2025.** On a hosted app platform, an agent deleted a company's production
>   database during an explicit code freeze, then misreported what it had done. The platform's fix was
>   structural, not a better prompt: development and production databases were separated automatically.
>
> Master anchors: **Beyer et al.**, *Site Reliability Engineering* (2016: change management; ch. 26,
> *Data Integrity*) · **Kief Morris**, *Infrastructure as Code* · the **AWS Well-Architected Framework**,
> Reliability pillar (RPO/RTO, the four DR strategies) · the **OpenGitOps** principles (CNCF) · the
> **Terraform/OpenTofu** and **Kubernetes** documentation · **Saltzer & Schroeder** (least privilege,
> `security.md` §1) · the GitLab database-outage postmortem (2017).

Load this before any command that changes something outside the repo: a deploy run by hand, Terraform /
OpenTofu / Pulumi / CDK, `kubectl` / `helm`, a cloud CLI, a migration or a query against a shared
database, secrets, DNS, IAM, backups. Also when choosing where to run the app, and when setting up
backups. The release path itself (pipeline, migrations, rollout, flags) is `deploy.md`.

**First, read `## Infra policy` in CLAUDE.md.** None recorded → use the conservative default (below:
observe freely, ask for everything else) and offer to write the policy down once.

---

## 1. The infra consent ladder (git.md §1, extended)

```
TIER 0 — observe                         get / describe / list / logs · terraform plan · kubectl diff ·
                                         --dry-run=server · cloud CLI describe-* / list-* / get-* ·
                                         read-only SQL (ideally on a replica) · dashboards, billing views
   → Just do it. Logs and query results can contain PII and secrets: take what the task needs and
     don't copy the rest into chat or files.

TIER 1 — local and disposable            docker compose on this machine · a dev cluster or namespace
                                         YOU created this session · an ephemeral preview environment
   → Do it, per the policy.

TIER 2 — shared, not production          apply to staging · migrate the staging DB · reseed shared dev
                                         data · restart a shared service
   → Per the Infra policy; with none, ask. Name the target environment in the question.

TIER 3 — production, reversible          a deploy through the pipeline · scale up/out · flip a flag ·
                                         a config change with a known rollback
   → Ask each time unless the policy grants exactly this action. Show the plan; name the rollback.

TIER 4 — production, irreversible or     destroy / delete anything · DROP, TRUNCATE, DELETE or UPDATE
         wide blast radius               not bounded by ids · a migration's contract step · IAM, roles,
                                         security groups, firewall · DNS · TLS certificates · rotating
                                         or deleting secrets and keys · backup or retention settings ·
                                         turning off deletion protection · anything with a new
                                         recurring cost
   → ALWAYS explicit confirmation, every time, even with a policy. Plan output + blast radius +
     a verified backup point + the rollback, in the question.
```

**Standing rules at every tier:**
- **Verify the target before any command that isn't Tier 0:** `kubectl config current-context`,
  `terraform workspace show`, `aws sts get-caller-identity` (or `gcloud config list`), the database host.
  The worst incidents are the right command in the wrong environment.
- **Count before bulk.** Run the same `WHERE` as a `SELECT count(*)`; read the plan's
  "N to add, N to change, N to destroy" line. A count that surprises you means stop (the S3 lesson).
- **Diagnose, don't delete.** A failing resource is described and its events read; deleting and
  recreating loses its state, data, IP, DNS and history.
- **Never switch off a safety to make a command pass:** deletion protection, `prevent_destroy`, a
  PodDisruptionBudget, backup retention, branch protection. Needing to is the signal to stop and ask.
- **No change outside the code that owns it.** A console click or hot fix during an emergency is
  recorded and written back into IaC the same day, or it is drift (§3).
- **Production data:** read through a read-only role. Writes go through a reviewed script or
  migration, in a transaction, after a backup point, never through an interactive session.

**How to ask at Tier 3–4** (one message, everything needed to decide):
```
"Apply to PRODUCTION? (workspace prod · account 4821…, eu-west-1)
  Plan: 0 to add, 1 to change, 0 to destroy
    ~ aws_db_instance.main  instance_class db.t4g.medium → db.r7g.large
      restart: a brief failover on Multi-AZ, downtime without it · ≈ +$190/month
  Rollback: revert the commit and re-apply (another restart)
  Backup point: snapshot pre-resize-2026-10-28, status available"
```

---

## 2. The credential is the boundary; the prompt is a speed bump

An instruction to the model is a probability. A permission rule is better, but it matches command
**text**: a script, a `make` target or `bash -c` slips past it, and `bypassPermissions` mode skips it
entirely. **What the agent's shell can reach is what it can break.** So:

- **No production write credentials in the agent's environment by default.** Production reads use a
  read-only role; production writes go through the pipeline's own identity, or a human runs them.
  For a database: a dedicated role with `ALTER ROLE agent_ro SET default_transaction_read_only = on`
  (Postgres) and only `SELECT` grants.
- **Short-lived credentials:** SSO sessions for people (`aws sso login`, `gcloud auth login`); OIDC
  from CI to the cloud (GitHub Actions, GitLab) instead of long-lived keys stored as CI secrets.
- **One account / project / subscription per environment.** It is the strongest blast-radius wall the
  cloud offers: staging credentials can't touch production at all.
- **Guards on the resource itself:** deletion protection on production databases, `prevent_destroy` on
  stateful Terraform resources, versioning and object lock on backup buckets, PodDisruptionBudgets.

Then add permission rules as the deterministic floor (`git.md` §2 explains why `ask` is the right
level: it still prompts in auto mode):

```json
{
  "permissions": {
    "ask": [
      "Bash(terraform apply *)", "Bash(terraform destroy *)", "Bash(terraform import *)",
      "Bash(terraform state *)", "Bash(terraform force-unlock *)",
      "Bash(tofu apply *)", "Bash(tofu destroy *)", "Bash(tofu state *)",
      "Bash(pulumi up *)", "Bash(pulumi destroy *)", "Bash(cdk deploy *)", "Bash(cdk destroy *)",
      "Bash(kubectl apply *)", "Bash(kubectl delete *)", "Bash(kubectl patch *)",
      "Bash(kubectl edit *)", "Bash(kubectl scale *)", "Bash(kubectl drain *)",
      "Bash(kubectl rollout undo *)", "Bash(kubectl rollout restart *)", "Bash(kubectl exec *)",
      "Bash(helm install *)", "Bash(helm upgrade *)", "Bash(helm uninstall *)", "Bash(helm rollback *)",
      "Bash(docker system prune *)", "Bash(docker volume rm *)"
    ]
  }
}
```
Add the project's own wrappers (`Bash(make deploy*)`, `Bash(./scripts/prod-*)`). Cloud CLIs mix reads
and writes under one verb tree, so a text rule either asks for every read or misses writes; the
read-only role is what makes `aws` / `gcloud` / `az` reads safe to allow.

---

## 3. Infrastructure as code — the plan is the review

**When:** as soon as there is more than one environment, or more than a handful of resources. On a PaaS
at SEED, the platform's config file in git (`fly.toml`, `render.yaml`, `vercel.json`, an app spec) is
IaC enough.

**State:**
- Remote backend with locking: S3 with a lock (DynamoDB, or native `use_lockfile` on Terraform 1.10+),
  GCS, Azure Blob, HCP Terraform. Never local state on a team.
- Never commit state: it holds secrets in plain text. Never hand-edit it. `terraform state rm/mv` and
  `force-unlock` are Tier 4.
- Split state by environment **and** by blast radius (network · data · app), so an app change can never
  plan to destroy the VPC.

**Plan, then apply exactly what was planned:**
```
terraform fmt -check && terraform validate
terraform plan -out=tfplan          # Tier 0: read every line
terraform apply tfplan              # applies what was reviewed, nothing that changed since
```
Read the summary, then every `-` (destroy) and `-/+` (replace). **"forces replacement" on a database,
a volume or a bucket means data loss** unless something else carries the data across.

**Structure and guards:**
- Modules for reuse; environments as thin root modules with variables. Pin provider and module
  versions and commit the lock file.
- `lifecycle { prevent_destroy = true }` on databases, data buckets and KMS keys. It only guards while
  the block exists, so pair it with the provider's own deletion protection.
- **Drift:** a scheduled `terraform plan -detailed-exitcode` in CI (exit code 2 = drift) that alerts.
- At HARDEN and beyond: policy scans in CI (Checkov, Trivy, OPA/Conftest) for public buckets,
  `0.0.0.0/0` ingress, unencrypted storage and missing tags.

**The agent's division of labour:** the agent writes the change and runs `fmt`, `validate` and `plan`
(Tier 0), then shows the plan. The apply runs in CI on merge, or by a person. That turns an infra change
into a reviewed PR, and the merge is already Tier 4 in `git.md`.

---

## 4. Where to run it — containers, orchestration, GitOps

Choose by phase and by who will operate it, not by fashion (`scaling-guide.md`: never add Kubernetes
"because we'll need it").

```
PaaS (Render, Fly.io, Railway, Heroku, Cloud Run, App Runner; Vercel / Netlify for front ends)
   You buy deploys, TLS, logs and rollback. Right for SEED–VALIDATE, and often long after.
Containers on a managed runtime (ECS on Fargate, Cloud Run, Azure Container Apps)
   When you need network control, sidecars, several services, or a lower bill at sustained load.
Kubernetes (managed: EKS, GKE, AKS)
   When there are many services AND someone owns the platform AND a PaaS can't meet a real need
   (custom scheduling, operators, multi-tenant clusters). It's a platform for building platforms;
   its main cost is people, not the bill.
```

**Container image hygiene:**
- Multi-stage builds on a slim or distroless base, pinned by digest; a `.dockerignore`.
- Run as a non-root user; one process per container.
- No secrets in layers: use build secrets (`RUN --mount=type=secret`) and runtime env.
- Handle `SIGTERM` for graceful shutdown (`capacity.md` Rung 3): exec-form `CMD`, or `tini` as PID 1.
- Scan images in CI (Trivy, Grype); rebuild on base-image CVEs.

**On Kubernetes, the minimum that prevents the classic outages:**
- Every container sets resource requests, and a memory limit. CPU limits throttle latency-sensitive
  services; many teams set CPU requests only.
- Startup, liveness and readiness probes per `capacity.md` Rung 3 (liveness never checks dependencies).
- Rolling updates with `maxUnavailable: 0`; a PodDisruptionBudget so node drains can't take every
  replica; a short `preStop` sleep so endpoints are removed before the process stops taking traffic.
- Namespaces and RBAC per team or environment; NetworkPolicies default-deny on sensitive namespaces.
- Secrets: a `Secret` is base64, not encryption. Keep them out of git through External Secrets
  Operator, Sealed Secrets or SOPS, backed by a real secret manager.
- Autoscaling on the metric that saturates first, with a maximum (`capacity.md` Rung 7).

**GitOps** (OpenGitOps: desired state is *declarative*, *versioned and immutable*, *pulled
automatically*, and *continuously reconciled*):
- Argo CD or Flux runs in the cluster and pulls from git.
- Git becomes the audit log, `git revert` becomes the rollback, drift is corrected automatically, and
  CI never needs cluster credentials.
- The costs: one more system to run, secrets need their own answer, and image promotion needs
  automation (an updater bot or a PR that bumps the tag).
- Adopt it on Kubernetes at HARDEN. On a PaaS, "merge to main deploys" is the lightweight equivalent.

**For an agent, GitOps is the best consent model there is:** every infra change is a PR, and the merge
is the decision the user already owns.

---

## 5. Secrets in operation

- Distinct secrets per environment; production secrets never on a laptop or in an agent's environment.
- A managed store (the cloud's secret manager, Vault, Doppler, 1Password, Infisical) by HARDEN; the
  platform's env store before that.
- **Rotation without an outage:** support two valid credentials at once (new and old), deploy the new
  one, verify, then revoke the old one. A rotation that requires a simultaneous restart of everything
  will be postponed forever.
- **A leaked secret is rotated first, and purged second.** Removing it from history doesn't help: it is
  already in clones, forks, CI logs and caches. Then check the provider's access logs for use.
- Pre-commit and CI secret scanning (gitleaks, trufflehog, GitHub push protection).
- Deleting an encryption key (KMS, a master key) destroys every byte encrypted with it. It is Tier 4,
  and should be a scheduled deletion with a waiting period.

---

## 6. Backups and disaster recovery — restores, not backups

> "No one really wants backups; what people really want are restores." (*SRE*, ch. 26)

GitLab, January 2017: under pressure, an engineer deleted the primary database's data directory,
thinking they were on the replica. Of the five backup and replication mechanisms in place, none worked
as expected. The restore came from a staging copy taken six hours earlier, and six hours of data were
lost. Every mechanism existed; none had been restored.

**Decide RPO and RTO per data class first.** How much data may be lost (RPO), and how long may it be
down (RTO)? These are product decisions with a price, like a staleness budget.

**The mechanisms, and what each one is not:**
- **Point-in-time recovery** (continuous WAL / binlog archiving: the managed provider's PITR,
  pgBackRest, WAL-G). RPO of minutes. This is the primary.
- **Periodic logical dumps** (`pg_dump`, `mysqldump`). Portable and slow on large databases; a good
  second form that survives a corrupted physical chain.
- **A replica is not a backup:** it replicates a `DROP TABLE` within milliseconds.
- **A snapshot in the same account is not offsite:** whoever (or whatever) can delete the database can
  usually delete the snapshot.
- **3-2-1** (three copies, two kinds of media, one offsite), in cloud terms: another region **and**
  another account, made immutable (object lock, a locked backup vault) against ransomware and against
  your own credentials.
- Back up what the database doesn't hold: object storage (versioning plus lifecycle rules), secrets
  and keys, IaC state, DNS zones, and the queue's dead-letter queue if it holds unprocessed work.

**Restore drills:** scheduled (monthly, or quarterly at minimum) and automated:
1. restore the latest backup to a scratch instance;
2. check it: row counts, the newest timestamp is within RPO of now, the app's smoke test passes;
3. record how long it took. That duration is your real RTO;
4. alert when the drill fails.

An untested backup is a hope.

**DR strategies** (AWS Well-Architected, cheapest and slowest first): backup & restore (RTO in hours) →
pilot light → warm standby → multi-site active/active (RTO in seconds, the most expensive by far). For
most products the answer is backup & restore, IaC that can rebuild everything, and a runbook that has
been followed once. Climb only when the RTO demands it.

**Before any Tier 4 data action:** take a named backup point and check that it completed.

---

## 7. Cost is an operational property

- Every change that adds a resource states its monthly cost in the plan review (Infracost for Terraform,
  or the provider's calculator). A new recurring cost is Tier 4.
- Budgets and billing alerts from day one: the cheapest insurance in the cloud.
- The usual surprises: NAT gateway data processing, cross-zone and egress traffic, idle or oversized
  instances, log ingestion and retention (the observability bill), forgotten preview environments, and
  autoscaling without a maximum.
- Tag every resource (`env`, `service`, `owner`) so the bill can be attributed; give ephemeral
  environments a TTL.

---

## 8. The dial — the minimum operations per phase

```
SEED      A PaaS. Provider backups ON and restored once. A billing alert. No production write
          credentials in the agent's environment. The platform config in git.
VALIDATE  Staging. Everything in IaC or platform config. Production in its own account / project.
          Uptime check + error alerting (observability.md). A one-page runbook: deploy, rollback,
          restore.
HARDEN    Remote state with locking; plan in CI, apply on merge. Deletion protection + prevent_destroy.
          PITR plus an offsite, immutable copy; a scheduled restore drill. Secret manager + OIDC.
          Cost tags; policy scans. GitOps if on Kubernetes.
SCALE     Drift detection. A DR strategy chosen per RTO, and game days that exercise it. Policy-as-code
          gates. A platform owner for the paved road.
```

## Add to CLAUDE.md at the first shared environment

```markdown
## Infra policy
Environments: local · staging · prod (prod = account/project <id>, context <name>, workspace <name>)
Agent credentials: prod read-only · staging [read-only | apply]
Observe (get/describe/plan/diff/logs): always
Staging apply / migrate: [auto | ask first]
Prod: ships through the pipeline on merge; any other prod change asks, with the plan and the rollback
Tier 4 (destroy, IAM, DNS, data deletion, backups/retention, new recurring cost): explicit, every time
Backups: [mechanism] · RPO [x] · RTO [y] · last restore drill [date]

## Debt signals
- TODO[restore drill overdue since <date>]: run it, record the duration
- TODO[drift on <stack>]: write the console change back into IaC
- TODO[long-lived cloud key in <CI/env>]: replace with OIDC / SSO
- TODO[resource without owner/env tags: <id>]: tag it or delete it
```
