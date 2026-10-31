# gateway crds

shared gateway api definitions are managed by [gateway-api](../gateway-api/app/kustomization.yaml).
the envoy controller chart disables bundled crds to preserve that shared version.

[crds/ks.yaml](crds/ks.yaml) applies envoy-specific definitions directly from
the controller's chart artifact. keep its source tag aligned with the controller
chart when upgrading.
