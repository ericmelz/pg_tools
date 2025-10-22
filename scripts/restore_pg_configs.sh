#!/usr/bin/env bash
set -euo pipefail

# restore_pg_configs.sh
# Usage:
#   ./restore_pg_configs.sh "2025-10-22T08:00:00" 17 test1 /mnt/sdc-data1/test1_restore
#
# Restores, as of the given timestamp:
#   postgresql/<version>/<cluster>/postgresql.conf
#   postgresql/<version>/<cluster>/pg_hba.conf
#   postgresql/<version>/<cluster>/pg_ident.conf
#
# From the /etc git repo (via sudo) into the destination directory,
# with final ownership postgres:postgres.

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <DATESTAMP> <PG_VERSION> <CLUSTER_NAME> <DEST_DIR>" >&2
  echo "Example: $0 '2025-10-22T08:00:00' 17 test1 /mnt/sdc-data1/test1_restore" >&2
  exit 1
fi

DATESTAMP="$1"
PG_VERSION="$2"
CLUSTER="$3"
DEST_DIR="$4"

REPO_DIR="/etc"
BRANCH="main"   # change if your default branch is different

# Ensure destination exists (owned by postgres; permissions are typical for config dir snapshots)
sudo install -d -m 750 -o postgres -g postgres -- "$DEST_DIR"

# Find the last commit at or before the timestamp
COMMIT="$(sudo git -C "$REPO_DIR" rev-list -1 --before="$DATESTAMP" "$BRANCH" || true)"
if [[ -z "$COMMIT" ]]; then
  echo "Error: No commit found in $REPO_DIR on branch '$BRANCH' at or before '$DATESTAMP'." >&2
  exit 2
fi

echo "Using commit $COMMIT from $REPO_DIR (<= $DATESTAMP)"

# File paths in the repo
BASE="postgresql/$PG_VERSION/$CLUSTER"
FILES=(
  "$BASE/postgresql.conf"
  "$BASE/pg_hba.conf"
  "$BASE/pg_ident.conf"
)

FAIL=0
for F in "${FILES[@]}"; do
  BASENAME="$(basename "$F")"
  OUT="$DEST_DIR/$BASENAME"

  # Check that the file exists in that commit
  if ! sudo git -C "$REPO_DIR" cat-file -e "${COMMIT}:${F}" 2>/dev/null; then
    echo "Warning: ${F} does not exist in commit $COMMIT. Skipping." >&2
    FAIL=1
    continue
  fi

  echo "Restoring $F -> $OUT"
  # Write file contents with sudo; preserve only the contents (no extra newline)
  sudo git -C "$REPO_DIR" show "${COMMIT}:${F}" | sudo tee "$OUT" >/dev/null

  # Reasonable, secure perms for these config files; adjust if needed
  sudo chown postgres:postgres "$OUT"
  sudo chmod 640 "$OUT"
done

if [[ $FAIL -ne 0 ]]; then
  echo "Completed with warnings: one or more files were not present in the target commit." >&2
  exit 3
fi

echo "Done. Files restored to: $DEST_DIR"
sudo ls -l "$DEST_DIR"
