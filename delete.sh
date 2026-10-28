#!/usr/bin/env bash
# Make S3 match /Volumes/Photos: deletes from S3 what is gone locally, and also
# uploads new/changed files.
#   ./delete.sh                 DRY RUN (always the default)
#   ./delete.sh --no-dry-run    real run; you must type "delete" to confirm
# Set ECHO=echo to print the aws command instead of running it.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

EXTRA=(--dryrun)
REAL=0
case "${1:-}" in
  "") ;;
  --no-dry-run) REAL=1 ;;
  *) echo "Usage: $0 [--no-dry-run]" >&2; exit 1 ;;
esac

require_mounted

if [[ $REAL -eq 1 ]]; then
  read -r -p "REAL RUN: delete from $DEST anything missing in $SRC. Type 'delete': " ans
  [[ "$ans" == "delete" ]] || { echo "Aborted." >&2; exit 1; }
  EXTRA=()
else
  echo "DRY RUN (no changes). Use --no-dry-run to apply." >&2
fi

${ECHO:-} aws s3 sync "$SRC" "$DEST" --delete \
  --storage-class "$STORAGE_CLASS" \
  --no-follow-symlinks \
  "${EXCLUDES[@]}" \
  ${EXTRA[@]+"${EXTRA[@]}"}
