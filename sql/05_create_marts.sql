-- ============================================================================
-- 05_create_marts.sql
-- Marts layer: business-ready facts and dimensions
-- ============================================================================
-- Purpose: Build star-schema-style tables for analytics and reporting.
--
-- NOTE: CREATE OR REPLACE recreates each mart table on every run.
-- ============================================================================

USE DATABASE WALMART_SALES;
USE SCHEMA MARTS;
USE WAREHOUSE WALMART_WH;

-- ----------------------------------------------------------------------------
-- MARTS.DIM_STORE
-- Store dimension — one row per store
-- Source: STAGING.STG_STORES
--
-- For this portfolio project, store is used as the natural key.
-- A surrogate key or SCD Type 2 is not required here.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE MARTS.DIM_STORE AS
SELECT
    store,
    store_type,
    store_size,
    loaded_at
FROM STAGING.STG_STORES;

COMMENT ON TABLE MARTS.DIM_STORE IS
    'Store dimension — natural key is store (no surrogate key in this project)';

-- ----------------------------------------------------------------------------
-- MARTS.FACT_SALES
-- Weekly sales fact at department level
-- Grain: store + dept + sales_date
-- Source: STAGING.STG_TRAIN joined to DIM_STORE and STG_FEATURES
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE MARTS.FACT_SALES AS
SELECT
    t.store,
    t.dept,
    t.sales_date,
    t.weekly_sales,
    t.is_holiday,
    s.store_type,
    s.store_size,
    f.temperature,
    f.fuel_price,
    f.markdown1,
    f.markdown2,
    f.markdown3,
    f.markdown4,
    f.markdown5,
    f.cpi,
    f.unemployment,
    CURRENT_TIMESTAMP()                 AS loaded_at
FROM STAGING.STG_TRAIN t
INNER JOIN MARTS.DIM_STORE s
    ON t.store = s.store
LEFT JOIN STAGING.STG_FEATURES f
    ON t.store = f.store
   AND t.sales_date = f.feature_date;

COMMENT ON TABLE MARTS.FACT_SALES IS
    'Sales fact — store + dept + sales_date with store attributes and features';

-- ----------------------------------------------------------------------------
-- MARTS.FACT_STORE_FEATURES
-- Store-level features for time-series analysis and forecasting
-- Grain: store + feature_date
-- Source: STAGING.STG_FEATURES
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE MARTS.FACT_STORE_FEATURES AS
SELECT
    store,
    feature_date,
    temperature,
    fuel_price,
    markdown1,
    markdown2,
    markdown3,
    markdown4,
    markdown5,
    cpi,
    unemployment,
    is_holiday,
    loaded_at
FROM STAGING.STG_FEATURES;

COMMENT ON TABLE MARTS.FACT_STORE_FEATURES IS
    'Store weekly features — external drivers for sales analysis';

-- ----------------------------------------------------------------------------
-- MARTS.FACT_STORE_WEEKLY_SALES
-- Store-level weekly sales rollup for executive reporting
-- Grain: store + sales_date
-- Source: MARTS.FACT_SALES
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE MARTS.FACT_STORE_WEEKLY_SALES AS
SELECT
    store,
    sales_date,
    store_type,
    store_size,
    is_holiday,
    SUM(weekly_sales)                 AS total_weekly_sales,
    AVG(weekly_sales)                 AS avg_department_weekly_sales,
    COUNT(DISTINCT dept)              AS active_departments,
    MAX(temperature)                  AS temperature,
    MAX(fuel_price)                   AS fuel_price,
    MAX(cpi)                          AS cpi,
    MAX(unemployment)                 AS unemployment
FROM MARTS.FACT_SALES
GROUP BY
    store,
    sales_date,
    store_type,
    store_size,
    is_holiday;

COMMENT ON TABLE MARTS.FACT_STORE_WEEKLY_SALES IS
    'Store-week sales rollup — totals and averages across departments';

-- ----------------------------------------------------------------------------
-- Verification: mart row counts
-- ----------------------------------------------------------------------------
SELECT 'DIM_STORE'               AS table_name, COUNT(*) AS row_count FROM MARTS.DIM_STORE
UNION ALL
SELECT 'FACT_SALES',             COUNT(*) FROM MARTS.FACT_SALES
UNION ALL
SELECT 'FACT_STORE_FEATURES',    COUNT(*) FROM MARTS.FACT_STORE_FEATURES
UNION ALL
SELECT 'FACT_STORE_WEEKLY_SALES', COUNT(*) FROM MARTS.FACT_STORE_WEEKLY_SALES;

-- Verification: fact rows without a matching DIM_STORE (expect 0 after INNER JOIN build)
WALMART_SALES.PUBLICWALMART_SALES.RAWWALMART_SALES.MARTSSELECT COUNT(*) AS orphan_fact_sales_rows
FROM STAGING.STG_TRAIN t
LEFT JOIN MARTS.DIM_STORE d
    ON t.store = d.store
WHERE d.store IS NULL;


SELECT COUNT(*) AS orphan_fact_sales_rows
FROM MARTS.FACT_SALES f
LEFT JOIN MARTS.DIM_STORE d
ON f.store = d.store
WHERE d.store IS NULL;

SELECT COUNT(*) AS null_weekly_sales
FROM MARTS.FACT_SALES
WHERE weekly_sales IS NULL;

SELECT store, dept, sales_date, COUNT(*) AS cnt
FROM MARTS.FACT_SALES
GROUP BY store, dept, sales_date
HAVING COUNT(*) > 1;
