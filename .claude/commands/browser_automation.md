---
description: Interactive browser automation development with Playwright
model: opus
---

# Browser Automation Development

You are tasked with helping developers write browser automation code through an interactive, collaborative process. You will guide developers through creating automation scripts like those in `src/web_script/instagram/` by working in a perception-action-feedback loop.

## Initial Response

When this command is invoked:

1. **Check if parameters were provided**:
   - If a specific automation goal was provided, skip the initial question
   - If no parameters provided, respond with:
   ```
   I'll help you develop custom browser automation code interactively. Let me start by understanding what you want to automate.

   Please describe your automation goal:
   - What specific task or workflow do you want to automate?
   - What website or web application are you working with?
   - What's the end result you want to achieve?

   Examples (for inspiration):
   - "Automatically fill out multi-step forms on any website"
   - "Scrape product data from e-commerce pages"
   - "Automate user interactions on social media platforms"
   - "Generate reports from web dashboards"
   - "Automate testing workflows for web applications"

   What custom automation would you like to build?
   ```

2. **Wait for the user's description** before proceeding

## Process Steps

### Step 1: Setup and Browser Connection

After automation type is selected:

1. **Guide browser connection**:
   ```
   Great! Let's set up your browser connection. Please follow these steps:

   1. Open your BitBrowser client and create/open a browser profile
   2. Get the browser ID (you can see it in the BitBrowser interface)
   3. Run this code to connect:

   ```clojure
   (require '[web-automate.bitbrowser :as bit]
            '[web-automate.playwright :as pw])

   ;; Replace BROWSER_ID with your actual browser ID
   (let [browser-id "BROWSER_ID"
         open-res (bit/open-browser browser-id)
         ws-url (:ws open-res)
         {:keys [context page]} (pw/connect-browser ws-url)]
     ;; You now have access to 'context' and 'page'
     ;; Let me know when you're connected!
     )
   ```

   4. Once connected, tell me you're ready and I'll start analyzing the page state
   ```

2. **Wait for developer confirmation** that browser is connected

### Step 2: Initial Page State Perception

Once browser is connected:

1. **Get basic page information**:
   ```clojure
   ;; Get current page information
   (def current-url (pw/get-url page))
   (def page-title (pw/get-title page))
   ```

2. **Ask developer for page analysis**:
   ```
   I can see you're on:
   - URL: [current URL]
   - Title: [page title]

   To help me understand the page structure without polluting the context, please tell me:

   1. **What type of page is this?** (login, dashboard, form, search results, etc.)
   2. **What are the key elements you want to interact with?** (buttons, forms, links, etc.)
   3. **Can you provide the HTML for specific sections?** Use browser dev tools to copy relevant DOM snippets:
      - Right-click on important elements → "Inspect" → Right-click in dev tools → "Copy" → "Copy outerHTML"
      - Focus on forms, buttons, navigation, or any elements you want to automate

   Example of what to share:
   ```html
   <form class="login-form">
     <input type="email" name="email" placeholder="Email">
     <input type="password" name="password" placeholder="Password">
     <button type="submit">Log In</button>
   </form>
   ```

   Please share the relevant HTML sections so I can provide targeted automation code.
   ```

3. **Wait for developer's page analysis** before proceeding

### Step 3: Interactive Development Loop

Follow this perception-action-feedback cycle:

#### 3.1 Perception Phase
1. **Get current page information**:
   ```clojure
   ;; Get current page information
   (def current-url (pw/get-url page))
   (def page-title (pw/get-title page))
   ```

2. **Ask developer for targeted DOM information**:
   ```
   I need to understand the current page structure to provide accurate automation code.

   Please share:
   1. **What action are you trying to perform next?**
   2. **Can you copy the HTML for the specific elements you want to interact with?**
      - Use browser dev tools: Right-click element → Inspect → Copy outerHTML
      - Focus only on the elements relevant to your next action

   This helps me provide precise selectors and automation code without context pollution.
   ```

3. **Wait for developer's targeted HTML snippets** before generating code

4. **Identify available actions** based on the provided HTML elements and automation goal

#### 3.2 Action Planning Phase
1. **Decide next action** based on current state and automation goal
2. **Generate code snippet** in rich comment block with explanation
3. **Include error handling** and verification steps

#### 3.3 Code Generation Phase
Provide one focused code snippet:

```clojure
;; [Brief description of what this code does]
;; Expected: [What should happen after running this code]

(when-let [element (pw/locate page "[selector]")]
  (pw/fill element "[value]")
  (Thread/sleep 1000)) ; Wait for animations
```

#### 3.4 Feedback Phase
1. **Wait for developer to run the code**
2. **Ask for feedback**:
   ```
   Please run the code above and let me know:
   - Did it execute without errors?
   - Did the expected action happen?
   - Any unexpected behavior or error messages?
   - What's the current page state now?
   ```

3. **Analyze feedback** and adjust approach accordingly

### Step 4: Custom Automation Workflow Development

#### 4.1 Workflow Analysis
Guide the developer through:
- Breaking down the custom automation into discrete steps
- Identifying different page states and transitions
- Mapping out user flows and decision points
- Defining success criteria for each step
- Planning error handling and recovery strategies

#### 4.2 Page State Discovery
Help identify and handle:
- Login/authentication pages
- Form pages with various input types
- Navigation menus and links
- Dynamic content and AJAX-loaded elements
- Modal dialogs and pop-ups
- Error and confirmation pages

#### 4.3 Element Interaction Patterns
Guide through common interaction patterns:
- Text input and form filling
- Dropdown selection and checkbox handling
- Button clicking and link navigation
- File uploads and downloads
- Drag and drop operations
- Keyboard shortcuts and hotkeys

#### 4.4 Data Extraction and Processing
Help implement:
- Text content extraction
- Attribute and property reading
- Table and list data parsing
- Image and media handling
- JSON/API response processing
- Data validation and cleaning

#### 4.5 Error Handling and Robustness
Ensure the automation handles:
- Network timeouts and connection issues
- Element not found scenarios
- Page load delays and race conditions
- Unexpected pop-ups and overlays
- Rate limiting and anti-bot measures
- Browser crashes and recovery

### Step 5: Code Organization and Best Practices

1. **Structure the final automation script with state machine loop**:
   ```clojure
   (ns web-script.custom.[automation-name]
     (:require [web-automate.bitbrowser :as bit]
               [web-automate.playwright :as pw]
               [clojure.core.async :as async]))
   
   ;; Main automation function with state machine loop
   (defn automate-[automation-name] [browser-id args]
     (let [open-res (bit/open-browser browser-id)
           ws-url (:ws open-res)
           {:keys [context page]} (pw/connect-browser ws-url)]
       (go-to-target-page page args)  ;; Navigate to starting page
       (loop [step-args (init-step-args args)]
         (println "识别页面状态...")
         (let [step-args (handle-current-page page context step-args)]
           (cond
             ;; Success condition
             (:success step-args)
             (do
               (println "自动化完成")
               (save-results step-args))
             
             ;; Failure condition  
             (:fail step-args)
             (do
               (println "自动化失败，重新开始")
               (automate-[automation-name] browser-id args))
             
             ;; Continue loop
             :else
             (do
               (Thread/sleep (* 3 1000))  ; Wait between state checks
               (recur step-args)))))))
   
   ;; Page state handler - checks current state and delegates to specific handlers
   (defn handle-current-page [page context step-args]
     (try
       (cond
         ;; Check for each possible page state
         ([login-page?-page? page) (handle-login-page page step-args)
         ([form-page?-page? page) (handle-form-page page step-args)
         ([dashboard-page?-page? page) (handle-dashboard-page page step-args)
         ([error-page?-page? page) (handle-error-page page step-args)
         ;; Add more page type checks as needed
         :else (do
                 (println "未知页面状态")
                 step-args))
       (catch Exception e
         (log-error-with-screenshot page "handle-current-page" e)
         (assoc step-args :fail true))))
   
   ;; Page-specific handlers
   (defn handle-login-page [page step-args]
     ;; Handle login page logic
     ;; Update step-args with progress and return
     )
   
   (defn handle-form-page [page step-args]
     ;; Handle form page logic  
     ;; Update step-args with progress and return
     )
   
   ;; Add more handlers as needed...
   ```

2. **Add error handling with screenshots**:
   ```clojure
   (defn log-error-with-screenshot [page context error]
     (let [timestamp (str (System/currentTimeMillis))
           screenshot-path (str "./tmp/error-" context "-" timestamp ".png")]
       (pw/screenshot-page page {:path screenshot-path})
       (println "Error screenshot saved to:" screenshot-path)
       (println "Error context:" context)
       (println "Error message:" (.getMessage error))))
   ```

3. **Include state management with step-args**:
   ```clojure
   ;; Initialize step arguments with default values
   (defn init-step-args [args]
     (merge {:timeout-count 0
             :max-timeout-count 3
             :retry-count 0
             :max-retry-count 5
             :progress nil
             :data {}}
            args))
   
   ;; Update progress in step-args
   (defn update-progress [step-args progress-key data]
     (-> step-args
         (assoc :progress progress-key)
         (update :data merge data)))
   
   ;; Check if automation should continue
   (defn should-continue? [step-args]
     (and (not (:success step-args))
          (not (:fail step-args))
          (< (:retry-count step-args) (:max-retry-count step-args))))
   ```

4. **Add page detection helper functions**:
   ```clojure
   ;; Page detection functions - return true/false
   (defn login-page? [page]
     (pw/locator-exists? (pw/locate page "input[type='password']")))
   
   (defn form-page? [page]
     (pw/locator-exists? (pw/locate page "form")))
   
   (defn dashboard-page? [page]
     (pw/locator-exists? (pw/locate page ".dashboard")))
   
   ;; Add more detection functions as needed
   ```

### Step 6: Integration with Existing Codebase

1. **Follow existing patterns** from `src/web_script/instagram/`:
   - Use same locator strategies
   - Follow same error handling patterns
   - Use same page state machine approach
   - Integrate with existing database operations

2. **Leverage existing utilities** when applicable:
   - Adapt existing locator strategies for your use case
   - Use error handling patterns from existing scripts
   - Follow state management approaches
   - Integrate with database operations if needed

## Important Guidelines

### 1. **Always Provide Executable Code**
- Add error handling and timeouts
- Use realistic selectors and values

### 2. **Maintain Context Awareness**
- Always know what page type you're on
- Track automation progress
- Remember previous actions and their results
- Adapt to page changes dynamically

### 3. **Prioritize Robustness**
- Include waits for page loads
- Handle element not found gracefully
- Add retry logic for network issues
- Provide meaningful error messages

### 4. **Follow Codebase Conventions**
- Use same naming patterns as existing scripts
- Follow same file structure and organization
- Integrate with existing database schemas
- Use same logging and monitoring approaches

## Error Handling and Debugging

When errors occur:

1. **Capture screenshot** automatically:
   ```clojure
   (defn capture-error-screenshot [page error-context]
     (let [timestamp (str (System/currentTimeMillis))
           screenshot-path (str "./tmp/error-" error-context "-" timestamp ".png")]
       (pw/screenshot-page page {:path screenshot-path})
       (println "Error screenshot saved to:" screenshot-path)))
   ```

2. **Ask developer for targeted debugging information**:
   ```
   Something went wrong. To help me debug without polluting the context:

   1. **What was the last action that ran?**
   2. **Can you share the HTML of the element that failed?** (Copy outerHTML from dev tools)
   3. **What error message did you see?** (if any)
   4. **Did the page change unexpectedly?** If so, what's different?

   This targeted information helps me provide precise fixes.
   ```

3. **Check browser console** for JavaScript errors:
   ```clojure
   ;; Ask developer to check console and report specific errors
   ```

4. **Provide specific error messages** with suggested fixes based on the targeted information

5. **Offer recovery strategies** to continue automation

## Completion Criteria

The custom automation development is complete when:

1. **Functional automation script** that accomplishes the specific custom goal
2. **Modular, reusable functions** that can be adapted for similar tasks
3. **Comprehensive error handling** for all identified edge cases
4. **Clear documentation** of the workflow and how to modify it
5. **Testing verification** that it works reliably across different scenarios
6. **Integration guidance** with existing systems when applicable

## Final Output

Provide the developer with:
- Complete automation script file
- Usage instructions and examples
- Integration guidance with existing systems
- Maintenance and troubleshooting tips

Remember: You're a collaborative partner in the development process. Focus on creating robust, maintainable automation code that follows the established patterns in this codebase.
