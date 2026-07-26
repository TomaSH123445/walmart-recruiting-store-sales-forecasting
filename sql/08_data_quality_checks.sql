-- ============================================================================
-- 08_data_quality_checks.sql
-- Data quality validation queries
-- ============================================================================
-- Purpose: Reusable checks to catch load errors, orphans, and anomalies
-- before building marts or training forecast models.
--
-- Run after RAW load (Section A) and again after STAGING/MARTS builds
-- (Sections B and C).
-- ============================================================================

USE DATABASE WALMART_SALES;
USE WAREHOUSE WALMART_WH;

-- ############################################################################
-- SECTION A: RAW layer checks
-- Run after 03_load_data.sql
-- ############################################################################

-- A1. Row counts for all RAW tables
SELECT 'RAW.TRAIN'    AS check_name, COUNT(*) AS metric_value FROM RAW.TRAIN
UNION ALL
SELECT 'RAW.TEST',     COUNT(*) FROM RAW.TEST
UNION ALL
SELECT 'RAW.FEATURES', COUNT(*) FROM RAW.FEATURES
UNION ALL
SELECT 'RAW.STORES',   COUNT(*) FROM RAW.STORES;

-- A2. Duplicates in RAW.TRAIN by store + dept + date (expect 0 rows)
SELECT
    store,
    dept,
    date,
    COUNT(*)            AS duplicate_count
FROM RAW.TRAIN
GROUP BY store, dept, date
HAVING COUNT(*) > 1;

-- A3. NULL values in critical columns of RAW.TRAIN
SELECT
    COUNT(*)                                                    AS total_rows,
    SUM(IFF(weekly_sales IS NULL, 1, 0))                        AS null_weekly_sales,
    SUM(IFF(date IS NULL, 1, 0))                                AS null_dates
FROM RAW.TRAIN;

-- A4. Date range in RAW.TRAIN
SELECT
    MIN(date)                   AS min_date,
    MAX(date)                   AS max_date
FROM RAW.TRAIN;

-- A5. Orphan stores — stores in TRAIN not found in STORES (expect 0 rows)
SELECT DISTINCT
    t.store                     AS orphan_store
FROM RAW.TRAIN t
LEFT JOIN RAW.STORES s
    ON t.store = s.store
WHERE s.store IS NULL;

-- A6. Feature coverage — store + date in TRAIN without matching FEATURES row
SELECT
    COUNT(*)                    AS missing_feature_combinations
FROM (
    SELECT DISTINCT store, date
    FROM RAW.TRAIN
) t
LEFT JOIN RAW.FEATURES f
    ON t.store = f.store
   AND t.date = f.date
WHERE f.store IS NULL;

-- ############################################################################
-- SECTION B: STAGING layer checks
-- Run after 04_create_staging.sql
-- ############################################################################

-- B1. RAW.TRAIN vs STAGING.STG_TRAIN row count comparison
SELECT
    (SELECT COUNT(*) FROM RAW.TRAIN)            AS raw_train_count,
    (SELECT COUNT(*) FROM STAGING.STG_TRAIN)    AS staging_train_count,
    (SELECT COUNT(*) FROM RAW.TRAIN)
        - (SELECT COUNT(*) FROM STAGING.STG_TRAIN) AS rows_removed_by_dedup;

-- B2. Duplicates in STAGING.STG_TRAIN (expect 0 rows)
SELECT
    store,
    dept,
    sales_date,
    COUNT(*)                    AS duplicate_count
FROM STAGING.STG_TRAIN
GROUP BY store, dept, sales_date
HAVING COUNT(*) > 1;

-- B3. Negative weekly_sales in staging (expect 0)
SELECT
    COUNT(*)                    AS negative_weekly_sales_count
FROM STAGING.STG_TRAIN
WHERE weekly_sales < 0;

-- B4. NULL weekly_sales in staging (expect 0)
SELECT
    COUNT(*)                    AS null_weekly_sales_count
FROM STAGING.STG_TRAIN
WHERE weekly_sales IS NULL;

-- ############################################################################
-- SECTION C: MARTS layer checks
-- Run after 05_create_marts.sql
-- ############################################################################

-- C1. Orphan fact rows — FACT_SALES without matching DIM_STORE (expect 0)
SELECT
    COUNT(*)                    AS orphan_fact_sales_rows
FROM MARTS.FACT_SALES f
LEFT JOIN MARTS.DIM_STORE d
    ON f.store = d.store
WHERE d.store IS NULL;

-- C2. Sales rows without joined feature data
SELECT
    COUNT(*)                    AS sales_rows_without_features
FROM MARTS.FACT_SALES f
LEFT JOIN MARTS.FACT_STORE_FEATURES ff
    ON f.store = ff.store
   AND f.sales_date = ff.feature_date
WHERE ff.store IS NULL;

-- C3. Outliers — weekly_sales outside mean +/- 3 * STDDEV
WITH sales_stats AS (
    SELECT
        AVG(weekly_sales)       AS mean_sales,
        STDDEV(weekly_sales)    AS std_sales
    FROM MARTS.FACT_SALES
)
SELECT
    f.store,
    f.dept,
    f.sales_date,
    f.weekly_sales,
    s.mean_sales,
    s.std_sales
FROM MARTS.FACT_SALES f
CROSS JOIN sales_stats s
WHERE f.weekly_sales > s.mean_sales + 3 * s.std_sales
   OR f.weekly_sales < s.mean_sales - 3 * s.std_sales
ORDER BY f.weekly_sales DESC;
