-- ============================================================
-- Synthetic Banking  - Database Setup
-- Generated on: 2025-09-22 15:50:17
-- ============================================================
--
-- This script creates the database and schemas for the
-- synthetic EMEA retail bank data generator.
--
-- Execution Order:
-- 1. Run this file first: 00_database_setup.sql
-- 2. Then run schema files in order:
--    - 01_CRM.sql (Customer/CRM data)
--    - 02_REF.sql (Reference data - FX rates)  
--    - 03_PAY.sql (Payment transactions)
--    - 04_EQT.sql (Equity trades)
--    - 05_ICG.sql (SWIFT ISO20022 Message Processing)
 --   - 05_REP.sql (Reporting/Aggregation)
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
    COMMENT = 'Payment raw data schema for transaction information';

CREATE SCHEMA IF NOT EXISTS PAY_AGG_001
    COMMENT = 'Payment aggregation schema for transaction analytics and anomaly detection';

CREATE SCHEMA IF NOT EXISTS EQT_RAW_001
    COMMENT = 'Equity trading raw data schema for FIX protocol trades';

CREATE SCHEMA IF NOT EXISTS REP_AGG_001
    COMMENT = 'Reporting aggregation schema for dynamic tables and analytics';

CREATE SCHEMA IF NOT EXISTS ICG_RAW_v001
    COMMENT = 'ICG raw data schema for SWIFT ISO20022 message storage';

CREATE SCHEMA IF NOT EXISTS ICG_AGG_v001
    COMMENT = 'ICG aggregation schema for processed SWIFT messages';

CREATE SCHEMA IF NOT EXISTS ICG_DAP_v001
    COMMENT = 'ICG data products schema for SWIFT analytics and reporting';

-- ============================================================
-- Database and schemas created successfully!
-- ============================================================
