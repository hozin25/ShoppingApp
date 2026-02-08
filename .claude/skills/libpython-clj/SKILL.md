---
name: libpython-clj
description: Interoperate with Python from Clojure using libpython-clj2. Use this when you need to call Python libraries, use Python modules, or integrate Python functionality into your Clojure code.
---

# libpython-clj - Python Interoperability for Clojure

## When to Use This Skill

Use this skill when you need to:
- **Call Python libraries** from Clojure code
- **Use Python modules** that don't have Clojure equivalents
- **Integrate existing Python code** into Clojure applications
- **Access Python's ecosystem** of libraries and tools
- **Bridge between Clojure and Python** codebases

## How It Works

libpython-clj2 embeds a Python interpreter in your Clojure process, allowing you to import Python modules, call Python functions, and work with Python objects directly from Clojure. It provides seamless type conversion between Clojure and Python data structures.

**Key concepts:**
- **Python environment**: Initialize Python with a virtual environment or system Python
- **Module imports**: Import Python modules using `py/import-module`
- **Function calls**: Use `py.` and `py.-` to call Python functions and access attributes
- **Type conversion**: Automatic conversion between Clojure and Python types, with explicit conversion functions available
- **Python objects**: Work with Python objects directly in Clojure

## Instructions

### 0. Setup

Add libpython-clj2 to your dependencies:

```clojure
;; deps.edn
{:deps {clj-python/libpython-clj {:mvn/version "2.025"}}}
```

Require the namespace:

```clojure
(require '[libpython-clj2.python :as py :refer [py. py.-]])
```

### 1. Creating Python Environments

**Using cljpy-main (recommended):**

The `cljpy-main` component provides a convenient way to set up Python environments with virtual environments:

```clojure
(require '[com.zihao.cljpy-main.interface :refer [make-python-env]])

;; Create Python environment with modules
(def python-env
  (make-python-env ["./components/my-component"]  ; user library paths
                   {:built-in "builtins"          ; Python built-in functions
                    :sys "sys"                    ; Python sys module
                    :math "math"                  ; Python math module
                    :my-module "my_module"}))     ; Your custom module

;; Access imported modules
(def built-in (:built-in python-env))
(def sys (:sys python-env))
(def math (:math python-env))
```

### 2. Importing Python Modules

**Basic import:**

```clojure
(def math (py/import-module "math"))
(def json (py/import-module "json"))
(def os (py/import-module "os"))
```

**Import submodules:**

```clojure
(def sync-client (py/import-module "baml_client.sync_client"))
(def runtime (py/import-module "baml_client.runtime"))
```

**Import and access module attributes:**

```clojure
(def sys (py/import-module "sys"))
(def modules (py/py.- sys "modules"))  ; Access sys.modules
(def path (py/py.- sys "path"))        ; Access sys.path
```

### 3. Calling Python Functions with `py.`

The `py.` macro is used to call Python functions and methods:

**Calling module functions:**

```clojure
;; Call built-in functions
(py. built-in "print" "Hello, World!")
(py. built-in "abs" -10)
(py. built-in "len" [1 2 3 4])

;; Call math functions
(py. math "sqrt" 16)           ; => 4.0
(py. math "pi")                ; => 3.14159...
(py. math "cos" 0)             ; => 1.0
```

**Calling methods on Python objects:**

```clojure
;; Call methods on objects
(py. some-python-object "method_name" arg1 arg2)

;; Example: JSON operations
(def json (py/import-module "json"))
(py. json "dumps" {:name "John" :age 30})
(py. json "loads" "{\"name\": \"John\"}")
```

**Calling with keyword arguments:**

```clojure
;; Using ->py-dict for keyword arguments
(py. some-function "arg1" (py/->py-dict {:key1 "value1" :key2 "value2"}))
```

### 4. Accessing Attributes with `py.-`

The `py.-` macro is used to access attributes and properties of Python objects:

**Accessing module attributes:**

```clojure
;; Access module-level attributes
(py.- math "pi")               ; Access math.pi
(py.- math "e")                ; Access math.e
(py.- sys "version")           ; Access sys.version
(py.- sys "path")              ; Access sys.path
```

**Accessing object attributes:**

```clojure
;; Access attributes on Python objects
(py.- some-python-object "attribute_name")

;; Example: Access class from module
(def sync-client (py/import-module "baml_client.sync_client"))
(def b (py/py.- sync-client "b"))  ; Access sync_client.b
```

**Accessing nested attributes:**

```clojure
;; Access nested attributes
(py.- (py/py.- sys "modules") "json")  ; Access sys.modules["json"]
```

### 5. Type Conversion

**Clojure to Python:**

```clojure
;; Automatic conversion (most cases)
(py. math "sqrt" 16)  ; Integer automatically converted

;; Explicit conversion
(py/->python [1 2 3])           ; Convert vector to Python list
(py/->python {:a 1 :b 2})       ; Convert map to Python dict
(py/->python "hello")            ; Convert string to Python string
(py/->py-dict {:a 1 :b 2})      ; Convert map to Python dict (alias)
(py/->py-list [1 2 3])          ; Convert vector to Python list
```

**Python to Clojure:**

```clojure
;; Automatic conversion (most cases)
(py. math "sqrt" 16)  ; Returns Clojure number

;; Explicit conversion
(py/->jvm python-object)        ; Convert Python object to Clojure
(py/as-jvm python-object)      ; Alias for ->jvm
```

**Working with Python dictionaries:**

```clojure
;; Create Python dict from Clojure map
(def py-dict (py/->py-dict {:name "John" :age 30}))

;; Convert Python dict to Clojure map
(def clj-map (py/->jvm py-dict))
```

### 6. Common Patterns

**Reloading Python modules:**

```clojure
(def importlib (py/import-module "importlib"))
(def sys (py/import-module "sys"))
(def modules (py/py.- sys "modules"))

;; Reload a module
(py. importlib "reload" (get modules "my_module"))
```

**Extending Python path:**

```clojure
(def sys (py/import-module "sys"))
(def path (py/py.- sys "path"))
(py/call-attr path "extend" ["./my-python-libs"])
```

**Calling methods with call-attr:**

```clojure
;; Alternative to py. for method calls
(py/call-attr some-object "method_name" arg1 arg2)

;; Example: Extend sys.path
(py/call-attr (py/get-attr sys "path") "extend" ["./libs"])
```

**Getting attributes with get-attr:**

```clojure
;; Alternative to py.- for attribute access
(py/get-attr sys "version")
(py/get-attr math "pi")
```

**Working with Python classes:**

```clojure
;; Get a class from a module
(def TerminalApp (py/py.- app-module "TerminalApp"))

;; Instantiate the class
(def app-instance (py/py. TerminalApp))

;; Call instance methods
(py. app-instance "start_spinner")
(py. app-instance "add_user_output" "Hello")
```

### 7. Error Handling

```clojure
(try
  (py. math "sqrt" -1)
  (catch Exception e
    (println "Error:" (.getMessage e))))
```

### 8. Working with Python Collections

**Python lists:**

```clojure
;; Create Python list
(def py-list (py/->python [1 2 3 4 5]))

;; Access elements
(py/py.- py-list "0")  ; Get first element
(py/call-attr py-list "append" 6)  ; Append element
```

**Python dictionaries:**

```clojure
;; Create Python dict
(def py-dict (py/->py-dict {:a 1 :b 2 :c 3}))

;; Access values
(py/py.- py-dict "a")  ; Get value for key "a"
```

### 9. Advanced Usage

**Chaining operations:**

```clojure
;; Chain attribute access and method calls
(-> (py/import-module "sys")
    (py/py.- "modules")
    (get "json")
    (py/py.- "dumps")
    (py. {:name "John"}))
```

**Working with Pydantic models:**

```clojure
;; Call model_dump() on Pydantic model
(def model-dump (py/py. pydantic-model "model_dump"))
(def clj-map (keywordize-keys (py/->jvm model-dump)))
```

**Module initialization pattern:**

```clojure
(defn make-python-env [user-lib-paths modules]
  (let [init-config {:python-executable "./.venv/bin/python"
                     :library-path "./.venv/lib/python3.12/libpython3.12.so"
                     :user-lib-paths (conj user-lib-paths "./.venv/lib/python3.12/site-packages")}]
    (py/initialize! init-config)
    (let [sys (py/import-module "sys")]
      (py/call-attr (py/get-attr sys "path") "extend" (:user-lib-paths init-config))
      (into {}
            (for [[k v] modules]
              [k (py/import-module v)])))))
```

## Available Functions and Macros

### Core Functions
- `py/initialize! [config]` - Initialize Python interpreter with configuration
- `py/import-module [module-name]` - Import a Python module
- `py/call-attr [obj method-name & args]` - Call a method on a Python object
- `py/get-attr [obj attr-name]` - Get an attribute from a Python object
- `py/set-attr! [obj attr-name value]` - Set an attribute on a Python object

### Macros
- `py. [obj method-or-fn & args]` - Call Python function or method (most common)
- `py.- [obj attr-name]` - Access Python attribute (most common)

### Type Conversion
- `py/->python [clj-value]` - Convert Clojure value to Python
- `py/->jvm [py-value]` - Convert Python value to Clojure
- `py/as-jvm [py-value]` - Alias for ->jvm
- `py/->py-dict [clj-map]` - Convert Clojure map to Python dict
- `py/->py-list [clj-vector]` - Convert Clojure vector to Python list

### Utility Functions
- `py/with-gil-stack-rc-context [f]` - Execute function with GIL context
- `py/with-python [f]` - Execute function in Python context

## Important Notes

- **Initialization**: Python must be initialized before importing modules. Use `py/initialize!` once at startup.
- **Virtual environments**: It's recommended to use Python virtual environments (`.venv`) to manage dependencies and avoid conflicts.
- **Type conversion**: Most types convert automatically between Clojure and Python. Use explicit conversion functions when needed.
- **`py.` vs `py.-`**: Use `py.` for calling functions/methods, use `py.-` for accessing attributes/properties.
- **Module reloading**: Use `importlib.reload()` to reload Python modules during development.
- **Path management**: Extend `sys.path` to add custom Python library paths.
- **Error handling**: Python exceptions are converted to Java/Clojure exceptions. Use try-catch for error handling.
- **Thread safety**: Python's GIL is managed automatically by libpython-clj2.
- **Memory management**: Python objects are garbage collected automatically. No manual cleanup needed.
- **Performance**: Python interop has some overhead. For performance-critical code, consider native Clojure alternatives.

## Common Patterns Summary

**Setup pattern:**
```clojure
(require '[libpython-clj2.python :as py :refer [py. py.-]]
         '[com.zihao.cljpy-main.interface :refer [make-python-env]])

(def python-env (make-python-env [] {:built-in "builtins" :sys "sys"}))
(def built-in (:built-in python-env))
```

**Calling functions:**
```clojure
(py. built-in "print" "Hello")
(py. math "sqrt" 16)
```

**Accessing attributes:**
```clojure
(py.- math "pi")
(py.- sys "version")
```

**Working with modules:**
```clojure
(def module (py/import-module "module_name"))
(py. module "function" arg1 arg2)
(def attr (py/py.- module "attribute"))
```

## Typical Workflow

1. **Setup Python environment:**
   ```clojure
   (require '[com.zihao.cljpy-main.interface :refer [make-python-env]]
            '[libpython-clj2.python :as py :refer [py. py.-]])
   
   (def python-env (make-python-env ["./components/my-lib"]
                                    {:my-module "my_module"}))
   ```

2. **Import and use modules:**
   ```clojure
   (def my-module (:my-module python-env))
   (def result (py. my-module "some_function" arg1 arg2))
   ```

3. **Access module attributes:**
   ```clojure
   (def class-or-constant (py/py.- my-module "SomeClass"))
   ```

4. **Work with Python objects:**
   ```clojure
   (def instance (py/py. class-or-constant))
   (py. instance "method" arg)
   (def attr (py/py.- instance "attribute"))
   ```

## References

- [libpython-clj2 GitHub Repository](https://github.com/clj-python/libpython-clj)

