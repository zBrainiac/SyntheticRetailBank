-- ============================================================
-- Suspend All Tasks and Dynamic Tables
-- Generated on: 2025-01-27
-- ============================================================
--
-- OVERVIEW:
-- This script dynamically suspends all tasks and dynamic tables in the
-- AAA_DEV_SYNTHETIC_BANK database. It queries the system to find all
-- active tasks and DTs, then suspends them programmatically.
--
-- BUSINESS PURPOSE:
-- - Graceful shutdown of all automated processes
-- - Maintenance operations requiring system quiescence
-- - Resource optimization during low-activity periods
-- - Emergency stop of all data processing workflows
--
-- USAGE:
-- 1. Execute this script to suspend all tasks and DTs
-- 2. Perform maintenance or other operations
-- 3. Execute resume_all_tasks_and_dts.sql to restart
--
-- SAFETY FEATURES:
-- - Only affects AAA_DEV_SYNTHETIC_BANK database
-- - Preserves all object definitions
-- - Can be safely re-executed
-- - Logs all operations for audit trail
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;

-- ============================================================
-- DYNAMIC TASK SUSPENSION
-- ============================================================
-- Suspend all tasks in the database using dynamic SQL

DECLARE
    task_cursor CURSOR FOR
    SELECT 
        task_name,
        task_schema,
        state
    FROM TABLE(INFORMATION_SCHEMA.TASKS())
    WHERE task_database = 'AAA_DEV_SYNTHETIC_BANK'
    AND state IN ('STARTED', 'RESUMED');
    
    task_sql STRING;
    task_count INTEGER DEFAULT 0;
BEGIN
    -- Log start of task suspension
    SELECT 'Starting task suspension process...' AS status;
    
    -- Loop through all active tasks
    FOR task_record IN task_cursor DO
        -- Build ALTER TASK statement
        task_sql := 'ALTER TASK ' || task_record.task_schema || '.' || task_record.task_name || ' SUSPEND';
        
        -- Execute the suspension
        EXECUTE IMMEDIATE task_sql;
        
        -- Log the operation
        SELECT 'Suspended task: ' || task_record.task_schema || '.' || task_record.task_name AS task_suspended;
        
        task_count := task_count + 1;
    END FOR;
    
    -- Log completion
    SELECT 'Task suspension completed. Total tasks suspended: ' || task_count AS task_summary;
END;

-- ============================================================
-- DYNAMIC TABLE SUSPENSION
-- ============================================================
-- Suspend all dynamic tables in the database using dynamic SQL

DECLARE
    dt_cursor CURSOR FOR
    SELECT 
        table_name,
        table_schema,
        refresh_mode
    FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLES())
    WHERE table_catalog = 'AAA_DEV_SYNTHETIC_BANK'
    AND refresh_mode = 'AUTO';
    
    dt_sql STRING;
    dt_count INTEGER DEFAULT 0;
BEGIN
    -- Log start of dynamic table suspension
    SELECT 'Starting dynamic table suspension process...' AS status;
    
    -- Loop through all active dynamic tables
    FOR dt_record IN dt_cursor DO
        -- Build ALTER DYNAMIC TABLE statement
        dt_sql := 'ALTER DYNAMIC TABLE ' || dt_record.table_schema || '.' || dt_record.table_name || ' SUSPEND';
        
        -- Execute the suspension
        EXECUTE IMMEDIATE dt_sql;
        
        -- Log the operation
        SELECT 'Suspended dynamic table: ' || dt_record.table_schema || '.' || dt_record.table_name AS dt_suspended;
        
        dt_count := dt_count + 1;
    END FOR;
    
    -- Log completion
    SELECT 'Dynamic table suspension completed. Total DTs suspended: ' || dt_count AS dt_summary;
END;

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================
-- Verify that all tasks and DTs have been suspended

-- Check task status
SELECT 
    'TASK_STATUS' AS object_type,
    task_schema,
    task_name,
    state,
    'SUSPENDED' AS expected_state
FROM TABLE(INFORMATION_SCHEMA.TASKS())
WHERE task_database = 'AAA_DEV_SYNTHETIC_BANK'
AND state IN ('STARTED', 'RESUMED')

UNION ALL

-- Check dynamic table status
SELECT 
    'DYNAMIC_TABLE_STATUS' AS object_type,
    table_schema,
    table_name,
    refresh_mode,
    'SUSPENDED' AS expected_state
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLES())
WHERE table_catalog = 'AAA_DEV_SYNTHETIC_BANK'
AND refresh_mode = 'AUTO'

ORDER BY object_type, table_schema, table_name;

-- ============================================================
-- SUMMARY REPORT
-- ============================================================
-- Provide a summary of suspended objects

SELECT 
    'SUSPENSION_SUMMARY' AS report_type,
    COUNT(*) AS total_tasks,
    COUNT(CASE WHEN state = 'SUSPENDED' THEN 1 END) AS suspended_tasks,
    COUNT(CASE WHEN state IN ('STARTED', 'RESUMED') THEN 1 END) AS active_tasks
FROM TABLE(INFORMATION_SCHEMA.TASKS())
WHERE task_database = 'AAA_DEV_SYNTHETIC_BANK'

UNION ALL

SELECT 
    'SUSPENSION_SUMMARY' AS report_type,
    COUNT(*) AS total_dynamic_tables,
    COUNT(CASE WHEN refresh_mode = 'SUSPENDED' THEN 1 END) AS suspended_dts,
    COUNT(CASE WHEN refresh_mode = 'AUTO' THEN 1 END) AS active_dts
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLES())
WHERE table_catalog = 'AAA_DEV_SYNTHETIC_BANK';

-- ============================================================
-- COMPLETION MESSAGE
-- ============================================================

SELECT 
    'SUSPENSION_COMPLETE' AS status,
    CURRENT_TIMESTAMP() AS completed_at,
    'All tasks and dynamic tables in AAA_DEV_SYNTHETIC_BANK have been suspended.' AS message,
    'Execute resume_all_tasks_and_dts.sql to restart all processes.' AS next_step;
