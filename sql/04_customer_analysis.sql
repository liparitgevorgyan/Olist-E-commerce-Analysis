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
