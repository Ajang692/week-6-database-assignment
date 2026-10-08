```sql
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
-- 3. CHECK WHETHER THIS SERVER IS IN RECOVERY MODE
-- ============================================================

SELECT pg_is_in_recovery();


-- ============================================================
-- 4. CHECK DATABASE DATA DIRECTORY
-- ============================================================

SHOW data_directory;


-- ============================================================
-- 5. CHECK PG_HBA CONFIGURATION FILE
-- ============================================================

SHOW hba_file;


-- ============================================================
-- 6. CHECK STREAMING REPLICATION STATUS
-- Run this on the PRIMARY server
-- ============================================================

SELECT
    client_addr,
    state,
    sync_state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn
FROM pg_stat_replication;


-- ============================================================
-- 7. CHECK REPLICATION LAG
-- ============================================================

SELECT
    client_addr,
    pg_wal_lsn_diff(sent_lsn, replay_lsn)
        AS replication_lag_bytes
FROM pg_stat_replication;


-- ============================================================
-- 8. CHECK STANDBY RECOVERY STATUS
-- Run this on the STANDBY server
-- ============================================================

SELECT pg_is_in_recovery();


-- ============================================================
-- 9. CHECK STANDBY WAL RECEIVER
-- ============================================================

SELECT
    status,
    receive_start_lsn,
    received_lsn,
    latest_end_lsn,
    latest_end_time
FROM pg_stat_wal_receiver;


-- ============================================================
-- 10. CHECK CURRENT WAL LSN
-- ============================================================

SELECT pg_current_wal_lsn();


-- ============================================================
-- 11. CHECK CURRENT TIME
-- Used to identify the PITR recovery target
-- ============================================================

SELECT now();


-- ============================================================
-- 12. PITR RECOVERY TARGET USED IN THIS LAB
-- ============================================================

-- Recovery target:
-- 2026-10-07 13:23:32.085175+03


-- ============================================================
-- END OF ANSWERS
-- ============================================================
```
