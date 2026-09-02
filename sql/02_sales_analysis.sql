-- 02. Sales Analysis
-- Analysis of monthly sales dynamics and revenue changes

-- =========================================================
-- 1. Monthly sales dynamics
-- =========================================================

SELECT
    DATE_TRUNC('month', created_at)::date AS month,
    COUNT(DISTINCT orders.order_id) AS orders,
    ROUND(SUM(o.price)::numeric, 2) AS revenue,
    ROUND(
        SUM(o.price)::numeric /
        COUNT(DISTINCT orders.order_id),
        2
    ) AS average_order_value
FROM orders
LEFT JOIN order_items o USING (order_id)
GROUP BY month
ORDER BY month;


-- =========================================================
-- 2. Month-over-month revenue growth
-- =========================================================

SELECT
    month,
    orders,
    revenue,
    revenue - LAG(revenue) OVER (ORDER BY month) AS revenue_change,
    ROUND(
        (
            revenue - LAG(revenue) OVER (ORDER BY month)
        )
        / LAG(revenue) OVER (ORDER BY month) * 100,
        2
    ) AS revenue_growth_pct,
    average_order_value
FROM (
    SELECT
        DATE_TRUNC('month', created_at)::date AS month,
        COUNT(DISTINCT orders.order_id) AS orders,
        ROUND(SUM(o.price)::numeric, 2) AS revenue,
        ROUND(
            SUM(o.price)::numeric /
            COUNT(DISTINCT orders.order_id),
            2
        ) AS average_order_value
    FROM orders
    LEFT JOIN order_items o USING (order_id)
    GROUP BY month
) t
ORDER BY month;


-- =========================================================
-- 3. Top 3 months by revenue growth
-- =========================================================

WITH sales AS (
    SELECT
        DATE_TRUNC('month', created_at)::date AS month,
        COUNT(DISTINCT orders.order_id) AS orders,
        ROUND(SUM(o.price)::numeric, 2) AS revenue,
        ROUND(
            SUM(o.price)::numeric /
            COUNT(DISTINCT orders.order_id),
            2
        ) AS average_order_value
    FROM orders
    LEFT JOIN order_items o USING (order_id)
    GROUP BY month
),
growth AS (
    SELECT
        month,
        orders,
        revenue,
        average_order_value,
        revenue - LAG(revenue) OVER (ORDER BY month) AS revenue_change,
        ROUND(
            (
                revenue - LAG(revenue) OVER (ORDER BY month)
            )
            / LAG(revenue) OVER (ORDER BY month) * 100,
            2
        ) AS revenue_growth_pct
    FROM sales
)
SELECT *
FROM growth
WHERE revenue_growth_pct IS NOT NULL
  AND month BETWEEN '2017-01-01' AND '2018-08-01'
ORDER BY revenue_growth_pct DESC
LIMIT 3;


-- =========================================================
-- 4. Top 3 months by revenue decline
-- =========================================================

WITH sales AS (
    SELECT
        DATE_TRUNC('month', created_at)::date AS month,
        COUNT(DISTINCT orders.order_id) AS orders,
        ROUND(SUM(o.price)::numeric, 2) AS revenue,
        ROUND(
            SUM(o.price)::numeric /
            COUNT(DISTINCT orders.order_id),
            2
        ) AS average_order_value
    FROM orders
    LEFT JOIN order_items o USING (order_id)
    GROUP BY month
),
growth AS (
    SELECT
        month,
        orders,
        revenue,
        average_order_value,
        revenue - LAG(revenue) OVER (ORDER BY month) AS revenue_change,
        ROUND(
            (
                revenue - LAG(revenue) OVER (ORDER BY month)
            )
            / LAG(revenue) OVER (ORDER BY month) * 100,
            2
        ) AS revenue_growth_pct
    FROM sales
)
SELECT *
FROM growth
WHERE revenue_growth_pct IS NOT NULL
  AND month BETWEEN '2017-01-01' AND '2018-08-01'
ORDER BY revenue_growth_pct
LIMIT 3;
