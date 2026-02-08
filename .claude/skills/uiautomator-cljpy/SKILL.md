---
name: uiautomator-cljpy
description: Android UI automation library for Clojure using uiautomator2 via libpython-clj2. Use this when you need to automate Android device interactions, find UI elements, perform gestures, or control apps programmatically.
---

# uiautomator-cljpy - Android UI Automation

## When to Use This Skill

Use this skill when you need to:
- **Automate Android device interactions** (clicks, swipes, text input)
- Find and interact with UI elements on Android devices
- Control Android applications programmatically
- Take screenshots and dump UI hierarchies for debugging
- Execute shell commands on Android devices
- Transfer files between host and device

## How It Works

The `uiautomator-cljpy` library provides Clojure bindings for uiautomator2, a Python library for Android UI automation. It uses `libpython-clj2` to interface with the Python uiautomator2 module, allowing you to control Android devices from Clojure code.

**Key concepts:**
- **Device connection**: Connect to devices via IP:PORT (e.g., "192.168.1.19:5001") or device serial
- **Element finding**: Use filter maps (e.g., `{"text" "OK"}`, `{"resourceId" "com.example:id/button"}`) to locate UI elements
- **Waiting**: Functions like `wait-find` and `wait-find-any` poll for elements with configurable timeouts
- **Element operations**: Once found, elements can be clicked, have text set, or be queried for properties

## Instructions

### 0. Setup and Connection

First, ensure you have the Python environment set up with uiautomator2:

```clojure
(require '[com.zihao.cljpy-main.interface :refer [make-python-env]])
(def python-env
  (make-python-env []
                   {:u2 "uiautomator2"}))
(def u2-module (:u2 python-env))
```

Then connect to a device:

```clojure
(require '[uiautomator-cljpy.utils :as uia-utils])
(def device (uia-utils/connect-device u2-module "192.168.1.19:5001"))
```

**Device identifiers:**
- IP:PORT format: `"192.168.1.19:5001"` (for devices connected via network)
- Device serial: Use ADB device serial for USB-connected devices

### 1. Finding Elements

Elements are found using filter maps that match UI properties:

```clojure
;; Find by text
(uia-utils/wait-find device {"text" "OK"})

;; Find by resource ID
(uia-utils/wait-find device {"resourceId" "com.example:id/button"})

;; Find by description
(uia-utils/wait-find device {"description" "Send button"})

;; Find by text contains
(uia-utils/wait-find device {"textContains" "Telegram"})

;; Find by description contains
(uia-utils/wait-find device {"descriptionContains" "Phone"})

;; Find by class name
(uia-utils/wait-find device {"className" "android.widget.Button"})
```

**Waiting functions:**
- `wait-find`: Waits for a single element matching the filter (default timeout: 3000ms)
- `wait-find-any`: Tries multiple filters and returns the first match
- `wait-find-xpath`: Finds elements using XPath expressions

### 2. Interacting with Elements

**Clicking:**
```clojure
;; Find and click (waits for element, then clicks)
(uia-utils/find-and-click device {"text" "OK"})

;; Click an existing element
(let [element (uia-utils/wait-find device {"text" "OK"})]
  (uia-utils/click element))

;; Click at screen coordinates
(uia-utils/click-screen device 100 200)

;; Long press
(uia-utils/long-click-screen device 100 200 2.0) ; 2 second duration
```

**Text input:**
```clojure
;; Find element and set text
(uia-utils/find-and-settext device {"className" "android.widget.EditText"} "Hello World")

;; Set text on existing element
(let [element (uia-utils/wait-find device {"className" "android.widget.EditText"})]
  (uia-utils/set-text element "Hello World"))
```

**Reading text:**
```clojure
(let [element (uia-utils/wait-find device {"text" "Some Text"})]
  (uia-utils/get-text element))
```

### 3. Gestures and Navigation

**Swiping:**
```clojure
;; Swipe up (default scale: 0.5)
(uia-utils/swipe device "up")

;; Swipe with custom scale
(uia-utils/swipe device "up" {:scale 1.0})

;; Swipe with custom coordinates
(uia-utils/swipe device "up" {:scale 0.5 :start-x 100 :start-y 500 :end-x 100 :end-y 200})

;; Direct coordinate swipe
(uia-utils/swipe device 100 500 100 200)
```

**System keys:**
```clojure
(uia-utils/press device "home")
(uia-utils/press device "back")
```

### 4. App Management

```clojure
;; Open an app
(uia-utils/open-app device "com.example.app")

;; Stop an app
(uia-utils/stop-app device "com.example.app")

;; Restart an app
(uia-utils/restart-app device "com.example.app")

;; Clear app data
(uia-utils/clear-app device "com.example.app")

;; Get list of installed apps
(uia-utils/app-list device)

;; Get current app info
(uia-utils/app-current device)
```

### 5. Screenshots and Debugging

```clojure
;; Take screenshot (returns temp file path)
(def screenshot-path (uia-utils/screenshot device))

;; Dump UI hierarchy (XML)
(uia-utils/dump-hierarchy device)

;; Create debug dump (screenshot + hierarchy)
(uia-utils/debug-dump device "/path/to/debug/dir")
```

### 6. Element Navigation

**Finding related elements:**
```clojure
;; Find sibling element
(let [profile-info (uia-utils/wait-find device {"text" "Profile info"})]
  (uia-utils/sibling profile-info {"className" "android.widget.FrameLayout"}))

;; Find child element
(let [parent (uia-utils/wait-find device {"text" "Parent"})]
  (uia-utils/child parent {"className" "android.widget.ImageView"}))

;; Chain operations
(-> (uia-utils/wait-find device {"text" "Profile info"})
    (uia-utils/sibling {"className" "android.widget.FrameLayout"})
    (uia-utils/child {"className" "android.widget.ImageView"})
    uia-utils/click)
```

### 7. XPath Queries

```clojure
;; Find all elements matching XPath
(uia-utils/xpath device "//android.widget.Button[@text='OK']")

;; Wait for XPath elements
(uia-utils/wait-find-xpath device "//android.widget.Button" :timeout 5000)
```

### 8. Clipboard Operations

```clojure
;; Get clipboard content
(uia-utils/get-clipboard device)

;; Set clipboard content
(uia-utils/set-clipboard device "Text to copy")
```

### 9. File Operations

```clojure
;; Push file to device
(uia-utils/push device "/host/path/file.txt" "/sdcard/file.txt")

;; Pull file from device
(uia-utils/pull device "/host/path/file.txt" "/sdcard/file.txt")

;; Push image and trigger media scanner
(uia-utils/push-img device "/path/to/image.jpg")
```

### 10. Shell Commands

```clojure
;; Execute shell command (returns exit code)
(uia-utils/shell device "ls /sdcard")
```

### 11. Waiting for Elements to Disappear

```clojure
;; Wait for element to disappear
(uia-utils/wait-disappear device {"text" "Loading..."} :timeout 5000)

;; Wait for existing element to disappear
(let [element (uia-utils/wait-find device {"text" "Loading..."})]
  (uia-utils/wait-disappear-elem element :timeout 5000))
```

### 12. Element Information

```clojure
;; Get element info (bounds, text, class, etc.)
(let [element (uia-utils/wait-find device {"text" "OK"})]
  (uia-utils/info element))

;; Check if element is checked (for checkboxes)
(let [element (uia-utils/wait-find device {"description" "Checkbox"})]
  (uia-utils/get-checked element))

;; Check if element exists
(let [element (uia-utils/get-element device {"text" "OK"})]
  (uia-utils/exists? element))
```

## Available Functions

### Device Connection
- `connect-device [u2-module serial]` - Connect to device via IP:PORT or serial

### Element Finding
- `get-element [device filter]` - Get single element (may not exist)
- `get-elements [device filter]` - Get all matching elements
- `wait-find [device filter & {:keys [timeout]}]` - Wait for element (default: 3000ms)
- `wait-find-any [device filters & {:keys [timeout]}]` - Try multiple filters, return first match
- `wait-find-xpath [device xpath-expr & {:keys [timeout]}]` - Wait for XPath elements
- `exists? [element]` - Check if element exists
- `filter-exists? [device element-or-filter]` - Check if filter matches existing element

### Element Interaction
- `click [element]` - Click an element
- `find-and-click [device filter & {:keys [timeout]}]` - Find and click (waits for element)
- `click-screen [device x y]` or `[device xpath-elem]` - Click at coordinates
- `long-click-screen [device x y duration]` or `[device xpath-elem duration]` - Long press
- `set-text [element text]` - Set text on editable element
- `find-and-settext [device filter text & {:keys [timeout]}]` - Find and set text
- `get-text [element]` - Get text content
- `text [xpath-elem-or-element]` - Get text property

### Gestures
- `swipe [device direction]` - Swipe in direction (up/down/left/right)
- `swipe [device direction opts]` - Swipe with options (scale, coordinates)
- `swipe [device start-x start-y end-x end-y]` - Direct coordinate swipe
- `press [device key]` - Press system key (home, back, etc.)

### App Management
- `open-app [device app-name]` - Open application
- `stop-app [device app-name]` - Stop application
- `restart-app [device app-name]` - Restart application
- `clear-app [device app-name]` - Clear app data
- `app-list [device]` - List installed apps
- `app-current [device]` - Get current app info

### Element Navigation
- `sibling [element filter]` - Find sibling element
- `child [element filter]` - Find child element
- `xpath [device expr]` - Find elements by XPath
- `xpath-elem->elem [xpath-elem]` - Extract element from XPath element

### Element Information
- `info [xpath-element]` - Get detailed element information
- `get-checked [element]` - Get checked state (for checkboxes)

### Waiting
- `wait-disappear [device filter & {:keys [timeout]}]` - Wait for element to disappear
- `wait-disappear-elem [element & {:keys [timeout]}]` - Wait for existing element to disappear

### Screenshots and Debugging
- `screenshot [device]` - Take screenshot (returns temp file path)
- `dump-hierarchy [device]` - Get UI hierarchy XML
- `debug-dump [device dir]` - Create screenshot + hierarchy dump files

### Clipboard
- `get-clipboard [device]` - Get clipboard content
- `set-clipboard [device text]` - Set clipboard content

### File Operations
- `push [device host-path device-path]` - Push file to device
- `pull [device host-path device-path]` - Pull file from device
- `push-img [device path]` - Push image and trigger media scanner

### Shell
- `shell [device cmd]` - Execute shell command (returns exit code)

### Utilities
- `optional [step]` - Returns step if truthy, otherwise true
- `retry [count body reset-state]` - Macro to retry operations

## Important Notes

- **Filter maps**: Use maps like `{"text" "OK"}` or `{"resourceId" "com.example:id/button"}` to find elements. Common keys: `text`, `textContains`, `description`, `descriptionContains`, `resourceId`, `className`
- **Timeouts**: Default timeout is 3000ms (3 seconds) for waiting functions. Use `:timeout` keyword argument to customize
- **Element existence**: Elements returned by `get-element` may not exist yet. Use `wait-find` to wait for elements, or check with `exists?`
- **Swipe scale**: Currently `scale` must be provided when using options map. Default two-parameter call uses scale 0.5
- **Device connection**: Devices can be connected via network (IP:PORT) or USB (device serial). Network connection requires uiautomator2 server running on device
- **Thread safety**: Functions are generally thread-safe, but device state changes between calls
- **Error handling**: Functions that wait for elements return `nil` if timeout is exceeded. Check return values before using elements
- **Chaining**: Many functions return elements, allowing for chaining: `(-> element (sibling filter) (child filter) click)`

## Typical Workflow

1. **Setup Python environment and connect to device:**
   ```clojure
   (require '[com.zihao.cljpy-main.interface :refer [make-python-env]]
            '[uiautomator-cljpy.utils :as uia-utils])
   
   (def python-env (make-python-env [] {:u2 "uiautomator2"}))
   (def u2-module (:u2 python-env))
   (def device (uia-utils/connect-device u2-module "192.168.1.19:5001"))
   ```

2. **Open app and wait for elements:**
   ```clojure
   (uia-utils/open-app device "com.example.app")
   (uia-utils/wait-find device {"text" "Welcome"})
   ```

3. **Interact with UI:**
   ```clojure
   (uia-utils/find-and-click device {"text" "Login"})
   (uia-utils/find-and-settext device {"className" "android.widget.EditText"} "username")
   (uia-utils/find-and-click device {"text" "Submit"})
   ```

4. **Wait for transitions:**
   ```clojure
   (uia-utils/wait-disappear device {"text" "Loading..."})
   (uia-utils/wait-find device {"text" "Success"})
   ```

5. **Debug when needed:**
   ```clojure
   (uia-utils/debug-dump device "/path/to/debug")
   (uia-utils/screenshot device)
   ```

