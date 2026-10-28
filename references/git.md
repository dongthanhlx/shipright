# Git — fluent with the tool, careful with the doors

> Every git operation is a door (judgment.md §1), and it has two dimensions: **can it be undone**
> (reflog protects commits, nothing protects uncommitted work) and **who sees it** (local vs everyone who
> pulls). An agent that runs git fluently but asks at the wrong moments is a hazard; one that asks about
> everything is friction. This file is where the line sits.
>
> Masters:
> - **Scott Chacon** (*Pro Git*, GitHub Flow) — the object model, reflog, and why published history is shared.
> - **Chris Beams** (*How to Write a Git Commit Message*) and **Tim Pope** — the seven rules; the log is documentation.
> - **Conventional Commits** — a machine-readable subject line (the style shipright already uses).
> - **Kent Beck** (*Tidy First?*) — structure and behaviour changes go in separate commits.
> - **Martin Fowler** (*Patterns for Managing Source Code Branches*, *Continuous Integration*) and
>   **Paul Hammant** (trunk-based development) — short-lived branches, integrate often.
> - **Google engineering practices** (*Small CLs*) — one change per review; small enough to review well.
> - **DORA / Accelerate** — small batches and fast integration predict delivery performance.
> - **Tom Preston-Werner** (SemVer) and **Olivier Lacan** (Keep a Changelog) — releases people can trust.
> - **Julia Evans** — git's mental model, and how to get out of trouble.
>
> If addyosmani's `git-workflow-and-versioning` is installed it may execute the mechanics; **the consent
> ladder and the project's git policy below always stay shipright's** — no mechanics skill decides when
> to ask the user.

---

## 0. Read the repo before you touch it

```
git status                         what's modified, staged, untracked — ALWAYS first, and before anything destructive
git branch --show-current          never assume; detached HEAD and the default branch both matter
git log --oneline -15              the house commit style (Conventional? ticket prefixes? sentence case?)
git log --merges --oneline -5      the house merge strategy (merge commits present? squash-only? linear?)
git remote -v · git branch -vv     where pushes go; which branches track what; ahead/behind
git stash list                     forgotten work you must not clobber
.github/PULL_REQUEST_TEMPLATE*, CONTRIBUTING.md, .pre-commit-config.yaml, commitlint config
```
**The repo's conventions beat this file.** Match the existing style; only fall back to the defaults here
when the repo has none.

---

## 1. The consent ladder — what the agent may do, and when it must ask

```
TIER 0 — read-only                     status · diff · log · show · blame · fetch · branch -a · reflog ·
                                       stash list · bisect (read-only runs)
   → Just do it. Asking here is friction.

TIER 1 — local, recoverable (reflog)   create/switch branch (clean tree) · stage · commit on a
                                       feature branch · stash push · rebase/squash commits NOT yet pushed ·
                                       amend a commit NOT yet pushed
   → Allowed when the project's Git policy (§2) grants it. With no policy: propose, then do it on "yes".
     Commits only on a feature branch, never directly on the default branch.

TIER 2 — destroys UNCOMMITTED work     reset --hard · checkout/restore of modified files · clean -fd ·
         (no reflog can bring it back) stash drop/clear · branch -D of an unmerged branch ·
                                       rebase that drops commits · checkout that would overwrite changes
   → ALWAYS ask, every time, with the evidence: what exactly would be lost (git status, diff --stat,
     stash show -p). Offer the safe alternative first: stash it, or commit it to a backup branch.
     The one exception is narrow: undoing YOUR OWN edits since your last checkpoint (a failed refactor
     step), by path — `git restore <files you touched>`. That's why the tree was clean, or checkpointed,
     before you started. If it wasn't, you can't tell your edits from the user's: ask.

TIER 3 — outward-facing (others see it) push · open/update a PR · comment/review on a PR · push a tag ·
                                       create a release · delete a remote branch
   → Ask each time, unless the Git policy grants exactly this action. A "yes" covers THAT action on
     THAT branch — not the next branch, not the next session. After doing it, report the URL.

TIER 4 — shared history / production   merge into the default or a protected branch · push directly to
                                       it · force-push a shared branch · rewrite published history ·
                                       delete the default branch · change branch protection · publish a
                                       release/tag that triggers a deploy
   → ALWAYS explicit confirmation with the consequence stated — even when a policy exists. Never on a
     protected branch unless the user names it. Merging is the user's decision; shipright prepares it.
```

**Standing rules at every tier** (the harness and the repo's safety nets exist for a reason):
- Never `--no-verify`, never skip signing, never edit git config (`user.name`, `user.email`, hooks).
- A hook failed → the commit did **not** happen. Fix the cause and make a **new** commit; `--amend` there
  would rewrite the *previous* commit.
- Force-push only your own branch, only with `--force-with-lease --force-if-includes`, only after asking.
- No interactive commands (`-i`, an editor). Messages via `-m` / `-F` / a heredoc.

### How to ask — one line, everything needed to decide
```
"Push 3 commits (feat/account-roster, a new branch — not main) to origin and open a DRAFT PR against main?
  a1b2c3 feat(accounts): add AccountRoster view-model
  d4e5f6 test(accounts): cover NEEDS_ATTENTION transition
  789abc docs: record ADR-002 session partitions"
```
What, where, whether it's reversible, and the evidence. Never "should I commit?" with nothing attached.

---

## 2. The Git policy — durable authorization, set once in CLAUDE.md

Consent asked every time is friction; consent assumed is a hazard. The fix is to ask **once, at L0**
(or the first time git comes up) and record the answer where every session reads it:

```markdown
## Git policy
Default branch: main — protected; never commit or push to it directly
Commit:   auto on feature branches at green   | ask first
Push:     auto to my own feature branches     | ask first
PR:       auto-open as DRAFT                  | ask first
Merge:    always ask (Tier 4 — the user merges or explicitly approves)
Strategy: squash | merge commit | rebase       (match the repo's history)
Style:    Conventional Commits — type(scope): imperative summary
```
SKILL.md's working context reads the **whole section** (heading to next `## ` heading) every session,
so a rule added here is seen — but keep it short: every line is read at every session start.

**No policy recorded → the conservative default:** propose commits and ask; ask before every push, PR
and merge. Offer to write the policy down the first time — then stop asking what it already answers.
A policy can widen Tier 1 and Tier 3. Nothing widens Tier 2 or Tier 4.

---

## 3. When to commit (Beck, Fowler, CI)

```
□ At green: the tests you touched pass and the quality gate is clean (b-add-feature.md Step 5). Never
  push red. (A deliberate RED test in a TDD step may be a local checkpoint — squash it before pushing.)
□ One logical change per commit — describable in one sentence without "and".
□ Structure and behaviour in separate commits (Tidy First): a rename/extract first, then the feature.
  Refactors never ride along with fixes (c-fix-bug.md, d-refactor.md already require this).
□ Small and often: every commit is a safe point to return to. Before a risky step (a big refactor, a
  migration), make the checkpoint commit first — if the policy allows it, or ask.
□ Stage deliberately: `git add <paths>`, never a blind `git add -A`. Read `git diff --staged` before
  committing. Untracked files are reviewed, not swept in.
□ Unrelated changes you notice (formatting, a typo elsewhere) → a separate commit, or tell the user —
  never folded silently into this one.
```

**Never commit:** secrets, `.env`, keys, tokens, credentials in URLs · build output, dependency folders,
caches · large binaries (use LFS or keep them out) · local editor/OS files · anything the user didn't ask
to change. A `.gitignore` covering these exists from the first commit.

---

## 4. Commit messages (Beams · Conventional Commits)

```
feat(accounts): pause an account when the platform asks for verification

The platform's challenge page was being retried, which locks accounts.
NEEDS_ATTENTION now stops the account and surfaces it in the AttentionInbox;
the user resolves it, then resumes.

Refs: #142
```
- **Subject:** the repo's style first; otherwise `type(scope): summary` — imperative ("add", not
  "added"), ~50 chars (72 max), no trailing period. Types: feat · fix · refactor · test · docs · perf ·
  build · ci · chore. Breaking change → `!` after the type and a `BREAKING CHANGE:` footer.
- **Body:** *why* and what changed in behaviour — the diff already shows *how*. Wrap at 72.
- **Scope and nouns from the Ubiquitous Language** — `feat(payouts)`, not `feat(stuff)`.
- Trailers the harness or repo requires (Co-Authored-By, sign-off, issue refs) go at the end.
- Never: "wip", "fix", "update", "changes", "misc" as the whole message on anything that gets pushed.

---

## 5. Branches (Fowler · trunk-based · GitHub Flow)

```
□ Never work directly on the default branch — branch first (`type/short-description`: feat/account-roster,
  fix/payout-idempotency).
□ Short-lived: merge within a day or two. A long-lived branch is deferred integration (team-scale.md).
□ One concern per branch; unfinished work merges behind a feature flag rather than living on a branch.
□ Staying current: rebase commits that are only yours and unpublished; once pushed and shared, merge the
  default branch in instead (or ask before a rebase + force-push — Tier 4 on a shared branch).
□ After merge: switch to the default branch, pull, delete the local branch (Tier 1). Deleting the
  remote branch is Tier 3 unless the host does it on merge.
```

---

## 6. Pull requests (Google *Small CLs*)

```
□ Small: one concern; roughly under 200–400 changed lines. A bigger change is split into PRs that
  build on each other.
□ Self-review the full diff before anyone else sees it — as if reviewing a stranger's code.
□ Description = what · why · how it was tested · risks / rollout · screenshots for UI. Use the repo's
  PR template when there is one.
□ CI green before asking for review. Draft PR when you want early feedback, not approval.
□ Responding to review: push new commits; don't force-push over reviewed commits unless that's the
  repo's convention.
□ The review gate is real: /code-review is user-invoked — ask for it; /security-review when auth,
  payments or untrusted input were touched (SKILL.md §Quality system).
□ No `gh` CLI? Give the user the compare URL and a ready-to-paste title + body. Don't block.
```

---

## 7. Merging — prepared by shipright, decided by the user

```
□ Preconditions: CI green, required approvals, no unresolved threads, branch current with the base.
□ Strategy = the repo's (read it from history — §0): squash for feature PRs with noisy history, a merge
  commit when the individual commits carry meaning, rebase-merge for a linear log.
□ Never merge your own PR, or anything into a protected branch, without explicit confirmation (Tier 4).
□ After merging: pull the default branch, delete the branch, check the deploy/CI run that it triggered.
```

## 8. Conflicts

```
□ Understand both sides before choosing: `git log --merge -p`, and conflictstyle=zdiff3 shows the base.
□ Never a blanket --ours / --theirs over a conflict you haven't read.
□ Resolve, run the tests, then continue. If the right answer depends on intent ("which behaviour
  should win?"), that's the user's call — ask with both versions shown.
□ Rebase/merge in progress and it's going wrong → `--abort` returns to safety. It's always available.
```

## 9. Versions and releases

```
SemVer       MAJOR for breaking changes · MINOR for features · PATCH for fixes. Pre-1.0 promises nothing.
Changelog    Keep a Changelog: Added / Changed / Fixed / Removed / Security — written for users, not a git log dump.
Tags         annotated (`git tag -a v1.4.0 -m ...`), on the default branch, after the merge.
Publishing   pushing a tag or creating a release is Tier 3 — Tier 4 when it triggers a deploy.
```

## 10. Recovery (Pro Git, Julia Evans)

```
Committed on the wrong branch (unpushed)  → branch from here, reset the original back (Tier 1: reflog has it)
Need to undo a PUSHED commit              → git revert (a new commit). Never reset + force-push shared history.
"Lost" a commit or branch                 → git reflog, then branch from the entry
Bad merge not yet pushed                  → git reset --hard ORIG_HEAD (Tier 2 if the tree is dirty — ask)
Find which commit broke it                → git bisect (c-fix-bug.md Step 2)
A SECRET was committed                    → ROTATE IT FIRST. Removing it from history (git filter-repo) is a
                                             Tier 4 rewrite and does not un-leak what was already pushed or cloned.
```

## 11. Git hygiene that is really security (references/security.md)

```
□ .gitignore from the first commit (.env*, keys, credentials, build output).
□ Secret scanning before commit (gitleaks / the host's push protection) — cheaper than a rotation.
□ Signed commits when the repo requires them — never bypass.
□ Never put tokens in remote URLs, commit messages, PR bodies or command output you print.
```

---

## Add to CLAUDE.md (at L0 — the first time git comes up)

The `## Git policy` block from §2, filled with the user's answers. Nothing else from this file needs to be
in the constitution — it's how shipright works, not a project decision.
