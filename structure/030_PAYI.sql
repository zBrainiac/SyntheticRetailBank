-- ============================================================
-- PAY_RAW_001 Schema - Payment Transaction Data
-- Generated on: 2025-09-22 15:50:17
-- ============================================================
--
-- This schema contains payment transaction data with multi-currency support
-- for the synthetic EMEA retail bank data generator.
--
-- Objects created:
-- - Stages: PAYI_TRANSACTIONS
-- - File Formats: PAYI_FF_TRANSACTION_CSV  
-- - Tables: PAYI_TRANSACTIONS
-- - Streams: PAYI_STREAM_TRANSACTION_FILES
-- - Tasks: PAYI_TASK_LOAD_TRANSACTIONS
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA PAY_RAW_001;

-- ============================================================
-- INTERNAL STAGES
-- ============================================================

-- Stage for transaction files
CREATE OR REPLACE STAGE PAYI_TRANSACTIONS
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Internal stage for transaction CSV files';

-- ============================================================
-- FILE FORMATS
-- ============================================================

-- Transaction CSV file format
CREATE OR REPLACE FILE FORMAT PAYI_FF_TRANSACTION_CSV
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
-- PAYI_TRANSACTIONS TABLE
-- ============================================================
-- Payment transaction data with FX conversions and settlement dates
-- Located in PAY schema for payment data

CREATE OR REPLACE TABLE PAYI_TRANSACTIONS (
    BOOKING_DATE TIMESTAMP_NTZ NOT NULL COMMENT 'Transaction timestamp when recorded (ISO 8601 UTC format: YYYY-MM-DDTHH:MM:SS.fffffZ)',
    VALUE_DATE DATE NOT NULL COMMENT 'Date when funds are settled/available (YYYY-MM-DD)',
    TRANSACTION_ID VARCHAR(50) NOT NULL COMMENT 'Unique transaction identifier',
    ACCOUNT_ID VARCHAR(30) NOT NULL COMMENT 'Reference to account ID in ACCI_ACCOUNTS',
    AMOUNT DECIMAL(15,2) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Signed transaction amount in original currency (positive = incoming, negative = outgoing)',
    CURRENCY VARCHAR(3) NOT NULL COMMENT 'Transaction currency (USD, EUR, GBP, JPY, CAD, CHF)',
    BASE_AMOUNT DECIMAL(15,2) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Signed transaction amount converted to base currency USD (positive = incoming, negative = outgoing)',
    BASE_CURRENCY VARCHAR(3) NOT NULL COMMENT 'Currency of Account - ISO 4217 currency code',
    FX_RATE DECIMAL(15,6) NOT NULL COMMENT 'Exchange rate used for conversion (from transaction currency to base currency)',
    COUNTERPARTY_ACCOUNT VARCHAR(100) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Counterparty account identifier',
    DESCRIPTION VARCHAR(500) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Transaction description (may contain anomaly indicators in [brackets])',

    -- GENERATED ALWAYS AS virtual columns not supported - replaced with comments for documentation
    -- BOOKING_DATE_LOCAL: Use DATE(BOOKING_DATE) in queries
    -- AMOUNT_CATEGORY: Use CASE WHEN BASE_AMOUNT < 1000 THEN 'SMALL' WHEN BASE_AMOUNT < 10000 THEN 'MEDIUM' ELSE 'LARGE' END
    -- IS_ANOMALOUS: Use DESCRIPTION LIKE '%[%]%' in queries

    -- Metadata
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),

    -- Constraints
    CONSTRAINT PK_PAYI_TRANSACTIONS PRIMARY KEY (TRANSACTION_ID),
    CONSTRAINT FK_PAYI_TRANSACTIONS_ACCOUNT FOREIGN KEY (ACCOUNT_ID) REFERENCES AAA_DEV_SYNTHETIC_BANK.CRM_RAW_001.ACCI_ACCOUNTS (ACCOUNT_ID)
    -- CHECK constraints not supported in Snowflake - replaced with comments for documentation
    -- CHK_CURRENCY_TXN: CURRENCY should be in ('USD', 'EUR', 'GBP', 'JPY', 'CAD', 'CHF')
    -- CHK_BASE_CURRENCY_TXN: BASE_CURRENCY should be 'USD'
    -- CHK_AMOUNT_SIGNED: AMOUNT and BASE_AMOUNT can be positive (incoming) or negative (outgoing)
    -- CHK_FX_RATE_POSITIVE: FX_RATE should be > 0
    -- CHK_VALUE_DATE_LOGIC: VALUE_DATE should be >= BOOKING_DATE
)
COMMENT = 'Payment transactions with multi-currency support and anomaly detection';

-- ============================================================
-- STREAMS ON STAGES
-- ============================================================

-- Stream to detect new transaction files
CREATE OR REPLACE STREAM PAYI_STREAM_TRANSACTION_FILES
    ON STAGE PAYI_TRANSACTIONS
    COMMENT = 'Stream to detect new transaction files on stage';

-- ============================================================
-- AUTOMATED LOADING TASKS
-- ============================================================

-- Task to load transaction files when new files arrive
CREATE OR REPLACE TASK PAYI_TASK_LOAD_TRANSACTIONS
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('PAYI_STREAM_TRANSACTION_FILES')
AS
    COPY INTO PAYI_TRANSACTIONS (BOOKING_DATE, VALUE_DATE, TRANSACTION_ID, ACCOUNT_ID, AMOUNT, CURRENCY, BASE_AMOUNT, BASE_CURRENCY, FX_RATE, COUNTERPARTY_ACCOUNT, DESCRIPTION)
    FROM @PAYI_TRANSACTIONS
    PATTERN = '.*pay_transactions.*\.csv'
    FILE_FORMAT = PAYI_FF_TRANSACTION_CSV
    ON_ERROR = CONTINUE;

-- ============================================================
-- TASK ACTIVATION
-- ============================================================
-- Activate all tasks to enable automated loading

ALTER TASK PAYI_TASK_LOAD_TRANSACTIONS RESUME;

-- ============================================================
-- PAYI_RAW_001 Schema setup completed!
-- ============================================================
