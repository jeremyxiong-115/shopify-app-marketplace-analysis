USE ShopifyMarketplace;
GO

CREATE TABLE apps (
    id VARCHAR(36) NOT NULL,
    url NVARCHAR(1000),
    title NVARCHAR(500),
    developer NVARCHAR(500),
    developer_link NVARCHAR(1000),
    icon NVARCHAR(1000),
    rating DECIMAL(3,2),
    reviews_count INT,
    description_raw NVARCHAR(MAX),
    description NVARCHAR(MAX),
    pricing_hint NVARCHAR(500),
    lastmod DATE,
    has_reviews BIT,

    CONSTRAINT PK_apps PRIMARY KEY (id)
);
GO

SELECT *
FROM apps;

SELECT COUNT(*) AS total_rows
FROM apps;

SELECT COUNT(DISTINCT id) AS unique_apps
FROM apps;

SELECT COUNT(*) AS duplicate_ids
FROM (
    SELECT id
    FROM apps
    GROUP BY id
    HAVING COUNT(*) > 1
) AS duplicates;

CREATE TABLE apps_categories (
    app_id VARCHAR(36) NOT NULL,
    category_id VARCHAR(32) NOT NULL,

    CONSTRAINT PK_apps_categories
        PRIMARY KEY (app_id, category_id)
);
GO

SELECT COUNT(*) AS total_rows
FROM apps_categories;

SELECT COUNT(*) AS duplicate_relationships
FROM (
    SELECT app_id, category_id
    FROM apps_categories
    GROUP BY app_id, category_id
    HAVING COUNT(*) > 1
) AS duplicates;

SELECT COUNT(*) AS invalid_app_ids
FROM apps_categories ac
LEFT JOIN apps a
    ON ac.app_id = a.id
WHERE a.id IS NULL;

CREATE TABLE categories (
    id VARCHAR(32) NOT NULL,
    title NVARCHAR(500),

    CONSTRAINT PK_categories PRIMARY KEY (id)
);
GO

SELECT COUNT(*) AS total_rows
FROM categories;

SELECT COUNT(DISTINCT id) AS unique_categories
FROM categories;

SELECT COUNT(*) AS duplicate_ids
FROM (
    SELECT id
    FROM categories
    GROUP BY id
    HAVING COUNT(*) > 1
) AS duplicates;

SELECT COUNT(*) AS invalid_category_ids
FROM apps_categories ac
LEFT JOIN categories c
    ON ac.category_id = c.id
WHERE c.id IS NULL;

CREATE TABLE key_benefits (
    app_id VARCHAR(36) NOT NULL,
    description NVARCHAR(MAX)
);
GO

SELECT COUNT(*) AS total_rows
FROM key_benefits;

SELECT COUNT(*) AS invalid_app_ids
FROM key_benefits kb
LEFT JOIN apps a
    ON kb.app_id = a.id
WHERE a.id IS NULL;

SELECT COUNT(*) AS missing_descriptions
FROM key_benefits
WHERE description IS NULL;

CREATE TABLE pricing_plans (
    id VARCHAR(36) NOT NULL,
    app_id VARCHAR(36) NOT NULL,
    title NVARCHAR(500),
    price NVARCHAR(500),
    price_type VARCHAR(50),
    price_amount DECIMAL(10,2),

    CONSTRAINT PK_pricing_plans PRIMARY KEY (id)
);
GO

SELECT COUNT(*) AS total_rows
FROM pricing_plans;

SELECT COUNT(DISTINCT id) AS unique_plans
FROM pricing_plans;

SELECT COUNT(*) AS duplicate_ids
FROM (
    SELECT id
    FROM pricing_plans
    GROUP BY id
    HAVING COUNT(*) > 1
) AS duplicates;

SELECT COUNT(*) AS invalid_app_ids
FROM pricing_plans pp
LEFT JOIN apps a
    ON pp.app_id = a.id
WHERE a.id IS NULL;

CREATE TABLE pricing_plan_features (
    pricing_plan_id VARCHAR(36) NOT NULL,
    app_id VARCHAR(36) NOT NULL,
    feature NVARCHAR(MAX)
);
GO

SELECT COUNT(*) AS total_rows
FROM pricing_plan_features;

SELECT COUNT(*) AS invalid_app_ids
FROM pricing_plan_features ppf
LEFT JOIN apps a
    ON ppf.app_id = a.id
WHERE a.id IS NULL;

SELECT COUNT(*) AS invalid_pricing_plan_ids
FROM pricing_plan_features ppf
LEFT JOIN pricing_plans pp
    ON ppf.pricing_plan_id = pp.id
WHERE pp.id IS NULL;

SELECT COUNT(*) AS invalid_features
FROM pricing_plan_features
WHERE feature = '#NAME?';

CREATE TABLE reviews (
    app_id VARCHAR(36) NOT NULL,
    author NVARCHAR(500),
    rating INT NOT NULL,
    posted_at DATE NOT NULL,
    body NVARCHAR(MAX),
    developer_reply NVARCHAR(MAX),
    developer_reply_posted_at DATE,
    is_edited BIT NOT NULL,
    has_developer_reply BIT NOT NULL,
    has_review_text BIT NOT NULL
);
GO

SELECT COUNT(*) AS total_rows
FROM reviews;

SELECT COUNT(*) AS invalid_app_ids
FROM reviews r
LEFT JOIN apps a
    ON r.app_id = a.id
WHERE a.id IS NULL;

SELECT MIN(rating) AS min_rating,
       MAX(rating) AS max_rating
FROM reviews;

SELECT COUNT(*) AS missing_posted_at
FROM reviews
WHERE posted_at IS NULL;

SELECT COUNT(*) AS reply_date_mismatch
FROM reviews
WHERE has_developer_reply = 1
  AND developer_reply_posted_at IS NULL;

SELECT TOP 20
    r.app_id
FROM reviews r
LEFT JOIN apps a
    ON r.app_id = a.id
WHERE a.id IS NULL;

SELECT COUNT(*) AS null_app_ids
FROM reviews
WHERE app_id IS NULL;

SELECT
    COUNT(*) AS blank_app_ids
FROM reviews
WHERE LTRIM(RTRIM(app_id)) = '';

DROP TABLE reviews;
GO

CREATE TABLE reviews (
    app_id VARCHAR(36) NOT NULL,
    author NVARCHAR(500),
    rating INT NOT NULL,
    posted_at DATE NOT NULL,
    body NVARCHAR(MAX),
    developer_reply NVARCHAR(MAX),
    developer_reply_posted_at DATE,
    is_edited BIT NOT NULL,
    has_developer_reply BIT NOT NULL,
    has_review_text BIT NOT NULL
);
GO

BULK INSERT reviews
FROM 'D:\xiongsongsong\Programming Language\Data Analyst Projects\shopify-app-marketplace-analysis\data\processed\reviews_clean.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001',
    TABLOCK
);

TRUNCATE TABLE reviews;
GO

SELECT COUNT(*) AS total_rows
FROM reviews;

SELECT COUNT(*) AS total_rows
FROM reviews;

SELECT COUNT(*) AS blank_app_ids
FROM reviews
WHERE LTRIM(RTRIM(app_id)) = '';

SELECT COUNT(*) AS invalid_app_ids
FROM reviews r
LEFT JOIN apps a
    ON r.app_id = a.id
WHERE a.id IS NULL;

TRUNCATE TABLE reviews;
GO

SELECT COUNT(*) AS total_rows
FROM reviews;

SELECT COUNT(*) AS blank_app_ids
FROM reviews
WHERE LTRIM(RTRIM(app_id)) = '';

SELECT COUNT(*) AS invalid_app_ids
FROM reviews r
LEFT JOIN apps a
    ON r.app_id = a.id
WHERE a.id IS NULL;

SELECT MIN(rating) AS min_rating,
       MAX(rating) AS max_rating
FROM reviews;

SELECT COUNT(*) AS missing_posted_at
FROM reviews
WHERE posted_at IS NULL;

SELECT COUNT(*) AS reply_date_mismatch
FROM reviews
WHERE has_developer_reply = 1
  AND developer_reply_posted_at IS NULL;