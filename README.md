# Synthetic Retail Bank

A showcase demonstrating risk management and governance challenges faced by modern retail banks in the Europe (EMEA) region. This synthetic bank environment illustrates real-world scenarios including anti-money laundering compliance, transaction monitoring, customer due diligence, and regulatory reporting requirements that financial institutions must navigate daily.

## Business-Relevant Overview

| Original Section                      | Simplified & Business-Centric Description                                                                                                                                                                                                                                                                                                              |
|---------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Compliance & Regulatory Risk          | **Financial Crime Prevention & Oversight**: Focuses on meeting mandatory legal obligations for Anti-Money Laundering (AML), identifying Politically Exposed Persons (PEP), and ensuring accurate regulatory reporting (e.g., GDPR, MiFID II). The core purpose is to prevent financial crime and avoid regulatory fines.                               |
| Credit Risk Management & IRB Approach | **Capital Adequacy & Lending Risk**: Simulates the advanced approach (IRB) for calculating the bank's regulatory capital reserves (Risk Weighted Assets - RWA) based on the likelihood of customer defaults (PD, LGD, EAD). The core purpose is to ensure financial stability and solvency.                                                            |
| Operational Risk Management           | **Day-to-Day Business Resilience**: Covers risks arising from execution failure, system failure, or external events. Focuses on real-time transaction monitoring, managing settlement/counterparty risk, and ensuring robust data governance (e.g., customer audit trails). The core purpose is to maintain service quality and operational stability. |
| Financial Crime Prevention            | **Anomaly Detection & Fraud Control**: A practical layer of defense against money laundering and fraud, using behavioral baselines to detect high-risk patterns like structuring, large-value trades, and suspicious cross-border activity. The core purpose is to protect the bank's assets and reputation.                                           |
| Key Capabilities                      | **Data Utility for GRC (Governance, Risk, Compliance)**: The generated data is engineered for specific validation tasks, including testing vendor RegTech systems, calibrating internal risk scoring models, and providing an auditable, end-to-end data lineage for regulatory examiners.                                                             |


## Key Capabilities

### **Customer Risk & Compliance Management**
- **Multi-Jurisdictional Customer Base**: EMEA customers across 12 countries with localized compliance requirements
- **Dynamic Risk Scoring**: Behavioral profiling with CRITICAL, HIGH, MODERATE, NORMAL risk classifications
- **PEP Screening & Monitoring**: Politically Exposed Persons identification with fuzzy name matching algorithms
- **Customer 360° Risk View**: Comprehensive profiles integrating master data, transaction history, lifecycle events, and compliance status
- **Enhanced Due Diligence**: Automated triggers for high-risk customer segments and suspicious behavior patterns
- **Customer Lifecycle Analytics**: Event tracking (onboarding, address changes, employment changes, account upgrades, closures, reactivations, churn)
- **Churn Prediction**: ML-ready dataset with churn probability scoring (0-100%) based on transaction inactivity and lifecycle patterns
- **Lifecycle Event Correlation**: AML detection correlating lifecycle events with transaction anomalies for SAR filing recommendations

### **Transaction Monitoring & AML**
- **Real-Time Anomaly Detection**: Multi-dimensional behavioral analysis using statistical scoring models
- **Suspicious Pattern Recognition**: Detection of structuring, layering, and integration money laundering techniques
- **Cross-Border Payment Surveillance**: Multi-currency transaction monitoring with enhanced controls
- **Trade-Based Money Laundering Detection**: Equity trading pattern analysis for unusual investment behaviors
- **Regulatory Alert Generation**: Automated suspicious activity report (SAR) triggers and case management

### **Investment Performance & Portfolio Analytics**
- **Time Weighted Return (TWR)**: Industry-standard investment performance measurement eliminating cash flow timing effects
- **Risk-Adjusted Returns**: Sharpe ratio calculation for portfolio performance evaluation
- **Volatility Analysis**: Standard deviation of returns for risk assessment and client suitability
- **Maximum Drawdown**: Peak-to-trough decline tracking for downside risk management
- **Portfolio Attribution**: Account-level and customer-level performance aggregation and analysis

### **Governance & Audit Controls**
- **Complete Audit Trail**: SCD Type 2 address tracking and comprehensive transaction history
- **Data Lineage & Quality**: End-to-end data governance with validation and reconciliation controls
- **Regulatory Reporting**: GDPR, MiFID II, Basel III, and PSD2 compliant data structures and processes
- **Risk Appetite Monitoring**: Configurable thresholds and escalation procedures for risk limit breaches
- **Management Information**: Executive dashboards and regulatory reporting with drill-down capabilities
- **Data Sensitivity Classification**: Automated PII protection using Snowflake sensitivity tags and masking policies

### **Credit Risk & Capital Management Framework**
- **IRB Capital Adequacy**: Basel III/IV compliant Internal Ratings Based approach for regulatory capital
- **Credit Risk Parameters**: PD, LGD, EAD modeling with exposure-weighted portfolio aggregation
- **Risk Weighted Assets**: Automated RWA calculation and regulatory capital requirement monitoring
- **Credit Rating Systems**: Internal rating scales (AAA-CCC) with default identification and watch list management
- **Rating History & Migrations**: SCD Type 2 historical tracking of credit ratings with daily snapshots for trend analysis
- **Default Tracking**: Real-time monitoring of new defaults, cured defaults, and net default changes
- **Portfolio Risk Management**: Credit concentration analysis, vintage tracking, and collateral coverage monitoring
- **Model Validation**: IRB model backtesting, performance monitoring with actual vs. predicted default rates, and stress testing capabilities

### **BCBS 239 Risk Data Aggregation & Reporting**
- **Comprehensive Risk Aggregation**: Multi-dimensional risk data aggregation across all business lines and risk types
- **Executive Risk Dashboards**: Real-time executive risk monitoring with key risk indicators and portfolio metrics
- **Regulatory Reporting**: BCBS 239 compliant regulatory reporting capabilities with data quality metrics
- **Risk Concentration Analysis**: Real-time risk concentration monitoring and breach detection
- **Risk Limit Monitoring**: Automated risk limit monitoring with utilization tracking and alert management
- **Data Quality Governance**: Comprehensive data quality monitoring with completeness, accuracy, and timeliness metrics
- **Regulatory Compliance**: Basel III/IV compliance reporting with capital adequacy and risk coverage analysis
- **IT Infrastructure Monitoring**: System performance, data processing times, and infrastructure health metrics

### **FRTB Market Risk Framework**
- **Multi-Asset Coverage**: Equity, FX, interest rate, commodity, and credit spread risk classes
- **Interest Rate Risk**: Government and corporate bonds with duration, DV01, and credit spread calculations
- **Commodity Risk**: Energy (crude oil, natural gas), precious metals (gold, silver), base metals (copper, aluminum), and agricultural commodities
- **Risk Sensitivities**: Delta, vega, and curvature risk calculations for FRTB Standardized Approach (SA)
- **Liquidity Classification**: Liquidity scores for Non-Modellable Risk Factor (NMRF) identification
- **Capital Requirements**: FRTB SA capital charge calculations with correlation benefits across risk buckets
- **Trading Book Analytics**: Position aggregation, P&L attribution, and desk-level risk metrics
- **Regulatory Compliance**: Basel III/IV FRTB framework implementation with standardized risk bucketing

### **Operational Risk Framework**
- **Settlement Risk Management**: Payment timing analysis and counterparty exposure monitoring
- **Concentration Risk**: Customer, geographic, and currency exposure analysis with limit monitoring
- **Model Risk Management**: Statistical model validation and performance monitoring for anomaly detection
- **Business Continuity**: Scenario analysis and stress testing capabilities for operational resilience
- **Third-Party Risk**: Counterparty due diligence and ongoing monitoring of external relationships

## Data Sensitivity Classification

The synthetic bank implements a focused data protection strategy using Snowflake sensitivity tags to automatically protect highly sensitive PII and financial data.

### **Implementation Approach**
- **Single Tag**: `SENSITIVITY_LEVEL` with key/value pairs
- **Focus**: Only tag highly sensitive PII and financial data requiring protection
- **Values**: `'restricted'` and `'top_secret'` only
- **Non-sensitive data**: Left untagged for business operations

### **Sensitivity Categories**

#### **RESTRICTED** - Highly sensitive PII data
- Personal Identifiable Information (PII)
- Financial amounts and balances
- Risk assessments and credit ratings
- Transaction descriptions and counterparty data
- Trading quantities and amounts

#### **TOP_SECRET** - Maximum protection
- Full customer names and addresses
- PEP (Politically Exposed Person) data
- Street addresses and personal identifiers
- Complete personal information

### **Potencial Role-Based Access Control**

| Role | Untagged | RESTRICTED | TOP_SECRET |
|------|----------|------------|------------|
| **PUBLIC_USER** | Yes | No | No |
| **BUSINESS_USER** | Yes | No | No |
| **ANALYST** | Yes | Yes | No |
| **SENIOR_ANALYST** | Yes | Yes | No |
| **RISK_MANAGER** | Yes | Yes | Yes |
| **COMPLIANCE_OFFICER** | Yes | Yes | Yes |
| **DATA_SCIENTIST** | Yes | Yes | Yes |

### **Key Benefits**
- **Focused Protection**: Only tag highly sensitive PII data that requires protection
- **Business Efficiency**: Untagged columns remain fully accessible for business operations
- **Automated Security**: Tagged columns automatically protected by masking policies
- **Compliance Ready**: GDPR, CCPA, and Basel III compliant data protection

## What

This repository delivers a complete data generation and ingestion framework, organized into two core components: 
- Data Generators (the synthetic data source)
- Domain-Oriented DDL (the target schema and transformation structure).

### Data Generators

| Generator                          | Description                                                                                  |
|------------------------------------|----------------------------------------------------------------------------------------------|
| **`customer_generator.py`**        | EMEA customer master data with localized names, addresses, and onboarding dates              |
| **`pay_transaction_generator.py`** | Multi-currency payment transactions with realistic settlement patterns and anomaly injection |
| **`equity_generator.py`**          | FIX protocol-compliant equity trades with market data and commission calculations            |
| **`fixed_income_generator.py`**    | Fixed income trades (government/corporate bonds, interest rate swaps) with duration & DV01   |
| **`commodity_generator.py`**       | Commodity trades (energy, metals, agricultural) with delta risk and volatility metrics       |
| **`fx_generator.py`**              | Daily foreign exchange rates with bid/ask spreads for multi-currency support                 |
| **`swift_generator.py`**           | ISO20022 SWIFT message generation (pacs.008, pacs.002) for cross-border payments             |
| **`mortgage_email_generator.py`**  | Realistic mortgage application email threads (customer, internal, loan officer)              |
| **`pep_generator.py`**             | Politically Exposed Persons reference data with fuzzy matching capabilities                  |
| **`address_update_generator.py`**  | SCD Type 2 address change files for data governance and audit trails                         |
| **`customer_lifecycle_generator.py`** | Customer lifecycle events (onboarding, address changes, employment changes, account upgrades, closures, reactivations, churn) and status history (SCD Type 2) for churn prediction and lifecycle analytics |
| **`anomaly_patterns.py`**          | Suspicious transaction pattern injection for AML testing and training                        |

### External Data Integration

| Component                          | Description                                                                                  |
|------------------------------------|----------------------------------------------------------------------------------------------|
| **`001_get_listings.sql`**         | Snowflake Data Exchange setup for Global Sanctions Data - real-time compliance screening    |
| **Global Sanctions Data**          | External sanctions and watchlist data from Snowflake Data Exchange marketplace              |
| **PEP Enhancement**                | Integration with Politically Exposed Persons screening for regulatory compliance             |
| **Compliance Support**             | Real-time sanctions checking for customer onboarding and transaction monitoring             |

### Domain-Oriented DDL (`structure/` directory)
- **Raw Data Layer (0xx)**: Customer master (`CRMI`), accounts (`ACCI`), FX rates (`REFI`), payments (`PAYI`), equity trades (`EQTI`), SWIFT messages (`ICGI`), loan documents (`LOAI`)
- **Aggregation Layer (3xx)**: Customer 360° views (`CRMA`), account balances (`ACCA`), payment anomalies (`PAYA`), investment performance (`PAYA`), SWIFT processing (`ICGA`)
- **Reporting Layer (5xx)**: Risk analytics, compliance reporting, investment performance, and management dashboards (`REPP`)
- **Architecture**: Snowflake-optimized DDL with business domain separation and data maturity layers

## Installation

1. Clone this repository:
```bash
git clone https://github.com/zBrainiac/SyntheticRetailBank.git
cd SyntheticRetailBank
```

2. Setup Snowflake CLI:
   - Follow the official [Snowflake CLI installation guide](https://docs.snowflake.com/en/developer-guide/snowflake-cli/install)
   - Configure your connection: `snow connection add <my-sf-connection>`

3. Setup Python virtual environment:

```bash
# Create virtual environment (if it doesn't exist)
python -m venv venv

# Activate virtual environment
source venv/bin/activate  # On macOS/Linux
# or
venv\Scripts\activate     # On Windows
```

4. Install required dependencies:

```bash
# Install dependencies in virtual environment
./venv/bin/pip install -r requirements.txt
```

## 🚀 Quick Start

### **One-Command Deployment (Recommended)**

Deploy the complete synthetic bank with automatic data upload:

```bash
# 1. Generate comprehensive data (19 months for proper dormancy and churn testing)
./data_generator.sh 1000 --clean

# 2. Deploy everything (structure + data upload + task activation)
./deploy-structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<my-sf-connection>
```

**Result**: Fully operational synthetic bank with all data loaded and processing automatically! 🎉

**What gets generated:**
- 1000 customers with extended attributes (employment, account tier, risk profile)
- 19 months of payment transactions, equity trades, fixed income & commodity trades
- SWIFT ISO20022 messages, PEP data, mortgage emails
- Customer lifecycle events, status history, address & attribute updates (SCD Type 2)
- FX rates and anomaly patterns for AML testing

**⚠️ Important**: Always generate data **before** deploying structure, as the deployment script expects the generated files to exist for automatic upload.

### **Step-by-Step Deployment**

If you prefer manual control:

```bash
# 1. Generate data (default: 20 customers, 19 months, all generators)
./data_generator.sh

# 2. Deploy SQL structure
./deploy-structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<my-sf-connection>

# 3. Upload data manually (if needed)
./upload-data.sh --CONNECTION_NAME=<my-sf-connection>
```

**⚠️ Important**: Data generation must happen **before** structure deployment!

### **Testing & Debugging**

```bash
# Preview everything (dry run)
./deploy-structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<my-sf-connection> --DRY_RUN

# Test single SQL file
./deploy-structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<my-sf-connection> --FILE=031_ICGI_swift_messages.sql
```

## Usage

### Basic Usage

Generate default dataset (20 customers, 19 months, all generators):

```bash
./data_generator.sh
```

### Advanced Usage

#### Generate Everything (Complete Dataset)

**Recommended: Use the one-command data generator script:**

```bash
# Generate default dataset (20 customers, 19 months)
./data_generator.sh

# Generate with custom customer count
./data_generator.sh 100

# Generate with cleanup (removes previous data first)
./data_generator.sh 100 --clean
```

**What gets generated:**
- Customer master data with extended attributes (employment, account tier, risk profile)
- Payment transactions & accounts
- Equity, fixed income, and commodity trades
- SWIFT ISO20022 messages & mortgage emails
- PEP data & sanctions screening
- Customer lifecycle events & status history
- Address & customer attribute updates (SCD Type 2)
- FX rates & anomaly patterns

📖 **For complete list of command-line options and advanced examples**, see: [`DATA_GENERATOR_USAGE.md`](DATA_GENERATOR_USAGE.md)

## Output Files

### Customer Data File
**Filename**: `customers.csv`

Contains EMEA customer information with localized data and extended attributes (17 columns):

**Core Attributes:**
- `customer_id`: Unique customer identifier (CUST_00001 format)
- `first_name`: Customer first name (localized to country)
- `family_name`: Customer family/last name (localized to country)
- `date_of_birth`: Customer birth date (YYYY-MM-DD)
- `onboarding_date`: Date when customer was onboarded (YYYY-MM-DD)
- `reporting_currency`: Customer reporting currency based on country (EUR, GBP, USD, CHF, NOK, SEK, DKK, PLN)
- `has_anomaly`: Boolean flag indicating if customer has anomalous behavior

**Employment Information:**
- `employer`: Employer name (nullable for unemployed/retired)
- `position`: Job position/title
- `employment_type`: Employment type (FULL_TIME, PART_TIME, CONTRACT, SELF_EMPLOYED, RETIRED, UNEMPLOYED)
- `income_range`: Income range bracket (e.g., 50K-75K, 100K-150K)

**Account & Contact Information:**
- `account_tier`: Account tier (STANDARD, SILVER, GOLD, PLATINUM, PREMIUM)
- `email`: Customer email address
- `phone`: Customer phone number
- `preferred_contact_method`: Preferred contact method (EMAIL, SMS, POST, MOBILE_APP)

**Risk Profile:**
- `risk_classification`: Risk classification (LOW, MEDIUM, HIGH)
- `credit_score_band`: Credit score band (POOR, FAIR, GOOD, VERY_GOOD, EXCELLENT)

**Note**: Address data is stored separately in `customer_addresses.csv` with SCD Type 2 tracking support.

### Customer Address Files

**Initial Address File**: `customer_addresses.csv`
- Contains the initial/onboarding address for each customer
- Used as baseline for SCD Type 2 address tracking

**Address Update Files**: `address_updates/customer_addresses_YYYY-MM-DD.csv`
- Date-stamped files containing address changes over time
- Implements SCD Type 2 (Slowly Changing Dimension Type 2) for historical address tracking
- Each file represents a batch of address changes on a specific date
- Used by `CRMI_ADDRESSES` table for audit trails and compliance reporting

### Customer Update Files

**Customer Update Files**: `customer_updates/customer_updates_YYYY-MM-DD.csv`
- Date-stamped files containing customer attribute changes (employment, account tier, contact info, risk profile)
- Each file contains complete customer records with all 17 attributes plus `insert_timestamp_utc`
- Implements SCD Type 2 for tracking customer attribute history over time
- Used by `CRMI_CUSTOMER` table for historical analysis and lifecycle tracking

### Customer Lifecycle Files

**Lifecycle Event Files**: `customer_events/customer_events_YYYY-MM-DD.csv`
- Date-stamped files containing customer lifecycle events
- Event types: ONBOARDING, ADDRESS_CHANGE, EMPLOYMENT_CHANGE, ACCOUNT_UPGRADE, ACCOUNT_DOWNGRADE, ACCOUNT_CLOSE, REACTIVATION, CHURN, DORMANT_DETECTED
- Data-driven events (generated from address/customer updates) and random events (closures, reactivations)
- Used for churn prediction, lifecycle analytics, and AML correlation analysis

**Customer Status History**: `customer_status.csv`
- Tracks customer status transitions over time (SCD Type 2)
- Status types: ACTIVE, CLOSED, CHURNED, REACTIVATED, DORMANT
- Includes status start/end dates and IS_CURRENT flag
- Used for lifecycle reporting and customer segmentation

### Account Master Data File
**Filename**: `accounts.csv`

Contains account information for all customers with columns:
- `account_id`: Unique account identifier (CUSTOMER_ID_ACCOUNT_TYPE_XX format)
- `account_type`: Type of account (CHECKING, SAVINGS, BUSINESS, INVESTMENT)
- `base_currency`: Account's base currency (EUR, GBP, USD, CHF, etc.)
- `customer_id`: Reference to customer who owns the account
- `status`: Account status (ACTIVE, DORMANT)

Note: INVESTMENT accounts are used for equity trading settlements.

### FX Rates File
**Filename**: `fx_rates.csv`

Contains daily foreign exchange rates with columns:
- `date`: Rate date (YYYY-MM-DD)
- `from_currency`: Source currency
- `to_currency`: Target currency
- `mid_rate`: Mid-market exchange rate
- `bid_rate`: Bid exchange rate (bank buys at this rate)
- `ask_rate`: Ask exchange rate (bank sells at this rate)

### Daily Payment Transaction Files
**Filename Pattern**: `pay_transactions_YYYY-MM-DD.csv`

Each file contains payment transactions for a single business day with columns:
- `booking_date`: Transaction timestamp when recorded (ISO 8601 UTC format: YYYY-MM-DD HH:MM:SS.fffffZ)
- `value_date`: Date when funds are settled/available (YYYY-MM-DD)
- `transaction_id`: Unique transaction identifier
- `customer_id`: Reference to customer
- `amount`: Signed transaction amount in original currency (positive = incoming, negative = outgoing)
- `currency`: Transaction currency (USD, EUR, GBP, JPY, CAD, CHF)
- `base_amount`: Signed transaction amount converted to base currency USD (positive = incoming, negative = outgoing)
- `base_currency`: Base currency for reporting (USD)
- `fx_rate`: Exchange rate used for conversion (from transaction currency to base currency)
- `counterparty_account`: Counterparty account identifier
- `description`: Transaction description (may contain anomaly indicators in [brackets])

Note: Direction is determined by amount sign - no separate direction field.

### Daily Equity Trade Files
**Filename Pattern**: `trades_YYYY-MM-DD.csv`

Each file contains equity trades for a single business day following FIX protocol standards:
- `trade_date`: Trade execution timestamp (ISO 8601 UTC format)
- `settlement_date`: Settlement date (YYYY-MM-DD)
- `trade_id`: Unique trade identifier
- `customer_id`: Reference to customer
- `account_id`: Investment account used for settlement
- `order_id`: Order reference
- `exec_id`: Execution reference
- `symbol`: Stock symbol
- `isin`: International Securities Identification Number
- `side`: FIX protocol side (1=Buy, 2=Sell)
- `quantity`: Number of shares/units
- `price`: Price per share/unit
- `currency`: Trade currency
- `gross_amount`: Signed gross trade amount (positive for buys, negative for sells)
- `commission`: Trading commission
- `net_amount`: Signed net amount after commission
- `base_currency`: Base currency for reporting (CHF)
- `base_gross_amount`: Gross amount in CHF
- `base_net_amount`: Net amount in CHF
- `fx_rate`: Exchange rate to CHF
- `market`: Exchange/market (NYSE, LSE, XETRA, etc.)
- `order_type`: Order type (MARKET, LIMIT, STOP, etc.)
- `exec_type`: Execution type (NEW, PARTIAL_FILL, FILL, etc.)
- `time_in_force`: Time in force (DAY, GTC, IOC, etc.)
- `broker_id`: Executing broker
- `venue`: Trading venue

### Fixed Income Trade File
**Filename**: `fixed_income_trades/fixed_income_trades.csv`

Contains fixed income trades (bonds and interest rate swaps) with FRTB risk metrics:
- `trade_date`: Trade execution timestamp (ISO 8601 UTC format)
- `settlement_date`: Settlement date (YYYY-MM-DD)
- `trade_id`: Unique trade identifier
- `customer_id`: Reference to customer
- `account_id`: Investment account used for settlement
- `instrument_type`: BOND or IRS (Interest Rate Swap)
- `isin`: International Securities Identification Number (for bonds)
- `issuer`: Bond issuer or swap counterparty
- `issuer_type`: SOVEREIGN, CORPORATE, or SUPRANATIONAL
- `currency`: Trade currency (CHF, EUR, USD, GBP)
- `notional`: Notional amount in trade currency
- `price`: Bond price (as percentage of par) or swap rate
- `accrued_interest`: Accrued interest amount (bonds only)
- `coupon_rate`: Annual coupon rate (bonds) or fixed rate (swaps)
- `maturity_date`: Instrument maturity date
- `duration`: Modified duration in years (interest rate sensitivity)
- `dv01`: Dollar Value of 1 basis point move (CHF)
- `credit_rating`: Credit rating (AAA to CCC for bonds)
- `credit_spread_bps`: Credit spread in basis points
- `floating_rate_index`: Floating rate index for swaps (SARON, EURIBOR, SOFR, SONIA)
- `base_currency`: Base currency for reporting (CHF)
- `base_notional`: Notional amount in CHF
- `base_total_value`: Total trade value in CHF
- `fx_rate`: Exchange rate to CHF
- `liquidity_score`: Liquidity score (1-10) for NMRF classification

### Commodity Trade File
**Filename**: `commodity_trades/commodity_trades.csv`

Contains commodity trades across multiple asset classes with risk metrics:
- `trade_date`: Trade execution timestamp (ISO 8601 UTC format)
- `settlement_date`: Settlement/delivery date (YYYY-MM-DD)
- `trade_id`: Unique trade identifier
- `customer_id`: Reference to customer
- `account_id`: Investment account used for settlement
- `commodity_type`: ENERGY, PRECIOUS_METAL, BASE_METAL, or AGRICULTURAL
- `commodity_name`: Specific commodity (e.g., Crude Oil WTI, Gold, Copper)
- `commodity_code`: Standard commodity code
- `contract_type`: SPOT, FUTURE, FORWARD, or SWAP
- `quantity`: Quantity traded
- `unit`: Unit of measure (barrels, troy ounces, metric tons, bushels)
- `price`: Price per unit in trade currency
- `currency`: Trade currency (USD, EUR, GBP, CHF)
- `contract_size`: Standard contract size
- `num_contracts`: Number of contracts
- `delivery_month`: Delivery month (YYYY-MM)
- `delivery_location`: Delivery location/hub
- `delta`: Price sensitivity (CHF per unit price change)
- `spot_price`: Current spot price
- `forward_price`: Forward/futures price
- `volatility`: Price volatility percentage
- `exchange`: Trading exchange (CME, ICE, LME, NYMEX, CBOT)
- `base_currency`: Base currency for reporting (CHF)
- `base_total_value`: Total trade value in CHF
- `fx_rate`: Exchange rate to CHF
- `liquidity_score`: Liquidity score (1-10) for NMRF classification

## Anomaly Types

The tool generates several types of suspicious transaction patterns:

1. **Large Amount Transactions**: Amounts significantly higher than normal patterns
2. **High Frequency**: Unusually high number of transactions in short periods
3. **Suspicious Counterparties**: Transactions with shell companies, offshore accounts
4. **Round Amount Transactions**: Suspicious round numbers (10000, 50000, etc.)
5. **Off-Hours Transactions**: Transactions outside normal business hours or on weekends
6. **Rapid Succession**: Multiple large transactions in quick succession
7. **New Beneficiary Large**: Large transfers to previously unknown counterparties

## Configuration

The tool uses a configuration system that can be customized through command line arguments or by modifying the `config.py` file directly.

### Key Configuration Parameters

- **Customer Count**: Number of customers to simulate
- **Anomaly Percentage**: Percentage of customers that will exhibit suspicious behavior
- **Generation Period**: Time span for transaction generation (default: 19 months for proper dormancy and churn testing)
- **Transaction Frequency**: Average number of transactions per customer per month
- **Amount Ranges**: Minimum and maximum transaction amounts
- **Currency Options**: Available currencies for transactions

## Example Output Structure

```
generated_data/
├── customers.csv
├── transactions_2023-01-03.csv
├── transactions_2023-01-04.csv
├── ...
├── transactions_2024-12-30.csv
└── generation_summary.txt
```

## Data Characteristics

### Realistic Patterns
- **Business Hours**: Most transactions occur during 9 AM - 5 PM
- **Weekday Focus**: Primarily business day transactions
- **Amount Distribution**: Log-normal distribution for realistic amount spread
- **Customer Onboarding**: Varied onboarding dates with most customers pre-existing
- **Settlement Timing**: Realistic value dates based on transaction type, amount, and currency:
  - Small transactions (< $1,000): Usually same-day or next business day settlement
  - Medium transactions ($1,000-$10,000): 0-2 business days settlement
  - Large transactions (> $10,000): May require 0-3 business days for verification
  - International transactions: Additional 1-2 day delays for non-USD currencies
  - Weekend handling: Value dates skip weekends automatically

### Anomaly Patterns
- **Temporal Clustering**: Anomalies occur in concentrated time periods
- **Amount Escalation**: Gradual increase in suspicious transaction amounts
- **Pattern Mixing**: Multiple anomaly types can occur for the same customer
- **Realistic Timing**: Even anomalous transactions follow some business patterns

## Business Applications

### **Risk Management Training & Education**
- **AML Analyst Training**: Hands-on experience identifying suspicious transaction patterns and money laundering typologies
  - *Key Reports*:
    - `REPP_AGG_DT_ANOMALY_ANALYSIS`
    - `PAYA_AGG_DT_TRANSACTION_ANOMALIES`
    - `REPP_AGG_DT_HIGH_RISK_PATTERNS`
- **Compliance Officer Development**: Practical scenarios for regulatory reporting, customer due diligence, and risk assessment
  - *Key Reports*:
    - `CRMA_AGG_DT_CUSTOMER_360`
    - `REPP_AGG_DT_CUSTOMER_SUMMARY`
    - `REPP_AGG_DT_DAILY_TRANSACTION_SUMMARY`
- **Executive Risk Awareness**: Board-level demonstrations of operational risk, compliance failures, and regulatory consequences
  - *Key Reports*:
    - `REPP_AGG_DT_ANOMALY_ANALYSIS`
    - `REPP_AGG_DT_SETTLEMENT_ANALYSIS`
    - `REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT`
- **Churn Prediction & Retention**: Identify at-risk customers for retention campaigns and churn prevention strategies
  - *Key Reports*:
    - `CRMA_AGG_DT_CUSTOMER_360_LIFECYCLE`
    - `REPP_AGG_DT_LIFECYCLE_ANOMALIES`
    - `CRMA_AGG_DT_CUSTOMER_360`
- **Audit & Control Testing**: Internal audit teams can validate control effectiveness and identify process gaps
  - *Key Reports*:
    - `CRMA_AGG_DT_ADDRESSES_HISTORY`
    - `PAYA_AGG_DT_ACCOUNT_BALANCES`
    - `REPP_AGG_DT_HIGH_RISK_PATTERNS`

### **Technology & System Validation**
- **Transaction Monitoring System Testing**: Validate AML systems with known suspicious patterns and false positive scenarios
  - *Key Reports*:
    - `PAYA_AGG_DT_TRANSACTION_ANOMALIES`
    - `REPP_AGG_DT_HIGH_RISK_PATTERNS`
    - `REPP_AGG_DT_ANOMALY_ANALYSIS`
    - `REPP_AGG_DT_LIFECYCLE_ANOMALIES`
- **Risk Model Development**: Build and calibrate customer risk scoring models with controlled datasets
  - *Key Reports*:
    - `REPP_AGG_DT_CUSTOMER_SUMMARY`
    - `CRMA_AGG_DT_CUSTOMER_360`
    - `PAYA_AGG_DT_ACCOUNT_BALANCES`
- **Investment Performance Analytics**: Portfolio management and performance attribution with risk-adjusted metrics
  - *Key Reports*:
    - `PAYA_AGG_DT_TIME_WEIGHTED_RETURN`
    - `REPP_AGG_DT_EQUITY_SUMMARY`
    - `PAYA_AGG_DT_ACCOUNT_BALANCES`
- **Credit Risk Model Validation**: IRB model development, backtesting, and regulatory validation
  - *Key Reports*:
    - `REPP_AGG_DT_IRB_CUSTOMER_RATINGS`
    - `REPP_AGG_DT_CUSTOMER_RATING_HISTORY`
    - `REPP_AGG_DT_IRB_RISK_TRENDS`
    - `REPP_AGG_DT_IRB_PORTFOLIO_METRICS`
- **Capital Adequacy Assessment**: Basel III/IV capital requirement calculation and stress testing
  - *Key Reports*:
    - `REPP_AGG_DT_IRB_RWA_SUMMARY`
    - `REPP_AGG_DT_IRB_PORTFOLIO_METRICS`
    - `REPP_AGG_DT_IRB_RISK_TRENDS`
    - `REPP_AGG_DT_CUSTOMER_RATING_HISTORY`
- **Regulatory Technology (RegTech) Evaluation**: Test vendor solutions against realistic banking scenarios
  - *Key Reports*:
    - `REPP_AGG_DT_DAILY_TRANSACTION_SUMMARY`
    - `REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT`
    - `REFA_AGG_DT_FX_RATES_ENHANCED`
- **Data Analytics & AI Training**: Develop machine learning models for fraud detection and behavioral analysis
  - *Key Reports*:
    - `PAYA_AGG_DT_TRANSACTION_ANOMALIES`
    - `REPP_AGG_DT_EQUITY_SUMMARY`
    - `REPP_AGG_DT_SETTLEMENT_ANALYSIS`
- **Portfolio Performance Measurement**: Investment performance tracking and client reporting with industry-standard metrics
  - *Key Reports*:
    - `PAYA_AGG_DT_TIME_WEIGHTED_RETURN`
    - `REPP_AGG_DT_EQUITY_POSITIONS`
    - `REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE`

### **Governance & Compliance Assurance**
- **Regulatory Examination Preparation**: Demonstrate compliance capabilities to regulators with comprehensive audit trails
  - *Key Reports*:
    - `CRMA_AGG_DT_ADDRESSES_HISTORY`
    - `REPP_AGG_DT_DAILY_TRANSACTION_SUMMARY`
    - `CRMI_EXPOSED_PERSON`
- **Policy & Procedure Validation**: Test internal policies against realistic customer and transaction scenarios
  - *Key Reports*:
    - `REPP_AGG_DT_HIGH_RISK_PATTERNS`
    - `PAYA_AGG_DT_TRANSACTION_ANOMALIES`
    - `REPP_AGG_DT_CUSTOMER_SUMMARY`
- **Risk Appetite Calibration**: Validate risk thresholds and escalation procedures with controlled stress scenarios
  - *Key Reports*:
    - `REPP_AGG_DT_ANOMALY_ANALYSIS`
    - `REPP_AGG_DT_SETTLEMENT_ANALYSIS`
    - `REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT`
    - `REPP_AGG_DT_IRB_RWA_SUMMARY`
- **Capital Adequacy Compliance**: Demonstrate Basel III/IV compliance and regulatory capital adequacy
  - *Key Reports*:
    - `REPP_AGG_DT_IRB_RWA_SUMMARY`
    - `REPP_AGG_DT_IRB_PORTFOLIO_METRICS`
    - `REPP_AGG_DT_IRB_RISK_TRENDS`
    - `REPP_AGG_DT_CUSTOMER_RATING_HISTORY`
- **Business Continuity Planning**: Test operational resilience and recovery procedures with realistic data volumes
  - *Key Reports*:
    - `PAYA_AGG_DT_ACCOUNT_BALANCES`
    - `REPP_AGG_DT_EQUITY_SUMMARY`
    - `REFA_AGG_DT_FX_RATES_ENHANCED`
- **Investment Advisory & Wealth Management**: Client performance reporting and portfolio management analytics
  - *Key Reports*:
    - `PAYA_AGG_DT_TIME_WEIGHTED_RETURN`
    - `PAYA_AGG_DT_ACCOUNT_BALANCES`
    - `REPP_AGG_DT_EQUITY_SUMMARY`

### **BCBS 239 Risk Data Aggregation & Reporting Demonstration**
- **Executive Risk Management**: Comprehensive risk dashboards for senior management and board reporting
  - *Key Reports*:
    - `REPP_AGG_DT_BCBS239_EXECUTIVE_DASHBOARD`
    - `REPP_AGG_DT_BCBS239_RISK_AGGREGATION`
    - `REPP_AGG_DT_BCBS239_REGULATORY_REPORTING`
- **Risk Concentration Analysis**: Real-time monitoring of risk concentrations and portfolio diversification
  - *Key Reports*:
    - `REPP_AGG_DT_BCBS239_RISK_CONCENTRATION`
    - `REPP_AGG_DT_BCBS239_RISK_LIMITS`
    - `REPP_AGG_DT_BCBS239_DATA_QUALITY`
- **Regulatory Compliance Reporting**: BCBS 239 compliant risk data aggregation and reporting capabilities
  - *Key Reports*:
    - `REPP_AGG_DT_BCBS239_REGULATORY_REPORTING`
    - `REPP_AGG_DT_BCBS239_EXECUTIVE_DASHBOARD`
    - `REPP_AGG_DT_BCBS239_DATA_QUALITY`
- **Data Quality & Governance**: Comprehensive data quality monitoring and governance metrics
  - *Key Reports*:
    - `REPP_AGG_DT_BCBS239_DATA_QUALITY`
    - `REPP_AGG_DT_BCBS239_RISK_AGGREGATION`
    - `REPP_AGG_DT_BCBS239_REGULATORY_REPORTING`

## Technical Details

### Dependencies
- **Faker**: Generates realistic customer data (names, addresses, dates)
- **NumPy**: Provides log-normal distribution for realistic transaction amounts
- **Standard Library**: Uses built-in Python modules for core functionality

### Performance
- Generates approximately 1000 transactions per second
- Memory usage scales linearly with customer count
- Optimized for datasets up to 10,000 customers

## Troubleshooting

### Common Issues and Solutions

#### **Data Generation Issues**
```bash
# Error: "ModuleNotFoundError: No module named 'faker'"
# Solution: Ensure virtual environment is set up and dependencies installed
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Error: "Customer file not found"
# Solution: Ensure you run data generation before deployment
./data_generator.sh 100 --clean

# Error: "Invalid arguments: Number of customers must be positive"
# Solution: Use valid customer count
./data_generator.sh 100  # Valid
./data_generator.sh -5   # Invalid (negative numbers not allowed)
```

#### **Snowflake Connection Issues**
```bash
# Error: "Connection not found"
# Solution: Add your connection first
snow connection add <my-sf-connection>

# Error: "Database does not exist"
# Solution: Create database first
snow sql -c <my-sf-connection> -q "CREATE DATABASE AAA_DEV_SYNTHETIC_BANK;"
```

#### **Deployment Issues**
```bash
# Error: "SQL compilation error: Tag 'SENSITIVITY_LEVEL' does not exist"
# Solution: Create the tag first
snow sql -c <my-sf-connection> -q "CREATE TAG SENSITIVITY_LEVEL;"

# Error: "Stream has no data"
# Solution: Check if data was uploaded successfully
./upload-data.sh --CONNECTION_NAME=<my-sf-connection>
```

#### **Performance Issues**
```bash
# For large datasets (1000+ customers):
# 1. Increase Snowflake warehouse size in your connection settings
# 2. The data_generator.sh script is optimized for parallel processing

# Generate large dataset
./data_generator.sh 1000 --clean

# For very large datasets, monitor progress and adjust parameters in data_generator.sh if needed
# See DATA_GENERATOR_USAGE.md for advanced main.py usage with custom parallel workers
```

### **Data Quality Validation**
```sql
-- Check customer data quality
SELECT COUNT(*) as customer_count FROM CRMI_CUSTOMER;
SELECT COUNT(*) as account_count FROM ACCI_ACCOUNT;
SELECT COUNT(*) as transaction_count FROM PAYI_TRANSACTION;

-- Check for data completeness
SELECT 
    COUNT(*) as total_customers,
    COUNT(CASE WHEN has_anomaly = true THEN 1 END) as anomalous_customers,
    ROUND(COUNT(CASE WHEN has_anomaly = true THEN 1 END) * 100.0 / COUNT(*), 2) as anomaly_percentage
FROM CRMI_CUSTOMER;
```

## Contributing

This tool is designed to be extensible. Key areas for enhancement:

1. **Additional Anomaly Types**: Implement new suspicious patterns
2. **Geographic Patterns**: Add location-based transaction patterns
3. **Industry Sectors**: Customize patterns by business type
4. **Regulatory Compliance**: Add specific regulatory scenario templates

## License

This project is provided as-is for educational and testing purposes. Ensure compliance with all applicable regulations when using generated data.

## Support

For questions or issues, please review the code documentation and configuration options. The tool includes comprehensive error handling and validation to guide proper usage.

