#!/bin/bash
set -euo pipefail

# VixRex Database Backup Script
# Usage: ./backup_database.sh [daily|weekly|manual]

BACKUP_TYPE="${1:-weekly}"
BACKUP_DIR="$(cd "$(dirname "$0")" && pwd)/dumps"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/vixrex_${BACKUP_TYPE}_${DATE}.dump"
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

echo "=== VixRex Database Backup ==="
echo "Type: $BACKUP_TYPE"
echo "Target: $BACKUP_FILE"

if [ -z "${DATABASE_URL:-}" ]; then
  echo "ERROR: DATABASE_URL environment variable is not set."
  echo "Set it in GitHub Secrets or export it before running."
  exit 1
fi

pg_dump "$DATABASE_URL" \
  --no-owner \
  --no-privileges \
  --no-comments \
  -F c \
  -Z 6 \
  -f "$BACKUP_FILE"

FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "Backup completed: $BACKUP_FILE ($FILE_SIZE)"

echo "Cleaning backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "vixrex_*.dump" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

echo "=== Done ==="