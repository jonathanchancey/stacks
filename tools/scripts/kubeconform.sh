#!/usr/bin/env bash
set -euo pipefail

manifest_dir=${1:?manifest directory required}
mode=${2:---authored}
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
kube_version=$(yq -er '.kubeVersion' "$script_dir/../flate.yaml")
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

[[ -d $manifest_dir ]] || { echo "manifest directory not found: $manifest_dir" >&2; exit 1; }
schema_locations=(
  -schema-location 'https://k8s-schemas.home-operations.com/{{if .Group}}{{.Group}}{{else}}core{{end}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
  -schema-location default
)

case "$mode" in
  --rendered)
    echo "validating rendered manifests in $manifest_dir"
    unset FLATE_BASE FLATE_PATH_ORIG FLATE_NAMESPACE
    # sops envelopes are source metadata; encrypted values remain placeholders.
    "$script_dir/flate.sh" build all --path "$manifest_dir" --skip-crds=false |
      yq 'del(.sops)' > "$work_dir/manifests.yaml"
    yq -o=json -I=0 'select(.kind == "CustomResourceDefinition")' "$work_dir/manifests.yaml" |
      python3 "$script_dir/flate-crd-schemas.py" "$work_dir/schemas"
    # use the installed crd shape and kubernetes quantity semantics before fallback schemas.
    schema_locations=(
      -schema-location "$work_dir/schemas/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json"
      -schema-location default
      -schema-location 'https://k8s-schemas.home-operations.com/{{if .Group}}{{.Group}}{{else}}core{{end}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
    )
    ;;
  --authored)
    echo "validating authored manifests in $manifest_dir"
    find "$manifest_dir" -maxdepth 1 -type f -name '*.yaml' -print0 |
      while IFS= read -r -d '' file; do
        printf '\n---\n'
        cat "$file"
      done > "$work_dir/manifests.yaml"
    find "$manifest_dir" -type f -name kustomization.yaml -print0 |
      while IFS= read -r -d '' file; do
        # components receive their substitutions and namespace from their consumer.
        [[ $file == */components/* ]] && continue
        printf '\n---\n'
        kustomize build "$(dirname -- "$file")" --load-restrictor=LoadRestrictionsNone
      done >> "$work_dir/manifests.yaml"
    ;;
  *) echo "unknown validation mode: $mode" >&2; exit 1 ;;
esac

[[ -s $work_dir/manifests.yaml ]] || { echo 'no manifests found' >&2; exit 1; }

status=0
kubeconform \
  -strict -summary -verbose -output json \
  -ignore-missing-schemas -skip Secret \
  -kubernetes-version "$kube_version" \
  "${schema_locations[@]}" \
  "$work_dir/manifests.yaml" > "$work_dir/report.json" || status=$?

# show every missing schema and invalid object without logging successful objects.
yq -p=json -o=yaml -r '.resources[] | select(.status != "statusValid") | .status + ": " + .version + " " + .kind + "/" + .name + " " + .msg' "$work_dir/report.json"
yq -p=json -o=yaml '.summary' "$work_dir/report.json"
exit "$status"
