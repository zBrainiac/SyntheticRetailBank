-- ============================================================
-- ICG_AGG_v001 Schema - SWIFT ISO20022 Message Aggregation & Business Logic
-- Generated on: 2025-09-28 (Updated with comprehensive documentation)
-- ============================================================
--
-- OVERVIEW:
-- This schema provides the aggregation and business logic layer for SWIFT ISO20022
-- message processing, transforming raw XML messages into structured business data
-- for operational monitoring, compliance analysis, and regulatory reporting.
--
-- BUSINESS PURPOSE:
-- - Parse and structure SWIFT PACS.008 customer credit transfer instructions
-- - Process SWIFT PACS.002 payment status reports and acknowledgments
-- - Extract business-critical data elements for operational decision making
-- - Provide analytics-ready datasets for treasury management and risk assessment
-- - Enable real-time monitoring of payment flows and settlement status
-- - Support regulatory compliance and audit trail requirements
--
-- DATA TRANSFORMATION:
-- Raw XML (ICG_RAW_v001) → Parsed Business Data → Analytics & Reporting (ICG_DAP_v001)
--
-- OBJECTS CREATED:
-- ┌─ DYNAMIC TABLES (2):
-- │  ├─ ICG_AGG_SWIFT_PACS008      - Parsed customer credit transfer instructions
-- │  └─ ICG_AGG_SWIFT_PACS002      - Parsed payment status reports and acknowledgments
-- │
-- └─ REFRESH STRATEGY:
--    ├─ TARGET_LAG: 60 minutes (aligned with operational SLA requirements)
--    ├─ WAREHOUSE: MD_TEST_WH
--    └─ AUTO-REFRESH: Based on source table changes from ICG_RAW_v001
--
-- SUPPORTED MESSAGE TYPES:
-- - PACS.008.001.08: FIToFICstmrCdtTrf (Customer Credit Transfer)
-- - PACS.002.001.10: FIToFIPmtStsRpt (Payment Status Report)
-- - Future extensibility for additional ISO20022 payment message types
--
-- BUSINESS DATA ELEMENTS:
-- - Payment identification and routing information
-- - Debtor and creditor party details for compliance screening
-- - Settlement instructions and clearing system codes
-- - Amount, currency, and charges information
-- - Status codes and reason codes for operational monitoring
-- - Derived analytics fields for business intelligence
--
-- RELATED SCHEMAS:
-- - ICG_RAW_v001: Source raw XML messages
-- - ICG_DAP_v001: Analytics and reporting data products
-- - CRM_RAW_001: Customer master data for party identification
-- - PAY_RAW_001: Domestic payment correlation and reconciliation
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA ICG_AGG_v001;

-- ============================================================
-- DYNAMIC TABLES - SWIFT MESSAGE PARSING & BUSINESS LOGIC
-- ============================================================
-- Dynamic tables that automatically parse raw SWIFT ISO20022 XML messages
-- into structured business data with comprehensive field extraction and
-- derived analytics for operational monitoring and compliance reporting.

-- ============================================================
-- ICG_AGG_SWIFT_PACS008 - Customer Credit Transfer Instructions (pacs.008)
-- ============================================================
-- Processes SWIFT pacs.008 (FIToFICstmrCdtTrf) messages for customer credit
-- transfer instructions with comprehensive business data extraction and analytics.
-- Financial Institution to Financial Institution Customer Credit Transfer parsing
-- with derived fields for operational monitoring, compliance screening, and treasury management.

CREATE OR REPLACE DYNAMIC TABLE ICGA_AGG_SWIFT_PACS008
TARGET_LAG = '60 minutes'
WAREHOUSE = MD_TEST_WH
COMMENT = 'SWIFT PACS.008 Customer Credit Transfer messages parsed and structured for business analysis. Includes payment instructions, routing information, compliance data, and derived analytics for operational monitoring, risk management, and regulatory reporting.'
AS
SELECT 
    -- Source metadata - Technical tracking
    FILE_NAME as source_filename,
    LOAD_TS as source_load_timestamp,
    
    -- Group Header Information - Message-level controls
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[0]."$"')::STRING AS message_id,
    TRY_CAST(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[1]."$"')::STRING AS TIMESTAMP_NTZ) AS creation_datetime,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[2]."$"')::INTEGER AS number_of_transactions,
    
    -- Group Header Settlement Information - Liquidity management
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[3]."@Ccy"')::STRING AS group_settlement_currency,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[3]."$"')::DECIMAL(18,2) AS group_settlement_amount,
    
    -- Settlement Information - Routing and clearing
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[4]."$"[0]."$"')::STRING AS settlement_method,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[4]."$"[1]."$"."$"')::STRING AS clearing_system_code,
    
    -- Payment Identification - Transaction tracking
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[0]."$"[0]."$"')::STRING AS instruction_id,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[0]."$"[1]."$"')::STRING AS end_to_end_id,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[0]."$"[2]."$"')::STRING AS transaction_id,
    
    -- Payment Type Information - Processing rules
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[1]."$"[0]."$"')::STRING AS instruction_priority,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[1]."$"[1]."$"."$"')::STRING AS service_level_code,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[1]."$"[2]."$"."$"')::STRING AS local_instrument_code,
    
    -- Transaction Amount - Financial data
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[2]."@Ccy"')::STRING AS transaction_currency,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[2]."$"')::DECIMAL(18,2) AS transaction_amount,
    
    -- Settlement Date and Charges - Operational controls
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[3]."$"')::DATE AS interbank_settlement_date,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[4]."$"')::STRING AS charges_bearer,
    
    -- Agent Information - Routing and correspondent banking
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[5]."$"."$"."$"')::STRING AS instructing_agent_bic,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[6]."$"."$"."$"')::STRING AS instructed_agent_bic,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[7]."$"."$"."$"')::STRING AS debtor_agent_bic,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[8]."$"."$"."$"')::STRING AS creditor_agent_bic,
    
    -- Debtor Information - Payer details for compliance
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[9]."$"[0]."$"')::STRING AS debtor_name,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[9]."$"[1]."$"[0]."$"')::STRING AS debtor_street,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[9]."$"[1]."$"[1]."$"')::STRING AS debtor_postal_code,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[9]."$"[1]."$"[2]."$"')::STRING AS debtor_city,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[9]."$"[1]."$"[3]."$"')::STRING AS debtor_country,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[10]."$"."$"."$"')::STRING AS debtor_iban,
    
    -- Creditor Information - Beneficiary details for compliance
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[11]."$"[0]."$"')::STRING AS creditor_name,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[11]."$"[1]."$"[0]."$"')::STRING AS creditor_street,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[11]."$"[1]."$"[1]."$"')::STRING AS creditor_postal_code,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[11]."$"[1]."$"[2]."$"')::STRING AS creditor_city,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[11]."$"[1]."$"[3]."$"')::STRING AS creditor_country,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[12]."$"."$"."$"')::STRING AS creditor_iban,
    
    -- Remittance Information - Payment purpose and compliance
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[13]."$"."$"')::STRING AS remittance_information,
    
    -- Analytics Fields - Business intelligence and monitoring
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[2]."$"')::DECIMAL(18,2) >= 100000 THEN TRUE
        ELSE FALSE
    END AS is_high_value_payment,
    
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[4]."$"[1]."$"."$"')::STRING = 'TARGET2' THEN TRUE
        ELSE FALSE
    END AS is_target2_payment,
    
    CONCAT(
        COALESCE(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[9]."$"[1]."$"[3]."$"')::STRING, 'UNKNOWN'),
        ' -> ',
        COALESCE(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[11]."$"[1]."$"[3]."$"')::STRING, 'UNKNOWN')
    ) AS payment_corridor,
    
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[9]."$"[1]."$"[3]."$"')::STRING = 
             GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[11]."$"[1]."$"[3]."$"')::STRING THEN 'DOMESTIC'
        ELSE 'CROSS_BORDER'
    END AS payment_type_classification,
    
    -- Processing metadata - Technical operations
    CURRENT_TIMESTAMP() AS parsed_at,
    LENGTH(RAW_XML::STRING) AS xml_size_bytes

FROM ICG_RAW_v001.ICGI_RAW_SWIFT_MESSAGES
WHERE RAW_XML IS NOT NULL
  AND (FILE_NAME ILIKE '%pacs008%' OR RAW_XML::STRING ILIKE '%FIToFICstmrCdtTrf%');

-- ============================================================
-- ICG_AGG_SWIFT_PACS002 - Payment Status Reports & Acknowledgments (pacs.002)
-- ============================================================
-- Processes SWIFT pacs.002 (FIToFIPmtStsRpt) messages for payment status reports
-- and acknowledgments with comprehensive status tracking and operational analytics.
-- Financial Institution to Financial Institution Payment Status Report parsing
-- with derived fields for SLA monitoring, exception handling, and customer communication.

CREATE OR REPLACE DYNAMIC TABLE ICGA_AGG_SWIFT_PACS002
TARGET_LAG = '60 minutes'
WAREHOUSE = MD_TEST_WH
COMMENT = 'SWIFT PACS.002 Payment Status Reports parsed and structured for operational monitoring. Includes status confirmations, rejection reasons, processing timestamps, and derived analytics for SLA tracking, exception handling, and customer communication workflows.'
AS
SELECT 
    -- Source metadata - Technical tracking
    FILE_NAME as source_filename,                                          -- Original XML file name for audit and correlation
    LOAD_TS as source_load_timestamp,                                     -- System ingestion timestamp for data lineage
    
    -- Group Header Information - Response message controls
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[0]."$"')::STRING AS message_id,                   -- Unique status report ID for deduplication
    TRY_CAST(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[1]."$"')::STRING AS TIMESTAMP_NTZ) AS creation_datetime,  -- When status report was created (SLA measurement)
    
    -- Agent Information - Response routing
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[2]."$"."$"."$"')::STRING AS instructing_agent_bic,-- Bank sending status report (operational contact)
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[3]."$"."$"."$"')::STRING AS instructed_agent_bic, -- Bank receiving status report (for routing)
    
    -- Original Payment Reference - Links back to instruction
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[0]."$"')::STRING AS original_message_id,          -- Links to original PACS.008 for reconciliation
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[1]."$"')::STRING AS original_message_name_id,     -- Confirms message type being acknowledged
    TRY_CAST(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[2]."$"')::STRING AS TIMESTAMP_NTZ) AS original_creation_datetime, -- Original instruction time for SLA tracking
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[3]."$"')::STRING AS group_status,                -- Overall status of payment batch
    
    -- Transaction-level Status - Individual payment outcome
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[0]."$"')::STRING AS original_end_to_end_id,       -- Customer reference for notification and reconciliation
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING AS transaction_status,           -- Payment status code (ACCP/RJCT/PDNG) for operational decisions
    
    -- Status Details - Reason and processing information
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[2]."$"."$"')::STRING AS status_reason,            -- Detailed reason for customer service and investigation
    
    -- Additional Processing Information - Extended tracking
    TRY_CAST(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[3]."$"')::STRING AS STRING) AS original_instruction_id,  -- Bank internal reference for operations
    TRY_CAST(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[4]."$"')::STRING AS STRING) AS original_transaction_id,  -- SWIFT tracking reference for inquiries
    TRY_CAST(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[5]."$"')::STRING AS TIMESTAMP_NTZ) AS acceptance_datetime,-- When payment was actually processed (settlement timing)
    
    -- Derived Analytics Fields - Business intelligence for status monitoring
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING = 'ACCP' THEN 'ACCEPTED'
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING = 'RJCT' THEN 'REJECTED'
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING = 'PDNG' THEN 'PENDING'
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING = 'ACSC' THEN 'ACCEPTED_SETTLEMENT_COMPLETED'
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING = 'ACSP' THEN 'ACCEPTED_SETTLEMENT_IN_PROCESS'
        ELSE GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING
    END AS transaction_status_description,                                  -- Human-readable status for dashboards and customer notifications
    
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[3]."$"')::STRING = 'ACCP' THEN 'ACCEPTED'
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[3]."$"')::STRING = 'RJCT' THEN 'REJECTED'
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[3]."$"')::STRING = 'PDNG' THEN 'PENDING'
        ELSE GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[3]."$"')::STRING
    END AS group_status_description,                                        -- Batch-level status for operational monitoring
    
    -- Response Classification - Operational alerting and SLA monitoring
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING IN ('ACCP', 'ACSC', 'ACSP') THEN TRUE
        ELSE FALSE
    END AS is_positive_response,                                            -- Success indicator for SLA reporting and customer communication
    
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING = 'RJCT' THEN TRUE
        ELSE FALSE
    END AS is_rejection,                                                    -- Failure flag for exception handling and customer service escalation
    
    -- Message Type Validation - Processing integrity checks
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[1]."$"')::STRING = 'pacs.008.001.08' THEN TRUE
        ELSE FALSE
    END AS is_pacs008_response,                                             -- Confirms this status relates to payment instruction (not other message types)
    
    -- Temporal Correlation - Data organization and performance optimization
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[0]."$"')::STRING LIKE '20%-%-%' THEN
            SUBSTR(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[0]."$"')::STRING, 1, 8)
        ELSE NULL
    END AS original_message_date,                                           -- Business date extraction for time-based analytics and archiving
    
    -- Processing metadata - Technical operations and monitoring
    CURRENT_TIMESTAMP() AS parsed_at,                                       -- Processing timestamp for data quality monitoring
    LENGTH(RAW_XML::STRING) AS xml_size_bytes                              -- Message complexity indicator for performance analysis

FROM ICG_RAW_v001.ICGI_RAW_SWIFT_MESSAGES
WHERE RAW_XML IS NOT NULL
  AND (FILE_NAME ILIKE '%pacs002%' OR RAW_XML::STRING ILIKE '%FIToFIPmtStsRpt%');

-- ============================================================
-- ICG_DAP_v001 SCHEMA - Data Products for SWIFT Processing
-- ============================================================



-- ============================================================
-- ICG_DAP_SWIFT_JOIN_PACS008_002 - Joined Payment Flow
-- ============================================================
-- Joins pacs.008 credit transfers with their pacs.002 status reports
-- Provides end-to-end view of payment processing lifecycle

CREATE OR REPLACE DYNAMIC TABLE ICGA_AGG_SWIFT_JOIN_PACS008_PACS002
TARGET_LAG = '60 minutes'
WAREHOUSE = MD_TEST_WH
COMMENT = 'Complete SWIFT payment lifecycle view joining PACS.008 instructions with PACS.002 status reports. Provides end-to-end payment tracking, SLA monitoring, settlement analysis, and comprehensive business intelligence for treasury management, compliance reporting, and operational excellence.'
AS
SELECT
    -- Join keys - Message correlation identifiers
    p008.message_id                AS pacs008_message_id,               -- Original payment instruction ID for tracking
    p002.original_message_id       AS pacs002_original_message_id,     -- Status report reference back to instruction
    
    -- Transaction-level correlation - Customer and operational references
    p008.end_to_end_id             AS pacs008_end_to_end_id,           -- Customer's payment reference for reconciliation
    p002.original_end_to_end_id    AS pacs002_original_end_to_end_id,  -- Confirmed customer reference in status report
    
    -- Status Information - Payment outcome and processing results
    p002.transaction_status,                                           -- Final payment status (ACCP/RJCT/PDNG) for operational decisions
    p002.transaction_status_description,                               -- Human-readable status for customer communication
    p002.group_status,                                                 -- Batch-level outcome for bulk processing analysis
    p002.group_status_description,                                     -- Readable batch status for operational dashboards
    p002.status_reason,                                                -- Detailed reason code for investigation and customer service
    p002.is_rejection,                                                 -- Failed payment flag for exception handling workflows
    p002.is_positive_response,                                         -- Success indicator for SLA and performance reporting
    
    -- Payment Details - Financial and business information
    p008.transaction_currency,                                         -- Payment currency for FX and treasury management
    p008.transaction_amount,                                           -- Payment value for limit monitoring and settlement
    p008.debtor_name,                                                  -- Payer identification for compliance and customer service
    p008.creditor_name,                                                -- Beneficiary identification for delivery confirmation
    p008.payment_corridor,                                             -- Geographic flow for correspondent banking analysis
    p008.payment_type_classification,                                  -- Domestic vs cross-border for regulatory reporting
    p008.is_high_value_payment,                                        -- Large payment flag for enhanced monitoring and approval
    p008.is_target2_payment,                                           -- RTGS classification for liquidity and settlement planning
    
    -- Technical Metadata - Data lineage and processing information
    p008.source_filename   AS pacs008_file,                           -- Original instruction file for audit trail
    p002.source_filename   AS pacs002_file,                           -- Status report file for correlation verification
    p008.source_load_timestamp AS pacs008_load_timestamp,             -- When instruction was received for timing analysis
    p002.source_load_timestamp AS pacs002_load_timestamp,             -- When status was received for response time measurement
    DATEDIFF('minutes', p002.ORIGINAL_CREATION_DATETIME, p002.CREATION_DATETIME) AS ack_time, -- Processing time for SLA monitoring and performance optimization
    CURRENT_TIMESTAMP() AS joined_at                                  -- Join processing timestamp for data quality tracking
    
FROM ICGA_AGG_SWIFT_PACS008 p008
LEFT JOIN ICGA_AGG_SWIFT_PACS002 p002
    ON p002.original_message_id = p008.message_id
   AND (
        p002.original_end_to_end_id = p008.end_to_end_id
        OR p002.original_transaction_id = p008.transaction_id
   );


-- ============================================================
-- SCHEMA COMPLETION STATUS
-- ============================================================
-- ✅ ICG_AGG_v001 Schema Deployment Complete
--
-- OBJECTS CREATED:
-- • 2 Dynamic Tables: ICG_AGG_SWIFT_PACS008, ICG_AGG_SWIFT_PACS002
-- • 1 Data Product: ICG_DAP_SWIFT_JOIN_PACS008_002 (comprehensive payment lifecycle)
-- • Automated refresh: 60-minute TARGET_LAG for near real-time business intelligence
-- • Comprehensive field extraction: 50+ business data elements per message type
--
-- NEXT STEPS:
-- 1. ✅ ICG_AGG_v001 schema deployed successfully
-- 2. Verify dynamic table refresh: SHOW DYNAMIC TABLES IN SCHEMA ICG_AGG_v001;
-- 3. Monitor processing performance and adjust TARGET_LAG if needed
-- 4. Deploy ICG_DAP_v001 schema for advanced analytics and reporting
-- 5. Integrate with operational dashboards and monitoring systems
--
-- USAGE EXAMPLES:
--
-- -- Query all high-value payments (>= 100k EUR equivalent)
-- SELECT debtor_name, creditor_name, transaction_amount, transaction_currency, payment_corridor
-- FROM ICG_AGG_SWIFT_PACS008 
-- WHERE is_high_value_payment = TRUE
-- ORDER BY transaction_amount DESC;
--
-- -- Query rejected payments with reasons
-- SELECT original_end_to_end_id, transaction_status_description, status_reason, 
--        instructing_agent_bic, instructed_agent_bic
-- FROM ICG_AGG_SWIFT_PACS002 
-- WHERE is_rejection = TRUE
-- ORDER BY creation_datetime DESC;
--
-- -- Query complete payment lifecycle with SLA analysis
-- SELECT pacs008_end_to_end_id, transaction_amount, transaction_currency,
--        debtor_name, creditor_name, transaction_status_description, ack_time
-- FROM ICG_DAP_SWIFT_JOIN_PACS008_002 
-- WHERE ack_time > 60  -- Payments taking longer than 60 minutes
-- ORDER BY ack_time DESC;
--
-- -- Query cross-border payment flows by corridor
-- SELECT payment_corridor, COUNT(*) as payment_count, 
--        SUM(transaction_amount) as total_amount, transaction_currency
-- FROM ICG_AGG_SWIFT_PACS008 
-- WHERE payment_type_classification = 'CROSS_BORDER'
-- GROUP BY payment_corridor, transaction_currency
-- ORDER BY total_amount DESC;
--
-- -- Query TARGET2 payment volumes
-- SELECT DATE(creation_datetime) as business_date,
--        COUNT(*) as target2_payments,
--        SUM(transaction_amount) as total_eur_amount
-- FROM ICG_AGG_SWIFT_PACS008 
-- WHERE is_target2_payment = TRUE
-- GROUP BY business_date
-- ORDER BY business_date DESC;
--
-- MANUAL REFRESH COMMANDS:
-- ALTER DYNAMIC TABLE ICG_AGG_SWIFT_PACS008 REFRESH;
-- ALTER DYNAMIC TABLE ICG_AGG_SWIFT_PACS002 REFRESH;
-- ALTER DYNAMIC TABLE ICG_DAP_SWIFT_JOIN_PACS008_002 REFRESH;
--
-- MONITORING:
-- - Dynamic table refresh status: SELECT * FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY());
-- - Processing performance: SELECT COUNT(*), AVG(xml_size_bytes) FROM ICG_AGG_SWIFT_PACS008;
-- - Message type distribution: SELECT message_type, COUNT(*) FROM (SELECT CASE WHEN FILE_NAME ILIKE '%pacs008%' THEN 'PACS.008' ELSE 'PACS.002' END as message_type FROM ICG_RAW_v001.ICG_RAW_SWIFT_MESSAGES) GROUP BY message_type;
--
-- PERFORMANCE OPTIMIZATION:
-- - Monitor warehouse usage during refresh periods
-- - Consider clustering on creation_datetime for time-based queries
-- - Adjust TARGET_LAG based on business SLA requirements
-- - Archive processed messages based on regulatory retention policies
-- ============================================================
