# Deploy — make change boring

> Most outages are self-inflicted. Google's SRE teams found that roughly 70% of outages come from a
> change to a live system: code, config, schema or infrastructure. The answer is not fewer deploys.
> It is deploys **small enough** to reason about, **visible enough** to judge within minutes, and
> **reversible enough** that a bad one costs minutes, not a night. DORA's data says speed and
> stability are not a trade-off: the teams that deploy most often also break production least.
>
> Master anchors: **Humble & Farley**, *Continuous Delivery* (2010: the deployment pipeline, build once,
> one deploy process for every environment) · **Forsgren, Humble & Kim**, *Accelerate* (2018) and the
> DORA reports · **Wiggins**, *The Twelve-Factor App* (config, build/release/run, dev/prod parity,
> disposability) · **Beyer et al.**, *Site Reliability Engineering* and *The Site Reliability Workbook*
> (change management, canarying releases) · **Liguori**, *Automating safe, hands-off deployments* and
> **Pokkunuri**, *Ensuring rollback safety during deployments* (Amazon Builders' Library) ·
> **Hodgson**, *Feature Toggles* (martinfowler.com, 2017) · **Sato**, *ParallelChange*, and **Ambler &
> Sadalage**, *Refactoring Databases* (expand/contract) · **Majors** (decouple deploy from release) ·
> **Kane**, `strong_migrations` (the catalogue of unsafe migrations).

Load this before the first deploy beyond a laptop, when setting up CI/CD or staging, before any schema
change on a database that has users, when a deploy broke production or the team is afraid to deploy,
and when adding feature flags. Infrastructure changes and who may run them are `infra.md`; the git
side of a release is `git.md`.

---

## 0. The release floor — before the first real user

```
□ One command or one pipeline deploys. No hand-edited servers: if it only works on the box, it can't
  be redeployed, and nobody knows what is running.
□ The artifact is built ONCE per commit, named by the commit SHA, and promoted unchanged.
  Staging and production run the same bytes.
□ Config and secrets come from the environment, never baked into the artifact; validated at boot,
  fail fast on a missing or malformed value.
□ Health endpoints exist (capacity.md Rung 3: shallow liveness, readiness that checks only the
  instance itself).
□ The previous version can be redeployed in minutes, and that has been DONE once, not assumed.
□ Migrations run as their own explicit step, never as a side effect of app boot on N instances.
□ The running version is visible: a version label on every log line, span and metric, and a deploy
  marker on the dashboard. "Did it start after the deploy?" must have an answer.
□ A backup exists and has been restored once (infra.md §6).
```

---

## 1. Environments and config (Twelve-Factor)

**Environments.** Local, staging and production; per-PR preview environments when the platform makes
them cheap. Staging earns its cost when it runs the **same artifact, the same deploy script and the
same kinds of backing services** as production (Postgres in tests, not SQLite). It will always differ
in data and in load, so it catches wiring and migrations, not capacity. Load is `capacity.md`'s job.

**Config.** Three kinds, kept apart:
- **Deploy-time config:** URLs, pool sizes, flag defaults. From the environment.
- **Secrets:** from the platform's secret store or a secret manager (`infra.md` §5). Never in git,
  never in the image, never in a log line.
- **Build-time config:** ideally none. A front-end bundle that needs a public URL at build time is
  rebuilt per environment and breaks "build once". Prefer runtime config (a `/config.json` served
  by the app) when it matters.

The code never asks which environment it is in. `if (env === "prod")` is a smell; the difference is a
config **value** (`PAYMENTS_MODE=live`), so staging exercises the same code path. Validate the whole
config at boot with a schema (zod, pydantic, envconfig): a missing value fails the deploy, not the
first customer request (`security.md` A02).

---

## 2. The pipeline — build once, promote

```
commit ─► CI: build · unit · lint · typecheck · dependency/secret scan
        ─► artifact: image tag = git SHA, immutable (never :latest; pin base images by digest)
        ─► staging: same deploy script as prod ─► migrations ─► smoke / e2e on the critical journeys
        ─► production: progressive rollout (§4), bake time, automatic rollback on alarms
        ─► verify: synthetic check of the critical journey + the business metric
```

- **Never rebuild for production.** A rebuild is different bytes: a new transitive dependency, a new
  base image, a non-reproducible step. What you tested is not what you shipped.
- **The deploy script is code:** versioned, the same for every environment, idempotent. Re-running a
  deploy that half-failed must be safe.
- **The pipeline deploys; people and agents trigger it.** Nobody SSHes in to `git pull`. The pipeline's
  identity holds the production credentials, so a laptop (or an agent's shell) doesn't have to
  (`infra.md` §2).
- **Small batches.** One logical change per deploy where you can. When a deploy of 40 commits breaks,
  the search is 40 commits wide. DORA's research ties small batches to lower change failure rates.
- **"Don't deploy on Friday"** is a symptom. The question is whether you can see a bad deploy and undo
  it in minutes; if you can't, fix that. A freeze around a known high-stakes event is still sensible.

---

## 3. Database migrations on a live system — expand / contract

During a rolling deploy, **old and new code run against the same schema at the same time**. A rollback
runs old code against the new schema. So every migration must work with the version before it and the
version after it. Destructive change gets split into steps that each preserve that property
(Ambler & Sadalage's *transition period*; Sato's *parallel change*):

```
Rename users.name → users.full_name, without downtime:
1 EXPAND       add full_name, nullable                          deploy: schema only
2 DUAL WRITE   code writes both columns, still reads name       deploy
3 BACKFILL     copy old → new in batches (1–10k rows), throttled, resumable, idempotent; a job, not a
               migration transaction; watch replica lag
4 SWITCH READ  code reads full_name, still writes both          deploy  ← rollback is still safe
5 STOP OLD     code stops writing name                          deploy
6 CONTRACT     drop name: days later, once nothing reads it     deploy  ← the one-way door
```
Steps 1–5 are each reversible. Step 6 is not: it gets a backup point and explicit confirmation
(`infra.md` Tier 4). The same pattern on the code side is `requirement-drift.md` (expand → migrate →
contract).

**Operations that lock or rewrite** (Postgres names; other engines differ in names, not in kind):

| Operation | What goes wrong | Safe form |
|---|---|---|
| Any DDL | It waits for an exclusive lock behind a long query, and every query queues behind *it* | `SET lock_timeout = '5s'` (and a `statement_timeout`) inside the migration; retry on timeout |
| `CREATE INDEX` | Blocks writes for the whole build | `CREATE INDEX CONCURRENTLY`, outside a transaction. A failure leaves an INVALID index: drop it, retry |
| Add a foreign key or `CHECK` | Scans the table while holding a lock | `ADD CONSTRAINT … NOT VALID`, then `VALIDATE CONSTRAINT` in a separate step |
| `SET NOT NULL` on a big table | Full scan under an exclusive lock | Add `CHECK (col IS NOT NULL) NOT VALID` → validate → `SET NOT NULL` (PG 12+ skips the scan) → drop the check |
| Change a column type | Usually a full table rewrite | A new column plus expand/contract |
| Add a column with a volatile default (`now()`, `random()`) | Table rewrite | Add nullable, backfill, then set the default. A constant default is metadata-only on PG 11+ |
| Rename or drop a column or table | The old code still running breaks at once | Expand/contract. Tell the ORM to ignore the column first (e.g. Rails `ignored_columns`) |
| One big `UPDATE` / `DELETE` | Long locks, bloat, replica lag | A batched backfill job with pauses between batches |

MySQL: online DDL support varies by version and operation (`ALGORITHM=INSTANT/INPLACE`); for large
tables use `gh-ost` or `pt-online-schema-change`. Lint migrations in CI: `strong_migrations` (Rails),
`squawk` (any Postgres SQL), Django's `sqlmigrate` review.

**Rules:**
- Migrations are versioned files in git, applied by a tool (Prisma Migrate, Alembic, Flyway, Liquibase,
  golang-migrate, Laravel, Django). **Forward-only in production.** A "down" migration rarely survives
  real data; the rollback of a schema change is the next expand/contract step, and the last resort is
  the backup.
- Run them **once, as a pipeline step, before the new code rolls out.** On boot, N instances race for
  them, and a slow migration fails every readiness check at once.
- Time them against a production-sized, anonymised copy. Two seconds on a dev database can be forty
  minutes on production.
- Data migrations (backfills, fixes) are code: reviewed, idempotent, batched, logged with counts, and
  run with a `--dry-run` that prints how many rows would change.

---

## 4. Rolling out — limit the blast radius, detect, undo automatically

| Strategy | How | Rollback | Watch out for |
|---|---|---|---|
| Rolling | Replace instances a few at a time | Roll the previous artifact back the same way | Two versions serve traffic at once: §3 and §5 must hold |
| Blue/green (Fowler) | Two full environments; switch the router | Switch back: seconds | Briefly double the cost; the database is shared, so the schema must suit both |
| Canary (Sato; SRE Workbook) | A small slice first (one box, 1–5%, one cell), compared with the rest | Stop and drain the canary | Compare the canary with the control group **at the same time**, not with yesterday |
| Dark launch + flag (§6) | Deploy with the feature off; release by config | Flip the flag off | A flag that defaults ON when its service is down |

Amazon's pipelines (Liguori) are the reference shape: pre-production → **one box** → a small wave →
progressively larger waves, each with a **bake time**, **automatic rollback** when an alarm fires, and
time windows that block deploys when nobody is around to respond.

**What to watch during the bake:** error rate, p99 latency and saturation **by version label**, and the
**business metric** (orders per minute, sign-ups, messages sent). A deploy can leave 5xx flat while
checkout conversion drops to zero.

**Roll back first, debug later** (`branches/f-incident.md`). Rollback is the fastest and most practised
path: one command that redeploys the previous SHA. Roll forward only when rolling back is unsafe (the
new version already wrote something the old one can't read, which §5 exists to prevent) or when the
fix is tiny and certain.

**What a rollback does not undo:** rows already written, messages already published, emails and push
notifications sent, third-party calls made (charges, refunds), and a migration's contract step. Know
which of these the change does before you ship it.

---

## 5. Rollback safety — the two-phase change (Pokkunuri)

When new code **writes** something old code can't **read** (a new message field it requires, a new
enum value, a new cache serialisation, new column semantics), a rollback strands the data written in
between. Split it:

```
Phase 1  PREPARE   deploy code that READS old and new, and still WRITES old. Roll out fully.
Phase 2  ACTIVATE  deploy code (or flip a flag) that WRITES new.
```
Rolling back Phase 2 now lands on readers that understand everything written. Where it applies:
- queue messages: `messaging.md` §7 (tolerant readers, additive changes);
- cache values: `caching.md` key versioning (`app:v3:...`);
- persisted enums and JSON columns;
- API responses consumed by **mobile and desktop clients**. Those never roll back; old versions stay
  installed for years, so their contracts are additive or versioned, never changed in place.

---

## 6. Feature flags — deploy is not release (Hodgson)

| Kind | Purpose | Lifetime | Flipped by |
|---|---|---|---|
| Release | Ship unfinished or risky code dark; release gradually | Days to weeks. **Delete** after 100% | Developers |
| Ops (kill switch) | Turn off an expensive or fragile path under load | Long-lived, deliberate, documented | On-call |
| Experiment | A/B test | Until the decision | Product |
| Permission | Plan, beta or tenant access | Long-lived: it's product logic | The product, via entitlements |

- **A flag service is a dependency** (`resilience.md`): every evaluation needs a local default for when
  it is unreachable. Release flags default OFF; kill switches keep the last known value. Anything
  security-relevant is evaluated server-side.
- **Every release flag gets an owner and a removal date when it is created.** A flag at 100% for two
  weeks is debt, and each live flag doubles the states nobody has tested.
- **Never reuse a flag's name for a new meaning, and delete dead code with its flag.** Knight Capital
  (2012): a deploy reached seven of eight servers; a repurposed flag woke code that had been dead for
  years on the eighth, and the firm lost about $440M in 45 minutes. The two lessons: delete dead code,
  and verify that every instance runs the same version.
- Test both states of any flag that ships.
- Start with config or a database table. Adopt a flag service when you need percentage rollouts or
  targeting; prefer one behind the OpenFeature API (Unleash, Flagsmith, GrowthBook, LaunchDarkly) so the
  vendor stays behind an adapter (Boundary 4).

---

## 7. After the deploy — verify, then measure the pipeline

- A synthetic check of the critical journey in production (log in, add to cart, pay in test mode), not
  just `/health` returning 200.
- The deploy marker and version label make "what changed?" a lookup, not an investigation.
- DORA's four keys, tracked once deploys are frequent enough to count: deployment frequency, lead time
  for changes, change failure rate, time to restore (`observability.md`). They are a diagnosis of the
  pipeline, never a target for individuals.

---

## 8. The dial — what to add at each phase

```
SEED      A PaaS or one VM with a deploy script; push-to-deploy is fine. Migration tool from the first
          table. Secrets in the platform's env store. Provider backups ON, restored once.
VALIDATE  CI builds the artifact once; staging with the same script; health checks; the rollback
          command tested; expand/contract for any change to a table with users; version label in
          logs; release flags from config.
HARDEN    Progressive rollout with bake time and automatic rollback on alarms; the business metric in
          the bake checks; migration linting in CI; secret manager + short-lived CI credentials
          (infra.md §2); flag defaults for outages; a written deploy / rollback / restore runbook.
SCALE     One-box and waves by zone, region or cell; two-phase changes enforced in review; deploy
          windows; DORA metrics; the pipeline treated as a product with an owner.
```

## Add to CLAUDE.md when the first real deploy lands

```markdown
## Deploy conventions
- Artifact built once per commit, tagged <sha>; staging and prod run the same artifact.
- Deploy: [command / pipeline]. Rollback: [command] (redeploy the previous sha), last tested [date].
- Migrations: forward-only, a pipeline step before rollout; expand/contract on live tables;
  lock_timeout 5s; indexes CONCURRENTLY; backfills are batched jobs.
- Anything another version must read (messages, cache values, persisted enums, client APIs):
  two-phase — read both first, write new second.
- Release flags: owner + removal date at creation; default OFF when the flag service is down.
- Config and secrets from the environment, validated at boot; no environment-name branches in code.

## Debt signals
- TODO[rollback untested since <date>]: redeploy the previous sha on staging
- TODO[flag <name> at 100% since <date>]: delete the flag and the dead path
- TODO[migration <id> took <N>s on the prod copy]: batch it / make it concurrent
- TODO[manual deploy step: <step>]: automate it
```
