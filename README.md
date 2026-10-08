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
