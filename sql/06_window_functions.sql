-- ============================================================================
-- 06_window_functions.sql
-- Advanced SQL: window functions for retail analytics
-- ============================================================================
-- Purpose: Demonstrate analytical SQL skills using Snowflake window functions.
--
-- Window functions compute across related rows WITHOUT collapsing groups
-- (unlike GROUP BY). Each row keeps its detail while gaining context.
-- ============================================================================

USE DATABASE WALMART_SALES;
USE SCHEMA MARTS;
USE WAREHOUSE WALMART_WH;

-- ----------------------------------------------------------------------------
-- Example 1: 4-week moving average of weekly sales by store–department
-- ROWS BETWEEN 3 PRECEDING AND CURRENT ROW = current week + prior 3 weeks
-- ----------------------------------------------------------------------------
SELECT
    store,
    dept,
    sales_date,
    weekly_sales,
    AVG(weekly_sales) OVER (
        PARTITION BY store, dept
        ORDER BY sales_date
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ) AS moving_avg_4wk
FROM MARTS.FACT_SALES
ORDER BY store, dept, sales_date;

-- ----------------------------------------------------------------------------
-- Example 2: Week-over-week sales change (%)
-- LAG() returns the previous week's sales within the same store + dept.
-- NULLIF prevents division by zero when prior_week_sales is 0.
-- ----------------------------------------------------------------------------
SELECT
    store,
    dept,
    sales_date,
    weekly_sales,
    LAG(weekly_sales) OVER (
        PARTITION BY store, dept
        ORDER BY sales_date
    ) AS prior_week_sales,
    (
        weekly_sales
        - LAG(weekly_sales) OVER (
            PARTITION BY store, dept
            ORDER BY sales_date
        )
    ) / NULLIF(
        LAG(weekly_sales) OVER (
            PARTITION BY store, dept
            ORDER BY sales_date
        ),
        0
    ) AS wow_pct_change
FROM MARTS.FACT_SALES
ORDER BY store, dept, sales_date;

-- ----------------------------------------------------------------------------
-- Example 3: Rank departments by total sales within each store
-- DENSE_RANK leaves no gaps when two departments tie for the same rank.
-- ----------------------------------------------------------------------------
SELECT
    store,
    dept,
    SUM(weekly_sales) AS total_sales,
    DENSE_RANK() OVER (
        PARTITION BY store
        ORDER BY SUM(weekly_sales) DESC
    ) AS department_rank
FROM MARTS.FACT_SALES
GROUP BY store, dept
ORDER BY store, department_rank;

-- ----------------------------------------------------------------------------
-- Example 4: Holiday vs non-holiday sales comparison
-- Aggregates total and average department-level sales by holiday flag.
-- ----------------------------------------------------------------------------
SELECT
    is_holiday,
    COUNT(*)              AS sales_records,
    SUM(weekly_sales)     AS total_sales,
    AVG(weekly_sales)     AS avg_department_sales
FROM MARTS.FACT_SALES
GROUP BY is_holiday
ORDER BY is_holiday;

-- Verification
SELECT COUNT(*) AS fact_sales_rows FROM MARTS.FACT_SALES;
