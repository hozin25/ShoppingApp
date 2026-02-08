---
name: cdp-browser
description: Browser automation using the web-automate Clojure library via Playwright API and Chrome DevTools Protocol (CDP). Use this when you need to automate browser interactions, control existing browsers via CDP, interact with web pages using Playwright locators and actions, or work with the web-automate.playwright.interface namespace.
---

# CDP Browser Automation

## When to Use This Skill

Use this skill when you need to:
- **Control your existing browser** without launching a new instance
- **Preserve logged-in sessions** and cookies
- **Automate browser interactions** in your current browser environment
- **Connect to BitBrowser instances** via CDP endpoint
- **Test web applications** in your actual browser with all extensions and settings

## How It Works

This skill uses `web-automate.playwright.interface` via Clojure evaluation to control browsers via CDP:
1. Get a CDP WebSocket endpoint (from BitBrowser, Chrome remote debugging, etc.)
2. Use clojure-eval to connect via `(pw/connect-browser ws-url)`
3. Control the browser using Playwright API functions

## Instructions

### 0. Explore Function Documentation

To explore all available Playwright functions and their complete docstrings:

```bash
clj-nrepl-eval -p <PORT> "(doseq [sym (sort (keys (ns-publics 'web-automate.playwright.interface)))] (let [v (ns-resolve 'web-automate.playwright.interface sym)] (when (:doc (meta v)) (println (str sym \":\")) (println (:doc (meta v))) (println))))"
```

This displays all functions with parameters, options, and return values directly from the source.

### 1. Obtain CDP Endpoint

**From BitBrowser:**
```bash
clj-nrepl-eval -p <PORT> "(require '[web-automate.bitbrowser.interface :as bit] :reload) (:ws (bit/open-browser \"<BROWSER-ID>\"))"
```

**From Chrome remote debugging:** Start Chrome with `--remote-debugging-port=9222` and use `ws://127.0.0.1:9222/devtools/browser/<id>`

### 2. Connect to Browser

```bash
# Require namespaces
clj-nrepl-eval -p <PORT> "(require '[web-automate.playwright.interface :as pw] :reload)"

# Connect to CDP endpoint
clj-nrepl-eval -p <PORT> "(def connect-res (pw/connect-browser \"ws://127.0.0.1:65168/devtools/browser/...\"))"

# Extract page object
clj-nrepl-eval -p <PORT> "(def page (:page connect-res))"
```

### 3. Control the Browser

Once connected, use the Playwright API functions documented below.

## Playwright API Reference

> **Note:** For detailed documentation of each function including parameters, options, and return values, use the docstring exploration command in Section 0.

### Browser & Context Management
**Connect/Launch:** `connect-browser`, `launch-browser`, `launch-with-persistent-context`, `create-chrome`
**Close:** `close-browser`, `close-context`, `close-page`
**Context:** `pages-context`, `context-page`, `new-page`
**State:** `storage-state`, `set-geolocation`, `geolocation-context`, `set-offline`

### Page Navigation & Info
**Navigate:** `visit-page`, `go-back`, `go-forward`, `reload-page`
**Get Info:** `url-page`, `title-page`, `content-page`, `set-content-page`
**Screenshots/PDF:** `screenshot-page`, `page-pdf`
**Frames:** `frames-page`, `main-frame`, `frame-by-name`, `frame-by-url`

### Locators (Element Finding)
**Basic:** `locate`, `by-text`, `by-title`, `by-label`, `by-placeholder`, `by-alt-text`, `by-test-id`, `by-role`
**Advanced:** `any-locator`, `combine-locator`, `locator-frame`, `frame-locator`
**Frame Locators:** `locator-frame`

### Locator Actions
**Click:** `locator-click`, `click-any`
**Input:** `locator-fill`, `locator-input-value`, `locator-select-options`
**Get Info:** `locator-text`, `locator-get-attribute`, `locator-all-attributes`
**Query:** `locator-exists?`, `locator-count`, `locator-all`, `locator-element`
**Navigation:** `locator-parent`, `locator-meaningful-parent`
**Debug:** `locator-highlight`, `debug-locator`
**Screenshot:** `screenshot`

### Waiting & Conditions ⚠️ USE THESE INSTEAD OF Thread/sleep!
**Wait Exist:** `wait-exist`, `wait-exist-any` - Wait for elements to appear in DOM
**Wait Load:** `wait-for-load-state-page`, `frame-wait-for-load-state` - Wait for page/frame load states (`load`, `domcontentloaded`, `networkidle`)
**Wait URL:** `wait-for-url-page`, `frame-wait-for-url` - Wait for URL to match pattern
**Wait Events:** `wait-for-console-message`, `wait-for-download-page`, `wait-for-popup-page`, `wait-for-request`, `wait-for-response`
**Wait Function:** `wait-for-function-page`, `wait-for-function-frame`, `wait-for-condition-page` - Wait for custom conditions

### Frame Operations
**Info:** `frame-name`, `frame-url`, `frame-title`, `frame-content`, `frame-element`, `frame-page`, `parent-frame`, `child-frames`
**Navigate:** `frame-navigate`, `frame-set-content`
**Evaluate:** `frame-evaluate`, `evaluate-handle-frame`
**Query:** `query-selector-frame`, `query-selector-all-frame`
**Actions:** `drag-and-drop-frame`, `is-enabled-frame`, `add-script-tag-frame`, `add-style-tag-frame`

### Cookie & Storage
**Cookies:** `cookies-context`, `get-cookies`, `get-cookie`, `add-cookies`, `clear-cookies`
**Storage:** `local-storage`
**Scripts:** `add-init-script`, `add-script-tag-page`, `add-style-tag-page`

### Evaluation & Scripting
**Evaluate:** `evaluate-page`, `evaluate-handle-page`, `frame-evaluate`, `evaluate-handle-frame`
**Content:** `set-content-page`, `content-page`, `frame-content`, `frame-set-content`

### Network & Headers
**Routing:** `route-context`, `unroute-context`, `unroute-all-context`
**Headers:** `set-extra-http-headers`, `set-extra-http-headers-context`

### Timeouts & Settings
**Timeouts:** `set-default-timeout`, `set-default-timeout-context`, `set-default-navigation-timeout`, `set-default-navigation-timeout-context`
**Viewport:** `set-viewport-size`
**Permissions:** `grant-permissions`
**Page Control:** `bring-to-front`, `pause-page`, `is-closed?`, `is-detached?`

### Utility Functions
**File Upload:** `choose-png-file`, `choose-b64-as-png-file`
**Drag & Drop:** `drag-and-drop-page`, `drag-and-drop-frame`

## Anti-Patterns (What NOT to Do)

### ❌ DON'T: Use Thread/sleep for waiting
```clojure
;; BAD - Fixed wait time, unreliable
(pw/visit-page page "https://example.com")
(java.lang.Thread/sleep 5000)  ; ❌ What if page loads in 1 second? Or 10 seconds?
(def btn (pw/locate page "button"))
```

### ✅ DO: Use wait functions
```clojure
;; GOOD - Waits for actual element to appear
(pw/visit-page page "https://example.com")
(pw/wait-for-load-state-page page :state "networkidle")  ; ✅ Wait for network
(pw/wait-exist page "button" :timeout-milli 10000)  ; ✅ Wait for element
(def btn (pw/locate page "button"))
```

## Common Usage Patterns

### Page Operations
```bash
# Get page info
clj-nrepl-eval -p <PORT> "(.title page)"
clj-nrepl-eval -p <PORT> "(.url page)"

# Navigate
clj-nrepl-eval -p <PORT> "(pw/visit-page page \"https://example.com\")"

# Screenshot
clj-nrepl-eval -p <PORT> "(pw/screenshot-page page {:path \"./screenshot.png\"})"
```

### Element Location & Interaction
```bash
# Locate and click
clj-nrepl-eval -p <PORT> "(def btn (pw/locate page \"button.submit\")) (pw/locator-click btn)"

# Any of multiple locators
clj-nrepl-eval -p <PORT> "(def next-btn (pw/any-locator [(pw/locate page \"text=Next\") (pw/locate page \"text=次へ\")]))"
clj-nrepl-eval -p <PORT> "(pw/click-any [(pw/locate page \"text=Register\") (pw/locate page \"text=登録\")])"

# Fill input
clj-nrepl-eval -p <PORT> "(pw/locator-fill locator \"text to enter\")"

# Get element data
clj-nrepl-eval -p <PORT> "(pw/locator-text locator)"
clj-nrepl-eval -p <PORT> "(pw/locator-get-attribute locator \"href\")"
clj-nrepl-eval -p <PORT> "(pw/locator-input-value locator)"
```

### Waiting (IMPORTANT: Use These Instead of Thread/sleep!)

**⚠️ Always use Playwright wait functions instead of `Thread/sleep` for reliable automation.**

```bash
# Wait for element to appear (recommended after navigation)
clj-nrepl-eval -p <PORT> "(pw/wait-exist page \"[data-e2e=\"chat-list-item\"]\" :timeout-milli 10000)"

# Wait for any of multiple selectors
clj-nrepl-eval -p <PORT> "(pw/wait-exist-any page [\"text=Loaded\" \"text=完了\"] :timeout-milli 10000)"

# Wait for page load state (after navigation)
clj-nrepl-eval -p <PORT> "(pw/wait-for-load-state-page page :state \"networkidle\")"

# Wait for URL change
clj-nrepl-eval -p <PORT> "(pw/wait-for-url-page page \"https://example.com\")"

# Check if exists (non-blocking)
clj-nrepl-eval -p <PORT> "(pw/locator-exists? locator)"
```

**Common Pattern: Navigate and Wait**
```bash
# Navigate then wait for content
clj-nrepl-eval -p <PORT> "(pw/visit-page page \"https://example.com\")"
clj-nrepl-eval -p <PORT> "(pw/wait-for-load-state-page page :state \"networkidle\")"
clj-nrepl-eval -p <PORT> "(pw/wait-exist page \".content\" :timeout-milli 10000)"
```

**Why wait functions are better than Thread/sleep:**
- ✅ Wait for actual DOM readiness instead of fixed time
- ✅ Faster when page loads quickly
- ✅ More reliable when page loads slowly
- ✅ Prevents race conditions
- ✅ Handles dynamic content loading

### Cookie Management
```bash
# Get all cookies for URL
clj-nrepl-eval -p <PORT> "(pw/get-cookies context \"https://www.instagram.com\")"

# Get specific cookie
clj-nrepl-eval -p <PORT> "(pw/get-cookie context \"https://www.instagram.com\" \"sessionid\")"
```

## Important Notes

- **Session persistence:** Browser sessions remain connected in the REPL until explicitly closed
- **Context vs Page:** The connect result has both `:context` (for cookies, storage) and `:page` (for DOM interaction)
- **Always use :reload:** When requiring namespaces, use `:reload` to ensure you have the latest code
- **Error handling:** Use `try/catch` when dealing with potential timeouts or missing elements
- **⚠️ NEVER use Thread/sleep:** Always use `wait-exist`, `wait-for-load-state-page`, or other wait functions instead of `(java.lang.Thread/sleep ...)`. Fixed sleep times are unreliable and inefficient.
- **Examples:** See `components/web-script/src/com/dx/web_script/instagram/` for real-world examples

## Complete Examples

### Connect to BitBrowser and Get Tab Title
```bash
clj-nrepl-eval -p 49464 "(require '[web-automate.bitbrowser.interface :as bit] :reload) (require '[web-automate.playwright.interface :as pw] :reload) (def connect-res (let [ws-url (:ws (bit/open-browser \"391b80ec7fe74fb391b700ebb9e09fc1\"))] (pw/connect-browser ws-url))) (def page (:page connect-res)) (.title page)"
```

### Navigate and Click Element
```bash
# Navigate
clj-nrepl-eval -p <PORT> "(pw/visit-page page \"https://example.com\")"

# Find and click button
clj-nrepl-eval -p <PORT> "(def btn (pw/locate page \"button.submit\")) (pw/locator-click btn)"
```

### Check Page Type and Handle
```bash
clj-nrepl-eval -p <PORT> "(if (pw/locator-exists? (pw/locate page \"text=Login\")) (do (println \"Login page\") (pw/locator-click (pw/locate page \"text=Sign In\"))) (println \"Other page\"))"
```

## Integration with Other Skills

- **bitbrowser skill:** Use bitbrowser to get CDP endpoints, then use this skill to control
- **clojure-eval skill:** All operations go through clojure-eval with nREPL
- **Instagram automation examples:** `components/web-script/src/com/dx/web_script/instagram/` contains extensive examples
