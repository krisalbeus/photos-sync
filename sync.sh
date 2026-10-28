#!/usr/bin/env bash
# Upload new/changed photos to S3 Glacier Deep Archive. Never deletes anything.
#   ./sync.sh              run
#   ./sync.sh --dry-run    preview only
# Set ECHO=echo to print the aws command instead of running it.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

EXTRA=()
case "${1:-}" in
  "") ;;
  --dry-run) EXTRA=(--dryrun) ;;
  *) echo "Usage: $0 [--dry-run]" >&2; exit 1 ;;
esac

require_mounted

${ECHO:-} aws s3 sync "$SRC" "$DEST" \
  --storage-class "$STORAGE_CLASS" \
  --no-follow-symlinks \
  "${EXCLUDES[@]}" \
  ${EXTRA[@]+"${EXTRA[@]}"}
