#!/usr/bin/env bash
set -euo pipefail

kubectl=(kubectl --context bastille --namespace auth-system)
release="$("${kubectl[@]}" get helmrelease kaniop -o json)"
if ! jq -e '
  .metadata.generation == .status.observedGeneration
  and .status.history[0].chartVersion == "0.25.0"
  and .status.history[0].status == "deployed"
  and any(.status.conditions[]; .type == "Ready" and .status == "True")
' >/dev/null <<< "$release"; then
  echo "kaniop 0.25.0 must be ready before cleanup" >&2
  exit 1
fi

jobs="$("${kubectl[@]}" get jobs -l app.kubernetes.io/component=crd-migration -o json)"
if ! jq -e '
  all(.items[];
    (.metadata.name != "kaniop-crd-migrate" and .metadata.name != "kaniop-crd-verify")
    or any(.status.conditions[]?;
      (.type == "Complete" or .type == "Failed") and .status == "True")
  )
' >/dev/null <<< "$jobs"; then
  echo "wait for the retired kaniop migration jobs to finish" >&2
  exit 1
fi

resources=(
  clusterrolebinding/kaniop-crd-migrator
  rolebinding/kaniop-crd-migrator
  clusterrole/kaniop-crd-migrator
  role/kaniop-crd-migrator
  serviceaccount/kaniop-crd-migrator
)

"${kubectl[@]}" delete "${resources[@]}" --ignore-not-found
remaining="$("${kubectl[@]}" get "${resources[@]}" --ignore-not-found -o name)"
if [[ -n "$remaining" ]]; then
  echo "retired kaniop migration permissions remain" >&2
  exit 1
fi
