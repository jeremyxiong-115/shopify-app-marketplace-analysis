-- Marketplace & Competition Analysis


-- Question 1: How large is the Shopify App Marketplace?
-- 问题 1：Shopify App Marketplace 的整体规模有多大？

-- 1.1 How many apps and developers are in the marketplace?
-- 1.1 市场中一共有多少个 App 和 Developer？

SELECT
    COUNT(*) AS total_apps,
    COUNT(DISTINCT developer) AS total_developers
FROM apps;


-- 1.2 How many categories are in the marketplace?
-- 1.2 市场中一共有多少个 Category？

SELECT
    COUNT(*) AS total_categories
FROM categories;


-- Question 2: Which categories have the most apps?
-- 问题 2：哪些 Category 中的 App 数量最多？

SELECT TOP 20
    c.title AS category,
    COUNT(DISTINCT ac.app_id) AS app_count
FROM apps_categories ac
JOIN categories c
    ON ac.category_id = c.id
GROUP BY c.id, c.title
ORDER BY app_count DESC;


-- Question 3: Which categories receive the most customer reviews?
-- 问题 3：哪些 Category 获得的用户评论数量最多？

SELECT TOP 20
    c.title AS category,
    COUNT(r.rating) AS review_count
FROM apps_categories ac
JOIN categories c
    ON ac.category_id = c.id
JOIN reviews r
    ON ac.app_id = r.app_id
GROUP BY c.id, c.title
ORDER BY review_count DESC;


-- Question 4: Which categories have the highest average number of reviews per app?
-- 问题 4：哪些 Category 平均每个 App 获得的评论数量最高？

SELECT TOP 20
    c.title AS category,
    COUNT(DISTINCT ac.app_id) AS app_count,
    COUNT(r.rating) AS review_count,
    CAST(
        COUNT(r.rating) * 1.0 / COUNT(DISTINCT ac.app_id)
        AS DECIMAL(10,2)
    ) AS avg_reviews_per_app
FROM apps_categories ac
JOIN categories c
    ON ac.category_id = c.id
LEFT JOIN reviews r
    ON ac.app_id = r.app_id
GROUP BY c.id, c.title
ORDER BY avg_reviews_per_app DESC;


-- Question 4: Which established categories have the highest average reviews per app?
-- 问题 4：在具有一定市场规模的 Category 中，哪些平均每个 App 获得的评论最多？

SELECT TOP 20
    c.title AS category,
    COUNT(DISTINCT ac.app_id) AS app_count,
    COUNT(r.rating) AS review_count,
    CAST(
        COUNT(r.rating) * 1.0 / COUNT(DISTINCT ac.app_id)
        AS DECIMAL(10,2)
    ) AS avg_reviews_per_app
FROM apps_categories ac
JOIN categories c
    ON ac.category_id = c.id
LEFT JOIN reviews r
    ON ac.app_id = r.app_id
GROUP BY c.id, c.title
HAVING COUNT(DISTINCT ac.app_id) >= 50
ORDER BY avg_reviews_per_app DESC;


-- Question 5: Which established categories have the highest average app ratings?
-- 问题 5：在具有一定市场规模的 Category 中，哪些 Category 的 App 平均评分最高？

SELECT TOP 20
    c.title AS category,
    COUNT(DISTINCT ac.app_id) AS app_count,
    CAST(AVG(a.rating) AS DECIMAL(4,2)) AS avg_rating
FROM apps_categories ac
JOIN categories c
    ON ac.category_id = c.id
JOIN apps a
    ON ac.app_id = a.id
WHERE a.rating IS NOT NULL
GROUP BY c.id, c.title
HAVING COUNT(DISTINCT ac.app_id) >= 50
ORDER BY avg_rating DESC;


-- Question 6: Which established categories have the lowest average app ratings?
-- 问题 6：在具有一定市场规模的 Category 中，哪些 Category 的 App 平均评分最低？

SELECT TOP 20
    c.title AS category,
    COUNT(DISTINCT ac.app_id) AS app_count,
    CAST(AVG(a.rating) AS DECIMAL(4,2)) AS avg_rating
FROM apps_categories ac
JOIN categories c
    ON ac.category_id = c.id
JOIN apps a
    ON ac.app_id = a.id
WHERE a.rating IS NOT NULL
GROUP BY c.id, c.title
HAVING COUNT(DISTINCT ac.app_id) >= 50
ORDER BY avg_rating ASC;


-- Question 7: Which low-rated established categories also have strong review activity?
-- 问题 7：哪些平均评分较低、具有一定市场规模的 Category，同时拥有较高的用户评论活跃度？

WITH category_app_stats AS (
    SELECT
        c.id AS category_id,
        c.title AS category,
        COUNT(DISTINCT ac.app_id) AS app_count,
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
        COUNT(r.rating) AS review_count
    FROM apps_categories ac
    JOIN reviews r
        ON ac.app_id = r.app_id
    GROUP BY ac.category_id
)

SELECT TOP 20
    cas.category,
    cas.app_count,
    crs.review_count,
    CAST(
        crs.review_count * 1.0 / cas.app_count
        AS DECIMAL(10,2)
    ) AS avg_reviews_per_app,
    CAST(cas.avg_rating AS DECIMAL(4,2)) AS avg_rating
FROM category_app_stats cas
JOIN category_review_stats crs
    ON cas.category_id = crs.category_id
WHERE
    cas.app_count >= 50
    AND cas.avg_rating < 3.50
ORDER BY crs.review_count DESC;


-- Question 8: Which categories have the most unique developers?
-- 问题 8：哪些 Category 中拥有最多不同的 Developer？

SELECT TOP 20
    c.title AS category,
    COUNT(DISTINCT ac.app_id) AS app_count,
    COUNT(DISTINCT a.developer) AS developer_count,
    CAST(
        COUNT(DISTINCT ac.app_id) * 1.0
        / COUNT(DISTINCT a.developer)
        AS DECIMAL(10,2)
    ) AS apps_per_developer
FROM apps_categories ac
JOIN categories c
    ON ac.category_id = c.id
JOIN apps a
    ON ac.app_id = a.id
GROUP BY c.id, c.title
HAVING COUNT(DISTINCT ac.app_id) >= 50
ORDER BY developer_count DESC;


-- Question 9: How concentrated are customer reviews within established categories?
-- 问题 9：在具有一定市场规模的 Category 中，用户评论是否集中在少数头部 App？

WITH app_review_counts AS (
    SELECT
        ac.category_id,
        ac.app_id,
        COUNT(r.rating) AS app_review_count
    FROM apps_categories ac
    LEFT JOIN reviews r
        ON ac.app_id = r.app_id
    GROUP BY ac.category_id, ac.app_id
),

category_review_stats AS (
    SELECT
        category_id,
        COUNT(*) AS app_count,
        SUM(app_review_count) AS total_reviews,
        MAX(app_review_count) AS top_app_reviews
    FROM app_review_counts
    GROUP BY category_id
)

SELECT TOP 20
    c.title AS category,
    crs.app_count,
    crs.total_reviews,
    crs.top_app_reviews,
    CAST(
        crs.top_app_reviews * 100.0 / NULLIF(crs.total_reviews, 0)
        AS DECIMAL(10,2)
    ) AS top_app_review_share_pct
FROM category_review_stats crs
JOIN categories c
    ON crs.category_id = c.id
WHERE
    crs.app_count >= 50
    AND crs.total_reviews > 0
ORDER BY top_app_review_share_pct DESC;


-- Question 10: Which established categories have the lowest review concentration?
-- 问题 10：在具有一定市场规模的 Category 中，哪些 Category 的用户评论分布最分散？

WITH app_review_counts AS (
    SELECT
        ac.category_id,
        ac.app_id,
        COUNT(r.rating) AS app_review_count
    FROM apps_categories ac
    LEFT JOIN reviews r
        ON ac.app_id = r.app_id
    GROUP BY ac.category_id, ac.app_id
),

category_review_stats AS (
    SELECT
        category_id,
        COUNT(*) AS app_count,
        SUM(app_review_count) AS total_reviews,
        MAX(app_review_count) AS top_app_reviews
    FROM app_review_counts
    GROUP BY category_id
)

SELECT TOP 20
    c.title AS category,
    crs.app_count,
    crs.total_reviews,
    crs.top_app_reviews,
    CAST(
        crs.top_app_reviews * 100.0 / NULLIF(crs.total_reviews, 0)
        AS DECIMAL(10,2)
    ) AS top_app_review_share_pct
FROM category_review_stats crs
JOIN categories c
    ON crs.category_id = c.id
WHERE
    crs.app_count >= 50
    AND crs.total_reviews > 0
ORDER BY top_app_review_share_pct ASC;