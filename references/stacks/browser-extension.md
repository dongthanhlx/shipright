# Stack Reference: Browser Extension (Manifest V3, TypeScript)

MV3 is the only format Chrome runs; Firefox and Safari support it too (Firefox keeps event-page
background *scripts* instead of a service worker). Build once, target all three with a framework that
generates the per-browser manifest. See `references/stacks/nodejs.md` for the language baseline.

---

## Mapping: generic → extension specific

```
framework / build        → WXT (Vite-based; file-based entrypoints → generated per-browser manifest;
                           dev mode with HMR; zips per store). Actively maintained — the 2026 default.
                           Minimal alternative: CRXJS (a Vite plugin over your own manifest.json).
language                 → TypeScript, strict
public boundary file     → one module per feature, imported via its index.ts
schema validation        → zod (every message, every API response, everything read from a page)
extension API            → `browser` from WXT (promise-based, typed, cross-browser) — not raw callback `chrome.*`
unit tests               → Vitest + WXT's fakeBrowser (in-memory storage/runtime — no hand mocks)
end-to-end tests         → Playwright: chromium.launchPersistentContext with the built extension loaded
build check              → tsc --noEmit (TypeScript 7)
http client              → fetch + AbortSignal.timeout(), from the background only
structured logging       → console with a requestId (per context) — never log page data or tokens
scheduler                → browser.alarms (survives the service worker being stopped)
state                    → browser.storage (local / session / sync) — WXT's storage wrapper for typed keys
messaging                → a typed message contract (e.g. @webext-core/messaging), validated on receipt
UI                       → popup / options / side panel pages — React or plain TS, bundled by Vite
```

---

## Component model (MV3) — the contexts, and what each may do

```
entrypoints/
  background.ts          SERVICE WORKER (Firefox: event page). Events, network calls, state coordination.
                         No DOM. Stopped when idle (~30 s) — nothing in memory survives.
  content.ts             CONTENT SCRIPT — runs INSIDE the web page. DOM access; a hostile environment.
  popup/                 POPUP — short-lived UI opened from the toolbar.
  options/               OPTIONS page.
  sidepanel/             SIDE PANEL (Chrome) — persistent UI beside the page.
  offscreen.html         OFFSCREEN DOCUMENT (Chrome) — only when you need a DOM API the worker lacks
                         (clipboard, audio, DOMParser). Not web-accessible.
wxt.config.ts            manifest fields: permissions, host_permissions, name, icons
```
WXT turns `entrypoints/` into the manifest; you declare intent, it emits the right shape per browser.

---

## Extension boundary rules (shipright's boundaries 1–4, extension edition)

```
Rule 1: The content script NEVER calls your backend or third-party APIs
  It lives in the page's origin — CORS, the page's CSP, and a hostile page watching.
  → send a typed message to the background, which does the network call.

Rule 2: The background NEVER touches a page's DOM
  → it messages the content script (tabs.sendMessage), which reads/writes the DOM.

Rule 3: State lives in browser.storage — NEVER in module variables
  The service worker is stopped when idle; `let cache = {}` at top level is lost.
  storage.local (large, per device) · storage.session (in-memory, cleared on browser restart — right
  place for short-lived tokens) · storage.sync (small, synced across the user's browsers).
  IndexedDB is available in the background too, for large structured data.

Rule 4: External responses pass an Adapter in the background
  Raw API response → validate + normalise in the background → send the domain object to UI/content.
  Popup, options and content scripts never see raw external responses.
```

---

## MV3 lifecycle rules — add to CLAUDE.md

```markdown
## Browser extension (MV3) rules
- Register every event listener SYNCHRONOUSLY at the top level of the background (WXT's defineBackground
  main runs synchronously — keep it that way). A listener added after an await misses the wake-up event.
- No long-lived timers in the background — it will be stopped. Use browser.alarms (minimum period 30 s);
  setTimeout is fine only for delays of a few seconds inside one event.
- All state via browser.storage (session for ephemeral secrets, local for data). Never module variables.
- Message handlers: use the promise-based `browser` API (return a promise) or a typed messaging library.
  With raw chrome.runtime.onMessage, an async reply needs `return true`.
- Content scripts may read browser.storage, but NEVER do network calls — message the background.
- No remote code: everything executable ships in the package (MV3 policy — and a security rule).
```

---

## Security — the MV3 threat model (see references/security.md for the spine)

An extension runs with the user's authority inside pages it doesn't control. Least privilege (Saltzer &
Schroeder) is the whole game.

```
The content script runs in a HOSTILE page
  ✗ trust scraped DOM values, eval page-provided data, build queries from them
  ✓ everything read from the page is untrusted input — validate with zod before use or storage.

Messaging is an entry point (other extensions — and web pages via externally_connectable — can reach you)
  ✗ an onMessage handler that acts on any message
  ✓ check sender.id (and sender.url / origin) against an allow-list before anything privileged;
    keep externally_connectable absent or narrow; validate every payload with the shared schema.

XSS in popup / options / side panel / injected UI
  ✗ el.innerHTML = untrustedData  → XSS in an extension page = access to your privileged APIs
  ✓ textContent / framework rendering; keep the default MV3 CSP; inject UI into pages with a shadow root
    (WXT's createShadowRootUi) so the page can't restyle or read it.

Secrets do not belong in an extension
  ✗ API keys in the bundle or storage.local → they ship to every user; storage is NOT encrypted
  ✓ secrets stay behind YOUR backend. A user's own short-lived token → storage.session.

Least privilege (stores reject over-broad extensions)
  ✓ activeTab + optional_host_permissions requested at the moment of use, over <all_urls> up front.
  ✓ host_permissions only for domains you actually call; content-script `matches` as narrow as the feature.
  ✓ web_accessible_resources: the minimum, each scoped by `matches` — every entry is reachable by web pages.

Remote code is banned in MV3 — keep it that way
  ✗ fetch a script/string and eval it, or load remote JS → policy violation + RCE risk

Supply chain
  ✓ lockfile committed, npm audit in CI; review what each dependency injects into the page bundle.
```

Add to CLAUDE.md: "Validate message sender and payload before privileged actions. No secrets in the
extension. No innerHTML with untrusted data; injected UI in a shadow root. Permissions requested at the
moment of use; host_permissions = only domains actually called."

---

## Tooling

```bash
npx wxt@latest init my-extension     # pick a template (vanilla / React / Vue / Svelte / Solid)
cd my-extension
npm run dev                          # opens a browser with the extension loaded + HMR
npm run dev:firefox                  # same, Firefox
npm run zip                          # per-store zips for Chrome Web Store / Firefox Add-ons
```
Linting: ESLint flat config (typescript-eslint). Store submission: least-privilege permissions and a
privacy policy URL are review requirements, not polish.

---

## Testing — test-first, at two levels

**Unit (Vitest + fakeBrowser)** — the background's handlers and the services behind them, with
in-memory `browser.storage` / `runtime` instead of hand-written mocks:
```typescript
import { describe, it, expect, beforeEach } from 'vitest'
import { fakeBrowser } from 'wxt/testing/fake-browser'   // vitest.config: plugins: [WxtVitest()] from 'wxt/testing/vitest-plugin'
import { handleFetchPrice } from '@/features/pricing'

describe('pricing background handler', () => {
  beforeEach(() => fakeBrowser.reset())            // no state leaks between tests

  it('stores the NORMALISED price, not the raw response', async () => {
    const api = { getPrice: async () => ({ price: '99.99', currency: 'USD' }) }  // the Adapter seam
    await handleFetchPrice({ url: 'https://shop.example/p/1' }, api)
    expect(await fakeBrowser.storage.local.get('priceData'))
      .toEqual({ priceData: { amount: 9999, currency: 'USD' } })               // integer minor units
  })
})
```

**End-to-end (Playwright)** — load the BUILT extension; MV3 extensions need a persistent context:
```typescript
const context = await chromium.launchPersistentContext('', {
  channel: 'chromium',   // Playwright's bundled Chromium — branded Chrome/Edge removed the side-loading flags
  args: [`--disable-extensions-except=${dist}`, `--load-extension=${dist}`],
})
const [worker] = context.serviceWorkers().length
  ? context.serviceWorkers() : [await context.waitForEvent('serviceworker')]
const extensionId = new URL(worker.url()).host
const popup = await context.newPage()
await popup.goto(`chrome-extension://${extensionId}/popup.html`)
```
Remember the worker is stopped after ~30 s idle: a test that passes only because the worker stayed warm
is testing the wrong thing — include one test that waits past the idle timeout.

---

## Walking skeleton for an extension MVP

```
User clicks the toolbar icon
  → popup sends a typed { type: 'GET_DATA' } message
  → background validates the sender, calls the API through its Adapter (with a timeout)
  → background stores the normalised result in browser.storage.local
  → background replies with the domain object
  → popup renders it (loading, empty and error states included — references/ui-design.md)

Gate: this flow passes as a Vitest test (fakeBrowser) AND as a Playwright test against the built
extension, in Chrome and Firefox. Don't add features until it does.
```
