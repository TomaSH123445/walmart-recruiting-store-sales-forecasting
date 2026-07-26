-- ============================================================================
-- 07_reporting_views.sql
-- Reporting layer: business-friendly views for dashboards
-- ============================================================================
-- Purpose: Expose curated, documented views for Streamlit, BI tools, or
-- portfolio SQL demos. Views sit on top of MARTS — no heavy logic here.
--
-- NOTE: CREATE OR REPLACE VIEW replaces the view if it already exists.
-- ============================================================================

USE DATABASE WALMART_SALES;
USE SCHEMA REPORTING;
USE WAREHOUSE WALMART_WH;

-- ----------------------------------------------------------------------------
-- REPORTING.VW_SALES_SUMMARY
-- Monthly sales KPIs broken down by store type
-- Source: MARTS.FACT_SALES
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW REPORTING.VW_SALES_SUMMARY AS
SELECT
    DATE_TRUNC('MONTH', sales_date)     AS sales_month,
    store_type,
    COUNT(DISTINCT store)               AS store_count,
    SUM(weekly_sales)                   AS total_sales,
    AVG(weekly_sales)                   AS avg_department_sales,
    COUNT(*)                            AS sales_records
FROM MARTS.FACT_SALES
GROUP BY
    DATE_TRUNC('MONTH', sales_date),
    store_type;

COMMENT ON VIEW REPORTING.VW_SALES_SUMMARY IS
    'Monthly sales totals and averages by store type';

-- ----------------------------------------------------------------------------
-- REPORTING.VW_HOLIDAY_IMPACT
-- Compare sales volume and averages: holiday vs non-holiday weeks
-- Source: MARTS.FACT_SALES
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW REPORTING.VW_HOLIDAY_IMPACT AS
SELECT
    is_holiday,
    COUNT(DISTINCT sales_date)          AS week_count,
    SUM(weekly_sales)                   AS total_sales,
    AVG(weekly_sales)                   AS avg_department_sales
FROM MARTS.FACT_SALES
GROUP BY is_holiday;

COMMENT ON VIEW REPORTING.VW_HOLIDAY_IMPACT IS
    'Holiday lift analysis — avg sales when is_holiday is true vs false';

-- ----------------------------------------------------------------------------
-- REPORTING.VW_TOP_DEPARTMENTS
-- Rank departments by total sales within each store
-- Source: MARTS.FACT_SALES
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW REPORTING.VW_TOP_DEPARTMENTS AS
WITH department_sales AS (
    SELECT
        store,
        dept,
        SUM(weekly_sales)               AS total_sales
    FROM MARTS.FACT_SALES
    GROUP BY store, dept
)
SELECT
    store,
    dept,
    total_sales,
    DENSE_RANK() OVER (
        PARTITION BY store
        ORDER BY total_sales DESC
    )                                   AS department_rank
FROM department_sales;

COMMENT ON VIEW REPORTING.VW_TOP_DEPARTMENTS IS
    'Ranked departments by total sales per store';

-- ----------------------------------------------------------------------------
-- REPORTING.VW_STORE_WEEK_METRICS
-- Store-week dashboard view with sales rollups and external features
-- Source: MARTS.FACT_STORE_WEEKLY_SALES
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW REPORTING.VW_STORE_WEEK_METRICS AS
SELECT
    store,
    sales_date,
    store_type,
    store_size,
    is_holiday,
    total_weekly_sales,
    avg_department_weekly_sales,
    active_departments,
    temperature,
    fuel_price,
    cpi,
    unemployment
FROM MARTS.FACT_STORE_WEEKLY_SALES;

COMMENT ON VIEW REPORTING.VW_STORE_WEEK_METRICS IS
    'Store-week metrics combining sales aggregates and external features';

-- Optional grants (uncomment and adjust role name if needed):
-- GRANT SELECT ON ALL VIEWS IN SCHEMA REPORTING TO ROLE <YOUR_ROLE>;

-- Verify views
SHOW VIEWS IN SCHEMA REPORTING;
