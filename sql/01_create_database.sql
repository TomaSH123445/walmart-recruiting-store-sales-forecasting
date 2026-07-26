-- ============================================================================
-- 01_create_database.sql
-- Walmart Store Sales Forecasting — Snowflake environment setup
-- ============================================================================
-- Purpose: Create the database, schemas (layers), and a compute warehouse.
--
-- Snowflake layering convention used in this project:
--   RAW       → landing zone for Kaggle CSV data (as-is)
--   STAGING   → cleaned, typed, deduplicated tables
--   MARTS     → business-ready fact/dimension tables
--   REPORTING → views for dashboards and portfolio demos
--
-- Run this script first, then proceed through 02–08 in order.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Database
-- ----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS WALMART_SALES
    COMMENT = 'Walmart Store Sales Forecasting — portfolio project';

USE DATABASE WALMART_SALES;

-- ----------------------------------------------------------------------------
-- Schemas (data layers)
-- Each schema represents a stage in the analytics pipeline.
-- ----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS RAW
    COMMENT = 'Raw Kaggle CSV landing tables — minimal transformation';

CREATE SCHEMA IF NOT EXISTS STAGING
    COMMENT = 'Cleaned and standardized tables ready for modeling';

CREATE SCHEMA IF NOT EXISTS MARTS
    COMMENT = 'Business-ready facts and dimensions for analysis';

CREATE SCHEMA IF NOT EXISTS REPORTING
    COMMENT = 'Reporting views for dashboards and SQL demos';

-- ----------------------------------------------------------------------------
-- Warehouse
-- XSMALL is cost-effective for learning and portfolio workloads.
-- AUTO_SUSPEND = 60 stops billing after 60 seconds of idle time.
-- ----------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS WALMART_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Compute warehouse for Walmart sales analytics';

-- Optional grants (uncomment and adjust role name if needed):
-- GRANT USAGE ON DATABASE WALMART_SALES TO ROLE <YOUR_ROLE>;
-- GRANT USAGE ON ALL SCHEMAS IN DATABASE WALMART_SALES TO ROLE <YOUR_ROLE>;
-- GRANT USAGE ON WAREHOUSE WALMART_WH TO ROLE <YOUR_ROLE>;

-- Verify setup
SHOW SCHEMAS IN DATABASE WALMART_SALES;
SHOW WAREHOUSES LIKE 'WALMART_WH';
