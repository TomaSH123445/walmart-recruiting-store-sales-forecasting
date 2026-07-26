-- ============================================================================
-- 02_create_raw_tables.sql
-- Raw layer: mirror Kaggle CSV structure with minimal typing
-- ============================================================================
-- Purpose: Define landing tables that match the source files column-for-column.
-- Raw tables preserve source data as-is so you can always trace back to Kaggle.
--
-- Source files (place locally — not committed to Git):
--   train.csv, test.csv, features.csv, stores.csv
--
-- NOTE: CREATE OR REPLACE drops and recreates each table if it already exists.
-- ============================================================================

USE DATABASE WALMART_SALES;
USE SCHEMA RAW;

-- ----------------------------------------------------------------------------
-- RAW.TRAIN
-- Historical sales at Store + Dept + Date grain
-- Source CSV columns: Store, Dept, Date, Weekly_Sales, IsHoliday
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE RAW.TRAIN (
    store           NUMBER(3, 0),
    dept            NUMBER(3, 0),
    date            DATE,
    weekly_sales    NUMBER(18, 2),
    isholiday       BOOLEAN
)
COMMENT = 'Raw training sales from Kaggle train.csv — Store + Dept + Date grain';

-- ----------------------------------------------------------------------------
-- RAW.TEST
-- Holdout period without sales — same grain as TRAIN minus Weekly_Sales
-- Source CSV columns: Store, Dept, Date, IsHoliday
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE RAW.TEST (
    store           NUMBER(3, 0),
    dept            NUMBER(3, 0),
    date            DATE,
    isholiday       BOOLEAN
)
COMMENT = 'Raw test rows from Kaggle test.csv — forecasting holdout period';

-- ----------------------------------------------------------------------------
-- RAW.FEATURES
-- Store-level weekly external features
-- Source CSV columns: Store, Date, Temperature, Fuel_Price, MarkDown1-5,
--                     CPI, Unemployment, IsHoliday
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE RAW.FEATURES (
    store           NUMBER(3, 0),
    date            DATE,
    temperature     NUMBER(10, 2),
    fuel_price      NUMBER(10, 3),
    markdown1       NUMBER(18, 2),
    markdown2       NUMBER(18, 2),
    markdown3       NUMBER(18, 2),
    markdown4       NUMBER(18, 2),
    markdown5       NUMBER(18, 2),
    cpi             NUMBER(12, 6),
    unemployment    NUMBER(10, 3),
    isholiday       BOOLEAN
)
COMMENT = 'Raw store features from Kaggle features.csv — Store + Date grain';

-- ----------------------------------------------------------------------------
-- RAW.STORES
-- Static store attributes — one row per Store
-- Source CSV columns: Store, Type, Size
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE RAW.STORES (
    store           NUMBER(3, 0),
    type            VARCHAR(1),
    size            NUMBER(10, 0)
)
COMMENT = 'Raw store metadata from Kaggle stores.csv — one row per store';

-- Verify tables
SHOW TABLES IN SCHEMA RAW;
