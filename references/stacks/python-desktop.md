# Stack Reference: Python desktop apps on Windows (Qt / PySide6)

> A desktop app is a **long-running process on a machine you don't control**, with one thread that
> must never block, secrets that live on the user's disk, and a binary that Windows will distrust until
> it is signed. Everything below follows from those three facts.
>
> Master anchors: **the Qt Project** (*Threads and QObjects* — the threading contract you cannot
> break); **Martin Fitzpatrick** (*Create GUI Applications with Python & Qt*, pythonguis.com — the
> practical PySide6 canon); **Mark Summerfield** (*Rapid GUI Programming with Python and Qt* —
> model/view); **Raymond Chen** (*The Old New Thing* — how Windows actually behaves); **Microsoft
> Learn** (app data locations, DLL search order, code signing, UAC); **David Beazley** (threads vs
> processes vs async — pick by what the work waits on); **Joe Armstrong** (supervision, "let it
> crash" — isolate the failing worker, restart it, never the whole app) with **Nygard** (bulkheads);
> **Kay Hayen** (Nuitka). shipright's lens: the same 5 boundaries — the window is just another handler.
>
> The general Python stack (errors, typing, security footguns) is `references/stacks/python.md` —
> load both. This file adds what is specific to a GUI process on Windows.

---

## Decision 0 — desktop at all? (judgment.md: the cheapest thing that works)

```
Needs local files / hardware / a local browser / to run while offline / per-machine state?  → desktop.
A form over a server-side database that many people share?                                   → a web app.
A script one person runs?                                                                    → a CLI. No GUI.
```
A desktop app costs signing, installers, updates and support for every Windows version it meets.
Pay that only when the machine is the point.

### Framework — pick a default, keep it at the edge
```
Default: PySide6 (Qt for Python, the official binding) — LGPLv3: closed-source commercial use is fine
         with dynamic linking. Widgets for data-heavy tools (tables, forms, admin); QML for fluid UI.
PyQt6 — same Qt, but GPLv3 or a paid commercial licence. For a closed-source product this is a
        ONE-WAY DOOR (a licence, not a library) — decide it on day one, not at release.
Tkinter / ttk — built in, fine for a small internal tool. Hits its ceiling fast on tables and theming.
pywebview / Flet — a web UI inside a native window; choose when the team is web-first.
```
Confine the framework to the UI layer. A service or repository that imports `PySide6` is a Boundary 2
violation — and it makes the core untestable without a display.

---

## The architecture — the 5 boundaries, desktop edition

```
ui/            Views + view-models (QWidget / QML). = the HANDLER: collect input → call a service →
               render the result. Zero business rules. Never touches the DB, the network, or a browser.
services/      Business rules (account lifecycle, scheduling, rate budgets). No Qt, no I/O imports.
repositories/  SQLite access, returns domain objects (Boundary 2b).
adapters/      Every external system: platform APIs, browser automation, OS APIs (Boundary 4).
workers/       Where long-running work runs — threads / processes / an asyncio loop. Supervised.
app.py         Composition root: build repositories → services → adapters → windows. Nothing else
               constructs anything.
```

**The rule that makes or breaks a Qt app — the GUI thread never waits.**
```
Only the GUI (main) thread may touch a QWidget / QObject that lives there. Never block it: anything
that can take > ~16 ms (a network call, a DB query that isn't trivial, a file scan, a browser action)
runs in a worker, and the result comes back through a SIGNAL (queued across threads automatically).
  ✗ button.clicked → requests.get(...)            → the window freezes; Windows marks it "Not Responding"
  ✓ button.clicked → service.start_job() → worker → finished.emit(result) → view updates
  ✗ a worker thread calling label.setText(...)     → undefined behaviour; crashes at random, later
  ✓ the worker emits a signal; the slot runs on the GUI thread
```
This is Boundary 5 applied *inside* the process: the GUI thread is an integration point with a human,
and its timeout is one frame.

### Pick the concurrency model by what the work WAITS on (Beazley)
```
I/O-bound, many concurrent operations (HTTP, browser automation)
  → asyncio. Run the loop on the Qt event loop (PySide6.QtAsyncio, or qasync) OR in one dedicated
    worker thread that talks to the UI only via signals. One loop, not one per account.
I/O-bound, a few blocking calls
  → QThreadPool + QRunnable (or the worker-object + QThread pattern). Never subclass QThread to
    do work in run() while also giving it slots — the classic Qt threading bug.
CPU-bound (image/video processing, parsing big files)
  → a process (ProcessPoolExecutor / multiprocessing). Threads won't help under the GIL.
Isolation matters (one account's crash must not take the others down)
  → a process per unit, supervised (see Resilience).
```
Free-threaded Python (3.14+, PEP 779) is officially supported but **not the default build**, and any C
extension that hasn't opted in silently re-enables the GIL. Don't design a Qt app around it until your
exact dependency set supports it — measure, don't assume.

---

## Data on the user's machine

```
Where                          What
%LOCALAPPDATA%\<Vendor>\<App>\  database, per-account profiles, caches, logs — per-user, not roaming
%APPDATA%\<Vendor>\<App>\       small user settings that should roam (QSettings is fine here)
Install dir (per-user:          code only — NEVER write here at runtime (it may be read-only / shared)
  %LOCALAPPDATA%\Programs\<App>)
```
Resolve these with `QStandardPaths` or the Known Folders API — never hard-code `C:\Users\...`.

**SQLite, correctly:** WAL mode (`PRAGMA journal_mode=WAL`), `busy_timeout`, short transactions,
**one writer**, and a connection per thread (never share a `sqlite3.Connection` across threads). Schema
migrations are versioned from the first release — the database outlives every version of the app that
created it (a one-way door: data identity and schema).

---

## Security — the user's machine is the trust boundary (see references/security.md)

```
Secrets at rest (passwords, OAuth refresh tokens, cookies, API keys)
  ✗ plaintext in SQLite / JSON / QSettings / .env next to the exe
  ✓ envelope encryption: a random data key encrypts the secrets (cryptography: AES-GCM / Fernet);
    the data key itself is protected by Windows DPAPI (CurrentUser scope) or stored via `keyring`
    (Windows Credential Manager — blobs are small, so store the KEY there, not the data).
  Be honest about what this buys: DPAPI stops other Windows users and a stolen disk. It does NOT stop
  malware running as the same user. Don't claim more than that.
  Browser profile directories contain live sessions — treat the whole folder as a secret.

Prefer tokens over passwords
  If the platform offers OAuth, store the refresh token, never the password. A password you don't hold
  can't leak.

Code integrity
  ✓ Sign the exe AND the installer (Azure Artifact Signing — formerly Trusted Signing — or an OV/EV
    certificate). Unsigned binaries get SmartScreen / Smart App Control warnings and AV suspicion.
  ✓ Updates are signed and VERIFIED before install — use a TUF-based updater (tufup). Never
    "download an exe from a URL and run it".
  ✓ Install per-user, run un-elevated. Asking for admin is almost never needed and widens every bug.
  ✓ DLL planting: don't load DLLs from the current directory or a user-writable path next to the exe.

Supply chain
  ✓ Pin with hashes (uv.lock / pip-compile --generate-hashes); pip-audit in CI; ship only what you use.

Logs
  ✓ Rotating file logs in %LOCALAPPDATA%\...\logs. Redact tokens, cookies, passwords, phone numbers
    before they reach the handler — a support bundle gets emailed around.

Local IPC / single-instance
  ✓ QLocalServer / named mutex for "one instance only"; treat anything received on it as untrusted input.
```

---

## Resilience — a desktop app runs for days (Nygard + Armstrong)

```
□ Every network / browser / API call has an explicit timeout (Boundary 5). Playwright's defaults are
  long — set them per context. A hung call must not wedge a worker forever.
□ Bulkhead per unit of work: one failing account/job never stalls the others. Separate queues, and a
  process boundary when a crash (not just an exception) is possible.
□ Supervise workers: on failure, restart with backoff + a cap; after N failures, STOP that unit and
  surface it to the user. Don't hammer.
□ Kill child processes with the parent. Browsers and helper processes orphaned by a crash keep running
  (and keep sessions open). Put them in a Windows Job Object with KILL_ON_JOB_CLOSE (pywin32).
□ Graceful shutdown on app.aboutToQuit: stop accepting work → signal workers → wait with a timeout →
  close browser contexts → flush and close the DB.
□ Crash capture: faulthandler to a file, sys.excepthook + threading.excepthook → log + a friendly
  dialog. A silent crash in a worker thread is the most common "it just stopped working".
□ Idempotent jobs: every side-effecting job has a key in SQLite, so a restart never repeats an action.
□ Steady state: caps on log size, cache size, open pages, retained history (resilience.md §8).
```

---

## Performance — measure first (references/performance.md), then these

```
Startup    python -X importtime shows what's slow. Import heavy modules lazily (after the first window
           paints). Nuitka standalone starts noticeably faster than a onefile bundle that unpacks.
Big lists  QAbstractTableModel + QTableView (virtualised — only visible rows render). Never
           QTableWidget with thousands of items.
UI updates Coalesce worker progress to a few updates per second, emit ranges (dataChanged) not
           per-row resets. A flood of signals freezes the GUI as surely as a blocking call.
Memory     Qt parent/child ownership frees widgets — keep references only where needed, disconnect
           long-lived signals, close pages/contexts you're done with. Watch RSS over a day (steady state).
Browsers   A browser PROCESS is the expensive unit; a CONTEXT inside it is cheap (isolated cookies/storage,
           milliseconds to create). Size concurrency from measured memory, cap it with a semaphore, and
           close idle sessions — never "one browser per account, all open, forever".
```

---

## Multi-account / multi-session apps (e.g. managing several social-media accounts from one PC)

### Decision 0 again — official API before automation (product-judgment.md §1: viability)
```
The platform has an official API for the job (e.g. TikTok for Developers — Content Posting API, Login
Kit; each account authorises the app via OAuth and gets its OWN tokens; there is no agency-wide token)
  → use it. Stable, permitted, rate limits are known, and it's a normal Adapter (Boundary 4 +
    third-party-apis.md Layer 1: call the real sandbox, save fixtures, then write the Adapter).
No API for the job
  → browser automation is a fallback, not a foundation: it breaks on every UI change and may violate the
    platform's terms. Raise it as a VIABILITY question before building on it — what happens to the
    product when the platform changes its page, or suspends the accounts?
```

### The domain model
```
Account (aggregate root)
  id: your own UUID — never the handle/username (they change; same rule as chatbot userId)
  handle, platform, owner note
  status: NEW → AUTHORISING → ACTIVE ⇄ PAUSED
                                ↓
                        NEEDS_ATTENTION   (login challenge, 2FA, verification, captcha, policy notice)
                                ↓
                             DISABLED
  credential_ref → the encrypted secret store (never inline)
  session_dir    → its own profile folder / storage-state file (isolation = no cross-account cookies)
  network        → optional per-account settings the USER supplies (e.g. a proxy they run for that
                   account's region) — configuration, not a feature shipright designs
  rate_budget    → actions per window, from the platform's published limits

Job — "post X to account A at T": state machine (QUEUED → RUNNING → DONE | FAILED | CANCELLED),
  idempotency key, attempts, last_error. Persisted in SQLite; the scheduler survives restarts.
```

**NEEDS_ATTENTION is a human-in-the-loop state, not an error to retry.** When the platform asks for
verification, the app stops that account, tells the user, and waits. Retrying a challenge is how
accounts get locked.

### Isolation and scheduling
```
□ One isolated session per account: a browser CONTEXT (with its saved storage state) or a persistent
  profile dir — never two accounts sharing cookies or storage.
□ A bounded pool of active sessions (semaphore) and a per-account rate budget paced to the platform's
  published limits. (Jitter on RETRY backoff is a resilience pattern — resilience.md. Randomising
  activity to look human is evasion, and out of scope — see below.)
□ Per-account bulkhead: one account's failure/challenge pauses that account only.
□ The UI never touches Playwright or an API client — it asks services, which ask adapters.
```

### What shipright will not build — and says so
Fingerprint spoofing / "anti-detect" browsers, CAPTCHA or verification bypass, evading bans or rate
limits, mass account creation, fake engagement. They break platform terms, invite legal exposure, and
are an arms race the product loses — every one is a viability failure (product-judgment.md §1), not an
engineering problem. When a request needs one of these, shipright states that plainly and offers the
permitted path (official API, human-in-the-loop verification, staying inside the published limits).

---

## Testing

```
□ Services and domain: plain pytest, no Qt, no display — the boundaries make this free.
□ UI: pytest-qt (qtbot) for the few flows that matter; assert through signals, not sleeps.
□ Adapters: fixtures from real responses (third-party-apis.md Layer 2); a scheduled contract test for
  platform APIs; for browser automation, a smoke test against the real page that is allowed to fail
  loudly — that failure is your early warning the page changed.
□ Test the FROZEN build, not just the source: CI builds the Nuitka/PyInstaller bundle on windows-latest
  and launches it with a --self-check flag. Missing hidden imports and data files only show up there.
□ Resilience: kill a worker / hang an adapter in a test — the rest of the app keeps running (resilience.md).
```

## Packaging & distribution

```
Build     Nuitka --standalone (a folder) for anything you distribute: compiled, faster start, far fewer
          antivirus false positives. PyInstaller --onedir is fine for internal tools.
          Avoid --onefile in either: it unpacks to %TEMP% at every launch — slow, and exactly what AV
          heuristics flag.
Installer Inno Setup or MSIX; per-user install, no admin; Start-menu shortcut; clean uninstall that
          leaves (or asks about) user data.
Sign      the exe, the DLLs you built, and the installer (Security above). SmartScreen reputation builds
          with signed downloads over time.
Update    signed + verified (tufup). Show what changed; never update mid-job.
Browsers  if you drive a browser, pin its version to your automation library's, install it into
          %LOCALAPPDATA% (PLAYWRIGHT_BROWSERS_PATH) on first run, and verify it before use.
```

---

## Add to CLAUDE.md

```markdown
## Desktop conventions (Windows, PySide6)
- The GUI thread never blocks: anything > ~16 ms runs in a worker; results return via signals.
  Workers never touch widgets.
- ui/ = handler layer only. Services and repositories never import PySide6.
- Paths via QStandardPaths: data/logs in %LOCALAPPDATA%\<Vendor>\<App>. Never write to the install dir.
- Secrets: envelope-encrypted, key protected by DPAPI / keyring. No plaintext secrets anywhere on disk.
- SQLite: WAL, one writer, connection per thread, versioned migrations.
- Every external call has a timeout; every side-effecting job has an idempotency key in SQLite.
- Child processes live in a Job Object (die with the app). Workers are supervised with capped restarts.
- Ship: Nuitka standalone, signed exe + installer, TUF-verified updates. CI tests the frozen build.
```

## Debt signals
```
- TODO[freeze>100ms]: profile the GUI thread — something blocking slipped onto it
- TODO[startup>3s]: python -X importtime → lazy-import the heaviest modules
- TODO[rss-grows-daily]: steady-state leak — pages/contexts/signals not released
- TODO[av-false-positive]: switch to Nuitka standalone + sign; submit the file to the AV vendor
- TODO[first-external-user]: code signing + signed auto-update before anyone outside the team installs it
- TODO[platform-page-changed]: automation adapter broke — check whether an official API now covers it
```

## Ubiquitous Language
Name windows and view-models after the job, not the widget: `AccountRoster`, `PublishQueue`,
`AttentionInbox` — not `MainWindow2`, `TableDialog`, `Manager`. Define the terms in CLAUDE.md before
building the first screen.
