-- ============================================
-- PostgreSQL Backup and Disaster Recovery Lab
-- answers.sql
-- ============================================


-- ============================================
-- STEP 1: VERIFY LOGICAL BACKUP
-- ============================================

-- Connect to the bootcamp database
\c bootcamp

-- Check the students table
\dt

-- View the existing student data
SELECT * FROM students;


-- ============================================
-- STEP 2: VERIFY WAL ARCHIVING
-- ============================================

-- Check WAL level
SHOW wal_level;

-- Check archive mode
SHOW archive_mode;

-- Check archive command
SHOW archive_command;

-- Check PostgreSQL data directory
SHOW data_directory;


-- ============================================
-- STEP 3: SIMULATE DISASTER
-- ============================================

-- Record the current time BEFORE deleting the data.
-- Use this timestamp as the recovery_target_time.
SELECT now();

-- Simulate accidental deletion
DELETE FROM students;

-- Verify that the data has been deleted
SELECT count(*) FROM students;

-- Display the remaining data
SELECT * FROM students;


-- ============================================
-- STEP 3: POINT-IN-TIME RECOVERY
-- ============================================

-- After restoring the base backup and configuring
-- recovery_target_time, verify the recovered data.

SELECT count(*) FROM students;

SELECT * FROM students;

-- Check whether the server is still in recovery
SELECT pg_is_in_recovery();


-- ============================================
-- STEP 4: CREATE STREAMING REPLICATION USER
-- ============================================

-- Create the replication user
CREATE ROLE replicator
WITH REPLICATION LOGIN PASSWORD 'reppass';


-- Verify the replication role
SELECT rolname, rolreplication, rolcanlogin
FROM pg_roles
WHERE rolname = 'replicator';


-- ============================================
-- STEP 5: VERIFY STREAMING REPLICATION
-- ============================================

-- Check connected replication standby
SELECT application_name,
       state,
       sent_lsn,
       replay_lsn
FROM pg_stat_replication;


-- Check replication lag
SELECT application_name,
       state,
       pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
FROM pg_stat_replication;


-- Check whether the standby is in recovery
-- Run this while connected to the standby.
SELECT pg_is_in_recovery();


-- ============================================
-- FINAL VERIFICATION
-- ============================================

-- Verify students data
SELECT * FROM students;

-- Verify replication status
SELECT application_name,
       state,
       pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
FROM pg_stat_replication;
