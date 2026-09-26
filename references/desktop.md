# Desktop apps — judgment first, then the stack

> A desktop app is **a long-running process on a machine you don't control**: one thread that must never
> block, secrets that live on the user's disk, a binary the OS distrusts until it is signed, and an update
> channel that is the most dangerous code path you ship. Every section below follows from those facts.
>
> **Scope — modern Node.js / Python only.** shipright builds desktop apps the way today's flagship apps
> are built: **Electron + TypeScript** (VS Code, Claude desktop, Slack, Discord, Figma, Notion — all
> Chromium-based), with **Python** entering as PySide6 or as a sidecar process behind an Electron UI.
> Deliberately not covered: .NET (WPF/WinUI/Avalonia/MAUI), Qt C++, Flutter, Tauri (Rust core), Tkinter.
>
> Masters, by concern:
> - **Charles Petzold** (*Programming Windows*) — the message loop. Every UI stack, Chromium included, is
>   one thread pumping events; block it and the app is dead.
> - **The Chromium multi-process architecture** and **Erich Gamma** (VS Code's architecture — the
>   extension host runs out-of-process so an extension can't freeze the editor) — put untrusted or heavy
>   work in *another process*.
> - **Raymond Chen** (*The Old New Thing*) — how Windows actually behaves.
> - **John Gossman** (MVVM) and **Martin Fowler** (*Presentation Model*) — state and logic out of the view.
> - **The Electron security guide** and Doyensec's *Electronegativity* research — the threat model of a
>   web engine with native powers.
> - **Joe Armstrong** (supervision, "let it crash") with **Michael Nygard** (bulkheads, timeouts).
> - **Brendan Gregg** — performance is measured, never guessed.
> - **Microsoft Fluent / Windows app guidelines** and **Apple HIG** — conventions users already know.
> - **The Update Framework** (TUF, Justin Cappos) — updates that can't be hijacked.
>
> shipright's lens: the 5 boundaries hold unchanged — **the window is just another handler.**
> Stack mechanics: `references/stacks/electron.md` · `references/stacks/python-desktop.md`.

---

## 0. Desktop at all? (judgment.md — the cheapest thing that works)

```
The job needs the machine: local files/hardware, offline work, a local browser engine, per-machine state,
tight OS integration (tray, global shortcuts, file associations)                       → desktop.
Many people share one set of data through forms                                         → a web app.
One person runs it now and then                                                        → a CLI / script.
```
A desktop app costs signing certificates, installers, auto-update infrastructure, and support for every
OS version it meets. Pay that only when the machine is the point.

---

## 1. Choosing the shape — a one-way door, so decide it at L0 (ADR-001)

Changing the UI stack later is a rewrite. Decide once, with reasons. Three shapes cover everything
shipright builds:

| Shape | Pick when | Watch out for |
|---|---|---|
| **Electron + TypeScript** (React/Vite in the renderer) — **the default** | Almost always: a rich UI, embedded web content, cross-platform, the JS ecosystem. The stack VS Code and Claude desktop ship on. | Footprint (~100+ MB, Chromium per app). Security is *your* job — the §4 baseline is mandatory. |
| **Electron UI + Python sidecar** | The job needs Python's ecosystem (data, ML, scraping/automation libraries) but the UI should be modern web. Python runs as a supervised child process; Electron is the face. | Two runtimes to package and sign; the IPC between them is an interface contract (typed, validated, versioned). |
| **Python + PySide6 (Qt 6)** | Python-first team, a data-heavy native UI (big tables, forms, charts), no need for embedded web content. | Qt licence choice (PySide6 LGPL — fine; PyQt6 GPL/commercial); Python packaging and AV false positives — `stacks/python-desktop.md`. |

```
Default: Electron + TypeScript. Move off it only for a reason you can name:
  the core work is Python and belongs in-process with a native UI → PySide6
  the core work is Python but the UI should be web / embed web views → Electron + Python sidecar
```

### The fork that decides the shape for multi-account / multi-session apps — OPERATE or ACT?
```
OPERATE — a person uses N logged-in web sessions inside one window (a unified inbox, a tabbed
          workspace; think Ferdium/Rambox for many accounts).
          → Electron. Each account gets its own session partition (`persist:<accountId>`) shown in a
            WebContentsView — isolation of cookies and storage is built in. §10.
ACT     — the app does things on the accounts' behalf (schedule, publish, fetch analytics).
          → an official API if one exists (preferred), otherwise browser automation as a flagged fallback.
            Any of the three shapes works; choose by where the work's libraries live. §10.
Most real products are ACT with a small OPERATE surface (open an account's live view when needed).
```

---

## 2. Architecture — the 5 boundaries, desktop edition

```
view (renderer)     UI components. Render state, emit intents. No business rules, no Node/OS access.
view-models/stores  UI state + commands (MVVM / Presentation Model) — testable with no window.
                    = the HANDLER: take input → call a service (over IPC) → expose the result.
services            Business rules. No UI framework, no Electron/Qt imports, no raw I/O.
repositories        Local storage (SQLite) → typed domain objects.
adapters            Every external system: platform APIs, browser automation, OS APIs, the Python
                    sidecar, the network (Boundary 4).
workers             Long-running work in separate processes (utilityProcess / child process / a
                    Python sidecar). Supervised.
composition root    One place builds everything (Electron main / Python app startup).
```
In Electron the process split *is* the layering: renderer = view; preload = the one narrow bridge; main
= composition root + OS adapters; utility processes = workers. A renderer that reaches Node or the file
system directly is a Boundary 1 violation *and* a security hole.

### The UI-thread contract (Petzold) — the rule that decides whether the app feels broken
```
One thread owns the UI and pumps its events. It never waits: anything that can take more than a frame
(~16 ms) — network, disk, a query, parsing, a browser action — runs elsewhere, and the result comes
back as a message.
  Electron — BOTH the renderer and the MAIN process must stay unblocked: a blocked main process freezes
             every window. Never use sendSync / synchronous fs in main; heavy work → utilityProcess.
  PySide6  — only the GUI thread touches widgets; workers report back through signals.
```
This is Boundary 5 inside the process: the UI thread is an integration point with a human, and its
timeout is one frame.

### The process model (Chromium, Gamma) — isolate what can crash, hang or be hostile
```
UI process(es)      the window and view-models.
Worker processes    anything that can hang, crash or run untrusted content: browser automation,
                    per-account sessions when isolation matters, heavy CPU, the Python sidecar.
Between them        a typed, validated message protocol. IPC is an interface contract, and every message
                    from a less-trusted process is untrusted input.
```
Pick concurrency by what the work waits on: many I/O waits → async; CPU-bound or must-survive-a-crash →
a process.

---

## 3. Data and state on the user's machine

```
Per-user data (DB, caches, logs, sessions)  Electron app.getPath('userData') · Qt QStandardPaths
  → Windows %LOCALAPPDATA% / %APPDATA%\<App>, macOS ~/Library/Application Support/<App>
The install directory                        code only — never written to at runtime
```
- **SQLite** is the default local database (Node: better-sqlite3 in main or a utility process; Python:
  sqlite3). WAL mode, a busy timeout, short transactions, one writer.
- **Schema migrations are versioned from release one** — the data outlives every app version that wrote
  it. Data identity and schema are one-way doors.
- **Settings ≠ secrets.** Preferences in a settings store; anything that grants access in §4's secret store.
- **Window state persists** (size, position, panes, last view).

---

## 4. Security — the trust boundary is the user's PC (references/security.md)

```
Secrets at rest (passwords, OAuth refresh tokens, cookies, API keys)
  ✗ plaintext in the DB, a JSON settings file, electron-store, or a .env next to the binary
  ✓ the OS secret store — Electron safeStorage (DPAPI / Keychain / libsecret) · Python keyring — holding
    the data or a KEY that encrypts larger data (envelope encryption, AES-GCM).
  Say honestly what this buys: it stops other OS users and a stolen disk. It does NOT stop malware running
  as the same user.
  Prefer OAuth tokens over passwords — a password you never hold can't leak.
  Session partitions / browser profiles hold live logins — protect them like secrets.

The Electron baseline (non-negotiable — modern Electron defaults most of it; never turn it off)
  nodeIntegration:false · contextIsolation:true · sandbox:true · webSecurity:true
  a small, task-shaped API exposed from preload via contextBridge — never ipcRenderer itself
  every IPC request validated in main (sender + arguments) · a strict Content-Security-Policy
  never load remote content into a privileged window; external sites go in their own sessions with no
    preload; block unexpected navigation and window.open
  Fuses at package time: EnableEmbeddedAsarIntegrityValidation + OnlyLoadAppFromAsar, disable RunAsNode
    and NODE_OPTIONS — so a tampered bundle won't run and the binary can't be used as a Node launcher.

Inputs that don't look like inputs
  Deep links / custom protocols, file associations, drag-and-drop, the clipboard, command-line
  arguments, messages from the Python sidecar — all untrusted. Validate at the boundary.

Code integrity
  ✓ Sign every binary and the installer — Windows: Azure Artifact Signing (formerly Trusted Signing) or
    an OV/EV certificate; macOS: Developer ID + notarization + hardened runtime.
  ✓ Updates signed and VERIFIED before they run. "Download an exe and run it" is an RCE feature.
  ✓ Per-user install, un-elevated. Never load libraries from the current or a user-writable directory.

Supply chain · Logs
  ✓ Lockfiles (package-lock / uv.lock with hashes), npm audit / pip-audit in CI, ship only what you use.
  ✓ Redact tokens, cookies, passwords and personal data BEFORE logging.
```

---

## 5. Resilience — a desktop app runs for days (Armstrong + Nygard)

```
□ Every network / browser / API call has an explicit timeout (Boundary 5).
□ Bulkheads: one failing account, job or plugin never stalls the others — separate queues, and a process
  boundary where a crash (not just an exception) is possible.
□ Supervise workers and the Python sidecar: restart with backoff and a cap; after N failures STOP that
  unit and tell the user.
□ Children die with the parent — Windows Job Objects (kill-on-close); elsewhere watch the parent and
  exit. Orphaned browsers keep sessions open and memory used.
□ Graceful shutdown: stop taking work → signal workers → wait with a timeout → close sessions → flush data.
□ Crash reporting: Electron crashReporter (Crashpad) / Sentry, personal data scrubbed; handle
  render-process-gone and child-process-gone; catch unhandled rejections in every process.
□ Idempotent jobs: a key in the local DB so a restart never repeats a side effect.
□ Single instance (app.requestSingleInstanceLock / QLockFile) — two copies writing one DB corrupt it.
□ Steady state: caps on logs, caches, open sessions, retained history. Could it run a week untouched?
```

---

## 6. Performance — measure first (Gregg; references/performance.md)

```
Budgets:
  cold start to first usable window   — ~1–2 s
  UI thread (renderer AND main)       — no task over ~16 ms; zero freezes over 100 ms
  idle memory / idle CPU              — know your floor; ~0 % CPU when idle (no polling, no hidden animations)
Techniques:
  load modules lazily in main (the Electron performance guide's first rule) · bundle the renderer
  (Vite) · virtualised lists/tables · coalesce background updates to a few per second · throttle hidden
  windows · close sessions, views and handles you're done with.
  Sessions are the expensive unit: every live WebContentsView / browser context costs memory. Keep a
  bounded number alive, HIBERNATE the rest (destroy the view, keep the partition on disk — the login
  survives), and size the cap from measured memory.
```

---

## 7. Packaging, signing, updates — the release pipeline IS part of the product

| Shape | Package / install | Update |
|---|---|---|
| Electron | Electron Forge (the Electron team's recommended toolchain) or electron-builder; fuses plugin on | update.electronjs.org (open source) or electron-updater — signed builds only |
| Electron + Python sidecar | as Electron, with the sidecar frozen by Nuitka `--standalone` and shipped as an extra resource | one update ships both — never let them drift apart |
| Python + PySide6 | Nuitka `--standalone` + Inno Setup / MSIX (`stacks/python-desktop.md`) | tufup (TUF) |

```
□ Per-user install, no admin. Clean uninstall that asks before deleting user data.
□ Sign binaries AND installer; notarize on macOS.
□ Auto-update: signed, verified, never mid-task, a visible changelog, a rollback path.
□ CI builds the SHIPPED artifact on the target OS and launches it (--self-check): missing native modules,
  assets and the sidecar only fail in the packaged build.
□ Native Node modules (better-sqlite3 …) are rebuilt for Electron's ABI — the packager must do this.
```

---

## 8. The experience floor, desktop edition (references/ui-design.md + Fluent / HIG)

```
□ Fully keyboard-operable: tab order, visible focus, standard shortcuts (Ctrl+S, Ctrl+F, Esc), a real menu.
□ Accessible names on every control (Narrator / VoiceOver read the accessibility tree Chromium or Qt builds).
□ Crisp at 150–200 % scaling; follows OS light/dark/high-contrast.
□ Native conventions: a tray icon only if it earns its place; quitting really quits.
□ State floor: long actions show progress and can be cancelled; empty, error and offline states are
  designed; the window never freezes.
□ Notifications respect OS settings and are never the only place a failure is reported.
```

---

## 9. Stack mechanics
`references/stacks/electron.md` — main/preload/renderer, typed IPC, utilityProcess, sessions and
WebContentsView, safeStorage, native modules, Forge/fuses, signing, updates, Playwright tests.
`references/stacks/python-desktop.md` — PySide6, the Qt threading contract, asyncio, Nuitka, tufup,
and running Python as a sidecar behind Electron.

---

## 10. Multi-account / multi-session apps (e.g. managing 10–100 social-media accounts from one PC)

### ACT through the official API before anything else (product-judgment.md §1: viability)
```
The platform has an official API for the job (e.g. TikTok for Developers — Content Posting API, Login
Kit; each account authorises the app via OAuth and gets its OWN tokens; there is no agency-wide token)
  → use it. Stable, permitted, known rate limits, a normal Adapter (Boundary 4 + third-party-apis.md
    Layer 1). 100 accounts over an API is light: no browsers at all.
No API for the job
  → browser automation is a fallback, not a foundation: it breaks on every page change and may violate
    the platform's terms. Raise it as a VIABILITY question before building on it.
```

### OPERATE — N live sessions in one window (Electron)
```
□ One partition per account: session.fromPartition('persist:' + accountId) — its own cookies, storage,
  cache. Never share a partition between accounts.
□ Show each in a WebContentsView (BrowserView is deprecated). No preload, no Node, sandboxed — it's a
  third-party site with a live login.
□ Bounded live views + hibernation: only the visible and recently used sessions keep a view; the rest are
  destroyed and restored on demand from their persistent partition. 100 live Chromium views is not a plan.
□ The app's own UI never trusts anything from these views.
```

### The domain model
```
Account (aggregate root)
  id: your own UUID — never the handle (it changes; the same rule as a chatbot's userId)
  handle, platform, owner note
  status: NEW → AUTHORISING → ACTIVE ⇄ PAUSED
                                ↓
                        NEEDS_ATTENTION   (login challenge, 2FA, verification, captcha, policy notice)
                                ↓
                             DISABLED
  credential_ref → the OS secret store (§4), never inline
  session        → its own partition / browser context — no two accounts share cookies or storage
  network        → optional per-account settings the USER supplies (e.g. their own regional proxy) —
                   configuration, not a feature shipright designs
  rate_budget    → actions per window, from the platform's published limits

Job — "publish X to account A at time T": QUEUED → RUNNING → DONE | FAILED | CANCELLED, with an idempotency
key and attempt count, persisted locally so the schedule survives restarts.
```
**NEEDS_ATTENTION is a human-in-the-loop state, not an error to retry.** When the platform asks for
verification, the app stops that account, tells the person, and — in an OPERATE app — opens that
account's view so they can resolve it themselves. Retrying a challenge is how accounts get locked.

### Isolation and scheduling
```
□ A bounded pool of active sessions/contexts, sized from measured memory.
□ Per-account rate budgets paced to the platform's published limits. (Jitter on RETRY backoff is a
  resilience pattern. Randomising activity to look human is evasion — out of scope, below.)
□ Per-account bulkhead: one account's failure or challenge pauses that account only.
□ The renderer never touches the automation engine or API client — it asks services over IPC.
```

### What shipright will not build — and says so
Fingerprint spoofing / "anti-detect" browsers, captcha or verification bypass, evading bans or rate
limits, mass account creation, fake engagement. They break platform terms, invite legal exposure, and are
an arms race the product loses — each is a viability failure (product-judgment.md §1), not an engineering
problem. shipright says so plainly and offers the permitted path: the official API, human-in-the-loop
verification, staying inside published limits.

---

## 11. Testing

```
□ Services and domain: plain unit tests (Vitest / pytest) — no window, no Electron.
□ View-models / stores: tested without a window.
□ End-to-end: Playwright drives Electron (_electron.launch) and asserts on state, never on sleeps;
  pytest-qt for PySide6.
□ Adapters: fixtures from real responses; a scheduled contract test for platform APIs; for automation,
  a smoke test against the real page that fails loudly when the page changes.
□ The SHIPPED artifact: CI installs and launches the packaged, signed build on the target OS.
□ Resilience: kill a worker / the sidecar / hang an adapter in a test — the rest keeps working.
```

---

## Add to CLAUDE.md

```markdown
## Desktop conventions
- Shape: [Electron+TS | Electron + Python sidecar | PySide6] because [reason] — ADR-001. A rewrite to change.
- The UI thread never blocks — renderer AND main (Electron) / GUI thread (Qt). > ~16 ms → a worker.
- Renderer = view only: no Node, no fs. The preload exposes a small typed API; main validates every IPC call.
- Hang-prone or untrusted work (automation, per-account sessions, the Python sidecar) runs in supervised
  processes that die with the app.
- Data under userData via the OS API; SQLite WAL, versioned migrations. Never write to the install dir.
- Secrets only via safeStorage / keyring. Nothing sensitive in settings or logs.
- Every external call has a timeout; every side-effecting job has an idempotency key.
- Release: signed binaries + installer, fuses on, verified auto-update; CI launches the packaged build.
```

## Debt signals
```
- TODO[freeze>100ms]: profile the UI thread (renderer/main) — blocking work slipped onto it
- TODO[cold-start>2s]: lazy-load main-process modules; measure the startup path
- TODO[rss-grows-daily]: steady-state leak — sessions, views, handles, listeners not released
- TODO[live-sessions>N]: hibernate idle account views
- TODO[first-external-user]: code signing + signed auto-update before anyone outside the team installs it
- TODO[platform-page-changed]: automation adapter broke — check whether an official API now covers it
```

## Ubiquitous Language
Name windows and view-models after the job, not the widget: `AccountRoster`, `PublishQueue`,
`AttentionInbox` — not `MainWindow2`, `GridForm`, `Manager`. Define the terms in CLAUDE.md before the
first screen exists.
