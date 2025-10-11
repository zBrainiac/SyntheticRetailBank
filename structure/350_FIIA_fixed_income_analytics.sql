-- ============================================================
-- FII_AGG_001 Schema - Fixed Income Aggregation & Analytics
-- Generated on: 2025-10-05
-- ============================================================
--
-- OVERVIEW:
-- This schema provides aggregated views and analytics for fixed income trading data.
-- It transforms raw bond and swap trades from FII_RAW_001.FIII_TRADES into 
-- business-ready analytical views for interest rate risk management, credit risk
-- monitoring, and FRTB capital calculations.
--
-- BUSINESS PURPOSE:
-- - Interest rate risk management (duration, DV01 analytics)
-- - Credit risk monitoring (exposure by rating/issuer)
-- - Portfolio position tracking (current holdings per customer)
-- - FRTB Standardized Approach capital calculations
-- - Yield curve construction and analysis
-- - Regulatory reporting and compliance
--
-- OBJECTS CREATED:
-- ┌─ DYNAMIC TABLES (5):
-- │  ├─ FIIA_AGG_DT_TRADE_SUMMARY - Enriched trade-level analytics
-- │  ├─ FIIA_AGG_DT_PORTFOLIO_POSITIONS - Current holdings by customer/issuer
-- │  ├─ FIIA_AGG_DT_DURATION_ANALYSIS - Interest rate risk metrics
-- │  ├─ FIIA_AGG_DT_CREDIT_EXPOSURE - Credit risk by rating/issuer
-- │  └─ FIIA_AGG_DT_YIELD_CURVE - Yield curve construction
-- │
-- └─ REFRESH STRATEGY:
--    ├─ TARGET_LAG: 60 minutes (consistent with system schedule)
--    ├─ WAREHOUSE: MD_TEST_WH
--    └─ AUTO-REFRESH: Based on source table changes
--
-- DATA FLOW:
-- FII_RAW_001.FIII_TRADES (raw trades)
--     ↓
-- FIIA_AGG_DT_TRADE_SUMMARY (enriched analytics)
--     ↓
-- FIIA_AGG_DT_PORTFOLIO_POSITIONS (current holdings)
--     ↓
-- FIIA_AGG_DT_DURATION_ANALYSIS (interest rate risk)
-- FIIA_AGG_DT_CREDIT_EXPOSURE (credit risk)
-- FIIA_AGG_DT_YIELD_CURVE (yield curve)
--
-- RELATED SCHEMAS:
-- - FII_RAW_001: Source fixed income trading data
-- - CRM_RAW_001: Customer and account master data
-- - REF_RAW_001: FX rates for currency conversion
-- - REP_AGG_001: FRTB reporting and capital calculations
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA FII_AGG_001;

-- ============================================================
-- FIIA_AGG_DT_TRADE_SUMMARY - Enriched Trade Analytics
-- ============================================================
-- Trade-level view with enriched metadata, risk metrics, and classifications

CREATE OR REPLACE DYNAMIC TABLE FIIA_AGG_DT_TRADE_SUMMARY(
    TRADE_ID VARCHAR(50) COMMENT 'Unique trade identifier',
    TRADE_DATE TIMESTAMP_NTZ COMMENT 'Trade execution timestamp',
    SETTLEMENT_DATE DATE COMMENT 'Settlement date',
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier',
    ACCOUNT_ID VARCHAR(30) COMMENT 'Investment account',
    INSTRUMENT_TYPE VARCHAR(10) COMMENT 'BOND or IRS',
    INSTRUMENT_ID VARCHAR(50) COMMENT 'ISIN or swap ID',
    ISSUER VARCHAR(100) COMMENT 'Issuer or counterparty',
    ISSUER_TYPE VARCHAR(20) COMMENT 'SOVEREIGN, CORPORATE, SUPRANATIONAL',
    CURRENCY VARCHAR(3) COMMENT 'Trade currency',
    SIDE CHAR(1) COMMENT '1=Buy/Pay, 2=Sell/Receive',
    SIDE_DESCRIPTION VARCHAR(12) COMMENT 'BUY/PAY or SELL/RECEIVE',
    NOTIONAL NUMBER(18,2) COMMENT 'Notional amount',
    PRICE NUMBER(18,4) COMMENT 'Clean price or rate',
    GROSS_AMOUNT NUMBER(18,2) COMMENT 'Gross amount in trade currency',
    NET_AMOUNT NUMBER(18,2) COMMENT 'Net amount after commission',
    BASE_GROSS_AMOUNT NUMBER(18,2) COMMENT 'Gross amount in CHF',
    BASE_NET_AMOUNT NUMBER(18,2) COMMENT 'Net amount in CHF',
    FX_RATE NUMBER(15,6) COMMENT 'Exchange rate to CHF',
    DURATION NUMBER(8,4) COMMENT 'Modified duration (years)',
    DV01 NUMBER(18,2) COMMENT 'Dollar value of 1bp move (CHF)',
    CREDIT_RATING VARCHAR(3) COMMENT 'Credit rating',
    CREDIT_SPREAD_BPS NUMBER(8,2) COMMENT 'Credit spread (bps)',
    MATURITY_DATE DATE COMMENT 'Maturity date',
    DAYS_TO_MATURITY NUMBER(10,0) COMMENT 'Days until maturity',
    LIQUIDITY_SCORE NUMBER(2,0) COMMENT 'Liquidity score (1-10)',
    TRADE_VALUE_CATEGORY VARCHAR(15) COMMENT 'SMALL/MEDIUM/LARGE/VERY_LARGE',
    MATURITY_BUCKET VARCHAR(15) COMMENT 'SHORT/MEDIUM/LONG term',
    CREATED_AT TIMESTAMP_NTZ COMMENT 'Record creation timestamp'
) COMMENT = 'Enriched fixed income trade analytics with risk metrics and classifications'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    t.TRADE_ID,
    t.TRADE_DATE,
    t.SETTLEMENT_DATE,
    t.CUSTOMER_ID,
    t.ACCOUNT_ID,
    t.INSTRUMENT_TYPE,
    t.INSTRUMENT_ID,
    t.ISSUER,
    t.ISSUER_TYPE,
    t.CURRENCY,
    t.SIDE,
    CASE t.SIDE 
        WHEN '1' THEN 'BUY/PAY'
        WHEN '2' THEN 'SELL/RECEIVE'
        ELSE 'UNKNOWN'
    END AS SIDE_DESCRIPTION,
    t.NOTIONAL,
    t.PRICE,
    t.GROSS_AMOUNT,
    t.NET_AMOUNT,
    t.BASE_GROSS_AMOUNT,
    t.BASE_NET_AMOUNT,
    t.FX_RATE,
    t.DURATION,
    t.DV01,
    t.CREDIT_RATING,
    t.CREDIT_SPREAD_BPS,
    t.MATURITY_DATE,
    DATEDIFF(DAY, CURRENT_DATE, t.MATURITY_DATE) AS DAYS_TO_MATURITY,
    t.LIQUIDITY_SCORE,
    
    -- Trade value categorization
    CASE 
        WHEN ABS(t.BASE_GROSS_AMOUNT) >= 10000000 THEN 'VERY_LARGE'
        WHEN ABS(t.BASE_GROSS_AMOUNT) >= 1000000 THEN 'LARGE'
        WHEN ABS(t.BASE_GROSS_AMOUNT) >= 100000 THEN 'MEDIUM'
        ELSE 'SMALL'
    END AS TRADE_VALUE_CATEGORY,
    
    -- Maturity bucket
    CASE 
        WHEN DATEDIFF(DAY, CURRENT_DATE, t.MATURITY_DATE) <= 365 THEN 'SHORT_TERM'
        WHEN DATEDIFF(DAY, CURRENT_DATE, t.MATURITY_DATE) <= 1825 THEN 'MEDIUM_TERM'
        ELSE 'LONG_TERM'
    END AS MATURITY_BUCKET,
    
    t.CREATED_AT

FROM AAA_DEV_SYNTHETIC_BANK.FII_RAW_001.FIII_TRADES t
ORDER BY t.TRADE_DATE DESC;

-- ============================================================
-- FIIA_AGG_DT_PORTFOLIO_POSITIONS - Current Holdings
-- ============================================================
-- Current portfolio positions by customer/issuer showing holdings and P&L

CREATE OR REPLACE DYNAMIC TABLE FIIA_AGG_DT_PORTFOLIO_POSITIONS(
    ACCOUNT_ID VARCHAR(30) COMMENT 'Investment account',
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier',
    INSTRUMENT_TYPE VARCHAR(10) COMMENT 'BOND or IRS',
    ISSUER VARCHAR(100) COMMENT 'Issuer or counterparty',
    ISSUER_TYPE VARCHAR(20) COMMENT 'SOVEREIGN, CORPORATE, SUPRANATIONAL',
    CREDIT_RATING VARCHAR(3) COMMENT 'Credit rating',
    CURRENCY VARCHAR(3) COMMENT 'Trading currency',
    TOTAL_NOTIONAL NUMBER(18,2) COMMENT 'Total notional amount',
    TOTAL_TRADES NUMBER(10,0) COMMENT 'Number of trades',
    TOTAL_BUY_TRADES NUMBER(10,0) COMMENT 'Number of buy trades',
    TOTAL_SELL_TRADES NUMBER(10,0) COMMENT 'Number of sell trades',
    TOTAL_INVESTMENT_CHF NUMBER(18,2) COMMENT 'Total investment in CHF',
    NET_INVESTMENT_CHF NUMBER(18,2) COMMENT 'Net investment (buys - sells) in CHF',
    REALIZED_PL_CHF NUMBER(18,2) COMMENT 'Realized profit/loss in CHF',
    AVERAGE_DURATION NUMBER(8,4) COMMENT 'Weighted average duration',
    TOTAL_DV01_CHF NUMBER(18,2) COMMENT 'Total DV01 in CHF',
    AVERAGE_CREDIT_SPREAD_BPS NUMBER(8,2) COMMENT 'Average credit spread',
    POSITION_STATUS VARCHAR(10) COMMENT 'LONG/SHORT/CLOSED',
    FIRST_TRADE_DATE DATE COMMENT 'Date of first trade',
    LAST_TRADE_DATE DATE COMMENT 'Date of most recent trade',
    LAST_UPDATED TIMESTAMP_NTZ COMMENT 'Timestamp when calculated'
) COMMENT = 'Current fixed income portfolio positions by customer and issuer'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    t.ACCOUNT_ID,
    t.CUSTOMER_ID,
    t.INSTRUMENT_TYPE,
    t.ISSUER,
    t.ISSUER_TYPE,
    t.CREDIT_RATING,
    t.CURRENCY,
    
    -- Aggregate notional
    SUM(CASE WHEN t.SIDE = '1' THEN t.NOTIONAL ELSE -t.NOTIONAL END) AS TOTAL_NOTIONAL,
    
    -- Trade counts
    COUNT(*) AS TOTAL_TRADES,
    COUNT(CASE WHEN t.SIDE = '1' THEN 1 END) AS TOTAL_BUY_TRADES,
    COUNT(CASE WHEN t.SIDE = '2' THEN 1 END) AS TOTAL_SELL_TRADES,
    
    -- Investment amounts
    SUM(ABS(t.BASE_GROSS_AMOUNT)) AS TOTAL_INVESTMENT_CHF,
    
    -- Net investment (signed amounts: buys are negative, sells are positive)
    ROUND(SUM(t.BASE_NET_AMOUNT), 2) AS NET_INVESTMENT_CHF,
    
    -- Realized P&L calculation (simplified: sell proceeds minus proportional buy cost)
    ROUND(
        SUM(CASE WHEN t.SIDE = '2' THEN ABS(t.BASE_GROSS_AMOUNT) ELSE 0 END) -
        (
            CASE
                WHEN SUM(CASE WHEN t.SIDE = '2' THEN t.NOTIONAL ELSE 0 END) > 0
                 AND SUM(CASE WHEN t.SIDE = '1' THEN t.NOTIONAL ELSE 0 END) > 0 THEN
                    (SUM(CASE WHEN t.SIDE = '1' THEN ABS(t.BASE_GROSS_AMOUNT) ELSE 0 END) /
                     SUM(CASE WHEN t.SIDE = '1' THEN t.NOTIONAL ELSE 0 END)) *
                    SUM(CASE WHEN t.SIDE = '2' THEN t.NOTIONAL ELSE 0 END)
                ELSE 0
            END
        ), 2
    ) AS REALIZED_PL_CHF,
    
    -- Risk metrics (weighted by notional)
    ROUND(
        SUM(t.DURATION * ABS(t.NOTIONAL)) / NULLIF(SUM(ABS(t.NOTIONAL)), 0), 2
    ) AS AVERAGE_DURATION,
    
    SUM(t.DV01) AS TOTAL_DV01_CHF,
    
    ROUND(
        AVG(t.CREDIT_SPREAD_BPS), 2
    ) AS AVERAGE_CREDIT_SPREAD_BPS,
    
    -- Position status
    CASE 
        WHEN SUM(CASE WHEN t.SIDE = '1' THEN t.NOTIONAL ELSE -t.NOTIONAL END) > 0 THEN 'LONG'
        WHEN SUM(CASE WHEN t.SIDE = '1' THEN t.NOTIONAL ELSE -t.NOTIONAL END) < 0 THEN 'SHORT'
        ELSE 'CLOSED'
    END AS POSITION_STATUS,
    
    -- Time dimensions
    MIN(t.TRADE_DATE) AS FIRST_TRADE_DATE,
    MAX(t.TRADE_DATE) AS LAST_TRADE_DATE,
    CURRENT_TIMESTAMP() AS LAST_UPDATED

FROM AAA_DEV_SYNTHETIC_BANK.FII_RAW_001.FIII_TRADES t
GROUP BY t.ACCOUNT_ID, t.CUSTOMER_ID, t.INSTRUMENT_TYPE, t.ISSUER, t.ISSUER_TYPE, t.CREDIT_RATING, t.CURRENCY
ORDER BY TOTAL_INVESTMENT_CHF DESC;

-- ============================================================
-- FIIA_AGG_DT_DURATION_ANALYSIS - Interest Rate Risk
-- ============================================================
-- Interest rate risk metrics aggregated by maturity bucket and currency

CREATE OR REPLACE DYNAMIC TABLE FIIA_AGG_DT_DURATION_ANALYSIS(
    CURRENCY VARCHAR(3) COMMENT 'Currency',
    MATURITY_BUCKET VARCHAR(15) COMMENT 'SHORT/MEDIUM/LONG term',
    TOTAL_POSITIONS NUMBER(10,0) COMMENT 'Number of positions',
    TOTAL_NOTIONAL NUMBER(18,2) COMMENT 'Total notional amount',
    TOTAL_NOTIONAL_CHF NUMBER(18,2) COMMENT 'Total notional in CHF',
    WEIGHTED_AVG_DURATION NUMBER(8,4) COMMENT 'Weighted average duration',
    TOTAL_DV01_CHF NUMBER(18,2) COMMENT 'Total DV01 in CHF',
    MIN_DURATION NUMBER(8,4) COMMENT 'Minimum duration',
    MAX_DURATION NUMBER(8,4) COMMENT 'Maximum duration',
    LAST_UPDATED TIMESTAMP_NTZ COMMENT 'Timestamp when calculated'
) COMMENT = 'Interest rate risk metrics by maturity bucket and currency'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    t.CURRENCY,
    CASE 
        WHEN DATEDIFF(DAY, CURRENT_DATE, t.MATURITY_DATE) <= 365 THEN 'SHORT_TERM'
        WHEN DATEDIFF(DAY, CURRENT_DATE, t.MATURITY_DATE) <= 1825 THEN 'MEDIUM_TERM'
        ELSE 'LONG_TERM'
    END AS MATURITY_BUCKET,
    
    COUNT(*) AS TOTAL_POSITIONS,
    SUM(t.NOTIONAL) AS TOTAL_NOTIONAL,
    SUM(t.BASE_GROSS_AMOUNT) AS TOTAL_NOTIONAL_CHF,
    
    -- Weighted average duration
    ROUND(
        SUM(t.DURATION * ABS(t.NOTIONAL)) / NULLIF(SUM(ABS(t.NOTIONAL)), 0), 2
    ) AS WEIGHTED_AVG_DURATION,
    
    SUM(t.DV01) AS TOTAL_DV01_CHF,
    MIN(t.DURATION) AS MIN_DURATION,
    MAX(t.DURATION) AS MAX_DURATION,
    CURRENT_TIMESTAMP() AS LAST_UPDATED

FROM AAA_DEV_SYNTHETIC_BANK.FII_RAW_001.FIII_TRADES t
WHERE t.INSTRUMENT_TYPE = 'BOND'
GROUP BY t.CURRENCY, MATURITY_BUCKET
ORDER BY t.CURRENCY, MATURITY_BUCKET;

-- ============================================================
-- FIIA_AGG_DT_CREDIT_EXPOSURE - Credit Risk by Rating
-- ============================================================
-- Credit risk exposure aggregated by credit rating and issuer type

CREATE OR REPLACE DYNAMIC TABLE FIIA_AGG_DT_CREDIT_EXPOSURE(
    CREDIT_RATING COMMENT 'Credit rating',
    ISSUER_TYPE COMMENT 'SOVEREIGN, CORPORATE, SUPRANATIONAL',
    TOTAL_POSITIONS COMMENT 'Number of positions',
    TOTAL_NOTIONAL_CHF COMMENT 'Total notional in CHF',
    AVERAGE_CREDIT_SPREAD_BPS COMMENT 'Average credit spread',
    TOTAL_DV01_CHF COMMENT 'Total DV01 in CHF',
    CONCENTRATION_PERCENTAGE COMMENT 'Percentage of total portfolio',
    LAST_UPDATED COMMENT 'Timestamp when calculated'
) COMMENT = 'Credit risk exposure by rating and issuer type'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
WITH total_portfolio AS (
    SELECT SUM(ABS(BASE_GROSS_AMOUNT)) AS total_notional
    FROM AAA_DEV_SYNTHETIC_BANK.FII_RAW_001.FIII_TRADES
    WHERE INSTRUMENT_TYPE = 'BOND'
)
SELECT 
    t.CREDIT_RATING,
    t.ISSUER_TYPE,
    COUNT(*) AS TOTAL_POSITIONS,
    SUM(ABS(t.BASE_GROSS_AMOUNT)) AS TOTAL_NOTIONAL_CHF,
    ROUND(AVG(t.CREDIT_SPREAD_BPS), 2) AS AVERAGE_CREDIT_SPREAD_BPS,
    SUM(t.DV01) AS TOTAL_DV01_CHF,
    ROUND(
        (SUM(ABS(t.BASE_GROSS_AMOUNT)) / tp.total_notional) * 100, 2
    ) AS CONCENTRATION_PERCENTAGE,
    CURRENT_TIMESTAMP() AS LAST_UPDATED

FROM AAA_DEV_SYNTHETIC_BANK.FII_RAW_001.FIII_TRADES t
CROSS JOIN total_portfolio tp
WHERE t.INSTRUMENT_TYPE = 'BOND'
GROUP BY t.CREDIT_RATING, t.ISSUER_TYPE, tp.total_notional
ORDER BY TOTAL_NOTIONAL_CHF DESC;

-- ============================================================
-- FIIA_AGG_DT_YIELD_CURVE - Yield Curve Construction
-- ============================================================
-- Yield curve data points by currency and maturity

CREATE OR REPLACE DYNAMIC TABLE FIIA_AGG_DT_YIELD_CURVE(
    CURRENCY COMMENT 'Currency',
    MATURITY_YEARS COMMENT 'Years to maturity (rounded)',
    AVERAGE_YIELD COMMENT 'Average yield (%)',
    AVERAGE_CREDIT_SPREAD_BPS COMMENT 'Average credit spread (bps)',
    TRADE_COUNT COMMENT 'Number of trades',
    LAST_UPDATED COMMENT 'Timestamp when calculated'
) COMMENT = 'Yield curve construction by currency and maturity'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    t.CURRENCY,
    ROUND(DATEDIFF(DAY, CURRENT_DATE, t.MATURITY_DATE) / 365.0, 0) AS MATURITY_YEARS,
    ROUND(AVG(t.COUPON_RATE), 2) AS AVERAGE_YIELD,
    ROUND(AVG(t.CREDIT_SPREAD_BPS), 2) AS AVERAGE_CREDIT_SPREAD_BPS,
    COUNT(*) AS TRADE_COUNT,
    CURRENT_TIMESTAMP() AS LAST_UPDATED

FROM AAA_DEV_SYNTHETIC_BANK.FII_RAW_001.FIII_TRADES t
WHERE t.INSTRUMENT_TYPE = 'BOND'
  AND t.MATURITY_DATE > CURRENT_DATE
GROUP BY t.CURRENCY, MATURITY_YEARS
HAVING TRADE_COUNT >= 3  -- Minimum 3 trades for reliable yield point
ORDER BY t.CURRENCY, MATURITY_YEARS;

-- ============================================================
-- FII_AGG_001 Schema Setup Complete!
-- ============================================================
--
-- USAGE EXAMPLES:
--
-- 1. View current portfolio positions:
--    SELECT * FROM FIIA_AGG_DT_PORTFOLIO_POSITIONS 
--    WHERE POSITION_STATUS != 'CLOSED'
--    ORDER BY TOTAL_INVESTMENT_CHF DESC;
--
-- 2. Analyze interest rate risk:
--    SELECT CURRENCY, MATURITY_BUCKET, TOTAL_DV01_CHF, WEIGHTED_AVG_DURATION
--    FROM FIIA_AGG_DT_DURATION_ANALYSIS
--    ORDER BY TOTAL_DV01_CHF DESC;
--
-- 3. Monitor credit exposure:
--    SELECT CREDIT_RATING, ISSUER_TYPE, TOTAL_NOTIONAL_CHF, CONCENTRATION_PERCENTAGE
--    FROM FIIA_AGG_DT_CREDIT_EXPOSURE
--    ORDER BY TOTAL_NOTIONAL_CHF DESC;
--
-- 4. View yield curve:
--    SELECT * FROM FIIA_AGG_DT_YIELD_CURVE
--    WHERE CURRENCY = 'CHF'
--    ORDER BY MATURITY_YEARS;
--
-- 5. Check dynamic table refresh status:
--    SHOW DYNAMIC TABLES IN SCHEMA FII_AGG_001;
--
-- ============================================================
