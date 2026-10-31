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

# changed-only flate diffs omit chart sources owned by unchanged applications.
# render both complete trees, keeping self-referential sources local in a worktree.
unset FLATE_BASE FLATE_PATH_ORIG FLATE_NAMESPACE
snapshot=$(mktemp -d)
cleanup() {
  git worktree remove --force "$snapshot/base" || true
  rm -rf "$snapshot"
}
trap cleanup EXIT
git -c core.hooksPath=/dev/null worktree add --detach "$snapshot/base" "$merge_base"
for side in base head; do
  cluster_dir=flux/bastille
  if [[ $side == base ]]; then
    cluster_dir="$snapshot/base/flux/bastille"
  fi
  tools/scripts/flate.sh build all --path "$cluster_dir" --output json > "$snapshot/$side.json"
  tools/scripts/flate.sh get images --path "$cluster_dir" --output json > "$snapshot/$side-images.json"
done
python3 tools/scripts/rendered-diff.py "$snapshot" "$DIFF_DIR"
python3 tools/scripts/check-images.py "$DIFF_DIR/images.json"
