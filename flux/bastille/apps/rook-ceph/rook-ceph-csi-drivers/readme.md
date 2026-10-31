# ceph csi drivers

[`helmrelease.yaml`](app/helmrelease.yaml) manages the existing rbd driver through
ceph-csi-operator. keep `releaseName: ceph-csi-drivers` to adopt the existing
helm release. keep its driver name aligned with the provisioner in
[`rook-ceph-cluster`](../rook-ceph-cluster/app/helmrelease.yaml); changing it
prevents existing volumes from mounting. cephfs, nfs, and nvmeof are disabled.

upgrade in order: rook operator, csi drivers, then cluster. the kustomization
dependencies enforce this order. keep the driver chart release compatible with
the ceph-csi-operator bundled in the rook chart. the upstream driver chart is
sourced from its tagged git release because upstream publishes no oci chart.

before migrating settings, save `drivers.csi.ceph.io` and
`operatorconfigs.csi.ceph.io`, then compare their effective configuration with
the rendered chart. verify existing volumes and a new pvc mount afterward.

local `flux-local test --enable-helm` resolves git chart paths from the working
directory. link the tagged upstream checkout's `deploy` directory into the repo
root before testing, then remove the link. [ci](../../../../../.github/workflows/flux-diff.yaml)
performs this setup automatically.

rook's operator chart manages the csi image set through its `csi` values.
helm drift detection keeps that configmap aligned with the chart defaults.
check the running driver images after upgrades; ceph-csi-operator `v1.0.4`
does not watch image-set configmap changes, so restart its controller manager
if the driver images remain stale after the configmap is corrected.
