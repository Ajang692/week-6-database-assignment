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
