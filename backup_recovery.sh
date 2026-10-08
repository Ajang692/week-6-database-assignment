#!/bin/bash

# ============================================================
# PLP HANDS-ON LAB
# Backups, Point-in-Time Recovery, and Replication
# ============================================================

# ============================================================
# 1. VARIABLES
# ============================================================

DB_NAME="your_database_name"
BACKUP_DIR="/var/backups/postgresql"
DATA_DIR="/var/lib/postgresql/data"

REPLICATOR_USER="replicator"

# ============================================================
# 2. CREATE BACKUP DIRECTORY
# ============================================================

sudo mkdir -p "$BACKUP_DIR"

# ============================================================
# 3. CREATE A LOGICAL BACKUP USING pg_dump
# ============================================================

pg_dump "$DB_NAME" > "$BACKUP_DIR/${DB_NAME}_backup.sql"

# Verify the backup
ls -lh "$BACKUP_DIR/${DB_NAME}_backup.sql"

# ============================================================
# 4. CHECK WAL CONFIGURATION
# ============================================================

psql -d "$DB_NAME" -c "SHOW wal_level;"
psql -d "$DB_NAME" -c "SHOW archive_mode;"
psql -d "$DB_NAME" -c "SHOW archive_command;"

# ============================================================
# 5. STOP POSTGRESQL SERVICE
# ============================================================

sudo systemctl stop postgresql

# ============================================================
# 6. BACK UP THE DAMAGED DATA DIRECTORY
# ============================================================

sudo mv "$DATA_DIR" "${DATA_DIR}_damaged"

# ============================================================
# 7. CREATE A NEW DATA DIRECTORY
# ============================================================

sudo mkdir -p "$DATA_DIR"

sudo chown postgres:postgres "$DATA_DIR"
sudo chmod 700 "$DATA_DIR"

# ============================================================
# 8. RESTORE THE BASE BACKUP
# ============================================================

sudo -u postgres pg_basebackup \
    -h PRIMARY_HOST \
    -D "$DATA_DIR" \
    -U "$REPLICATOR_USER" \
    -Fp \
    -Xs \
    -P \
    -R

# ============================================================
# 9. CONFIGURE pg_hba.conf FOR REPLICATION
# ============================================================

echo "host replication $REPLICATOR_USER STANDBY_IP/32 scram-sha-256" \
    | sudo tee -a "$DATA_DIR/pg_hba.conf"

# ============================================================
# 10. RECOVERY CONFIGURATION
# ============================================================

sudo tee -a "$DATA_DIR/postgresql.conf" > /dev/null <<EOF

restore_command = 'cp /path/to/archive/%f %p'
recovery_target_time = '2026-10-08 10:00:00'

EOF

# ============================================================
# 11. SET PERMISSIONS
# ============================================================

sudo chown -R postgres:postgres "$DATA_DIR"
sudo chmod 700 "$DATA_DIR"

# ============================================================
# 12. START POSTGRESQL
# ============================================================

sudo systemctl start postgresql

# ============================================================
# 13. VERIFY POSTGRESQL STATUS
# ============================================================

sudo systemctl status postgresql

# ============================================================
# 14. VERIFY RECOVERY MODE
# ============================================================

psql -d "$DB_NAME" -c "SELECT pg_is_in_recovery();"

# ============================================================
# 15. VERIFY REPLICATION
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
# END
# ============================================================
