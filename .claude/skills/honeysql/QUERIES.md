# HoneySQL Query Examples

This document provides detailed examples for building various types of SQL queries with HoneySQL.

## 1. Basic SELECT Queries

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

**With multiple conditions:**
```clojure
(sql/format {:select [:*]
             :from [:users]
             :where [:and
                     [:= :status "active"]
                     [:> :age 18]
                     [:like :name "%john%"]]})
```

## 2. Joins

**Inner join:**
```clojure
(sql/format {:select [:u.name :p.title]
             :from [[:users :u]]
             :join [[:posts :p] [:= :u.id :p.user_id]]})
```

**Left/Right/Full outer joins:**
```clojure
(sql/format {:select [:u.name :p.title]
             :from [[:users :u]]
             :left-join [[:posts :p] [:= :u.id :p.user_id]]
             :right-join [[:comments :c] [:= :p.id :c.post_id]]
             :full-join [[:tags :t] [:= :p.id :t.post_id]]})
```

**Multiple joins:**
```clojure
(-> (select :u.name :p.title)
    (from [:users :u])
    (join [:posts :p] [:= :u.id :p.user_id])
    (join [:comments :c] [:= :p.id :c.post_id])
    sql/format)
```

## 3. WHERE Clauses

**Comparison operators:**
```clojure
;; Equals
[:= :status "active"]
[:= :id 42]

;; Not equals
[:not= :status "deleted"]

;; Comparison
[:> :age 18]
[:< :price 100]
[:>= :score 80]
[:<= :quantity 10]

;; Between
[:between :age 18 65]

;; In
[:in :status ["active" "pending" "approved"]]

;; Like
[:like :name "%john%"]
[:ilike :email "%@example.com"]  ; case-insensitive (PostgreSQL)

;; Is null / Is not null
[:is-null :deleted_at]
[:is-not-null :email]
```

**Logical operators:**
```clojure
;; AND
[:and [:= :status "active"] [:> :age 18]]

;; OR
[:or [:= :status "active"] [:= :status "pending"]]

;; NOT
[:not [:= :status "deleted"]]

;; Complex combinations
[:and
 [:= :status "active"]
 [:or
  [:> :age 18]
  [:= :role "admin"]]]
```

## 4. ORDER BY, LIMIT, OFFSET

```clojure
(sql/format {:select [:*]
             :from [:users]
             :order-by [[:created_at :desc] :name]
             :limit 10
             :offset 20})
```

**Multiple order by:**
```clojure
(sql/format {:select [:*]
             :from [:users]
             :order-by [[:status :desc]
                       [:name :asc]
                       [:created_at :nulls-first]]})
```

## 5. GROUP BY and HAVING

```clojure
(sql/format {:select [:status [:%count.* :count]]
             :from [:users]
             :group-by :status
             :having [:> :count 5]})
```

## 6. INSERT Statements

**Simple insert:**
```clojure
(sql/format {:insert-into :users
             :values [{:name "John" :email "john@example.com" :age 30}]})
;; => ["INSERT INTO users (name, email, age) VALUES (?, ?, ?)" "John" "john@example.com" 30]
```

**Multiple rows:**
```clojure
(sql/format {:insert-into :users
             :values [{:name "John" :email "john@example.com"}
                     {:name "Jane" :email "jane@example.com"}]})
```

**Insert with select:**
```clojure
(sql/format {:insert-into :users
             :columns [:name :email]
             :values {:select [:name :email]
                     :from [:temp_users]}})
```

**Using helper functions:**
```clojure
(-> (insert-into :users)
    (values [{:name "John" :email "john@example.com"}])
    sql/format)
```

## 7. UPDATE Statements

```clojure
(sql/format {:update :users
             :set {:status "active" :updated_at [:raw "NOW()"]}
             :where [:= :id 42]})
;; => ["UPDATE users SET status = ?, updated_at = NOW() WHERE id = ?" "active" 42]
```

**Using helper functions:**
```clojure
(-> (update :users)
    (set {:status "active"})
    (where [:= :id 42])
    sql/format)
```

## 8. DELETE Statements

```clojure
(sql/format {:delete-from :users
             :where [:= :status "deleted"]})
;; => ["DELETE FROM users WHERE status = ?" "deleted"]
```

**Using helper functions:**
```clojure
(-> (delete-from :users)
    (where [:= :status "deleted"])
    sql/format)
```

## 9. Aggregations and Functions

```clojure
(sql/format {:select [[:%count.* :total]
                     [:%sum :price :total_price]
                     [:%avg :rating :avg_rating]
                     [:%max :created_at :latest]
                     [:%min :price :cheapest]]
             :from [:products]})
```

**Custom expressions:**
```clojure
(sql/format {:select [[[:raw "CONCAT(first_name, ' ', last_name)"] :full_name]
                     [[:raw "EXTRACT(YEAR FROM created_at)"] :year]]
             :from [:users]})
```

## 10. Aliases

**Column aliases:**
```clojure
(sql/format {:select [[:u.name :user_name]
                     [:p.title :post_title]]
             :from [[:users :u]]
             :join [[:posts :p] [:= :u.id :p.user_id]]})
```

**Table aliases:**
```clojure
(sql/format {:select [:u.* :p.*]
             :from [[:users :u]]
             :join [[:posts :p] [:= :u.id :p.user_id]]})
```

## 11. DISTINCT

```clojure
(sql/format {:select-distinct [:status]
             :from [:users]})
```

## 12. UNION

```clojure
(sql/format {:union [{:select [:name] :from [:users]}
                     {:select [:title] :from [:posts]}]})
```

## 13. Parameters

**Named parameters:**
```clojure
(sql/format {:select [:*]
             :from [:users]
             :where [:= :status [:param :status]]}
            {:params {:status "active"}})
;; => ["SELECT * FROM users WHERE status = ?" "active"]
```

**Multiple parameters:**
```clojure
(sql/format {:select [:*]
             :from [:users]
             :where [:and
                     [:= :status [:param :status]]
                     [:> :age [:param :min_age]]]}
            {:params {:status "active" :min_age 18}})
```

**Numbered parameters (PostgreSQL style):**
```clojure
(sql/format {:select [:*]
             :from [:users]
             :where [:= :status [:param :status]]}
            {:params {:status "active"}
             :numbered true})
;; => ["SELECT * FROM users WHERE status = $1" "active"]
```

## 14. Raw SQL

**Raw expressions:**
```clojure
(sql/format {:select [[[:raw "NOW()"] :current_time]
                     [[:raw "@x := 10"] :variable]]
             :from [:users]})
```

**Raw in WHERE:**
```clojure
(sql/format {:select [:*]
             :from [:users]
             :where [[:raw "created_at > NOW() - INTERVAL '7 days'"]]})
```

**Note**: Use `[:raw "..."]` sparingly and only when necessary. It bypasses parameterization and can lead to SQL injection if not careful.

