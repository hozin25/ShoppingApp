---
name: replicant-table-component
description: Replicant table-component is a powerful data table component for building interactive tables with filtering, selection, pagination, and CRUD operations in ClojureScript applications.
---

# Replicant Table Component - Data Tables for ClojureScript

## When to Use This Skill

Use this skill when you need to:
- **Display tabular data** from queries in a ClojureScript/Replicant application
- **Add filtering capabilities** to tables (text filters, exact match, partial match)
- **Enable row selection** (single or multi-selection) for batch operations
- **Implement pagination** for large datasets
- **Build CRUD interfaces** with create, edit, delete operations
- **Integrate tables with the Replicant store** for state management

## How It Works

The `table-component` is part of the Replicant component library. It connects to the Replicant store atom and query system to:
- Fetch data via query handlers
- Store selection state, filter state, and pagination in the global store
- Automatically handle pagination, filtering, and selection UI
- Provide hooks for custom actions (create, edit, delete)

**Key concepts:**
- **Query-based data**: Tables fetch data via `:query/kind` identifiers
- **Store integration**: Selection, filters, and pagination stored in global Replicant store
- **Column definitions**: Map of column headers to render functions or keywords
- **Configuration options**: Multi-selection, select-all, row IDs, custom actions
- **Filter system**: `table-filter` component for adding filter inputs

## Quick Start

### Setup

Require the necessary namespaces:

```clojure
(ns my-ns.render
  (:require
   [com.zihao.replicant-component.interface :refer [table-component]]
   [com.zihao.replicant-component.component.table :refer [table-filter get-selected-ids]]))
```

### Basic Example

**Simple table without selection:**
```clojure
(def my-table
  (table-component
   :query/my-data
   ["ID" "Name" "Status"]
   {"ID" :id
    "Name" :name
    "Status" (fn [row] [:span {:class ["badge"]} (:status row)])}
   {:table-id :query/my-data
    :row->id :id}))
```

**Table with multi-selection:**
```clojure
(def table-id :query/browser-devices)

(def browser-table
  (table-component
   :query/browser-devices
   ["ID" "Name" "Status"]
   {"ID" (fn [row] [:span {:class ["font-mono"]} (:id row)])
    "Name" (fn [row] (:name row))
    "Status" (fn [row] (status-badge (:status row)))}
   {:table-id table-id
    :multi-selection? true
    :select-all? true
    :row->id :id}))
```

**Using the table in render:**
```clojure
(defn render [state]
  [:div
   (browser-table state)])
```

## Core API

### `table-component`

Creates a table component that fetches and displays data.

**Signature:**
```clojure
(table-component query-kind column-headers column-defs options)
```

**Parameters:**
- `query-kind` - Keyword identifying the query (e.g., `:query/browser-devices`)
- `column-headers` - Vector of column header strings
- `column-defs` - Map of column header strings to:
  - Keywords (direct field access): `:id`, `:name`
  - Functions (custom rendering): `(fn [row] [:span (:name row)])`
- `options` - Map of configuration options (see Options below)

**Options:**
- `:table-id` - Unique identifier for the table (used for selection/filter state)
- `:row->id` - Function or keyword to extract unique ID from each row
- `:multi-selection?` - Boolean, enable multi-row selection (default: false)
- `:select-all?` - Boolean, show "select all" checkbox (requires `:multi-selection?`)
- `:on-new` - Vector of actions to execute when "new" button clicked

**Example:**
```clojure
(def my-table
  (table-component
   :query/users
   ["ID" "Email" "Actions"]
   {"ID" :user/id
    "Email" :user/email
    "Actions" (fn [row]
                [:div {:class ["flex" "gap-2"]}
                 [:button {:on {:click [[:user/edit (:user/id row)]]}}
                  "Edit"]
                 [:button {:on {:click [[:user/delete (:user/id row)]]}}
                  "Delete"]])}
   {:table-id :query/users
    :row->id :user/id
    :on-new [[:user/edit :random]]}))
```

### `table-filter`

Creates filter inputs for a table.

**Signature:**
```clojure
(table-filter state table-id filter-defs)
```

**Parameters:**
- `state` - Replicant store state
- `table-id` - Same `:table-id` used in `table-component`
- `filter-defs` - Vector of filter definitions

**Filter Definition:**
```clojure
{:type :text          ; Filter input type
 :key :conversation_id ; Key in filter map passed to query
 :label "会话ID"       ; Label for the filter input
 :placeholder "输入会话ID进行筛选（完全匹配）"}
```

**Example:**
```clojure
(defn filter-section [state]
  (table-filter state table-id
                [{:type :text
                  :key :id
                  :label "浏览器ID"
                  :placeholder "输入浏览器ID进行筛选"}
                 {:type :text
                  :key :name
                  :label "名称"
                  :placeholder "输入名称进行筛选"}]))
```

**Using filters:**
```clojure
(defn render [state]
  [:div
   (filter-section state)
   (my-table state)])
```

### `get-selected-ids`

Retrieves selected row IDs from the store.

**Signature:**
```clojure
(get-selected-ids state table-id id-key)
```

**Parameters:**
- `state` - Replicant store state
- `table-id` - Same `:table-id` used in `table-component`
- `id-key` - Keyword or function to extract ID from row (same as `:row->id`)

**Returns:** Vector of selected row IDs

**Example:**
```clojure
(defn render [state]
  (let [selected-ids (get-selected-ids state table-id :id)]
    [:div
     (when (seq selected-ids)
       [:button {:on {:click [[:batch/delete selected-ids]]}}
        "Delete Selected"])
     (my-table state)]))
```

## Query Handler Integration

Tables fetch data via query handlers. The query handler receives a query map with:
- `:query/kind` - The query identifier
- `:query/data` - Map containing:
  - `:page` - Current page number (default: 1)
  - `:size` - Page size (default: 20)
  - `:filter` - Map of filter key-value pairs

**Query Handler Example:**
```clojure
(defn query-handler [query]
  (case (:query/kind query)
    :query/browser-devices
    (let [{:keys [page size filter]} (:query/data query)
          page (or page 1)
          size (or size 20)
          filter (or filter {})]
      (db/all-browsers page size filter))
    
    nil))
```

**Filter Usage in Query Handler:**
```clojure
(defn query-handler [query]
  (case (:query/kind query)
    :query/messages-pb
    (let [{:keys [page size filter]} (:query/data query)
          filter* (when (and filter (seq filter)) filter)]
      (db/get-all-messages ds (or page 1) (or size 20) filter*))
    
    nil))
```

**Database Function with Filter:**
```clojure
(defn get-all-messages
  ([ds] (get-all-messages ds 1 100 nil))
  ([ds page size] (get-all-messages ds page size nil))
  ([ds page size filter]
   (let [conversation-id (when filter (get filter :conversation_id))
         base-query {:select [:m.*]
                     :from [[:pb_messages :m]]
                     :order-by [[:m.id :desc]]
                     :limit size
                     :offset offset}
         query (if (and conversation-id (seq (str/trim conversation-id)))
                 (assoc base-query :where [:= :m.conversation_id (str/trim conversation-id)])
                 base-query)]
     (jdbc/execute! ds (sql/format query)))))
```

## Store Structure

The Replicant store atom stores table-related state under paths like:
- Selection state: `[:table-selection <table-id>]`
- Filter state: `[:table-filter <table-id>]`
- Pagination: `[:table-pagination <table-id>]`

These are managed automatically by the table component. You typically don't need to access them directly - use `get-selected-ids` for selections and `table-filter` handles filter state.

## Common Patterns

### Pattern 1: Table with Filters and Multi-Selection

```clojure
(def table-id :query/browser-devices)

(def browser-table
  (table-component
   :query/browser-devices
   ["ID" "Name" "Status"]
   {"ID" (fn [row] [:span {:class ["font-mono"]} (:id row)])
    "Name" (fn [row] (:name row))
    "Status" (fn [row] (status-badge (:status row)))}
   {:table-id table-id
    :multi-selection? true
    :select-all? true
    :row->id :id}))

(defn filter-section [state]
  (table-filter state table-id
                [{:type :text :key :id :label "浏览器ID"}
                 {:type :text :key :name :label "名称"}]))

(defn render [state]
  (let [selected-ids (get-selected-ids state table-id :id)]
    [:div
     (when (seq selected-ids)
       [:button {:on {:click [[:batch/operation selected-ids]]}}
        "Batch Operation"])
     (filter-section state)
     (browser-table state)]))
```

### Pattern 2: Table with CRUD Actions

```clojure
(def config-table
  (table-component
   :query/script-config
   ["ID" "名称" "操作"]
   {"ID" :db/id
    "名称" :config/name
    "操作" (fn [row]
            [:div {:class ["flex" "gap-2"]}
             [:button {:on {:click [[:config/edit (:db/id row)]]}}
              "编辑"]
             [:button {:on {:click [[:config/delete {:id (:db/id row)}]]}}
              "删除"]])}
   {:table-id :query/script-config
    :row->id :db/id
    :on-new [[:config/edit :random]]}))
```

### Pattern 3: Custom Cell Rendering

```clojure
(def conversations-table
  (table-component
   :query/conversations
   ["ID" "用户名" "Has Reply" "创建时间"]
   {"ID" (fn [row] (:conversations/id row))
    "用户名" (fn [row] (:conversations/username row))
    "Has Reply" (fn [row]
                 (let [has-reply (:has_reply row)]
                   [:span {:class [(if (= 1 has-reply) "text-green-600" "text-gray-400")]}
                    (if (= 1 has-reply) "是" "否")]))
    "创建时间" (fn [row] (:conversations/created_at row))}
   {:table-id :query/conversations
    :row->id :conversations/id}))
```

## Router Integration

Tables are typically loaded via router actions:

```clojure
(defn get-location-load-actions [location]
  (case (:location/page-id location)
    :pages/my-page
    [[:data/query {:query/kind :query/my-data
                   :query/data {:page 1 :size 20}}]]
    nil))
```

## Important Notes

- **Query Kind**: The `query-kind` parameter must match a `:query/kind` handled by your query handler
- **Table ID**: Use a unique `:table-id` for each table to avoid state conflicts
- **Row ID**: The `:row->id` must uniquely identify each row (keyword or function)
- **Filter Keys**: Filter `:key` values are passed to query handler in `:query/data :filter` map
- **Store Access**: Don't directly access store paths - use provided functions like `get-selected-ids`
- **Pagination**: Handled automatically by the component based on `:page` and `:size` in query data
- **Filter Types**: Currently supports `:text` type filters (exact or partial match depends on query handler implementation)
- **Selection State**: Persists across re-renders and is stored in the global Replicant store

## References

- Replicant Component Library (internal)
- Replicant Main (state management)
- Examples in this codebase:
  - `components/browser-device/src/com/dx/browser_device/render.cljs`
  - `components/auto-sync-tiktok-pb-message/src/com/dx/auto_sync_tiktok_pb_message/render.cljs`
  - `components/whatsapp-account/src/com/dx/whatsapp_account/render.cljc`

