# Registry pack — browser-extension

> One project-type pack. Load it together with the trigger index in `references/registry.md`,
> never the other packs. Install names, commands and the consent rule: registry.md §Install recipes.

Chrome / Firefox / Safari extension, Manifest V3, TypeScript.

```
install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, test-driven-development]
  framework:
    - WXT (Vite-based, generates the per-browser manifest): npx wxt@latest init
  testing:
    - Vitest + WXT's fakeBrowser (unit) · Playwright launchPersistentContext (end-to-end, built extension)

tested-with: Chrome MV3, Firefox MV3, WXT 0.x (current), Vitest 4, Playwright (current)
load: references/stacks/browser-extension.md — MV3 contexts, typed messaging, storage boundaries, and the
      content-script security model (a content script trusts a hostile DOM — see security.md)

shipright-adds-to-CLAUDE:
  boundary-sw: "Background (service worker): NO DOM, NO module-level state (it is stopped when idle)"
  boundary-content: "Content script: NO network calls → typed message to the background"
  boundary-state: "State via browser.storage (session for ephemeral tokens, local for data). Never JS variables."
  messaging: "One typed message contract; sender + payload validated on every receipt"
  mv3-gotchas:
    - "Listeners registered SYNCHRONOUSLY at the top level of the background"
    - "No long-lived timers → browser.alarms (min 30 s period)"
    - "Promise-based `browser` API for replies (raw chrome.runtime.onMessage needs `return true`)"
    - "No remote code; keep the default extension-page CSP"
  debt-signals:
    - "TODO[publish]: privacy policy URL + least-privilege permission review before store submission"
    - "TODO[broad-host-permission]: move to optional_host_permissions requested at the moment of use"
```
