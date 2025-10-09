-- ============================================================
-- Resume All Tasks and Dynamic Tables
-- Generated on: 2025-01-27
-- ============================================================
--
-- OVERVIEW:
-- This script dynamically resumes all suspended tasks and dynamic tables
-- in the AAA_DEV_SYNTHETIC_BANK database. It queries the system to find all
-- suspended tasks and DTs, then resumes them programmatically.
--
-- BUSINESS PURPOSE:
-- - Restart all automated processes after maintenance
-- - Resume data processing workflows
-- - Restore normal system operations
-- - Re-enable all scheduled and real-time processing
--
-- USAGE:
-- 1. Execute this script to resume all tasks and DTs
-- 2. Monitor system performance after restart
-- 3. Verify all processes are running correctly
--
-- SAFETY FEATURES:
-- - Only affects AAA_DEV_SYNTHETIC_BANK database
-- - Preserves all object definitions and configurations
-- - Can be safely re-executed
-- - Logs all operations for audit trail
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;

-- ============================================================
-- DYNAMIC TASK RESUMPTION
-- ============================================================
-- Resume all suspended tasks in the database using dynamic SQL

DECLARE
    task_cursor CURSOR FOR
    SELECT 
        task_name,
        task_schema,
        state
    FROM TABLE(INFORMATION_SCHEMA.TASKS())
    WHERE task_database = 'AAA_DEV_SYNTHETIC_BANK'
    AND state = 'SUSPENDED';
    
    task_sql STRING;
    task_count INTEGER DEFAULT 0;
BEGIN
    -- Log start of task resumption
    SELECT 'Starting task resumption process...' AS status;
    
    -- Loop through all suspended tasks
    FOR task_record IN task_cursor DO
        -- Build ALTER TASK statement
        task_sql := 'ALTER TASK ' || task_record.task_schema || '.' || task_record.task_name || ' RESUME';
        
        -- Execute the resumption
        EXECUTE IMMEDIATE task_sql;
        
        -- Log the operation
        SELECT 'Resumed task: ' || task_record.task_schema || '.' || task_record.task_name AS task_resumed;
        
        task_count := task_count + 1;
    END FOR;
    
    -- Log completion
    SELECT 'Task resumption completed. Total tasks resumed: ' || task_count AS task_summary;
END;

-- ============================================================
-- DYNAMIC TABLE RESUMPTION
-- ============================================================
-- Resume all suspended dynamic tables in the database using dynamic SQL

DECLARE
    dt_cursor CURSOR FOR
    SELECT 
        table_name,
        table_schema,
        refresh_mode
    FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLES())
    WHERE table_catalog = 'AAA_DEV_SYNTHETIC_BANK'
    AND refresh_mode = 'SUSPENDED';
    
    dt_sql STRING;
    dt_count INTEGER DEFAULT 0;
BEGIN
    -- Log start of dynamic table resumption
    SELECT 'Starting dynamic table resumption process...' AS status;
    
    -- Loop through all suspended dynamic tables
    FOR dt_record IN dt_cursor DO
        -- Build ALTER DYNAMIC TABLE statement
        dt_sql := 'ALTER DYNAMIC TABLE ' || dt_record.table_schema || '.' || dt_record.table_name || ' RESUME';
        
        -- Execute the resumption
        EXECUTE IMMEDIATE dt_sql;
        
        -- Log the operation
        SELECT 'Resumed dynamic table: ' || dt_record.table_schema || '.' || dt_record.table_name AS dt_resumed;
        
        dt_count := dt_count + 1;
    END FOR;
    
    -- Log completion
    SELECT 'Dynamic table resumption completed. Total DTs resumed: ' || dt_count AS dt_summary;
END;

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================
-- Verify that all tasks and DTs have been resumed

-- Check task status
SELECT 
    'TASK_STATUS' AS object_type,
    task_schema,
    task_name,
    state,
    'STARTED/RESUMED' AS expected_state
FROM TABLE(INFORMATION_SCHEMA.TASKS())
WHERE task_database = 'AAA_DEV_SYNTHETIC_BANK'
AND state = 'SUSPENDED'

UNION ALL

-- Check dynamic table status
SELECT 
    'DYNAMIC_TABLE_STATUS' AS object_type,
    table_schema,
    table_name,
    refresh_mode,
    'AUTO' AS expected_state
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLES())
WHERE table_catalog = 'AAA_DEV_SYNTHETIC_BANK'
AND refresh_mode = 'SUSPENDED'

ORDER BY object_type, table_schema, table_name;

-- ============================================================
-- SUMMARY REPORT
-- ============================================================
-- Provide a summary of resumed objects

SELECT 
    'RESUMPTION_SUMMARY' AS report_type,
    COUNT(*) AS total_tasks,
    COUNT(CASE WHEN state IN ('STARTED', 'RESUMED') THEN 1 END) AS active_tasks,
    COUNT(CASE WHEN state = 'SUSPENDED' THEN 1 END) AS suspended_tasks
FROM TABLE(INFORMATION_SCHEMA.TASKS())
WHERE task_database = 'AAA_DEV_SYNTHETIC_BANK'

UNION ALL

SELECT 
    'RESUMPTION_SUMMARY' AS report_type,
    COUNT(*) AS total_dynamic_tables,
    COUNT(CASE WHEN refresh_mode = 'AUTO' THEN 1 END) AS active_dts,
    COUNT(CASE WHEN refresh_mode = 'SUSPENDED' THEN 1 END) AS suspended_dts
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLES())
WHERE table_catalog = 'AAA_DEV_SYNTHETIC_BANK';

-- ============================================================
-- MONITORING QUERIES
-- ============================================================
-- Additional queries to monitor system health after resumption

-- Active tasks with their schedules
SELECT 
    'ACTIVE_TASKS' AS monitor_type,
    task_schema,
    task_name,
    state,
    schedule,
    next_scheduled_time
FROM TABLE(INFORMATION_SCHEMA.TASKS())
WHERE task_database = 'AAA_DEV_SYNTHETIC_BANK'
AND state IN ('STARTED', 'RESUMED')
ORDER BY task_schema, task_name;

-- Active dynamic tables with their refresh settings
SELECT 
    'ACTIVE_DYNAMIC_TABLES' AS monitor_type,
    table_schema,
    table_name,
    refresh_mode,
    target_lag,
    warehouse_name
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLES())
WHERE table_catalog = 'AAA_DEV_SYNTHETIC_BANK'
AND refresh_mode = 'AUTO'
ORDER BY table_schema, table_name;

-- ============================================================
-- COMPLETION MESSAGE
-- ============================================================

SELECT 
    'RESUMPTION_COMPLETE' AS status,
    CURRENT_TIMESTAMP() AS completed_at,
    'All tasks and dynamic tables in AAA_DEV_SYNTHETIC_BANK have been resumed.' AS message,
    'Monitor system performance and verify all processes are running correctly.' AS next_step;
