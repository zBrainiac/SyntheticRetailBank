-- ============================================================
-- CRM_AGG_001 Schema - Customer Address Aggregation & SCD Type 2 Views
-- Generated on: 2025-09-27 (Updated)
-- ============================================================
--
-- OVERVIEW:
-- This schema provides aggregated views and Slowly Changing Dimension (SCD) Type 2
-- processing for customer address data. It transforms the append-only base table
-- from CRM_RAW_001.CRMI_ADDRESSES into business-ready dimensional views.
--
-- BUSINESS PURPOSE:
-- - Current address lookup for operational systems
-- - Historical address tracking for compliance and analytics
-- - Point-in-time address queries for regulatory reporting
-- - Address change audit trails for customer service
--
-- SCD TYPE 2 IMPLEMENTATION:
-- The base table (CRMI_ADDRESSES) uses an append-only structure where each
-- address change creates a new record with INSERT_TIMESTAMP_UTC. Dynamic tables
-- automatically convert this into proper SCD Type 2 with VALID_FROM/VALID_TO ranges.
--
-- OBJECTS CREATED:
-- ┌─ DYNAMIC TABLES (3):
-- │  ├─ CRMA_AGG_DT_ADDRESSES_CURRENT  - Latest address per customer (operational)
-- │  ├─ CRMA_AGG_DT_ADDRESSES_HISTORY  - Full SCD Type 2 history (analytical)
-- │  └─ CRMA_AGG_DT_CUSTOMER           - Comprehensive customer view with Exposed Person matching
-- │
-- └─ REFRESH STRATEGY:
--    ├─ TARGET_LAG: 1 hour (consistent with system schedule)
--    ├─ WAREHOUSE: MD_TEST_WH
--    └─ AUTO-REFRESH: Based on source table changes
--
-- DATA FLOW:
-- CRM_RAW_001.CRMI_ADDRESSES (append-only base)
--     ↓
-- CRMA_AGG_DT_ADDRESSES_CURRENT (latest addresses)
--     ↓
-- CRMA_AGG_DT_ADDRESSES_HISTORY (full SCD Type 2)
--     ↓
-- CRMA_AGG_DT_CUSTOMER (comprehensive view with Exposed Person matching)
--
-- SUPPORTED COUNTRIES:
-- Norway, Netherlands, Sweden, Germany, France, Italy, United Kingdom,
-- Denmark, Belgium, Austria, Switzerland (12 EMEA countries)
--
-- RELATED SCHEMAS:
-- - CRM_RAW_001: Source customer and address master data
-- - PAY_RAW_001: Payment transactions (address for compliance)
-- - EQT_RAW_001: Equity trades (address for tax reporting)
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_AGG_001;

-- ============================================================
-- DYNAMIC TABLES - SCD Type 2 Address Processing
-- ============================================================
-- Dynamic tables that automatically maintain current and historical address views
-- from the append-only base table. These tables refresh every 5 minutes based on
-- source data changes, providing near real-time dimensional processing.


-- ============================================================
-- CRMA_AGG_DT_ADDRESSES_CURRENT - Current Address Lookup (Operational)
-- ============================================================
-- Operational view providing the most recent address for each customer.
-- Used by front-end applications, customer service, and real-time processing.
-- Optimized for fast lookups with one record per customer.


CREATE OR REPLACE DYNAMIC TABLE CRMA_AGG_DT_ADDRESSES_CURRENT(
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier for address lookup (CUST_XXXXX format)',
    STREET_ADDRESS VARCHAR(200) COMMENT 'Current street address for customer correspondence',
    CITY VARCHAR(100) COMMENT 'Current city for customer location and compliance',
    STATE VARCHAR(100) COMMENT 'Current state/region for regulatory jurisdiction',
    ZIPCODE VARCHAR(20) COMMENT 'Current postal code for address validation',
    COUNTRY VARCHAR(50) COMMENT 'Current country for regulatory and tax purposes',
    CURRENT_FROM TIMESTAMP_NTZ COMMENT 'Date when this address became current/effective',
    IS_CURRENT BOOLEAN COMMENT 'Boolean flag indicating this is the current address (always TRUE)'
) COMMENT = 'Current/latest address for each customer. Operational view with one record per customer showing the most recent address based on INSERT_TIMESTAMP_UTC. Used for real-time customer lookups and front-end applications.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    CUSTOMER_ID,
    STREET_ADDRESS,
    CITY,
    STATE,
    ZIPCODE,
    COUNTRY,
    INSERT_TIMESTAMP_UTC AS CURRENT_FROM,
    TRUE AS IS_CURRENT
FROM (
    SELECT 
        CUSTOMER_ID,
        STREET_ADDRESS,
        CITY,
        STATE,
        ZIPCODE,
        COUNTRY,
        INSERT_TIMESTAMP_UTC,
        ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC DESC) as rn
    FROM CRM_RAW_001.CRMI_ADDRESSES
) ranked
WHERE rn = 1;

-- ============================================================
-- CRMA_AGG_DT_ADDRESSES_HISTORY - Address History SCD Type 2 (Analytical)
-- ============================================================
-- Analytical view providing complete SCD Type 2 address history with effective date ranges.
-- Used for compliance reporting, historical analysis, and point-in-time queries.
-- Includes VALID_FROM/VALID_TO ranges and IS_CURRENT flags for each address period.

CREATE OR REPLACE DYNAMIC TABLE CRMA_AGG_DT_ADDRESSES_HISTORY(
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier for address history tracking',
    STREET_ADDRESS VARCHAR(200) COMMENT 'Historical street address for compliance audit trail',
    CITY VARCHAR(100) COMMENT 'Historical city for location tracking and analysis',
    STATE VARCHAR(100) COMMENT 'Historical state/region for regulatory compliance',
    ZIPCODE VARCHAR(20) COMMENT 'Historical postal code for address validation',
    COUNTRY VARCHAR(50) COMMENT 'Historical country for regulatory and tax compliance',
    VALID_FROM DATE COMMENT 'Start date when this address was effective (SCD Type 2)',
    VALID_TO DATE COMMENT 'End date when this address was superseded (NULL if current)',
    IS_CURRENT BOOLEAN COMMENT 'Boolean flag indicating if this is the current address',
    INSERT_TIMESTAMP_UTC TIMESTAMP_NTZ COMMENT 'Original timestamp when address was recorded in system'
) COMMENT = 'SCD Type 2 address history with VALID_FROM/VALID_TO effective date ranges. Converts append-only base table into proper slowly changing dimension for compliance reporting, historical analysis, and point-in-time customer address queries.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    CUSTOMER_ID,
    STREET_ADDRESS,
    CITY,
    STATE,
    ZIPCODE,
    COUNTRY,
    INSERT_TIMESTAMP_UTC::DATE AS VALID_FROM,
    CASE 
        WHEN LEAD(INSERT_TIMESTAMP_UTC) OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC) IS NOT NULL 
        THEN LEAD(INSERT_TIMESTAMP_UTC) OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC)::DATE - 1
        ELSE NULL 
    END AS VALID_TO,
    CASE 
        WHEN LEAD(INSERT_TIMESTAMP_UTC) OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC) IS NULL 
        THEN TRUE 
        ELSE FALSE 
    END AS IS_CURRENT,
    INSERT_TIMESTAMP_UTC
FROM CRM_RAW_001.CRMI_ADDRESSES
ORDER BY CUSTOMER_ID, INSERT_TIMESTAMP_UTC;

-- ============================================================
-- CRMA_AGG_DT_CUSTOMER - Comprehensive Customer View with PEP Matching & Accuracy Scoring
-- ============================================================
-- 360-degree customer view combining master data, current address, accounts,
-- Exposed Person compliance fuzzy matching, and Global Sanctions Data fuzzy matching 
-- with accuracy percentage scoring. Used for comprehensive customer analysis, 
-- compliance screening, and risk assessment across all customer touchpoints 
-- with quantified match confidence levels for both PEP and sanctions screening.

CREATE OR REPLACE DYNAMIC TABLE CRMA_AGG_DT_CUSTOMER(
    CUSTOMER_ID VARCHAR(30) COMMENT 'Unique customer identifier for relationship management',
    FIRST_NAME VARCHAR(100) COMMENT 'Customer first name for identification and compliance',
    FAMILY_NAME VARCHAR(100) COMMENT 'Customer family/last name for identification and compliance',
    FULL_NAME VARCHAR(201) COMMENT 'Customer full name (First + Last) for reporting',
    DATE_OF_BIRTH DATE COMMENT 'Customer date of birth for identity verification',
    ONBOARDING_DATE DATE COMMENT 'Date when customer relationship was established',
    REPORTING_CURRENCY VARCHAR(3) COMMENT 'Customer reporting currency based on country',
    HAS_ANOMALY BOOLEAN COMMENT 'Flag indicating if customer has anomalous transaction patterns',
    STREET_ADDRESS VARCHAR(200) COMMENT 'Current street address for correspondence',
    CITY VARCHAR(100) COMMENT 'Current city for location and regulatory purposes',
    STATE VARCHAR(100) COMMENT 'Current state/region for jurisdiction and compliance',
    ZIPCODE VARCHAR(20) COMMENT 'Current postal code for address validation',
    COUNTRY VARCHAR(50) COMMENT 'Current country for regulatory and tax purposes',
    ADDRESS_EFFECTIVE_DATE TIMESTAMP_NTZ COMMENT 'Date when current address became effective',
    TOTAL_ACCOUNTS NUMBER(10,0) COMMENT 'Total number of accounts held by customer',
    ACCOUNT_TYPES VARCHAR(200) COMMENT 'Comma-separated list of account types held',
    CURRENCIES VARCHAR(50) COMMENT 'Comma-separated list of currencies used by customer',
    CHECKING_ACCOUNTS NUMBER(10,0) COMMENT 'Number of checking accounts held',
    SAVINGS_ACCOUNTS NUMBER(10,0) COMMENT 'Number of savings accounts held',
    BUSINESS_ACCOUNTS NUMBER(10,0) COMMENT 'Number of business accounts held',
    INVESTMENT_ACCOUNTS NUMBER(10,0) COMMENT 'Number of investment accounts held',
    EXPOSED_PERSON_EXACT_MATCH_ID VARCHAR(50) COMMENT 'PEP ID for exact name match (compliance)',
    EXPOSED_PERSON_EXACT_MATCH_NAME VARCHAR(200) COMMENT 'PEP name for exact match (compliance)',
    EXPOSED_PERSON_EXACT_CATEGORY VARCHAR(50) COMMENT 'PEP category for exact match (DOMESTIC/FOREIGN/etc.)',
    EXPOSED_PERSON_EXACT_RISK_LEVEL VARCHAR(20) COMMENT 'PEP risk level for exact match (CRITICAL/HIGH/MEDIUM/LOW)',
    EXPOSED_PERSON_EXACT_STATUS VARCHAR(20) COMMENT 'PEP status for exact match (ACTIVE/INACTIVE)',
    EXPOSED_PERSON_FUZZY_MATCH_ID VARCHAR(50) COMMENT 'PEP ID for fuzzy name match (compliance)',
    EXPOSED_PERSON_FUZZY_MATCH_NAME VARCHAR(200) COMMENT 'PEP name for fuzzy match (compliance)',
    EXPOSED_PERSON_FUZZY_CATEGORY VARCHAR(50) COMMENT 'PEP category for fuzzy match (DOMESTIC/FOREIGN/etc.)',
    EXPOSED_PERSON_FUZZY_RISK_LEVEL VARCHAR(20) COMMENT 'PEP risk level for fuzzy match (CRITICAL/HIGH/MEDIUM/LOW)',
    EXPOSED_PERSON_FUZZY_STATUS VARCHAR(20) COMMENT 'PEP status for fuzzy match (ACTIVE/INACTIVE)',
    EXPOSED_PERSON_MATCH_ACCURACY_PERCENT NUMBER(5,2) COMMENT 'PEP match accuracy percentage (70-100% for fuzzy, 100% for exact)',
    EXPOSED_PERSON_MATCH_TYPE VARCHAR(15) COMMENT 'Type of PEP match (EXACT_MATCH/FUZZY_MATCH/NO_MATCH)',
    SANCTIONS_EXACT_MATCH_ID VARCHAR(50) COMMENT 'Sanctions ID for exact name match against global sanctions data',
    SANCTIONS_EXACT_MATCH_NAME VARCHAR(200) COMMENT 'Sanctions name for exact match against global sanctions data',
    SANCTIONS_EXACT_MATCH_TYPE VARCHAR(20) COMMENT 'Sanctions match type (INDIVIDUAL/ENTITY) for exact match',
    SANCTIONS_EXACT_MATCH_COUNTRY VARCHAR(50) COMMENT 'Sanctions country for exact match',
    SANCTIONS_FUZZY_MATCH_ID VARCHAR(50) COMMENT 'Sanctions ID for fuzzy name match against global sanctions data',
    SANCTIONS_FUZZY_MATCH_NAME VARCHAR(200) COMMENT 'Sanctions name for fuzzy match against global sanctions data',
    SANCTIONS_FUZZY_MATCH_TYPE VARCHAR(20) COMMENT 'Sanctions match type (INDIVIDUAL/ENTITY) for fuzzy match',
    SANCTIONS_FUZZY_MATCH_COUNTRY VARCHAR(50) COMMENT 'Sanctions country for fuzzy match',
    SANCTIONS_MATCH_ACCURACY_PERCENT NUMBER(5,2) COMMENT 'Sanctions match accuracy percentage (70-100% for fuzzy, 100% for exact)',
    SANCTIONS_MATCH_TYPE VARCHAR(15) COMMENT 'Type of sanctions match (EXACT_MATCH/FUZZY_MATCH/NO_MATCH)',
    OVERALL_EXPOSED_PERSON_RISK VARCHAR(30) COMMENT 'Overall PEP risk assessment (CRITICAL/HIGH/MEDIUM/LOW/NO_EXPOSED_PERSON_RISK)',
    OVERALL_SANCTIONS_RISK VARCHAR(30) COMMENT 'Overall sanctions risk assessment (CRITICAL/HIGH/MEDIUM/LOW/NO_SANCTIONS_RISK)',
    OVERALL_RISK_RATING VARCHAR(20) COMMENT 'Comprehensive risk rating combining PEP, sanctions, and anomalies (CRITICAL/HIGH/MEDIUM/LOW/NO_RISK)',
    OVERALL_RISK_SCORE NUMBER(5,2) COMMENT 'Numerical risk score (0-100) combining all risk factors',
    REQUIRES_EXPOSED_PERSON_REVIEW BOOLEAN COMMENT 'Boolean flag indicating if customer requires PEP compliance review',
    REQUIRES_SANCTIONS_REVIEW BOOLEAN COMMENT 'Boolean flag indicating if customer requires sanctions compliance review',
    HIGH_RISK_CUSTOMER BOOLEAN COMMENT 'Boolean flag for customers with both anomalies and PEP/sanctions matches',
    LAST_UPDATED TIMESTAMP_NTZ COMMENT 'Timestamp when customer record was last updated'
) COMMENT = 'Comprehensive 360-degree customer view with master data, current address, account summary, Exposed Person fuzzy matching, and Global Sanctions Data fuzzy matching with accuracy scoring for compliance screening. Combines operational and compliance data for holistic customer risk assessment and regulatory reporting with both PEP and sanctions screening capabilities.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    -- Customer Master Data
    c.CUSTOMER_ID,
    c.FIRST_NAME,
    c.FAMILY_NAME,
    CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME) AS FULL_NAME,
    c.DATE_OF_BIRTH,
    c.ONBOARDING_DATE,
    c.REPORTING_CURRENCY,
    c.HAS_ANOMALY,
    
    -- Current Address Information
    addr.STREET_ADDRESS,
    addr.CITY,
    addr.STATE,
    addr.ZIPCODE,
    addr.COUNTRY,
    addr.CURRENT_FROM AS ADDRESS_EFFECTIVE_DATE,
    
    -- Account Summary
    COUNT(acc.ACCOUNT_ID) AS TOTAL_ACCOUNTS,
    LISTAGG(DISTINCT acc.ACCOUNT_TYPE, ', ') WITHIN GROUP (ORDER BY acc.ACCOUNT_TYPE) AS ACCOUNT_TYPES,
    LISTAGG(DISTINCT acc.BASE_CURRENCY, ', ') WITHIN GROUP (ORDER BY acc.BASE_CURRENCY) AS CURRENCIES,
    COUNT(CASE WHEN acc.ACCOUNT_TYPE = 'CHECKING' THEN 1 END) AS CHECKING_ACCOUNTS,
    COUNT(CASE WHEN acc.ACCOUNT_TYPE = 'SAVINGS' THEN 1 END) AS SAVINGS_ACCOUNTS,
    COUNT(CASE WHEN acc.ACCOUNT_TYPE = 'BUSINESS' THEN 1 END) AS BUSINESS_ACCOUNTS,
    COUNT(CASE WHEN acc.ACCOUNT_TYPE = 'INVESTMENT' THEN 1 END) AS INVESTMENT_ACCOUNTS,
    
    -- PEP Compliance Fuzzy Matching
    -- Exact name match
    pep_exact.EXPOSED_PERSON_ID AS EXPOSED_PERSON_EXACT_MATCH_ID,
    pep_exact.FULL_NAME AS EXPOSED_PERSON_EXACT_MATCH_NAME,
    pep_exact.EXPOSED_PERSON_CATEGORY AS EXPOSED_PERSON_EXACT_CATEGORY,
    pep_exact.RISK_LEVEL AS EXPOSED_PERSON_EXACT_RISK_LEVEL,
    pep_exact.STATUS AS EXPOSED_PERSON_EXACT_STATUS,
    
    -- Fuzzy name matching (similar names)
    pep_fuzzy.EXPOSED_PERSON_ID AS EXPOSED_PERSON_FUZZY_MATCH_ID,
    pep_fuzzy.FULL_NAME AS EXPOSED_PERSON_FUZZY_MATCH_NAME,
    pep_fuzzy.EXPOSED_PERSON_CATEGORY AS EXPOSED_PERSON_FUZZY_CATEGORY,
    pep_fuzzy.RISK_LEVEL AS EXPOSED_PERSON_FUZZY_RISK_LEVEL,
    pep_fuzzy.STATUS AS EXPOSED_PERSON_FUZZY_STATUS,
    
    -- PEP Match Accuracy Level
    CASE 
        WHEN pep_exact.EXPOSED_PERSON_ID IS NOT NULL THEN 100.0  -- Exact match = 100% accuracy
        WHEN pep_fuzzy.EXPOSED_PERSON_ID IS NOT NULL THEN
            -- Calculate accuracy based on edit distance for fuzzy matches
            CASE 
                -- Both names have edit distance of 1 (highest fuzzy accuracy)
                WHEN EDITDISTANCE(UPPER(c.FIRST_NAME), UPPER(pep_fuzzy.FIRST_NAME)) = 1
                     AND EDITDISTANCE(UPPER(c.FAMILY_NAME), UPPER(pep_fuzzy.LAST_NAME)) = 1 
                THEN 95.0
                -- One exact name, other with edit distance 1
                WHEN (UPPER(c.FIRST_NAME) = UPPER(pep_fuzzy.FIRST_NAME) AND EDITDISTANCE(UPPER(c.FAMILY_NAME), UPPER(pep_fuzzy.LAST_NAME)) = 1)
                     OR (EDITDISTANCE(UPPER(c.FIRST_NAME), UPPER(pep_fuzzy.FIRST_NAME)) = 1 AND UPPER(c.FAMILY_NAME) = UPPER(pep_fuzzy.LAST_NAME))
                THEN 90.0
                -- One exact name, other with edit distance 2
                WHEN (UPPER(c.FIRST_NAME) = UPPER(pep_fuzzy.FIRST_NAME) AND EDITDISTANCE(UPPER(c.FAMILY_NAME), UPPER(pep_fuzzy.LAST_NAME)) = 2)
                     OR (EDITDISTANCE(UPPER(c.FIRST_NAME), UPPER(pep_fuzzy.FIRST_NAME)) = 2 AND UPPER(c.FAMILY_NAME) = UPPER(pep_fuzzy.LAST_NAME))
                THEN 85.0
                -- Full name similarity with edit distance <= 3
                WHEN EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(pep_fuzzy.FULL_NAME)) <= 3
                THEN GREATEST(70.0, 100.0 - (EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(pep_fuzzy.FULL_NAME)) * 10.0))
                -- Default fuzzy match accuracy
                ELSE 75.0
            END
        ELSE NULL  -- No match
    END AS EXPOSED_PERSON_MATCH_ACCURACY_PERCENT,
    
    -- PEP Risk Assessment
    CASE 
        WHEN pep_exact.EXPOSED_PERSON_ID IS NOT NULL THEN 'EXACT_MATCH'
        WHEN pep_fuzzy.EXPOSED_PERSON_ID IS NOT NULL THEN 'FUZZY_MATCH'
        ELSE 'NO_MATCH'
    END AS EXPOSED_PERSON_MATCH_TYPE,
    
    CASE 
        WHEN pep_exact.RISK_LEVEL = 'CRITICAL' OR pep_fuzzy.RISK_LEVEL = 'CRITICAL' THEN 'CRITICAL'
        WHEN pep_exact.RISK_LEVEL = 'HIGH' OR pep_fuzzy.RISK_LEVEL = 'HIGH' THEN 'HIGH'
        WHEN pep_exact.RISK_LEVEL = 'MEDIUM' OR pep_fuzzy.RISK_LEVEL = 'MEDIUM' THEN 'MEDIUM'
        WHEN pep_exact.RISK_LEVEL = 'LOW' OR pep_fuzzy.RISK_LEVEL = 'LOW' THEN 'LOW'
        ELSE 'NO_EXPOSED_PERSON_RISK'
    END AS OVERALL_EXPOSED_PERSON_RISK,
    
    -- Sanctions Matching (Global Sanctions Data) - Fuzzy matching against external database
    sanctions_exact.ENTITY_ID AS SANCTIONS_EXACT_MATCH_ID,
    sanctions_exact.ENTITY_NAME AS SANCTIONS_EXACT_MATCH_NAME,
    sanctions_exact.ENTITY_TYPE AS SANCTIONS_EXACT_MATCH_TYPE,
    sanctions_exact.COUNTRY AS SANCTIONS_EXACT_MATCH_COUNTRY,
    
    sanctions_fuzzy.ENTITY_ID AS SANCTIONS_FUZZY_MATCH_ID,
    sanctions_fuzzy.ENTITY_NAME AS SANCTIONS_FUZZY_MATCH_NAME,
    sanctions_fuzzy.ENTITY_TYPE AS SANCTIONS_FUZZY_MATCH_TYPE,
    sanctions_fuzzy.COUNTRY AS SANCTIONS_FUZZY_MATCH_COUNTRY,
    
    -- Sanctions Match Accuracy Level
    CASE 
        WHEN sanctions_exact.ENTITY_ID IS NOT NULL THEN 100.0  -- Exact match = 100% accuracy
        WHEN sanctions_fuzzy.ENTITY_ID IS NOT NULL THEN
            -- Calculate accuracy based on edit distance for fuzzy matches
            CASE 
                -- Edit distance of 1 (highest fuzzy accuracy)
                WHEN EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(sanctions_fuzzy.ENTITY_NAME)) = 1
                THEN 95.0
                -- Edit distance of 2
                WHEN EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(sanctions_fuzzy.ENTITY_NAME)) = 2
                THEN 90.0
                -- Edit distance of 3
                WHEN EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(sanctions_fuzzy.ENTITY_NAME)) = 3
                THEN 85.0
                -- Edit distance of 4
                WHEN EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(sanctions_fuzzy.ENTITY_NAME)) = 4
                THEN 80.0
                -- Edit distance of 5 (lowest acceptable fuzzy match)
                WHEN EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(sanctions_fuzzy.ENTITY_NAME)) = 5
                THEN 75.0
                -- Default fuzzy match accuracy
                ELSE 70.0
            END
        ELSE NULL  -- No match
    END AS SANCTIONS_MATCH_ACCURACY_PERCENT,
    
    -- Sanctions Risk Assessment
    CASE 
        WHEN sanctions_exact.ENTITY_ID IS NOT NULL THEN 'EXACT_MATCH'
        WHEN sanctions_fuzzy.ENTITY_ID IS NOT NULL THEN 'FUZZY_MATCH'
        ELSE 'NO_MATCH'
    END AS SANCTIONS_MATCH_TYPE,
    
    CASE 
        WHEN sanctions_exact.ENTITY_ID IS NOT NULL OR sanctions_fuzzy.ENTITY_ID IS NOT NULL THEN 'CRITICAL'
        ELSE 'NO_SANCTIONS_RISK'
    END AS OVERALL_SANCTIONS_RISK,
    
    -- Overall Risk Rating (combines PEP, sanctions, and anomalies)
    CASE 
        -- CRITICAL: Any sanctions match OR (PEP CRITICAL + anomaly)
        WHEN sanctions_exact.ENTITY_ID IS NOT NULL OR sanctions_fuzzy.ENTITY_ID IS NOT NULL THEN 'CRITICAL'
        WHEN (pep_exact.RISK_LEVEL = 'CRITICAL' OR pep_fuzzy.RISK_LEVEL = 'CRITICAL') AND c.HAS_ANOMALY = TRUE THEN 'CRITICAL'
        
        -- HIGH: PEP HIGH + anomaly OR PEP CRITICAL without anomaly
        WHEN (pep_exact.RISK_LEVEL = 'HIGH' OR pep_fuzzy.RISK_LEVEL = 'HIGH') AND c.HAS_ANOMALY = TRUE THEN 'HIGH'
        WHEN pep_exact.RISK_LEVEL = 'CRITICAL' OR pep_fuzzy.RISK_LEVEL = 'CRITICAL' THEN 'HIGH'
        
        -- MEDIUM: PEP MEDIUM + anomaly OR PEP HIGH without anomaly
        WHEN (pep_exact.RISK_LEVEL = 'MEDIUM' OR pep_fuzzy.RISK_LEVEL = 'MEDIUM') AND c.HAS_ANOMALY = TRUE THEN 'MEDIUM'
        WHEN pep_exact.RISK_LEVEL = 'HIGH' OR pep_fuzzy.RISK_LEVEL = 'HIGH' THEN 'MEDIUM'
        
        -- LOW: PEP LOW + anomaly OR PEP MEDIUM without anomaly OR anomaly only
        WHEN (pep_exact.RISK_LEVEL = 'LOW' OR pep_fuzzy.RISK_LEVEL = 'LOW') AND c.HAS_ANOMALY = TRUE THEN 'LOW'
        WHEN pep_exact.RISK_LEVEL = 'MEDIUM' OR pep_fuzzy.RISK_LEVEL = 'MEDIUM' THEN 'LOW'
        WHEN c.HAS_ANOMALY = TRUE THEN 'LOW'
        WHEN pep_exact.RISK_LEVEL = 'LOW' OR pep_fuzzy.RISK_LEVEL = 'LOW' THEN 'LOW'
        
        -- NO_RISK: No matches and no anomalies
        ELSE 'NO_RISK'
    END AS OVERALL_RISK_RATING,
    
    -- Overall Risk Score (0-100 numerical score)
    CASE 
        -- CRITICAL: 90-100
        WHEN sanctions_exact.ENTITY_ID IS NOT NULL OR sanctions_fuzzy.ENTITY_ID IS NOT NULL THEN 100
        WHEN (pep_exact.RISK_LEVEL = 'CRITICAL' OR pep_fuzzy.RISK_LEVEL = 'CRITICAL') AND c.HAS_ANOMALY = TRUE THEN 95
        
        -- HIGH: 70-89
        WHEN (pep_exact.RISK_LEVEL = 'HIGH' OR pep_fuzzy.RISK_LEVEL = 'HIGH') AND c.HAS_ANOMALY = TRUE THEN 85
        WHEN pep_exact.RISK_LEVEL = 'CRITICAL' OR pep_fuzzy.RISK_LEVEL = 'CRITICAL' THEN 80
        
        -- MEDIUM: 50-69
        WHEN (pep_exact.RISK_LEVEL = 'MEDIUM' OR pep_fuzzy.RISK_LEVEL = 'MEDIUM') AND c.HAS_ANOMALY = TRUE THEN 65
        WHEN pep_exact.RISK_LEVEL = 'HIGH' OR pep_fuzzy.RISK_LEVEL = 'HIGH' THEN 60
        
        -- LOW: 20-49
        WHEN (pep_exact.RISK_LEVEL = 'LOW' OR pep_fuzzy.RISK_LEVEL = 'LOW') AND c.HAS_ANOMALY = TRUE THEN 45
        WHEN pep_exact.RISK_LEVEL = 'MEDIUM' OR pep_fuzzy.RISK_LEVEL = 'MEDIUM' THEN 40
        WHEN c.HAS_ANOMALY = TRUE THEN 35
        WHEN pep_exact.RISK_LEVEL = 'LOW' OR pep_fuzzy.RISK_LEVEL = 'LOW' THEN 30
        
        -- NO_RISK: 0-19
        ELSE 10
    END AS OVERALL_RISK_SCORE,
    
    -- Compliance Flags
    CASE 
        WHEN pep_exact.EXPOSED_PERSON_ID IS NOT NULL OR pep_fuzzy.EXPOSED_PERSON_ID IS NOT NULL THEN TRUE 
        ELSE FALSE 
    END AS REQUIRES_EXPOSED_PERSON_REVIEW,
    
    CASE 
        WHEN sanctions_exact.ENTITY_ID IS NOT NULL OR sanctions_fuzzy.ENTITY_ID IS NOT NULL THEN TRUE 
        ELSE FALSE 
    END AS REQUIRES_SANCTIONS_REVIEW,
    
    CASE 
        WHEN c.HAS_ANOMALY = TRUE AND (pep_exact.EXPOSED_PERSON_ID IS NOT NULL OR pep_fuzzy.EXPOSED_PERSON_ID IS NOT NULL OR sanctions_exact.ENTITY_ID IS NOT NULL OR sanctions_fuzzy.ENTITY_ID IS NOT NULL) THEN TRUE
        ELSE FALSE
    END AS HIGH_RISK_CUSTOMER,
    
    -- Metadata
    CURRENT_TIMESTAMP() AS LAST_UPDATED

FROM CRM_RAW_001.CRMI_PARTY c

-- Join current address
LEFT JOIN CRMA_AGG_DT_ADDRESSES_CURRENT addr
    ON c.CUSTOMER_ID = addr.CUSTOMER_ID

-- Join accounts (aggregated)
LEFT JOIN CRM_RAW_001.ACCI_ACCOUNTS acc
    ON c.CUSTOMER_ID = acc.CUSTOMER_ID

-- Exact Exposed Person name matching
LEFT JOIN CRM_RAW_001.CRMI_EXPOSED_PERSON pep_exact
    ON UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)) = UPPER(pep_exact.FULL_NAME)
    AND pep_exact.STATUS = 'ACTIVE'

-- Fuzzy Exposed Person name matching (similar names, different spellings)
LEFT JOIN CRM_RAW_001.CRMI_EXPOSED_PERSON pep_fuzzy
    ON pep_fuzzy.EXPOSED_PERSON_ID != COALESCE(pep_exact.EXPOSED_PERSON_ID, 'NO_EXACT_MATCH')  -- Avoid duplicate matches
    AND pep_fuzzy.STATUS = 'ACTIVE'
    AND (
        -- Similar first name and exact last name
        (EDITDISTANCE(UPPER(c.FIRST_NAME), UPPER(pep_fuzzy.FIRST_NAME)) <= 2 
         AND UPPER(c.FAMILY_NAME) = UPPER(pep_fuzzy.LAST_NAME))
        OR
        -- Exact first name and similar last name  
        (UPPER(c.FIRST_NAME) = UPPER(pep_fuzzy.FIRST_NAME)
         AND EDITDISTANCE(UPPER(c.FAMILY_NAME), UPPER(pep_fuzzy.LAST_NAME)) <= 2)
        OR
        -- Both names similar (stricter threshold)
        (EDITDISTANCE(UPPER(c.FIRST_NAME), UPPER(pep_fuzzy.FIRST_NAME)) = 1
         AND EDITDISTANCE(UPPER(c.FAMILY_NAME), UPPER(pep_fuzzy.LAST_NAME)) = 1)
        OR
        -- Full name similarity (for compound names)
        EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(pep_fuzzy.FULL_NAME)) <= 3
    )

-- Sanctions matching against Global Sanctions Data with fuzzy matching
-- Using copy database to avoid external database limitations
LEFT JOIN AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET_COPY.PUBLIC.SANCTIONS_DATA_STAGING sanctions_exact
    ON UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)) = UPPER(sanctions_exact.ENTITY_NAME)

LEFT JOIN AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET_COPY.PUBLIC.SANCTIONS_DATA_STAGING sanctions_fuzzy
    ON sanctions_fuzzy.ENTITY_ID != COALESCE(sanctions_exact.ENTITY_ID, 'NO_EXACT_MATCH')
    AND EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(sanctions_fuzzy.ENTITY_NAME)) <= 5

GROUP BY 
    c.CUSTOMER_ID, c.FIRST_NAME, c.FAMILY_NAME, c.DATE_OF_BIRTH, c.ONBOARDING_DATE, c.REPORTING_CURRENCY, c.HAS_ANOMALY,
    addr.STREET_ADDRESS, addr.CITY, addr.STATE, addr.ZIPCODE, addr.COUNTRY, addr.CURRENT_FROM,
    pep_exact.EXPOSED_PERSON_ID, pep_exact.FULL_NAME, pep_exact.EXPOSED_PERSON_CATEGORY, pep_exact.RISK_LEVEL, pep_exact.STATUS,
    pep_fuzzy.EXPOSED_PERSON_ID, pep_fuzzy.FULL_NAME, pep_fuzzy.FIRST_NAME, pep_fuzzy.LAST_NAME, pep_fuzzy.EXPOSED_PERSON_CATEGORY, pep_fuzzy.RISK_LEVEL, pep_fuzzy.STATUS,
    sanctions_exact.ENTITY_ID, sanctions_exact.ENTITY_NAME, sanctions_exact.ENTITY_TYPE, sanctions_exact.COUNTRY,
    sanctions_fuzzy.ENTITY_ID, sanctions_fuzzy.ENTITY_NAME, sanctions_fuzzy.ENTITY_TYPE, sanctions_fuzzy.COUNTRY

ORDER BY c.CUSTOMER_ID;

-- ============================================================
-- CRM_AGG_001 Schema Setup Complete!
-- ============================================================
--
-- DYNAMIC TABLE REFRESH STATUS:
-- All three dynamic tables will automatically refresh based on changes to the
-- source tables with a 1-hour target lag. The 360° view depends on multiple
-- source tables: CRMI_PARTY, CRMI_ADDRESSES, ACCI_ACCOUNTS, CRMI_EXPOSED_PERSON,
-- and Global Sanctions Data from Snowflake Data Exchange with comprehensive fuzzy matching.
--
-- USAGE EXAMPLES:
--
-- 1. Get current address for a customer:
--    SELECT * FROM CRMA_AGG_DT_ADDRESSES_CURRENT 
--    WHERE CUSTOMER_ID = 'CUST_00001';
--
-- 2. Get address history for compliance:
--    SELECT * FROM CRMA_AGG_DT_ADDRESSES_HISTORY 
--    WHERE CUSTOMER_ID = 'CUST_00001' 
--    ORDER BY VALID_FROM;
--
-- 3. Point-in-time address query:
--    SELECT * FROM CRMA_AGG_DT_ADDRESSES_HISTORY 
--    WHERE CUSTOMER_ID = 'CUST_00001' 
--    AND '2024-06-15' BETWEEN VALID_FROM AND COALESCE(VALID_TO, CURRENT_DATE());
--
-- 4. Address change audit trail:
--    SELECT CUSTOMER_ID, VALID_FROM, VALID_TO, STREET_ADDRESS, CITY, COUNTRY
--    FROM CRMA_AGG_DT_ADDRESSES_HISTORY 
--    WHERE CUSTOMER_ID = 'CUST_00001'
--    ORDER BY VALID_FROM;
--
-- 5. Comprehensive customer view with Exposed Person and Sanctions screening:
--    SELECT * FROM CRMA_AGG_DT_CUSTOMER 
--    WHERE CUSTOMER_ID = 'CUST_00001';
--
-- 6. Find customers with sanctions matches:
--    SELECT CUSTOMER_ID, FULL_NAME, SANCTIONS_MATCH_TYPE, SANCTIONS_MATCH_ACCURACY_PERCENT,
--           SANCTIONS_EXACT_MATCH_NAME, SANCTIONS_FUZZY_MATCH_NAME
--    FROM CRMA_AGG_DT_CUSTOMER 
--    WHERE SANCTIONS_MATCH_TYPE != 'NO_MATCH';
--
-- 7. High-risk customers (anomalies + PEP + sanctions):
--    SELECT CUSTOMER_ID, FULL_NAME, HIGH_RISK_CUSTOMER, OVERALL_EXPOSED_PERSON_RISK, OVERALL_SANCTIONS_RISK
--    FROM CRMA_AGG_DT_CUSTOMER 
--    WHERE HIGH_RISK_CUSTOMER = TRUE;
--
-- 8. Compliance review queue:
--    SELECT CUSTOMER_ID, FULL_NAME, REQUIRES_EXPOSED_PERSON_REVIEW, REQUIRES_SANCTIONS_REVIEW
--    FROM CRMA_AGG_DT_CUSTOMER 
--    WHERE REQUIRES_EXPOSED_PERSON_REVIEW = TRUE OR REQUIRES_SANCTIONS_REVIEW = TRUE;
--
-- 6. Find customers with Exposed Person matches (with accuracy):
--    SELECT CUSTOMER_ID, FULL_NAME, EXPOSED_PERSON_MATCH_TYPE, OVERALL_EXPOSED_PERSON_RISK, EXPOSED_PERSON_MATCH_ACCURACY_PERCENT
--    FROM CRMA_AGG_DT_CUSTOMER 
--    WHERE EXPOSED_PERSON_MATCH_TYPE != 'NO_MATCH'
--    ORDER BY EXPOSED_PERSON_MATCH_ACCURACY_PERCENT DESC, OVERALL_EXPOSED_PERSON_RISK DESC;
--
-- 7. High-risk customers (anomaly + PEP) with match accuracy:
--    SELECT CUSTOMER_ID, FULL_NAME, COUNTRY, TOTAL_ACCOUNTS, 
--           EXPOSED_PERSON_EXACT_MATCH_NAME, EXPOSED_PERSON_FUZZY_MATCH_NAME, OVERALL_EXPOSED_PERSON_RISK, EXPOSED_PERSON_MATCH_ACCURACY_PERCENT
--    FROM CRMA_AGG_DT_CUSTOMER 
--    WHERE HIGH_RISK_CUSTOMER = TRUE;
--
-- 8. Exposed Person match accuracy analysis:
--    SELECT 
--        EXPOSED_PERSON_MATCH_TYPE,
--        CASE 
--            WHEN EXPOSED_PERSON_MATCH_ACCURACY_PERCENT = 100 THEN 'EXACT (100%)'
--            WHEN EXPOSED_PERSON_MATCH_ACCURACY_PERCENT >= 90 THEN 'HIGH (90-99%)'
--            WHEN EXPOSED_PERSON_MATCH_ACCURACY_PERCENT >= 80 THEN 'MEDIUM (80-89%)'
--            WHEN EXPOSED_PERSON_MATCH_ACCURACY_PERCENT >= 70 THEN 'LOW (70-79%)'
--            ELSE 'NO_MATCH'
--        END AS ACCURACY_BAND,
--        COUNT(*) AS CUSTOMER_COUNT,
--        AVG(EXPOSED_PERSON_MATCH_ACCURACY_PERCENT) AS AVG_ACCURACY
--    FROM CRMA_AGG_DT_CUSTOMER 
--    WHERE EXPOSED_PERSON_MATCH_TYPE != 'NO_MATCH'
--    GROUP BY EXPOSED_PERSON_MATCH_TYPE, ACCURACY_BAND
--    ORDER BY AVG_ACCURACY DESC;
--
-- 9. Customer compliance summary:
--    SELECT 
--        COUNT(*) AS TOTAL_CUSTOMERS,
--        COUNT(CASE WHEN EXPOSED_PERSON_MATCH_TYPE = 'EXACT_MATCH' THEN 1 END) AS EXACT_EXPOSED_PERSON_MATCHES,
--        COUNT(CASE WHEN EXPOSED_PERSON_MATCH_TYPE = 'FUZZY_MATCH' THEN 1 END) AS FUZZY_EXPOSED_PERSON_MATCHES,
--        COUNT(CASE WHEN REQUIRES_EXPOSED_PERSON_REVIEW = TRUE THEN 1 END) AS REQUIRES_REVIEW,
--        COUNT(CASE WHEN HIGH_RISK_CUSTOMER = TRUE THEN 1 END) AS HIGH_RISK_COUNT,
--        AVG(CASE WHEN EXPOSED_PERSON_MATCH_ACCURACY_PERCENT IS NOT NULL THEN EXPOSED_PERSON_MATCH_ACCURACY_PERCENT END) AS AVG_MATCH_ACCURACY
--    FROM CRMA_AGG_DT_CUSTOMER;
--
-- 10. Sanctions screening with Global Sanctions Data:
--    SELECT CUSTOMER_ID, FULL_NAME, COUNTRY,
--           SANCTIONS_EXACT_MATCH_NAME, SANCTIONS_FUZZY_MATCH_NAME, 
--           SANCTIONS_MATCH_TYPE, OVERALL_SANCTIONS_RISK, SANCTIONS_MATCH_ACCURACY_PERCENT
--    FROM CRMA_AGG_DT_CUSTOMER 
--    WHERE SANCTIONS_MATCH_TYPE != 'NO_MATCH'
--    ORDER BY SANCTIONS_MATCH_ACCURACY_PERCENT DESC, OVERALL_SANCTIONS_RISK DESC;
--
-- 11. High-risk customers with both PEP and Sanctions matches:
--    SELECT CUSTOMER_ID, FULL_NAME, COUNTRY, TOTAL_ACCOUNTS,
--           EXPOSED_PERSON_EXACT_MATCH_NAME, SANCTIONS_EXACT_MATCH_NAME,
--           OVERALL_EXPOSED_PERSON_RISK, OVERALL_SANCTIONS_RISK
--    FROM CRMA_AGG_DT_CUSTOMER 
--    WHERE HIGH_RISK_CUSTOMER = TRUE;
--
-- 12. Sanctions match accuracy analysis:
--    SELECT 
--        SANCTIONS_MATCH_TYPE,
--        CASE 
--            WHEN SANCTIONS_MATCH_ACCURACY_PERCENT = 100 THEN 'EXACT (100%)'
--            WHEN SANCTIONS_MATCH_ACCURACY_PERCENT >= 90 THEN 'HIGH (90-99%)'
--            WHEN SANCTIONS_MATCH_ACCURACY_PERCENT >= 80 THEN 'MEDIUM (80-89%)'
--            WHEN SANCTIONS_MATCH_ACCURACY_PERCENT >= 70 THEN 'LOW (70-79%)'
--            ELSE 'NO_MATCH'
--        END AS ACCURACY_BAND,
--        COUNT(*) AS CUSTOMER_COUNT,
--        AVG(SANCTIONS_MATCH_ACCURACY_PERCENT) AS AVG_ACCURACY
--    FROM CRMA_AGG_DT_CUSTOMER 
--    WHERE SANCTIONS_MATCH_TYPE != 'NO_MATCH'
--    GROUP BY SANCTIONS_MATCH_TYPE, ACCURACY_BAND
--    ORDER BY AVG_ACCURACY DESC;
--
-- 13. Comprehensive compliance summary (PEP + Sanctions):
--    SELECT 
--        COUNT(*) AS TOTAL_CUSTOMERS,
--        COUNT(CASE WHEN EXPOSED_PERSON_MATCH_TYPE = 'EXACT_MATCH' THEN 1 END) AS EXACT_PEP_MATCHES,
--        COUNT(CASE WHEN EXPOSED_PERSON_MATCH_TYPE = 'FUZZY_MATCH' THEN 1 END) AS FUZZY_PEP_MATCHES,
--        COUNT(CASE WHEN SANCTIONS_MATCH_TYPE = 'EXACT_MATCH' THEN 1 END) AS EXACT_SANCTIONS_MATCHES,
--        COUNT(CASE WHEN SANCTIONS_MATCH_TYPE = 'FUZZY_MATCH' THEN 1 END) AS FUZZY_SANCTIONS_MATCHES,
--        COUNT(CASE WHEN REQUIRES_EXPOSED_PERSON_REVIEW = TRUE THEN 1 END) AS REQUIRES_PEP_REVIEW,
--        COUNT(CASE WHEN REQUIRES_SANCTIONS_REVIEW = TRUE THEN 1 END) AS REQUIRES_SANCTIONS_REVIEW,
--        COUNT(CASE WHEN HIGH_RISK_CUSTOMER = TRUE THEN 1 END) AS HIGH_RISK_COUNT
--    FROM CRMA_AGG_DT_CUSTOMER;
--
-- MONITORING:
-- - Monitor dynamic table refresh: SHOW DYNAMIC TABLES IN SCHEMA CRMA_AGG_001;
-- - Check refresh history: SELECT * FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY());
-- - Validate data quality: Compare record counts between base and dynamic tables
--
-- PERFORMANCE OPTIMIZATION:
-- - Dynamic tables automatically maintain incremental refresh
-- - Consider clustering on CUSTOMER_ID for large datasets
-- - Monitor warehouse usage during refresh periods
--
-- RELATED SCHEMAS:
-- - CRM_RAW_001: Source customer and address master data
-- - PAY_RAW_001: Payment transactions (join on CUSTOMER_ID)
-- - EQT_RAW_001: Equity trades (join on CUSTOMER_ID)
-- ============================================================
