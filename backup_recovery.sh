#!/bin/bash

# ============================================================
# PLP HANDS-ON LAB
# Backups, Point-in-Time Recovery, and Replication
# ============================================================

# ------------------------------------------------------------
# 1. VARIABLES
# ------------------------------------------------------------

DB_NAME="your_database"
DB_USER="postgres"

BACKUP_DIR="/var/backups/postgresql"
WAL_ARCHIVE="/var/lib/postgresql/wal_archive"
BASE_BACKUP="/var/backups/postgresql/base_backup"

# ------------------------------------------------------------
# 2. CREATE BACKUP DIRECTORIES
# ------------------------------------------------------------

mkdir -p "$BACKUP_DIR"
mkdir -p "$WAL_ARCHIVE"
mkdir -p "$BASE_BACKUP"

# ------------------------------------------------------------
# 3. LOGICAL BACKUP USING pg_dump
# ------------------------------------------------------------

pg_dump -U "$DB_USER" -d "$DB_NAME" \
    -F c \
    -f "$BACKUP_DIR/${DB_NAME}_backup.dump"

echo "Logical backup completed."

# ------------------------------------------------------------
# 4. WAL ARCHIVING
# ------------------------------------------------------------

# Add the following settings to postgresql.conf:

# wal_level = replica
# archive_mode = on
# archive_command = 'cp %p /var/lib/postgresql/wal_archive/%f'

# After changing postgresql.conf, restart PostgreSQL.

# Example:

# sudo systemctl restart postgresql

# ------------------------------------------------------------
# 5. CREATE A BASE BACKUP
# ------------------------------------------------------------

pg_basebackup \
    -U "$DB_USER" \
    -D "$BASE_BACKUP" \
    -Fp \
    -Xs \
    -P

echo "Base backup completed."

# ------------------------------------------------------------
# 6. POINT-IN-TIME RECOVERY
# ------------------------------------------------------------

# Stop PostgreSQL before restoring:

# sudo systemctl stop postgresql

# Restore/copy the base backup to the PostgreSQL data directory.

# Example:

# sudo rm -rf /var/lib/postgresql/data/*
# sudo cp -a "$BASE_BACKUP"/. /var/lib/postgresql/data/

# Configure recovery target in PostgreSQL.

# For PostgreSQL versions that use recovery.signal:

# sudo touch /var/lib/postgresql/data/recovery.signal

# Add the following to postgresql.conf:

# restore_command = 'cp /var/lib/postgresql/wal_archive/%f %p'
# recovery_target_time = 'YYYY-MM-DD HH:MM:SS'

# Start PostgreSQL:

# sudo systemctl start postgresql

# PostgreSQL will replay WAL files until the specified
# recovery target is reached.

# ------------------------------------------------------------
# 7. STREAMING REPLICATION
# ------------------------------------------------------------

# Create a replication user on the primary:

# sudo -u postgres psql

# Then execute:

# CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'StrongPassword';

# ------------------------------------------------------------
# 8. pg_hba.conf CONFIGURATION
# ------------------------------------------------------------

# Add an appropriate replication rule to pg_hba.conf:

# host    replication    replicator    STANDBY_IP/32    scram-sha-256

# Example:

# host    replication    replicator    192.168.1.20/32    scram-sha-256

# Reload PostgreSQL after changing pg_hba.conf:

# sudo systemctl reload postgresql

# ------------------------------------------------------------
# 9. CREATE STANDBY USING pg_basebackup
# ------------------------------------------------------------

# Run on the standby server:

# pg_basebackup \
#     -h PRIMARY_IP \
#     -U replicator \
#     -D /var/lib/postgresql/data \
#     -Fp \
#     -Xs \
#     -P \
#     -R

# The -R option creates the standby connection configuration.

# ------------------------------------------------------------
# 10. START THE STANDBY
# ------------------------------------------------------------

# sudo systemctl start postgresql

# ------------------------------------------------------------
# 11. VERIFY REPLICATION
# ------------------------------------------------------------

# On the primary:

# psql -U postgres -d your_database

# SELECT * FROM pg_stat_replication;

# On the standby:

# SELECT pg_is_in_recovery();

# ------------------------------------------------------------
# 12. CHECK REPLICATION LAG
# ------------------------------------------------------------

# On the primary:

# SELECT
#     application_name,
#     client_addr,
#     state,
#     sync_state,
#     pg_wal_lsn_diff(sent_lsn, replay_lsn) AS byte_lag
# FROM pg_stat_replication;

# ============================================================
# END OF BACKUP, PITR AND REPLICATION PROCEDURE
# ============================================================
