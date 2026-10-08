-- ============================================================
-- PLP HANDS-ON LAB
-- Backups, Point-in-Time Recovery, and Replication
-- ============================================================

-- ============================================================
-- 1. CHECK WAL CONFIGURATION
-- ============================================================

SHOW wal_level;

SHOW archive_mode;

SHOW archive_command;


-- ============================================================
-- 2. CHECK CURRENT DATABASE
-- ============================================================

SELECT current_database();

SELECT current_user;


-- ============================================================
-- 3. CHECK WHETHER THIS SERVER IS IN RECOVERY
-- ============================================================

SELECT pg_is_in_recovery();


-- ============================================================
-- 4. CHECK REPLICATION STATUS ON PRIMARY
-- ============================================================

SELECT
    pid,
    usename,
    application_name,
    client_addr,
    state,
    sync_state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn
FROM pg_stat_replication;


-- ============================================================
-- 5. CHECK REPLICATION LAG
-- ============================================================

SELECT
    application_name,
    client_addr,
    state,
    sync_state,
    pg_wal_lsn_diff(sent_lsn, replay_lsn) AS byte_lag
FROM pg_stat_replication;


-- ============================================================
-- 6. CHECK WAL LOCATION
-- ============================================================

SELECT pg_current_wal_lsn();


-- ============================================================
-- 7. VERIFY RECOVERY STATUS ON STANDBY
-- ============================================================

SELECT pg_is_in_recovery();


-- ============================================================
-- 8. CHECK DATABASES
-- ============================================================

SELECT
    datname
FROM pg_database
ORDER BY datname;


-- ============================================================
-- 9. CHECK SERVER VERSION
-- ============================================================

SELECT version();


-- ============================================================
-- 10. VERIFY CURRENT TIME
-- Useful when documenting PITR target time
-- ============================================================

SELECT current_timestamp;


-- ============================================================
-- END OF SQL VERIFICATION
-- ============================================================
