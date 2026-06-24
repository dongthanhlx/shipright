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

## Walking skeleton for extension MVP

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
