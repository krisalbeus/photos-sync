# Shared config for sync.sh, delete.sh and verify.sh. Source it; don't run it.

export AWS_PROFILE="${AWS_PROFILE:-kris}"
SRC="/Volumes/Photos"
DEST="s3://kris-albeus-photos-bkp"
STORAGE_CLASS="${STORAGE_CLASS:-DEEP_ARCHIVE}"

# Patterns are relative to SRC. "*" also matches "/", so each name is listed
# for the root and for any depth below it.
EXCLUDE_PATTERNS=(
  '$RECYCLE.BIN/*'            '*/$RECYCLE.BIN/*'
  'System Volume Information/*' '*/System Volume Information/*'
  '.Spotlight-V100/*'         '*/.Spotlight-V100/*'
  '.Trashes/*'                '*/.Trashes/*'
  '.fseventsd/*'              '*/.fseventsd/*'
  '.DS_Store'                 '*/.DS_Store'
  '._*'                       '*/._*'
  'Thumbs.db'                 '*/Thumbs.db'
)

EXCLUDES=()
for _p in "${EXCLUDE_PATTERNS[@]}"; do EXCLUDES+=(--exclude "$_p"); done
unset _p

require_mounted() {
  [[ -d "$SRC" && -n "$(ls -A "$SRC" 2>/dev/null)" ]] \
    || { echo "Not mounted or empty: $SRC (refusing to continue)" >&2; exit 1; }
}
