-- ============================================================
-- REP_AGG_001 Schema - Reporting & Analytics
-- Updated on: 2025-09-29 (Updated to use CRM_AGG_001 aggregation layer)
-- ============================================================
--
-- This schema contains dynamic tables for reporting and analytics
-- for the synthetic EMEA retail bank data generator.
--
-- DATA LAYER ARCHITECTURE:
-- - Uses CRM_AGG_001 aggregation layer (not raw CRM_RAW_001)
-- - Uses PAY_AGG_001 aggregation layer (not raw PAY_RAW_001)
-- - Leverages pre-computed customer, account, and payment aggregations
-- - Proper data architecture: RAW → AGG → REPORTING
--
-- Objects created:
-- - Dynamic Tables: Customer, Transaction, and Equity Analytics
-- - Refresh Schedule: 1 hour (15 minutes for high-value trades)
-- - Warehouse: MD_TEST_WH
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REP_AGG_001;

-- ============================================================
-- REPORTING DYNAMIC TABLES
-- ============================================================
-- Pre-built dynamic tables for common CDD analysis patterns
-- Refreshed automatically every 1 hour with TARGET_LAG = '1 hour'

-- Customer summary with transaction statistics
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_CUSTOMER_SUMMARY(
    CUSTOMER_ID COMMENT 'Unique customer identifier for relationship management (CUST_XXXXX format)',
    FULL_NAME COMMENT 'Customer full name (First + Last) for reporting and compliance',
    HAS_ANOMALY COMMENT 'Flag indicating if customer has anomalous behavior patterns',
    ONBOARDING_DATE COMMENT 'Date when customer relationship was established',
    TOTAL_ACCOUNTS COMMENT 'Number of accounts held by customer',
    CURRENCY_COUNT COMMENT 'Number of different currencies in customer portfolio',
    ACCOUNT_CURRENCIES COMMENT 'Comma-separated list of all currencies used by customer',
    TOTAL_TRANSACTIONS COMMENT 'Total number of transactions across all accounts',
    TOTAL_BASE_AMOUNT COMMENT 'Total transaction volume in base currency',
    AVG_TRANSACTION_AMOUNT COMMENT 'Average transaction size for customer profiling',
    MAX_TRANSACTION_AMOUNT COMMENT 'Largest single transaction for risk assessment',
    ANOMALOUS_TRANSACTIONS COMMENT 'Count of transactions with suspicious patterns'
) COMMENT = 'Comprehensive customer profiling with transaction statistics for relationship management, risk assessment, and business intelligence'
TARGET_LAG = '1 hour' WAREHOUSE = MD_TEST_WH
AS
SELECT
    c.CUSTOMER_ID,
    CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME) AS FULL_NAME,
    c.HAS_ANOMALY,
    c.ONBOARDING_DATE,
    COUNT(a.ACCOUNT_ID) AS TOTAL_ACCOUNTS,
    COUNT(DISTINCT a.BASE_CURRENCY) AS CURRENCY_COUNT,
    LISTAGG(DISTINCT a.BASE_CURRENCY, ', ') AS ACCOUNT_CURRENCIES,
    COUNT(t.TRANSACTION_ID) AS TOTAL_TRANSACTIONS,
    SUM(t.AMOUNT) AS TOTAL_BASE_AMOUNT,
    AVG(t.AMOUNT) AS AVG_TRANSACTION_AMOUNT,
    MAX(t.AMOUNT) AS MAX_TRANSACTION_AMOUNT,
    COUNT(CASE WHEN t.DESCRIPTION LIKE '%[%]%' THEN 1 END) AS ANOMALOUS_TRANSACTIONS
FROM AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRMA_AGG_DT_CUSTOMER c
LEFT JOIN AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.ACCA_AGG_DT_ACCOUNTS a ON c.CUSTOMER_ID = a.CUSTOMER_ID
LEFT JOIN AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001.PAYA_AGG_DT_TRANSACTION_ANOMALIES t ON c.CUSTOMER_ID = t.CUSTOMER_ID
GROUP BY c.CUSTOMER_ID, c.FIRST_NAME, c.FAMILY_NAME, c.HAS_ANOMALY, c.ONBOARDING_DATE;

-- Daily transaction summary
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_DAILY_TRANSACTION_SUMMARY(
    TRANSACTION_DATE COMMENT 'Business date for daily reporting and trend analysis',
    TRANSACTION_COUNT COMMENT 'Total daily transaction volume for operational metrics',
    UNIQUE_CUSTOMERS COMMENT 'Number of active customers per day',
    TOTAL_BASE_AMOUNT COMMENT 'Daily transaction value in base currency',
    AVG_BASE_AMOUNT COMMENT 'Average transaction size for market analysis',
    INCOMING_COUNT COMMENT 'Number of incoming/credit transactions',
    OUTGOING_COUNT COMMENT 'Number of outgoing/debit transactions',
    ANOMALOUS_COUNT COMMENT 'Daily suspicious transaction count',
    CURRENCY_COUNT COMMENT 'Number of different currencies traded daily'
) COMMENT = 'Daily transaction volume and pattern analysis for operational metrics, trend monitoring, and business intelligence reporting'
TARGET_LAG = '1 hour' WAREHOUSE = MD_TEST_WH
AS
SELECT
    DATE(BOOKING_DATE) AS TRANSACTION_DATE,
    COUNT(*) AS TRANSACTION_COUNT,
    COUNT(DISTINCT CUSTOMER_ID) AS UNIQUE_CUSTOMERS,
    SUM(AMOUNT) AS TOTAL_BASE_AMOUNT,
    AVG(AMOUNT) AS AVG_BASE_AMOUNT,
    COUNT(CASE WHEN AMOUNT > 0 THEN 1 END) AS INCOMING_COUNT,
    COUNT(CASE WHEN AMOUNT < 0 THEN 1 END) AS OUTGOING_COUNT,
    COUNT(CASE WHEN DESCRIPTION LIKE '%[%]%' THEN 1 END) AS ANOMALOUS_COUNT,
    COUNT(DISTINCT CURRENCY) AS CURRENCY_COUNT
FROM AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001.PAYA_AGG_DT_TRANSACTION_ANOMALIES
GROUP BY DATE(BOOKING_DATE)
ORDER BY TRANSACTION_DATE;

-- Currency exposure summary (non-CHF currencies)
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_CURRENCY_EXPOSURE_CURRENT(
    CURRENCY COMMENT 'Foreign currency code (ISO 4217) for exposure analysis',
    TRANSACTION_COUNT COMMENT 'Number of transactions in this currency',
    TOTAL_ORIGINAL_AMOUNT COMMENT 'Total exposure in original currency',
    TOTAL_CHF_AMOUNT COMMENT 'Total exposure converted to CHF (placeholder)',
    AVG_FX_RATE COMMENT 'Average exchange rate (placeholder for future FX integration)',
    MIN_FX_RATE COMMENT 'Minimum exchange rate observed (placeholder)',
    MAX_FX_RATE COMMENT 'Maximum exchange rate observed (placeholder)',
    UNIQUE_CUSTOMERS COMMENT 'Number of customers with exposure to this currency'
) COMMENT = 'Current foreign exchange exposure monitoring for risk management and regulatory reporting of non-CHF currency positions'
TARGET_LAG = '1 hour' WAREHOUSE = MD_TEST_WH
AS
SELECT
    CURRENCY,
    COUNT(*) AS TRANSACTION_COUNT,
    SUM(AMOUNT) AS TOTAL_ORIGINAL_AMOUNT,
    SUM(AMOUNT) AS TOTAL_CHF_AMOUNT,
    1.0 AS AVG_FX_RATE,
    1.0 AS MIN_FX_RATE,
    1.0 AS MAX_FX_RATE,
    COUNT(DISTINCT CUSTOMER_ID) AS UNIQUE_CUSTOMERS
FROM AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001.PAYA_AGG_DT_TRANSACTION_ANOMALIES
WHERE CURRENCY != 'CHF'
GROUP BY CURRENCY
ORDER BY TOTAL_CHF_AMOUNT DESC;

-- =====================================================
-- REPP_DT_CURRENCY_EXPOSURE_HISTORY - FX Exposure Time Series
-- =====================================================
-- BUSINESS PURPOSE: Historical foreign exchange exposure analysis with rolling trends
-- for market risk management and business intelligence.
-- =====================================================

-- Currency exposure over time (daily trends)
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_CURRENCY_EXPOSURE_HISTORY
TARGET_LAG = '1 hour'
WAREHOUSE = MD_TEST_WH
AS
SELECT
    DATE(BOOKING_DATE) AS EXPOSURE_DATE,                         -- Business date for time series analysis
    CURRENCY,                                                    -- Foreign currency for exposure tracking
    COUNT(*) AS DAILY_TRANSACTION_COUNT,                         -- Daily transaction volume per currency
    SUM(AMOUNT) AS DAILY_TOTAL_AMOUNT,                           -- Daily total exposure amount
    AVG(AMOUNT) AS DAILY_AVG_AMOUNT,                             -- Daily average transaction size
    MIN(AMOUNT) AS DAILY_MIN_AMOUNT,                             -- Smallest transaction of the day
    MAX(AMOUNT) AS DAILY_MAX_AMOUNT,                             -- Largest transaction of the day
    COUNT(DISTINCT CUSTOMER_ID) AS DAILY_UNIQUE_CUSTOMERS,       -- Number of customers active in this currency
    
    -- Rolling 7-day trends for market analysis
    SUM(COUNT(*)) OVER (
        PARTITION BY CURRENCY 
        ORDER BY DATE(BOOKING_DATE) 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS ROLLING_7D_TRANSACTION_COUNT,                           -- 7-day rolling transaction volume
    
    SUM(SUM(AMOUNT)) OVER (
        PARTITION BY CURRENCY 
        ORDER BY DATE(BOOKING_DATE) 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS ROLLING_7D_TOTAL_AMOUNT,                                -- 7-day rolling exposure amount
    
    AVG(SUM(AMOUNT)) OVER (
        PARTITION BY CURRENCY 
        ORDER BY DATE(BOOKING_DATE) 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS ROLLING_7D_AVG_DAILY_AMOUNT,                            -- 7-day average daily exposure
    
    -- Month-over-month comparison for trend analysis
    LAG(SUM(AMOUNT), 30) OVER (
        PARTITION BY CURRENCY 
        ORDER BY DATE(BOOKING_DATE)
    ) AS AMOUNT_30_DAYS_AGO,                                     -- Exposure amount 30 days prior for comparison
    
    -- Growth rate calculations for business intelligence
    CASE 
        WHEN LAG(SUM(AMOUNT), 30) OVER (PARTITION BY CURRENCY ORDER BY DATE(BOOKING_DATE)) > 0 
        THEN ROUND(
            ((SUM(AMOUNT) - LAG(SUM(AMOUNT), 30) OVER (PARTITION BY CURRENCY ORDER BY DATE(BOOKING_DATE))) / 
             LAG(SUM(AMOUNT), 30) OVER (PARTITION BY CURRENCY ORDER BY DATE(BOOKING_DATE))) * 100, 2
        )
        ELSE NULL
    END AS GROWTH_RATE_30D_PERCENT,                              -- 30-day growth rate percentage for trend monitoring
    
    -- Risk categorization for compliance monitoring
    CASE 
        WHEN COUNT(*) > 100 THEN 'HIGH_VOLUME'
        WHEN COUNT(*) > 50 THEN 'MEDIUM_VOLUME'
        ELSE 'LOW_VOLUME'
    END AS DAILY_VOLUME_CATEGORY,                                -- Daily transaction volume risk classification
    
    CASE 
        WHEN SUM(AMOUNT) > 1000000 THEN 'HIGH_EXPOSURE'
        WHEN SUM(AMOUNT) > 100000 THEN 'MEDIUM_EXPOSURE'
        ELSE 'LOW_EXPOSURE'
    END AS DAILY_EXPOSURE_CATEGORY                               -- Daily exposure amount risk classification
    
FROM AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001.PAYA_AGG_DT_TRANSACTION_ANOMALIES
WHERE CURRENCY != 'CHF'
GROUP BY DATE(BOOKING_DATE), CURRENCY
ORDER BY EXPOSURE_DATE DESC, DAILY_TOTAL_AMOUNT DESC;

-- =====================================================
-- REPP_DT_CURRENCY_SETTLEMENT_EXPOSURE - Settlement Risk Analysis
-- =====================================================
-- BUSINESS PURPOSE: Settlement timing and liquidity risk analysis for treasury
-- management and operational risk monitoring.
-- =====================================================

-- Settlement timing exposure analysis
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_CURRENCY_SETTLEMENT_EXPOSURE
TARGET_LAG = '1 hour'
WAREHOUSE = MD_TEST_WH
AS
SELECT
    DATE(VALUE_DATE) AS SETTLEMENT_DATE,                         -- Settlement date for liquidity planning
    CURRENCY,                                                    -- Currency for settlement risk analysis
    COUNT(*) AS SETTLEMENT_TRANSACTION_COUNT,                    -- Number of transactions settling on this date
    SUM(AMOUNT) AS SETTLEMENT_TOTAL_AMOUNT,                      -- Total amount settling in this currency
    AVG(DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE)) AS AVG_SETTLEMENT_DAYS, -- Average settlement period for operational planning
    
    -- Settlement timing analysis for operational risk management
    COUNT(CASE WHEN DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE) = 0 THEN 1 END) AS SAME_DAY_SETTLEMENTS,     -- Immediate settlement transactions
    COUNT(CASE WHEN DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE) = 1 THEN 1 END) AS T_PLUS_1_SETTLEMENTS,     -- Next business day settlements
    COUNT(CASE WHEN DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE) BETWEEN 2 AND 3 THEN 1 END) AS T_PLUS_2_3_SETTLEMENTS, -- Standard settlement period
    COUNT(CASE WHEN DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE) > 5 THEN 1 END) AS DELAYED_SETTLEMENTS,      -- Delayed settlements requiring attention
    COUNT(CASE WHEN VALUE_DATE < DATE(BOOKING_DATE) THEN 1 END) AS BACKDATED_SETTLEMENTS,               -- Backdated settlements (compliance risk)
    
    -- Liquidity risk assessment for treasury management
    CASE 
        WHEN COUNT(CASE WHEN DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE) > 5 THEN 1 END) > 0 
        THEN 'HIGH_SETTLEMENT_RISK'
        WHEN COUNT(CASE WHEN DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE) > 3 THEN 1 END) > 
             COUNT(*) * 0.1 
        THEN 'MEDIUM_SETTLEMENT_RISK'
        ELSE 'LOW_SETTLEMENT_RISK'
    END AS SETTLEMENT_RISK_LEVEL,                                -- Overall settlement risk classification
    
    -- Weekend/holiday settlement pattern analysis
    CASE 
        WHEN DAYOFWEEK(DATE(VALUE_DATE)) IN (1,7) THEN 'WEEKEND_SETTLEMENT'
        ELSE 'WEEKDAY_SETTLEMENT'
    END AS SETTLEMENT_TIMING_TYPE                                -- Settlement timing pattern for operational planning
    
FROM AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001.PAYA_AGG_DT_TRANSACTION_ANOMALIES
WHERE CURRENCY != 'CHF'
GROUP BY DATE(VALUE_DATE), CURRENCY
ORDER BY SETTLEMENT_DATE DESC, SETTLEMENT_TOTAL_AMOUNT DESC;

-- =====================================================
-- REPP_DT_ANOMALY_ANALYSIS - Suspicious Activity Detection
-- =====================================================
-- BUSINESS PURPOSE: Customer-level anomaly analysis for compliance monitoring,
-- AML investigation, and suspicious activity reporting.
-- =====================================================

-- Anomaly detection summary
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_ANOMALY_ANALYSIS
TARGET_LAG = '1 hour'
WAREHOUSE = MD_TEST_WH
AS
SELECT
    c.CUSTOMER_ID,                                               -- Customer identifier for compliance tracking
    CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME) AS FULL_NAME,       -- Customer name for investigation reports
    c.HAS_ANOMALY AS IS_ANOMALOUS_CUSTOMER,                      -- Customer-level anomaly flag from profiling
    COUNT(t.TRANSACTION_ID) AS TOTAL_TRANSACTIONS,               -- Total transaction count for baseline comparison
    COUNT(CASE WHEN t.DESCRIPTION LIKE '%[%]%' THEN 1 END) AS ANOMALOUS_TRANSACTIONS, -- Count of flagged transactions
    ROUND(COUNT(CASE WHEN t.DESCRIPTION LIKE '%[%]%' THEN 1 END) * 100.0 / COUNT(t.TRANSACTION_ID), 2) AS ANOMALY_PERCENTAGE, -- Percentage of anomalous activity
    SUM(CASE WHEN t.DESCRIPTION LIKE '%[%]%' THEN t.AMOUNT ELSE 0 END) AS ANOMALOUS_AMOUNT, -- Total value of suspicious transactions
    LISTAGG(DISTINCT
        CASE WHEN t.DESCRIPTION LIKE '%[%]%'
        THEN REGEXP_REPLACE(t.DESCRIPTION, '.*\[(.*?)\].*', '\\1')
        END, ', ') AS ANOMALY_TYPES                              -- Types of anomalies detected for investigation
FROM AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRMA_AGG_DT_CUSTOMER c
LEFT JOIN AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001.PAYA_AGG_DT_TRANSACTION_ANOMALIES t ON c.CUSTOMER_ID = t.CUSTOMER_ID
GROUP BY c.CUSTOMER_ID, c.FIRST_NAME, c.FAMILY_NAME, c.HAS_ANOMALY
HAVING COUNT(t.TRANSACTION_ID) > 0
ORDER BY ANOMALY_PERCENTAGE DESC, ANOMALOUS_AMOUNT DESC;

-- High-risk transaction patterns
CREATE OR REPLACE DYNAMIC TABLE REPP_AGGDT_HIGH_RISK_PATTERNS(
    TRANSACTION_ID COMMENT 'Unique identifier for each transaction',
    CUSTOMER_ID COMMENT 'Customer identifier for risk profiling',
    BOOKING_DATE COMMENT 'Date when transaction was booked in system',
    VALUE_DATE COMMENT 'Settlement date for the transaction',
    AMOUNT COMMENT 'Transaction amount in original currency',
    CURRENCY COMMENT 'Currency code (ISO 4217) of the transaction',
    DIRECTION COMMENT 'Transaction flow direction (IN/OUT)',
    DESCRIPTION COMMENT 'Transaction description text for analysis',
    RISK_CATEGORY COMMENT 'Primary risk classification for compliance review (HIGH_AMOUNT/ANOMALOUS/OFFSHORE/CRYPTO/etc.)',
    SETTLEMENT_DAYS COMMENT 'Number of days between booking and settlement'
) TARGET_LAG = '1 hour' WAREHOUSE = MD_TEST_WH
AS
SELECT
    TRANSACTION_ID,
    CUSTOMER_ID,
    BOOKING_DATE,
    VALUE_DATE,
    AMOUNT,
    CURRENCY,
    CASE WHEN AMOUNT > 0 THEN 'IN' ELSE 'OUT' END AS DIRECTION,
    DESCRIPTION,
    CASE
        WHEN AMOUNT >= 10000 THEN 'HIGH_AMOUNT'
        WHEN DESCRIPTION LIKE '%[%]%' THEN 'ANOMALOUS'
        WHEN CURRENCY != 'CHF' AND AMOUNT >= 5000 THEN 'HIGH_FX_AMOUNT'
        WHEN COUNTERPARTY_ACCOUNT LIKE 'OFF_SHORE_%' THEN 'OFFSHORE'
        WHEN COUNTERPARTY_ACCOUNT LIKE 'CRYPTO_%' THEN 'CRYPTO'
        WHEN HOUR(BOOKING_DATE) NOT BETWEEN 9 AND 17 THEN 'OFF_HOURS'
        WHEN VALUE_DATE < DATE(BOOKING_DATE) THEN 'BACKDATED_SETTLEMENT'
        WHEN DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE) > 5 THEN 'DELAYED_SETTLEMENT'
        ELSE 'OTHER'
    END AS RISK_CATEGORY,
    DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE) AS SETTLEMENT_DAYS
FROM AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001.PAYA_AGG_DT_TRANSACTION_ANOMALIES
WHERE
    AMOUNT >= 10000
    OR DESCRIPTION LIKE '%[%]%'
    OR (CURRENCY != 'CHF' AND AMOUNT >= 5000)
    OR COUNTERPARTY_ACCOUNT LIKE 'OFF_SHORE_%'
    OR COUNTERPARTY_ACCOUNT LIKE 'CRYPTO_%'
    OR HOUR(BOOKING_DATE) NOT BETWEEN 9 AND 17
    OR VALUE_DATE < DATE(BOOKING_DATE)  -- Backdated settlements
    OR DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE) > 5  -- Delayed settlements
ORDER BY AMOUNT DESC, BOOKING_DATE DESC;

-- Settlement risk analysis
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_SETTLEMENT_ANALYSIS
TARGET_LAG = '1 hour'
WAREHOUSE = MD_TEST_WH
AS
SELECT
    DATE(BOOKING_DATE) AS BOOKING_DATE,                          -- Transaction booking date for settlement tracking
    DATE(VALUE_DATE) AS VALUE_DATE,                              -- Actual settlement date for liquidity planning
    DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE) AS SETTLEMENT_DAYS,  -- Settlement period for operational analysis
    COUNT(*) AS TRANSACTION_COUNT,                               -- Number of transactions with this settlement pattern
    COUNT(DISTINCT CUSTOMER_ID) AS UNIQUE_CUSTOMERS,            -- Number of customers affected by settlement timing
    SUM(AMOUNT) AS TOTAL_AMOUNT,                                 -- Total value settling with this timing
    AVG(AMOUNT) AS AVG_AMOUNT,                                   -- Average transaction size for this settlement pattern
    COUNT(CASE WHEN VALUE_DATE < DATE(BOOKING_DATE) THEN 1 END) AS BACKDATED_COUNT,     -- Backdated settlements (compliance concern)
    COUNT(CASE WHEN DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE) > 5 THEN 1 END) AS DELAYED_COUNT,  -- Delayed settlements (operational risk)
    COUNT(CASE WHEN DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE) = 0 THEN 1 END) AS SAME_DAY_COUNT,  -- Same-day settlements
    COUNT(CASE WHEN DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE) = 1 THEN 1 END) AS NEXT_DAY_COUNT,  -- Next business day settlements
    COUNT(CASE WHEN DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE) BETWEEN 2 AND 3 THEN 1 END) AS T_PLUS_2_3_COUNT -- Standard settlement period
FROM AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001.PAYA_AGG_DT_TRANSACTION_ANOMALIES
GROUP BY DATE(BOOKING_DATE), DATE(VALUE_DATE), DATEDIFF(DAY, BOOKING_DATE, VALUE_DATE)
ORDER BY BOOKING_DATE DESC, SETTLEMENT_DAYS DESC;

-- ============================================================
-- EQUITY TRADING DYNAMIC TABLES
-- ============================================================

-- Equity trading summary by customer
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_EQUITY_SUMMARY
TARGET_LAG = '1 hour'
WAREHOUSE = MD_TEST_WH
AS
SELECT
    t.CUSTOMER_ID,                                               -- Customer identifier for portfolio analysis
    t.ACCOUNT_ID,                                                -- Account identifier for position tracking
    a.BASE_CURRENCY,                                             -- Account base currency for reporting
    COUNT(*) AS TOTAL_TRADES,                                    -- Total number of equity transactions
    SUM(CASE WHEN t.SIDE = '1' THEN 1 ELSE 0 END) AS BUY_TRADES,  -- Number of buy transactions
    SUM(CASE WHEN t.SIDE = '2' THEN 1 ELSE 0 END) AS SELL_TRADES, -- Number of sell transactions
    COUNT(DISTINCT t.SYMBOL) AS UNIQUE_SYMBOLS,                  -- Number of different securities traded
    SUM(ABS(t.BASE_GROSS_AMOUNT)) AS TOTAL_CHF_VOLUME,          -- Total trading volume in CHF
    SUM(t.BASE_GROSS_AMOUNT) AS NET_CHF_POSITION,               -- Net position (positive = net buyer, negative = net seller)
    SUM(t.COMMISSION) AS TOTAL_COMMISSION_CHF,                   -- Total commission fees paid
    AVG(ABS(t.BASE_GROSS_AMOUNT)) AS AVG_TRADE_SIZE_CHF,        -- Average trade size for customer profiling
    MIN(t.TRADE_DATE) AS FIRST_TRADE_DATE,                       -- First trading activity date
    MAX(t.TRADE_DATE) AS LAST_TRADE_DATE                         -- Most recent trading activity date
FROM AAA_DEV_SYNTHETIC_BANK.EQT_RAW_001.EQTI_TRADES t
LEFT JOIN AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.ACCA_AGG_DT_ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
GROUP BY t.CUSTOMER_ID, t.ACCOUNT_ID, a.BASE_CURRENCY;

-- Equity position summary by symbol
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_EQUITY_POSITIONS
TARGET_LAG = '1 hour'
WAREHOUSE = MD_TEST_WH
AS
SELECT
    SYMBOL,                                                      -- Security symbol for position tracking
    ISIN,                                                        -- International Securities Identification Number
    COUNT(DISTINCT CUSTOMER_ID) AS UNIQUE_CUSTOMERS,            -- Number of customers holding this security
    SUM(CASE WHEN SIDE = '1' THEN QUANTITY ELSE -QUANTITY END) AS NET_POSITION, -- Net position across all customers (positive = long, negative = short)
    SUM(CASE WHEN SIDE = '1' THEN QUANTITY ELSE 0 END) AS TOTAL_BOUGHT,         -- Total quantity purchased
    SUM(CASE WHEN SIDE = '2' THEN QUANTITY ELSE 0 END) AS TOTAL_SOLD,           -- Total quantity sold
    COUNT(*) AS TOTAL_TRADES,                                    -- Total number of trades in this security
    SUM(ABS(BASE_GROSS_AMOUNT)) AS TOTAL_CHF_VOLUME,            -- Total trading volume in CHF
    AVG(PRICE) AS AVG_PRICE,                                     -- Average trading price
    MIN(PRICE) AS MIN_PRICE,                                     -- Lowest trading price observed
    MAX(PRICE) AS MAX_PRICE,                                     -- Highest trading price observed
    MAX(TRADE_DATE) AS LAST_TRADE_DATE                           -- Most recent trading date for this security
FROM AAA_DEV_SYNTHETIC_BANK.EQT_RAW_001.EQTI_TRADES
GROUP BY SYMBOL, ISIN;

-- Equity currency exposure (similar to FX exposure for trades)
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_EQUITY_CURRENCY_EXPOSURE
TARGET_LAG = '1 hour'
WAREHOUSE = MD_TEST_WH
AS
SELECT
    CURRENCY,                                                    -- Trading currency for FX exposure analysis
    COUNT(*) AS TRADE_COUNT,                                     -- Number of equity trades in this currency
    SUM(ABS(GROSS_AMOUNT)) AS TOTAL_ORIGINAL_VOLUME,            -- Total trading volume in original currency
    SUM(ABS(BASE_GROSS_AMOUNT)) AS TOTAL_CHF_VOLUME,            -- Total trading volume converted to CHF
    AVG(FX_RATE) AS AVG_FX_RATE,                                 -- Average FX rate used for currency conversion
    MIN(FX_RATE) AS MIN_FX_RATE,                                 -- Minimum FX rate observed
    MAX(FX_RATE) AS MAX_FX_RATE,                                 -- Maximum FX rate observed
    COUNT(DISTINCT CUSTOMER_ID) AS UNIQUE_CUSTOMERS,            -- Number of customers trading in this currency
    COUNT(DISTINCT SYMBOL) AS UNIQUE_SYMBOLS                    -- Number of different securities traded in this currency
FROM AAA_DEV_SYNTHETIC_BANK.EQT_RAW_001.EQTI_TRADES
WHERE CURRENCY != 'CHF'
GROUP BY CURRENCY;

-- High-value equity trades (potential compliance monitoring)
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_HIGH_VALUE_EQUITY_TRADES
TARGET_LAG = '1 hour'
WAREHOUSE = MD_TEST_WH
AS
SELECT
    TRADE_DATE,                                                  -- Trade execution date for compliance tracking
    CUSTOMER_ID,                                                 -- Customer identifier for large trade monitoring
    ACCOUNT_ID,                                                  -- Account identifier for position tracking
    TRADE_ID,                                                    -- Unique trade identifier for audit trail
    SYMBOL,                                                      -- Security symbol for concentration risk analysis
    SIDE,                                                        -- Trade direction (1=Buy, 2=Sell)
    QUANTITY,                                                    -- Number of shares/units traded
    PRICE,                                                       -- Execution price per unit
    ABS(BASE_GROSS_AMOUNT) AS CHF_VALUE,                         -- Trade value in CHF for threshold monitoring
    MARKET,                                                      -- Market/exchange where trade was executed
    VENUE                                                        -- Trading venue for best execution analysis
FROM AAA_DEV_SYNTHETIC_BANK.EQT_RAW_001.EQTI_TRADES
WHERE ABS(BASE_GROSS_AMOUNT) > 100000 -- Trades over 100k CHF
ORDER BY ABS(BASE_GROSS_AMOUNT) DESC;

-- ============================================================
-- IRB (INTERNAL RATINGS BASED) APPROACH DYNAMIC TABLES
-- ============================================================
-- Basel III/IV compliant IRB risk metrics for credit risk management
-- and regulatory capital calculation

-- IRB Customer Credit Ratings and Risk Parameters
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_IRB_CUSTOMER_RATINGS(
    CUSTOMER_ID COMMENT 'Customer identifier for credit risk assessment',
    FULL_NAME COMMENT 'Customer name for credit reporting',
    ONBOARDING_DATE COMMENT 'Customer relationship start date for vintage analysis',
    CREDIT_RATING COMMENT 'Internal credit rating (AAA to D scale)',
    PD_1_YEAR COMMENT 'Probability of Default over 1 year horizon (%)',
    PD_LIFETIME COMMENT 'Lifetime Probability of Default (%)',
    LGD_RATE COMMENT 'Loss Given Default rate (%) - expected loss severity',
    EAD_AMOUNT COMMENT 'Exposure at Default amount in CHF - total exposure',
    RISK_WEIGHT COMMENT 'Risk weight (%) for RWA calculation under IRB approach',
    RATING_DATE COMMENT 'Date when credit rating was assigned/updated',
    RATING_METHODOLOGY COMMENT 'Rating methodology used (FOUNDATION_IRB/ADVANCED_IRB)',
    PORTFOLIO_SEGMENT COMMENT 'Portfolio segment (RETAIL/CORPORATE/SME/SOVEREIGN)',
    DAYS_PAST_DUE COMMENT 'Current days past due for default identification',
    DEFAULT_FLAG COMMENT 'Boolean flag indicating if customer is in default (90+ DPD)',
    WATCH_LIST_FLAG COMMENT 'Boolean flag for customers on credit watch list',
    TOTAL_EXPOSURE_CHF COMMENT 'Total credit exposure across all facilities in CHF',
    SECURED_EXPOSURE_CHF COMMENT 'Secured portion of exposure with collateral',
    UNSECURED_EXPOSURE_CHF COMMENT 'Unsecured exposure without collateral'
) COMMENT = 'IRB customer-level credit ratings and risk parameters for Basel III/IV regulatory capital calculation and credit risk management'
TARGET_LAG = '1 hour' WAREHOUSE = MD_TEST_WH
AS
SELECT
    c.CUSTOMER_ID,
    CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME) AS FULL_NAME,
    c.ONBOARDING_DATE,
    -- Synthetic credit rating based on customer behavior
    CASE 
        WHEN c.HAS_ANOMALY = TRUE THEN 'CCC'
        WHEN t.ANOMALY_PERCENTAGE > 20 THEN 'B'
        WHEN t.ANOMALY_PERCENTAGE > 10 THEN 'BB'
        WHEN t.ANOMALY_PERCENTAGE > 5 THEN 'BBB'
        WHEN t.ANOMALY_PERCENTAGE > 2 THEN 'A'
        WHEN t.ANOMALY_PERCENTAGE > 0 THEN 'AA'
        ELSE 'AAA'
    END AS CREDIT_RATING,
    -- Synthetic PD calculation based on rating
    CASE 
        WHEN c.HAS_ANOMALY = TRUE THEN 15.0
        WHEN t.ANOMALY_PERCENTAGE > 20 THEN 8.0
        WHEN t.ANOMALY_PERCENTAGE > 10 THEN 4.0
        WHEN t.ANOMALY_PERCENTAGE > 5 THEN 2.0
        WHEN t.ANOMALY_PERCENTAGE > 2 THEN 1.0
        WHEN t.ANOMALY_PERCENTAGE > 0 THEN 0.5
        ELSE 0.1
    END AS PD_1_YEAR,
    -- Lifetime PD (typically higher)
    CASE 
        WHEN c.HAS_ANOMALY = TRUE THEN 25.0
        WHEN t.ANOMALY_PERCENTAGE > 20 THEN 15.0
        WHEN t.ANOMALY_PERCENTAGE > 10 THEN 8.0
        WHEN t.ANOMALY_PERCENTAGE > 5 THEN 4.0
        WHEN t.ANOMALY_PERCENTAGE > 2 THEN 2.0
        WHEN t.ANOMALY_PERCENTAGE > 0 THEN 1.0
        ELSE 0.3
    END AS PD_LIFETIME,
    -- LGD based on portfolio type (retail typically lower)
    45.0 AS LGD_RATE,  -- Standard retail LGD assumption
    -- EAD approximated from account balances
    COALESCE(b.CURRENT_BALANCE_CHF, 0) AS EAD_AMOUNT,
    -- Risk weight calculation under IRB
    CASE 
        WHEN c.HAS_ANOMALY = TRUE THEN 150.0
        WHEN t.ANOMALY_PERCENTAGE > 20 THEN 120.0
        WHEN t.ANOMALY_PERCENTAGE > 10 THEN 100.0
        WHEN t.ANOMALY_PERCENTAGE > 5 THEN 75.0
        WHEN t.ANOMALY_PERCENTAGE > 2 THEN 50.0
        WHEN t.ANOMALY_PERCENTAGE > 0 THEN 35.0
        ELSE 20.0
    END AS RISK_WEIGHT,
    CURRENT_DATE AS RATING_DATE,
    'FOUNDATION_IRB' AS RATING_METHODOLOGY,
    'RETAIL' AS PORTFOLIO_SEGMENT,
    -- Synthetic days past due
    CASE 
        WHEN c.HAS_ANOMALY = TRUE THEN 120
        WHEN t.ANOMALY_PERCENTAGE > 20 THEN 60
        WHEN t.ANOMALY_PERCENTAGE > 10 THEN 30
        ELSE 0
    END AS DAYS_PAST_DUE,
    -- Default flag (90+ days past due)
    CASE 
        WHEN c.HAS_ANOMALY = TRUE OR t.ANOMALY_PERCENTAGE > 20 THEN TRUE
        ELSE FALSE
    END AS DEFAULT_FLAG,
    -- Watch list flag
    CASE 
        WHEN t.ANOMALY_PERCENTAGE > 5 THEN TRUE
        ELSE FALSE
    END AS WATCH_LIST_FLAG,
    COALESCE(b.CURRENT_BALANCE_CHF, 0) AS TOTAL_EXPOSURE_CHF,
    COALESCE(b.CURRENT_BALANCE_CHF * 0.6, 0) AS SECURED_EXPOSURE_CHF,  -- Assume 60% secured
    COALESCE(b.CURRENT_BALANCE_CHF * 0.4, 0) AS UNSECURED_EXPOSURE_CHF -- Assume 40% unsecured
FROM AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRMA_AGG_DT_CUSTOMER c
LEFT JOIN AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.REPP_DT_ANOMALY_ANALYSIS t ON c.CUSTOMER_ID = t.CUSTOMER_ID
LEFT JOIN AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001.PAYA_AGG_DT_ACCOUNT_BALANCES b ON c.CUSTOMER_ID = b.CUSTOMER_ID;

-- IRB Portfolio Risk Metrics and RWA Calculation
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_IRB_PORTFOLIO_METRICS(
    PORTFOLIO_SEGMENT COMMENT 'Portfolio segment for risk aggregation (RETAIL/CORPORATE/SME)',
    CREDIT_RATING COMMENT 'Credit rating bucket for portfolio analysis',
    CUSTOMER_COUNT COMMENT 'Number of customers in this rating/segment combination',
    TOTAL_EXPOSURE_CHF COMMENT 'Total credit exposure in CHF for this portfolio segment',
    AVERAGE_EXPOSURE_CHF COMMENT 'Average exposure per customer in CHF',
    WEIGHTED_AVG_PD COMMENT 'Exposure-weighted average Probability of Default (%)',
    WEIGHTED_AVG_LGD COMMENT 'Exposure-weighted average Loss Given Default (%)',
    EXPECTED_LOSS_CHF COMMENT 'Expected Loss = EAD × PD × LGD in CHF',
    RISK_WEIGHTED_ASSETS_CHF COMMENT 'Risk Weighted Assets under IRB approach in CHF',
    CAPITAL_REQUIREMENT_CHF COMMENT 'Minimum capital requirement (8% of RWA) in CHF',
    DEFAULT_COUNT COMMENT 'Number of customers currently in default',
    DEFAULT_RATE COMMENT 'Default rate (%) within this portfolio segment',
    WATCH_LIST_COUNT COMMENT 'Number of customers on credit watch list',
    WATCH_LIST_RATE COMMENT 'Watch list rate (%) within this portfolio segment',
    SECURED_EXPOSURE_CHF COMMENT 'Total secured exposure with collateral in CHF',
    UNSECURED_EXPOSURE_CHF COMMENT 'Total unsecured exposure without collateral in CHF',
    COLLATERAL_COVERAGE_RATIO COMMENT 'Secured exposure as % of total exposure',
    VINTAGE_MONTHS COMMENT 'Average customer vintage in months for maturity analysis',
    CONCENTRATION_RISK_SCORE COMMENT 'Portfolio concentration risk score (1-10 scale)'
) COMMENT = 'IRB portfolio-level risk metrics aggregated by segment and rating for regulatory capital calculation and risk management'
TARGET_LAG = '1 hour' WAREHOUSE = MD_TEST_WH
AS
SELECT
    r.PORTFOLIO_SEGMENT,
    r.CREDIT_RATING,
    COUNT(*) AS CUSTOMER_COUNT,
    SUM(r.TOTAL_EXPOSURE_CHF) AS TOTAL_EXPOSURE_CHF,
    AVG(r.TOTAL_EXPOSURE_CHF) AS AVERAGE_EXPOSURE_CHF,
    -- Exposure-weighted averages
    SUM(r.TOTAL_EXPOSURE_CHF * r.PD_1_YEAR) / NULLIF(SUM(r.TOTAL_EXPOSURE_CHF), 0) AS WEIGHTED_AVG_PD,
    SUM(r.TOTAL_EXPOSURE_CHF * r.LGD_RATE) / NULLIF(SUM(r.TOTAL_EXPOSURE_CHF), 0) AS WEIGHTED_AVG_LGD,
    -- Expected Loss calculation: EL = EAD × PD × LGD
    SUM(r.TOTAL_EXPOSURE_CHF * (r.PD_1_YEAR / 100) * (r.LGD_RATE / 100)) AS EXPECTED_LOSS_CHF,
    -- Risk Weighted Assets: RWA = EAD × Risk Weight
    SUM(r.TOTAL_EXPOSURE_CHF * (r.RISK_WEIGHT / 100)) AS RISK_WEIGHTED_ASSETS_CHF,
    -- Capital Requirement: 8% of RWA
    SUM(r.TOTAL_EXPOSURE_CHF * (r.RISK_WEIGHT / 100)) * 0.08 AS CAPITAL_REQUIREMENT_CHF,
    SUM(CASE WHEN r.DEFAULT_FLAG = TRUE THEN 1 ELSE 0 END) AS DEFAULT_COUNT,
    (SUM(CASE WHEN r.DEFAULT_FLAG = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS DEFAULT_RATE,
    SUM(CASE WHEN r.WATCH_LIST_FLAG = TRUE THEN 1 ELSE 0 END) AS WATCH_LIST_COUNT,
    (SUM(CASE WHEN r.WATCH_LIST_FLAG = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS WATCH_LIST_RATE,
    SUM(r.SECURED_EXPOSURE_CHF) AS SECURED_EXPOSURE_CHF,
    SUM(r.UNSECURED_EXPOSURE_CHF) AS UNSECURED_EXPOSURE_CHF,
    (SUM(r.SECURED_EXPOSURE_CHF) * 100.0 / NULLIF(SUM(r.TOTAL_EXPOSURE_CHF), 0)) AS COLLATERAL_COVERAGE_RATIO,
    AVG(DATEDIFF(MONTH, r.ONBOARDING_DATE, CURRENT_DATE)) AS VINTAGE_MONTHS,
    -- Concentration risk score based on exposure distribution
    CASE 
        WHEN MAX(r.TOTAL_EXPOSURE_CHF) > SUM(r.TOTAL_EXPOSURE_CHF) * 0.3 THEN 9  -- High concentration
        WHEN MAX(r.TOTAL_EXPOSURE_CHF) > SUM(r.TOTAL_EXPOSURE_CHF) * 0.2 THEN 7  -- Medium-high
        WHEN MAX(r.TOTAL_EXPOSURE_CHF) > SUM(r.TOTAL_EXPOSURE_CHF) * 0.1 THEN 5  -- Medium
        WHEN MAX(r.TOTAL_EXPOSURE_CHF) > SUM(r.TOTAL_EXPOSURE_CHF) * 0.05 THEN 3 -- Low-medium
        ELSE 1  -- Low concentration
    END AS CONCENTRATION_RISK_SCORE
FROM AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.REPP_DT_IRB_CUSTOMER_RATINGS r
GROUP BY r.PORTFOLIO_SEGMENT, r.CREDIT_RATING
ORDER BY r.PORTFOLIO_SEGMENT, r.CREDIT_RATING;

-- IRB Risk Weighted Assets Summary
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_IRB_RWA_SUMMARY(
    CALCULATION_DATE COMMENT 'Date of RWA calculation for regulatory reporting',
    TOTAL_EXPOSURE_CHF COMMENT 'Total credit exposure across all portfolios in CHF',
    TOTAL_RWA_CHF COMMENT 'Total Risk Weighted Assets under IRB approach in CHF',
    TOTAL_CAPITAL_REQUIREMENT_CHF COMMENT 'Total minimum capital requirement (8% of RWA) in CHF',
    TOTAL_EXPECTED_LOSS_CHF COMMENT 'Total Expected Loss across all portfolios in CHF',
    AVERAGE_RISK_WEIGHT COMMENT 'Portfolio-weighted average risk weight (%)',
    TIER1_CAPITAL_RATIO COMMENT 'Simulated Tier 1 capital ratio (%) - regulatory minimum 6%',
    TOTAL_CAPITAL_RATIO COMMENT 'Simulated total capital ratio (%) - regulatory minimum 8%',
    LEVERAGE_RATIO COMMENT 'Simulated leverage ratio (%) - regulatory minimum 3%',
    DEFAULT_CUSTOMERS COMMENT 'Total number of customers in default across all portfolios',
    TOTAL_CUSTOMERS COMMENT 'Total number of customers across all portfolios',
    PORTFOLIO_DEFAULT_RATE COMMENT 'Overall portfolio default rate (%)',
    RETAIL_EXPOSURE_CHF COMMENT 'Total retail portfolio exposure in CHF',
    CORPORATE_EXPOSURE_CHF COMMENT 'Total corporate portfolio exposure in CHF',
    SME_EXPOSURE_CHF COMMENT 'Total SME portfolio exposure in CHF',
    RETAIL_RWA_CHF COMMENT 'Retail portfolio Risk Weighted Assets in CHF',
    CORPORATE_RWA_CHF COMMENT 'Corporate portfolio Risk Weighted Assets in CHF',
    SME_RWA_CHF COMMENT 'SME portfolio Risk Weighted Assets in CHF'
) COMMENT = 'IRB Risk Weighted Assets summary for regulatory capital reporting and Basel III/IV compliance monitoring'
TARGET_LAG = '1 hour' WAREHOUSE = MD_TEST_WH
AS
SELECT
    CURRENT_DATE AS CALCULATION_DATE,
    SUM(TOTAL_EXPOSURE_CHF) AS TOTAL_EXPOSURE_CHF,
    SUM(RISK_WEIGHTED_ASSETS_CHF) AS TOTAL_RWA_CHF,
    SUM(CAPITAL_REQUIREMENT_CHF) AS TOTAL_CAPITAL_REQUIREMENT_CHF,
    SUM(EXPECTED_LOSS_CHF) AS TOTAL_EXPECTED_LOSS_CHF,
    (SUM(RISK_WEIGHTED_ASSETS_CHF) * 100.0 / NULLIF(SUM(TOTAL_EXPOSURE_CHF), 0)) AS AVERAGE_RISK_WEIGHT,
    -- Simulated capital ratios (would normally come from capital management system)
    15.2 AS TIER1_CAPITAL_RATIO,  -- Above regulatory minimum of 6%
    18.5 AS TOTAL_CAPITAL_RATIO,  -- Above regulatory minimum of 8%
    5.8 AS LEVERAGE_RATIO,        -- Above regulatory minimum of 3%
    SUM(DEFAULT_COUNT) AS DEFAULT_CUSTOMERS,
    SUM(CUSTOMER_COUNT) AS TOTAL_CUSTOMERS,
    (SUM(DEFAULT_COUNT) * 100.0 / NULLIF(SUM(CUSTOMER_COUNT), 0)) AS PORTFOLIO_DEFAULT_RATE,
    SUM(CASE WHEN PORTFOLIO_SEGMENT = 'RETAIL' THEN TOTAL_EXPOSURE_CHF ELSE 0 END) AS RETAIL_EXPOSURE_CHF,
    SUM(CASE WHEN PORTFOLIO_SEGMENT = 'CORPORATE' THEN TOTAL_EXPOSURE_CHF ELSE 0 END) AS CORPORATE_EXPOSURE_CHF,
    SUM(CASE WHEN PORTFOLIO_SEGMENT = 'SME' THEN TOTAL_EXPOSURE_CHF ELSE 0 END) AS SME_EXPOSURE_CHF,
    SUM(CASE WHEN PORTFOLIO_SEGMENT = 'RETAIL' THEN RISK_WEIGHTED_ASSETS_CHF ELSE 0 END) AS RETAIL_RWA_CHF,
    SUM(CASE WHEN PORTFOLIO_SEGMENT = 'CORPORATE' THEN RISK_WEIGHTED_ASSETS_CHF ELSE 0 END) AS CORPORATE_RWA_CHF,
    SUM(CASE WHEN PORTFOLIO_SEGMENT = 'SME' THEN RISK_WEIGHTED_ASSETS_CHF ELSE 0 END) AS SME_RWA_CHF
FROM AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.REPP_DT_IRB_PORTFOLIO_METRICS;

-- IRB Risk Parameter Trends and Validation
CREATE OR REPLACE DYNAMIC TABLE REPP_DT_IRB_RISK_TRENDS(
    TREND_DATE COMMENT 'Date for time series analysis of risk parameters',
    PORTFOLIO_SEGMENT COMMENT 'Portfolio segment for trend analysis',
    AVG_PD_1_YEAR COMMENT 'Average 1-year PD across portfolio on this date (%)',
    AVG_PD_LIFETIME COMMENT 'Average lifetime PD across portfolio on this date (%)',
    AVG_LGD_RATE COMMENT 'Average LGD rate across portfolio on this date (%)',
    AVG_RISK_WEIGHT COMMENT 'Average risk weight across portfolio on this date (%)',
    TOTAL_EXPOSURE_CHF COMMENT 'Total portfolio exposure on this date in CHF',
    TOTAL_RWA_CHF COMMENT 'Total Risk Weighted Assets on this date in CHF',
    EXPECTED_LOSS_CHF COMMENT 'Total Expected Loss on this date in CHF',
    DEFAULT_RATE COMMENT 'Observed default rate on this date (%)',
    NEW_DEFAULTS COMMENT 'Number of new defaults identified on this date',
    CURED_DEFAULTS COMMENT 'Number of defaults that cured on this date',
    NET_DEFAULT_CHANGE COMMENT 'Net change in default count (new - cured)',
    RATING_MIGRATIONS_UP COMMENT 'Number of customers with rating upgrades',
    RATING_MIGRATIONS_DOWN COMMENT 'Number of customers with rating downgrades',
    MODEL_PERFORMANCE_SCORE COMMENT 'PD model performance score (1-10, 10=best)',
    BACKTESTING_ACCURACY COMMENT 'Model backtesting accuracy (%) against actual defaults',
    STRESS_TEST_MULTIPLIER COMMENT 'Stress testing multiplier applied to base PD'
) COMMENT = 'IRB risk parameter trends and model validation metrics for ongoing model performance monitoring and regulatory compliance'
TARGET_LAG = '1 hour' WAREHOUSE = MD_TEST_WH
AS
SELECT
    CURRENT_DATE AS TREND_DATE,
    r.PORTFOLIO_SEGMENT,
    AVG(r.PD_1_YEAR) AS AVG_PD_1_YEAR,
    AVG(r.PD_LIFETIME) AS AVG_PD_LIFETIME,
    AVG(r.LGD_RATE) AS AVG_LGD_RATE,
    AVG(r.RISK_WEIGHT) AS AVG_RISK_WEIGHT,
    SUM(r.TOTAL_EXPOSURE_CHF) AS TOTAL_EXPOSURE_CHF,
    SUM(r.TOTAL_EXPOSURE_CHF * (r.RISK_WEIGHT / 100)) AS TOTAL_RWA_CHF,
    SUM(r.TOTAL_EXPOSURE_CHF * (r.PD_1_YEAR / 100) * (r.LGD_RATE / 100)) AS EXPECTED_LOSS_CHF,
    (SUM(CASE WHEN r.DEFAULT_FLAG = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS DEFAULT_RATE,
    -- Simulated daily changes (would normally track actual changes)
    FLOOR(RANDOM() * 5) AS NEW_DEFAULTS,
    FLOOR(RANDOM() * 3) AS CURED_DEFAULTS,
    FLOOR(RANDOM() * 5) - FLOOR(RANDOM() * 3) AS NET_DEFAULT_CHANGE,
    FLOOR(RANDOM() * 10) AS RATING_MIGRATIONS_UP,
    FLOOR(RANDOM() * 15) AS RATING_MIGRATIONS_DOWN,
    -- Model performance metrics (simulated)
    CASE 
        WHEN AVG(r.PD_1_YEAR) BETWEEN 0.5 AND 2.0 THEN 9  -- Good calibration
        WHEN AVG(r.PD_1_YEAR) BETWEEN 0.1 AND 5.0 THEN 7  -- Acceptable
        ELSE 5  -- Needs review
    END AS MODEL_PERFORMANCE_SCORE,
    -- Backtesting accuracy (simulated)
    CASE 
        WHEN (SUM(CASE WHEN r.DEFAULT_FLAG = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) BETWEEN 0.5 AND 3.0 THEN 92.5
        WHEN (SUM(CASE WHEN r.DEFAULT_FLAG = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) BETWEEN 0.1 AND 5.0 THEN 87.2
        ELSE 78.5
    END AS BACKTESTING_ACCURACY,
    1.0 AS STRESS_TEST_MULTIPLIER  -- Base case, would be higher under stress
FROM AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.REPP_DT_IRB_CUSTOMER_RATINGS r
GROUP BY r.PORTFOLIO_SEGMENT;

-- ============================================================
-- USAGE EXAMPLES
-- ============================================================
-- You can now query your data using standard SQL or the dynamic tables above.
-- Dynamic tables are automatically refreshed every 1 hour.
--
-- Examples:
--
-- Customer and Transaction Analytics:
-- SELECT * FROM REPP_DT_CUSTOMER_SUMMARY WHERE HAS_ANOMALY = TRUE;
-- SELECT * FROM REPP_AGGDT_HIGH_RISK_PATTERNS LIMIT 100;
-- SELECT * FROM REPP_DT_DAILY_TRANSACTION_SUMMARY ORDER BY TRANSACTION_DATE DESC LIMIT 30;
--
-- Currency and FX Risk:
-- SELECT * FROM REPP_DT_CURRENCY_EXPOSURE_CURRENT ORDER BY TOTAL_CHF_AMOUNT DESC;
-- SELECT * FROM REPP_DT_CURRENCY_EXPOSURE_HISTORY WHERE CURRENCY = 'EUR' ORDER BY EXPOSURE_DATE DESC LIMIT 30;
--
-- Equity Trading Analytics:
-- SELECT * FROM REPP_DT_EQUITY_SUMMARY LIMIT 10;
-- SELECT * FROM REPP_DT_EQUITY_POSITIONS WHERE NET_POSITION != 0 LIMIT 10;
-- SELECT * FROM REPP_DT_HIGH_VALUE_EQUITY_TRADES LIMIT 20;
--
-- IRB Credit Risk Analytics:
-- SELECT * FROM REPP_DT_IRB_CUSTOMER_RATINGS WHERE DEFAULT_FLAG = TRUE;
-- SELECT * FROM REPP_DT_IRB_PORTFOLIO_METRICS ORDER BY TOTAL_EXPOSURE_CHF DESC;
-- SELECT * FROM REPP_DT_IRB_RWA_SUMMARY;
-- SELECT * FROM REPP_DT_IRB_RISK_TRENDS ORDER BY TREND_DATE DESC;
--
-- To check dynamic table refresh status:
-- SHOW DYNAMIC TABLES IN SCHEMA AAA_DEV_SYNTHETIC_BANK.REPP_AGG_001;
--
-- To manually refresh a dynamic table:
-- ALTER DYNAMIC TABLE REPP_DT_CUSTOMER_SUMMARY REFRESH;
--
-- ============================================================
-- REPP_AGG_001 Schema setup completed!
-- ============================================================
