-- Opportunity Assessment


-- Phase 8 - Step 1: Build a category-level opportunity metrics table
-- Phase 8 - 第一步：建立 Category 层面的机会评估指标表

WITH category_app_stats AS (
    SELECT
        c.id AS category_id,
        c.title AS category,
        COUNT(DISTINCT ac.app_id) AS app_count,
        COUNT(DISTINCT a.developer) AS developer_count,
        AVG(a.rating) AS avg_rating
    FROM apps_categories ac
    JOIN categories c
        ON ac.category_id = c.id
    JOIN apps a
        ON ac.app_id = a.id
    WHERE a.rating IS NOT NULL
    GROUP BY c.id, c.title
),

category_review_stats AS (
    SELECT
        ac.category_id,
        COUNT(*) AS review_count,
        SUM(
            CASE
                WHEN r.rating = 1 THEN 1
                ELSE 0
            END
        ) AS one_star_reviews
    FROM apps_categories ac
    JOIN reviews r
        ON ac.app_id = r.app_id
    GROUP BY ac.category_id
)

SELECT TOP 30
    cas.category,
    cas.app_count,
    cas.developer_count,
    crs.review_count,

    CAST(
        crs.review_count * 1.0 / cas.app_count
        AS DECIMAL(10,2)
    ) AS reviews_per_app,

    CAST(
        cas.avg_rating
        AS DECIMAL(4,2)
    ) AS avg_rating,

    CAST(
        crs.one_star_reviews * 100.0 / crs.review_count
        AS DECIMAL(5,2)
    ) AS one_star_rate_pct

FROM category_app_stats cas
JOIN category_review_stats crs
    ON cas.category_id = crs.category_id

WHERE
    cas.app_count >= 50
    AND crs.review_count >= 1000

ORDER BY crs.review_count DESC;


-- Phase 8 - Step 2: Build the complete category opportunity metrics table
-- Phase 8 - 第二步：建立完整的 Category 机会评估指标表

WITH category_app_stats AS (
    SELECT
        c.id AS category_id,
        c.title AS category,
        COUNT(DISTINCT ac.app_id) AS app_count,
        COUNT(DISTINCT a.developer) AS developer_count,
        AVG(a.rating) AS avg_rating
    FROM apps_categories ac
    JOIN categories c
        ON ac.category_id = c.id
    JOIN apps a
        ON ac.app_id = a.id
    WHERE a.rating IS NOT NULL
    GROUP BY c.id, c.title
),

category_review_stats AS (
    SELECT
        ac.category_id,
        COUNT(*) AS review_count,

        SUM(
            CASE
                WHEN r.rating = 1 THEN 1
                ELSE 0
            END
        ) AS one_star_reviews,

        SUM(
            CASE
                WHEN r.has_developer_reply = 1 THEN 1
                ELSE 0
            END
        ) AS replied_reviews
    FROM apps_categories ac
    JOIN reviews r
        ON ac.app_id = r.app_id
    GROUP BY ac.category_id
),

app_review_counts AS (
    SELECT
        ac.category_id,
        ac.app_id,
        COUNT(r.rating) AS app_review_count
    FROM apps_categories ac
    LEFT JOIN reviews r
        ON ac.app_id = r.app_id
    GROUP BY ac.category_id, ac.app_id
),

category_concentration AS (
    SELECT
        category_id,
        SUM(app_review_count) AS total_reviews,
        MAX(app_review_count) AS top_app_reviews
    FROM app_review_counts
    GROUP BY category_id
),

category_pricing_base AS (
    SELECT
        ac.category_id,
        pp.price_type,
        pp.price_amount
    FROM apps_categories ac
    JOIN pricing_plans pp
        ON ac.app_id = pp.app_id
),

category_free_entry AS (
    SELECT
        category_id,
        COUNT(*) AS total_plan_count,

        SUM(
            CASE
                WHEN price_type IN ('free', 'free_to_install') THEN 1
                ELSE 0
            END
        ) AS free_entry_plan_count
    FROM category_pricing_base
    GROUP BY category_id
),

category_monthly_prices AS (
    SELECT
        category_id,
        price_amount
    FROM category_pricing_base
    WHERE price_type = 'monthly'
      AND price_amount IS NOT NULL
),

category_price_stats AS (
    SELECT DISTINCT
        category_id,

        COUNT(*) OVER (
            PARTITION BY category_id
        ) AS monthly_plan_count,

        PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY price_amount)
            OVER (PARTITION BY category_id) AS median_monthly_price

    FROM category_monthly_prices
)

SELECT TOP 30
    cas.category,

    cas.app_count,
    cas.developer_count,

    crs.review_count,

    CAST(
        crs.review_count * 1.0 / cas.app_count
        AS DECIMAL(10,2)
    ) AS reviews_per_app,

    CAST(
        cas.avg_rating
        AS DECIMAL(4,2)
    ) AS avg_rating,

    CAST(
        crs.one_star_reviews * 100.0 / crs.review_count
        AS DECIMAL(5,2)
    ) AS one_star_rate_pct,

    CAST(
        crs.replied_reviews * 100.0 / crs.review_count
        AS DECIMAL(5,2)
    ) AS reply_rate_pct,

    cps.monthly_plan_count,

    CAST(
        cps.median_monthly_price
        AS DECIMAL(10,2)
    ) AS median_monthly_price,

    CAST(
        cfe.free_entry_plan_count * 100.0
        / NULLIF(cfe.total_plan_count, 0)
        AS DECIMAL(5,2)
    ) AS free_entry_share_pct,

    CAST(
        cc.top_app_reviews * 100.0
        / NULLIF(cc.total_reviews, 0)
        AS DECIMAL(5,2)
    ) AS top_app_review_share_pct

FROM category_app_stats cas

JOIN category_review_stats crs
    ON cas.category_id = crs.category_id

LEFT JOIN category_concentration cc
    ON cas.category_id = cc.category_id

LEFT JOIN category_free_entry cfe
    ON cas.category_id = cfe.category_id

LEFT JOIN category_price_stats cps
    ON cas.category_id = cps.category_id

WHERE
    cas.app_count >= 50
    AND crs.review_count >= 1000

ORDER BY crs.review_count DESC;