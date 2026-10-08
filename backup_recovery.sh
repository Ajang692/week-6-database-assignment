```bash
#!/bin/bash

# ============================================================
# PLP HANDS-ON LAB
# Backups, Point-in-Time Recovery, and Replication
# ============================================================

set -e

# ============================================================
# 1. VARIABLES
# ============================================================

DB_NAME="bootcamp"

BACKUP_DIR="/var/backups/postgresql"

DATA_DIR="/var/lib/postgresql/data"

DAMAGED_DATA_DIR="/var/lib/postgresql/data_damaged"

REPLICATOR_USER="replicator"

PRIMARY_HOST="PRIMARY_HOST"

STANDBY_IP="STANDBY_IP"

WAL_ARCHIVE_DIR="/var/lib/postgresql/wal_archive"

# PITR recovery target from the lab
RECOVERY_TARGET_TIME="2026-10-07 13:23:32.085175+03"


# ============================================================
# 2. CREATE BACKUP DIRECTORY
# ============================================================

sudo mkdir -p "$BACKUP_DIR"


# ============================================================
# 3. CREATE LOGICAL BACKUP
# ============================================================

pg_dump "$DB_NAME" \
    > "$BACKUP_DIR/${DB_NAME}_backup.sql"

echo "Logical backup created:"

ls -lh "$BACKUP_DIR/${DB_NAME}_backup.sql"


# ============================================================
# 4. CHECK WAL CONFIGURATION
# ============================================================

psql -d "$DB_NAME" -c "SHOW wal_level;"

psql -d "$DB_NAME" -c "SHOW archive_mode;"

psql -d "$DB_NAME" -c "SHOW archive_command;"


# ============================================================
# 5. STOP POSTGRESQL SERVICE
# IMPORTANT:
# PostgreSQL must be stopped before restoring the data cluster.
# ============================================================

sudo systemctl stop postgresql


# ============================================================
# 6. PROTECT THE DAMAGED DATA DIRECTORY
# Do not delete the existing data directory.
# Move it so it can be preserved for investigation/recovery.
# ============================================================

if [ -d "$DATA_DIR" ]; then
    sudo mv "$DATA_DIR" "$DAMAGED_DATA_DIR"
fi


# ============================================================
# 7. CREATE THE ACTIVE DATA DIRECTORY
# ============================================================

sudo mkdir -p "$DATA_DIR"

sudo chown postgres:postgres "$DATA_DIR"

sudo chmod 700 "$DATA_DIR"


# ============================================================
# 8. RESTORE BASE BACKUP
# ============================================================

sudo -u postgres pg_basebackup \
    -h "$PRIMARY_HOST" \
    -D "$DATA_DIR" \
    -U "$REPLICATOR_USER" \
    -Fp \
    -Xs \
    -P \
    -R


# ============================================================
# 9. CONFIGURE pg_hba.conf FOR REPLICATION
# ============================================================

echo "host replication $REPLICATOR_USER $STANDBY_IP/32 scram-sha-256" \
    | sudo tee -a "$DATA_DIR/pg_hba.conf"


# ============================================================
# 10. CONFIGURE WAL ARCHIVE RECOVERY
# ============================================================

sudo tee -a "$DATA_DIR/postgresql.conf" > /dev/null <<EOF

# Point-in-Time Recovery configuration
restore_command = 'cp $WAL_ARCHIVE_DIR/%f %p'

# PITR recovery target
recovery_target_time = '$RECOVERY_TARGET_TIME'

EOF


# ============================================================
# 11. SET CORRECT OWNERSHIP AND PERMISSIONS
# ============================================================

sudo chown -R postgres:postgres "$DATA_DIR"

sudo chmod 700 "$DATA_DIR"


# ============================================================
# 12. START POSTGRESQL SERVICE
# ============================================================

sudo systemctl start postgresql


# ============================================================
# 13. CHECK POSTGRESQL SERVICE
# ============================================================

sudo systemctl status postgresql


# ============================================================
# 14. VERIFY RECOVERY STATUS
# ============================================================

psql -d "$DB_NAME" -c \
    "SELECT pg_is_in_recovery();"


# ============================================================
# 15. CHECK STREAMING REPLICATION
# Run on the PRIMARY server.
# ============================================================

psql -d "$DB_NAME" -c "
SELECT
    client_addr,
    state,
    sync_state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn
FROM pg_stat_replication;
"


# ============================================================
# 16. CHECK REPLICATION LAG
# ============================================================

psql -d "$DB_NAME" -c "
SELECT
    client_addr,
    pg_wal_lsn_diff(sent_lsn, replay_lsn)
        AS replication_lag_bytes
FROM pg_stat_replication;
"


# ============================================================
# 17. COMPLETION MESSAGE
# ============================================================

echo "Backup, PITR recovery, and replication workflow completed."

echo "PITR recovery target: $RECOVERY_TARGET_TIME"
```
