-- ============================================================
-- REF_RAW_001 Schema - Reference Data (FX Rates)
-- Generated on: 2025-09-22 15:50:17
-- ============================================================
--
-- This schema contains reference data including foreign exchange rates
-- for the synthetic EMEA retail bank data generator.
--
-- Objects created:
-- - Stages: REFI_FX_RATES
-- - File Formats: REFI_FF_FX_RATES_CSV  
-- - Tables: REFI_FX_RATES
-- - Streams: REFI_STREAM_FX_RATE_FILES
-- - Tasks: REFI_TASK_LOAD_FX_RATES
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REF_RAW_001;

-- ============================================================
-- INTERNAL STAGES
-- ============================================================

-- Stage for FX rates files
CREATE OR REPLACE STAGE REFI_FX_RATES
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Internal stage for FX rates CSV files';

-- ============================================================
-- FILE FORMATS
-- ============================================================

-- FX Rates CSV file format
CREATE OR REPLACE FILE FORMAT REFI_FF_FX_RATES_CSV
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    ESCAPE = 'NONE'
    ESCAPE_UNENCLOSED_FIELD = '\134'
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF"Z"';

-- ============================================================
-- TABLES
-- ============================================================

-- ============================================================
-- REFI_FX_RATES TABLE
-- ============================================================
-- Daily foreign exchange rates with bid/ask spreads
-- Located in REF schema for reference data

CREATE OR REPLACE TABLE REFI_FX_RATES (
    DATE DATE NOT NULL COMMENT 'Rate date (YYYY-MM-DD)',
    FROM_CURRENCY VARCHAR(3) NOT NULL COMMENT 'Source currency',
    TO_CURRENCY VARCHAR(3) NOT NULL COMMENT 'Target currency',
    MID_RATE DECIMAL(15,6) NOT NULL COMMENT 'Mid-market exchange rate',
    BID_RATE DECIMAL(15,6) NOT NULL COMMENT 'Bid exchange rate (bank buys at this rate)',
    ASK_RATE DECIMAL(15,6) NOT NULL COMMENT 'Ask exchange rate (bank sells at this rate)',

    -- Metadata
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),

    -- Constraints
    CONSTRAINT PK_REFI_FX_RATES PRIMARY KEY (DATE, FROM_CURRENCY, TO_CURRENCY)
    -- CHECK constraints not supported in Snowflake - replaced with comments for documentation
    -- CHK_FX_CURRENCIES: FROM_CURRENCY and TO_CURRENCY should be in ('USD', 'EUR', 'GBP', 'JPY', 'CAD') and different
    -- CHK_FX_RATES_POSITIVE: MID_RATE, BID_RATE, ASK_RATE should be > 0
    -- CHK_FX_SPREAD: BID_RATE <= MID_RATE <= ASK_RATE
)
COMMENT = 'Daily foreign exchange rates with realistic bid/ask spreads';

-- ============================================================
-- STREAMS ON STAGES
-- ============================================================

-- Stream to detect new FX rates files
CREATE OR REPLACE STREAM REFI_STREAM_FX_RATE_FILES
    ON STAGE REFI_FX_RATES
    COMMENT = 'Stream to detect new FX rates files on stage';

-- ============================================================
-- AUTOMATED LOADING TASKS
-- ============================================================

-- Task to load FX rates files when new files arrive
CREATE OR REPLACE TASK REFI_TASK_LOAD_FX_RATES
    WAREHOUSE = MD_TEST_WH
    SCHEDULE = '1 HOUR'
    WHEN SYSTEM$STREAM_HAS_DATA('REFI_STREAM_FX_RATE_FILES')
AS
    COPY INTO REFI_FX_RATES (DATE, FROM_CURRENCY, TO_CURRENCY, MID_RATE, BID_RATE, ASK_RATE)
    FROM @REFI_FX_RATES
    PATTERN = '.*fx_rates.*\.csv'
    FILE_FORMAT = REFI_FF_FX_RATES_CSV
    ON_ERROR = CONTINUE;

-- ============================================================
-- TASK ACTIVATION
-- ============================================================
-- Activate all tasks to enable automated loading

ALTER TASK REFI_TASK_LOAD_FX_RATES RESUME;

-- ============================================================
-- REFI_RAW_001 Schema setup completed!
-- ============================================================
