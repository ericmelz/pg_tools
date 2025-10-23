# pg_tools

PostgreSQL point-in-time recovery (PITR) utility suite for restoring PostgreSQL databases and configurations to specific timestamps.

## Overview

This toolkit enables you to restore a PostgreSQL cluster to any point in time, combining data recovery from pgbackrest backups with configuration restoration from git-versioned system files. This is useful for disaster recovery, testing, compliance audits, and development scenarios.

## Features

- **Point-in-time recovery**: Restore database state to any specific timestamp
- **Dual-source restoration**: Recover both data (from pgbackrest) and configurations (from git)
- **Automated cluster setup**: Creates and starts the restored cluster automatically
- **Proper permissions**: Sets correct ownership (postgres:postgres) and permissions on all files
- **Error handling**: Strict bash error checking to catch issues early

## Prerequisites

### Required Software

- **PostgreSQL** (including `pg_createcluster` utility)
- **pgbackrest** - Configured with valid backup stanzas
- **git** - For accessing versioned /etc configurations
- **sudo access** - Required for all restoration operations

### Required Setup

1. **pgbackrest backups**: Must have existing pgbackrest backups configured for the source cluster
2. **Git-versioned /etc**: The `/etc` directory must be a git repository with history of PostgreSQL configuration files:
   - `postgresql.conf`
   - `pg_hba.conf`
   - `pg_ident.conf`

## Installation

Clone this repository:

```bash
git clone <repository-url>
cd pg_tools
```

Make scripts executable:

```bash
chmod +x scripts/*.sh
```

## Usage

### Complete Restoration

Use the main orchestration script to perform a complete restoration:

```bash
sudo ./scripts/restore_pg.sh <DATESTAMP> <PG_VERSION> <OLD_CLUSTER_NAME> <NEW_CLUSTER_NAME> <DEST_DIR>
```

**Parameters:**
- `DATESTAMP`: Target recovery timestamp (format: "YYYY-MM-DD HH:MM:SS")
- `PG_VERSION`: PostgreSQL major version number (e.g., 17, 16, 15)
- `OLD_CLUSTER_NAME`: Original cluster name (used as pgbackrest stanza name)
- `NEW_CLUSTER_NAME`: Name for the new restored cluster
- `DEST_DIR`: Destination directory for restored data

**Example:**

```bash
sudo ./scripts/restore_pg.sh "2025-10-22 08:00:00" 17 production production_restore /mnt/backup/production_restore
```

This will:
1. Restore database files to `/mnt/backup/production_restore` as of 2025-10-22 08:00:00
2. Restore configuration files from git history at the same timestamp
3. Create a new PostgreSQL 17 cluster named `production_restore`
4. Start the cluster and make it available for use

### Individual Script Usage

#### Data Restoration Only

```bash
sudo ./scripts/restore_pg_data.sh "2025-10-22 08:00:00" 17 production production_restore /mnt/backup/production_restore
```

Restores only the database data files using pgbackrest.

#### Configuration Restoration Only

```bash
sudo ./scripts/restore_pg_configs.sh "2025-10-22 08:00:00" 17 production_restore /mnt/backup/production_restore/etc
```

Restores only the PostgreSQL configuration files from git history.

## How It Works

### Data Restoration Process

1. Creates destination directory with proper ownership and permissions
2. Uses `pgbackrest restore` with `--type=time` to recover data to the specified timestamp
3. Performs recovery promotion to make the database readable
4. Configures proper file permissions (750 for directories, postgres:postgres ownership)

### Configuration Restoration Process

1. Accesses git repository in `/etc`
2. Finds the most recent commit at or before the target timestamp
3. Extracts PostgreSQL configuration files from that commit:
   - `postgresql.conf` - Main database settings
   - `pg_hba.conf` - Client authentication rules
   - `pg_ident.conf` - Username mapping rules
4. Copies files to the restored cluster's configuration directory
5. Sets proper ownership and permissions (640)

### Cluster Creation

1. Uses `pg_createcluster` to initialize a new PostgreSQL cluster
2. Configures the cluster to use the restored data directory
3. Starts the PostgreSQL service using `systemctl`

## Common Use Cases

### Disaster Recovery

Quickly restore a corrupted or failed database to a known good state:

```bash
sudo ./scripts/restore_pg.sh "2025-10-22 06:00:00" 17 prod prod_recovery /var/lib/postgresql/17/prod_recovery
```

### Testing and Validation

Create a test database at a specific point in time for testing or debugging:

```bash
sudo ./scripts/restore_pg.sh "2025-10-15 14:30:00" 17 prod test_clone /opt/pg_test/test_clone
```

### Compliance and Auditing

Restore historical database state for compliance or audit requirements:

```bash
sudo ./scripts/restore_pg.sh "2025-09-30 23:59:59" 17 prod audit_q3 /mnt/audit/q3_2025
```

## Error Handling

All scripts use strict bash error handling (`set -euo pipefail`):
- Exit immediately on errors
- Treat undefined variables as errors
- Fail on pipe command errors

If a script fails, check:
1. pgbackrest stanza exists and has backups covering the requested timestamp
2. `/etc` is a git repository with commits covering the requested timestamp
3. Destination directory parent exists and has sufficient space
4. You have sudo privileges
5. PostgreSQL and pgbackrest are properly installed and configured

## Troubleshooting

### "Stanza not found" Error

Verify pgbackrest stanza name:
```bash
pgbackrest info
```

### "No commit found at timestamp" Warning

Check git history in `/etc`:
```bash
cd /etc
git log --all --pretty=format:"%H %ad" --date=iso
```

### Permission Denied

Ensure you're running scripts with sudo:
```bash
sudo ./scripts/restore_pg.sh ...
```

### Cluster Already Exists

Remove the existing cluster first:
```bash
sudo pg_dropcluster <version> <cluster_name>
```

## Directory Structure

```
pg_tools/
├── README.md                      # This file
├── .gitignore                     # Git ignore patterns
└── scripts/                       # Restoration scripts
    ├── restore_pg.sh              # Main orchestration script
    ├── restore_pg_configs.sh      # Configuration restoration
    └── restore_pg_data.sh         # Data restoration
```

## Contributing

Contributions are welcome! Please ensure:
- Scripts maintain strict error handling (`set -euo pipefail`)
- All parameters are validated with clear usage messages
- Proper ownership and permissions are set on all created files
- Changes are tested with multiple PostgreSQL versions

## License

[Add your license here]

## Authors

[Add author information here]

## Acknowledgments

This tool leverages:
- [pgbackrest](https://pgbackrest.org/) - Backup and restore tool for PostgreSQL
- [PostgreSQL](https://www.postgresql.org/) - The world's most advanced open source database
- [git](https://git-scm.com/) - Distributed version control system
