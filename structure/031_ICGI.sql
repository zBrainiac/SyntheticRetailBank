-- ============================================================
-- PAY_RAW_001 Schema - SWIFT ISO20022 Message Processing (Raw Data Layer)
-- Generated on: 2025-09-28 (Updated with comprehensive documentation)
-- ============================================================
--
-- OVERVIEW:
-- This schema provides the foundational raw data layer for SWIFT ISO20022 message
-- processing within the Interbank Credit Gateway (ICG) clearing and settlement
-- operations. It handles the ingestion, parsing, and initial storage of XML-based
-- SWIFT messages for downstream processing and business intelligence.
--
-- BUSINESS PURPOSE:
-- - Real-time ingestion of SWIFT ISO20022 XML messages (PACS.008, PACS.002)
-- - Automated file processing with stream-based triggering for operational efficiency
-- - Raw message preservation for compliance, audit trails, and regulatory reporting
-- - Foundation for downstream payment processing, status tracking, and analytics
-- - Support for high-volume interbank clearing and settlement operations
--
-- SUPPORTED MESSAGE TYPES:
-- - PACS.008: FIToFICstmrCdtTrf (Customer Credit Transfer Instructions)
-- - PACS.002: FIToFIPmtStsRpt (Payment Status Reports and Acknowledgments)
-- - Future extensibility for additional ISO20022 message types (PACS.004, PACS.007, etc.)
--
-- OBJECTS CREATED:
-- ┌─ STAGES (1):
-- │  └─ ICGI_RAW_SWIFT_INBOUND     - XML message landing area with directory listing
-- │
-- ├─ FILE FORMATS (1):
-- │  └─ ICGI_XML_FILE_FORMAT       - ISO20022 XML parsing configuration
-- │
-- ├─ TABLES (1):
-- │  └─ ICGI_RAW_SWIFT_MESSAGES    - Raw XML message storage with metadata
-- │
-- ├─ STREAMS (1):
-- │  └─ ICGI_STREAM_SWIFT_FILES    - File arrival detection for automation
-- │
-- └─ TASKS (1):
--    └─ ICGI_TASK_LOAD_SWIFT_MESSAGES - Automated XML ingestion (60-minute schedule)
--
-- DATA ARCHITECTURE:
-- Raw XML files → ICGI_RAW_SWIFT_INBOUND → Stream Detection → Automated Task → Raw Table → Downstream Processing
--
-- PROCESSING PATTERNS:
-- - SWIFT XML: *pacs008*.xml, *pacs002*.xml for message type identification
-- - Automatic XML parsing with PARSE_XML() for VARIANT storage
-- - Metadata capture (filename, load timestamp) for data lineage and audit
-- - Error handling with ON_ERROR = CONTINUE for resilient processing
-- - Stream-based triggering for near real-time processing efficiency
--
-- SUPPORTED COUNTRIES & CURRENCIES:
-- - All EMEA countries with SWIFT connectivity
-- - Multi-currency support (EUR, GBP, USD, CHF, NOK, SEK, DKK)
-- - TARGET2 and correspondent banking network compatibility
--
-- RELATED SCHEMAS:
-- - PAY_AGG_001: Message parsing and business logic transformation
-- - REP_AGG_001: Analytics and reporting data products
-- - CRM_RAW_001: Customer data for payment participant identification
-- - PAY_RAW_001: Domestic payment correlation and reconciliation
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;

-- ============================================================
-- PAY_RAW_001 SCHEMA - Raw SWIFT Messages
-- ============================================================

USE SCHEMA PAY_RAW_001;

-- ============================================================
-- FILE FORMATS - XML Processing Configuration
-- ============================================================
-- Specialized file format for SWIFT ISO20022 XML message parsing with
-- optimized settings for financial message processing and compliance requirements.

-- XML file format for SWIFT ISO20022 messages
CREATE OR REPLACE FILE FORMAT ICGI_XML_FILE_FORMAT
    TYPE = XML
    STRIP_OUTER_ELEMENT = TRUE
    COMMENT = 'Optimized XML file format for SWIFT ISO20022 message processing. Strips outer XML envelope for efficient VARIANT parsing of PACS.008 credit transfers and PACS.002 status reports. Supports multi-message files and preserves all ISO20022 schema elements for compliance and downstream analytics.';

-- ============================================================
-- INTERNAL STAGES - Message Landing Area
-- ============================================================
-- Secure internal stage for SWIFT ISO20022 XML message ingestion with
-- directory listing enabled for automated file discovery and processing workflows.

-- Stage for inbound SWIFT messages (production)
CREATE OR REPLACE STAGE ICGI_RAW_SWIFT_INBOUND
    FILE_FORMAT = ICGI_XML_FILE_FORMAT
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Production staging area for inbound SWIFT ISO20022 XML messages. Handles PACS.008 customer credit transfers, PACS.002 payment status reports, and future message types. Directory listing enabled for automated file discovery and stream-based processing triggers. Supports high-volume interbank clearing operations with secure file handling.';

-- ============================================================
-- TABLES - Raw Message Storage
-- ============================================================
-- Persistent storage for raw SWIFT ISO20022 XML messages with metadata
-- for audit trails, compliance, and downstream processing requirements.

-- ============================================================
-- ICGI_RAW_SWIFT_MESSAGES TABLE - Raw XML Message Repository
-- ============================================================
-- Central repository for all inbound SWIFT ISO20022 XML messages with
-- comprehensive metadata capture for operational monitoring and compliance.

CREATE OR REPLACE TABLE ICGI_RAW_SWIFT_MESSAGES (
    FILE_NAME   STRING COMMENT 'Original source file name for audit trail, correlation with external systems, and operational troubleshooting. Enables traceability back to source systems and message routing verification.',
    LOAD_TS     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP COMMENT 'System ingestion timestamp for data lineage tracking, SLA monitoring, and processing performance analysis. Critical for operational dashboards and regulatory reporting timelines.',
    RAW_XML     VARIANT COMMENT 'Complete SWIFT ISO20022 XML message content preserved as VARIANT for flexible schema evolution, compliance archival, and comprehensive downstream parsing. Supports all current and future ISO20022 message types with full fidelity preservation.'
)
COMMENT = 'Master repository for raw SWIFT ISO20022 XML messages supporting interbank clearing and settlement operations. Stores PACS.008 customer credit transfer instructions, PACS.002 payment status reports, and future message types in native XML format. Provides foundation for downstream business logic processing, regulatory compliance analysis, operational monitoring, and audit trail maintenance. Optimized for high-volume message ingestion with comprehensive metadata capture.';

-- ============================================================
-- STREAMS - File Arrival Detection
-- ============================================================
-- Change data capture streams for automated detection of new SWIFT message
-- arrivals, enabling near real-time processing and operational efficiency.

-- Stream to detect new SWIFT XML files arriving on the stage
CREATE OR REPLACE STREAM ICGI_STREAM_SWIFT_FILES
ON STAGE ICGI_RAW_SWIFT_INBOUND
COMMENT = 'Change data capture stream for automated detection of new SWIFT ISO20022 XML files arriving on the inbound stage. Triggers downstream processing tasks for near real-time message ingestion and business logic execution. Essential for operational SLA compliance and timely payment processing in high-volume interbank clearing environments.';

-- ============================================================
-- TASKS - Automated Message Processing
-- ============================================================
-- Scheduled tasks for automated SWIFT message ingestion with stream-based
-- triggering for efficient resource utilization and near real-time processing.

-- Task to automatically load new SWIFT XML files
CREATE OR REPLACE TASK ICGI_TASK_LOAD_SWIFT_MESSAGES
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('ICGI_STREAM_SWIFT_FILES')
    -- Automated SWIFT ISO20022 XML message ingestion task with stream-based triggering
    -- for efficient processing of PACS.008 and PACS.002 messages. Executes every 60 minutes
    -- with serverless compute and conditional execution based on file arrival detection for
    -- optimal resource utilization and operational cost management.
AS
    COPY INTO ICGI_RAW_SWIFT_MESSAGES (FILE_NAME, RAW_XML)
    FROM (
        SELECT 
            METADATA$FILENAME AS FILE_NAME,          -- Capture original filename for audit trail
            PARSE_XML($1) AS RAW_XML                 -- Parse XML content into VARIANT for flexible processing
        FROM @ICGI_RAW_SWIFT_INBOUND
    )
    PATTERN = '.*\.xml'                              -- Process all XML files regardless of naming convention
    FILE_FORMAT = ICGI_XML_FILE_FORMAT               -- Use optimized XML format for ISO20022 messages
    ON_ERROR = CONTINUE;                             -- Continue processing on individual file errors for resilience

-- Activate the task for production operations
ALTER TASK ICGI_TASK_LOAD_SWIFT_MESSAGES RESUME;

-- ============================================================
-- MANUAL LOADING EXAMPLES
-- ============================================================

-- Manual COPY INTO command for immediate loading of SWIFT XML files
-- Use this for one-time bulk loading or testing
/*
COPY INTO ICGI_RAW_SWIFT_MESSAGES (FILE_NAME, RAW_XML)
FROM (
    SELECT 
        METADATA$FILENAME AS FILE_NAME,
        PARSE_XML($1) AS RAW_XML
    FROM @ICGI_RAW_SWIFT_INBOUND_DEV
)
PATTERN = '.*\.(xml|XML)'
FILE_FORMAT = ICGI_XML_FILE_FORMAT
ON_ERROR = CONTINUE;

-- Check loaded data
SELECT 
    FILE_NAME,
    LOAD_TS,
    RAW_XML:"@xmlns"::STRING AS XML_NAMESPACE,
    RAW_XML:"Document":"*"[0] AS MESSAGE_TYPE
FROM ICGI_RAW_SWIFT_MESSAGES 
ORDER BY LOAD_TS DESC
LIMIT 10;
*/

-- ============================================================
-- SCHEMA COMPLETION STATUS
-- ============================================================
-- ✅ PAY_RAW_001 Schema Deployment Complete
--
-- OBJECTS CREATED:
-- • 1 Stage: ICGI_RAW_SWIFT_INBOUND (XML messages)
-- • 1 File Format: ICGI_XML_FILE_FORMAT (optimized ISO20022 XML parsing)
-- • 1 Table: ICGI_RAW_SWIFT_MESSAGES (raw message repository with metadata)
-- • 1 Stream: ICGI_STREAM_SWIFT_FILES (file arrival detection for automation)
-- • 1 Task: ICGI_TASK_LOAD_SWIFT_MESSAGES (automated ingestion - ACTIVE)
--
-- NEXT STEPS:
-- 1. ✅ PAY_RAW_001 schema deployed successfully
-- 2. Upload SWIFT ISO20022 XML files to stage: PUT file://*.xml @ICGI_RAW_SWIFT_INBOUND;
-- 3. Monitor task execution: SHOW TASKS IN SCHEMA PAY_RAW_001;
-- 4. Verify message loading: SELECT COUNT(*) FROM ICGI_RAW_SWIFT_MESSAGES;
-- 5. Check processing errors in task history and stream status
-- 6. Deploy PAY_AGG_001 schema for message parsing and business logic
--
-- USAGE EXAMPLES:
-- -- Upload SWIFT XML files
-- PUT file://pacs008_20250928_001.xml @ICGI_RAW_SWIFT_INBOUND;
-- PUT file://pacs002_20250928_001.xml @ICGI_RAW_SWIFT_INBOUND;
--
-- -- Monitor ingestion
-- SELECT FILE_NAME, LOAD_TS, LENGTH(RAW_XML::STRING) AS xml_size 
-- FROM ICGI_RAW_SWIFT_MESSAGES 
-- ORDER BY LOAD_TS DESC LIMIT 10;
--
-- -- Check message types
-- SELECT 
--     FILE_NAME,
--     CASE 
--         WHEN RAW_XML::STRING ILIKE '%FIToFICstmrCdtTrf%' THEN 'PACS.008'
--         WHEN RAW_XML::STRING ILIKE '%FIToFIPmtStsRpt%' THEN 'PACS.002'
--         ELSE 'UNKNOWN'
--     END AS message_type,
--     COUNT(*) AS message_count
-- FROM ICGI_RAW_SWIFT_MESSAGES 
-- GROUP BY FILE_NAME, message_type;
--
-- MONITORING:
-- - Task status: SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY()) WHERE NAME = 'ICGI_TASK_LOAD_SWIFT_MESSAGES';
-- - Stream status: SHOW STREAMS IN SCHEMA PAY_RAW_001;
-- - Stage contents: LIST @ICGI_RAW_SWIFT_INBOUND;
--
-- PERFORMANCE OPTIMIZATION:
-- - Monitor warehouse usage during peak message processing periods
-- - Consider clustering on LOAD_TS for time-based queries
-- - Archive old messages based on regulatory retention requirements
-- ============================================================
