# Registry pack — desktop-app

> One project-type pack. Load it together with the trigger index in `references/registry.md`,
> never the other packs. Install names, commands and the consent rule: registry.md §Install recipes.

A desktop (PC) application built the modern way — Electron + TypeScript by default, or Python (PySide6, or a
Python sidecar behind Electron). Local tools, multi-account managers — anything whose job needs the machine: local files,
a local browser engine, offline work, per-machine state, OS integration.

```
decide-at-L0 (one-way door — record ADR-001):
  the shape: Electron+TS (default) | Electron + Python sidecar | PySide6 — and OPERATE vs ACT → desktop.md §1
  the UI-framework licence (e.g. Qt LGPL vs commercial, PyQt GPL)     → a licence is a one-way door too

install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, test-driven-development]
  when-secrets-or-accounts:
    - addyosmani/agent-skills
      skills: [security-and-hardening]      # plus /security-review (bundled) on every such diff
  per-stack tooling: desktop.md §7 (packaging + signed updates) and §9 (mechanics)

tested-with: Electron (current stable), Node.js 24 LTS, TypeScript 7, Python 3.13–3.14, PySide6 6.x, Nuitka 2.x
load: references/desktop.md — ALWAYS (stack choice, UI-thread contract, process model, secrets, signing,
      updates, resilience, multi-account apps). Then the shape's mechanics:
      Electron → stacks/electron.md + stacks/nodejs.md; Python → stacks/python-desktop.md + stacks/python.md.
      The window owes the experience floor too → references/ui-design.md (judgment.md §5b).

shipright-adds-to-CLAUDE:
  stack-adr: "Shape = [Electron+TS | +Python sidecar | PySide6] because [reason] (ADR-001). A rewrite to change."
  ui-thread: "The UI thread never blocks (> ~16 ms → worker). Workers never touch UI objects."
  ui-boundary: "view-models are the handler layer. Services/repositories never import the UI framework."
  processes: "Hang-prone or untrusted work runs in supervised worker processes; IPC is validated."
  data: "Runtime data under the per-user app-data dir via the OS API. Never the install dir."
  secrets: "OS secret store holds the key; data envelope-encrypted. Nothing sensitive in settings or logs."
  isolation: "One isolated session per account. One account's failure pauses that account only."
  ship: "Signed binaries + installer, verified auto-update, per-user install. CI launches the packaged build."
  debt-signals:
    - "TODO[freeze>100ms]: profile the UI thread"
    - "TODO[first-external-user]: code signing + signed auto-update"
    - "TODO[rss-grows-daily]: release sessions/pages/handles/listeners"
```
