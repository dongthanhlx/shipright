# Desktop apps — judgment first, then the stack

> A desktop app is **a long-running process on a machine you don't control**: one thread that must never
> block, secrets that live on the user's disk, a binary the OS distrusts until it is signed, and an update
> channel that is the most dangerous code path you ship. Every section below follows from those facts —
> in any language. The stack decides the mechanics; it doesn't change the rules.
>
> Masters, by concern:
> - **Charles Petzold** (*Programming Windows*) — the message loop. Every UI framework since (Win32, WPF,
>   WinUI, Qt, Cocoa, Chromium) is one thread pumping events; block it and the app is dead.
> - **Raymond Chen** (*The Old New Thing*) — how Windows actually behaves, and why "clever" apps break.
> - **John Gossman** (MVVM) and **Martin Fowler** (*Presentation Model*) — keep state and logic out of the
>   view so it can be tested without a window.
> - **Erich Gamma** (VS Code's architecture) and the **Chromium multi-process design** — put untrusted or
>   heavy work in *another process*, so it can crash or hang without taking the window with it.
> - **Joe Armstrong** (supervision, "let it crash") with **Michael Nygard** (bulkheads, timeouts).
> - **Brendan Gregg** — performance is measured, never guessed.
> - **Microsoft Fluent / Windows app guidelines** and **Apple HIG** — native conventions users already know.
> - **Electron's security guide** (and Doyensec's *Electronegativity* research) and **Tauri's capability
>   model** — the threat model of a web engine with native powers.
> - **The Update Framework** (TUF, Justin Cappos) — how to ship updates that can't be hijacked.
>
> shipright's lens: the 5 boundaries hold unchanged — **the window is just another handler.**
> Stack mechanics: `references/stacks/python-desktop.md` for Python; the other stacks are in §9.

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

## 1. Choosing the technology — a one-way door, so decide it at L0

Switching UI stacks later is a rewrite, not a refactor. Decide once, with reasons, and record the ADR.
**The strongest factor is the team's existing language** — a stack the team knows beats a better
benchmark in a stack it doesn't. Then narrow by target OS, the kind of UI, and footprint.

| Stack | Pick when | Watch out for |
|---|---|---|
| **.NET — WPF** | Windows-only business/data app, .NET team, long life. Mature, open source, current .NET. | Windows only. Older visual style unless themed. |
| **.NET — WinUI 3** (Windows App SDK) | Windows-only, want the modern Fluent look and new Windows APIs. | Younger than WPF; check the specific controls you need exist. |
| **.NET — Avalonia** | Cross-platform (Win/macOS/Linux) with a WPF-like XAML model. | Smaller ecosystem than WPF. |
| **Tauri 2** (Rust core + OS webview) | Web-skilled team, small installer, strict least-privilege by default (capabilities). | Renders in the OS webview (WebView2 / WebKit) — small cross-OS differences; the Rust side needs Rust skills. Its RAM advantage is smaller than the marketing — measure. |
| **Electron** (Chromium + Node) | Web team, needs identical rendering everywhere, or a huge JS ecosystem. VS Code, Slack. | Largest footprint (~100+ MB installer, heavy RAM). Security is *your* job — §4. |
| **Qt — C++ or Python (PySide6)** | Native performance, complex widgets, data-heavy tools; Python when the job leans on its ecosystem (data, ML, automation). | Licence: LGPL vs commercial (PyQt: GPL). Python adds packaging work — `stacks/python-desktop.md`. |
| **Flutter** | There is (or will be) a Flutter mobile app sharing the UI. | Fewer mature Windows plugins than mobile. |
| **.NET MAUI** | Mobile-first app that also needs a desktop build. | Desktop is not its strongest target — prefer WPF/WinUI/Avalonia for desktop-first. |

```
Defaults when the constraints don't decide it:
  Windows-only business tool, .NET team      → WPF (or WinUI 3 for the modern look)
  Cross-platform, web team, footprint matters → Tauri 2
  Cross-platform, must render identically     → Electron (and pay the §4 security tax)
  Python-heavy job (data, automation, ML)     → PySide6
  Shares code with a Flutter mobile app       → Flutter
```
Libraries you need are part of the decision. Example: browser automation (Playwright) exists for
Node, Python, .NET and Java — so it constrains nothing; a Python-only ML library does.

---

## 2. Architecture — the 5 boundaries, desktop edition

```
view/          Windows, pages, controls. Bind to a view-model; no logic beyond layout and binding.
view-models/   UI state + commands (MVVM / Presentation Model). Testable with no window. = the HANDLER:
               take input → call a service → expose the result. Zero business rules.
services/      Business rules. No UI framework imports, no I/O imports.
repositories/  Local storage (SQLite etc.) → typed domain objects.
adapters/      Every external system: platform APIs, browser engines, OS APIs, the network (Boundary 4).
workers/       Long-running work — threads, async tasks, or separate processes. Supervised.
composition    One place builds everything and wires it (app startup). Nothing else constructs services.
```
A service that imports the UI framework is a Boundary 2 violation — and it means the core can only be
tested with a window open.

### The UI-thread contract (Petzold) — the rule that decides whether the app feels broken
```
One thread owns the UI and pumps its events. It must never wait: anything that can take more than a
frame (~16 ms) — network, disk, a query, a browser action, parsing — runs elsewhere, and the result
comes back through the framework's marshalling (a signal, the Dispatcher, a message, an event).
Workers never touch UI objects directly.

  WPF: Dispatcher · WinUI: DispatcherQueue · Qt: signals/slots across threads · Electron: the main
  process AND each renderer must stay unblocked (a blocked main process freezes every window) ·
  Tauri: async commands on the Rust side · Flutter: isolates for heavy work.
```
This is Boundary 5 inside the process: the UI thread is an integration point with a human, and its
timeout is one frame. Windows labels a window "Not Responding" after a few seconds of this.

### The process model (Gamma, Chromium) — isolate what can crash, hang or be hostile
```
In the UI process          : the UI, view-models, light services.
In a worker process         : anything that can hang, crash, or run untrusted content — browser engines,
                              plugins/extensions, heavy CPU work, one unit per account when isolation
                              matters. VS Code runs extensions in a separate host for exactly this reason:
                              an extension can misbehave without freezing the editor.
Between them                : a typed, validated message protocol (IPC is an interface contract, and
                              every message from a less-trusted process is untrusted input).
```
Pick concurrency by what the work waits on: many I/O waits → async; a few blocking calls → a thread
pool; CPU-bound or must-survive-a-crash → a process.

---

## 3. Data and state on the user's machine

```
Per-user, per-machine data (DB, caches, logs, profiles)  Windows %LOCALAPPDATA%\<Vendor>\<App>
                                                          macOS   ~/Library/Application Support/<App>
                                                          Linux   $XDG_DATA_HOME/<app>
Small roaming settings                                     Windows %APPDATA% · the framework's settings API
The install directory                                      code only — never written to at runtime
```
Resolve these through the framework/OS API, never hard-coded paths.

- **SQLite** is the default local database: WAL mode, a busy timeout, short transactions, one writer.
- **Schema migrations are versioned from release one.** The data outlives every version of the app that
  wrote it — data identity and schema are one-way doors.
- **Settings ≠ secrets.** Preferences go in settings; anything that grants access goes in §4's secret store.
- **Window state persists** (size, position, split panes, last view) — users notice when it doesn't.

---

## 4. Security — the trust boundary is the user's PC (references/security.md)

```
Secrets at rest (passwords, OAuth refresh tokens, cookies, API keys)
  ✗ plaintext in the DB, a JSON/INI file, the settings store, or a .env next to the binary
  ✓ the OS secret store — Windows DPAPI / Credential Manager · macOS Keychain · Linux Secret Service —
    holding a KEY; larger data is encrypted with that key (envelope encryption, AES-GCM).
  Say honestly what this buys: it stops other OS users and a stolen disk. It does NOT stop malware
  running as the same user. Don't promise more.
  Prefer OAuth tokens over passwords — a password you never hold can't leak.
  A browser profile folder holds live sessions — protect it like a secret.

Web engine inside a native app (Electron / Tauri / WebView2 / any embedded browser)
  Electron baseline — nodeIntegration:false · contextIsolation:true · sandbox:true · webSecurity:true ·
    a narrow task-shaped API exposed from the preload via contextBridge · every IPC request validated in
    the main process · a strict Content-Security-Policy · never load remote content into a privileged
    window · block navigation and new windows you didn't intend.
  Tauri — grant the smallest capability set per window; every command validates its arguments.
  Anything rendered from the network is untrusted — show it in an unprivileged view, never with native powers.

Inputs that don't look like inputs
  Deep links / custom protocol handlers, file associations, drag-and-drop, the clipboard, command-line
  arguments, IPC from other processes — all untrusted. Validate at the boundary (Boundary 4 / A05).

Code integrity
  ✓ Sign every binary and the installer — Windows: Azure Artifact Signing (formerly Trusted Signing) or an
    OV/EV certificate; macOS: Developer ID + notarization + hardened runtime. Unsigned = SmartScreen /
    Gatekeeper warnings and antivirus suspicion.
  ✓ Updates are signed and VERIFIED before they run (TUF-based tooling, or the framework updater with
    signature checks on). "Download an exe and run it" is a remote-code-execution feature.
  ✓ Install per-user and run un-elevated. Admin rights are almost never needed and widen every bug.
  ✓ Windows DLL planting: never load libraries from the current or a user-writable directory.

Supply chain · Logs
  ✓ Lockfiles with hashes, a dependency audit in CI, ship only what you use.
  ✓ Redact tokens, cookies, passwords and personal data BEFORE logging — support bundles get emailed.
```

---

## 5. Resilience — a desktop app runs for days (Armstrong + Nygard)

```
□ Every network / browser / API call has an explicit timeout (Boundary 5).
□ Bulkheads: one failing account, job or plugin never stalls the others — separate queues, and a
  process boundary where a crash (not just an exception) is possible.
□ Supervise workers: restart with backoff and a cap; after N failures STOP that unit and tell the user.
□ Child processes die with the parent — Windows Job Objects (kill-on-close); on macOS/Linux, watch the
  parent and exit. Orphaned browsers keep sessions open and memory used.
□ Graceful shutdown: stop taking work → signal workers → wait with a timeout → close sessions → flush data.
□ Crash reporting: capture native and managed crashes (Crashpad / Sentry / the platform's reporter) with
  personal data scrubbed, and catch unhandled errors on worker threads — a silent worker death is the
  classic "it just stopped working".
□ Idempotent jobs: a key in the local DB so a restart never repeats a side effect.
□ Single instance where it matters (a named mutex / local socket) — two copies writing one DB corrupt it.
□ Steady state: caps on logs, caches, open sessions and history (resilience.md §8). Test: could it run
  for a week untouched?
```

---

## 6. Performance — measure first (Gregg; references/performance.md)

```
Budgets (set them, then measure against them):
  cold start to first usable window    — target ~1–2 s
  UI thread                            — no task over ~16 ms; zero freezes over 100 ms
  idle memory                          — know your stack's floor and track growth per day
  idle CPU                             — ~0 %: no polling timers, no animations in hidden windows
Techniques:
  lazy-load modules and screens after the first window paints · virtualised lists/tables (only
  visible rows render) · coalesce background updates to a few per second · batch model changes ·
  throttle work in hidden/minimised windows (battery) · release sessions, pages and handles you're done
  with · a browser PROCESS is expensive, a browser CONTEXT is cheap — size concurrency from measured
  memory and cap it.
```

---

## 7. Packaging, signing, updates — the release pipeline IS part of the product

| Stack | Package / install | Update |
|---|---|---|
| .NET (WPF / WinUI / Avalonia) | MSIX, or Velopack / Inno Setup | MSIX App Installer, or Velopack (delta updates) |
| Tauri | built-in bundler (MSI / NSIS, DMG, AppImage) | Tauri updater plugin — signed updates |
| Electron | electron-builder / Electron Forge | electron-updater / Squirrel — signed builds |
| Qt C++ | windeployqt + an installer (Inno / Qt Installer Framework) | Velopack or your own TUF-verified channel |
| Python | `stacks/python-desktop.md` (Nuitka standalone) | tufup (TUF) |
| Flutter | msix package / Inno Setup | platform-appropriate updater, signed |

```
□ Per-user install, no admin. Clean uninstall that asks before deleting user data.
□ Sign binaries AND installer; notarize on macOS.
□ Auto-update: signed, verified, never mid-task, with a visible changelog and a rollback path.
□ CI builds the SHIPPED artifact on the target OS and launches it (a --self-check flag): missing native
  dependencies, assets and runtime components only exist in the packaged build.
□ Pin bundled engines (a browser build, a webview runtime requirement) to the versions you tested.
```

---

## 8. The experience floor, desktop edition (references/ui-design.md + Fluent / HIG)

```
□ Fully keyboard-operable: logical tab order, visible focus, standard shortcuts (Ctrl+S, Ctrl+F, Esc).
□ Accessible names on every control — Windows UI Automation (Narrator) and macOS VoiceOver read them.
□ Crisp at 150–200 % scaling (high-DPI aware), readable in the OS dark/light/high-contrast themes.
□ Native conventions: menus and shortcuts where users expect them; a tray icon only if it earns its place,
  and quitting really quits.
□ State floor: every long action shows progress and can be cancelled; empty, error and offline states are
  designed; the window never freezes (the desktop's missing loading state is a hang).
□ Notifications respect the OS settings and are never the only place a failure is reported.
```

---

## 9. Stack mechanics — where the rules land in each runtime

```
.NET        async/await + the Dispatcher for UI marshalling; CommunityToolkit.Mvvm for view-models;
            DI via Microsoft.Extensions.Hosting as the composition root; EF Core or Dapper + SQLite;
            ProtectedData (DPAPI) / Credential Manager for secrets; xUnit for services, UI tests on
            view-models (no window needed).
Tauri       Rust commands are the adapter/service boundary — the web UI never gets raw OS access;
            capabilities per window; state in Rust managed state + SQLite (plugin); secrets via the
            OS keyring crate; updater plugin with signing keys.
Electron    main process = composition root + adapters; preload = the only bridge (contextBridge, a
            small typed API); renderer = view. Heavy or risky work in a utilityProcess, not the main
            process. safeStorage for secrets (OS-backed). Follow the Electron security checklist.
Qt C++      the same threading contract as PySide (QThread worker-object, signals); QtKeychain for
            secrets; Qt Test.
Python      references/stacks/python-desktop.md (GIL/free-threading, asyncio integration, Nuitka).
Flutter     isolates for heavy work; platform channels are the adapter boundary; flutter_secure_storage.
```
A stack not listed: map it onto the same questions — what owns the UI thread, where is the process
boundary, which OS secret store, how is it signed and updated, how is the shipped artifact tested.

---

## 10. Multi-account / multi-session apps (e.g. managing several social-media accounts from one PC)

### Official API before automation (product-judgment.md §1: viability)
```
The platform has an official API for the job (e.g. TikTok for Developers — Content Posting API, Login
Kit; each account authorises the app via OAuth and gets its OWN tokens; there is no agency-wide token)
  → use it. Stable, permitted, known rate limits, and a normal Adapter (Boundary 4 + third-party-apis.md
    Layer 1: call the real sandbox, save fixtures, then write the Adapter).
No API for the job
  → browser automation is a fallback, not a foundation: it breaks on every page change and may violate
    the platform's terms. Raise it as a VIABILITY question before building on it — what happens to the
    product when the page changes, or the accounts are suspended?
```

### The domain model
```
Account (aggregate root)
  id: your own UUID — never the handle/username (they change; the same rule as a chatbot's userId)
  handle, platform, owner note
  status: NEW → AUTHORISING → ACTIVE ⇄ PAUSED
                                ↓
                        NEEDS_ATTENTION   (login challenge, 2FA, verification, captcha, policy notice)
                                ↓
                             DISABLED
  credential_ref → the OS secret store (§4), never inline
  session        → its own isolated browser context / profile — no two accounts share cookies or storage
  network        → optional per-account settings the USER supplies (e.g. their own regional proxy) —
                   configuration, not a feature shipright designs
  rate_budget    → actions per window, from the platform's published limits

Job — "publish X to account A at time T": QUEUED → RUNNING → DONE | FAILED | CANCELLED, with an
idempotency key and attempt count, persisted locally so the schedule survives restarts.
```
**NEEDS_ATTENTION is a human-in-the-loop state, not an error to retry.** When the platform asks for
verification, the app stops that account, tells the person, and waits. Retrying a challenge is how
accounts get locked.

### Isolation and scheduling
```
□ One isolated session per account; a bounded pool of active sessions (sized from measured memory).
□ Per-account rate budgets paced to the platform's published limits. (Jitter on RETRY backoff is a
  resilience pattern. Randomising activity to look human is evasion — out of scope, below.)
□ Per-account bulkhead: one account's failure or challenge pauses that account only.
□ The view never touches the automation engine or API client — view-models ask services, services ask adapters.
```

### What shipright will not build — and says so
Fingerprint spoofing / "anti-detect" browsers, captcha or verification bypass, evading bans or rate
limits, mass account creation, fake engagement. They break platform terms, invite legal exposure, and are
an arms race the product loses — each is a viability failure (product-judgment.md §1), not an engineering
problem. When a request needs one, shipright says so plainly and offers the permitted path: the official
API, human-in-the-loop verification, staying inside published limits.

---

## 11. Testing

```
□ Services and domain: plain unit tests, no UI framework — the boundaries make this free.
□ View-models: tested without a window (that is what MVVM is for).
□ A few end-to-end UI flows with the stack's driver (WinAppDriver/UIA, Playwright for Electron/Tauri,
  pytest-qt, Flutter integration tests) — assert on state, never on sleeps.
□ Adapters: fixtures from real responses; a scheduled contract test for platform APIs; for automation,
  a smoke test against the real page that fails loudly when the page changes.
□ The SHIPPED artifact: CI installs and launches the packaged, signed build on the target OS.
□ Resilience: kill a worker / hang an adapter in a test — the rest of the app keeps working.
```

---

## Add to CLAUDE.md

```markdown
## Desktop conventions
- Stack: [chosen] because [team skill / target OS / footprint] — ADR-001. Changing it is a rewrite.
- The UI thread never blocks: > ~16 ms goes to a worker; results return via [Dispatcher/signals/IPC].
  Workers never touch UI objects.
- view-models = handler layer. Services/repositories never import the UI framework.
- Hang-prone or untrusted work (browser engines, plugins, per-account sessions) runs in supervised
  worker processes; IPC messages are validated.
- Data under the per-user app-data dir via the OS API; never the install dir. SQLite WAL, versioned migrations.
- Secrets only in the OS secret store (envelope-encrypted). Nothing sensitive in settings or logs.
- Every external call has a timeout; every side-effecting job has an idempotency key.
- Release: signed binaries + installer, verified auto-update, per-user install; CI launches the packaged build.
```

## Debt signals
```
- TODO[freeze>100ms]: profile the UI thread — blocking work slipped onto it
- TODO[cold-start>2s]: lazy-load modules/screens; measure the startup path
- TODO[rss-grows-daily]: steady-state leak — sessions, pages, handles, listeners not released
- TODO[first-external-user]: code signing + signed auto-update before anyone outside the team installs it
- TODO[av-false-positive]: sign; avoid self-extracting packaging; report the file to the AV vendor
- TODO[platform-page-changed]: automation adapter broke — check whether an official API now covers it
```

## Ubiquitous Language
Name windows and view-models after the job, not the widget: `AccountRoster`, `PublishQueue`,
`AttentionInbox` — not `MainWindow2`, `GridForm`, `Manager`. Define the terms in CLAUDE.md before the
first screen exists.
