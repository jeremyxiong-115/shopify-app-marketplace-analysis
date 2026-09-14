-- Review & Customer Feedback Analysis


-- Question 1: How are customer ratings distributed across all reviews?
-- 问题 1：所有用户 Reviews 的评分分布是什么样？

SELECT
    rating,
    COUNT(*) AS review_count,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS percentage
FROM reviews
GROUP BY rating
ORDER BY rating DESC;


-- Question 2: What percentage of customer reviews receive a developer reply?
-- 问题 2：有多少比例的用户 Reviews 得到了开发者回复？

SELECT
    COUNT(*) AS total_reviews,

    SUM(
        CASE
            WHEN has_developer_reply = 1 THEN 1
            ELSE 0
        END
    ) AS replied_reviews,

    CAST(
        SUM(
            CASE
                WHEN has_developer_reply = 1 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS reply_rate_pct

FROM reviews;


-- Question 3: How does developer reply rate vary by customer rating?
-- 问题 3：不同用户评分的 Review，其开发者回复率有何差异？

SELECT
    rating,
    COUNT(*) AS review_count,

    SUM(
        CASE
            WHEN has_developer_reply = 1 THEN 1
            ELSE 0
        END
    ) AS replied_reviews,

    CAST(
        SUM(
            CASE
                WHEN has_developer_reply = 1 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS reply_rate_pct

FROM reviews
GROUP BY rating
ORDER BY rating DESC;


-- Question 4: Which categories receive the most 1-star reviews?
-- 问题 4：哪些 Category 收到的 1-star Reviews 数量最多？

SELECT TOP 20
    c.title AS category,
    COUNT(*) AS one_star_review_count
FROM reviews r
JOIN apps_categories ac
    ON r.app_id = ac.app_id
JOIN categories c
    ON ac.category_id = c.id
WHERE r.rating = 1
GROUP BY c.id, c.title
ORDER BY one_star_review_count DESC;


-- Question 5: Which established categories have the highest 1-star review rate?
-- 问题 5：在具有一定 Review 数量的 Category 中，哪些 Category 的 1-star Review 占比最高？

SELECT TOP 20
    c.title AS category,
    COUNT(*) AS total_reviews,
    SUM(
        CASE
            WHEN r.rating = 1 THEN 1
            ELSE 0
        END
    ) AS one_star_reviews,
    CAST(
        SUM(
            CASE
                WHEN r.rating = 1 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS one_star_rate_pct
FROM reviews r
JOIN apps_categories ac
    ON r.app_id = ac.app_id
JOIN categories c
    ON ac.category_id = c.id
GROUP BY c.id, c.title
HAVING COUNT(*) >= 1000
ORDER BY one_star_rate_pct DESC;


-- Question 6: Which established categories have the highest developer reply rates?
-- 问题 6：在具有一定 Review 数量的 Category 中，哪些 Category 的开发者回复率最高？

SELECT TOP 20
    c.title AS category,
    COUNT(*) AS total_reviews,
    SUM(
        CASE
            WHEN r.has_developer_reply = 1 THEN 1
            ELSE 0
        END
    ) AS replied_reviews,
    CAST(
        SUM(
            CASE
                WHEN r.has_developer_reply = 1 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS reply_rate_pct
FROM reviews r
JOIN apps_categories ac
    ON r.app_id = ac.app_id
JOIN categories c
    ON ac.category_id = c.id
GROUP BY c.id, c.title
HAVING COUNT(*) >= 1000
ORDER BY reply_rate_pct DESC;


-- Question 6: Which established categories have the highest developer reply rates?
-- 问题 6：在具有一定 App 规模和 Review 数量的 Category 中，哪些开发者回复率最高？

SELECT TOP 20
    c.title AS category,
    COUNT(DISTINCT ac.app_id) AS app_count,
    COUNT(*) AS total_reviews,

    SUM(
        CASE
            WHEN r.has_developer_reply = 1 THEN 1
            ELSE 0
        END
    ) AS replied_reviews,

    CAST(
        SUM(
            CASE
                WHEN r.has_developer_reply = 1 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS reply_rate_pct

FROM reviews r
JOIN apps_categories ac
    ON r.app_id = ac.app_id
JOIN categories c
    ON ac.category_id = c.id

GROUP BY c.id, c.title

HAVING
    COUNT(DISTINCT ac.app_id) >= 50
    AND COUNT(*) >= 1000

ORDER BY reply_rate_pct DESC;


-- Question 7: Which established categories have the lowest developer reply rates?
-- 问题 7：在具有一定 App 规模和 Review 数量的 Category 中，哪些开发者回复率最低？

SELECT TOP 20
    c.title AS category,
    COUNT(DISTINCT ac.app_id) AS app_count,
    COUNT(*) AS total_reviews,

    SUM(
        CASE
            WHEN r.has_developer_reply = 1 THEN 1
            ELSE 0
        END
    ) AS replied_reviews,

    CAST(
        SUM(
            CASE
                WHEN r.has_developer_reply = 1 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS reply_rate_pct

FROM reviews r
JOIN apps_categories ac
    ON r.app_id = ac.app_id
JOIN categories c
    ON ac.category_id = c.id

GROUP BY c.id, c.title

HAVING
    COUNT(DISTINCT ac.app_id) >= 50
    AND COUNT(*) >= 1000

ORDER BY reply_rate_pct ASC;


-- Question 8: Which categories show both high 1-star review rates and low developer reply rates?
-- 问题 8：哪些 Category 同时具有较高的 1-star Review 占比和较低的开发者回复率？

WITH category_review_stats AS (
    SELECT
        c.id AS category_id,
        c.title AS category,
        COUNT(DISTINCT ac.app_id) AS app_count,
        COUNT(*) AS total_reviews,

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

    FROM reviews r
    JOIN apps_categories ac
        ON r.app_id = ac.app_id
    JOIN categories c
        ON ac.category_id = c.id

    GROUP BY c.id, c.title
)

SELECT TOP 20
    category,
    app_count,
    total_reviews,

    CAST(
        one_star_reviews * 100.0 / total_reviews
        AS DECIMAL(5,2)
    ) AS one_star_rate_pct,

    CAST(
        replied_reviews * 100.0 / total_reviews
        AS DECIMAL(5,2)
    ) AS reply_rate_pct

FROM category_review_stats

WHERE
    app_count >= 50
    AND total_reviews >= 1000
    AND one_star_reviews * 100.0 / total_reviews >= 5
    AND replied_reviews * 100.0 / total_reviews <= 20

ORDER BY one_star_rate_pct DESC;


-- Question 9: How many 1-star reviews contain written review text?
-- 问题 9：1-star Reviews 中有多少包含可分析的文字内容？

SELECT
    COUNT(*) AS total_one_star_reviews,

    SUM(
        CASE
            WHEN has_review_text = 1 THEN 1
            ELSE 0
        END
    ) AS one_star_reviews_with_text,

    CAST(
        SUM(
            CASE
                WHEN has_review_text = 1 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS text_available_pct

FROM reviews
WHERE rating = 1;


-- Question 10: Extract 1-star review text for customer complaint analysis
-- 问题 10：提取 1-star Review 文本，用于分析用户投诉主题

SELECT
    app_id,
    body
FROM reviews
WHERE rating = 1
  AND has_review_text = 1;