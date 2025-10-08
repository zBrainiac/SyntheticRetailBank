-- ============================================================
-- CRM_RAW_001 Schema - Customer Relationship Management & Exposed Person Compliance
-- Generated on: 2025-09-27 (Updated - ACCI objects moved to 15_ACCI.sql)
-- ============================================================
--
-- OVERVIEW:
-- This schema contains customer master data and compliance data for the synthetic
-- EMEA retail bank data generator. It supports 12 EMEA countries with localized
-- customer data, SCD Type 2 address history, and Exposed Person compliance tracking.
--
-- SUPPORTED COUNTRIES:
-- Norway, Netherlands, Sweden, Germany, France, Italy, United Kingdom, 
-- Denmark, Belgium, Austria, Switzerland
--
-- DATA ARCHITECTURE:
-- - Customer data separated from address data for normalization
-- - Address history tracked with SCD Type 2 via dynamic tables
-- - Exposed Person data for regulatory compliance and risk management
-- - Automated loading via streams and tasks (1-hour schedule)
--
-- OBJECTS CREATED:
-- ┌─ STAGES (3):
-- │  ├─ CRMI_CUSTOMERS      - Customer master data files
-- │  ├─ CRMI_ADDRESSES      - Customer address files (SCD Type 2)
-- │  └─ CRMI_EXPOSED_PERSON           - Politically Exposed Persons files
-- │
-- ┌─ FILE FORMATS (3):
-- │  ├─ CRMI_FF_CUSTOMER_CSV - Customer CSV format with ISO timestamps
-- │  ├─ CRMI_FF_ADDRESS_CSV  - Address CSV format with UTC timestamps
-- │  └─ CRMI_FF_EXPOSED_PERSON_CSV     - Exposed Person CSV format with compliance fields
-- │
-- ┌─ TABLES (3):
-- │  ├─ CRMI_PARTY          - Customer master data (normalized)
-- │  ├─ CRMI_ADDRESSES      - Address base table (append-only)
-- │  └─ CRMI_EXPOSED_PERSON           - Exposed Person compliance data
-- │
-- ┌─ STREAMS (3):
-- │  ├─ CRMI_STREAM_CUSTOMER_FILES - Detects new customer files
-- │  ├─ CRMI_STREAM_ADDRESS_FILES  - Detects new address files
-- │  └─ CRMI_STREAM_EXPOSED_PERSON_FILES     - Detects new Exposed Person files
-- │
-- └─ TASKS (3):
--    ├─ CRMI_TASK_LOAD_CUSTOMERS  - Automated customer loading
--    ├─ CRMI_TASK_LOAD_ADDRESSES  - Automated address loading
--    └─ CRMI_TASK_LOAD_EXPOSED_PERSON       - Automated Exposed Person loading
--
-- RELATED SCHEMAS:
-- - CRM_AGG_001 - Customer address aggregation and SCD Type 2 views
-- - PAY_RAW_001 - Payment transaction data
-- - EQT_RAW_001 - Equity trading data
-- - REF_RAW_001 - Reference data (FX rates)
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_RAW_001;

-- ============================================================
-- INTERNAL STAGES - File Landing Areas
-- ============================================================
-- Internal stages for CSV file ingestion with directory listing enabled
-- for automated file detection via streams. All stages support PUT/GET
-- operations for manual file uploads and downloads.

-- Customer master data stage
CREATE OR REPLACE STAGE CRMI_CUSTOMERS
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Internal stage for customer master data CSV files. Expected pattern: *customers*.csv with fields: customer_id, first_name, family_name, date_of_birth, onboarding_date, reporting_currency, has_anomaly';

-- Customer address data stage (SCD Type 2)
CREATE OR REPLACE STAGE CRMI_ADDRESSES
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Internal stage for customer address CSV files with SCD Type 2 support. Expected pattern: *customer_addresses*.csv with insert_timestamp_utc for change tracking';

-- Exposed Person compliance data stage
CREATE OR REPLACE STAGE CRMI_EXPOSED_PERSON
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Internal stage for PEP (Politically Exposed Persons) compliance CSV files. Expected pattern: *exposed_person*.csv with risk levels and reference links for regulatory compliance';

-- ============================================================
-- FILE FORMATS - CSV Parsing Configurations
-- ============================================================
-- Standardized CSV file formats for consistent data ingestion across
-- all customer-related data sources. All formats handle quoted fields,
-- trim whitespace, and use flexible column count matching.

-- Customer master data CSV format
CREATE OR REPLACE FILE FORMAT CRMI_FF_CUSTOMER_CSV
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    REPLACE_INVALID_CHARACTERS = TRUE
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF"Z"'
    COMMENT = 'CSV format for customer master data with EMEA localization support, country-based reporting currencies, and anomaly flags';

-- Customer address CSV format (SCD Type 2)
CREATE OR REPLACE FILE FORMAT CRMI_FF_ADDRESS_CSV
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    REPLACE_INVALID_CHARACTERS = TRUE
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    COMMENT = 'CSV format for customer address data with SCD Type 2 support via INSERT_TIMESTAMP_UTC field';

-- Exposed Person compliance data CSV format
CREATE OR REPLACE FILE FORMAT CRMI_FF_EXPOSED_PERSON_CSV
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    REPLACE_INVALID_CHARACTERS = TRUE
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    COMMENT = 'CSV format for PEP (Politically Exposed Persons) compliance data with risk levels and reference documentation';

-- ============================================================
-- MASTER DATA TABLES - Customer Information & Compliance
-- ============================================================

-- ============================================================
-- CRMI_PARTY - Customer Master Data (Normalized)
-- ============================================================
-- Core customer information normalized and separated from address data.
-- Supports 12 EMEA countries with localized data generation and anomaly
-- detection flags for compliance and risk management scenarios.

CREATE OR REPLACE TABLE CRMI_PARTY (
    CUSTOMER_ID VARCHAR(20) NOT NULL WITH TAG (SENSITIVITY_LEVEL='top_secret') COMMENT 'Unique customer identifier (CUST_XXXXX format)',
    FIRST_NAME VARCHAR(100) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Customer first name (localized to country)',
    FAMILY_NAME VARCHAR(100) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Customer family/last name (localized to country)',
    DATE_OF_BIRTH DATE NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Date of birth (YYYY-MM-DD format)',
    ONBOARDING_DATE DATE NOT NULL COMMENT 'Customer onboarding date (YYYY-MM-DD)',
    REPORTING_CURRENCY VARCHAR(3) NOT NULL COMMENT 'Customer reporting currency based on country (EUR, GBP, USD, CHF, NOK, SEK, DKK, PLN)',
    HAS_ANOMALY BOOLEAN NOT NULL DEFAULT FALSE WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Flag indicating customer has anomalous transaction patterns for compliance testing',

    -- Constraints
    CONSTRAINT PK_CRMI_PARTY PRIMARY KEY (CUSTOMER_ID)
    -- CHECK constraints not supported in Snowflake - replaced with comments for documentation
    -- CHK_DATE_OF_BIRTH: DATE_OF_BIRTH should be >= 18 years ago (adult customers only)
    -- CHK_ONBOARDING_DATE: ONBOARDING_DATE should be <= current date
    -- CHK_REPORTING_CURRENCY: REPORTING_CURRENCY should be in ('EUR', 'GBP', 'USD', 'CHF', 'NOK', 'SEK', 'DKK', 'PLN')
)
COMMENT = 'Customer master data table with normalized structure. Address data stored separately in CRMI_ADDRESSES for SCD Type 2 tracking. Supports EMEA retail banking with localized customer information and country-based reporting currencies.';
-- ============================================================
-- CRMI_ADDRESSES - Customer Address Base Table (SCD Type 2)
-- ============================================================
-- Append-only address table supporting SCD Type 2 via INSERT_TIMESTAMP_UTC.
-- Dynamic tables in CRMA_AGG_001 schema provide current and historical views.
-- Each address change creates a new record with timestamp for audit trail.

CREATE OR REPLACE TABLE CRMI_ADDRESSES (
    CUSTOMER_ID VARCHAR(20) NOT NULL COMMENT 'Reference to customer (foreign key to CRMI_PARTY)',
    STREET_ADDRESS VARCHAR(200) NOT NULL WITH TAG (SENSITIVITY_LEVEL='top_secret') COMMENT 'Street address (localized format)',
    CITY VARCHAR(100) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'City name (localized to country)',
    STATE VARCHAR(100) COMMENT 'State/Region (where applicable for the country)',
    ZIPCODE VARCHAR(20) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Postal code (country-specific format)',
    COUNTRY VARCHAR(50) NOT NULL COMMENT 'Customer''s country (12 EMEA countries supported)',
    INSERT_TIMESTAMP_UTC TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when this address record was inserted',
    
    CONSTRAINT FK_CRMI_ADDRESSES_CUSTOMER FOREIGN KEY (CUSTOMER_ID) REFERENCES CRMI_PARTY (CUSTOMER_ID)
)
COMMENT = 'Customer address base table with append-only structure. Each address change creates a new record with INSERT_TIMESTAMP_UTC. Dynamic tables provide current and historical views.';

-- ============================================================
-- CRMI_EXPOSED_PERSON - Politically Exposed Persons (Compliance)
-- ============================================================
-- PEP master data for regulatory compliance and risk management.
-- Tracks current and former political figures, family members, and associates
-- for automated compliance screening and regulatory reporting requirements.

CREATE OR REPLACE TABLE CRMI_EXPOSED_PERSON (
    EXPOSED_PERSON_ID VARCHAR(50) NOT NULL COMMENT 'Unique PEP identifier',
    FULL_NAME VARCHAR(200) NOT NULL WITH TAG (SENSITIVITY_LEVEL='top_secret') COMMENT 'Full name of the politically exposed person',
    FIRST_NAME VARCHAR(100) WITH TAG (SENSITIVITY_LEVEL='top_secret') COMMENT 'First name',
    LAST_NAME VARCHAR(100) NOT NULL WITH TAG (SENSITIVITY_LEVEL='top_secret') COMMENT 'Last name/family name',
    DATE_OF_BIRTH DATE WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Date of birth (YYYY-MM-DD)',
    NATIONALITY VARCHAR(50) COMMENT 'Nationality/citizenship',
    POSITION_TITLE VARCHAR(200) NOT NULL COMMENT 'Political position or title held',
    ORGANIZATION VARCHAR(200) COMMENT 'Government organization or political party',
    COUNTRY VARCHAR(50) NOT NULL COMMENT 'Country where political position is/was held',
    EXPOSED_PERSON_CATEGORY VARCHAR(50) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'PEP category: DOMESTIC, FOREIGN, INTERNATIONAL_ORG, FAMILY_MEMBER, CLOSE_ASSOCIATE',
    RISK_LEVEL VARCHAR(20) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Risk assessment level: LOW, MEDIUM, HIGH, CRITICAL',
    STATUS VARCHAR(20) NOT NULL COMMENT 'Current status: ACTIVE, INACTIVE, DECEASED',
    START_DATE DATE COMMENT 'Date when PEP status began (YYYY-MM-DD)',
    END_DATE DATE COMMENT 'Date when PEP status ended (YYYY-MM-DD), NULL if still active',
    REFERENCE_LINK VARCHAR(500) COMMENT 'URL reference to official source or documentation',
    SOURCE VARCHAR(100) COMMENT 'Data source (e.g., government website, sanctions list)',
    LAST_UPDATED DATE NOT NULL COMMENT 'Date when record was last updated (YYYY-MM-DD)',
    CREATED_DATE DATE NOT NULL COMMENT 'Date when record was created (YYYY-MM-DD)',
    
    CONSTRAINT PK_CRMI_EXPOSED_PERSON PRIMARY KEY (EXPOSED_PERSON_ID)
)
COMMENT = 'Politically Exposed Persons (PEP) master data for compliance and risk management. Tracks current and former political figures, their family members, and close associates for regulatory compliance.';

-- ============================================================
-- CHANGE DETECTION STREAMS - File Monitoring
-- ============================================================
-- Streams monitor stages for new files and trigger automated processing
-- tasks. Each stream detects specific file patterns and maintains change
-- tracking for reliable data pipeline processing.

-- Customer file detection stream
CREATE OR REPLACE STREAM CRMI_STREAM_CUSTOMER_FILES
    ON STAGE CRMI_CUSTOMERS
    COMMENT = 'Monitors CRMI_CUSTOMERS stage for new customer CSV files. Triggers CRMI_TASK_LOAD_CUSTOMERS when files matching *customers*.csv pattern are detected';

-- Address file detection stream
CREATE OR REPLACE STREAM CRMI_STREAM_ADDRESS_FILES
    ON STAGE CRMI_ADDRESSES
    COMMENT = 'Monitors CRMI_ADDRESSES stage for new address CSV files. Triggers CRMI_TASK_LOAD_ADDRESSES for SCD Type 2 processing when files matching *customer_addresses*.csv pattern are detected';

-- PEP file detection stream
CREATE OR REPLACE STREAM CRMI_STREAM_EXPOSED_PERSON_FILES
    ON STAGE CRMI_EXPOSED_PERSON
    COMMENT = 'Monitors CRMI_EXPOSED_PERSON stage for new Exposed Person compliance CSV files. Triggers CRMI_TASK_LOAD_EXPOSED_PERSON when files matching *exposed_person*.csv pattern are detected';

-- ============================================================
-- AUTOMATED PROCESSING TASKS - Data Pipeline Orchestration
-- ============================================================
-- Automated tasks triggered by stream data availability. All tasks run
-- on 1-hour schedule with stream-based triggering for efficient resource
-- usage. Error handling continues processing despite individual record failures.

-- Customer master data loading task
CREATE OR REPLACE TASK CRMI_TASK_LOAD_CUSTOMERS
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('CRMI_STREAM_CUSTOMER_FILES')
   -- COMMENT = 'Automated loading of customer master data from CSV files. Triggered by CRMI_STREAM_CUSTOMER_FILES when new files arrive'
AS
    COPY INTO CRMI_PARTY (CUSTOMER_ID, FIRST_NAME, FAMILY_NAME, DATE_OF_BIRTH, ONBOARDING_DATE, REPORTING_CURRENCY, HAS_ANOMALY)
    FROM @CRMI_CUSTOMERS
    PATTERN = '.*customers.*\.csv'
    FILE_FORMAT = CRMI_FF_CUSTOMER_CSV
    ON_ERROR = CONTINUE;

-- Customer address loading task (SCD Type 2)
CREATE OR REPLACE TASK CRMI_TASK_LOAD_ADDRESSES
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('CRMI_STREAM_ADDRESS_FILES')
 --   COMMENT = 'Automated loading of customer address data with SCD Type 2 support. Uses explicit column mapping and handles empty state values'
AS
    COPY INTO CRMI_ADDRESSES (CUSTOMER_ID, STREET_ADDRESS, CITY, STATE, ZIPCODE, COUNTRY, INSERT_TIMESTAMP_UTC)
    FROM (
        SELECT 
            $1::VARCHAR(20) AS CUSTOMER_ID,
            $2::VARCHAR(200) AS STREET_ADDRESS,
            $3::VARCHAR(100) AS CITY,
            NULLIF($4, '')::VARCHAR(100) AS STATE,  -- Handle empty state values for countries without states
            $5::VARCHAR(20) AS ZIPCODE,
            $6::VARCHAR(50) AS COUNTRY,
            $7::TIMESTAMP_NTZ AS INSERT_TIMESTAMP_UTC
        FROM @CRMI_ADDRESSES
    )
    PATTERN = '.*customer_addresses.*\.csv'
    FILE_FORMAT = CRMI_FF_ADDRESS_CSV
    ON_ERROR = CONTINUE;

-- Exposed Person compliance data loading task
CREATE OR REPLACE TASK CRMI_TASK_LOAD_EXPOSED_PERSON
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('CRMI_STREAM_EXPOSED_PERSON_FILES')
 --   COMMENT = 'Automated task to load PEP (Politically Exposed Persons) CSV files from stage'
AS
    COPY INTO CRMI_EXPOSED_PERSON (
        EXPOSED_PERSON_ID, FULL_NAME, FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, NATIONALITY,
        POSITION_TITLE, ORGANIZATION, COUNTRY, EXPOSED_PERSON_CATEGORY, RISK_LEVEL, STATUS,
        START_DATE, END_DATE, REFERENCE_LINK, SOURCE, LAST_UPDATED, CREATED_DATE
    )
    FROM @CRMI_EXPOSED_PERSON
    PATTERN = '.*pep.*\.csv'
    FILE_FORMAT = CRMI_FF_EXPOSED_PERSON_CSV
    ON_ERROR = CONTINUE;

-- ============================================================
-- TASK ACTIVATION - Enable Automated Processing
-- ============================================================
-- Tasks must be explicitly resumed to begin processing. This allows for
-- controlled deployment and testing before enabling automated data flows.

-- Enable customer data loading
ALTER TASK CRMI_TASK_LOAD_CUSTOMERS RESUME;

-- Enable address data loading (SCD Type 2)
ALTER TASK CRMI_TASK_LOAD_ADDRESSES RESUME;

-- Enable Exposed Person compliance data loading
ALTER TASK CRMI_TASK_LOAD_EXPOSED_PERSON RESUME;

-- ============================================================
-- SCHEMA COMPLETION STATUS
-- ============================================================
-- ✅ CRM_RAW_001 Schema Deployment Complete
--
-- OBJECTS CREATED:
-- • 3 Stages: CRMI_CUSTOMERS, CRMI_ADDRESSES, CRMI_EXPOSED_PERSON
-- • 3 File Formats: CRMI_FF_CUSTOMER_CSV, CRMI_FF_ADDRESS_CSV, CRMI_FF_EXPOSED_PERSON_CSV
-- • 3 Tables: CRMI_PARTY, CRMI_ADDRESSES, CRMI_EXPOSED_PERSON
-- • 3 Streams: CRMI_STREAM_CUSTOMER_FILES, CRMI_STREAM_ADDRESS_FILES, CRMI_STREAM_EXPOSED_PERSON_FILES
-- • 3 Tasks: CRMI_TASK_LOAD_CUSTOMERS, CRMI_TASK_LOAD_ADDRESSES, CRMI_TASK_LOAD_EXPOSED_PERSON (ALL ACTIVE)
--
-- NEXT STEPS:
-- 1. ✅ CRM_RAW_001 schema deployed successfully
-- 2. Upload customer, address, and Exposed Person CSV files to respective stages
-- 3. Monitor task execution: SHOW TASKS IN SCHEMA CRM_RAW_001;
-- 4. Verify data loading: SELECT COUNT(*) FROM CRMI_PARTY, CRMI_ADDRESSES, CRMI_EXPOSED_PERSON;
-- 5. Check for processing errors in task history
-- 6. Deploy CRM_AGG_001 schema for SCD Type 2 address views
--
-- USAGE EXAMPLES:
-- -- Upload files
-- PUT file://customers.csv @CRMI_CUSTOMERS;
-- PUT file://customer_addresses*.csv @CRMI_ADDRESSES;
-- PUT file://pep_data.csv @CRMI_EXPOSED_PERSON;
-- 
-- -- Check customer distribution by country and currency
-- SELECT c.COUNTRY, p.REPORTING_CURRENCY, COUNT(*) as CUSTOMER_COUNT
-- FROM CRMI_PARTY p
-- JOIN CRMI_ADDRESSES c ON p.CUSTOMER_ID = c.CUSTOMER_ID
-- GROUP BY c.COUNTRY, p.REPORTING_CURRENCY
-- ORDER BY c.COUNTRY, p.REPORTING_CURRENCY;
--
-- -- Customer reporting currency analysis
-- SELECT REPORTING_CURRENCY, COUNT(*) as CUSTOMER_COUNT,
--        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as PERCENTAGE
-- FROM CRMI_PARTY
-- GROUP BY REPORTING_CURRENCY
-- ORDER BY CUSTOMER_COUNT DESC;
--
-- -- Exposed Person risk analysis
-- SELECT EXPOSED_PERSON_CATEGORY, RISK_LEVEL, COUNT(*) as PEP_COUNT
-- FROM CRMI_EXPOSED_PERSON 
-- GROUP BY EXPOSED_PERSON_CATEGORY, RISK_LEVEL
-- ORDER BY EXPOSED_PERSON_CATEGORY, RISK_LEVEL;
-- ============================================================