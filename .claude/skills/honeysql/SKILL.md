---
name: honeysql
description: Turn Clojure data structures into SQL. Use this when you need to build SQL queries programmatically, avoid SQL injection, or compose dynamic queries in a safe and composable way.
---

# HoneySQL - SQL Query Builder for Clojure

## When to Use This Skill

Use this skill when you need to:
- **Build SQL queries programmatically** from Clojure data structures
- **Avoid SQL injection** by using parameterized queries
- **Compose dynamic queries** based on runtime conditions
- **Write database-agnostic queries** that work across different SQL dialects
- **Build complex queries** with joins, subqueries, CTEs, and more
- **Extend SQL syntax** for database-specific features

## How It Works

HoneySQL converts Clojure data structures (maps and vectors) into SQL. It supports both a **map-based DSL** and **helper functions** for building queries. Queries are built as data structures and then formatted into SQL strings with parameter placeholders.

**Key concepts:**
- **Map-based DSL**: Build queries using maps with keywords like `:select`, `:from`, `:where`, etc.
- **Helper functions**: Use functions like `select`, `from`, `where` that return maps (HoneySQL 2.x style)
- **Formatting**: Use `sql/format` to convert the data structure into `[sql-string & params]`
- **Parameters**: Values are automatically parameterized to prevent SQL injection
- **Composability**: Queries can be built incrementally and combined

## Quick Start

### Setup

Add HoneySQL to your dependencies:

```clojure
;; deps.edn
{:deps {com.github.seancorfield/honeysql {:mvn/version "2.7.1364"}}}
```

Require the namespace:

```clojure
(require '[honey.sql :as sql])
;; For helper functions (HoneySQL 2.x style):
(require '[honey.sql.helpers :refer [select from where insert-into values update set delete-from]])
```

### Basic Example

**Using map-based DSL:**
```clojure
(sql/format {:select [:id :name :email]
             :from [:users]
             :where [:= :status "active"]})
;; => ["SELECT id, name, email FROM users WHERE status = ?" "active"]
```

**Using helper functions:**
```clojure
(-> (select :id :name :email)
    (from :users)
    (where [:= :status "active"])
    sql/format)
;; => ["SELECT id, name, email FROM users WHERE status = ?" "active"]
```

### Typical Workflow

1. **Require HoneySQL:**
   ```clojure
   (require '[honey.sql :as sql]
            '[honey.sql.helpers :refer [select from where]])
   ```

2. **Build query as data structure:**
   ```clojure
   (def query (-> (select :id :name :email)
                 (from :users)
                 (where [:= :status "active"])))
   ```

3. **Format to SQL:**
   ```clojure
   (let [[sql-str & params] (sql/format query)]
     (jdbc/execute! datasource (into [sql-str] params)))
   ```

## Detailed Documentation

For comprehensive examples and reference material, see:

- **[QUERIES.md](QUERIES.md)** - Detailed query examples: SELECT, INSERT, UPDATE, DELETE, JOINs, WHERE clauses, aggregations, and more
- **[REFERENCE.md](REFERENCE.md)** - Complete reference of all functions, operators, keywords, and core API
- **[ADVANCED.md](ADVANCED.md)** - Advanced topics: CTEs, subqueries, query composition, formatting options, and next.jdbc integration

## Important Notes

- **Parameterization**: All values are automatically parameterized to prevent SQL injection. Use `[:param :name]` for named parameters or `[:raw "..."]` for raw SQL (use with caution).
- **Helper functions vs Maps**: Helper functions (HoneySQL 2.x) return maps that can be formatted. Both approaches are equivalent - choose based on preference.
- **Composability**: Queries are just data structures - merge, assoc, update as needed before formatting.
- **Dialects**: HoneySQL supports multiple SQL dialects. Use `:dialect` option in `format` for dialect-specific SQL generation.
- **Raw SQL**: Use `[:raw "..."]` sparingly and only when necessary. It bypasses parameterization and can lead to SQL injection if not careful.
- **Identifiers**: Use keywords for table/column names. Use vectors for aliases: `[:table :alias]` or `[:column :alias]`.
- **Subqueries**: Subqueries are just nested query maps - they work anywhere a table reference would work.
- **NULL handling**: Use `:is-null` and `:is-not-null` operators, not `:= nil`.
- **Extensibility**: You can register custom operators, functions, and clauses using `register-op!`, `register-fn!`, and `register-clause!`.

## References

- [HoneySQL GitHub Repository](https://github.com/seancorfield/honeysql)
- [HoneySQL Documentation on cljdoc](https://cljdoc.org/d/com.github.seancorfield/honeysql/CURRENT)
