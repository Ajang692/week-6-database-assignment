# PostgreSQL Backups, Point-in-Time Recovery, and Replication

## Overview

This project demonstrates PostgreSQL backup, point-in-time recovery (PITR), WAL archiving, and streaming replication.

The project contains SQL verification queries and a companion shell script documenting the operating-system commands and PostgreSQL configuration changes required to perform the backup and recovery procedures.

## Files

- `answers.sql` - SQL commands used to verify PostgreSQL configuration, recovery status, replication status, and replication lag.
- `backup_recovery.sh` - Shell commands documenting logical backups, WAL archiving, base backups, PITR, and streaming replication.
- `README.md` - Documentation for the project.

## 1. Logical Backup

A logical backup can be created using `pg_dump`.

Example:

```bash
pg_dump -U postgres -d your_database -F c -f backup.dump

wal_level = replica
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/wal_archive/%f'

pg_basebackup -U postgres -D /var/backups/postgresql/base_backup -Fp -Xs -P

restore_command = 'cp /var/lib/postgresql/wal_archive/%f %p'
recovery_target_time = 'YYYY-MM-DD HH:MM:SS'

CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'StrongPassword';

pg_basebackup -h PRIMARY_IP -U replicator -D /var/lib/postgresql/data -Fp -Xs -P -R

SELECT * FROM pg_stat_replication;
SELECT pg_is_in_recovery();

## Backup and Recovery Shell Script

The `backup_recovery.sh` script contains the ordered operating system
workflow for PostgreSQL backup, point-in-time recovery, and streaming
replication.

### Backup and Recovery Workflow

The recovery process follows these steps:

1. Create a directory for PostgreSQL backups.
2. Use `pg_dump` to create a logical database backup.
3. Check the PostgreSQL WAL configuration.
4. Stop the PostgreSQL service before restoring the database cluster.
5. Back up or move the damaged PostgreSQL data directory.
6. Create a new PostgreSQL data directory.
7. Restore the base backup using `pg_basebackup`.
8. Configure the standby using the `-R` option.
9. Configure `pg_hba.conf` to allow the replication user to connect.
10. Set the correct PostgreSQL ownership and permissions.
11. Configure `restore_command` for WAL archive recovery.
12. Configure `recovery_target_time` for point-in-time recovery.
13. Start the PostgreSQL service.
14. Verify that PostgreSQL is running.
15. Use `pg_is_in_recovery()` to verify whether the server is a standby.
16. Check `pg_stat_replication` on the primary server.
17. Use `pg_wal_lsn_diff()` to measure replication lag in bytes.

### pg_hba.conf Replication Configuration

The standby server must be allowed to authenticate as the replication
user. The PostgreSQL `pg_hba.conf` file therefore needs a replication
entry such as:

    host replication replicator STANDBY_IP/32 scram-sha-256

This allows the `replicator` user on the standby server to establish a
streaming replication connection with the primary server.

### Important Recovery Actions

Before restoring a PostgreSQL data directory, the PostgreSQL service
must be stopped to prevent files from being modified while the
restoration is taking place.

The damaged data directory should be backed up or moved before the
restored base backup is placed into the active PostgreSQL data path.

After restoring the base backup, the correct PostgreSQL ownership and
permissions must be applied before starting the PostgreSQL service.

### Verification

The following PostgreSQL checks are used to verify the recovery and
replication configuration:

    SELECT pg_is_in_recovery();

    SELECT
        client_addr,
        state,
        sync_state,
        sent_lsn,
        write_lsn,
        flush_lsn,
        replay_lsn
    FROM pg_stat_replication;

Replication lag can be checked using:

    SELECT
        client_addr,
        pg_wal_lsn_diff(sent_lsn, replay_lsn)
        AS replication_lag_bytes
    FROM pg_stat_replication;

The `backup_recovery.sh` file documents the complete ordered shell
workflow, while `answers.sql` contains the SQL verification commands.
