#!/usr/bin/env bash
set -euo pipefail

tools_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
kube_version=$(yq -er '.kubeVersion' "$tools_dir/flate.yaml")
api_versions=$(yq -r '.apiVersions | join(",")' "$tools_dir/flate.yaml")

exec flate "$@" --kube-version "$kube_version" --api-versions "$api_versions" --no-progress
