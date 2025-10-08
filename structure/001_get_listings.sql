-- ============================================================
-- Snowflake Data Exchange - Global Sanctions Data Setup
-- Generated on: 2025-01-XX
-- ============================================================
--
-- OVERVIEW:
-- This script sets up access to the Global Sanctions Data Set from Snowflake's
-- Data Exchange marketplace. This provides real-time sanctions and watchlist
-- data for compliance screening and regulatory reporting.

-- ============================================================
-- DATA EXCHANGE SETUP - Global Sanctions Data Access
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

-- ============================================================
-- DATABASE CREATION - Global Sanctions Data Import
-- ============================================================

DROP DATABASE if exists AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET;

CREATE Database if not exists AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET
  FROM LISTING 'GZT1ZVEJH9';

-- ============================================================
-- DATA EXPLORATION AND USAGE
-- ============================================================
-- USE SCHEMA GLOBAL_SANCTIONS_DATA;
-- SELECT * FROM SANCTIONS_DATAFEED LIMIT 10;
-- ============================================================
-- Global Sanctions Data Setup Complete!
-- ============================================================