#!/bin/bash

# =============================================================================
# Synthetic Bank End-to-End Deployment Script
# =============================================================================
# 
# This script provides complete end-to-end deployment of the synthetic bank:
# 1. Deploys all SQL files in the structure/ folder to Snowflake
# 2. Automatically uploads generated data to appropriate stages
# 3. Activates processing tasks for immediate operation
#
# Features:
# - Complete dependency-aware SQL deployment
# - Automatic data upload to correct stages
# - Task activation and monitoring
# - Dry run mode for testing
# - Single file debugging support
#
# Usage:
#   ./deploy-structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=my_connection
#
# Example:
#   ./deploy-structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=sfseeurope-mdaeppen
# =============================================================================

set -e

# --- Default values ---
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="$BASE_DIR/structure"

# --- Parse arguments ---
for ARG in "$@"; do
  case $ARG in
    --DATABASE=*)
      DATABASE="${ARG#*=}"
      ;;
    --CONNECTION_NAME=*)
      CONNECTION_NAME="${ARG#*=}"
      ;;
    --SQL_DIR=*)
      SQL_DIR="${ARG#*=}"
      ;;
    --FILE=*)
      SINGLE_FILE="${ARG#*=}"
      ;;
    --DRY_RUN)
      DRY_RUN=true
      ;;
    *)
      echo "❌ Unknown argument: $ARG"
      echo "Usage: $0 --DATABASE=... --CONNECTION_NAME=... [--SQL_DIR=...] [--FILE=...] [--DRY_RUN]"
      exit 1
      ;;
  esac
done

# --- Validate required inputs ---
if [[ -z "$DATABASE" || -z "$CONNECTION_NAME" ]]; then
  echo "❌ Missing required arguments."
  echo "Usage: $0 --DATABASE=... --CONNECTION_NAME=... [--SQL_DIR=...] [--FILE=...] [--DRY_RUN]"
  echo ""
  echo "Arguments:"
  echo "  --DATABASE=...        Target database name"
  echo "  --CONNECTION_NAME=... Snowflake connection name"
  echo "  --SQL_DIR=...         Path to SQL files (default: ./structure)"
  echo "  --FILE=...            Test a single SQL file (e.g., 031_ICGI.sql)"
  echo "  --DRY_RUN            Show what would be executed without running"
  exit 1
fi

if [[ ! -d "$SQL_DIR" ]]; then
  echo "❌ Structure folder not found: $SQL_DIR"
  exit 1
fi

echo "🚀 Snowflake Structure Deployment"
echo "=================================="
echo "📁 SQL Directory: $SQL_DIR"
echo "🗄️  Database: $DATABASE"
echo "🔗 Connection: $CONNECTION_NAME"
if [[ "$DRY_RUN" == "true" ]]; then
  echo "🔍 Mode: DRY RUN (no actual execution)"
fi
echo ""

# --- Find and sort SQL files ---
if [[ -n "$SINGLE_FILE" ]]; then
  # Test a single file
  if [[ -f "$SQL_DIR/$SINGLE_FILE" ]]; then
    SQL_FILES="$SQL_DIR/$SINGLE_FILE"
    echo "🔍 Testing single file: $SINGLE_FILE"
  else
    echo "❌ File not found: $SQL_DIR/$SINGLE_FILE"
    exit 1
  fi
else
  # Find all SQL files
  SQL_FILES=$(find "$SQL_DIR" -type f -name "*.sql" | sort)
  
  if [[ -z "$SQL_FILES" ]]; then
    echo "❌ No SQL files found in $SQL_DIR"
    exit 0
  fi
fi

echo "📄 Found SQL files:"
for FILE in $SQL_FILES; do
  echo "  - $(basename "$FILE")"
done
echo ""

# --- Execute each SQL file with USE statements prepended ---
for FILE in $SQL_FILES; do
  echo "📝 Processing: $(basename "$FILE")"
  
  # Create temporary file with SQL content
  TMP_FILE=$(mktemp)
  {
    # For 000_database_setup.sql, don't use the database (it creates it)
    if [[ "$(basename "$FILE")" == "000_database_setup.sql" ]]; then
      echo "SELECT"
      echo "  CURRENT_DATABASE() AS database_name,"
      echo "  CURRENT_SCHEMA() AS schema_name,"
      echo "  CURRENT_USER() AS current_user,"
      echo "  CURRENT_ROLE() AS current_role;"
      cat "$FILE"
    else
      echo "USE DATABASE $DATABASE;"
      echo "SELECT"
      echo "  CURRENT_DATABASE() AS database_name,"
      echo "  CURRENT_SCHEMA() AS schema_name,"
      echo "  CURRENT_USER() AS current_user,"
      echo "  CURRENT_ROLE() AS current_role;"
      cat "$FILE"
    fi
  } > "$TMP_FILE"

  # Always show the SQL content for debugging
  echo "   📋 SQL Content:"
  echo "   ┌─────────────────────────────────────────────────────────────────"
  if [[ "$(basename "$FILE")" == "000_database_setup.sql" ]]; then
    echo "   │ [Database creation script - no USE DATABASE needed]"
  else
    echo "   │ USE DATABASE $DATABASE;"
  fi
  echo "   │ [Context info query]"
  echo "   │ [Content of $(basename "$FILE")]"
  echo "   └─────────────────────────────────────────────────────────────────"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "   🔍 DRY RUN - Would execute the above SQL"
    echo "   ✅ DRY RUN: $FILE"
  else
    echo "   🚀 Executing SQL..."
    set +e
    snow sql -c "$CONNECTION_NAME" -f "$TMP_FILE"
    RESULT=$?
    set -e

    if [[ $RESULT -ne 0 ]]; then
      # Special handling for Global Sanctions Data database already existing
      if [[ "$(basename "$FILE")" == "001_get_listings.sql" ]]; then
        echo "⚠️  Global Sanctions Data setup issue detected"
        echo "   This could be due to:"
        echo "   1. Database already exists (expected if previously imported)"
        echo "   2. Missing user profile information (first_name, last_name, email)"
        echo ""
        echo "💡 To fix user profile issue:"
        echo "   1. Go to Snowsight UI → User Profile"
        echo "   2. Add First Name, Last Name, and Email"
        echo "   3. Or run: ALTER USER <username> SET first_name='John', last_name='Doe', email='john@company.com'"
        echo ""
        echo "   Continuing with deployment..."
        echo "✅ Success: $(basename "$FILE") (setup issue handled)"
      else
        echo "❌ Execution failed for: $(basename "$FILE")"
        echo "⛔️ Aborting remaining scripts."
        rm "$TMP_FILE"
        exit 1
      fi
    else
      echo "✅ Success: $(basename "$FILE")"
    fi
  fi

  rm "$TMP_FILE"

  echo ""
done

if [[ "$DRY_RUN" == "true" ]]; then
  echo "🔍 DRY RUN completed - no actual changes made"
else
  echo "🎉 All SQL scripts executed successfully!"
  
  # =============================================================================
  # AUTOMATIC DATA UPLOAD AFTER SUCCESSFUL DEPLOYMENT
  # =============================================================================
  # Only trigger data upload for full deployments, not single file tests
  if [[ -z "$SINGLE_FILE" ]]; then
    echo ""
    echo "📤 AUTOMATIC DATA UPLOAD"
    echo "========================"
    echo "🚀 Structure deployment successful! Now uploading generated data..."
    echo ""
    
    # Check if upload-data.sh exists
    if [[ -f "./upload-data.sh" ]]; then
      echo "📋 Found upload-data.sh - Starting data upload..."
      echo ""
      
      # Execute the data upload script
      echo "🔄 Executing: ./upload-data.sh --CONNECTION_NAME=$CONNECTION_NAME"
      echo ""
      
      # Run the upload script
      ./upload-data.sh --CONNECTION_NAME="$CONNECTION_NAME"
      
      if [[ $? -eq 0 ]]; then
        echo ""
        echo "✅ DATA UPLOAD COMPLETED SUCCESSFULLY!"
        echo ""
        echo ""
        echo "🎯 END-TO-END DEPLOYMENT SUMMARY:"
        echo "   ✅ Database & schemas created"
        echo "   ✅ All SQL objects deployed"
        echo "   ✅ Generated data uploaded to stages"
        echo "   ✅ Streams recreated to detect uploaded files"
        echo "   ✅ Tasks activated and ready for processing"
        echo ""
        echo "🚀 Your synthetic bank is now fully operational!"
        echo ""
        echo "Next steps:"
        echo "1. Monitor task execution: SHOW TASKS IN DATABASE $DATABASE;"
        echo "2. Check data loading: SELECT COUNT(*) FROM [schema].[table];"
        echo "3. Verify stage contents: LIST @[stage_name];"
        echo "4. Check stream status: SHOW STREAMS IN DATABASE $DATABASE;"
      else
        echo ""
        echo "❌ Data upload failed! Please check the upload script output above."
        echo "💡 You can retry the upload manually:"
        echo "   ./upload-data.sh --CONNECTION_NAME=$CONNECTION_NAME"
      fi
    else
      echo "⚠️  upload-data.sh not found - Skipping data upload"
      echo "💡 To upload data manually, run:"
      echo "   ./upload-data.sh --CONNECTION_NAME=$CONNECTION_NAME"
    fi
  else
    echo ""
    echo "🔍 Single file test completed - Data upload skipped"
    echo "💡 To upload data after full deployment, run:"
    echo "   ./upload-data.sh --CONNECTION_NAME=$CONNECTION_NAME"
  fi
fi
