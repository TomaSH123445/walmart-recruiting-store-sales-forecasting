-- ============================================================================
-- 04_create_staging.sql
-- Staging layer: clean, type, and standardize raw data
-- ============================================================================
-- Purpose: Transform RAW tables into analysis-ready staging tables.
--
-- Transformations applied:
--   - Rename columns to snake_case
--   - Deduplicate on natural keys (QUALIFY ROW_NUMBER)
--   - Add audit column loaded_at
--   - Preserve NULL for missing markdown / CPI / unemployment (no zero imputation)
--
-- NOTE: CREATE OR REPLACE recreates each staging table on every run.
-- ============================================================================

USE DATABASE WALMART_SALES;
USE SCHEMA STAGING;
USE WAREHOUSE WALMART_WH;

-- ----------------------------------------------------------------------------
-- STAGING.STG_TRAIN
-- Cleaned training sales — grain: store + dept + sales_date
-- Source: RAW.TRAIN
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE STAGING.STG_TRAIN AS
SELECT
    store,
    dept,
    date                            AS sales_date,
    weekly_sales,
    isholiday                       AS is_holiday,
    CURRENT_TIMESTAMP()             AS loaded_at
FROM RAW.TRAIN
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY store, dept, date
    ORDER BY store
) = 1;

COMMENT ON TABLE STAGING.STG_TRAIN IS
    'Cleaned training sales — one row per store + dept + sales_date';

-- ----------------------------------------------------------------------------
-- STAGING.STG_TEST
-- Cleaned test rows (no sales column) — grain: store + dept + sales_date
-- Source: RAW.TEST
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE STAGING.STG_TEST AS
SELECT
    store,
    dept,
    date                            AS sales_date,
    isholiday                       AS is_holiday,
    CURRENT_TIMESTAMP()             AS loaded_at
FROM RAW.TEST
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY store, dept, date
    ORDER BY store
) = 1;

COMMENT ON TABLE STAGING.STG_TEST IS
    'Cleaned test rows for forecasting holdout period';

-- ----------------------------------------------------------------------------
-- STAGING.STG_FEATURES
-- Cleaned store-level weekly features — grain: store + feature_date
-- Source: RAW.FEATURES
-- NULL markdown / CPI / unemployment values are kept as NULL (not imputed).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE STAGING.STG_FEATURES AS
SELECT
    store,
    date                            AS feature_date,
    temperature,
    fuel_price,
    markdown1,
    markdown2,
    markdown3,
    markdown4,
    markdown5,
    cpi,
    unemployment,
    isholiday                       AS is_holiday,
    CURRENT_TIMESTAMP()             AS loaded_at
FROM RAW.FEATURES
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY store, date
    ORDER BY store
) = 1;

COMMENT ON TABLE STAGING.STG_FEATURES IS
    'Cleaned external features — one row per store + feature_date';

-- ----------------------------------------------------------------------------
-- STAGING.STG_STORES
-- Cleaned store dimension — grain: store
-- Source: RAW.STORES
-- store_type is normalized to uppercase single character (A, B, or C).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE STAGING.STG_STORES AS
SELECT
    store,
    TRIM(UPPER(type))::VARCHAR(1)   AS store_type,
    size                            AS store_size,
    CURRENT_TIMESTAMP()             AS loaded_at
FROM RAW.STORES
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY store
    ORDER BY store
) = 1;

COMMENT ON TABLE STAGING.STG_STORES IS
    'Cleaned store attributes — store_type (A/B/C) and store_size';

-- ----------------------------------------------------------------------------
-- Verification: RAW vs STAGING row counts
-- Staging counts may be lower than RAW if duplicates were removed.
-- ----------------------------------------------------------------------------
SELECT
    'TRAIN' AS entity,
    (SELECT COUNT(*) FROM RAW.TRAIN)        AS raw_count,
    (SELECT COUNT(*) FROM STAGING.STG_TRAIN) AS staging_count
UNION ALL
SELECT
    'TEST',
    (SELECT COUNT(*) FROM RAW.TEST),
    (SELECT COUNT(*) FROM STAGING.STG_TEST)
UNION ALL
SELECT
    'FEATURES',
    (SELECT COUNT(*) FROM RAW.FEATURES),
    (SELECT COUNT(*) FROM STAGING.STG_FEATURES)
UNION ALL
SELECT
    'STORES',
    (SELECT COUNT(*) FROM RAW.STORES),
    (SELECT COUNT(*) FROM STAGING.STG_STORES);

    SELECT *
FROM STAGING.STG_TRAIN
ORDER BY store, dept, sales_date
LIMIT 10;

SELECT *
FROM STAGING.STG_FEATURES
ORDER BY store, feature_date
LIMIT 10;

SELECT *
FROM STAGING.STG_STORES
ORDER BY store
LIMIT 10;