#!/usr/bin/env bash
set -euo pipefail

cluster_dir=${1:?cluster directory required}
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
args=(--path "$cluster_dir")

# tests always cover the selected namespace or the full tree, never a git diff.
unset FLATE_BASE FLATE_PATH_ORIG FLATE_NAMESPACE
if [[ $# -gt 1 ]]; then
  [[ -n $2 ]] || { echo 'namespace must not be empty' >&2; exit 1; }
  args+=(--namespace "$2")
fi

# flate accepts an empty selection; make a misspelled namespace fail instead.
inventory=$("$script_dir/flate.sh" get ks "${args[@]}" --output json)
if [[ $(yq -p=json 'length' <<< "$inventory") -eq 0 ]]; then
  echo "no kustomizations found in $cluster_dir${2:+ for namespace $2}" >&2
  exit 1
fi

exec "$script_dir/flate.sh" test all "${args[@]}"
