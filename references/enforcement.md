# Enforcement — boundaries that block, not just advise

> Documentation tells Claude the rules. A hook *enforces* them. `hooks/boundary-guard.sh` is a
> PreToolUse hook that inspects the code Claude is about to write and **blocks** the two
> highest-confidence boundary violations before they ever land in a file.
>
> This is opt-in. shipright works fully without it (the rules live in CLAUDE.md and the quality
> gate). The hook is for teams that want the boundaries to be un-bypassable, not just agreed.

---

## What it blocks (only near-zero-false-positive cases)

```
Boundary 2 — a service-layer file importing the shared DB module
  src/modules/orders/orders.service.ts:  import { db } from '../../shared/db'   ← BLOCKED
  (TS *.service.* / Py *_service.py ; matches shared/db and shared.db)

Boundary 1 — a deep import into ANOTHER module's internals (bypassing its index)
  src/modules/orders/orders.service.ts:  import { X } from '../payments/payment.service'  ← BLOCKED
  (keys on .service/.repository/.controller/.store/.gateway file suffixes, which only exist
   inside modules — so shared/ and config/ never false-positive)
```

Everything else — project-specific banned imports, money rules, naming — stays in CLAUDE.md and
the Branch B quality gate. The hook deliberately enforces only the universal two, because a guard
that false-positives gets disabled. (This restraint is `references/judgment.md` applied to the
guard itself: know when NOT to fire.)

When blocked, Claude receives the reason on stderr and self-corrects (imports via the public
`index` / injects a repository) — usually on the next attempt, no human needed.

---

## Install (opt-in)

Add to `~/.claude/settings.json` (user-level is safe — see "Safe to enable globally" below):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command",
            "command": "~/.claude/skills/shipright/hooks/boundary-guard.sh" }
        ]
      }
    ]
  }
}
```

If you already use shipright's SessionStart update check, keep both — they're independent hooks.

Verify the logic at any time (no Claude Code session needed):
```bash
~/.claude/skills/shipright/hooks/boundary-guard.sh --self-test
```

---

## Configuration

| Control | Effect |
|---|---|
| `SHIPRIGHT_GUARD=off` (env) | Disable the guard entirely for a session |
| `shipright-ignore` (code comment on the line) | Allow one specific import — the senior move: name the exception |
| module dir convention | Auto-detects `modules/ \| domains/ \| features/ \| services/` as the module root |

**Bypass example** (a legitimate, documented exception):
```typescript
import { db } from '../../shared/db' // shipright-ignore: one-off migration shim, removed in #214
```
This mirrors judgment.md — breaking a rule is fine *when you name why*; breaking it silently is not.

---

## Guarantees

- **Fails open.** Any internal error — no working `jq` or Python, malformed input, an unknown
  tool shape — results in *allow*, never a block. The guard can never brick your editing.
  The flip side: failing open is *silent*. Run `--self-test` once on each machine — its header names
  the parser it found, and with none it reports the end-to-end cases as **skipped**, i.e. the guard
  is installed but inert. (On Windows the `python3` on PATH is often the Microsoft Store alias, which
  exists and fails; the guard now only uses a Python that actually runs, `python3` then `python`.)
- **Portable.** bash 3.2 (stock macOS) to 5.x; Linux, macOS, Windows (Git Bash). Windows paths
  (`D:\repo\src\modules\…`) are normalized, and paths are made relative to the session's `cwd`
  before the module is read, so a `services/` folder *above* the repo is never mistaken for one.
- **Resolves before it judges.** A relative import is resolved against the file's own directory
  first: `../orders.service` from `orders/http/` is the same module and allowed; `../../payments/
  payment.service` from the same place is blocked. Comment lines are ignored.
- **No-op outside module-structured projects.** A file not under a `modules/`-like directory is
  ignored, so enabling it globally is safe — it only acts on shipright-shaped repos.
- **Source files only.** Non-source files (`.md`, configs) and the Bash tool are ignored.
- **Fast + offline.** Pure shell + one JSON parse (`jq`, else a working Python). No network, no state.

---

## What it does NOT do (by design)

- It does not enforce project-specific rules (those belong in CLAUDE.md — they vary per project).
- It does not lint style, naming, or Boundary 3/4/5 (too project-specific / too easy to
  false-positive at the import-string level). Those stay in the Branch B quality gate.
- It is not a substitute for code review — it's a fast structural tripwire for the two violations
  that are cheapest to prevent and most expensive to unwind later.

The guard is a *fitness function* (Ford/Parsons) — an automated integrity check of an architectural
characteristic (here: no cross-module deep imports), just at edit-time instead of CI. The full set of
shipright's fitness functions + how they let the architecture evolve safely: references/evolutionary-architecture.md.

If you want broader static enforcement at CI time (not edit time), use dependency-cruiser
(Node) or import-linter (Python) — see `references/scaling-guide.md` Stage 1, Step 3.
