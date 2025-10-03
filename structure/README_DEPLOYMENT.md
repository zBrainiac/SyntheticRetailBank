# Snowflake DDL Deployment Guide

This directory holds the complete DDL (in Snowflake syntax) for the **Synthetic Retail Bank** data model. It includes schemas for customer data (CRM), multi-currency support, SCD Type 2 address tracking, Exposed Person compliance, payment anomaly detection, and advanced analytics.


## File Structure

The DDL is organized by **business domain** to ensure a clear separation of concerns and independence. Within each domain, individual files are used for each **data maturity layer** to reduce internal dependencies.

```
structure/
├── 000_database_setup.sql     # Database and warehouse creation
├── 010_CRMI.sql               # CRM Raw: Customer Master Data & Exposed Person System
├── 011_ACCI.sql               # CRM Raw: Account Master Data
├── 020_REFI.sql               # REF Raw: FX Rates Reference Data
├── 030_PAYI.sql               # PAY Raw: Payment Transactions
├── 040_EQTI.sql               # EQT Raw: Equity Trading
├── 050_ICGI.sql               # ICG Raw: SWIFT ISO20022 Message Processing
├── 310_CRMA.sql               # CRM Agg: Customer Address Aggregation (SCD Type 2)
├── 311_ACCA.sql               # CRM Agg: Account Aggregation Layer
├── 330_PAYA.sql               # PAY Agg: Payment Anomaly Detection & Account Balances
├── 350_ICGA.sql               # ICG Agg: SWIFT Message Aggregation
├── 500_REPP.sql               # REP Agg: Reporting & Analytics
└── README_DEPLOYMENT.md       # This deployment guide
```

## Object Prefix Matrix

### Prefix per **Data Architecture Layers:**

| **Layer**                           | **Schemas**                                                                  | **Schema Object - Prefixes** <br/> (Tables / View / ...)         |
|-------------------------------------|------------------------------------------------------------------------------|------------------------------------------------------------------|
| **🟢 DAP** <br/> Data Products      | ICG_DAP_v001                                                                 | ICGD_                                                            |
| **🟡 AGG** <br/> Aggregation Layer  | CRM_AGG_001<br/>PAY_AGG_001<br/>ICG_AGG_v001<br/>REP_AGG_001                 | CRMA_<br/>ACCA_<br/>PAYA_<br/>ICG_<br/>REPP_                     |
| **🔴 RAW** <br/> RAW / Landing zone | CRM_RAW_001<br/>REF_RAW_001<br/>PAY_RAW_001<br/>EQT_RAW_001<br/>ICG_RAW_v001 | CRMI_<br/>ACCI_<br/>REFI_<br/>PAYI_<br/>EQTI_<br/>ICG_<br/>ICGI_ |



### ** Naming Convention:**

#### Schema - Naming
- 1-3 position: Business domain (CRM, PAY, EQT, ICG, REF, REP, ...)
- 4 position: "_")
- 5-7 position: data maturity layer (RAW, AGG, ..., DAP)
- 8 position: "_")
- 9-14 position: versioning (V000, +1 = minor changes, +10	= major changes)


####  Schema Object - Prefixes (Tables / View / ...)
- 1-3 position: Business domain (CRM, PAY, EQT, ICG, REF, REP, ...)
- 4 position: software component with data maturity layer (I=Ingestion/Raw, A=Aggregation, P=Processing/DAP)
- Examples: 
  - `CRMI_` = **CRM Ingestion** (RAW layer)
  - `CRMA_` = **CRM Aggregation** (AGG layer)
  - `PAYA_` = **PAY Aggregation** (AGG layer)

## 🚀 Deployment Order

**⚠️ CRITICAL: Execute files in the exact order listed below to ensure proper dependencies:**

### 1. Database Setup
```sql
-- Execute first: Database and warehouse creation
@000_database_setup.sql
```

### 2. Customer Master Data & Exposed Person System
**Business Domain**: `CRM`

```sql
-- Execute second: Core customer data and compliance
@010_CRMI.sql
```

**Objects Created:**
- **Schema**: `CRM_RAW_001`
- **Stages**: `CRMI_CUSTOMERS`, `CRMI_ADDRESSES`, `CRMI_EXPOSED_PERSON`
- **File Formats**: `CRMI_FF_CUSTOMER_CSV`, `CRMI_FF_ADDRESS_CSV`, `CRMI_FF_EXPOSED_PERSON_CSV`
- **Tables**: `CRMI_PARTY`, `CRMI_ADDRESSES`, `CRMI_EXPOSED_PERSON`
- **Streams**: `CRMI_STREAM_CUSTOMER_FILES`, `CRMI_STREAM_ADDRESS_FILES`, `CRMI_STREAM_EXPOSED_PERSON_FILES`
- **Tasks**: `CRMI_TASK_LOAD_CUSTOMERS`, `CRMI_TASK_LOAD_ADDRESSES`, `CRMI_TASK_LOAD_EXPOSED_PERSON`

**Key Features:**
- **Customer Master Data**: Core customer information (12 EMEA countries)
- **REPORTING_CURRENCY**: Country-based currency assignment (EUR, GBP, NOK, SEK, DKK, PLN)
- **SCD Type 2 Addresses**: Append-only base table with `INSERT_TIMESTAMP_UTC`
- **Exposed Person Compliance**: Politically Exposed Persons for regulatory compliance
- **Automated Loading**: Stream-triggered tasks with 1-hour schedule

### 3. Account Master Data
**Business Domain**: `CRM`

```sql
-- Execute third: Account information
@011_ACCI.sql
```

**Objects Created:**
- **Schema**: `CRM_RAW_001`
- **Stages**: `ACCI_ACCOUNTS`
- **File Formats**: `ACCI_FF_ACCOUNT_CSV`
- **Tables**: `ACCI_ACCOUNTS`
- **Streams**: `ACCI_STREAM_ACCOUNT_FILES`
- **Tasks**: `ACCI_TASK_LOAD_ACCOUNTS`

### 4. FX Rates Reference Data
**Business Domain**: `REF`

```sql
-- Execute fourth: Foreign exchange rates
@020_REFI.sql
```

**Objects Created:**
- **Schema**: `REF_RAW_001`
- **Stages**: `REFI_FX_RATES`
- **File Formats**: `REFI_FF_FX_RATES_CSV`
- **Tables**: `REFI_FX_RATES`
- **Streams**: `REFI_STREAM_FX_RATE_FILES`
- **Tasks**: `REFI_TASK_LOAD_FX_RATES`

**Key Features:**
- **Multi-Currency Support**: Daily FX rates with bid/ask spreads
- **Real-Time Rates**: Latest rates for currency conversion
- **Reference Data**: Central FX rate repository for all schemas

### 4a. FX Rates Aggregation Layer
**Business Domain**: `REF`

```sql
-- Execute after raw layer: Enhanced FX rates with analytics
@320_REFA.sql
```

**Objects Created:**
- **Schema**: `REF_AGG_001`
- **Dynamic Tables**: `REFA_AGG_DT_FX_RATES_ENHANCED` - Enhanced FX rates with analytics and volatility metrics

**Key Features:**
- **Enhanced Analytics**: Spreads, volatility, trends, risk classifications
- **Real-Time Metrics**: Current rates, moving averages, position analysis
- **Risk Management**: Volatility and spread-based risk classifications

### 5. Payment Transactions
**Business Domain**: `PAY`

```sql
-- Execute fifth: Payment data
@030_PAYI.sql
```

**Objects Created:**
- **Schema**: `PAY_RAW_001`
- **Stages**: `PAYI_TRANSACTIONS`
- **File Formats**: `PAYI_FF_TRANSACTION_CSV`
- **Tables**: `PAYI_TRANSACTIONS`
- **Streams**: `PAYI_STREAM_TRANSACTION_FILES`
- **Tasks**: `PAYI_TASK_LOAD_TRANSACTIONS`

**Key Features:**
- **Multi-Currency Transactions**: Support for all EMEA currencies
- **Base Currency Conversion**: Automatic FX conversion to base currency
- **Anomaly Detection Ready**: Transaction patterns for behavioral analysis

### 6. Equity Trading
**Business Domain**: `EQT`

```sql
-- Execute sixth: Trading data
@040_EQTI.sql
```

**Objects Created:**
- **Schema**: `EQT_RAW_001`
- **Stages**: `EQTI_TRADES`
- **File Formats**: `EQTI_FF_TRADES_CSV`
- **Tables**: `EQTI_TRADES`
- **Streams**: `EQTI_STREAM_TRADES_FILES`
- **Tasks**: `EQTI_TASK_LOAD_TRADES`

### 7. SWIFT ISO20022 Message Processing
**Business Domain**: `ICG` 

```sql
-- Execute seventh: SWIFT message processing
@050_ICGI.sql
```

**Objects Created:**
- **Schema**: `ICG_RAW_v001`
- **Stages**: `ICGI_RAW_SWIFT_INBOUND`, `ICGI_RAW_EMAIL_INBOUND`, `ICGI_RAW_PDF_INBOUND`
- **File Formats**: `ICGI_XML_FILE_FORMAT`
- **Tables**: `ICGI_RAW_SWIFT_MESSAGES`
- **Streams**: `ICGI_STREAM_SWIFT_FILES`
- **Tasks**: `ICGI_TASK_LOAD_SWIFT_MESSAGES`

**Key Features:**
- **SWIFT Message Processing**: PACS.008 and PACS.002 message types
- **DocAI Integration**: Email and PDF staging for document AI processing
- **XML Processing**: Structured SWIFT message parsing

##  AGGREGATION LAYER

Execute after all raw layer schemas are deployed:

### 8. Customer Address Aggregation (SCD Type 2)
```sql
-- Execute eighth: Customer address dimensional views
@310_CRMA.sql
```

**Objects Created:**
- **Schema**: `CRM_AGG_001`
- **Dynamic Tables**: 
  - `CRMA_AGG_DT_ADDRESSES_CURRENT` - Latest address per customer
  - `CRMA_AGG_DT_ADDRESSES_HISTORY` - Full SCD Type 2 with VALID_FROM/VALID_TO
  - `CRMA_AGG_DT_CUSTOMER` - Customer 360° view with Exposed Person fuzzy matching

**Key Features:**
- **SCD Type 2 Implementation**: Complete address history tracking
- **Customer 360°**: Comprehensive customer view with master data, addresses, accounts
- **Exposed Person Matching**: Advanced `EDITDISTANCE` fuzzy matching for compliance
- **Real-Time Refresh**: 1-hour TARGET_LAG for operational queries

### 9. Account Aggregation Layer
```sql
-- Execute ninth: Account master data aggregation
@311_ACCA.sql
```

**Objects Created:**
- **Schema**: `CRM_AGG_001`
- **Dynamic Tables**: `ACCA_AGG_DT_ACCOUNTS` - Enhanced account master data

**Key Features:**
- **Data Architecture**: Proper Raw → Aggregation → Analytics layering
- **Enhanced Metadata**: Account type flags and classification
- **Processing Metadata**: Aggregation timestamps and source tracking

### 10. Payment Anomaly Detection & Account Balances
```sql
-- Execute tenth: Payment analytics and anomaly detection
@330_PAYA.sql
```

**Objects Created:**
- **Schema**: `PAY_AGG_001`
- **Dynamic Tables**: 
  - `PAYA_AGG_DT_TRANSACTION_ANOMALIES` - Behavioral anomaly detection
  - `PAYA_AGG_DT_ACCOUNT_BALANCES` - Real-time account balances with FX conversion

**Key Features:**
- **Behavioral Anomaly Detection**: Multi-dimensional transaction analysis
- **Account Balance Management**: Real-time balance calculation with intelligent transaction allocation
- **Dynamic FX Integration**: Real-time currency conversion using `REF_RAW_001.REFI_FX_RATES`
- **Risk Scoring**: Composite anomaly scores with operational alerting thresholds

### 11. SWIFT Message Aggregation
```sql
-- Execute eleventh: SWIFT message processing
@350_ICGA.sql
```

**Objects Created:**
- **Schema**: `ICG_AGG_v001`
- **Dynamic Tables**: 
  - `ICGA_AGG_SWIFT_PACS008` - Parsed SWIFT PACS.008 customer credit transfer instructions
  - `ICGA_AGG_SWIFT_PACS002` - Parsed SWIFT PACS.002 payment status reports and acknowledgments
  - `ICGA_AGG_SWIFT_JOIN_PACS008_PACS002` - Complete payment lifecycle view joining instructions with status reports

### 12. Reporting & Analytics
```sql
-- Execute last: Analytics and reporting
@500_REPP.sql
```

**Objects Created:**
- **Schema**: `REP_AGG_001`
- **Dynamic Tables**: 
  - `REPP_DT_CUSTOMER_SUMMARY` - Comprehensive customer profiling with transaction statistics
  - `REPP_DT_DAILY_TRANSACTION_SUMMARY` - Daily transaction volume and pattern analysis
  - `REPP_DT_CURRENCY_EXPOSURE_CURRENT` - Current foreign exchange exposure monitoring
  - `REPP_AGGDT_HIGH_RISK_PATTERNS` - High-risk transaction pattern detection for compliance
  - `REPP_DT_IRB_CUSTOMER_RATINGS` - IRB customer-level credit ratings and risk parameters
  - `REPP_DT_IRB_PORTFOLIO_METRICS` - IRB portfolio-level risk metrics aggregated by segment
  - `REPP_DT_IRB_RWA_SUMMARY` - IRB Risk Weighted Assets summary for regulatory reporting
  - `REPP_DT_IRB_RISK_TRENDS` - IRB risk parameter trends and model validation metrics

## Schema Architecture

### RAW LAYER (Data Ingestion)
| Schema         | Purpose                          | Key Objects                                                    | Refresh Strategy       |
|----------------|----------------------------------|----------------------------------------------------------------|------------------------|
| `CRM_RAW_001`  | Customer Master & Exposed Person | CRMI_PARTY, CRMI_ADDRESSES, CRMI_EXPOSED_PERSON, ACCI_ACCOUNTS | Stream-triggered tasks |
| `REF_RAW_001`  | Reference Data                   | REFI_FX_RATES                                                  | Stream-triggered tasks |
| `PAY_RAW_001`  | Payment Transactions             | PAYI_TRANSACTIONS                                              | Stream-triggered tasks |
| `EQT_RAW_001`  | Equity Trading                   | EQTI_TRADES                                                    | Stream-triggered tasks |
| `ICG_RAW_v001` | SWIFT Messages                   | ICGI_RAW_SWIFT_MESSAGES                                        | Stream-triggered tasks |

### AGGREGATION LAYER (Business Logic)
| Schema         | Purpose            | Key Objects                                            | Refresh Strategy      |
|----------------|--------------------|--------------------------------------------------------|-----------------------|
| `CRM_AGG_001`  | Customer Analytics | Address SCD Type 2, Customer 360°, Account aggregation | 1-hour dynamic tables |
| `REF_AGG_001`  | Reference Analytics | FX rates with analytics and volatility metrics        | 1-hour dynamic tables |
| `PAY_AGG_001`  | Payment Analytics  | Anomaly detection, Account balances with FX            | 1-hour dynamic tables |
| `ICG_AGG_v001` | SWIFT Processing   | Parsed SWIFT messages and payment lifecycle analytics  | 1-hour dynamic tables |
| `REP_AGG_001`  | Reporting          | Customer summaries, transaction analytics, IRB metrics | 1-hour dynamic tables |

##  Advanced Features

### Multi-Currency Support
- **Customer Reporting Currencies**: Country-based currency assignment (EUR, GBP, NOK, SEK, DKK, PLN)
- **FX Rate Integration**: Real-time currency conversion using `REF_RAW_001.REFI_FX_RATES`
- **Dynamic Base Currency**: Automatic detection from transaction data
- **Account Balance Conversion**: Real-time FX conversion for account currency display

### SCD Type 2 Address Management
- **Base Table**: `CRMI_ADDRESSES` with append-only structure
- **Current View**: `CRMA_AGG_DT_ADDRESSES_CURRENT` for operational queries
- **History View**: `CRMA_AGG_DT_ADDRESSES_HISTORY` with VALID_FROM/VALID_TO
- **Automated Processing**: Dynamic tables handle SCD Type 2 logic

### Payment Anomaly Detection
- **Behavioral Analysis**: Multi-dimensional customer behavior profiling
- **Statistical Scoring**: Z-scores for amount, timing, and velocity anomalies
- **Risk Classification**: CRITICAL, HIGH, MODERATE, NORMAL classifications
- **Operational Alerting**: Immediate review and enhanced monitoring flags

### Account Balance Management
- **Real-Time Balances**: Dynamic calculation with transaction allocation logic
- **Multi-Account Support**: CHECKING, SAVINGS, BUSINESS, INVESTMENT accounts
- **FX Integration**: Currency conversion using actual market rates
- **Balance Analytics**: Activity levels, risk indicators, and categorization

### Exposed Person Compliance System
- **Master Data**: `CRMI_EXPOSED_PERSON` table with comprehensive PEP information
- **Risk Categories**: DOMESTIC, FOREIGN, INTERNATIONAL_ORG, FAMILY_MEMBER, CLOSE_ASSOCIATE
- **Reference Links**: URL sources for compliance documentation
- **Fuzzy Matching**: Advanced name matching for compliance screening

### Customer 360° View
- **Comprehensive Data**: Master data + current address + account summary + Exposed Person matching
- **Fuzzy Exposed Person Matching**: `EDITDISTANCE` functions for similar name detection
- **Risk Assessment**: Automated Exposed Person risk level calculation
- **Compliance Flags**: High-risk customer identification

### SWIFT Message Processing
- **ISO20022 Support**: PACS.008 (payment initiation) and PACS.002 (payment status)
- **XML Processing**: Native Snowflake XML parsing
- **Automated Loading**: Stream-triggered processing
- **Message Correlation**: Joined views for complete payment flows

## Object Naming Standards

### Consistent Naming Convention
- **Raw Tables**: `{DOMAIN}I_{OBJECT}` (e.g., `CRMI_PARTY`, `PAYI_TRANSACTIONS`)
- **Aggregation Tables**: `{DOMAIN}A_AGG_{OBJECT}` (e.g., `ICGA_AGG_SWIFT_PACS008`)
- **Dynamic Tables**: `{SCHEMA}_DT_{PURPOSE}` (e.g., `CRMA_AGG_DT_ADDRESSES_CURRENT`)
- **Stages**: `{DOMAIN}I_{OBJECT}` (e.g., `CRMI_CUSTOMERS`)
- **File Formats**: `{DOMAIN}I_FF_{OBJECT}_CSV` (e.g., `CRMI_FF_CUSTOMER_CSV`)
- **Streams**: `{DOMAIN}I_STREAM_{OBJECT}_FILES`
- **Tasks**: `{DOMAIN}I_TASK_LOAD_{OBJECT}`

### Domain Prefixes
- **CRMI**: Customer Master Ingestion
- **CRMA**: Customer Master Aggregation
- **ACCI**: Account Ingestion
- **ACCA**: Account Aggregation
- **REFI**: Reference Data Ingestion
- **REFA**: Reference Data Aggregation
- **PAYI**: Payment Ingestion
- **PAYA**: Payment Aggregation
- **EQTI**: Equity Trading Ingestion
- **ICGI**: Interbank Clearing Gateway Ingestion
- **ICGA**: Interbank Clearing Gateway Aggregation
- **REPP**: Reporting

## Configuration

### Warehouse Settings
All tasks and dynamic tables use: **`MD_TEST_WH`**

To change warehouse:
```sql
-- Search and replace 'MD_TEST_WH' with your warehouse name across all files
```

### Refresh Strategy
- **Tasks**: 1-hour schedule with stream-based triggering
- **Dynamic Tables**: 1-hour `TARGET_LAG` for consistent refresh
- **High-Value Trades**: 1-hour refresh for risk management

### Error Handling
- **Tasks**: `ON_ERROR = CONTINUE` for resilient processing
- **Pattern Matching**: Specific file patterns for each data type
- **Comprehensive Logging**: Built-in Snowflake task logging

## Verification

### Post-Deployment Checks
```sql
-- Verify database and schemas
SHOW DATABASES LIKE 'AAA_DEV_SYNTHETIC_BANK';
SHOW SCHEMAS IN DATABASE AAA_DEV_SYNTHETIC_BANK;

-- Check core tables
SHOW TABLES IN SCHEMA AAA_DEV_SYNTHETIC_BANK.CRM_RAW_001;
SHOW TABLES IN SCHEMA AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001;

-- Verify dynamic tables
SHOW DYNAMIC TABLES IN SCHEMA AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001;
SHOW DYNAMIC TABLES IN SCHEMA AAA_DEV_SYNTHETIC_BANK.REP_AGG_001;

-- Check task status
SHOW TASKS IN DATABASE AAA_DEV_SYNTHETIC_BANK;
SELECT NAME, STATE, SCHEDULE FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- Verify streams
SHOW STREAMS IN DATABASE AAA_DEV_SYNTHETIC_BANK;
```

### Sample Queries
```sql
-- Customer 360 view with Exposed Person matching
SELECT * FROM AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRMA_AGG_DT_CUSTOMER 
WHERE PEP_MATCH_TYPE != 'NO_MATCH' LIMIT 10;

-- Current addresses
SELECT * FROM AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRMA_AGG_DT_ADDRESSES_CURRENT LIMIT 10;

-- Address history for specific customer
SELECT * FROM AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRMA_AGG_DT_ADDRESSES_HISTORY 
WHERE CUSTOMER_ID = 'CUST_00001' ORDER BY VALID_FROM;
```

## Data Loading

### File Upload Process
```sql
-- Upload customer master data
PUT file://path/to/customers.csv @AAA_DEV_SYNTHETIC_BANK.CRM_RAW_001.CRMI_CUSTOMERS;

-- Upload address data (base + updates)
PUT file://path/to/customer_addresses.csv @AAA_DEV_SYNTHETIC_BANK.CRM_RAW_001.CRMI_ADDRESSES;
PUT file://path/to/address_updates/*.csv @AAA_DEV_SYNTHETIC_BANK.CRM_RAW_001.CRMI_ADDRESSES;

-- Upload Exposed Person data
PUT file://path/to/exposed_person_data.csv @AAA_DEV_SYNTHETIC_BANK.CRM_RAW_001.CRMI_EXPOSED_PERSON;

-- Upload accounts
PUT file://path/to/accounts.csv @AAA_DEV_SYNTHETIC_BANK.CRM_RAW_001.ACCI_ACCOUNTS;

-- Upload transaction files
PUT file://path/to/pay_transactions_*.csv @AAA_DEV_SYNTHETIC_BANK.PAY_RAW_001.PAYI_TRANSACTIONS;

-- Upload equity trades
PUT file://path/to/trades_*.csv @AAA_DEV_SYNTHETIC_BANK.EQT_RAW_001.EQTI_TRADES;

-- Upload SWIFT messages
PUT file://path/to/*.xml @AAA_DEV_SYNTHETIC_BANK.ICGI_RAW_001.ICGI_RAW_SWIFT_INBOUND_DEV;
```

### Automated Processing
1. **Streams detect** new files automatically
2. **Tasks process** files within 1 hour
3. **Dynamic tables refresh** according to TARGET_LAG
4. **Data flows** through the complete pipeline

---

**Complete Synthetic Bank Data Platform - Ready to show case!**
