# HoneySQL Advanced Topics

This document covers advanced HoneySQL features including CTEs, subqueries, query composition, formatting options, and database integration.

## Common Table Expressions (CTEs)

CTEs allow you to define temporary named result sets that exist only for the duration of a query.

**Single CTE:**
```clojure
(sql/format {:with [[:active_users {:select [:*]
                                     :from [:users]
                                     :where [:= :status "active"]}]]
             :select [:*]
             :from [:active_users]
             :where [:> :age 18]})
```

**Multiple CTEs:**
```clojure
(sql/format {:with [[:active_users {:select [:*]
                                     :from [:users]
                                     :where [:= :status "active"]}]
                    [:recent_orders {:select [:*]
                                     :from [:orders]
                                     :where [:> :created_at [:raw "NOW() - INTERVAL '30 days'"]]}]]
             :select [:*]
             :from [:active_users]
             :join [:recent_orders] [:= :active_users.id :recent_orders.user_id]})
```

## Subqueries

Subqueries are nested query maps that can be used in various contexts.

**Subquery in WHERE clause:**
```clojure
(sql/format {:select [:name]
             :from [:users]
             :where [:in :id {:select [:user_id]
                             :from [:orders]
                             :where [:> :total 100]}]})
```

**Subquery in SELECT:**
```clojure
(sql/format {:select [:name
                     {:select [:%count.*]
                      :from [:orders]
                      :where [:= :orders.user_id :users.id]}]
             :from [:users]})
```

**Subquery as table:**
```clojure
(sql/format {:select [:*]
             :from [{:select [:id :name]
                     :from [:users]
                     :where [:= :status "active"]}]})
```

## Composing Queries

Since queries are just data structures, you can build them incrementally and combine them.

### Building Incrementally

**Using maps:**
```clojure
(let [base-query {:select [:*]
                   :from [:users]}]
  (sql/format (if active-only?
                (assoc base-query :where [:= :status "active"])
                base-query)))
```

**Using helper functions:**
```clojure
(let [base (-> (select :*)
               (from :users))]
  (-> base
      (cond-> active-only? (where [:= :status "active"]))
      (cond-> (some? min-age) (where [:> :age min-age]))
      sql/format))
```

### Merging Queries

```clojure
(let [query1 {:select [:id :name]
              :from [:users]}
      query2 {:where [:= :status "active"]}]
  (sql/format (merge query1 query2)))
```

### Conditional Clauses

```clojure
(defn build-user-query [filters]
  (-> (select :id :name :email)
      (from :users)
      (cond-> (:status filters) (where [:= :status (:status filters)]))
      (cond-> (:min-age filters) (where [:> :age (:min-age filters)]))
      (cond-> (:search filters) (where [:like :name (str "%" (:search filters) "%")]))
      sql/format))
```

## Formatting Options

### Pretty Printing

Format SQL with indentation for readability:

```clojure
(sql/format query {:pretty true})
```

### Dialect-Specific Formatting

HoneySQL supports multiple SQL dialects. Use the `:dialect` option for dialect-specific SQL generation:

```clojure
(sql/format query {:dialect :mysql})
(sql/format query {:dialect :postgres})
(sql/format query {:dialect :sqlserver})
(sql/format query {:dialect :oracle})
```

### Quote Identifiers

Use double quotes for identifiers:

```clojure
(sql/format query {:quoted true})
;; Uses double quotes: "users" instead of users
```

### Numbered Parameters

Use numbered parameters (PostgreSQL style: `$1`, `$2`, etc.):

```clojure
(sql/format query {:numbered true})
;; => ["SELECT * FROM users WHERE status = $1" "active"]
```

## Integration with next.jdbc

HoneySQL works seamlessly with `next.jdbc` for executing queries.

### Basic Integration

```clojure
(require '[next.jdbc :as jdbc]
         '[honey.sql :as sql])

(let [ds (jdbc/get-datasource db-spec)
      query {:select [:*]
             :from [:users]
             :where [:= :status "active"]}
      [sql-str & params] (sql/format query)]
  (jdbc/execute! ds (into [sql-str] params)))
```

### Using sqlvec Directly

`sql/format` returns a vector that can be passed directly to `jdbc/execute!`:

```clojure
(let [ds (jdbc/get-datasource db-spec)
      query {:select [:*]
             :from [:users]
             :where [:= :status "active"]}
      sqlvec (sql/format query)]
  (jdbc/execute! ds sqlvec))
```

### With Named Parameters

```clojure
(let [ds (jdbc/get-datasource db-spec)
      query {:select [:*]
             :from [:users]
             :where [:and
                     [:= :status [:param :status]]
                     [:> :age [:param :min_age]]]}
      sqlvec (sql/format query {:params {:status "active" :min_age 18}})]
  (jdbc/execute! ds sqlvec))
```

### Transaction Example

```clojure
(jdbc/with-transaction [tx ds]
  (let [insert-query {:insert-into :users
                      :values [{:name "John" :email "john@example.com"}]}
        [sql-str & params] (sql/format insert-query)]
    (jdbc/execute! tx (into [sql-str] params))
    
    (let [select-query {:select [:*]
                        :from [:users]
                        :where [:= :email "john@example.com"]}
          [sql-str & params] (sql/format select-query)]
      (jdbc/execute! tx (into [sql-str] params)))))
```

## Extensibility

HoneySQL allows you to extend its functionality with custom operators, functions, and clauses.

### Register Custom Operator

```clojure
(sql/register-op! :custom-op)
```

### Register Custom Function

```clojure
(sql/register-fn! :custom-fn)
```

### Register Custom Clause

```clojure
(sql/register-clause! :custom-clause)
```

## Best Practices

1. **Prefer parameterization**: Always use direct values or `[:param :name]` instead of `[:raw "..."]` when possible
2. **Use helper functions for complex queries**: They make query building more readable and composable
3. **Build queries incrementally**: Start with a base query and add conditions as needed
4. **Use CTEs for complex queries**: They improve readability for multi-step queries
5. **Specify dialect when needed**: Use `:dialect` option for database-specific features
6. **Test with pretty printing**: Use `{:pretty true}` during development to debug query structure

## Common Patterns

### Pagination

```clojure
(defn paginated-query [page page-size]
  (-> (select :*)
      (from :users)
      (order-by [:created_at :desc])
      (limit page-size)
      (offset (* (- page 1) page-size))
      sql/format))
```

### Search with Multiple Filters

```clojure
(defn search-users [filters]
  (let [base (-> (select :*)
                 (from :users))
        with-filters (reduce (fn [q [key val]]
                               (case key
                                 :status (where q [:= :status val])
                                 :min-age (where q [:> :age val])
                                 :search (where q [:like :name (str "%" val "%")])
                                 q))
                             base
                             filters)]
    (sql/format with-filters)))
```

### Upsert Pattern (PostgreSQL)

```clojure
(sql/format {:insert-into :users
             :values [{:id 1 :name "John" :email "john@example.com"}]
             :on-conflict [:id]
             :do-update-set {:name :excluded.name
                            :email :excluded.email}})
```

