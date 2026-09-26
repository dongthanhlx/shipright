# Stack Reference: Python desktop apps (PySide6 / Qt)

> **Read `references/desktop.md` first** — it owns the rules for any desktop app (stack choice, the
> UI-thread contract, process model, secrets, signing, updates, resilience, multi-account apps). This
> file is only where those rules land in Python. Plus `references/stacks/python.md` for the language.
>
> Masters for this stack: **the Qt Project** (*Threads and QObjects*); **Martin Fitzpatrick** (*Create
> GUI Applications with Python & Qt*, pythonguis.com); **Mark Summerfield** (*Rapid GUI Programming with
> Python and Qt* — model/view); **David Beazley** (threads vs processes vs async in Python);
> **Kay Hayen** (Nuitka).

Python enters a desktop app in one of two shapes (desktop.md §1):
- **PySide6** — a native Qt 6 UI, in-process with Python. Python-first team, data-heavy screens, no
  embedded web content.
- **A Python sidecar behind an Electron UI** — the job needs Python's libraries (data, ML, automation),
  the UI should be modern web. Electron owns the window; Python is a supervised worker process.

---

## Framework — licence is the one-way door
```
PySide6 (Qt for Python, official) — default. LGPLv3: closed-source commercial use is fine with dynamic
         linking. Widgets for data-heavy tools; QML for fluid UI.
PyQt6 — the same Qt under GPLv3 or a paid licence. For a closed-source product that is a LICENCE
         one-way door — decide it at L0, not at release.
Not covered (desktop.md scope): Tkinter, wxPython, pywebview/Flet — shipright builds on the two shapes above.
```

## The sidecar shape — Python behind Electron
```
Process   Electron main spawns the frozen sidecar (Nuitka --standalone, shipped as an extraResource),
          puts it under supervision (restart with backoff + cap) and kills it on quit.
Protocol  newline-delimited JSON-RPC over stdio: {id, method, params} → {id, result | error}. Versioned —
          the first message is a handshake with the protocol version; mismatch = refuse and report.
          Every message validated on both sides (pydantic in Python, zod in TypeScript).
          stdout is the protocol ONLY — logs go to stderr / a file, or they corrupt the stream.
Boundary  the sidecar is an ADAPTER (Boundary 4): the renderer never talks to it; main's services do.
Timeouts  every request carries a deadline; a sidecar that stops answering is restarted, not waited on.
Why stdio over a local HTTP port: no port to collide with or expose, no firewall prompt, and the pipe
          dies with the process.
```

## The UI-thread contract in Qt
```
Only the GUI thread touches QWidgets/QObjects living there. Work > ~16 ms goes to a worker; results come
back through signals (queued across threads automatically).
  ✗ button.clicked → requests.get(...)           → "Not Responding"
  ✗ a worker calling label.setText(...)            → undefined behaviour, random crashes later
  ✓ worker emits finished(result) → slot updates the view on the GUI thread
Use QThreadPool + QRunnable, or the worker-object moved to a QThread. Don't subclass QThread to do work
in run() while also giving it slots — the classic Qt threading bug.
```

## Concurrency in Python (Beazley)
```
Many I/O waits (HTTP, browser automation) → asyncio: run it on the Qt loop (PySide6.QtAsyncio, or the
  maintained third-party qasync) or in ONE dedicated worker thread that talks to the UI via signals.
A few blocking calls                      → QThreadPool.
CPU-bound / crash isolation               → processes (ProcessPoolExecutor, multiprocessing) — the GIL
  means threads won't speed up CPU work.
Free-threaded Python (3.14+, PEP 779) is officially supported but not the default build, and any C
extension that hasn't opted in silently re-enables the GIL. Don't design around it until your exact
dependency set supports it — measure.
```

## Where desktop.md's rules land in Python
```
Paths        QStandardPaths (AppDataLocation / AppLocalDataLocation) — never hard-coded.
SQLite       sqlite3 with PRAGMA journal_mode=WAL + busy_timeout; one connection PER THREAD (never
             share a Connection across threads); migrations with alembic or a numbered-SQL runner.
Secrets      keyring (→ Windows Credential Manager / macOS Keychain) holds the KEY; cryptography
             (AESGCM / Fernet) encrypts the data. Or DPAPI directly via pywin32 (win32crypt).
             QSettings is for preferences only — never secrets.
Job Objects  pywin32 (win32job) with JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE so browsers/helpers die with the app.
Crashes      faulthandler to a file; sys.excepthook + threading.excepthook → log + a friendly dialog.
Single inst. QLocalServer / QLockFile.
Shutdown     app.aboutToQuit → stop workers → close sessions → close the DB.
Automation   playwright (Python) — one browser, one isolated context per account; set timeouts per
             context (the defaults are long); PLAYWRIGHT_BROWSERS_PATH under %LOCALAPPDATA%.
Big tables   QAbstractTableModel + QTableView (virtualised) — never QTableWidget with thousands of rows.
Startup      python -X importtime → lazy-import heavy modules after the first window paints.
```

## Packaging & updates
```
Nuitka --standalone (a folder) for anything you distribute: compiled, faster start, far fewer antivirus
  false positives. PyInstaller --onedir is fine for internal tools.
Avoid --onefile in either: it unpacks to %TEMP% on every launch — slow, and exactly what AV heuristics flag.
Installer: Inno Setup or MSIX, per-user. Sign the exe, the built DLLs and the installer (desktop.md §4).
Updates:  tufup (built on python-tuf) — signed, verified, packaging-agnostic.
CI:       build on windows-latest and launch the frozen build with --self-check; missing hidden imports
          and data files only appear there.
Deps:     pin with hashes (uv.lock / pip-compile --generate-hashes); pip-audit in CI.
```

## Testing
```
Services/domain: pytest, no Qt. UI: pytest-qt (qtbot) — wait on signals (qtbot.waitSignal), never sleep.
The frozen build: smoke-launched in CI (above).
```

## Add to CLAUDE.md (on top of desktop.md's block)
```markdown
## Python desktop conventions
- PySide6 (LGPL). Services/repositories never import PySide6.
- Workers: QThreadPool/QRunnable or asyncio via QtAsyncio/qasync; CPU work in processes.
- sqlite3: one connection per thread, WAL. Secrets: keyring-held key + cryptography.
- Ship: Nuitka --standalone, signed; tufup updates; CI launches the frozen build.
```
