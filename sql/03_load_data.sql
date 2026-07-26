-- ============================================================================
-- 03_load_data.sql
-- Load Kaggle CSV files into RAW tables
-- ============================================================================
-- Purpose: Ingest local CSV files into Snowflake RAW schema.
--
-- Prerequisites:
--   1. Run 01_create_database.sql and 02_create_raw_tables.sql
--   2. Upload CSVs to RAW.CSV_STAGE (PUT commands or Snowflake UI)
--
-- Required source files: train.csv, test.csv, features.csv, stores.csv
--
-- NOTE: CREATE OR REPLACE STAGE recreates the stage if it already exists.
-- ============================================================================

USE DATABASE WALMART_SALES;
USE SCHEMA RAW;
USE WAREHOUSE WALMART_WH;

-- ----------------------------------------------------------------------------
-- Step 1: Internal stage and CSV file format
-- Kaggle dates are ISO format (YYYY-MM-DD, e.g. 2010-02-05).
-- Kaggle uses "NA" for missing markdown / CPI values — included in NULL_IF.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE STAGE RAW.CSV_STAGE
    FILE_FORMAT = (
        TYPE = 'CSV'
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
        SKIP_HEADER = 1
        NULL_IF = ('NULL', 'null', '', 'NA')
        EMPTY_FIELD_AS_NULL = TRUE
        DATE_FORMAT = 'YYYY-MM-DD'
    )
    COMMENT = 'Internal stage for Kaggle Walmart CSV uploads';

-- ----------------------------------------------------------------------------
-- Step 2: Upload files from local machine (SnowSQL examples)
-- AUTO_COMPRESS=TRUE creates .csv.gz files on the stage.
-- Adjust the local file path to match your environment.
-- ----------------------------------------------------------------------------
-- PUT file:///path/to/train.csv    @RAW.CSV_STAGE AUTO_COMPRESS=TRUE;
-- PUT file:///path/to/test.csv     @RAW.CSV_STAGE AUTO_COMPRESS=TRUE;
-- PUT file:///path/to/features.csv @RAW.CSV_STAGE AUTO_COMPRESS=TRUE;
-- PUT file:///path/to/stores.csv   @RAW.CSV_STAGE AUTO_COMPRESS=TRUE;

-- If files were uploaded through the Snowflake UI without gzip compression,
-- remove the .gz suffix from the stage file paths in the COPY commands below
-- (e.g. use train.csv instead of train.csv.gz).

-- Confirm staged files before loading
LIST @RAW.CSV_STAGE;

-- ----------------------------------------------------------------------------
-- Step 3: COPY INTO raw tables
-- ON_ERROR = 'ABORT_STATEMENT' fails the load immediately on any bad row.
-- Column order in CSV must match table DDL (see 02_create_raw_tables.sql).
-- ----------------------------------------------------------------------------
COPY INTO RAW.TRAIN
FROM @RAW.CSV_STAGE/train.csv.gz
ON_ERROR = 'ABORT_STATEMENT';

COPY INTO RAW.TEST
FROM @RAW.CSV_STAGE/test.csv.gz
ON_ERROR = 'ABORT_STATEMENT';

COPY INTO RAW.FEATURES
FROM @RAW.CSV_STAGE/features.csv.gz
ON_ERROR = 'ABORT_STATEMENT';

COPY INTO RAW.STORES
FROM @RAW.CSV_STAGE/stores.csv.gz
ON_ERROR = 'ABORT_STATEMENT';

-- ----------------------------------------------------------------------------
-- Step 4: Validate row counts after load
-- ----------------------------------------------------------------------------
SELECT 'RAW.TRAIN'    AS table_name, COUNT(*) AS row_count FROM RAW.TRAIN
UNION ALL
SELECT 'RAW.TEST',     COUNT(*) FROM RAW.TEST
UNION ALL
SELECT 'RAW.FEATURES', COUNT(*) FROM RAW.FEATURES
UNION ALL
SELECT 'RAW.STORES',   COUNT(*) FROM RAW.STORES;
