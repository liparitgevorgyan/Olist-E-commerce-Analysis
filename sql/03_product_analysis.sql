-- =========================================================
-- 03. Product Analysis
-- =========================================================


-- =========================================================
-- 1. Top 10 products by revenue
-- =========================================================

SELECT 
    product_id,
    ROUND(SUM(price)::decimal, 2) AS revenue
FROM order_items
GROUP BY product_id
ORDER BY revenue DESC
LIMIT 10;


-- =========================================================
-- 2. Bottom 10 products by revenue
-- =========================================================

SELECT 
    product_id,
    ROUND(SUM(price)::decimal, 2) AS revenue
FROM order_items
GROUP BY product_id
ORDER BY revenue
LIMIT 10;


-- =========================================================
-- 3. Top 10 categories by revenue
-- =========================================================

SELECT
    category,
    ROUND(SUM(price)::decimal, 2) AS revenue_by_category,
    COUNT(DISTINCT order_id) AS count_order_category,
    COUNT(item_id) AS count_item,
    ROUND(AVG(price)::decimal, 2) AS avg_price_category
FROM (
    SELECT
        product_id,
        price,
        order_id,
        item_id,
        ct.product_category_name_english AS category
    FROM order_items
    LEFT JOIN products p USING (product_id)
    LEFT JOIN category_translation ct USING (product_category_name)
) t
GROUP BY category
ORDER BY revenue_by_category DESC
LIMIT 10;


-- =========================================================
-- 4. Bottom 10 categories by revenue
-- =========================================================

SELECT
    category,
    ROUND(SUM(price)::decimal, 2) AS revenue_by_category,
    COUNT(DISTINCT order_id) AS count_order_category,
    COUNT(item_id) AS count_item,
    ROUND(AVG(price)::decimal, 2) AS avg_price_category
FROM (
    SELECT
        product_id,
        price,
        order_id,
        item_id,
        ct.product_category_name_english AS category
    FROM order_items
    LEFT JOIN products p USING (product_id)
    LEFT JOIN category_translation ct USING (product_category_name)
) t
GROUP BY category
ORDER BY revenue_by_category
LIMIT 10;


-- =========================================================
-- 5. ABC analysis by product category
-- =========================================================

SELECT
    category,
    revenue_by_category,
    revenue_prt,
    cum_revenue_prt,
    CASE
        WHEN cum_revenue_prt < 80 THEN 'A'
        WHEN cum_revenue_prt > 95 THEN 'C'
        ELSE 'B'
    END AS abc
FROM (
    SELECT
        *,
        SUM(revenue_prt) OVER (
            ORDER BY revenue_prt DESC
        ) AS cum_revenue_prt
    FROM (
        SELECT
            category,
            revenue_by_category,
            ROUND(
                revenue_by_category /
                SUM(revenue_by_category) OVER() * 100,
                3
            ) AS revenue_prt
        FROM (
            SELECT
                category,
                ROUND(SUM(price)::decimal, 2) AS revenue_by_category
            FROM (
                SELECT
                    ct.product_category_name_english AS category,
                    price
                FROM order_items
                LEFT JOIN products p USING (product_id)
                LEFT JOIN category_translation ct
                    USING (product_category_name)
            ) t
            GROUP BY category
        ) t1
    ) t2
) t3
ORDER BY revenue_by_category DESC;


-- =========================================================
-- 6. ABC analysis by product
-- =========================================================

SELECT
    product_id,
    revenue,
    revenue_prt,
    cum_revenue,
    CASE
        WHEN cum_revenue < 80 THEN 'A'
        WHEN cum_revenue > 95 THEN 'C'
        ELSE 'B'
    END AS category_of_revenue
FROM (
    SELECT
        *,
        SUM(revenue_prt) OVER (
            ORDER BY revenue_prt DESC
        ) AS cum_revenue
    FROM (
        SELECT
            product_id,
            revenue,
            ROUND(
                revenue /
                SUM(revenue) OVER() * 100,
                3
            ) AS revenue_prt
        FROM (
            SELECT
                product_id,
                ROUND(SUM(price)::decimal, 2) AS revenue
            FROM order_items
            GROUP BY product_id
        ) t
    ) t1
) t2
ORDER BY revenue DESC;


-- =========================================================
-- 7. Number and share of products in each ABC group
-- =========================================================

SELECT
    category_of_revenue,
    COUNT(*) AS product_count,
    ROUND(
        COUNT(*)::decimal /
        SUM(COUNT(*)) OVER() * 100,
        2
    ) AS product_share_pct
FROM (
    SELECT
        product_id,
        CASE
            WHEN cum_revenue < 80 THEN 'A'
            WHEN cum_revenue > 95 THEN 'C'
            ELSE 'B'
        END AS category_of_revenue
    FROM (
        SELECT
            *,
            SUM(revenue_prt) OVER (
                ORDER BY revenue_prt DESC
            ) AS cum_revenue
        FROM (
            SELECT
                product_id,
                revenue,
                ROUND(
                    revenue /
                    SUM(revenue) OVER() * 100,
                    3
                ) AS revenue_prt
            FROM (
                SELECT
                    product_id,
                    ROUND(SUM(price)::decimal, 2) AS revenue
                FROM order_items
                GROUP BY product_id
            ) t
        ) t1
    ) t2
) t3
GROUP BY category_of_revenue
ORDER BY category_of_revenue;
