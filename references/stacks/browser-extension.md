# Stack Reference: Browser Extension (Manifest V3)

MV3 is mandatory for all Chrome extensions in 2026. Firefox supports MV3 but keeps
non-persistent event pages. Use Extension.js to target both from the same source.

---

## Mapping: generic → extension specific

```
public boundary file     → index.js (re-exported from each component)
schema validation        → zod (in service worker for API responses)
test runner              → Jest + jsdom (popup), WebExtension polyfill for unit tests
build check              → tsc --noEmit (if TypeScript)
http client              → fetch (built-in, called from service worker only)
structured logging       → console with requestId (service worker context)
scheduler                → chrome.alarms API (NOT setTimeout — dies with SW)
state storage            → chrome.storage.local / chrome.storage.sync
cross-component comms    → chrome.runtime.sendMessage / sendResponse
```

---

## Component model (MV3) — the 4 contexts

```
my-extension/
  manifest.json          # blueprint: permissions, components, CSP
  background.js          # SERVICE WORKER: events, API calls, state mgmt
  content.js             # CONTENT SCRIPT: DOM access, page interaction
  popup/
    popup.html           # no inline scripts (CSP)
    popup.js             # POPUP UI: user input, display results
  offscreen/
    offscreen.html       # OFFSCREEN DOC: persistent state, WebSocket, audio
    offscreen.js
  options/
    options.html
    options.js
  icons/
    icon-16.png
    icon-48.png
    icon-128.png
```

---

## manifest.json — MV3 required structure

```json
{
  "manifest_version": 3,
  "name": "[extension-name]",
  "version": "0.1.0",
  "description": "[what it does]",

  "permissions": ["storage", "activeTab", "alarms"],
  "host_permissions": ["https://api.example.com/*"],

  "background": {
    "service_worker": "background.js",
    "type": "module"
  },

  "content_scripts": [{
    "matches": ["<all_urls>"],
    "js": ["content.js"],
    "run_at": "document_idle"
  }],

  "action": {
    "default_popup": "popup/popup.html",
    "default_icon": {
      "16": "icons/icon-16.png",
      "48": "icons/icon-48.png",
      "128": "icons/icon-128.png"
    }
  },

  "web_accessible_resources": [{
    "resources": ["offscreen/offscreen.html"],
    "matches": ["<all_urls>"]
  }]
}
```

---

## Extension boundary rules (adapted from shipright's 4 rules)

```
Rule 1: Content script NEVER calls external APIs directly
  Wrong: fetch('https://api.example.com') in content.js
  Right: chrome.runtime.sendMessage({ type: 'FETCH_DATA', url }) → service worker fetches

Rule 2: Service worker NEVER accesses DOM
  Wrong: document.querySelector('#price') in background.js
  Right: chrome.tabs.sendMessage(tabId, { type: 'GET_PRICE' }) → content script reads DOM

Rule 3: State lives in chrome.storage — NEVER in module variables
  Wrong: let userData = {} at top of background.js (lost when SW terminates)
  Right: chrome.storage.local.set({ userData }) / chrome.storage.local.get(['userData'])

Rule 4: External API responses always pass through Adapter in service worker
  Raw API response → normalize in background.js → send normalized data to popup/content
  Popup and content script never see raw external API responses
```

---

## L1 skeleton prompt (extension)

```
Create browser extension skeleton (Manifest V3):

manifest.json: permissions=[storage, activeTab], service_worker=background.js
background.js: register ALL listeners at top level synchronously (not inside async callbacks)
  - chrome.runtime.onInstalled listener
  - chrome.runtime.onMessage listener
  - chrome.alarms.onAlarm listener (if using alarms)
content.js: single listener for chrome.runtime.onMessage
popup/popup.html: no inline scripts, link to popup.js
popup/popup.js: sends messages to service worker, displays results
icons/: placeholder 16/48/128 PNG files

Critical MV3 rules in the skeleton:
  - State stored via chrome.storage.local, never module variables
  - setTimeout/setInterval NOT used — chrome.alarms instead
  - All listeners registered synchronously at module top level
  - No DOM access in background.js
  - No fetch calls in content.js

Gate: extension loads in chrome://extensions without errors
```

---

## L2 test patterns (extension)

```typescript
// Unit test service worker logic (no real chrome.* calls needed)
// Mock chrome.* APIs with jest-webextension-mock

import 'jest-webextension-mock'

describe('background message handler', () => {
  it('fetches data and stores result', async () => {
    // Arrange
    const mockResponse = { price: '99.99', currency: 'USD' }
    global.fetch = jest.fn().mockResolvedValue({
      json: () => Promise.resolve(mockResponse)
    })

    // Act
    await handleMessage({ type: 'FETCH_PRICE', url: 'https://...' }, null, jest.fn())

    // Assert
    expect(chrome.storage.local.set).toHaveBeenCalledWith({
      priceData: { price: 99.99, currency: 'USD' }  // normalized, not raw
    })
  })
})
```

---

## Critical MV3 gotchas — add to CLAUDE.md

```markdown
## Browser Extension (MV3) rules

### Service worker (background.js)
- NO DOM access (window, document do not exist)
- NO module-level state (let/const at top = lost when SW terminates)
- ALL state via chrome.storage.local.set/get
- ALL listeners registered SYNCHRONOUSLY at top level of file
- NO setTimeout/setInterval → use chrome.alarms API
- Async message response: must return true from onMessage listener
  chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
    doAsyncThing().then(sendResponse)
    return true  // ← required to keep channel open
  })

### Content script (content.js)
- NO external fetch calls → send message to service worker
- NO chrome.storage access (use messaging instead)
- Runs in isolated context — cannot access page's JS variables directly

### State management
- chrome.storage.local: large data, device only
- chrome.storage.sync: small data (<8KB), syncs across user's devices
- IndexedDB: large structured data, use via offscreen document

### Permissions (minimal permission principle)
- Request only what you need — extra permissions = Chrome Web Store rejection risk
- activeTab: access current tab on user gesture (less invasive than tabs)
- host_permissions: only domains you actually call
```

---

## Security — the MV3 threat model (see references/security.md for the spine)

An extension runs with the user's authority inside pages it doesn't control. Its threat model is
specific — least privilege (Saltzer & Schroeder) is the whole game here.

```
Content script runs in a HOSTILE page
  ✗ trust scraped DOM values as safe / eval page-provided data / build queries from them
  ✓ treat everything read from the page as untrusted input. Sanitize before use or storage.

Message passing is an entry point (other pages/extensions can message you)
  ✗ chrome.runtime.onMessage handler that acts on any message
  ✓ validate sender: check sender.id (your extension), sender.origin/url against an allow-list
    before doing anything privileged. Keep externally_connectable narrow or absent.

XSS in popup / options / injected UI
  ✗ el.innerHTML = untrustedData  → XSS in an extension = access to your privileged APIs
  ✓ el.textContent = data; build DOM nodes; MV3 CSP already forbids inline scripts — don't relax it.

Secrets do not belong in an extension
  ✗ API keys/tokens in the bundle or in chrome.storage → it ships to users; storage is NOT encrypted
  ✓ put secrets behind YOUR backend; the extension calls your backend, which holds the key.

Least privilege (Chrome will also reject over-broad extensions)
  ✓ activeTab over <all_urls>; request host_permissions only for domains you actually call.
  ✓ web_accessible_resources: expose the minimum — each entry is reachable by web pages.

Remote code is banned in MV3 — keep it that way
  ✗ fetch a script/string and eval it, or load remote JS  → policy violation + RCE risk
  ✓ all executable code ships in the package and is reviewed.
```

Add to CLAUDE.md: "Validate message sender before privileged actions. No secrets in the extension —
call a backend. No innerHTML with untrusted data. host_permissions = only domains actually used."

---

## Recommended tooling (2026)

```
Framework: Extension.js — targets Chrome (MV3) and Firefox from same source
TypeScript: yes, strongly recommended for message type safety
Build: Extension.js handles bundling, manifest generation, hot reload
Testing: jest + jest-webextension-mock for unit tests
E2E: Playwright + chrome-launcher for real browser testing
Linting: eslint + eslint-plugin-webextensions
```

```bash
# Start new extension with Extension.js
npx extension create my-extension
cd my-extension
npm run dev  # opens Chrome with extension loaded + hot reload
```

---

## Walking skeleton for extension MVP — test-first

> **Test before deploying to Chrome.** Extensions can't be "hot-fixed" once published.
> Write failing test first → implement → test passes → then load in Chrome.

### Test-first skeleton flow
```
1. Write failing test (jest-webextension-mock):
   it('popup sends message → background responds with data', async () => {
     chrome.runtime.onMessage.addListener.mockImplementation(
       (listener) => listener({ type: 'GET_DATA' }, null, mockSendResponse)
     )
     expect(mockSendResponse).toHaveBeenCalledWith({ data: expect.any(Array) })
   })
   → Test FAILS (nothing implemented)

2. Implement background.js handler until test passes
3. Load unpacked extension in Chrome
4. Verify: popup → message → response works in real browser
```

The minimal extension that proves the architecture works end-to-end:

```
User clicks toolbar icon
  → popup.html opens
  → popup.js sends { type: 'GET_DATA' } to service worker
  → background.js receives message, fetches from API
  → background.js stores result in chrome.storage.local
  → background.js sendResponse({ data: normalizedData })
  → popup.js displays data

Gate: this full flow works without errors in Chrome DevTools
Do NOT add more features until this gate passes.
```
