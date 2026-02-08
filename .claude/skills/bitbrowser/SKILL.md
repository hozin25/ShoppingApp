---
name: bitbrowser
description: Manage BitBrowser instances via Clojure evaluation. Use this when you need to open browsers, list browser profiles, or get CDP endpoints for browser automation. The agent should use the clojure-eval skill to interact with BitBrowser functions.
---

# BitBrowser Management

## How It Works

This skill provides access to BitBrowser management functions through the `web-automate.bitbrowser.interface` namespace. The agent should use the **clojure-eval skill** to evaluate Clojure code that calls these functions.

## Instructions

### 0. Explore Function Documentation

To explore all available functions and their complete docstrings:

```bash
clj-nrepl-eval -p <PORT> "(doseq [sym (sort (keys (ns-publics 'web-automate.bitbrowser.interface)))] (let [v (ns-resolve 'web-automate.bitbrowser.interface sym)] (when (:doc (meta v)) (println (str sym \":\")) (println (:doc (meta v))) (println))))"
```

This displays all functions with parameters, options, and return values directly from the source.

### 1. Use Clojure Eval Skill

All BitBrowser operations are performed by evaluating Clojure code using the clojure-eval skill. First, ensure you have an nREPL connection (see clojure-eval skill for details).

### 2. Require the BitBrowser Namespace

Before using BitBrowser functions, require the namespace:

```bash
clj-nrepl-eval -p <PORT> "(require '[web-automate.bitbrowser.interface :as bit] :reload)"
```

### 3. Open a Browser and Get CDP Endpoint

To open a browser and get its CDP WebSocket endpoint:

```bash
clj-nrepl-eval -p <PORT> "(require '[web-automate.bitbrowser.interface :as bit] :reload) (:ws (bit/open-browser \"<BROWSER-ID>\"))"
```

**Example:**
```bash
clj-nrepl-eval -p <PORT> "(require '[web-automate.bitbrowser.interface :as bit] :reload) (:ws (bit/open-browser \"74ff3f38dbc2480bb2ade11e2d2adc9a\"))"
```

This returns the CDP WebSocket endpoint (e.g., `ws://...`) which can be used with the **cdp-browser skill** to control the browser.

## Common Workflows

### Getting CDP Endpoint for cdp-browser Skill

1. **Require the namespace:**
   ```bash
   clj-nrepl-eval -p <PORT> "(require '[web-automate.bitbrowser.interface :as bit] :reload)"
   ```

2. **Open browser and extract CDP endpoint:**
   ```bash
   clj-nrepl-eval -p <PORT> "(:ws (bit/open-browser \"<BROWSER-ID>\"))"
   ```

3. **Use the returned WebSocket URL with the cdp-browser skill** to control the browser

**Complete example:**
```bash
# Step 1: Require namespace
clj-nrepl-eval -p 49625 "(require '[web-automate.bitbrowser.interface :as bit] :reload)"

# Step 2: Get CDP endpoint
clj-nrepl-eval -p 49625 "(:ws (bit/open-browser \"74ff3f38dbc2480bb2ade11e2d2adc9a\"))"
# Returns: "ws://127.0.0.1:9222/devtools/browser/abc123"

# Step 3: Use the CDP endpoint with cdp-browser skill
```

### Finding a Browser by Name

1. **List browsers with name filter:**
   ```bash
   clj-nrepl-eval -p <PORT> "(require '[web-automate.bitbrowser.interface :as bit] :reload) (bit/browser-list 0 100 {:name \"<SEARCH-TERM>\"})"
   ```

2. **Extract browser ID from results**

3. **Open the browser using the ID**

### Automating the Browser with Playwright

Once you have the CDP endpoint, use the **cdp-browser skill** to control the browser via Playwright.

**Quick example:**
```bash
# Connect to browser and get current tab title
clj-nrepl-eval -p <PORT> "(require '[web-automate.bitbrowser.interface :as bit] :reload) (require '[web-automate.playwright.interface :as pw] :reload) (def connect-res (let [ws-url (:ws (bit/open-browser \"<BROWSER-ID>\"))] (pw/connect-browser ws-url))) (def page (:page connect-res)) (.title page)"
```

See the **cdp-browser skill** for complete Playwright API documentation and examples.

## Available Functions

All functions are in the `web-automate.bitbrowser.interface` namespace (aliased as `bit`):

**Browser Management:**
- `bit/open-browser`
- `bit/running-browsers`
- `bit/browser-list`
- `bit/create-browser`
- `bit/delete-browser`
- `bit/clear-browser-data`

**Browser Groups:**
- `bit/group-list`
- `bit/browser-group-update`

**Automation:**
- `bit/auto-paste`
- `bit/auto-layout-windows`

**Cookies:**
- `bit/set-cookies`
- `bit/kv->ig-cookie`

**Utilities:**
- `bit/gen-uuid`

For complete documentation including parameters, options, and return values, use the docstring exploration command above.

## Important Notes

- **Idempotent open-browser:** Calling `bit/open-browser` multiple times on the same browser ID will not create duplicate instances. If already opened, it returns the existing CDP endpoint quickly.
- **Session persistence:** Browser sessions remain open until explicitly closed or the browser is closed in BitBrowser.

## Integration with Other Skills

### With cdp-browser Skill

The primary use case is to get CDP endpoints for the cdp-browser skill:

1. Use clojure-eval to call `bit/open-browser` with a browser ID
2. Extract the `:ws` value from the result
3. Pass that WebSocket URL to the cdp-browser skill to control the browser

### With clojure-eval Skill

All BitBrowser operations are performed through clojure-eval:
- Ensure nREPL is running (see clojure-eval skill documentation)
- Require the namespace with `:reload`
- Evaluate function calls to interact with BitBrowser

## Example Usage

**User:** Open browser ID "74ff3f38dbc2480bb2ade11e2d2adc9a" and get its CDP endpoint

**Agent:** 
1. Uses clojure-eval to require the namespace
2. Calls `bit/open-browser` with the browser ID
3. Extracts and returns the `:ws` value
4. Optionally uses the CDP endpoint with cdp-browser skill

**User:** List all browsers with "test" in the name

**Agent:**
1. Uses clojure-eval to require the namespace
2. Calls `bit/browser-list` with name filter
3. Returns the list of matching browsers

