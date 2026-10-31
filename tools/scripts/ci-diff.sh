#!/usr/bin/env bash
set -euo pipefail

: "${BASE_SHA:?base commit is required}"
: "${HEAD_SHA:?head commit is required}"
: "${DIFF_DIR:?artifact directory is required}"

[[ "$BASE_SHA" =~ ^[0-9a-f]{40}$ && "$HEAD_SHA" =~ ^[0-9a-f]{40}$ ]]
[[ "$(git rev-parse HEAD)" == "$HEAD_SHA" ]]
merge_base=$(git merge-base "$BASE_SHA" "$HEAD_SHA")
mkdir -p "$DIFF_DIR"
printf 'base tip: %s\nhead: %s\nmerge base: %s\n' "$BASE_SHA" "$HEAD_SHA" "$merge_base" > "$DIFF_DIR/revisions.txt"

tools/scripts/flate.sh diff all --path flux/bastille --base "$merge_base" --output github > "$DIFF_DIR/flux.diff"
tools/scripts/flate.sh diff images --path flux/bastille --base "$merge_base" --output json > "$DIFF_DIR/images.json"
python3 tools/scripts/check-images.py "$DIFF_DIR/images.json"
