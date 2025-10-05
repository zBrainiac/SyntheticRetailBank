-- ============================================================
-- Synthetic Banking - Database Setup
-- Generated on: 2025-09-22 15:50:17
-- Updated: 2025-10-04 (Schema consolidation and serverless tasks)
-- ============================================================
--
-- This script creates the database and schemas for the
-- synthetic EMEA retail bank data generator.
--
-- SCHEMAS CREATED:
-- RAW Layer (Data Ingestion):
--   • CRM_RAW_001 - Customer master data, addresses, accounts, PEP data
--   • REF_RAW_001 - Reference data (FX rates, lookup tables)
--   • PAY_RAW_001 - Payment transactions + SWIFT ISO20022 messages
--   • EQT_RAW_001 - Equity trading data (FIX protocol)
--   • FII_RAW_001 - Fixed income trades (bonds and interest rate swaps)
--   • CMD_RAW_001 - Commodity trades (energy, metals, agricultural)
--   • LOA_RAW_v001 - Loan information and mortgage data
--
-- AGGREGATION Layer (Business Logic):
--   • CRM_AGG_001 - Customer 360° views, SCD Type 2 addresses
--   • REF_AGG_001 - Enhanced FX rates with spreads
--   • PAY_AGG_001 - Transaction anomalies, account balances, SWIFT message processing
--   • EQT_AGG_001 - Equity trade analytics and portfolio positions
--   • FII_AGG_001 - Fixed income analytics (duration, DV01, credit risk)
--   • CMD_AGG_001 - Commodity analytics (delta risk, volatility, delivery tracking)
--   • LOA_AGG_v001 - Loan analytics and reporting
--
-- REPORTING Layer (Analytics):
--   • REP_AGG_001 - Cross-domain reporting, analytics, and FRTB market risk

-- ============================================================

-- Create database
CREATE DATABASE IF NOT EXISTS AAA_DEV_SYNTHETIC_BANK
    COMMENT = 'Bank Development Database';

USE DATABASE AAA_DEV_SYNTHETIC_BANK;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS CRM_RAW_001
    COMMENT = 'CRM raw data schema for customer/party information and accounts';

CREATE SCHEMA IF NOT EXISTS CRM_AGG_001
    COMMENT = 'CRM aggregation data schema for customer/party information';

CREATE SCHEMA IF NOT EXISTS REF_RAW_001
    COMMENT = 'Reference data schema for FX rates and other lookup tables';

CREATE SCHEMA IF NOT EXISTS REF_AGG_001
    COMMENT = 'Reference data aggregation schema for enhanced FX rates and analytics';

CREATE SCHEMA IF NOT EXISTS PAY_RAW_001
    COMMENT = 'Payment raw data schema for transaction information and SWIFT ISO20022 message storage';

CREATE SCHEMA IF NOT EXISTS PAY_AGG_001
    COMMENT = 'Payment aggregation schema for transaction analytics, anomaly detection, and SWIFT message processing';

CREATE SCHEMA IF NOT EXISTS EQT_RAW_001
    COMMENT = 'Equity trading raw data schema for FIX protocol trades';

CREATE SCHEMA IF NOT EXISTS EQT_AGG_001
    COMMENT = 'Equity trading aggregation schema for trade analytics and portfolio positions';

CREATE SCHEMA IF NOT EXISTS REP_AGG_001
    COMMENT = 'Reporting aggregation schema for dynamic tables and analytics';

CREATE SCHEMA IF NOT EXISTS FII_RAW_001
    COMMENT = 'Fixed Income raw data schema for bonds and interest rate swaps';

CREATE SCHEMA IF NOT EXISTS FII_AGG_001
    COMMENT = 'Fixed Income aggregation schema for duration, DV01, and credit risk analytics';

CREATE SCHEMA IF NOT EXISTS CMD_RAW_001
    COMMENT = 'Commodity raw data schema for energy, metals, and agricultural trades';

CREATE SCHEMA IF NOT EXISTS CMD_AGG_001
    COMMENT = 'Commodity aggregation schema for delta risk and volatility analytics';

CREATE SCHEMA IF NOT EXISTS LOA_RAW_v001
    COMMENT = 'Loan raw data schema for loan information';

CREATE SCHEMA IF NOT EXISTS LOA_AGG_v001
    COMMENT = 'Loan aggregation schema for loan analytics and reporting';

-- ============================================================
-- Database and schemas created successfully!
-- ============================================================
