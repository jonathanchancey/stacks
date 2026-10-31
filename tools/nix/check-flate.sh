#!/usr/bin/env bash
set -euo pipefail

flate_package=$1
git_command=$2
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
cd "$test_directory"

export KUBECONFIG="$test_directory/no-kubeconfig"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export FLATE_CACHE_DIR="$test_directory/cache" FLATE_NO_PROGRESS=true
mkdir -p cluster app charts/smoke/templates
"$git_command" init --quiet --initial-branch=main

cat > cluster/ks.yaml <<'YAML'
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: flux-system
  namespace: flux-system
spec:
  url: https://example.test/cluster.git
  ref:
    branch: main
---
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
  - helmrelease.yaml
YAML

cat > app/configmap.yaml <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: smoke-data
  namespace: apps
data:
  value: offline
YAML

cat > app/helmrelease.yaml <<'YAML'
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: smoke
  namespace: apps
spec:
  interval: 1m
  chart:
    spec:
      chart: charts/smoke
      sourceRef:
        kind: GitRepository
        name: flux-system
        namespace: flux-system
  values:
    message: offline-helm
YAML

cat > charts/smoke/Chart.yaml <<'YAML'
apiVersion: v2
name: smoke
version: 0.1.0
YAML

cat > charts/smoke/templates/configmap.yaml <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-helm
  namespace: {{ .Release.Namespace }}
data:
  message: {{ .Values.message | quote }}
YAML

"$flate_package/bin/flate" get ks --path cluster --output name > kustomizations.txt
grep -Fxq 'smoke' kustomizations.txt
"$flate_package/bin/flate" build ks smoke --path cluster > kustomization.yaml
grep -q 'name: smoke-data' kustomization.yaml
grep -q 'value: offline' kustomization.yaml
"$flate_package/bin/flate" build hr smoke --path cluster > helm.yaml
grep -q 'name: smoke-helm' helm.yaml
grep -q 'message: offline-helm' helm.yaml

# assert the fixture was collected before accepting the test command's exit code.
"$flate_package/bin/flate" test all --path cluster > result.txt
grep -Eq '[1-9][0-9]* passed' result.txt
if grep -Eq '[1-9][0-9]* (failed|skipped)' result.txt; then
  cat result.txt >&2
  exit 1
fi

printf '\n  - missing.yaml\n' >> app/kustomization.yaml
if "$flate_package/bin/flate" test all --path cluster > invalid.txt 2>&1; then
  echo 'flate accepted a missing kustomize resource' >&2
  cat invalid.txt >&2
  exit 1
fi
