#!/usr/bin/env bash
set -euo pipefail

# restore_pg_data.sh
# Usage:
#   ./restore_pg_data.sh "2025-10-22 08:00:00" 17 test1 test1_restore /mnt/sdc-data1/test1_restore
#
# Restores postgres data as of the given timestamp from pg data backup repo

if [[ $# -ne 5 ]]; then
  echo "Usage: $0 <DATESTAMP> <PG_VERSION> <OLD_CLUSTER_NAME> <NEW_CLUSTER_NAME> <DEST_DIR>" >&2
  echo "Example: $0 '2025-10-22T08:00:00' 17 test1 test1_restore /mnt/sdc-data1/test1_restore" >&2
  exit 1
fi

DATESTAMP="$1"
PG_VERSION="$2"
OLD_CLUSTER="$3"
NEW_CLUSTER="$4"
DEST_DIR="$5"

# Ensure destination exists (owned by postgres; permissions are typical for config dir snapshots)
sudo install -d -m 750 -o postgres -g postgres -- "$DEST_DIR"

sudo -u postgres pgbackrest --stanza=$OLD_CLUSTER restore \
  --pg1-path=$DEST_DIR \
  --type=time \
  --target="$DATESTAMP" \
  --target-action=promote \
  --log-level-console=info
