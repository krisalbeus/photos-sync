#!/usr/bin/env bash
# Read-only check of /Volumes/Photos against the S3 listing (key + size).
# Only calls ListObjectsV2; never retrieves or restores Deep Archive objects.
# Reports: missing in S3, size mismatches, extra in S3. Exit 1 if any differ.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_mounted

BUCKET_PREFIX="${DEST#s3://}"
BUCKET="${BUCKET_PREFIX%%/*}"
PREFIX="${BUCKET_PREFIX#*/}/"

LISTING="$(mktemp)"
trap 'rm -f "$LISTING"' EXIT
aws s3api list-objects-v2 --bucket "$BUCKET" --prefix "$PREFIX" \
  --query 'Contents[].{Key:Key,Size:Size}' --output json > "$LISTING"

python3 - "$SRC" "$PREFIX" "$LISTING" "${EXCLUDE_PATTERNS[@]}" <<'PY'
import fnmatch, json, os, sys

src, prefix, listing, *patterns = sys.argv[1:]
excluded = lambda rel: any(fnmatch.fnmatchcase(rel, p) for p in patterns)

local = {}
for root, _dirs, files in os.walk(src, followlinks=False):
    for f in files:
        path = os.path.join(root, f)
        if os.path.islink(path):
            continue
        rel = os.path.relpath(path, src)
        if not excluded(rel):
            local[rel] = os.path.getsize(path)

remote = {}
with open(listing, encoding="utf-8") as file:
    objects = json.load(file) or []

for o in objects:
    rel = o["Key"][len(prefix):]
    if rel and not rel.endswith("/"):
        remote[rel] = o["Size"]

missing = sorted(set(local) - set(remote))
extra = sorted(set(remote) - set(local))
diff = sorted(k for k in set(local) & set(remote) if local[k] != remote[k])

for title, items in (("MISSING in S3", missing), ("SIZE MISMATCH", diff), ("EXTRA in S3 (not local)", extra)):
    print(f"\n== {title}: {len(items)}")
    for k in items:
        print(f"  {k}" + (f"  local={local[k]} s3={remote[k]}" if title == "SIZE MISMATCH" else ""))

print(f"\nlocal={len(local)} s3={len(remote)}")
sys.exit(1 if missing or extra or diff else 0)
PY
