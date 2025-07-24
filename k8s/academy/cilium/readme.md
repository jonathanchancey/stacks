very important, enabling bgp requires deleting the operator so it can recreate the crds

helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.3.2 \
  -n envoy-gateway-system --create-namespace
