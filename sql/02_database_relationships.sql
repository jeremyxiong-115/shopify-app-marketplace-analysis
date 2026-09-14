ALTER TABLE pricing_plans
ADD CONSTRAINT FK_pricing_plans_apps
FOREIGN KEY (app_id)
REFERENCES apps(id);
GO

ALTER TABLE apps_categories
ADD CONSTRAINT FK_apps_categories_apps
FOREIGN KEY (app_id)
REFERENCES apps(id);
GO

ALTER TABLE apps_categories
ADD CONSTRAINT FK_apps_categories_categories
FOREIGN KEY (category_id)
REFERENCES categories(id);
GO

ALTER TABLE key_benefits
ADD CONSTRAINT FK_key_benefits_apps
FOREIGN KEY (app_id)
REFERENCES apps(id);
GO

ALTER TABLE pricing_plan_features
ADD CONSTRAINT FK_pricing_plan_features_apps
FOREIGN KEY (app_id)
REFERENCES apps(id);
GO

ALTER TABLE pricing_plan_features
ADD CONSTRAINT FK_pricing_plan_features_pricing_plans
FOREIGN KEY (pricing_plan_id)
REFERENCES pricing_plans(id);
GO

ALTER TABLE reviews
ADD CONSTRAINT FK_reviews_apps
FOREIGN KEY (app_id)
REFERENCES apps(id);
GO

SELECT 'apps' AS table_name, COUNT(*) AS row_count FROM apps
UNION ALL
SELECT 'apps_categories', COUNT(*) FROM apps_categories
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'key_benefits', COUNT(*) FROM key_benefits
UNION ALL
SELECT 'pricing_plans', COUNT(*) FROM pricing_plans
UNION ALL
SELECT 'pricing_plan_features', COUNT(*) FROM pricing_plan_features
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews;

SELECT
    fk.name AS foreign_key,
    OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk
ORDER BY child_table, foreign_key;