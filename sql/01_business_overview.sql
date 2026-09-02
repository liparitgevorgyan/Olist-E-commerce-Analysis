-- 01. Business overview
-- Key metrics for the entire Olist dataset

SELECT
    'count_orders' AS metric,
    COUNT(DISTINCT order_id) AS value
FROM orders

UNION ALL

SELECT
    'count_users',
    COUNT(DISTINCT user_unq_id)
FROM customers

UNION ALL

SELECT
    'count_items',
    COUNT(item_id)
FROM order_items

UNION ALL

SELECT
    'count_products',
    COUNT(DISTINCT product_id)
FROM products

UNION ALL

SELECT
    'count_sellers',
    COUNT(DISTINCT seller_id)
FROM order_items;
