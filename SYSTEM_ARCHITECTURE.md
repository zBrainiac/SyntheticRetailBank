# Synthetic Banking System - Architecture Documentation
**Version**: 2.0  
**Date**: October 11, 2025  
**Status**: Production Ready

---

## Table of Contents
1. [System Overview](#system-overview)
2. [Architecture Layers](#architecture-layers)
3. [Data Flow](#data-flow)
4. [Snowflake Schema Design](#snowflake-schema-design)
5. [Python Data Generation](#python-data-generation)
6. [Integration Points](#integration-points)
7. [Deployment Architecture](#deployment-architecture)
8. [Security & Compliance](#security--compliance)

---

## 1. System Overview

### 1.1 Purpose
Enterprise-grade synthetic banking data platform for:
- **Customer Due Diligence (CDD)** testing
- **Anti-Money Laundering (AML)** detection
- **Churn Prediction** analytics
- **FRTB** (Fundamental Review of Trading Book) compliance
- **Regulatory Reporting** validation

### 1.2 Technology Stack

```
┌─────────────────────────────────────────────────────────────┐
│                    TECHNOLOGY STACK                         │
├─────────────────────────────────────────────────────────────┤
│ Data Warehouse:     Snowflake (Dynamic Tables, Tasks)       │
│ Data Generation:    Python 3.12+ (Faker, NumPy, CSV)        │
│ Version Control:    Git                                     │
│ Deployment:         SnowSQL CLI / Snowflake Web UI          │
│ Documentation:      Markdown, ASCII Diagrams                │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 System Scope

**Data Domains**:
- Customer Master Data (EMEA, 12 countries)
- Account Management
- Payment Transactions
- SWIFT ISO20022 Messages
- Fixed Income Trading (Bonds, Swaps)
- Equity Trading
- Commodity Trading
- FX Rate Management
- PEP (Politically Exposed Persons)
- Customer Lifecycle Events
- Churn Prediction

**Key Metrics**:
- 100+ customers (scalable to 10,000+)
- 1,000+ transactions per month
- 7 lifecycle event types
- 6 lifecycle stages
- 4 trading asset classes

---

## 2. Architecture Layers

### 2.1 Three-Tier Data Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SNOWFLAKE DATA ARCHITECTURE                      │
└─────────────────────────────────────────────────────────────────────┘

Layer 1: RAW DATA INGESTION (RAW_001 Schemas)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  │ CRM_RAW_001  │  │ PAY_RAW_001  │  │ ICG_RAW_001  │
  │              │  │              │  │              │
  │ • Customers  │  │ • Payments   │  │ • SWIFT Msgs │
  │ • Addresses  │  │ • Txns       │  │              │
  │ • Events     │  │              │  │              │
  │ • Status     │  │              │  │              │
  │ • PEP Data   │  │              │  │              │
  └──────────────┘  └──────────────┘  └──────────────┘
           ↓                ↓                 ↓
  
  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  │ EQT_RAW_001  │  │ FII_RAW_001  │  │ CMD_RAW_001  │
  │              │  │              │  │              │
  │ • Equity     │  │ • Bonds      │  │ • Energy     │
  │   Trades     │  │ • IRS Swaps  │  │ • Metals     │
  │              │  │              │  │ • Agri       │
  └──────────────┘  └──────────────┘  └──────────────┘

Layer 2: AGGREGATION (AGG_001 Schemas)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  │ CRM_AGG_001  │  │ PAY_AGG_001  │  │ ACC_AGG_001  │
  │              │  │              │  │              │
  │ • Customer   │  │ • Txn        │  │ • Account    │
  │   360° View  │  │   Anomalies  │  │   Rollups    │
  │ • Address    │  │              │  │              │
  │   SCD Type 2 │  │              │  │              │
  │ • Lifecycle  │  │              │  │              │
  │   Analytics  │  │              │  │              │
  └──────────────┘  └──────────────┘  └──────────────┘
           ↓                ↓                 ↓

Layer 3: REPORTING & ANALYTICS (REP_AGG_001)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ┌───────────────────────────────────────────────────────────────┐
  │                      REP_AGG_001                              │
  │                                                               │
  │  ┌────────────┐  ┌────────────┐  ┌─────────────────────┐      │
  │  │ Customer   │  │ Anomaly    │  │ Lifecycle Anomalies │      │
  │  │ Summary    │  │ Analysis   │  │ (AML Correlation)   │      │
  │  └────────────┘  └────────────┘  └─────────────────────┘      │
  │                                                               │
  │  ┌────────────┐  ┌────────────┐  ┌────────────┐               │
  │  │ FX Risk    │  │ Portfolio  │  │ Credit     │               │
  │  │ Exposure   │  │ Analytics  │  │ Risk       │               │
  │  └────────────┘  └────────────┘  └────────────┘               │
  └───────────────────────────────────────────────────────────────┘
```

### 2.2 Layer Responsibilities

#### Layer 1: RAW (Source of Truth)
- **Purpose**: Immutable source data
- **Pattern**: Append-only, no transformations
- **Loading**: Serverless tasks with stream-based triggers
- **Refresh**: Real-time (on file arrival)

#### Layer 2: AGGREGATION (Business Logic)
- **Purpose**: Single-domain aggregations and transformations
- **Pattern**: Dynamic tables with SCD Type 2
- **Loading**: Auto-refresh from RAW layer
- **Refresh**: 60-minute target lag

#### Layer 3: REPORTING (Cross-Domain Analytics)
- **Purpose**: Multi-domain reporting and ML features
- **Pattern**: Cross-schema joins, complex calculations
- **Loading**: Auto-refresh from AGG layer
- **Refresh**: 60-minute target lag

---

## 3. Data Flow

### 3.1 End-to-End Data Pipeline

```
Python Data Generators              Snowflake Ingestion              Analytics
═══════════════════════            ════════════════════              ═══════════

┌─────────────────┐                ┌─────────────────┐              ┌──────────┐
│ customer_       │   CSV Files    │                 │              │          │
│ generator.py    │───────────────▶│  Internal Stage │              │ Dynamic  │
└─────────────────┘                │  @CRMI_CUSTOMERS│              │ Tables   │
                                   │                 │              │          │
┌─────────────────┐                ├─────────────────┤              │ Auto     │
│ pay_transaction │   CSV Files    │                 │              │ Refresh  │
│ _generator.py   │───────────────▶│  Internal Stage │─────────────▶│ Every    │
└─────────────────┘                │  @PAYI_TXN_STAGE│              │ 60 min   │
                                   │                 │              │          │
┌─────────────────┐                ├─────────────────┤              │          │
│ customer_       │   CSV Files    │                 │              │          │
│ lifecycle_      │───────────────▶│  Internal Stage │              │          │
│ generator.py    │                │  @CRMI_EVENTS   │              │          │
└─────────────────┘                │                 │              │          │
                                   ├─────────────────┤              └──────────┘
┌─────────────────┐                │                 │                    │
│ swift_message_  │   XML Files    │  Internal Stage │                    │
│ generator.py    │───────────────▶│  @ICGI_MESSAGES │                    │
└─────────────────┘                │                 │                    │
                                   └─────────────────┘                    ▼
                                          │                          ┌──────────┐
                                          │                          │          │
                                   ┌──────▼──────┐                   │  BI      │
                                   │             │                   │  Tools   │
                                   │  Streams    │                   │          │
                                   │  Detect     │                   │ • Churn  │
                                   │  New Files  │                   │   Model  │
                                   │             │                   │ • AML    │
                                   └──────┬──────┘                   │   Alerts │
                                          │                          │ • Risk   │
                                          │                          │   Dashbd │
                                   ┌──────▼──────┐                   │          │
                                   │             │                   └──────────┘
                                   │ Serverless  │
                                   │ Tasks       │
                                   │ (XSMALL)    │
                                   │             │
                                   │ COPY INTO   │
                                   │ Tables      │
                                   │             │
                                   └─────────────┘
```

### 3.2 Customer Lifecycle Data Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│              CUSTOMER LIFECYCLE EVENT PIPELINE                           │
└──────────────────────────────────────────────────────────────────────────┘

Step 1: Data Generation (Python)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ┌──────────────────┐          ┌──────────────────┐
  │ customer_        │          │ address_update_  │
  │ generator.py     │          │ generator.py     │
  │                  │          │                  │
  │ Creates:         │          │ Creates:         │
  │ • customers.csv  │          │ • address_       │
  │ • ONBOARDING_    │          │   updates/*.csv  │
  │   DATE per       │          │ • Timestamps     │
  │   customer       │          │                  │
  └────────┬─────────┘          └────────┬─────────┘
           │                             │
           └─────────────┬───────────────┘
                         ▼
           ┌──────────────────────────────┐
           │ customer_lifecycle_          │
           │ generator.py                 │
           │                              │
           │ Phase 1: Data-Driven Events  │
           │ • ONBOARDING (from customer) │
           │ • ADDRESS_CHANGE (from addr) │
           │                              │
           │ Phase 2: Random Events       │
           │ • EMPLOYMENT_CHANGE          │
           │ • ACCOUNT_UPGRADE            │
           │ • ACCOUNT_CLOSE              │
           │ • REACTIVATION               │
           │ • CHURN                      │
           │                              │
           │ Generates:                   │
           │ • customer_events.csv        │
           │ • customer_status.csv        │
           └──────────────┬───────────────┘
                          │
                          ▼

Step 2: Snowflake Ingestion
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

           ┌──────────────────────────────┐
           │ @CRMI_CUSTOMER_EVENTS Stage  │
           │                              │
           │ PUT customer_events.csv      │
           │ PUT customer_status.csv      │
           └──────────────┬───────────────┘
                          │
                   ┌──────▼──────┐
                   │   Streams   │
                   │   Detect    │
                   │   Files     │
                   └──────┬──────┘
                          │
              ┌───────────┴────────────┐
              ▼                        ▼
   ┌──────────────────┐    ┌──────────────────┐
   │ CRMI_TASK_LOAD_  │    │ CRMI_TASK_LOAD_  │
   │ CUSTOMER_EVENTS  │    │ CUSTOMER_STATUS  │
   │                  │    │                  │
   │ Serverless       │    │ Serverless       │
   │ Schedule: 5 min  │    │ Schedule: 5 min  │
   └────────┬─────────┘    └────────┬─────────┘
            │                       │
            ▼                       ▼
   ┌──────────────────┐    ┌──────────────────┐
   │ CRMI_CUSTOMER_   │    │ CRMI_CUSTOMER_   │
   │ EVENT            │    │ STATUS           │
   │                  │    │                  │
   │ RAW Layer Table  │    │ RAW Layer Table  │
   │ Append-Only      │    │ SCD Type 2       │
   └────────┬─────────┘    └────────┬─────────┘
            │                       │
            └───────────┬───────────┘
                        ▼

Step 3: Aggregation Layer
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ┌────────────────────────────────────────────────┐
   │ CRMA_AGG_DT_CUSTOMER_LIFECYCLE                 │
   │                                                │
   │ Dynamic Table (Auto-Refresh 60 min)            │
   │                                                │
   │ Combines:                                      │
   │ • Customer master data                         │
   │ • Current status (from CRMI_CUSTOMER_STATUS)   │
   │ • Lifecycle events (from CRMI_CUSTOMER_EVENT)  │
   │ • Transaction activity (from PAYI_TRANSACTIONS)│
   │                                                │
   │ Calculates:                                    │
   │ • LIFECYCLE_STAGE (6 stages)                   │
   │ • CHURN_PROBABILITY (0-100%)                   │
   │ • IS_DORMANT (>180 days inactive)              │
   │ • IS_AT_RISK (>90 days inactive)               │
   │ • Event type counts                            │
   └────────────────────┬───────────────────────────┘
                        │
                        ▼

Step 4: Reporting Layer
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ┌────────────────────────────────────────────────┐
   │ REPP_AGG_DT_LIFECYCLE_ANOMALIES                │
   │                                                │
   │ Dynamic Table (Auto-Refresh 60 min)            │
   │                                                │
   │ Correlates:                                    │
   │ • Lifecycle events (REACTIVATION, etc.)        │
   │ • Transaction anomalies (from PAY_AGG_001)     │
   │ • Dormancy periods                             │
   │                                                │
   │ Identifies:                                    │
   │ • SAR filing candidates                        │
   │ • AML risk levels                              │
   │ • Suspicious patterns                          │
   │ • 30-day correlation window                    │
   └────────────────────┬───────────────────────────┘
                        │
                        ▼
             ┌──────────────────┐
             │                  │
             │  BI Tools /      │
             │  ML Models       │
             │                  │
             │  • Churn Pred    │
             │  • AML Alerts    │
             │  • Retention     │
             │                  │
             └──────────────────┘
```

---

## 4. Snowflake Schema Design

### 4.1 Complete Schema Inventory

```
DATABASE: AAA_DEV_SYNTHETIC_BANK
════════════════════════════════════════════════════════════════════

SCHEMA: CRM_RAW_001 (Customer Relationship Management - Raw)
────────────────────────────────────────────────────────────────────
Tables (5):
  • CRMI_CUSTOMER              - Customer master data
  • CRMI_ADDRESSES             - Address history (append-only)
  • CRMI_EXPOSED_PERSON        - PEP data
  • CRMI_CUSTOMER_EVENT        - Lifecycle event log (7 event types)
  • CRMI_CUSTOMER_STATUS       - Status history (SCD Type 2)

Stages (4):
  • CRMI_CUSTOMERS
  • CRMI_ADDRESSES
  • CRMI_EXPOSED_PERSON
  • CRMI_CUSTOMER_EVENTS

Tasks (5 - All Serverless):
  • CRMI_TASK_LOAD_CUSTOMERS
  • CRMI_TASK_LOAD_ADDRESSES
  • CRMI_TASK_LOAD_EXPOSED_PERSON
  • CRMI_TASK_LOAD_CUSTOMER_EVENTS
  • CRMI_TASK_LOAD_CUSTOMER_STATUS

────────────────────────────────────────────────────────────────────

SCHEMA: CRM_AGG_001 (Customer - Aggregation)
────────────────────────────────────────────────────────────────────
Dynamic Tables (4):
  • CRMA_AGG_DT_ADDRESSES_CURRENT  - Latest address per customer
  • CRMA_AGG_DT_ADDRESSES_HISTORY  - Full SCD Type 2 address history
  • CRMA_AGG_DT_CUSTOMER           - 360° customer view + status
  • CRMA_AGG_DT_CUSTOMER_LIFECYCLE - Lifecycle analytics & churn

────────────────────────────────────────────────────────────────────

SCHEMA: ACC_RAW_001 (Accounts - Raw)
────────────────────────────────────────────────────────────────────
Tables (1):
  • ACCI_ACCOUNTS              - Account master data

────────────────────────────────────────────────────────────────────

SCHEMA: ACC_AGG_001 (Accounts - Aggregation)
────────────────────────────────────────────────────────────────────
Dynamic Tables (1):
  • ACCA_AGG_DT_ACCOUNTS       - Account aggregations

────────────────────────────────────────────────────────────────────

SCHEMA: PAY_RAW_001 (Payments - Raw)
────────────────────────────────────────────────────────────────────
Tables (1):
  • PAYI_TRANSACTIONS          - Payment transactions

────────────────────────────────────────────────────────────────────

SCHEMA: PAY_AGG_001 (Payments - Aggregation)
────────────────────────────────────────────────────────────────────
Dynamic Tables (1):
  • PAYA_AGG_DT_TRANSACTION_ANOMALIES - Anomaly detection

────────────────────────────────────────────────────────────────────

SCHEMA: ICG_RAW_001 (Incoming Payments - Raw)
────────────────────────────────────────────────────────────────────
Tables (1):
  • ICGI_SWIFT_MESSAGES        - SWIFT ISO20022 messages

────────────────────────────────────────────────────────────────────

SCHEMA: EQT_RAW_001 (Equity - Raw)
────────────────────────────────────────────────────────────────────
Tables (1):
  • EQTI_TRADES                - Equity trade data

────────────────────────────────────────────────────────────────────

SCHEMA: FII_RAW_001 (Fixed Income - Raw)
────────────────────────────────────────────────────────────────────
Tables (1):
  • FIII_TRADES                - Bond and swap trades

────────────────────────────────────────────────────────────────────

SCHEMA: CMD_RAW_001 (Commodity - Raw)
────────────────────────────────────────────────────────────────────
Tables (1):
  • CMDI_TRADES                - Commodity trades

────────────────────────────────────────────────────────────────────

SCHEMA: REF_RAW_001 (Reference Data - Raw)
────────────────────────────────────────────────────────────────────
Tables (1):
  • REFI_FX_RATES              - FX rate time series

────────────────────────────────────────────────────────────────────

SCHEMA: REP_AGG_001 (Reporting - Cross-Domain Analytics)
────────────────────────────────────────────────────────────────────
Dynamic Tables (10):
  • REPP_AGG_DT_CUSTOMER_SUMMARY
  • REPP_AGG_DT_DAILY_TRANSACTION_SUMMARY
  • REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT
  • REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY
  • REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE
  • REPP_AGG_DT_ANOMALY_ANALYSIS
  • REPP_AGG_DT_HIGH_RISK_PATTERNS
  • REPP_AGG_DT_SETTLEMENT_ANALYSIS
  • REPP_AGG_DT_LIFECYCLE_ANOMALIES - AML lifecycle correlation
  • (Additional tables in 510, 520, 525, 530 files)
```

### 4.2 Key Table Relationships

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ENTITY RELATIONSHIP DIAGRAM                      │
└─────────────────────────────────────────────────────────────────────┘

                    ┌──────────────────┐
                    │ CRMI_CUSTOMER    │
                    │ ──────────────── │
                    │ PK: CUSTOMER_ID  │
                    │                  │
                    │ • first_name     │
                    │ • family_name    │
                    │ • date_of_birth  │
                    │ • onboarding_dt  │
                    └────────┬─────────┘
                             │
                             │ 1
                  ┌──────────┼──────────────────────┐
                  │          │                      │
                * │        * │                    * │
      ┌───────────▼──────┐ ┌▼──────────────────┐ ┌▼──────────────────┐
      │ CRMI_ADDRESSES   │ │ CRMI_CUSTOMER_    │ │ CRMI_CUSTOMER_    │
      │ ──────────────── │ │ EVENT             │ │ STATUS            │
      │ FK: CUSTOMER_ID  │ │ ───────────────── │ │ ───────────────── │
      │                  │ │ PK: EVENT_ID      │ │ PK: STATUS_ID     │
      │ • street_address │ │ FK: CUSTOMER_ID   │ │ FK: CUSTOMER_ID   │
      │ • city, state    │ │                   │ │                   │
      │ • insert_ts_utc  │ │ • event_type      │ │ • status          │
      │   (SCD Type 2)   │ │ • event_date      │ │ • start_date      │
      └──────────────────┘ │ • event_details   │ │ • end_date        │
                           │   (JSON/VARIANT)  │ │ • is_current      │
                           └───────────────────┘ └───────────────────┘
      │
      │ 1
    * │
      ┌──────────────────┐
      │ ACCI_ACCOUNTS    │
      │ ──────────────── │
      │ PK: ACCOUNT_ID   │
      │ FK: CUSTOMER_ID  │
      │                  │
      │ • account_type   │
      │ • base_currency  │
      └────────┬─────────┘
               │ 1
             * │
      ┌────────▼─────────┐
      │ PAYI_TRANSACTIONS│
      │ ──────────────── │
      │ PK: TRANSACTION  │
      │     _ID          │
      │ FK: CUSTOMER_ID  │
      │ FK: ACCOUNT_ID   │
      │                  │
      │ • amount         │
      │ • booking_date   │
      │ • description    │
      └──────────────────┘
```

---

## 5. Python Data Generation

### 5.1 Generator Modules

```
┌────────────────────────────────────────────────────────────────┐
│              PYTHON DATA GENERATOR ARCHITECTURE                │
└────────────────────────────────────────────────────────────────┘

Main Orchestrator:
┌─────────────────────────────────────────────────────────────────┐
│ main.py                                                         │
│                                                                 │
│ • Command-line interface (argparse)                             │
│ • Configuration management                                      │
│ • Generator orchestration                                       │
│ • Summary report generation                                     │
│ • Error handling and logging                                    │
└─────────────────────────────────────────────────────────────────┘

Core Generators:
┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│ customer_      │  │ pay_transaction│  │ account_       │
│ generator.py   │  │ _generator.py  │  │ generator.py   │
│                │  │                │  │                │
│ • EMEA locale  │  │ • Anomaly      │  │ • 4 types      │
│ • 12 countries │  │   patterns     │  │ • Multi-       │
│ • Faker lib    │  │ • Date ranges  │  │   currency     │
└────────────────┘  └────────────────┘  └────────────────┘

Specialized Generators:
┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│ address_update_│  │ customer_      │  │ pep_           │
│ generator.py   │  │ lifecycle_     │  │ generator.py   │
│                │  │ generator.py   │  │                │
│ • SCD Type 2   │  │                │  │ • PEP data     │
│ • Time-series  │  │ • 7 event types│  │ • Risk levels  │
│ • Multi-file   │  │ • 2-phase gen  │  │ • Categories   │
└────────────────┘  └────────────────┘  └────────────────┘

Trading Generators:
┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│ equity_        │  │ fixed_income_  │  │ commodity_     │
│ generator.py   │  │ generator.py   │  │ generator.py   │
│                │  │                │  │                │
│ • Stock trades │  │ • Bonds        │  │ • Energy       │
│ • Market data  │  │ • IRS swaps    │  │ • Metals       │
│                │  │ • FRTB data    │  │ • Agricultural │
└────────────────┘  └────────────────┘  └────────────────┘

Message Generators:
┌────────────────┐  ┌────────────────┐
│ swift_         │  │ mortgage_email_│
│ generator.py   │  │ generator.py   │
│                │  │                │
│ • ISO20022     │  │ • PDF emails   │
│ • XML format   │  │ • Templates    │
│ • Parallel proc│  │                │
└────────────────┘  └────────────────┘

Utility Modules:
┌────────────────┐  ┌────────────────┐
│ config.py      │  │ base_generator │
│                │  │ .py            │
│ • GeneratorCfg │  │                │
│ • Constants    │  │ • Base class   │
└────────────────┘  └────────────────┘
```

### 5.2 Customer Lifecycle Generator Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│         CUSTOMER_LIFECYCLE_GENERATOR.PY (650+ lines)             │
└──────────────────────────────────────────────────────────────────┘

Class: CustomerLifecycleGenerator
──────────────────────────────────────────────────────────────────

Data Model:
  ┌─────────────────────┐  ┌─────────────────────┐
  │ LifecycleEvent      │  │ CustomerStatus      │
  │ ─────────────────── │  │ ─────────────────── │
  │ • event_id          │  │ • status_id         │
  │ • customer_id       │  │ • customer_id       │
  │ • event_type        │  │ • status            │
  │ • event_date        │  │ • start_date        │
  │ • event_timestamp   │  │ • end_date          │
  │ • channel           │  │ • is_current        │
  │ • event_details     │  │ • linked_event_id   │
  │   (JSON)            │  │                     │
  │ • previous_value    │  └─────────────────────┘
  │ • new_value         │
  │ • triggered_by      │
  │ • requires_review   │
  │ • review_status     │
  │ • notes             │
  └─────────────────────┘

Generation Pipeline:
──────────────────────────────────────────────────────────────────

Phase 1: Data-Driven Events (Cannot be randomly generated)
  │
  ├─▶ generate_onboarding_events()
  │   • Source: CRMI_CUSTOMER.ONBOARDING_DATE
  │   • One event per customer
  │   • Channel: ONLINE/BRANCH/MOBILE
  │   • Includes initial deposit, KYC
  │
  └─▶ generate_address_change_events()
      • Source: address_update_generator.py outputs
      • ⚠️ CRITICAL: Uses EXACT timestamps from CSV files
      • One-to-one mapping with address updates
      • Includes old/new address in JSON

Phase 2: Random Event Generation
  │
  ├─▶ generate_random_events()
  │   • Number of events per customer: 0-3 (weighted)
  │   • Time deltas: 30-900 days (normal dist, mean=180)
  │   • Constraints:
  │     - NO events for dormant customers
  │     - ONLY REACTIVATION for closed customers
  │
  └─▶ Event Types (weighted random selection):
      │
      ├─▶ EMPLOYMENT_CHANGE (40%)
      │   • Old/new employer, position, income change
      │
      ├─▶ ACCOUNT_UPGRADE (30%)
      │   • Tier upgrade, benefits, fees
      │
      ├─▶ ACCOUNT_CLOSE (15%)
      │   • Closure reason, final balance
      │
      ├─▶ REACTIVATION (10%)
      │   • Reactivation reason, dormancy period
      │
      └─▶ CHURN (5%)
          • Churn reason, retention attempts

Status History Generation:
  │
  └─▶ generate_customer_status_history()
      • SCD Type 2 implementation
      • Initial status: ACTIVE (at onboarding)
      • Status changes triggered by:
        - ACCOUNT_CLOSE → CLOSED
        - CHURN → CLOSED
        - REACTIVATION → REACTIVATED
      • Previous status closed with end_date
      • New status created with is_current=TRUE

Output Files:
  │
  ├─▶ customer_events.csv
  │   • All lifecycle events (ONBOARDING → CHURN)
  │   • JSON event_details with event-specific data
  │   • Channel and triggered_by tracking
  │
  └─▶ customer_status.csv
      • SCD Type 2 status history
      • Linked to triggering events
      • Current status flagged (is_current=TRUE)

Key Constraints:
  • ⚠️ ADDRESS_CHANGE: NEVER randomly generated
  • ⚠️ Timestamps MUST match address_update_generator.py
  • ⚠️ Dormant customers: NO events during dormancy
  • ⚠️ Event sequencing: Realistic time deltas
```

---

## 6. Integration Points

### 6.1 External System Integration

```
┌────────────────────────────────────────────────────────────────┐
│                  EXTERNAL INTEGRATIONS                         │
└────────────────────────────────────────────────────────────────┘

Data Exchange:
┌──────────────────────────────────────────────────────────────┐
│ AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET_COPY│
│                                                              │
│ • Global Sanctions Data                                      │
│ • Fuzzy name matching                                        │
│ • CRMA_AGG_DT_CUSTOMER joins for screening                   │
└──────────────────────────────────────────────────────────────┘

File Upload:
┌──────────────────────────────────────────────────────────────┐
│ SnowSQL CLI / Python Connector                               │
│                                                              │
│ • PUT command for CSV/XML uploads                            │
│ • Automatic file detection via streams                       │
│ • Serverless task execution                                  │
└──────────────────────────────────────────────────────────────┘

BI Tools:
┌──────────────────────────────────────────────────────────────┐
│ Tableau / Power BI / Snowsight                               │
│                                                              │
│ • Direct query to REP_AGG_001 dynamic tables                 │
│ • Churn prediction dashboards                                │
│ • AML alert monitoring                                       │
└──────────────────────────────────────────────────────────────┘
```

### 6.2 Data Synchronization

```
Critical Synchronization Points:
──────────────────────────────────────────────────────────────

1. Address Changes ← → Lifecycle Events
   ┌──────────────────────┐        ┌──────────────────────┐
   │ CRMI_ADDRESSES       │        │ CRMI_CUSTOMER_EVENT  │
   │                      │        │                      │
   │ INSERT_TIMESTAMP_UTC │◀──────▶│ EVENT_TIMESTAMP_UTC  │
   │                      │  MUST  │ (for ADDRESS_CHANGE) │
   │ (from generator)     │  MATCH │ (from generator)     │
   └──────────────────────┘        └──────────────────────┘
   
   ⚠️ CRITICAL: ADDRESS_CHANGE events must use exact timestamps
                from address_update_generator.py outputs

2. Lifecycle Events → Churn Prediction
   ┌──────────────────────┐        ┌──────────────────────┐
   │ PAYI_TRANSACTIONS    │        │ CRMA_AGG_DT_CUSTOMER_│
   │                      │        │ LIFECYCLE            │
   │ LAST_BOOKING_DATE    │──────▶ │                      │
   │                      │ Drives │ CHURN_PROBABILITY    │
   │ (transaction-based)  │  NOT   │ (NOT event-based)    │
   └──────────────────────┘  ◀──── └──────────────────────┘
   
   ℹ️ NOTE: Churn model uses transaction inactivity, not event frequency
            because dormant customers have NO events by definition

3. Lifecycle Events → AML Correlation
   ┌──────────────────────┐        ┌──────────────────────┐
   │ CRMI_CUSTOMER_EVENT  │        │ PAYA_AGG_DT_         │
   │                      │        │ TRANSACTION_ANOMALIES│
   │ EVENT_DATE           │◀──────▶│ BOOKING_DATE         │
   │                      │ 30-day │                      │
   │ (REACTIVATION, etc.) │ window │ (anomalies)          │
   └──────────────────────┘        └──────────────────────┘
   
   ℹ️ REPP_AGG_DT_LIFECYCLE_ANOMALIES correlates high-risk
      lifecycle events with suspicious transactions
```

---

## 7. Deployment Architecture

### 7.1 Deployment Topology

```
┌───────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT ARCHITECTURE                        │
└───────────────────────────────────────────────────────────────────┘

Development Environment:
┌─────────────────────────────────────────────────────────────────┐
│ Local Development                                               │
│ ─────────────────                                               │
│                                                                 │
│  ┌────────────────┐     ┌────────────────┐                      │
│  │ Python 3.12+   │     │ Git Repository │                      │
│  │ Virtual Env    │     │ (Version Ctrl) │                      │
│  └────────────────┘     └────────────────┘                      │
│           │                       │                             │
│           └───────────┬───────────┘                             │
│                       │                                         │
│              ┌────────▼─────────┐                               │
│              │ Generated CSV/   │                               │
│              │ XML Files        │                               │
│              └────────┬─────────┘                               │
│                       │                                         │
└───────────────────────┼─────────────────────────────────────────┘
                        │
                        │ SnowSQL PUT / Upload
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│ Snowflake Cloud                                                 │
│ ────────────────                                                │
│                                                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ AAA_DEV_SYNTHETIC_BANK Database                            │ │
│  │                                                            │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │ │
│  │  │ Internal     │  │ Serverless   │  │ Dynamic      │      │ │
│  │  │ Stages       │→ │ Tasks        │→ │ Tables       │      │ │
│  │  │              │  │              │  │              │      │ │
│  │  │ Auto-Ingest  │  │ Stream-based │  │ Auto-Refresh │      │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘      │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │ Compute: MD_TEST_WH (XSMALL)                         │  │ │
│  │  │ • Used by Dynamic Tables                             │  │ │
│  │  │ • Auto-suspend: 5 minutes                            │  │ │
│  │  │ • Auto-resume: Enabled                               │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                        │
                        │ ODBC / JDBC / Snowpark
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│ Business Intelligence Layer                                     │
│ ───────────────────────────                                     │
│                                                                 │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐     │
│  │ Snowsight      │  │ Tableau        │  │ Power BI       │     │
│  │                │  │                │  │                │     │
│  │ • SQL queries  │  │ • Dashboards   │  │ • Reports      │     │
│  │ • Dashboards   │  │ • Visual       │  │ • Visual       │     │
│  └────────────────┘  └────────────────┘  └────────────────┘     │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐     │
│  │ ML / AI Layer                                          │     │
│  │                                                        │     │
│  │ • Snowpark ML (Churn Prediction)                       │     │
│  │ • Python UDF (Custom Models)                           │     │
│  │ • AML Alert Engine                                     │     │
│  └────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```



---

## 8. Security & Compliance

### 8.1 Data Classification

```
┌───────────────────────────────────────────────────────────────────┐
│              DATA SENSITIVITY CLASSIFICATION                      │
└───────────────────────────────────────────────────────────────────┘

Tag: SENSITIVITY_LEVEL (Snowflake Tag)
──────────────────────────────────────────────────────────────────

Top Secret:
  • CRMI_CUSTOMER.CUSTOMER_ID
  • CRMI_CUSTOMER_CONTACT.CONTACT_VALUE (addresses, emails, phones)
  • PAYI_TRANSACTIONS.TRANSACTION_ID

Restricted:
  • CRMI_CUSTOMER.FIRST_NAME
  • CRMI_CUSTOMER.FAMILY_NAME
  • CRMI_CUSTOMER.DATE_OF_BIRTH
  • CRMI_CUSTOMER.HAS_ANOMALY
  • CRMI_CUSTOMER_EVENT.NOTES (free-text lifecycle notes)

Public:
  • REFI_FX_RATES (all fields)
  • Reference data


**End of System Architecture Documentation**

