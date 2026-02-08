# HoneySQL Reference

Complete reference of all functions, operators, keywords, and core API in HoneySQL.

## Query Building (Helper Functions)

These functions return maps that can be formatted. They follow the HoneySQL 2.x style:

- `select` - Build SELECT clause
- `from` - Build FROM clause
- `where` - Build WHERE clause
- `join`, `left-join`, `right-join`, `full-join` - Build JOIN clauses
- `group-by` - Build GROUP BY clause
- `having` - Build HAVING clause
- `order-by` - Build ORDER BY clause
- `limit` - Build LIMIT clause
- `offset` - Build OFFSET clause
- `insert-into` - Build INSERT statement
- `values` - Build VALUES clause
- `update` - Build UPDATE statement
- `set` - Build SET clause
- `delete-from` - Build DELETE statement

**Example:**
```clojure
(require '[honey.sql.helpers :refer [select from where]])

(-> (select :id :name)
    (from :users)
    (where [:= :status "active"]))
```

## Map-Based DSL Keywords

These keywords are used in maps to build queries:

### Query Clauses
- `:select`, `:select-distinct` - SELECT clause
- `:from` - FROM clause
- `:where` - WHERE clause
- `:join`, `:left-join`, `:right-join`, `:full-join` - JOIN clauses
- `:group-by` - GROUP BY clause
- `:having` - HAVING clause
- `:order-by` - ORDER BY clause
- `:limit` - LIMIT clause
- `:offset` - OFFSET clause

### Data Modification
- `:insert-into` - INSERT statement
- `:values` - VALUES clause
- `:columns` - Column list for INSERT
- `:update` - UPDATE statement
- `:set` - SET clause
- `:delete-from` - DELETE statement

### Advanced
- `:with` - Common Table Expressions (CTEs)
- `:union`, `:union-all` - UNION clauses

**Example:**
```clojure
{:select [:id :name]
 :from [:users]
 :where [:= :status "active"]}
```

## Operators

### Comparison Operators
- `:=` - Equals
- `:not=` - Not equals
- `:>` - Greater than
- `:<` - Less than
- `:>=` - Greater than or equal
- `:<=` - Less than or equal
- `:between` - Between values
- `:in` - In list
- `:not-in` - Not in list
- `:like` - LIKE pattern matching
- `:ilike` - Case-insensitive LIKE (PostgreSQL)
- `:is-null` - IS NULL
- `:is-not-null` - IS NOT NULL

### Logical Operators
- `:and` - Logical AND
- `:or` - Logical OR
- `:not` - Logical NOT

**Examples:**
```clojure
[:= :status "active"]
[:> :age 18]
[:in :status ["active" "pending"]]
[:and [:= :status "active"] [:> :age 18]]
```

## Aggregation Functions

- `:%count` - COUNT
- `:%sum` - SUM
- `:%avg` - AVG
- `:%max` - MAX
- `:%min` - MIN

**Examples:**
```clojure
[:%count.* :total]
[:%sum :price :total_price]
[:%avg :rating :avg_rating]
```

## Core Functions

### `sql/format`
Convert a query map to `[sql-string & params]`.

```clojure
(sql/format {:select [:*] :from [:users]})
;; => ["SELECT * FROM users"]

(sql/format query {:params {:status "active"}})
(sql/format query {:dialect :postgres})
(sql/format query {:pretty true})
(sql/format query {:numbered true})
(sql/format query {:quoted true})
```

**Options:**
- `:params` - Map of named parameters
- `:dialect` - SQL dialect (`:mysql`, `:postgres`, `:sqlserver`, etc.)
- `:pretty` - Pretty print SQL
- `:numbered` - Use numbered parameters (PostgreSQL style: `$1`, `$2`)
- `:quoted` - Quote identifiers with double quotes

### `sql/format-expr`
Format a single expression.

```clojure
(sql/format-expr [:= :status "active"])
;; => ["status = ?" "active"]
```

### `sql/register-op!`
Register a custom operator.

```clojure
(sql/register-op! :custom-op)
```

### `sql/register-fn!`
Register custom function syntax.

```clojure
(sql/register-fn! :custom-fn)
```

### `sql/register-clause!`
Register a custom SQL clause.

```clojure
(sql/register-clause! :custom-clause)
```

## Identifier Syntax

- **Keywords**: Use keywords for table/column names
  ```clojure
  :users
  :name
  ```

- **Aliases**: Use vectors for aliases
  ```clojure
  [:users :u]        ; table alias
  [:name :user_name] ; column alias
  ```

- **Qualified names**: Use vectors for qualified identifiers
  ```clojure
  [:users.id]
  [:schema.table]
  ```

## Parameter Syntax

- **Direct values**: Automatically parameterized
  ```clojure
  [:= :status "active"]  ; => "status = ?" with param "active"
  ```

- **Named parameters**: Use `[:param :name]`
  ```clojure
  [:= :status [:param :status]]
  ;; Then provide in format options:
  {:params {:status "active"}}
  ```

- **Raw SQL**: Use `[:raw "..."]` (use with caution)
  ```clojure
  [:raw "NOW()"]
  [:raw "INTERVAL '7 days'"]
  ```

## Subquery Syntax

Subqueries are just nested query maps. They work anywhere a table reference would work:

```clojure
{:select [:name]
 :from [:users]
 :where [:in :id {:select [:user_id]
                  :from [:orders]
                  :where [:> :total 100]}]}
```

## NULL Handling

Use `:is-null` and `:is-not-null` operators, not `:= nil`:

```clojure
[:is-null :deleted_at]
[:is-not-null :email]
;; NOT: [:= :deleted_at nil]
```

