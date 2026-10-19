#!/usr/bin/env bash
set -euo pipefail

flux_local_package=$1
git_command=$2
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
cd "$test_directory"

export HOME="$test_directory/home" KUBECONFIG="$test_directory/no-kubeconfig"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
mkdir -p "$HOME" cluster app
"$git_command" init --quiet --initial-branch=main

cat > cluster/ks.yaml <<'YAML'
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: smoke
  namespace: flux-system
spec:
  interval: 1m
  path: ./app
  prune: false
  sourceRef:
    kind: GitRepository
    name: flux-system
YAML

cat > app/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - configmap.yaml
YAML

cat > app/configmap.yaml <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: smoke-data
data:
  value: offline
YAML

"$flux_local_package/bin/flux-local" get ks --path "$test_directory/cluster" > result.txt
grep -Eq '^smoke[[:space:]]+(\./)?app[[:space:]]*$' result.txt
"$flux_local_package/bin/flux-local" build ks smoke --path "$test_directory/cluster" > result.yaml
grep -q 'name: smoke-data' result.yaml
grep -q 'value: offline' result.yaml
