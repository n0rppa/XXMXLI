#!/usr/bin/env bash
# Backup key site data to backups/<timestamp>.tar.gz
# - Includes: data/analytics, logs/, reports/, assets/images/filelist.json
# - Skips: node_modules, .git, large media directories by default
# Usage: ./scripts/backup_site_data.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"
DEST_DIR="$ROOT_DIR/backups"
OUT_FILE="$DEST_DIR/site_backup_${TS}.tar.gz"

mkdir -p "$DEST_DIR"

INCLUDE_LIST=(
  "data/analytics"
  "logs"
  "reports"
  "assets/images/filelist.json"
  "assets/audio/tracklist_*.json"
)

# Build tar include args
INCLUDE_ARGS=()
for p in "${INCLUDE_LIST[@]}"; do
  if [ -e "$ROOT_DIR/$p" ]; then
    INCLUDE_ARGS+=("-C" "$ROOT_DIR" "$p")
  fi
done

if [ ${#INCLUDE_ARGS[@]} -eq 0 ]; then
  echo "Nothing to back up. Exiting."
  exit 0
fi

echo "Creating backup: $OUT_FILE"
# shellcheck disable=SC2086
tar -czf "$OUT_FILE" ${INCLUDE_ARGS[@]}

echo "Backup complete: $OUT_FILE"
