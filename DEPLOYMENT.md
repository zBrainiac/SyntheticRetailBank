# Synthetic Bank Deployment Guide

This guide explains how to deploy the complete synthetic bank data structure to Snowflake, including automatic data upload for a fully operational system.

## 🚀 One-Command Deployment

The enhanced `deploy-structure.sh` script provides **end-to-end deployment**:
1. **Deploy SQL Structure** - Creates database, schemas, tables, tasks, streams
2. **Upload Generated Data** - Automatically uploads all generated data to appropriate stages
3. **Activate Processing** - Tasks start processing the uploaded data immediately

## Prerequisites

1. **Snowflake CLI**: Install and configure the Snowflake CLI
   ```bash
   pip install snowflake-cli-labs
   snowflake configure
   ```

2. **Connection Setup**: Create a connection configuration
   ```bash
   snowflake connection add --connection-name my_connection
   ```

3. **Generated Data**: Ensure you have generated data files
   ```bash
   python main.py --help  # See generation options
   ```

## Deployment Script

The `deploy-structure.sh` script provides **complete end-to-end deployment** with automatic data upload.

### Usage

```bash
./deploy-structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=my_connection
```

### Arguments

- `--DATABASE=...` - Target database name (required)
- `--CONNECTION_NAME=...` - Snowflake connection name (required)
- `--SQL_DIR=...` - Path to SQL files (optional, default: ./structure)
- `--DRY_RUN` - Show what would be executed without running (optional)
- `--FILE=...` - Test a single SQL file (optional, for debugging)

### Examples

#### Complete End-to-End Deployment (Recommended)
```bash
./deploy-structure.sh \
  --DATABASE=AAA_DEV_SYNTHETIC_BANK \
  --CONNECTION_NAME=sfseeurope-mdaeppen
```
**Result**: Deploys structure + uploads data + activates tasks = fully operational bank!

#### Dry Run (Preview Everything)
```bash
./deploy-structure.sh \
  --DATABASE=AAA_DEV_SYNTHETIC_BANK \
  --CONNECTION_NAME=sfseeurope-mdaeppen \
  --DRY_RUN
```
**Result**: Shows what would be deployed and uploaded without making changes

#### Test Single File (Debugging)
```bash
./deploy-structure.sh \
  --DATABASE=AAA_DEV_SYNTHETIC_BANK \
  --CONNECTION_NAME=sfseeurope-mdaeppen \
  --FILE=031_ICGI.sql
```
**Result**: Tests only the specified SQL file for debugging

#### Custom SQL Directory
```bash
./deploy-structure.sh \
  --DATABASE=AAA_DEV_SYNTHETIC_BANK \
  --CONNECTION_NAME=sfseeurope-mdaeppen \
  --SQL_DIR=/path/to/custom/structure
```

## 🎯 What Gets Deployed

### SQL Structure (25 files)
- **Database & Schemas**: `000_database_setup.sql`
- **Raw Data Layers**: Customer, Account, Payment, Trading, Loan data
- **Aggregation Layers**: Analytics, reporting, business logic
- **Reporting Layers**: Cross-domain analytics and FRTB compliance

### Generated Data Upload
- **Customer Data**: `master_data/customers_*.csv` → `@CRMI_CUSTOMERS`
- **Account Data**: `master_data/accounts_*.csv` → `@ACCI_ACCOUNTS`
- **Payment Data**: `payment_transactions/transactions_*.csv` → `@PAYI_TRANSACTIONS`
- **Trading Data**: `equity_trades/`, `fixed_income_trades/`, `commodity_trades/` → respective stages
- **Loan Documents**: `emails/`, `creditcard_pdf/` → `@LOAI_RAW_*`
- **SWIFT Messages**: `swift_messages/*.xml` → `@ICGI_RAW_SWIFT_INBOUND`
- **FX Rates**: `fx_rates/fx_rates_*.csv` → `@REFI_FX_RATES`

## 🚀 Deployment Process

1. **Structure Deployment**: SQL files executed in dependency order
2. **Data Upload**: Generated files uploaded to appropriate stages
3. **Task Activation**: Automated processing tasks resume
4. **Verification**: System ready for business operations

## Troubleshooting

### Common Issues

1. **Connection Error**: Verify your Snowflake connection is configured
   ```bash
   snowflake connection list
   ```

2. **Permission Error**: Ensure your user has CREATE SCHEMA and CREATE TABLE permissions

3. **Database Not Found**: The script creates `AAA_DEV_SYNTHETIC_BANK` automatically

4. **Data Upload Failed**: Check if `upload-data.sh` exists and generated data is present

### Debug Mode

Use `--DRY_RUN` to preview everything without making changes:

```bash
./deploy-structure.sh \
  --DATABASE=AAA_DEV_SYNTHETIC_BANK \
  --CONNECTION_NAME=sfseeurope-mdaeppen \
  --DRY_RUN
```

### Test Single File

Debug specific SQL files:

```bash
./deploy-structure.sh \
  --DATABASE=AAA_DEV_SYNTHETIC_BANK \
  --CONNECTION_NAME=sfseeurope-mdaeppen \
  --FILE=031_ICGI.sql
```

## ✅ Post-Deployment Verification

After successful deployment, verify your synthetic bank:

### 1. Check Database Objects
```sql
SHOW SCHEMAS IN DATABASE AAA_DEV_SYNTHETIC_BANK;
SHOW TABLES IN SCHEMA CRM_RAW_001;
SHOW TASKS IN DATABASE AAA_DEV_SYNTHETIC_BANK;
```

### 2. Verify Data Loading
```sql
SELECT COUNT(*) FROM CRM_RAW_001.CRMI_PARTY;
SELECT COUNT(*) FROM PAY_RAW_001.PAYI_TRANSACTIONS;
SELECT COUNT(*) FROM EQT_RAW_001.EQTI_TRADES;
```

### 3. Check Stage Contents
```sql
LIST @CRMI_CUSTOMERS;
LIST @PAYI_TRANSACTIONS;
LIST @EQTI_TRADES;
```

### 4. Monitor Task Execution
```sql
SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY()) 
WHERE NAME LIKE '%TASK%' 
ORDER BY COMPLETED_TIME DESC;
```

## 🎉 Success Indicators

Your synthetic bank is fully operational when you see:
- ✅ All schemas created (8 schemas)
- ✅ All tables populated with data
- ✅ Tasks running successfully
- ✅ Stages contain uploaded files
- ✅ Dynamic tables refreshing automatically

## Support

For issues with the deployment script or SQL files, check:
- Snowflake CLI documentation
- Individual SQL file comments
- `structure/README_DEPLOYMENT.md` for detailed object information
