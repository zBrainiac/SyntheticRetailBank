# Data Generator Usage Guide

## Overview

The `data_generator.sh` script is a one-command solution to generate a complete synthetic banking dataset with all data types.

## Quick Start

```bash
# Generate default dataset (20 customers)
./data_generator.sh

# Generate with custom customer count
./data_generator.sh 100

# Generate with cleanup (removes previous data first)
./data_generator.sh 100 --clean

# Or use -c flag
./data_generator.sh 50 -c
```

## What Gets Generated

### Master Data
- **customers.csv** - Customer master data with EMEA localization AND extended attributes (employer, account_tier, etc.)
- **accounts.csv** - Customer accounts (checking, savings, business, investment)
- **customer_addresses.csv** - Address history with SCD Type 2 support
- **customer_events/** - Lifecycle event files grouped by date
- **customer_status.csv** - Customer status history (SCD Type 2)
- **pep_data.csv** - Politically Exposed Persons reference data

### Transaction Data
- **payment_transactions/** - Daily payment transaction files (19 months)
- **equity_trades/** - Daily equity trade files
- **fixed_income_trades/** - Fixed income trades (bonds & swaps) with FRTB metrics
- **commodity_trades/** - Commodity trades (energy, metals, agricultural)

### Reference Data
- **fx_rates/** - Daily FX rates for multi-currency support
- **address_updates/** - Timestamped address change files (9 files)
- **customer_updates/** - Timestamped customer update files (8 files)

### Compliance & Communication Data
- **swift_messages/** - ISO20022 SWIFT XML messages
- **emails/** - Mortgage application email threads

## Configuration

The script uses these default settings:

| Parameter | Default | Description |
|-----------|---------|-------------|
| Customers | 20 (or $1) | Number of customers to generate |
| Period | 19 months | Generation time span (for dormancy testing) |
| Anomaly Rate | 3.0% | Percentage of customers with anomalies |
| SWIFT | 40% | Percentage of customers with SWIFT messages |
| PEP Records | 150 | Number of PEP records |
| Mortgage Emails | 5 customers | Number of mortgage email threads |
| Address Updates | 9 files | Number of timestamped address update files |
| Customer Updates | 8 files | Number of timestamped customer update files |
| Fixed Income | 50 trades | Number of bond/swap trades |
| Commodities | 25 trades | Number of commodity trades |

## Output Structure

```
generated_data/
├── master_data/
│   ├── customers.csv (with extended attributes: employer, account_tier, etc.)
│   ├── accounts.csv
│   ├── customer_addresses.csv
│   ├── customer_status.csv
│   ├── pep_data.csv
│   ├── address_updates/
│   │   ├── customer_addresses_2024-08-31.csv
│   │   └── ... (9 files)
│   ├── customer_updates/
│   │   ├── customer_updates_2024-09-05.csv
│   │   └── ... (8 files)
│   └── customer_events/
│       ├── customer_events_2022-05-30.csv
│       └── ... (date-based files)
├── payment_transactions/
│   ├── pay_transactions_2024-04-03.csv
│   └── ... (daily files)
├── equity_trades/
│   ├── trades_2024-04-03.csv
│   └── ... (daily files)
├── fixed_income_trades/
│   ├── fixed_income_trades_2024-04-15.csv
│   └── ... (files per trade date)
├── commodity_trades/
│   ├── commodity_trades_2024-05-20.csv
│   └── ... (files per trade date)
├── fx_rates/
│   ├── fx_rates_2024-04-03.csv
│   └── ... (daily files)
├── swift_messages/
│   ├── pacs.008_CUST_00001_001.xml
│   └── ... (XML files)
└── emails/
    ├── mortgage_request_CUST_00001.eml
    └── ... (email files)
```

## Use Cases

### Small Dataset (Testing/Development)
```bash
# Quick test with minimal data
./data_generator.sh 5 --clean
```

### Medium Dataset (Demo/Training)
```bash
# Good for demonstrations and training
./data_generator.sh 50 --clean
```

### Large Dataset (Production Simulation)
```bash
# Full-scale production simulation
./data_generator.sh 1000 --clean
```

## Next Steps After Generation

### 1. Review Generated Data
```bash
# Check summary report
cat generated_data/reports/generation_summary.txt

# Verify files
ls -la generated_data/master_data/
```

### 2. Deploy to Snowflake
```bash
# Deploy structure and upload data
./deploy-structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<your-connection>
```

### 3. Upload Data Only
```bash
# If structure already exists
./upload-data.sh --CONNECTION_NAME=<your-connection>
```

## Validation

The script automatically validates:
- ✅ All master data files exist
- ✅ Customer count matches expectations
- ✅ Lifecycle events generated for all customers
- ✅ Transaction, equity, FX, and update files created
- ✅ SWIFT, PEP, and email data generated

## Customization

To customize generation parameters, edit the script:

```bash
# Edit data_generator.sh
vim data_generator.sh

# Key parameters to modify:
PERIOD=19                      # Generation time span
--anomaly-rate 3.0             # Percentage of anomalies
--swift-percentage 40          # SWIFT message coverage
--pep-records 150              # Number of PEP records
--fixed-income-trades 50       # Fixed income trade count
--commodity-trades 25          # Commodity trade count
```

## Troubleshooting

### Script Fails with "Command not found"
```bash
# Make sure script is executable
chmod +x data_generator.sh
```

### Virtual Environment Not Found
```bash
# Create and activate virtual environment
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Data Generation Takes Too Long
```bash
# Reduce customer count or period
./data_generator.sh 10 --clean
```

### Want Fresh Data
```bash
# Always use --clean flag to remove old data
./data_generator.sh 20 --clean
```

## Advanced Usage with main.py

While `data_generator.sh` is recommended for most use cases, you can use `main.py` directly for fine-grained control.

### Command Line Options

#### Core Data Generation Options
| Option                     | Short | Description                                 | Default         |
|----------------------------|-------|---------------------------------------------|-----------------|
| `--customers`              | `-c`  | Number of customers to generate             | 10              |
| `--anomaly-rate`           | `-a`  | Percentage of customers with anomalies      | 2.0             |
| `--period`                 | `-p`  | Generation period in months                 | 24              |
| `--transactions-per-month` | `-t`  | Average transactions per customer per month | 3.5             |
| `--output-dir`             | `-o`  | Output directory for generated files        | generated_data  |
| `--start-date`             | `-s`  | Start date (YYYY-MM-DD format)              | Auto-calculated |
| `--clean`                  |       | Clean output directory before generation    | False           |
| `--verbose`                | `-v`  | Enable verbose output                       | False           |
| `--min-amount`             |       | Minimum transaction amount                  | 10.0            |
| `--max-amount`             |       | Maximum transaction amount                  | 50000.0         |

#### SWIFT Message Generation Options
| Option                     | Description                                            | Default                     |
|----------------------------|--------------------------------------------------------|-----------------------------|
| `--generate-swift`         | Generate SWIFT ISO20022 messages for customers         | False                       |
| `--swift-percentage`       | Percentage of customers to generate SWIFT messages for | 30.0                        |
| `--swift-avg-messages`     | Average SWIFT messages per selected customer           | 1.2                         |
| `--swift-workers`          | Number of parallel workers for SWIFT generation        | 4                           |
| `--swift-generator-script` | Path to SWIFT message generator script                 | swift_message_generator.py  |
| `--swift-generator-dir`    | Directory containing SWIFT generator script            | .                           |
| `--swift-output-dir`       | Output directory for SWIFT XML files                   | {output_dir}/swift_messages |

#### PEP (Politically Exposed Persons) Options
| Option           | Description                                     | Default |
|------------------|-------------------------------------------------|---------|
| `--generate-pep` | Generate PEP (Politically Exposed Persons) data | False   |
| `--pep-records`  | Number of PEP records to generate               | 50      |

#### Mortgage Email Generation Options
| Option                       | Description                                         | Default |
|------------------------------|-----------------------------------------------------|---------|
| `--generate-mortgage-emails` | Generate mortgage request emails                    | False   |
| `--mortgage-customers`       | Number of customers to generate mortgage emails for | 3       |

#### Address Update Generation Options
| Option                       | Description                                             | Default            |
|------------------------------|---------------------------------------------------------|--------------------|
| `--generate-address-updates` | Generate address update files for SCD Type 2 processing | False              |
| `--address-update-files`     | Number of address update files to generate              | 6                  |
| `--updates-per-file`         | Number of address updates per file                      | 5-15% of customers |

#### Customer Update Generation Options
| Option                        | Description                                              | Default            |
|-------------------------------|----------------------------------------------------------|--------------------|
| `--generate-customer-updates` | Generate customer update files for SCD Type 2 processing | False              |
| `--customer-update-files`     | Number of customer update files to generate              | 6                  |

#### Customer Lifecycle Generation Options
| Option                  | Description                                                                          | Default |
|-------------------------|--------------------------------------------------------------------------------------|---------|
| `--generate-lifecycle`  | Generate customer lifecycle events and status history for churn prediction & analytics | False   |

#### Fixed Income Generation Options (FRTB Market Risk)
| Option                    | Description                                                | Default |
|---------------------------|------------------------------------------------------------|---------|
| `--generate-fixed-income` | Generate fixed income trades (bonds and interest rate swaps) | False   |
| `--fixed-income-trades`   | Number of fixed income trades to generate                  | 1000    |
| `--bond-swap-ratio`       | Ratio of bonds to swaps (0.7 = 70% bonds, 30% swaps)      | 0.7     |

#### Commodity Generation Options (FRTB Market Risk)
| Option                  | Description                                                   | Default |
|-------------------------|---------------------------------------------------------------|---------|
| `--generate-commodities` | Generate commodity trades (energy, metals, agricultural)      | False   |
| `--commodity-trades`    | Number of commodity trades to generate                        | 500     |

### Complete Dataset Generation
```bash
# Small dataset with all features (10 customers, 19 months for dormancy testing)
./venv/bin/python main.py --customers 10 --anomaly-rate 3.0 --period 19 \
  --generate-swift --generate-pep --generate-mortgage-emails \
  --generate-address-updates --generate-customer-updates --generate-lifecycle \
  --generate-fixed-income --generate-commodities \
  --swift-percentage 40 --pep-records 150 --mortgage-customers 2 \
  --address-update-files 9 --customer-update-files 8 \
  --fixed-income-trades 10 --commodity-trades 5 --clean

# Production-ready dataset (1000 customers)
./venv/bin/python main.py --customers 1000 --anomaly-rate 3.0 --period 19 \
  --generate-swift --generate-pep --generate-mortgage-emails \
  --generate-address-updates --generate-customer-updates --generate-lifecycle \
  --generate-fixed-income --generate-commodities \
  --swift-percentage 40 --pep-records 15000 --mortgage-customers 52 \
  --address-update-files 9 --customer-update-files 8 \
  --fixed-income-trades 700 --commodity-trades 888 --clean
```

### Specific Use Cases
```bash
# Generate with more anomalies for testing
./venv/bin/python main.py --customers 100 --anomaly-rate 5.0 --clean

# Generate SWIFT messages only
./venv/bin/python main.py --customers 50 --generate-swift --swift-percentage 25 --clean

# Custom time period and output directory
./venv/bin/python main.py --customers 25 --period 12 --output-dir ./custom_data --clean

# Verbose output for debugging
./venv/bin/python main.py --verbose --customers 20 --anomaly-rate 3.0 --clean

# Lifecycle events only (requires existing customer data)
./venv/bin/python main.py --customers 100 --period 19 \
  --generate-address-updates --generate-customer-updates --generate-lifecycle --clean

# FRTB market risk data (fixed income + commodities)
./venv/bin/python main.py --customers 100 \
  --generate-fixed-income --generate-commodities \
  --fixed-income-trades 1000 --commodity-trades 500 --clean

# Complete dataset with all risk classes
./venv/bin/python main.py --customers 200 --period 24 \
  --generate-swift --generate-pep --generate-lifecycle \
  --generate-fixed-income --generate-commodities \
  --anomaly-rate 4.0 --clean
```

## Comparison with Manual Generation

### Old Way (Multiple Commands)
```bash
# Step 1: Generate base data
python main.py --customers 100 --clean

# Step 2: Generate address updates
python main.py --generate-address-updates

# Step 3: Generate customer updates
python main.py --generate-customer-snapshot --generate-customer-updates

# Step 4: Generate lifecycle
python main.py --generate-lifecycle

# Step 5: Generate SWIFT
python main.py --generate-swift

# Step 6: Generate PEP
python main.py --generate-pep

# Step 7: Generate mortgages
python main.py --generate-mortgage-emails

# Step 8: Generate fixed income
python main.py --generate-fixed-income

# Step 9: Generate commodities
python main.py --generate-commodities
```

### New Way (One Command)
```bash
# Everything in one command!
./data_generator.sh 100 --clean
```

## Performance

| Customer Count | Approx. Time | Disk Space |
|----------------|--------------|------------|
| 5 customers    | ~30 seconds  | ~50 MB     |
| 20 customers   | ~2 minutes   | ~200 MB    |
| 50 customers   | ~5 minutes   | ~500 MB    |
| 100 customers  | ~10 minutes  | ~1 GB      |
| 1000 customers | ~90 minutes  | ~10 GB     |

*Times may vary based on system performance*

## Tips

1. **Start Small**: Begin with 5-10 customers to verify setup
2. **Use Clean Flag**: Always use `--clean` for fresh data
3. **Check Summary**: Review `generated_data/reports/generation_summary.txt`
4. **Test Integration**: Use small datasets to test Snowflake integration
5. **Scale Gradually**: Increase customer count once workflow is validated

## Support

For issues or questions:
1. Check the validation output for specific errors
2. Review `generated_data/reports/generation_summary.txt`
3. Verify virtual environment is activated
4. Ensure all dependencies are installed: `pip install -r requirements.txt`

## Related Documentation

- **CUSTOMER_LIFECYCLE_INTEGRATION.md** - Lifecycle events and customer updates
- **README.md** - Main project documentation
- **SYSTEM_ARCHITECTURE.md** - System architecture and design

