-- ============================================================
-- EQT_RAW_001 Schema - Equity Trading Data
-- Generated on: 2025-09-22 15:50:17
-- ============================================================
--
-- This schema contains equity trading data following FIX protocol standards
-- for the synthetic EMEA retail bank data generator.
--
-- Objects created:
-- - Stages: EQTI_TRADES
-- - File Formats: EQTI_FF_TRADES_CSV  
-- - Tables: EQTI_TRADES
-- - Streams: EQTI_STREAM_TRADES_FILES
-- - Tasks: EQTI_TASK_LOAD_TRADES
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA EQT_RAW_001;

-- ============================================================
-- INTERNAL STAGES
-- ============================================================

-- Stage for equity trades files
CREATE OR REPLACE STAGE EQTI_TRADES
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Internal stage for equity trades CSV files';

-- ============================================================
-- FILE FORMATS
-- ============================================================

-- Equity Trades CSV file format
CREATE OR REPLACE FILE FORMAT EQTI_FF_TRADES_CSV
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
-- EQTI_TRADES TABLE (FIX PROTOCOL)
-- ============================================================
-- Equity trading data via FIX protocol with CHF as base currency
-- Located in EQT schema for equity trading data
-- Uses ACCOUNT_ID from ACCI_ACCOUNTS where ACCOUNT_TYPE = 'INVESTMENT'

CREATE OR REPLACE TABLE EQTI_TRADES (
    TRADE_DATE TIMESTAMP_NTZ NOT NULL COMMENT 'Trade execution timestamp (ISO 8601 UTC format)',
    SETTLEMENT_DATE DATE NOT NULL COMMENT 'Settlement date (YYYY-MM-DD)',
    TRADE_ID VARCHAR(50) NOT NULL COMMENT 'Unique trade identifier',
    CUSTOMER_ID VARCHAR(20) NOT NULL COMMENT 'Reference to customer',
    ACCOUNT_ID VARCHAR(50) NOT NULL COMMENT 'Investment account used for settlement (References ACCI_ACCOUNTS.ACCOUNT_ID where ACCOUNT_TYPE = ''INVESTMENT'')',
    ORDER_ID VARCHAR(50) NOT NULL COMMENT 'Order reference',
    EXEC_ID VARCHAR(50) NOT NULL COMMENT 'Execution reference',
    SYMBOL VARCHAR(20) NOT NULL COMMENT 'Stock symbol',
    ISIN VARCHAR(12) COMMENT 'International Securities Identification Number',
    SIDE CHAR(1) NOT NULL COMMENT 'FIX protocol side (1=Buy, 2=Sell)',
    QUANTITY NUMBER(15,4) NOT NULL WITH TAG (AAA_DEV_SYNTHETIC_BANK.CMD_AGG_001.SENSITIVITY_LEVEL='restricted') COMMENT 'Number of shares/units',
    PRICE NUMBER(18,6) NOT NULL COMMENT 'Price per share/unit',
    CURRENCY VARCHAR(3) NOT NULL COMMENT 'Trade currency',
    GROSS_AMOUNT NUMBER(18,2) NOT NULL WITH TAG (AAA_DEV_SYNTHETIC_BANK.CMD_AGG_001.SENSITIVITY_LEVEL='restricted') COMMENT 'Signed gross trade amount (positive for buys, negative for sells)',
    COMMISSION NUMBER(12,4) NOT NULL WITH TAG (AAA_DEV_SYNTHETIC_BANK.CMD_AGG_001.SENSITIVITY_LEVEL='restricted') COMMENT 'Trading commission',
    NET_AMOUNT NUMBER(18,2) NOT NULL WITH TAG (AAA_DEV_SYNTHETIC_BANK.CMD_AGG_001.SENSITIVITY_LEVEL='restricted') COMMENT 'Signed net amount after commission',
    BASE_CURRENCY VARCHAR(3) NOT NULL DEFAULT 'CHF' COMMENT 'Base currency for reporting (CHF)',
    BASE_GROSS_AMOUNT NUMBER(18,2) NOT NULL WITH TAG (AAA_DEV_SYNTHETIC_BANK.CMD_AGG_001.SENSITIVITY_LEVEL='restricted') COMMENT 'Gross amount in CHF',
    BASE_NET_AMOUNT NUMBER(18,2) NOT NULL WITH TAG (AAA_DEV_SYNTHETIC_BANK.CMD_AGG_001.SENSITIVITY_LEVEL='restricted') COMMENT 'Net amount in CHF',
    FX_RATE NUMBER(12,6) NOT NULL COMMENT 'Exchange rate to CHF',
    MARKET VARCHAR(10) NOT NULL COMMENT 'Exchange/market (NYSE, LSE, XETRA, etc.)',
    ORDER_TYPE VARCHAR(15) NOT NULL COMMENT 'Order type (MARKET, LIMIT, STOP, etc.)',
    EXEC_TYPE VARCHAR(15) NOT NULL COMMENT 'Execution type (NEW, PARTIAL_FILL, FILL, etc.)',
    TIME_IN_FORCE VARCHAR(10) COMMENT 'Time in force (DAY, GTC, IOC, etc.)',
    BROKER_ID VARCHAR(20) COMMENT 'Executing broker',
    VENUE VARCHAR(20) COMMENT 'Trading venue',

    -- Metadata
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),

    -- Constraints
    CONSTRAINT PK_EQTI_TRADES PRIMARY KEY (TRADE_ID),
    CONSTRAINT FK_EQTI_TRADES_CUSTOMER FOREIGN KEY (CUSTOMER_ID) REFERENCES AAA_DEV_SYNTHETIC_BANK.CRM_RAW_001.CRMI_PARTY(CUSTOMER_ID),
    CONSTRAINT FK_EQTI_TRADES_ACCOUNT FOREIGN KEY (ACCOUNT_ID) REFERENCES AAA_DEV_SYNTHETIC_BANK.CRM_RAW_001.ACCI_ACCOUNTS(ACCOUNT_ID)
    -- CHECK constraints not supported in Snowflake - replaced with comments for documentation
    -- CHK_EQ_SIDE: SIDE should be '1' (Buy) or '2' (Sell) per FIX protocol
    -- CHK_EQ_CURRENCY: CURRENCY should be in ('USD', 'EUR', 'GBP', 'JPY', 'CHF')
    -- CHK_EQ_BASE_CURRENCY: BASE_CURRENCY should be 'CHF'
    -- CHK_EQ_QUANTITY_POSITIVE: QUANTITY should be > 0
    -- CHK_EQ_PRICE_POSITIVE: PRICE should be > 0
    -- CHK_EQ_COMMISSION_POSITIVE: COMMISSION should be >= 0
    -- CHK_EQ_FX_RATE_POSITIVE: FX_RATE should be > 0
    -- CHK_EQ_SETTLEMENT_DATE: SETTLEMENT_DATE should be >= TRADE_DATE
    -- CHK_EQ_ACCOUNT_TYPE: Referenced ACCOUNT_ID should have ACCOUNT_TYPE = 'INVESTMENT'
)
COMMENT = 'Equity trades via FIX protocol with CHF as base currency. Uses INVESTMENT accounts from ACCI_ACCOUNTS. Signed amounts: positive for purchases, negative for sales.';

-- ============================================================
-- STREAMS ON STAGES
-- ============================================================

-- Stream to detect new equity trades files
CREATE OR REPLACE STREAM EQTI_STREAM_TRADES_FILES
    ON STAGE EQTI_TRADES
    COMMENT = 'Stream to detect new equity trades files on stage';

-- ============================================================
-- AUTOMATED LOADING TASKS
-- ============================================================

-- Task to load equity trades files when new files arrive
CREATE OR REPLACE TASK EQTI_TASK_LOAD_TRADES
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('EQTI_STREAM_TRADES_FILES')
AS
    COPY INTO EQTI_TRADES (TRADE_DATE, SETTLEMENT_DATE, TRADE_ID, CUSTOMER_ID, ACCOUNT_ID, ORDER_ID, EXEC_ID, SYMBOL, ISIN, SIDE, QUANTITY, PRICE, CURRENCY, GROSS_AMOUNT, COMMISSION, NET_AMOUNT, BASE_CURRENCY, BASE_GROSS_AMOUNT, BASE_NET_AMOUNT, FX_RATE, MARKET, ORDER_TYPE, EXEC_TYPE, TIME_IN_FORCE, BROKER_ID, VENUE)
    FROM @EQTI_TRADES
    PATTERN = '.*trades.*\.csv'
    FILE_FORMAT = EQTI_FF_TRADES_CSV
    ON_ERROR = CONTINUE;

-- ============================================================
-- TASK ACTIVATION
-- ============================================================
-- Activate all tasks to enable automated loading

ALTER TASK EQTI_TASK_LOAD_TRADES RESUME;

-- ============================================================
-- EQTI_RAW_001 Schema setup completed!
-- ============================================================
