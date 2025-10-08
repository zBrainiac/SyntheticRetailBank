# Snowflake DDL Deployment Guide

This directory holds the complete DDL (in Snowflake syntax) for the **Synthetic Retail Bank** data model. It includes schemas for customer data (CRM), multi-currency support, SCD Type 2 address tracking, Exposed Person compliance, payment anomaly detection, and advanced analytics.


## File Structure

The DDL is organized by **business domain** to ensure a clear separation of concerns and independence. Within each domain, individual files are used for each **data maturity layer** to reduce internal dependencies.

```
structure/
├── 000_database_setup.sql     # Database and warehouse creation
├── 001_get_listings.sql       # Snowflake Data Exchange: Global Sanctions Data Setup
├── 010_CRMI.sql               # CRM Raw: Customer Master Data & Exposed Person System
├── 011_ACCI.sql               # CRM Raw: Account Master Data
├── 020_REFI.sql               # REF Raw: FX Rates Reference Data
├── 030_PAYI.sql               # PAY Raw: Payment Transactions
├── 031_ICGI.sql               # PAY Raw: SWIFT ISO20022 Message Processing
├── 040_EQTI.sql               # EQT Raw: Equity Trading
├── 050_FIII.sql               # FII Raw: Fixed Income Trading (NEW)
├── 055_CMDI.sql               # CMD Raw: Commodity Trading (NEW)
├── 060_LOAI.sql               # LOA Raw: Loan & Document Processing
├── 310_CRMA.sql               # CRM Agg: Customer Address Aggregation (SCD Type 2)
├── 311_ACCA.sql               # CRM Agg: Account Aggregation Layer
├── 330_PAYA.sql               # PAY Agg: Payment Anomaly Detection & Account Balances
├── 331_ICGA.sql               # PAY Agg: SWIFT Message Aggregation
├── 340_EQTA.sql               # EQT Agg: Equity Trading Aggregation & Analytics
├── 350_FIIA.sql               # FII Agg: Fixed Income Aggregation & Analytics (NEW)
├── 355_CMDA.sql               # CMD Agg: Commodity Aggregation & Analytics (NEW)
├── 500_REPP.sql               # REP Agg: Core Reporting & Analytics
├── 510_REPP_EQUITY.sql        # REP Agg: Equity Trading Reporting
├── 520_REPP_CREDIT_RISK.sql   # REP Agg: Credit Risk & IRB Reporting
├── 525_REPP_FRTB.sql          # REP Agg: FRTB Market Risk Reporting (NEW)
├── 530_REPP_PORTFOLIO.sql     # REP Agg: Portfolio Performance Reporting
├── 700_semantic_view.sql      # Business-friendly semantic view
└── README_DEPLOYMENT.md       # This deployment guide
```

## Object Prefix Matrix

### Prefix per **Data Architecture Layers:**

| **Layer**                           | **Schemas**                                                                  | **Schema Object - Prefixes** <br/> (Tables / View / ...)         |
|-------------------------------------|------------------------------------------------------------------------------|------------------------------------------------------------------|
| **🟢 DAP** <br/> Data Products      |                                                                |                                                             |
| **🟡 AGG** <br/> Aggregation Layer  | CRM_AGG_001<br/>PAY_AGG_001<br/>EQT_AGG_001<br/>FII_AGG_001<br/>CMD_AGG_001<br/>REP_AGG_001 | CRMA_<br/>ACCA_<br/>PAYA_<br/>ICGA_<br/>EQTA_<br/>FIIA_<br/>CMDA_<br/>REPP_ |
| **🔴 RAW** <br/> RAW / Landing zone | CRM_RAW_001<br/>REF_RAW_001<br/>PAY_RAW_001<br/>EQT_RAW_001<br/>FII_RAW_001<br/>CMD_RAW_001 | CRMI_<br/>ACCI_<br/>REFI_<br/>PAYI_<br/>EQTI_<br/>ICGI_<br/>FIII_<br/>CMDI_ |



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

### 1a. Snowflake Data Exchange Setup (Optional)
**External Data Source**: Global Sanctions Data

```sql
-- Execute after database setup: Global sanctions data from Data Exchange
@001_get_listings.sql
```

**Purpose:**
- **Compliance Data**: Import global sanctions and watchlist data
- **PEP Screening**: Enhance Politically Exposed Persons screening
- **Regulatory Support**: Provide external reference data for compliance
- **Risk Management**: Support KYC/AML processes with real-time data

**Prerequisites:**
- Snowflake account with Data Exchange access
- Legal terms acceptance for data usage
- Email verification for listing access

**Objects Created:**
- **Database**: `REF_DAP_GLOBAL_SANCTIONS_DATA_SET`
- **Schema**: `GLOBAL_SANCTIONS_DATA`
- **Table**: `SANCTIONS_DATAFEED` - Comprehensive international sanctions data

**Key Features:**
- **Real-Time Updates**: Regular updates for current sanctions information
- **Global Coverage**: International sanctions and watchlist data
- **Compliance Integration**: Direct integration with customer screening processes
- **Regulatory Reporting**: Support for audit and compliance requirements

**Integration Points:**
- Cross-reference with `CRMI_EXPOSED_PERSON` data
- Enhance customer onboarding screening processes
- Support transaction monitoring and counterparty screening
- Provide evidence for regulatory compliance and audit requirements

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

### 7. Fixed Income Trading (FRTB)
**Business Domain**: `FII`

```sql
-- Execute seventh: Fixed income trades (bonds and swaps)
@050_FIII.sql
```

**Objects Created:**
- **Schema**: `FII_RAW_001`
- **Stages**: `FIII_STAGE`
- **Tables**: `FIII_TRADES`
- **Streams**: `FIII_TRADES_STREAM`
- **Tasks**: `FIII_LOAD_TRADES_TASK` (serverless, 60 min)

**Key Features:**
- **Government Bonds**: Sovereign debt (CHF, EUR, USD, GBP)
- **Corporate Bonds**: Investment grade and high yield with credit ratings
- **Interest Rate Swaps**: SARON, EURIBOR, SOFR, SONIA
- **FRTB Risk Metrics**: Duration, DV01, credit spreads, liquidity scores
- **Automated Loading**: Serverless task for CSV ingestion

### 8. Commodity Trading (FRTB)
**Business Domain**: `CMD`

```sql
-- Execute eighth: Commodity trades (energy, metals, agricultural)
@055_CMDI.sql
```

**Objects Created:**
- **Schema**: `CMD_RAW_001`
- **Stages**: `CMDI_STAGE`
- **Tables**: `CMDI_TRADES`
- **Streams**: `CMDI_TRADES_STREAM`
- **Tasks**: `CMDI_LOAD_TRADES_TASK` (serverless, 60 min)

**Key Features:**
- **Energy**: Crude Oil (WTI, Brent), Natural Gas, Heating Oil
- **Precious Metals**: Gold, Silver, Platinum, Palladium
- **Base Metals**: Copper, Aluminum, Zinc, Nickel
- **Agricultural**: Corn, Wheat, Soybeans, Coffee, Sugar
- **FRTB Risk Metrics**: Delta, volatility, spot/forward prices, liquidity scores
- **Physical Delivery**: Delivery month, location, and contract tracking

### 9. SWIFT ISO20022 Message Processing
**Business Domain**: `ICG` 

```sql
-- Execute fifth: SWIFT message processing (raw layer)
@031_ICGI.sql
```

**Objects Created:**
- **Schema**: `PAY_RAW_001`
- **Stages**: `ICGI_RAW_SWIFT_INBOUND`
- **File Formats**: `ICGI_XML_FILE_FORMAT`
- **Tables**: `ICGI_RAW_SWIFT_MESSAGES`
- **Streams**: `ICGI_STREAM_SWIFT_FILES`
- **Tasks**: `ICGI_TASK_LOAD_SWIFT_MESSAGES`

**Key Features:**
- **SWIFT Message Processing**: PACS.008 and PACS.002 message types
- **XML Processing**: Structured SWIFT message parsing with PARSE_XML()
- **Stream-Based Automation**: Automatic file detection and processing

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
-- Execute sixth: SWIFT message aggregation (PAY_AGG_001)
@331_ICGA.sql
```

**Objects Created:**
- **Schema**: `PAY_AGG_001`
- **Dynamic Tables**: 
  - `ICGA_AGG_DT_SWIFT_PACS008` - Parsed SWIFT PACS.008 customer credit transfer instructions
  - `ICGA_AGG_DT_SWIFT_PACS002` - Parsed SWIFT PACS.002 payment status reports and acknowledgments
  - `ICGA_AGG_DT_SWIFT_PAYMENT_LIFECYCLE` - Complete payment lifecycle view joining instructions with status reports

### 12. Equity Trading Aggregation & Analytics
```sql
-- Execute: Equity trading analytics
@340_EQTA.sql
```

**Objects Created:**
- **Schema**: `EQT_AGG_001`
- **Dynamic Tables**: 
  - `EQTA_AGG_DT_TRADE_SUMMARY` - Enriched trade-level analytics with metadata and classifications
  - `EQTA_AGG_DT_PORTFOLIO_POSITIONS` - Current holdings and positions per account with P&L
  - `EQTA_AGG_DT_CUSTOMER_ACTIVITY` - Customer trading behavior and activity metrics

**Key Features:**
- **Trade Analytics**: Comprehensive trade-level view with execution quality metrics
- **Portfolio Positions**: Real-time position tracking with realized P&L calculation
- **Customer Behavior**: Trading activity patterns and engagement analysis
- **Commission Analysis**: Commission rate tracking in basis points
- **Settlement Tracking**: Settlement period analysis and monitoring

### 13. Fixed Income Aggregation & Analytics (FRTB)
```sql
-- Execute: Fixed income analytics
@350_FIIA.sql
```

**Objects Created:**
- **Schema**: `FII_AGG_001`
- **Dynamic Tables** (5 tables):
  - `FIIA_AGG_DT_TRADE_SUMMARY` - Enriched trade analytics with risk metrics
  - `FIIA_AGG_DT_PORTFOLIO_POSITIONS` - Current holdings by customer/issuer
  - `FIIA_AGG_DT_DURATION_ANALYSIS` - Interest rate risk metrics (duration, DV01)
  - `FIIA_AGG_DT_CREDIT_EXPOSURE` - Credit risk by rating and issuer type
  - `FIIA_AGG_DT_YIELD_CURVE` - Yield curve construction by currency

**Key Features:**
- **Interest Rate Risk**: Duration and DV01 analytics for rate sensitivity
- **Credit Risk**: Exposure aggregation by credit rating and issuer
- **Yield Curve**: Multi-currency yield curve construction
- **Maturity Analysis**: Position bucketing by maturity (short/medium/long term)
- **FRTB Compliance**: Risk metrics for Standardized Approach capital calculations

### 14. Commodity Aggregation & Analytics (FRTB)
```sql
-- Execute: Commodity analytics
@355_CMDA.sql
```

**Objects Created:**
- **Schema**: `CMD_AGG_001`
- **Dynamic Tables** (5 tables):
  - `CMDA_AGG_DT_TRADE_SUMMARY` - Enriched trade analytics with risk metrics
  - `CMDA_AGG_DT_PORTFOLIO_POSITIONS` - Current holdings by commodity type
  - `CMDA_AGG_DT_DELTA_EXPOSURE` - Price risk exposure by commodity class
  - `CMDA_AGG_DT_VOLATILITY_ANALYSIS` - Volatility metrics and regime classification
  - `CMDA_AGG_DT_DELIVERY_SCHEDULE` - Physical delivery tracking and logistics

**Key Features:**
- **Delta Risk**: Price sensitivity aggregation by commodity class
- **Volatility Analysis**: Volatility regime classification (LOW/NORMAL/HIGH/EXTREME)
- **Physical Delivery**: Delivery obligation tracking for futures and forwards
- **Concentration Risk**: Position concentration analysis by commodity type
- **FRTB Compliance**: Risk metrics for Standardized Approach capital calculations

### 15. Core Reporting & Analytics
```sql
-- Execute: Core reporting tables
@500_REPP.sql
```

**Objects Created:**
- **Schema**: `REP_AGG_001`
- **Dynamic Tables** (9 core tables): 
  - `REPP_AGG_DT_CUSTOMER_SUMMARY` - Comprehensive customer profiling with transaction statistics
  - `REPP_AGG_DT_DAILY_TRANSACTION_SUMMARY` - Daily transaction volume and pattern analysis
  - `REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT` - Current foreign exchange exposure monitoring
  - `REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY` - Historical FX exposure trends
  - `REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE` - Settlement timing and liquidity risk
  - `REPP_AGG_DT_ANOMALY_ANALYSIS` - Customer-level anomaly detection
  - `REPP_AGG_DT_HIGH_RISK_PATTERNS` - High-risk transaction pattern detection
  - `REPP_AGG_DT_SETTLEMENT_ANALYSIS` - Settlement timing analysis

**Key Features:**
- **Customer Analytics**: 360° customer view with transaction profiling
- **FX Risk Management**: Multi-dimensional currency exposure analysis
- **Compliance Monitoring**: Anomaly detection and suspicious activity reporting
- **Settlement Risk**: Liquidity and operational risk monitoring

### 14. Equity Trading Reporting
```sql
-- Execute: Equity trading reporting
@510_REPP_EQUITY.sql
```

**Objects Created:**
- **Schema**: `REP_AGG_001`
- **Dynamic Tables** (4 tables): 
  - `REPP_AGG_DT_EQUITY_SUMMARY` - Customer equity trading activity summary
  - `REPP_AGG_DT_EQUITY_POSITIONS` - Position summary by security
  - `REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE` - FX exposure from equity trades
  - `REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES` - Large trade compliance monitoring

**Key Features:**
- **Trading Activity**: Customer-level trading statistics and profiling
- **Position Concentration**: Security-level position tracking and risk analysis
- **Currency Exposure**: FX risk from multi-currency equity trading
- **Compliance**: High-value trade monitoring (>100k CHF threshold)

### 15. Credit Risk & IRB Reporting
```sql
-- Execute: Credit risk and IRB analytics
@520_REPP_CREDIT_RISK.sql
```

**Objects Created:**
- **Schema**: `REP_AGG_001`
- **Dynamic Tables** (5 tables): 
  - `REPP_AGG_DT_IRB_CUSTOMER_RATINGS` - Customer-level credit ratings and risk parameters
  - `REPP_AGG_DT_IRB_PORTFOLIO_METRICS` - Portfolio-level risk aggregation
  - `REPP_AGG_DT_CUSTOMER_RATING_HISTORY` - Historical rating tracking (SCD Type 2)
  - `REPP_AGG_DT_IRB_RWA_SUMMARY` - Risk Weighted Assets summary
  - `REPP_AGG_DT_IRB_RISK_TRENDS` - Risk parameter trends and model validation

**Key Features:**
- **Basel III/IV Compliance**: IRB approach for regulatory capital calculation
- **Credit Rating System**: Internal rating scale (AAA to CCC) with PD/LGD/EAD
- **RWA Calculation**: Risk Weighted Assets and capital requirements
- **Rating Migrations**: Historical tracking of rating changes and defaults
- **Model Validation**: Backtesting and performance monitoring

### 16. Portfolio Performance Reporting
```sql
-- Execute: Portfolio performance analytics
@530_REPP_PORTFOLIO.sql
```

**Objects Created:**
- **Schema**: `REP_AGG_001`
- **Dynamic Tables** (1 table): 
  - `REPP_AGG_DT_PORTFOLIO_PERFORMANCE` - Integrated cash + equity performance

**Key Features:**
- **Time Weighted Return (TWR)**: Industry-standard performance measurement
- **Multi-Asset Integration**: Combined cash and equity performance
- **Portfolio Allocation**: Cash vs. equity allocation analysis
- **Risk Metrics**: Sharpe Ratio, volatility, max drawdown (placeholders)
- **Performance Classification**: Automated performance categorization
- **Wealth Management**: Client reporting and advisory analytics

### 19. FRTB Market Risk Reporting
```sql
-- Execute: FRTB market risk capital calculations
@525_REPP_FRTB.sql
```

### 20. Business Semantic View
```sql
-- Execute: Unified business-friendly data access
@550_semantic_view.sql
```

**Objects Created:**
- **Semantic View** (1 view):
  - `REPP_SEMANTIC_VIEW` - Unified business-friendly interface to all reporting tables

**Key Features:**
- **Unified Access**: Single view across all reporting domains
- **Business-Friendly**: Simplified column names and descriptions
- **Cross-Domain Analytics**: Combines core, equity, credit risk, FRTB, and portfolio data
- **BI Integration**: Optimized for business intelligence tools
- **Consistent Patterns**: Standardized data access across all business areas

**Prerequisites:**
- All reporting schemas must be deployed first (500-530 series)
- All dynamic tables must be created and refreshed
- This view is deployed last in the sequence

**Objects Created:**
- **Schema**: `REP_AGG_001`
- **Dynamic Tables** (4 tables):
  - `REPP_AGG_DT_FRTB_RISK_POSITIONS` - Consolidated positions by risk class
  - `REPP_AGG_DT_FRTB_SENSITIVITIES` - Delta/Vega/Curvature sensitivities
  - `REPP_AGG_DT_FRTB_CAPITAL_CHARGES` - SA capital charges by risk bucket
  - `REPP_AGG_DT_FRTB_NMRF_ANALYSIS` - Non-Modellable Risk Factor identification

**Key Features:**
- **FRTB Standardized Approach**: Basel III/IV compliant capital calculations
- **Multi-Asset Coverage**: Equity, FX, Interest Rate, Commodity, Credit Spread
- **Risk Sensitivities**: Delta, Vega, and Curvature risk aggregation
- **Capital Requirements**: Risk-weighted capital charges by risk bucket
- **NMRF Identification**: Illiquid position identification and capital add-ons
- **Risk Bucketing**: Granular risk classification per FRTB framework
- **Regulatory Reporting**: Ready for Basel III/IV compliance reporting

**FRTB Risk Classes:**
1. **Equity Risk** - Delta from equity positions (25% risk weight)
2. **FX Risk** - Delta from multi-currency exposures (15% risk weight)
3. **Interest Rate Risk** - Delta and DV01 from bonds/swaps (1.5-3% risk weight)
4. **Commodity Risk** - Delta from commodities (20-35% risk weight by type)
5. **Credit Spread Risk** - From corporate bonds (2-6% risk weight by rating)

## Schema Architecture

### RAW LAYER (Data Ingestion)
| Schema         | Purpose                          | Key Objects                                                    | Refresh Strategy       |
|----------------|----------------------------------|----------------------------------------------------------------|------------------------|
| `CRM_RAW_001`  | Customer Master & Exposed Person | CRMI_PARTY, CRMI_ADDRESSES, CRMI_EXPOSED_PERSON, ACCI_ACCOUNTS | Stream-triggered tasks |
| `REF_RAW_001`  | Reference Data                   | REFI_FX_RATES                                                  | Stream-triggered tasks |
| `PAY_RAW_001`  | Payment Transactions & SWIFT     | PAYI_TRANSACTIONS, ICGI_RAW_SWIFT_MESSAGES                     | Stream-triggered tasks |
| `EQT_RAW_001`  | Equity Trading                   | EQTI_TRADES                                                    | Stream-triggered tasks |
| `FII_RAW_001`  | Fixed Income Trading             | FIII_TRADES                                                    | Serverless tasks (60 min) |
| `CMD_RAW_001`  | Commodity Trading                | CMDI_TRADES                                                    | Serverless tasks (60 min) |

### AGGREGATION LAYER (Business Logic)
| Schema         | Purpose                  | Key Objects                                            | Refresh Strategy      |
|----------------|--------------------------|--------------------------------------------------------|-----------------------|
| `CRM_AGG_001`  | Customer Analytics       | Address SCD Type 2, Customer 360°, Account aggregation | 1-hour dynamic tables |
| `REF_AGG_001`  | Reference Analytics      | FX rates with analytics and volatility metrics         | 1-hour dynamic tables |
| `PAY_AGG_001`  | Payment Analytics        | Anomaly detection, Account balances, SWIFT processing  | 1-hour dynamic tables |
| `EQT_AGG_001`  | Equity Trading Analytics | Portfolio positions, Trade summary, Customer activity  | 1-hour dynamic tables |
| `FII_AGG_001`  | Fixed Income Analytics   | Duration/DV01, Credit exposure, Yield curve            | 1-hour dynamic tables |
| `CMD_AGG_001`  | Commodity Analytics      | Delta exposure, Volatility, Delivery schedule          | 1-hour dynamic tables |
| `REP_AGG_001`  | Reporting & FRTB         | Cross-domain reporting, FRTB capital calculations      | 1-hour dynamic tables |

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
- **Aggregation Tables**: `{DOMAIN}A_AGG_DT_{OBJECT}` (e.g., `ICGA_AGG_DT_SWIFT_PACS008`)
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
