# Stack Reference: Electron + TypeScript (the default desktop shape)

> **Read `references/desktop.md` first** — it owns the rules (shape choice, the UI-thread contract, the
> process model, secrets, signing, updates, resilience, multi-account apps). This file is where they land
> in Electron. Plus `references/stacks/nodejs.md` for the language.
>
> Masters for this stack: **the Electron docs** (Security, Performance, Process Model — written by the
> people who maintain it); **the VS Code architecture** (Erich Gamma's team — out-of-process extension
> host, a small typed IPC surface, lazy loading at scale); **Doyensec / Electronegativity** (how Electron
> apps actually get exploited); **the Chromium process model** underneath all of it.

---

## Mapping: generic → Electron specific
```
composition root     main process (src/main) — builds services, adapters, windows
handler / view       renderer (src/renderer) — React + TypeScript, bundled by Vite
the bridge           preload (src/preload) — contextBridge.exposeInMainWorld('api', {...}) ONLY
workers              utilityProcess.fork() — Node in its own process (SQLite server, automation, CPU work)
IPC                  ipcMain.handle / ipcRenderer.invoke — async request/response; never sendSync
per-account sessions session.fromPartition('persist:<accountId>') + WebContentsView
secrets              safeStorage (DPAPI / Keychain / libsecret)
local DB             better-sqlite3 (native module — rebuilt for Electron) in main or a utility process
validation           zod at every IPC handler
tooling              electron-vite (or Forge's Vite template) · Electron Forge / electron-builder
tests                Vitest (services) · Playwright _electron (end-to-end)
```

## Project layout
```
src/
  main/
    index.ts             app lifecycle, single-instance lock, window creation, composition
    ipc/                 one file per domain: registers handlers, validates with zod, calls services
    services/            business rules — no electron imports (testable in plain Vitest)
    repositories/        better-sqlite3 access → domain objects
    adapters/            platform API clients, automation driver, OS integrations
    workers/             utilityProcess entry points + a supervisor
  preload/
    index.ts             contextBridge — a small, typed, task-shaped API (accounts.list(), jobs.enqueue(...))
  renderer/              React app — talks ONLY to window.api
  shared/
    ipc-contract.ts      the typed channel map + zod schemas, imported by main, preload and renderer
```
The shared contract is the team API between processes (team-scale.md): change it deliberately, version it.

## Typed, validated IPC — the seam everything crosses
```ts
// shared/ipc-contract.ts
export const EnqueuePublish = z.object({ accountId: z.string().uuid(), videoPath: z.string(), at: z.string().datetime() })

// preload/index.ts — expose tasks, never ipcRenderer itself
contextBridge.exposeInMainWorld('api', {
  enqueuePublish: (input: z.infer<typeof EnqueuePublish>) => ipcRenderer.invoke('jobs:enqueuePublish', input),
})

// main/ipc/jobs.ts — validate sender AND payload, then call the service
ipcMain.handle('jobs:enqueuePublish', (event, raw) => {
  assertTrustedSender(event.senderFrame)          // only our own app window, never an account view
  return jobs.enqueuePublish(EnqueuePublish.parse(raw))
})
```

## Security — the baseline, in code (desktop.md §4)
```ts
new BrowserWindow({ webPreferences: {
  preload, contextIsolation: true, sandbox: true, nodeIntegration: false, webSecurity: true } })
```
```
□ Strict CSP on the app's own pages (no 'unsafe-eval', no remote scripts).
□ webContents.setWindowOpenHandler → deny by default; will-navigate → block anything not your app.
□ Account/third-party pages: their own partition, NO preload, sandboxed, never given the app's API.
□ Permission requests (camera, notifications…) handled by session.setPermissionRequestHandler — deny unless needed.
□ Fuses (@electron-forge/plugin-fuses or electron-builder): EnableEmbeddedAsarIntegrityValidation +
  OnlyLoadAppFromAsar ON; RunAsNode, EnableNodeOptionsEnvironmentVariable, EnableNodeCliInspectArguments OFF.
□ shell.openExternal only for allow-listed https URLs.
□ Keep Electron current — it carries Chromium's security fixes; an old Electron is an old browser.
```

## Performance (the Electron performance guide, VS Code's practice)
```
□ Measure first (Chrome DevTools performance panel for the renderer, --cpu-prof / tracing for main).
□ Lazy-require in main — don't load every module before the first window.
□ Never block main: no sendSync, no sync fs, no heavy JSON parsing — move it to a utilityProcess.
□ Bundle the renderer (Vite); code-split screens; virtualise long lists.
□ Show the window on 'ready-to-show' to avoid a white flash; keep background windows throttled.
□ Sessions: a bounded set of live WebContentsView; hibernate the rest (destroy the view, keep the partition).
```

## Resilience in Electron
```
□ app.requestSingleInstanceLock() — second launch focuses the first.
□ utilityProcess children supervised: on 'exit' restart with backoff + cap; mark the unit failed after N.
□ 'render-process-gone' / 'child-process-gone' → log, recover the view, tell the user if it repeats.
□ process.on('unhandledRejection') in every process → log with context.
□ crashReporter.start (Crashpad) or Sentry's Electron SDK, with personal data scrubbed.
□ before-quit: stop queues → ask workers to finish (timeout) → close views → close the DB.
```

## Packaging, signing, updates
```
Toolchain  Electron Forge (the Electron team's recommended toolchain; Vite + TypeScript templates) or
           electron-builder. Either way: asar on, fuses on, native modules rebuilt for Electron's ABI.
Sign       Windows: Azure Artifact Signing or OV/EV (sign the exe and the installer).
           macOS: Developer ID + hardened runtime + notarization.
Update     update.electronjs.org (public GitHub releases) or electron-updater against your own feed —
           signed builds, verified before install, never mid-job.
CI         build on each target OS, launch the packaged app with --self-check, run the Playwright smoke test.
Python     sidecar (optional): freeze it with Nuitka --standalone, ship as an extraResource, spawn it from
           main, supervise it, and speak a versioned JSON protocol over stdio (stacks/python-desktop.md).
```

## Testing
```
Vitest     services, repositories (in-memory SQLite), IPC handlers with fake senders.
Playwright _electron.launch({ args: ['.'] }) → drive real windows; assert on state, never sleep.
Security   a test that an account view has no window.api, and that a forged IPC sender is rejected.
```

## Add to CLAUDE.md (on top of desktop.md's block)
```markdown
## Electron conventions
- main = composition root + adapters; preload = the only bridge (contextBridge, typed API); renderer = view.
- IPC: invoke/handle only, zod-validated, sender-checked; the contract lives in shared/ipc-contract.ts.
- Heavy or risky work in utilityProcess, supervised. main never blocks.
- Third-party/account pages: own partition, no preload, sandboxed. Fuses on. CSP on.
- better-sqlite3 in main/utility; secrets via safeStorage. Forge + signed builds + verified updates.
```

## Ubiquitous Language
IPC channels and preload methods are named in domain terms — `jobs:enqueuePublish`, `accounts:pause` —
never `doAction`, `invoke2`, `handleData`. The channel map is part of the domain vocabulary.
