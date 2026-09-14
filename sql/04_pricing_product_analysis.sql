-- Pricing & Product Analysis


-- Question 1: What pricing models are most common in the Shopify App Marketplace?
-- 问题 1：Shopify App Marketplace 中最常见的定价模式有哪些？

SELECT
    price_type,
    COUNT(*) AS plan_count
FROM pricing_plans
GROUP BY price_type
ORDER BY plan_count DESC;


-- Question 2: What percentage of pricing plans does each pricing model represent?
-- 问题 2：不同定价模式分别占所有 Pricing Plans 的多少比例？

SELECT
    price_type,
    COUNT(*) AS plan_count,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS percentage
FROM pricing_plans
GROUP BY price_type
ORDER BY plan_count DESC;


-- Question 3: What is the typical monthly price range for Shopify App pricing plans?
-- 问题 3：Shopify App 的月付 Pricing Plan 通常处于什么价格区间？

SELECT
    COUNT(*) AS monthly_plan_count,
    CAST(AVG(price_amount) AS DECIMAL(10,2)) AS avg_monthly_price,
    MIN(price_amount) AS min_monthly_price,
    MAX(price_amount) AS max_monthly_price
FROM pricing_plans
WHERE price_type = 'monthly'
  AND price_amount IS NOT NULL;


-- Question 4: Are there potential outliers in monthly pricing plans?
-- 问题 4：月付 Pricing Plans 中是否存在潜在的价格异常值？

-- 4.1 Show the 20 highest monthly prices
-- 4.1 查看价格最高的 20 个 Monthly Plans

SELECT TOP 20
    app_id,
    title,
    price,
    price_amount
FROM pricing_plans
WHERE price_type = 'monthly'
  AND price_amount IS NOT NULL
ORDER BY price_amount DESC;


-- 4.2 How many monthly plans have a price of $0?
-- 4.2 有多少个月付计划的价格为 $0？

SELECT
    COUNT(*) AS zero_price_monthly_plans
FROM pricing_plans
WHERE price_type = 'monthly'
  AND price_amount = 0;


-- Question 5: What is the median monthly price for Shopify App pricing plans?
-- 问题 5：Shopify App 月付 Pricing Plan 的价格中位数是多少？

SELECT DISTINCT
    CAST(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY price_amount)
        OVER ()
        AS DECIMAL(10,2)
    ) AS median_monthly_price
FROM pricing_plans
WHERE price_type = 'monthly'
  AND price_amount IS NOT NULL;


-- Question 6: How are monthly pricing plans distributed across price ranges?
-- 问题 6：月付 Pricing Plans 主要分布在哪些价格区间？

SELECT
    CASE
        WHEN price_amount < 10 THEN 'Under $10'
        WHEN price_amount < 20 THEN '$10-$19.99'
        WHEN price_amount < 50 THEN '$20-$49.99'
        WHEN price_amount < 100 THEN '$50-$99.99'
        WHEN price_amount < 500 THEN '$100-$499.99'
        ELSE '$500+'
    END AS price_range,
    COUNT(*) AS plan_count
FROM pricing_plans
WHERE price_type = 'monthly'
  AND price_amount IS NOT NULL
GROUP BY
    CASE
        WHEN price_amount < 10 THEN 'Under $10'
        WHEN price_amount < 20 THEN '$10-$19.99'
        WHEN price_amount < 50 THEN '$20-$49.99'
        WHEN price_amount < 100 THEN '$50-$99.99'
        WHEN price_amount < 500 THEN '$100-$499.99'
        ELSE '$500+'
    END
ORDER BY MIN(price_amount);


-- Question 7: Which established categories have the highest median monthly prices?
-- 问题 7：在具有一定市场规模的 Category 中，哪些 Category 的月付价格中位数最高？

WITH category_monthly_prices AS (
    SELECT
        c.id AS category_id,
        c.title AS category,
        pp.price_amount
    FROM apps_categories ac
    JOIN categories c
        ON ac.category_id = c.id
    JOIN pricing_plans pp
        ON ac.app_id = pp.app_id
    WHERE pp.price_type = 'monthly'
      AND pp.price_amount IS NOT NULL
),

category_price_stats AS (
    SELECT DISTINCT
        category_id,
        category,
        COUNT(*) OVER (PARTITION BY category_id) AS monthly_plan_count,
        PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY price_amount)
            OVER (PARTITION BY category_id) AS median_monthly_price
    FROM category_monthly_prices
)

SELECT TOP 20
    category,
    monthly_plan_count,
    CAST(median_monthly_price AS DECIMAL(10,2)) AS median_monthly_price
FROM category_price_stats
WHERE monthly_plan_count >= 30
ORDER BY median_monthly_price DESC;


-- Question 8: Which established categories have the lowest median monthly prices?
-- 问题 8：在具有一定市场规模的 Category 中，哪些 Category 的月付价格中位数最低？

WITH category_monthly_prices AS (
    SELECT
        c.id AS category_id,
        c.title AS category,
        pp.price_amount
    FROM apps_categories ac
    JOIN categories c
        ON ac.category_id = c.id
    JOIN pricing_plans pp
        ON ac.app_id = pp.app_id
    WHERE pp.price_type = 'monthly'
      AND pp.price_amount IS NOT NULL
),

category_price_stats AS (
    SELECT DISTINCT
        category_id,
        category,
        COUNT(*) OVER (PARTITION BY category_id) AS monthly_plan_count,
        PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY price_amount)
            OVER (PARTITION BY category_id) AS median_monthly_price
    FROM category_monthly_prices
)

SELECT TOP 20
    category,
    monthly_plan_count,
    CAST(median_monthly_price AS DECIMAL(10,2)) AS median_monthly_price
FROM category_price_stats
WHERE monthly_plan_count >= 30
ORDER BY median_monthly_price ASC;


-- Question 9: Which established categories have the highest share of free pricing plans?
-- 问题 9：在具有一定市场规模的 Category 中，哪些 Category 的免费 Pricing Plan 占比最高？

SELECT TOP 20
    c.title AS category,
    COUNT(*) AS total_plan_count,
    SUM(
        CASE
            WHEN pp.price_type IN ('free', 'free_to_install') THEN 1
            ELSE 0
        END
    ) AS free_plan_count,
    CAST(
        SUM(
            CASE
                WHEN pp.price_type IN ('free', 'free_to_install') THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS free_plan_share_pct
FROM apps_categories ac
JOIN categories c
    ON ac.category_id = c.id
JOIN pricing_plans pp
    ON ac.app_id = pp.app_id
GROUP BY c.id, c.title
HAVING COUNT(*) >= 30
ORDER BY free_plan_share_pct DESC;


-- Question 10: What are the most common pricing plan features?
-- 问题 10：Shopify App 的 Pricing Plans 中最常见的产品功能是什么？

SELECT TOP 20
    feature,
    COUNT(DISTINCT pricing_plan_id) AS plan_count,
    COUNT(DISTINCT app_id) AS app_count
FROM pricing_plan_features
GROUP BY feature
ORDER BY plan_count DESC;


-- Question 11: Which apps offer the largest number of pricing plans?
-- 问题 11：哪些 Shopify Apps 提供的 Pricing Plans 数量最多？

SELECT TOP 20
    a.title AS app,
    a.developer,
    COUNT(pp.id) AS plan_count
FROM apps a
JOIN pricing_plans pp
    ON a.id = pp.app_id
GROUP BY a.id, a.title, a.developer
ORDER BY plan_count DESC;