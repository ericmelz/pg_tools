#!/usr/bin/env bash
set -euo pipefail

# restore_pg.sh
# Usage:
#   ./restore_pg.sh "2025-10-22 08:00:00" 17 test1 test1_restore /mnt/sdc-data1/test1_restore
#
# Restores, as of the given timestamp postgres:
# * data
# * configs
#
# Sets up a running postgres clustre with the restored data + configs

if [[ $# -ne 5 ]]; then
  echo "Usage: $0 <DATESTAMP> <PG_VERSION> <OLD_CLUSTER_NAME> <NEW_CLUSTER_NAME> <DEST_DIR>" >&2
  echo "Example: $0 '2025-10-22T08:00:00' 17 test1 test1_restore /mnt/sdc-data1/test1_restore" >&2
  exit 1
fi


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DATESTAMP="$1"
PG_VERSION="$2"
OLD_CLUSTER="$3"
NEW_CLUSTER="$4"
DEST_DIR="$5"

"${SCRIPT_DIR}/restore_pg_data.sh" "$@"
"${SCRIPT_DIR}/restore_pg_configs.sh" "$@"

sudo pg_createcluster $PG_VERSION $NEW_CLUSTER --datadir=$DEST_DIR
sudo systemctl start postgresql@$PG_VERSION-$NEW_CLUSTER
