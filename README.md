````markdown
# PLP Hands-On Lab: Backups, Point-in-Time Recovery, and Replication

## Overview

This project demonstrates PostgreSQL backup, Write-Ahead Logging (WAL), Point-in-Time Recovery (PITR), and streaming replication.

The lab covers:

- Logical database backups
- WAL configuration
- WAL archiving
- Physical base backups
- Point-in-Time Recovery
- Streaming replication
- Replication monitoring
- Replication lag
- PostgreSQL access control

---

## Files in This Repository

### answers.sql

Contains SQL commands used to:

- Check WAL configuration
- Check the current database
- Check the current PostgreSQL user
- Check recovery mode
- Check the PostgreSQL data directory
- Check the `pg_hba.conf` location
- Check streaming replication
- Measure replication lag
- Check WAL receiver status
- Check the current WAL LSN
- Check the current database time

### backup_recovery.sh

Contains the ordered operating-system workflow for:

- Creating a logical backup
- Checking WAL configuration
- Stopping PostgreSQL before recovery
- Protecting the damaged data directory
- Creating a new active data directory
- Restoring a base backup using `pg_basebackup`
- Configuring standby mode
- Configuring `pg_hba.conf`
- Configuring WAL recovery
- Setting the PITR recovery target
- Setting PostgreSQL ownership and permissions
- Starting PostgreSQL
- Verifying recovery
- Checking streaming replication
- Measuring replication lag

---

# 1. Logical Backup

A logical backup can be created using `pg_dump`.

Example:

```bash
pg_dump bootcamp > bootcamp_backup.sql
````

A custom-format backup can also be created using:

```bash
pg_dump -Fc bootcamp > bootcamp.dump
```

The logical backup can be used to restore database objects and data.

---

# 2. WAL Configuration

The following PostgreSQL settings are checked:

```sql
SHOW wal_level;

SHOW archive_mode;

SHOW archive_command;
```

## WAL

Write-Ahead Logging records database changes before those changes are written permanently to the database data files.

WAL supports:

* Crash recovery
* Streaming replication
* Point-in-Time Recovery

---

# 3. WAL Archiving

WAL archiving stores WAL files in an archive location so that they can be used during recovery.

The PostgreSQL configuration used in this lab included:

```text
wal_level = replica
archive_mode = on
archive_command = copy "%p" "C:\Program Files\PostgreSQL\16\wal_archive\%f"
```

The exact `archive_command` depends on the operating system and archive location.

---

# 4. Base Backup

A physical base backup can be created using:

```bash
pg_basebackup \
    -h PRIMARY_HOST \
    -D /var/lib/postgresql/data \
    -U replicator \
    -Fp \
    -Xs \
    -P \
    -R
```

Important options include:

* `-D` — destination data directory
* `-U` — replication user
* `-Fp` — plain format
* `-Xs` — include required WAL files
* `-P` — show progress
* `-R` — configure the standby for replication

---

# 5. Point-in-Time Recovery

Point-in-Time Recovery allows PostgreSQL to restore a database to a specific point in time using a base backup and archived WAL files.

The recovery process requires:

1. Stop the PostgreSQL service.
2. Protect or move the damaged data directory.
3. Restore the base backup into the active PostgreSQL data directory.
4. Configure the WAL `restore_command`.
5. Specify the recovery target time.
6. Start PostgreSQL.
7. Verify the recovery state.

The recovery target time used in this lab was:

```text
2026-10-07 13:23:32.085175+03
```

The recovery configuration is:

```text
restore_command = 'cp /var/lib/postgresql/wal_archive/%f %p'

recovery_target_time = '2026-10-07 13:23:32.085175+03'
```

The recovery target represents the point in time to which PostgreSQL should recover.

---

# 6. Important Recovery Actions

The PostgreSQL service must be stopped before replacing or restoring the data directory.

Example:

```bash
sudo systemctl stop postgresql
```

The damaged data directory should be protected rather than immediately deleted:

```bash
sudo mv /var/lib/postgresql/data \
        /var/lib/postgresql/data_damaged
```

A new active data directory can then be created:

```bash
sudo mkdir -p /var/lib/postgresql/data
```

The restored directory must have the correct PostgreSQL ownership and permissions:

```bash
sudo chown -R postgres:postgres /var/lib/postgresql/data

sudo chmod 700 /var/lib/postgresql/data
```

After restoring the backup and configuring recovery:

```bash
sudo systemctl start postgresql
```

This ordered process prevents PostgreSQL from modifying the files while recovery is taking place.

---

# 7. Replication User

A replication user is required for streaming replication.

Example:

```sql
CREATE ROLE replicator
WITH REPLICATION
LOGIN
PASSWORD 'your_secure_password';
```

The password should be replaced with a secure password when configuring an actual environment.

---

# 8. pg_hba.conf Replication Entry

The standby must be allowed to connect to the primary server.

An example `pg_hba.conf` entry is:

```text
host replication replicator STANDBY_IP/32 scram-sha-256
```

Where:

* `replication` identifies the replication connection
* `replicator` is the replication user
* `STANDBY_IP` is the IP address of the standby server
* `/32` restricts access to that specific IP address
* `scram-sha-256` provides password authentication

After changing `pg_hba.conf`, PostgreSQL should reload its configuration.

---

# 9. Streaming Replication

Streaming replication continuously sends WAL changes from the primary server to a standby server.

The standby can be checked using:

```sql
SELECT pg_is_in_recovery();
```

A standby normally returns:

```text
true
```

The primary normally returns:

```text
false
```

---

# 10. Check Replication Status

On the primary server:

```sql
SELECT
    client_addr,
    state,
    sync_state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn
FROM pg_stat_replication;
```

This provides information about connected standby servers.

---

# 11. Replication Lag

Replication lag can be measured using:

```sql
SELECT
    client_addr,
    pg_wal_lsn_diff(sent_lsn, replay_lsn)
        AS replication_lag_bytes
FROM pg_stat_replication;
```

The result shows the difference between the WAL position sent by the primary and the position replayed by the standby.

---

# 12. WAL Receiver

The standby's WAL receiver can be checked using:

```sql
SELECT
    status,
    receive_start_lsn,
    received_lsn,
    latest_end_lsn,
    latest_end_time
FROM pg_stat_wal_receiver;
```

This helps verify that the standby is receiving WAL from the primary.

---

# 13. Backup and Recovery Workflow

The complete recovery workflow is:

1. Create the backup directory.
2. Create a logical backup using `pg_dump`.
3. Check WAL configuration.
4. Stop the PostgreSQL service.
5. Back up or move the damaged data directory.
6. Create the active PostgreSQL data directory.
7. Restore the base backup using `pg_basebackup`.
8. Configure the standby using the `-R` option.
9. Add the replication entry to `pg_hba.conf`.
10. Configure `restore_command`.
11. Configure the PITR recovery target.
12. Set PostgreSQL ownership and permissions.
13. Start the PostgreSQL service.
14. Verify that PostgreSQL is running.
15. Use `pg_is_in_recovery()` to verify the standby.
16. Check `pg_stat_replication` on the primary.
17. Use `pg_wal_lsn_diff()` to measure replication lag.

---

# 14. Verification Commands

Check whether PostgreSQL is in recovery:

```sql
SELECT pg_is_in_recovery();
```

Check replication:

```sql
SELECT
    client_addr,
    state,
    sync_state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn
FROM pg_stat_replication;
```

Check replication lag:

```sql
SELECT
    client_addr,
    pg_wal_lsn_diff(sent_lsn, replay_lsn)
        AS replication_lag_bytes
FROM pg_stat_replication;
```

Check the WAL receiver:

```sql
SELECT
    status,
    receive_start_lsn,
    received_lsn,
    latest_end_lsn,
    latest_end_time
FROM pg_stat_wal_receiver;
```

---

# 15. Recovery Timestamp

The PITR timestamp recorded during the lab was:

```text
2026-10-07 13:23:32.085175+03
```

This timestamp is used as the recovery target in `backup_recovery.sh`.

---

# Conclusion

This lab demonstrates how PostgreSQL protects data through logical backups, WAL archiving, Point-in-Time Recovery, and streaming replication.

The `answers.sql` file contains the SQL verification commands, while `backup_recovery.sh` documents the complete ordered operating-system recovery workflow.

The recovery workflow includes stopping the PostgreSQL service, protecting the damaged data directory, restoring the base backup, configuring `pg_hba.conf`, configuring WAL recovery, setting the PITR target, restoring PostgreSQL ownership and permissions, and starting the service again.

```
```
