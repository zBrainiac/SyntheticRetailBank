# Synthetic Retail Bank

A showcase demonstrating risk management and governance challenges faced by modern retail banks in the Europe (EMEA) region. This synthetic bank environment illustrates real-world scenarios including anti-money laundering compliance, transaction monitoring, customer due diligence, and regulatory reporting requirements that financial institutions must navigate daily.

## Risk & Governance Showcase

This synthetic retail bank demonstrates critical risk management and governance scenarios that financial institutions encounter:

### **Compliance & Regulatory Risk**
- **Anti-Money Laundering (AML)**: Suspicious transaction pattern detection and reporting
  - *Reports*:
    - `REPP_DT_ANOMALY_ANALYSIS`
    - `REPP_DT_HIGH_RISK_PATTERNS`
    - `PAYA_AGG_DT_TRANSACTION_ANOMALIES` -- Calculate each account's behavioral baseline over the last 450 days
- **Know Your Customer (KYC)**: Customer due diligence and identity verification processes
  - *Reports*:
    - `REPP_DT_CUSTOMER_SUMMARY`
    - `CRMA_AGG_DT_CUSTOMER` -- Comprehensive customer view with Exposed Person matching
    - `CRMA_AGG_DT_ADDRESSES_CURRENT`
- **Politically Exposed Persons (PEP) Screening**: High-risk customer identification and monitoring
  - *Reports*:
    - `CRMA_AGG_DT_CUSTOMER` (with fuzzy matching against reference list in `CRMI_EXPOSED_PERSON`)
- **Regulatory Reporting**: GDPR, MiFID II, Basel III/IV, and PSD2 compliance requirements
  - *Reports*:
    - `REPP_DT_DAILY_TRANSACTION_SUMMARY`
    - `REPP_DT_CURRENCY_EXPOSURE_CURRENT`
    - `CRMA_AGG_DT_ADDRESSES_HISTORY`
    - `REPP_DT_IRB_RWA_SUMMARY`
    - `REPP_DT_IRB_PORTFOLIO_METRICS`
- **Sanctions Screening**: Transaction filtering against prohibited entities and jurisdictions
  - *Reports*:
    - `REPP_DT_HIGH_RISK_PATTERNS` (offshore/crypto filtering)
    - `PAYA_AGG_DT_TRANSACTION_ANOMALIES` TODO

### **Credit Risk Management & IRB Approach**
- **Basel III/IV Capital Adequacy**: Internal Ratings Based approach for regulatory capital calculation
  - *Reports*:
    - `REPP_DT_IRB_CUSTOMER_RATINGS`
    - `REPP_DT_IRB_PORTFOLIO_METRICS`
    - `REPP_DT_IRB_RWA_SUMMARY`
- **Credit Risk Parameters**: PD (Probability of Default), LGD (Loss Given Default), EAD (Exposure at Default)
  - *Reports*:
    - `REPP_DT_IRB_CUSTOMER_RATINGS`
    - `REPP_DT_IRB_RISK_TRENDS`
- **Risk Weighted Assets (RWA)**: Regulatory capital requirement calculation and monitoring
  - *Reports*:
    - `REPP_DT_IRB_RWA_SUMMARY`
    - `REPP_DT_IRB_PORTFOLIO_METRICS`
- **Credit Rating & Default Management**: Internal credit ratings and default identification
  - *Reports*:
    - `REPP_DT_IRB_CUSTOMER_RATINGS`
    - `REPP_DT_IRB_RISK_TRENDS`
- **Model Risk Management**: IRB model validation, backtesting, and performance monitoring
  - *Reports*:
    - `REPP_DT_IRB_RISK_TRENDS`
    - `REPP_DT_IRB_PORTFOLIO_METRICS`

### **Operational Risk Management**
- **Transaction Monitoring**: Real-time fraud detection and behavioral analysis
  - *Reports*:
    - `PAYA_AGG_DT_TRANSACTION_ANOMALIES` -- Calculate each account's behavioral baseline over the last 450 days
    - `REPP_DT_DAILY_TRANSACTION_SUMMARY`
    - `REPP_DT_HIGH_RISK_PATTERNS`
- **Customer Risk Profiling**: Dynamic risk scoring and segmentation
  - *Reports*:
    - `REPP_DT_CUSTOMER_SUMMARY`
    - `CRMA_AGG_DT_CUSTOMER`
    - `REPP_DT_ANOMALY_ANALYSIS`
- **Cross-Border Payment Risk**: Multi-currency transaction compliance and monitoring
  - *Reports*:
    - `REPP_DT_CURRENCY_EXPOSURE_CURRENT`
    - `REPP_DT_CURRENCY_EXPOSURE_HISTORY`
    - `REFA_AGG_DT_FX_RATES_ENHANCED`
- **Settlement Risk**: Payment timing and counterparty risk assessment
  - *Reports*:
    - `REPP_DT_SETTLEMENT_ANALYSIS`
    - `REPP_DT_HIGH_RISK_PATTERNS`
    - `REPP_DT_CURRENCY_SETTLEMENT_EXPOSURE`
- **Data Governance**: Customer data privacy, retention, and audit trail management
  - *Reports*:
    - `CRMA_AGG_DT_ADDRESSES_HISTORY`
    - `PAYA_AGG_DT_ACCOUNT_BALANCES`
    - `REPP_DT_CUSTOMER_SUMMARY`

### **Financial Crime Prevention**
- **Suspicious Activity Detection**: Pattern recognition for potential money laundering
  - *Reports*:
    - `REPP_DT_ANOMALY_ANALYSIS`
    - `PAYA_AGG_DT_TRANSACTION_ANOMALIES` -- Calculate each account's behavioral baseline over the last 450 days
    - `REPP_DT_HIGH_RISK_PATTERNS`
- **Trade-Based Money Laundering**: Equity trading anomaly identification
  - *Reports*:
    - `REPP_DT_EQUITY_SUMMARY`
    - `REPP_DT_HIGH_VALUE_EQUITY_TRADES`
    - `REPP_DT_EQUITY_POSITIONS`
- **Structuring Detection**: Transaction splitting and layering pattern analysis
  - *Reports*:
    - `PAYA_AGG_DT_TRANSACTION_ANOMALIES` -- Calculate each account's behavioral baseline over the last 450 days
    - `REPP_DT_ANOMALY_ANALYSIS`
- **High-Risk Geography Monitoring**: Enhanced due diligence for specific jurisdictions
  - *Reports*:
    - `REPP_DT_HIGH_RISK_PATTERNS` (offshore accounts)
    - `REPP_DT_CURRENCY_EXPOSURE_CURRENT`
- **Beneficial Ownership Transparency**: Ultimate beneficial owner identification and tracking
  - *Reports*:
    - `CRMA_AGG_DT_CUSTOMER`
    - `CRMI_EXPOSED_PERSON`
    - `REPP_DT_CUSTOMER_SUMMARY`

## Key Capabilities

### **Customer Risk & Compliance Management**
- **Multi-Jurisdictional Customer Base**: EMEA customers across 12 countries with localized compliance requirements
- **Dynamic Risk Scoring**: Behavioral profiling with CRITICAL, HIGH, MODERATE, NORMAL risk classifications
- **PEP Screening & Monitoring**: Politically Exposed Persons identification with fuzzy name matching algorithms
- **Customer 360° Risk View**: Comprehensive profiles integrating master data, transaction history, and compliance status
- **Enhanced Due Diligence**: Automated triggers for high-risk customer segments and suspicious behavior patterns

### **Transaction Monitoring & AML**
- **Real-Time Anomaly Detection**: Multi-dimensional behavioral analysis using statistical scoring models
- **Suspicious Pattern Recognition**: Detection of structuring, layering, and integration money laundering techniques
- **Cross-Border Payment Surveillance**: Multi-currency transaction monitoring with enhanced controls
- **Trade-Based Money Laundering Detection**: Equity trading pattern analysis for unusual investment behaviors
- **Regulatory Alert Generation**: Automated suspicious activity report (SAR) triggers and case management

### **Governance & Audit Controls**
- **Complete Audit Trail**: SCD Type 2 address tracking and comprehensive transaction history
- **Data Lineage & Quality**: End-to-end data governance with validation and reconciliation controls
- **Regulatory Reporting**: GDPR, MiFID II, Basel III, and PSD2 compliant data structures and processes
- **Risk Appetite Monitoring**: Configurable thresholds and escalation procedures for risk limit breaches
- **Management Information**: Executive dashboards and regulatory reporting with drill-down capabilities

### **Credit Risk & Capital Management Framework**
- **IRB Capital Adequacy**: Basel III/IV compliant Internal Ratings Based approach for regulatory capital
- **Credit Risk Parameters**: PD, LGD, EAD modeling with exposure-weighted portfolio aggregation
- **Risk Weighted Assets**: Automated RWA calculation and regulatory capital requirement monitoring
- **Credit Rating Systems**: Internal rating scales (AAA-CCC) with default identification and watch list management
- **Portfolio Risk Management**: Credit concentration analysis, vintage tracking, and collateral coverage monitoring
- **Model Validation**: IRB model backtesting, performance monitoring, and stress testing capabilities

### **Operational Risk Framework**
- **Settlement Risk Management**: Payment timing analysis and counterparty exposure monitoring
- **Concentration Risk**: Customer, geographic, and currency exposure analysis with limit monitoring
- **Model Risk Management**: Statistical model validation and performance monitoring for anomaly detection
- **Business Continuity**: Scenario analysis and stress testing capabilities for operational resilience
- **Third-Party Risk**: Counterparty due diligence and ongoing monitoring of external relationships

## Installation

1. Clone or download this repository
2. Install required dependencies:

```bash
pip install -r requirements.txt
```

## Usage

### Basic Usage

Generate default dataset (10 customers, 2% anomalies, 24 months):

```bash
python main.py
```

### Advanced Usage

#### Generate Everything (Complete Dataset)
```bash
# 🎯 GENERATE ALL DATA TYPES - Complete synthetic bank dataset
python main.py --customers 100 --generate-swift --generate-pep --generate-mortgage-emails --generate-address-updates --clean --verbose

# 🚀 PRODUCTION-READY DATASET - Large scale with all features
./venv/bin/python main.py --customers 1000 --anomaly-rate 3.0 --period 36 --generate-swift --generate-pep --generate-mortgage-emails --generate-address-updates --swift-percentage 40 --pep-records 150 --mortgage-customers 25 --address-update-files 12 --clean
```

#### Specific Use Cases
```bash
# Generate larger dataset with more anomalies
python main.py --customers 100 --anomaly-rate 5.0

# Generate with SWIFT ISO20022 messages
python main.py --customers 50 --generate-swift

# Custom SWIFT settings
python main.py --customers 100 --generate-swift --swift-percentage 25 --swift-avg-messages 2.0

# Custom time period and output directory
python main.py --customers 25 --period 12 --output-dir ./custom_data

# Clean previous output before generating new data
python main.py --clean --customers 50

# Verbose output with detailed configuration
python main.py --verbose --customers 20 --anomaly-rate 3.0

# generate all (small dataset)
./venv/bin/python main.py --customers 10 --anomaly-rate 3.0 --period 3 --generate-swift --generate-pep --generate-mortgage-emails --generate-address-updates --swift-percentage 40 --pep-records 150 --mortgage-customers 5 --address-update-files 12 --clean

# generate all (large dataset)
./venv/bin/python main.py --customers 1000 --anomaly-rate 3.0 --period 24 --generate-swift --generate-pep --generate-mortgage-emails --generate-address-updates --swift-percentage 30 --pep-records 200 --mortgage-customers 25 --address-update-files 24 --clean
```

### Command Line Options

#### Core Generation Options
| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--customers` | `-c` | Number of customers to generate | 10 |
| `--anomaly-rate` | `-a` | Percentage of customers with anomalies | 2.0 |
| `--period` | `-p` | Generation period in months | 24 |
| `--transactions-per-month` | `-t` | Average transactions per customer per month | 3.5 |
| `--output-dir` | `-o` | Output directory for generated files | generated_data |
| `--start-date` | `-s` | Start date (YYYY-MM-DD format) | Auto-calculated |
| `--clean` | | Clean output directory before generation | False |
| `--verbose` | `-v` | Enable verbose output | False |
| `--min-amount` | | Minimum transaction amount | 10.0 |
| `--max-amount` | | Maximum transaction amount | 50000.0 |

#### SWIFT Message Generation Options
| Option | Description | Default |
|--------|-------------|---------|
| `--generate-swift` | Generate SWIFT ISO20022 messages for customers | False |
| `--swift-percentage` | Percentage of customers to generate SWIFT messages for | 30.0 |
| `--swift-avg-messages` | Average SWIFT messages per selected customer | 1.2 |
| `--swift-workers` | Number of parallel workers for SWIFT generation | 4 |
| `--swift-generator-script` | Path to SWIFT message generator script | swift_message_generator.py |
| `--swift-generator-dir` | Directory containing SWIFT generator script | . |
| `--swift-output-dir` | Output directory for SWIFT XML files | {output_dir}/swift_messages |

#### PEP (Politically Exposed Persons) Options
| Option | Description | Default |
|--------|-------------|---------|
| `--generate-pep` | Generate PEP (Politically Exposed Persons) data | False |
| `--pep-records` | Number of PEP records to generate | 50 |

#### Mortgage Email Generation Options
| Option | Description | Default |
|--------|-------------|---------|
| `--generate-mortgage-emails` | Generate mortgage request emails | False |
| `--mortgage-customers` | Number of customers to generate mortgage emails for | 3 |

#### Address Update Generation Options
| Option | Description | Default |
|--------|-------------|---------|
| `--generate-address-updates` | Generate address update files for SCD Type 2 processing | False |
| `--address-update-files` | Number of address update files to generate | 6 |
| `--updates-per-file` | Number of address updates per file | 5-15% of customers |

## Output Files

### Customer Data File
**Filename**: `customers.csv`

Contains EMEA customer information with localized data and the following columns:
- `customer_id`: Unique customer identifier (CUST_00001 format)
- `first_name`: Customer first name (localized to country)
- `family_name`: Customer family/last name (localized to country)
- `date_of_birth`: Customer birth date (YYYY-MM-DD)
- `street_address`: Street address (localized format)
- `city`: City name (localized to country)
- `state`: State/Region (where applicable for the country)
- `zipcode`: Postal code (country-specific format)
- `country`: Customer's country (12 EMEA countries supported)
- `onboarding_date`: Date when customer was onboarded (YYYY-MM-DD)
- `has_anomaly`: Boolean flag indicating if customer has anomalous behavior

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

### Summary Report
**Filename**: `generation_summary.txt`

Contains comprehensive statistics about the generated dataset including:
- Configuration parameters used
- Customer and transaction counts
- Anomaly statistics
- List of anomalous customers
- Generated file inventory

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
- **Generation Period**: Time span for transaction generation (default: 24 months)
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
    - `REPP_DT_ANOMALY_ANALYSIS`
    - `PAYA_AGG_DT_TRANSACTION_ANOMALIES`
    - `REPP_DT_HIGH_RISK_PATTERNS`
- **Compliance Officer Development**: Practical scenarios for regulatory reporting, customer due diligence, and risk assessment
  - *Key Reports*:
    - `CRMA_AGG_DT_CUSTOMER`
    - `REPP_DT_CUSTOMER_SUMMARY`
    - `REPP_DT_DAILY_TRANSACTION_SUMMARY`
- **Executive Risk Awareness**: Board-level demonstrations of operational risk, compliance failures, and regulatory consequences
  - *Key Reports*:
    - `REPP_DT_ANOMALY_ANALYSIS`
    - `REPP_DT_SETTLEMENT_ANALYSIS`
    - `REPP_DT_CURRENCY_EXPOSURE_CURRENT`
- **Audit & Control Testing**: Internal audit teams can validate control effectiveness and identify process gaps
  - *Key Reports*:
    - `CRMA_AGG_DT_ADDRESSES_HISTORY`
    - `PAYA_AGG_DT_ACCOUNT_BALANCES`
    - `REPP_DT_HIGH_RISK_PATTERNS`

### **Technology & System Validation**
- **Transaction Monitoring System Testing**: Validate AML systems with known suspicious patterns and false positive scenarios
  - *Key Reports*:
    - `PAYA_AGG_DT_TRANSACTION_ANOMALIES`
    - `REPP_DT_HIGH_RISK_PATTERNS`
    - `REPP_DT_ANOMALY_ANALYSIS`
- **Risk Model Development**: Build and calibrate customer risk scoring models with controlled datasets
  - *Key Reports*:
    - `REPP_DT_CUSTOMER_SUMMARY`
    - `CRMA_AGG_DT_CUSTOMER`
    - `PAYA_AGG_DT_ACCOUNT_BALANCES`
- **Credit Risk Model Validation**: IRB model development, backtesting, and regulatory validation
  - *Key Reports*:
    - `REPP_DT_IRB_CUSTOMER_RATINGS`
    - `REPP_DT_IRB_RISK_TRENDS`
    - `REPP_DT_IRB_PORTFOLIO_METRICS`
- **Capital Adequacy Assessment**: Basel III/IV capital requirement calculation and stress testing
  - *Key Reports*:
    - `REPP_DT_IRB_RWA_SUMMARY`
    - `REPP_DT_IRB_PORTFOLIO_METRICS`
    - `REPP_DT_IRB_RISK_TRENDS`
- **Regulatory Technology (RegTech) Evaluation**: Test vendor solutions against realistic banking scenarios
  - *Key Reports*:
    - `REPP_DT_DAILY_TRANSACTION_SUMMARY`
    - `REPP_DT_CURRENCY_EXPOSURE_CURRENT`
    - `REFA_AGG_DT_FX_RATES_ENHANCED`
- **Data Analytics & AI Training**: Develop machine learning models for fraud detection and behavioral analysis
  - *Key Reports*:
    - `PAYA_AGG_DT_TRANSACTION_ANOMALIES`
    - `REPP_DT_EQUITY_SUMMARY`
    - `REPP_DT_SETTLEMENT_ANALYSIS`

### **Governance & Compliance Assurance**
- **Regulatory Examination Preparation**: Demonstrate compliance capabilities to regulators with comprehensive audit trails
  - *Key Reports*:
    - `CRMA_AGG_DT_ADDRESSES_HISTORY`
    - `REPP_DT_DAILY_TRANSACTION_SUMMARY`
    - `CRMI_EXPOSED_PERSON`
- **Policy & Procedure Validation**: Test internal policies against realistic customer and transaction scenarios
  - *Key Reports*:
    - `REPP_DT_HIGH_RISK_PATTERNS`
    - `PAYA_AGG_DT_TRANSACTION_ANOMALIES`
    - `REPP_DT_CUSTOMER_SUMMARY`
- **Risk Appetite Calibration**: Validate risk thresholds and escalation procedures with controlled stress scenarios
  - *Key Reports*:
    - `REPP_DT_ANOMALY_ANALYSIS`
    - `REPP_DT_SETTLEMENT_ANALYSIS`
    - `REPP_DT_CURRENCY_EXPOSURE_CURRENT`
    - `REPP_DT_IRB_RWA_SUMMARY`
- **Capital Adequacy Compliance**: Demonstrate Basel III/IV compliance and regulatory capital adequacy
  - *Key Reports*:
    - `REPP_DT_IRB_RWA_SUMMARY`
    - `REPP_DT_IRB_PORTFOLIO_METRICS`
    - `REPP_DT_IRB_RISK_TRENDS`
- **Business Continuity Planning**: Test operational resilience and recovery procedures with realistic data volumes
  - *Key Reports*:
    - `PAYA_AGG_DT_ACCOUNT_BALANCES`
    - `REPP_DT_EQUITY_SUMMARY`
    - `REFA_AGG_DT_FX_RATES_ENHANCED`

## Technical Details

### Dependencies
- **Faker**: Generates realistic customer data (names, addresses, dates)
- **NumPy**: Provides log-normal distribution for realistic transaction amounts
- **Standard Library**: Uses built-in Python modules for core functionality

### Performance
- Generates approximately 1000 transactions per second
- Memory usage scales linearly with customer count
- Optimized for datasets up to 10,000 customers

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

