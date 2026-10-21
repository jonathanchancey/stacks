#!/usr/bin/env bash
set -euo pipefail

# Always create and delete a dedicated cluster; never use the caller's context.
name="escalation-e2e-$$"
tmp=$(mktemp -d)
export KUBECONFIG="$tmp/kubeconfig"
trap 'kind delete cluster --name "$name"; rm -rf "$tmp"' EXIT
kind create cluster --name "$name" --image kindest/node:v1.33.0 \
  --config test/kind.yaml --kubeconfig "$KUBECONFIG" --wait 120s

kubectl create namespace escalation
kubectl create namespace escalation-grants
kubectl create serviceaccount escalation -n escalation
kubectl create role escalation-observe -n default --verb=get,list,watch --resource=pods
kubectl apply -f chart/crds/accessrequests.yaml
kubectl wait --for=condition=Established crd/accessrequests.escalation.stacks.dev --timeout=60s
helm template escalation chart -n escalation --set enabled=true --set existingSecret=unused \
  --show-only templates/rbac.yaml --show-only templates/policy.yaml | kubectl apply -f -
kubectl wait --for=jsonpath='{.status.observedGeneration}'=1 \
  validatingadmissionpolicy/escalation-escalation-grants \
  validatingadmissionpolicy/escalation-escalation-tokens --timeout=60s

ESCALATION_TEST_KUBECONFIG="$KUBECONFIG" go test -race -run TestKubernetesGrant -v -count=1 -timeout=20m
