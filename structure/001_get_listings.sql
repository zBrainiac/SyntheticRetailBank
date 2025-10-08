-- ============================================================
-- Snowflake Data Exchange - Global Sanctions Data Setup
-- Generated on: 2025-01-XX
-- ============================================================
--
-- OVERVIEW:
-- This script sets up access to the Global Sanctions Data Set from Snowflake's
-- Data Exchange marketplace. This provides real-time sanctions and watchlist
-- data for compliance screening and regulatory reporting.
--
-- PURPOSE:
-- - Import global sanctions data for PEP (Politically Exposed Persons) screening
-- - Enable compliance checking against international sanctions lists
-- - Support regulatory reporting and risk management
-- - Provide reference data for customer onboarding and transaction monitoring
--
-- DATA SOURCE:
-- - Snowflake Data Exchange Listing ID: GZT1ZVEJH9
-- - Global Sanctions Data Set with comprehensive international coverage
-- - Regular updates for current sanctions and watchlist information
--
-- PREREQUISITES:
-- - Snowflake account with Data Exchange access
-- - Legal terms acceptance for data usage
-- - Email verification for listing access
--
-- USAGE:
-- 1. Run this script to set up the sanctions data database
-- 2. Use the data for compliance screening in customer onboarding
-- 3. Integrate with PEP screening and risk assessment processes
-- 4. Support regulatory reporting and audit requirements
--
-- ============================================================

-- Step 1: Discover available listings (commented out - run manually if needed)
-- Get the global name and title of listings and filter on the title
-- SELECT "global_name", "title"
--   FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
--   WHERE "is_imported" = false
--     AND "title" LIKE '%Sanction%';

-- Step 2: Request access to the Global Sanctions Data listing
-- This initiates the listing request and waits for approval
CALL SYSTEM$REQUEST_LISTING_AND_WAIT('GZT1ZVEJH9');

-- Step 3: Accept legal terms for data usage
-- Email verification is required to create the database from listing
CALL SYSTEM$ACCEPT_LEGAL_TERMS('DATA_EXCHANGE_LISTING', 'GZT1ZVEJH9');

-- Step 4: Create database from the Data Exchange listing
-- This creates a new database with the sanctions data
CREATE DATABASE REF_DAP_GLOBAL_SANCTIONS_DATA_SET
  FROM LISTING 'GZT1ZVEJH9';

-- Step 5: Switch to the new database context
-- Use the new database for sanctions data access
USE DATABASE AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET;

-- Step 6: Access the sanctions data schema
-- Switch to the schema containing the sanctions data
USE SCHEMA GLOBAL_SANCTIONS_DATA;

-- ============================================================
-- DATA EXPLORATION AND USAGE
-- ============================================================
-- Once the database is created, you can explore the sanctions data:
--
-- -- Query the 'SANCTIONS_DATAFEED' table and limit the results to 10 rows
-- SELECT * FROM SANCTIONS_DATAFEED LIMIT 10;
--
-- -- Count total sanctions records
-- SELECT COUNT(*) as TOTAL_SANCTIONS FROM SANCTIONS_DATAFEED;
--
-- -- Check data freshness
-- SELECT MAX(LAST_UPDATED) as LATEST_UPDATE FROM SANCTIONS_DATAFEED;
--
-- -- Sample sanctions by country
-- SELECT COUNTRY, COUNT(*) as SANCTIONS_COUNT 
-- FROM SANCTIONS_DATAFEED 
-- GROUP BY COUNTRY 
-- ORDER BY SANCTIONS_COUNT DESC 
-- LIMIT 10;
--
-- ============================================================
-- INTEGRATION WITH SYNTHETIC BANK DATA
-- ============================================================
-- This sanctions data can be integrated with the synthetic bank data for:
--
-- 1. Customer Onboarding Screening:
--    - Check new customers against sanctions lists
--    - Flag potential matches for manual review
--    - Support KYC/AML compliance processes
--
-- 2. PEP (Politically Exposed Persons) Screening:
--    - Cross-reference with CRMI_EXPOSED_PERSON data
--    - Enhance compliance data with external sources
--    - Support regulatory reporting requirements
--
-- 3. Transaction Monitoring:
--    - Screen counterparties against sanctions lists
--    - Flag suspicious transactions for investigation
--    - Support real-time compliance checking
--
-- 4. Regulatory Reporting:
--    - Generate compliance reports
--    - Support audit requirements
--    - Provide evidence of due diligence
--
-- ============================================================
-- SANCTIONS DATA SETUP COMPLETED
-- ============================================================