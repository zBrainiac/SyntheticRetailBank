#!/bin/bash
# =============================================================================
# Synthetic Bank Data Upload Script
# =============================================================================
# 
# This script uploads all generated data to the appropriate Snowflake stages
# based on the comprehensive data mapping plan. It handles all data types and
# ensures proper file placement for automated processing by Snowflake tasks.
#
# Features:
# - Complete data mapping for all generated files
# - Automatic stage detection and file validation
# - Progress tracking and error handling
# - Dry run mode for testing
# - Comprehensive file counting and status reporting
#
# Usage:
#   ./upload-data.sh --CONNECTION_NAME=<my-sf-connection> [--DRY_RUN]
#
# Example:
#   ./upload-data.sh --CONNECTION_NAME=<my-sf-connection>
#   ./upload-data.sh --CONNECTION_NAME=<my-sf-connection> --DRY_RUN
# =============================================================================

set -e

# --- Default values ---
CONNECTION_NAME=""
DRY_RUN=false

# --- Dynamic path detection ---
# Get the directory where this script is located (works from any location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Generated data is always in the 'generated_data' subdirectory relative to the script
# This makes the script portable and works regardless of where it's executed from
GENERATED_DATA_DIR="$SCRIPT_DIR/generated_data"

# --- Parse arguments ---
for ARG in "$@"; do
    case $ARG in
        --CONNECTION_NAME=*)
            CONNECTION_NAME="${ARG#*=}"
            ;;
        --DRY_RUN)
            DRY_RUN=true
            ;;
        *)
            echo "❌ Unknown argument: $ARG"
            echo "Usage: $0 --CONNECTION_NAME=... [--DRY_RUN]"
            exit 1
            ;;
    esac
done

# --- Validate required inputs ---
if [[ -z "$CONNECTION_NAME" ]]; then
    echo "❌ Missing required argument: --CONNECTION_NAME"
    echo "Usage: $0 --CONNECTION_NAME=... [--DRY_RUN]"
    exit 1
fi

# --- Validate generated data directory ---
if [[ ! -d "$GENERATED_DATA_DIR" ]]; then
    echo "❌ Generated data directory not found: $GENERATED_DATA_DIR"
    echo "Please run the data generation first: python main.py --help"
    echo "Expected location: $GENERATED_DATA_DIR"
    exit 1
fi

echo "🚀 Synthetic Bank Data Upload"
echo "=================================="
echo "📁 Data Directory: $GENERATED_DATA_DIR"
echo "🔗 Connection: $CONNECTION_NAME"
echo "🧪 Dry Run: $DRY_RUN"
echo ""

# --- Function to upload files to stage ---
upload_to_stage() {
    local local_pattern="$1"
    local stage_name="$2"
    local schema="$3"
    local description="$4"
    
    echo "📤 Uploading $description..."
    echo "   Pattern: $local_pattern"
    echo "   Stage: $stage_name"
    echo "   Schema: $schema"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "   🧪 DRY RUN: Would upload files matching: $local_pattern"
        return 0
    fi
    
    # Find files matching the pattern
    local files_found=0
    for file in $local_pattern; do
        if [[ -f "$file" ]]; then
            files_found=$((files_found + 1))
            echo "   📄 Found: $(basename "$file")"
        fi
    done
    
    if [[ $files_found -eq 0 ]]; then
        echo "   ⚠️  No files found matching pattern: $local_pattern"
        return 0
    fi
    
    echo "   📊 Found $files_found files"
    
    # Upload files to stage (uncompressed for task processing)
    set +e
    snow sql -c "$CONNECTION_NAME" -q "
        USE DATABASE AAA_DEV_SYNTHETIC_BANK;
        USE SCHEMA $schema;
        PUT file://$local_pattern @$stage_name AUTO_COMPRESS=FALSE;
    "
    local result=$?
    set -e
    
    if [[ $result -eq 0 ]]; then
        echo "   ✅ Success: $files_found files uploaded to $stage_name"
    else
        echo "   ❌ Failed to upload to $stage_name"
        return 1
    fi
    
    echo ""
}

# --- Function to upload single files ---
upload_single_files() {
    local source_dir="$1"
    local stage_name="$2"
    local schema="$3"
    local description="$4"
    local file_pattern="$5"
    
    echo "📤 Uploading $description..."
    echo "   Directory: $source_dir"
    echo "   Stage: $stage_name"
    echo "   Schema: $schema"
    echo "   Pattern: $file_pattern"
    
    if [[ ! -d "$source_dir" ]]; then
        echo "   ⚠️  Directory not found: $source_dir"
        return 0
    fi
    
    # Count files
    local file_count=$(find "$source_dir" -name "$file_pattern" -type f | wc -l)
    echo "   📊 Found $file_count files"
    
    if [[ $file_count -eq 0 ]]; then
        echo "   ⚠️  No files found in $source_dir matching $file_pattern"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "   🧪 DRY RUN: Would upload $file_count files from $source_dir"
        return 0
    fi
    
    # Upload files to stage (uncompressed for task processing)
    set +e
    snow sql -c "$CONNECTION_NAME" -q "
        USE DATABASE AAA_DEV_SYNTHETIC_BANK;
        USE SCHEMA $schema;
        PUT file://$source_dir/$file_pattern @$stage_name AUTO_COMPRESS=FALSE;
    "
    local result=$?
    set -e
    
    if [[ $result -eq 0 ]]; then
        echo "   ✅ Success: $file_count files uploaded to $stage_name"
    else
        echo "   ❌ Failed to upload to $stage_name"
        return 1
    fi
    
    echo ""
}

# =============================================================================
# UPLOAD CUSTOMER & ACCOUNT DATA
# =============================================================================
echo "🏦 CUSTOMER & ACCOUNT DATA"
echo "=========================="

# Customer master data
upload_to_stage \
    "$GENERATED_DATA_DIR/master_data/customers.csv" \
    "CRMI_CUSTOMERS" \
    "CRM_RAW_001" \
    "Customer Master Data"

# Customer addresses (SCD Type 2)
upload_to_stage \
    "$GENERATED_DATA_DIR/master_data/customer_addresses.csv" \
    "CRMI_ADDRESSES" \
    "CRM_RAW_001" \
    "Customer Addresses (SCD Type 2)"

# Customer address updates (SCD Type 2 historical changes)
upload_single_files \
    "$GENERATED_DATA_DIR/master_data/address_updates" \
    "CRMI_ADDRESSES" \
    "CRM_RAW_001" \
    "Customer Address Updates (SCD Type 2)" \
    "customer_addresses_*.csv"

# Exposed Person compliance data
upload_to_stage \
    "$GENERATED_DATA_DIR/master_data/pep_data.csv" \
    "CRMI_EXPOSED_PERSON" \
    "CRM_RAW_001" \
    "Exposed Person Compliance Data"

# Account master data
upload_to_stage \
    "$GENERATED_DATA_DIR/master_data/accounts.csv" \
    "ACCI_ACCOUNTS" \
    "CRM_RAW_001" \
    "Account Master Data"

# =============================================================================
# UPLOAD REFERENCE DATA
# =============================================================================
echo "💱 REFERENCE DATA"
echo "================="

# FX Rates
upload_single_files \
    "$GENERATED_DATA_DIR/fx_rates" \
    "REFI_FX_RATES" \
    "REF_RAW_001" \
    "FX Rates" \
    "fx_rates_*.csv"

# =============================================================================
# UPLOAD PAYMENT DATA
# =============================================================================
echo "💳 PAYMENT DATA"
echo "==============="

# Payment transactions
upload_single_files \
    "$GENERATED_DATA_DIR/payment_transactions" \
    "PAYI_TRANSACTIONS" \
    "PAY_RAW_001" \
    "Payment Transactions" \
    "pay_transactions_*.csv"

# SWIFT ISO20022 messages
upload_single_files \
    "$GENERATED_DATA_DIR/swift_messages" \
    "ICGI_RAW_SWIFT_INBOUND" \
    "PAY_RAW_001" \
    "SWIFT ISO20022 Messages" \
    "*.xml"

# =============================================================================
# UPLOAD TRADING DATA
# =============================================================================
echo "📈 TRADING DATA"
echo "==============="

# Equity trades
upload_single_files \
    "$GENERATED_DATA_DIR/equity_trades" \
    "EQTI_TRADES" \
    "EQT_RAW_001" \
    "Equity Trades" \
    "trades_*.csv"

# Fixed Income trades
upload_single_files \
    "$GENERATED_DATA_DIR/fixed_income_trades" \
    "FIII_TRADES" \
    "FII_RAW_001" \
    "Fixed Income Trades" \
    "fixed_income_trades_*.csv"

# Commodity trades
upload_single_files \
    "$GENERATED_DATA_DIR/commodity_trades" \
    "CMDI_TRADES" \
    "CMD_RAW_001" \
    "Commodity Trades" \
    "commodity_trades_*.csv"

# =============================================================================
# UPLOAD LOAN DOCUMENTS
# =============================================================================
echo "📄 LOAN DOCUMENTS"
echo "================="

# Email documents
upload_single_files \
    "$GENERATED_DATA_DIR/emails" \
    "LOAI_RAW_EMAIL_INBOUND" \
    "LOA_RAW_v001" \
    "Loan Email Documents" \
    "*.txt"

# PDF documents
upload_single_files \
    "$GENERATED_DATA_DIR/creditcard_pdf" \
    "LOAI_RAW_PDF_INBOUND" \
    "LOA_RAW_v001" \
    "Loan PDF Documents" \
    "*.pdf"

# =============================================================================
# UPLOAD SUMMARY
# =============================================================================
echo "📊 UPLOAD SUMMARY"
echo "================="

if [[ "$DRY_RUN" == "true" ]]; then
    echo "🧪 DRY RUN COMPLETED - No files were actually uploaded"
    echo ""
    echo "To execute the actual upload, run:"
    echo "  ./upload-data.sh --CONNECTION_NAME=$CONNECTION_NAME"
else
    echo "✅ All data uploads completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Monitor task execution: SHOW TASKS IN DATABASE AAA_DEV_SYNTHETIC_BANK;"
    echo "2. Check data loading: SELECT COUNT(*) FROM [schema].[table];"
    echo "3. Verify stage contents: LIST @[stage_name];"
    echo "4. Check which streams have data: SHOW STREAMS IN DATABASE AAA_DEV_SYNTHETIC_BANK;"
    echo ""
    echo "Data is now ready for automated processing by Snowflake tasks!"
fi

echo "🎉 Upload process completed!"
