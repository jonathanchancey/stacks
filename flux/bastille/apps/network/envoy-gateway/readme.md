# gateway crds

shared gateway api definitions are managed by [gateway-api](../gateway-api/app/kustomization.yaml).
the envoy controller chart disables bundled crds to preserve that shared version.

[crds-helmrelease.yaml](app/crds-helmrelease.yaml) manages only envoy-specific
crds. keep its chart version aligned with the controller chart when upgrading.
