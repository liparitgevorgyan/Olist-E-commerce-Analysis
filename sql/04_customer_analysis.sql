-- =========================================================
-- 04. Customer Analysis
-- Analysis of customer activity and repeat purchases
-- =========================================================

-- 1. Order status distribution

SELECT
    status,
    COUNT(DISTINCT order_id) AS count_orders
FROM orders
GROUP BY status
ORDER BY count_orders DESC;

-- 2. Distribution of customers by number of orders

SELECT
    count_order_users AS orders_per_user,
    COUNT(*) AS count_users
FROM (
    SELECT
        c.user_unq_id,
        COUNT(DISTINCT order_id) AS count_order_users
    FROM customers c
    LEFT JOIN orders USING (user_id)
    GROUP BY c.user_unq_id
) t
GROUP BY count_order_users
ORDER BY orders_per_user;


-- 3. One-time / repeat customers


SELECT
    COUNT(user_unq_id) FILTER (
        WHERE count_order_users = 1
    ) AS count_user_one_time,

    COUNT(user_unq_id) FILTER (
        WHERE count_order_users > 1
    ) AS count_user_repeat_time,

    COUNT(*) AS all_customers
FROM (
    SELECT
        c.user_unq_id,
        COUNT(DISTINCT order_id) AS count_order_users
    FROM customers c
    LEFT JOIN orders USING (user_id)
    GROUP BY user_unq_id
) t;


-- 4. Share of one-time and repeat customers


SELECT
    count_user_one_time / all_customers::decimal * 100
        AS one_time_purchase_pct,

    count_user_repeat_time / all_customers::decimal * 100
        AS repeat_purchase_pct
FROM (
    SELECT
        COUNT(user_unq_id) FILTER (
            WHERE count_order_users = 1
        ) AS count_user_one_time,

        COUNT(user_unq_id) FILTER (
            WHERE count_order_users > 1
        ) AS count_user_repeat_time,

        COUNT(*) AS all_customers
    FROM (
        SELECT
            c.user_unq_id,
            COUNT(DISTINCT order_id) AS count_order_users
        FROM customers c
        LEFT JOIN orders USING (user_id)
        GROUP BY user_unq_id
    ) t
) t1;


-- 5. Top 10 customers by revenue


SELECT
    c.user_unq_id,
    SUM(price) AS customer_revenue
FROM order_items
LEFT JOIN orders USING (order_id)
LEFT JOIN customers c USING (user_id)
GROUP BY user_unq_id
ORDER BY customer_revenue DESC
LIMIT 10;

-- 6. Repeat purchase rate for completed purchases
--
-- Only delivered orders are considered completed purchases.

SELECT
    COUNT(*) FILTER (
        WHERE count_purchases = 1
    ) AS one_time_customers,

    COUNT(*) FILTER (
        WHERE count_purchases > 1
    ) AS repeat_customers,

    COUNT(*) AS all_customers,

    ROUND(
        COUNT(*) FILTER (
            WHERE count_purchases > 1
        ) / COUNT(*)::decimal * 100,
        2
    ) AS repeat_purchase_pct
FROM (
    SELECT
        c.user_unq_id,
        COUNT(DISTINCT o.order_id) AS count_purchases
    FROM customers c
    LEFT JOIN orders o
        ON c.user_id = o.user_id
        AND o.status = 'delivered'
    GROUP BY c.user_unq_id
) t;


-- 7. Monthly number of active customers
--
-- A customer is considered active if they made
-- at least one completed purchase during the month.

SELECT
    DATE_TRUNC('month', o.created_at)::date AS month,
    COUNT(DISTINCT c.user_unq_id) AS active_customers
FROM orders o
LEFT JOIN customers c USING (user_id)
WHERE o.status = 'delivered'
GROUP BY month
ORDER BY month;


-- 8. First completed purchase for each customer
--
-- Determines the cohort month of each customer.

SELECT
    user_unq_id,
    MIN(DATE_TRUNC('month', created_at)::date) AS cohort_month
FROM (
    SELECT
        c.user_unq_id,
        o.created_at
    FROM customers c
    JOIN orders o USING (user_id)
    WHERE o.status = 'delivered'
) t
GROUP BY user_unq_id;


-- 9. Customer retention by cohort
--
-- Cohort = month of the customer's first completed purchase.
-- Retention = share of customers from the cohort
-- who made a completed purchase in subsequent months.

WITH customer_cohorts AS (
    SELECT
        c.user_unq_id,
        MIN(DATE_TRUNC('month', o.created_at)::date) AS cohort_month
    FROM customers c
    JOIN orders o USING (user_id)
    WHERE o.status = 'delivered'
    GROUP BY c.user_unq_id
),

customer_activity AS (
    SELECT DISTINCT
        c.user_unq_id,
        DATE_TRUNC('month', o.created_at)::date AS activity_month
    FROM customers c
    JOIN orders o USING (user_id)
    WHERE o.status = 'delivered'
),

cohort_activity AS (
    SELECT
        cc.cohort_month,
        ca.activity_month,
        COUNT(DISTINCT ca.user_unq_id) AS active_customers
    FROM customer_cohorts cc
    JOIN customer_activity ca
        ON cc.user_unq_id = ca.user_unq_id
    GROUP BY
        cc.cohort_month,
        ca.activity_month
),

cohort_size AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_customers
    FROM customer_cohorts
    GROUP BY cohort_month
)

SELECT
    ca.cohort_month,
    ca.activity_month,
    ca.active_customers,
    cs.cohort_customers,
    ROUND(
        ca.active_customers / cs.cohort_customers::decimal * 100,
        2
    ) AS retention_pct
FROM cohort_activity ca
JOIN cohort_size cs
    USING (cohort_month)
ORDER BY
    ca.cohort_month,
    ca.activity_month;
