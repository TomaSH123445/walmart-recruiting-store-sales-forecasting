USE DATABASE WALMART_SALES;
USE WAREHOUSE WALMART_WH;

-- 1. Počet záznamů
SELECT 'RAW.TRAIN' AS check_name, COUNT(*) AS row_count FROM RAW.TRAIN
UNION ALL
SELECT 'RAW.TEST', COUNT(*) FROM RAW.TEST
UNION ALL
SELECT 'RAW.FEATURES', COUNT(*) FROM RAW.FEATURES
UNION ALL
SELECT 'RAW.STORES', COUNT(*) FROM RAW.STORES;

-- 2. Duplicity v historických prodejích
-- Správný výsledek: 0 řádků
SELECT
    store,
    dept,
    date,
    COUNT(*) AS duplicate_count
FROM RAW.TRAIN
GROUP BY store, dept, date
HAVING COUNT(*) > 1;

-- 3. NULL v kritických sloupcích
SELECT
    COUNT(*) AS total_rows,
    SUM(IFF(weekly_sales IS NULL, 1, 0)) AS null_weekly_sales,
    SUM(IFF(date IS NULL, 1, 0)) AS null_dates
FROM RAW.TRAIN;

-- 4. Datumový rozsah historických prodejů
SELECT
    MIN(date) AS min_date,
    MAX(date) AS max_date
FROM RAW.TRAIN;

-- 5. Obchody z TRAIN, které chybí ve STORES
-- Správný výsledek: 0 řádků
SELECT DISTINCT t.store
FROM RAW.TRAIN t
LEFT JOIN RAW.STORES s
    ON t.store = s.store
WHERE s.store IS NULL;

-- 6. Store + date z TRAIN bez feature řádku
SELECT COUNT(*) AS missing_feature_rows
FROM (
    SELECT DISTINCT store, date
    FROM RAW.TRAIN
) t
LEFT JOIN RAW.FEATURES f
    ON t.store = f.store
   AND t.date = f.date
WHERE f.store IS NULL;