-- Check all tables loaded correctly
SELECT table_name, 
       pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) AS size
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Quick row count check
SELECT 'orders'      AS table_name, COUNT(*) AS rows FROM orders      UNION ALL
SELECT 'order_items'                              , COUNT(*) FROM order_items UNION ALL
SELECT 'customers'                                , COUNT(*) FROM customers   UNION ALL
SELECT 'products'                                 , COUNT(*) FROM products    UNION ALL
SELECT 'payments'                                 , COUNT(*) FROM payments    UNION ALL
SELECT 'reviews'                                  , COUNT(*) FROM reviews;


-- Monthly revenue trend with MoM growth rate
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
        COUNT(DISTINCT o.order_id)                       AS total_orders,
        ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    TO_CHAR(order_month, 'YYYY-MM')                        AS month,
    total_orders,
    revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY order_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0) * 100
    , 2)                                                   AS mom_growth_pct
FROM monthly
ORDER BY order_month;

--Top 10 products categorised by revenue
SELECT
    COALESCE(p.product_category_name, 'Unknown')   AS category,
    COUNT(DISTINCT o.order_id)                      AS total_orders,
    ROUND(SUM(oi.price)::NUMERIC, 2)               AS product_revenue,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2)       AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2)               AS avg_item_price,
    ROUND(AVG(r.review_score)::NUMERIC, 2)         AS avg_review_score
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
LEFT JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY total_revenue DESC
LIMIT 10;

--Customer state-vise performance

SELECT
    c.customer_state                                        AS state,
    COUNT(DISTINCT c.customer_unique_id)                    AS unique_customers,
    COUNT(DISTINCT o.order_id)                              AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2)    AS total_revenue,
    ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2)    AS avg_order_value,
    ROUND(AVG(r.review_score)::NUMERIC, 2)                 AS avg_satisfaction
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c    ON o.customer_id = c.customer_id
LEFT JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY total_revenue DESC
LIMIT 15;


--Delivery performance analysis

SELECT
    c.customer_state                                            AS state,
    COUNT(DISTINCT o.order_id)                                  AS total_orders,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (
            o.order_delivered_customer_date - o.order_purchase_timestamp
        )) / 86400
    )::NUMERIC, 1)                                              AS avg_delivery_days,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (
            o.order_estimated_delivery_date - o.order_delivered_customer_date
        )) / 86400
    )::NUMERIC, 1)                                              AS avg_days_early_late,
    SUM(CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
        THEN 1 ELSE 0
    END)                                                        AS on_time_deliveries,
    ROUND(
        SUM(CASE
            WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END) * 100.0 / COUNT(*), 1
    )                                                           AS on_time_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY avg_delivery_days DESC
LIMIT 15;

--Payment method breakdown

SELECT
    payment_type,
    COUNT(DISTINCT order_id)                            AS total_orders,
    ROUND(SUM(payment_value)::NUMERIC, 2)              AS total_value,
    ROUND(AVG(payment_value)::NUMERIC, 2)              AS avg_payment,
    ROUND(AVG(payment_installments)::NUMERIC, 1)       AS avg_installments,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2
    )                                                   AS pct_of_orders
FROM payments
GROUP BY 1
ORDER BY total_orders DESC;

--Review score vs Delivery speed

-- Does faster delivery = better reviews?
SELECT
    r.review_score,
    COUNT(*)                                            AS order_count,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (
            o.order_delivered_customer_date - o.order_purchase_timestamp
        )) / 86400
    )::NUMERIC, 1)                                      AS avg_delivery_days,
    ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN reviews r      ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY 1;

--RFM Segment(Important)

-- Step 1: Calculate raw RFM scores per customer
WITH rfm_base AS (
    SELECT
        c.customer_unique_id                                        AS customer_id,
        MAX(o.order_purchase_timestamp)::DATE                       AS last_order_date,
        COUNT(DISTINCT o.order_id)                                  AS frequency,
        ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2)        AS monetary,
        (SELECT MAX(order_purchase_timestamp)::DATE FROM orders)
            - MAX(o.order_purchase_timestamp)::DATE                 AS recency_days
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c    ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
),

-- Step 2: Score each metric 1-5 using NTILE
rfm_scores AS (
    SELECT
        customer_id,
        last_order_date,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC)  AS r_score, -- lower recency = better
        NTILE(5) OVER (ORDER BY frequency ASC)      AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)       AS m_score
    FROM rfm_base
),

-- Step 3: Combine into RFM score and label segments
rfm_segments AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        (r_score + f_score + m_score)               AS rfm_total,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3
                THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2
                THEN 'New Customers'
            WHEN r_score >= 3 AND f_score >= 2 AND m_score >= 3
                THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3
                THEN 'At Risk'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4
                THEN 'Cannot Lose Them'
            WHEN r_score <= 2 AND f_score <= 2
                THEN 'Lost / Hibernating'
            ELSE 'Needs Attention'
        END                                         AS segment
    FROM rfm_scores
)

-- Step 4: Segment summary
SELECT
    segment,
    COUNT(customer_id)                              AS customer_count,
    ROUND(AVG(recency_days), 0)                    AS avg_recency_days,
    ROUND(AVG(frequency), 1)                       AS avg_frequency,
    ROUND(AVG(monetary), 2)                        AS avg_monetary,
    ROUND(SUM(monetary), 2)                        AS total_revenue
FROM rfm_segments
GROUP BY 1
ORDER BY total_revenue DESC;


--Seller performance leaderboard

SELECT
    oi.seller_id,
    s.seller_state,
    COUNT(DISTINCT o.order_id)                          AS total_orders,
    ROUND(SUM(oi.price)::NUMERIC, 2)                   AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2)                   AS avg_price,
    ROUND(AVG(r.review_score)::NUMERIC, 2)             AS avg_review_score,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (
            o.order_delivered_customer_date - o.order_purchase_timestamp
        )) / 86400
    )::NUMERIC, 1)                                      AS avg_delivery_days
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s      ON oi.seller_id = s.seller_id
LEFT JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1, 2
HAVING COUNT(DISTINCT o.order_id) >= 50        -- only sellers with meaningful volume
ORDER BY total_revenue DESC
LIMIT 20;

