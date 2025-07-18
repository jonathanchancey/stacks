# talos

## DNS, DHCP, and api endpoint

https://www.talos.dev/v1.10/introduction/prodnotes/#dns-records

```
kube.bastille.chancey.dev  IN  A  10.131.128.10
kube.bastille.chancey.dev  IN  A  10.131.128.11
kube.bastille.chancey.dev  IN  A  10.131.128.12
```

static
10.131.128.1/18

## bgp opensense

add neighbors
| Description | Neighbor Address | Remote AS |
| ----------- | ---------------- | --------- |
| sentinel-00 | 10.131.128.10    | 64516     |
| sentinel-01 | 10.131.128.11    | 64516     |
| sentinel-02 | 10.131.128.12    | 64516     |

click save in general tab

## bootstrap
```bash
# generate base configs
# mkdir .private
# cd .private
# talosctl gen secrets -o secrets.sops.yaml
# talosctl gen config --with-secrets secrets.sops.yaml bastille https://kube.bastille.chancey.dev:6443
# talosctl --talosconfig=./talosconfig apply-config --insecure --nodes 10.131.128.10 --endpoints 10.131.128.10 --file ./.private/controlplane.yaml

# render templates
talosctl --talosconfig=.private/talosconfig machineconfig patch .private/controlplane.yaml --patch @patches/controlplane.yaml --patch @patches/sentinel-00.yaml --output .private/rendered/sentinel-00.yaml
talosctl --talosconfig=.private/talosconfig machineconfig patch .private/controlplane.yaml --patch @patches/controlplane.yaml --patch @patches/sentinel-01.yaml --output .private/rendered/sentinel-01.yaml
talosctl --talosconfig=.private/talosconfig machineconfig patch .private/controlplane.yaml --patch @patches/controlplane.yaml --patch @patches/sentinel-02.yaml --output .private/rendered/sentinel-02.yaml

# apply insecure
talosctl --talosconfig=.private/talosconfig apply-config --insecure --nodes 10.131.128.10 --endpoints 10.131.128.10 --file ./.private/rendered/sentinel-00.yaml
talosctl --talosconfig=.private/talosconfig apply-config --insecure --nodes 10.131.128.11 --endpoints 10.131.128.11 --file ./.private/rendered/sentinel-01.yaml
talosctl --talosconfig=.private/talosconfig apply-config --insecure --nodes 10.131.128.12 --endpoints 10.131.128.12 --file ./.private/rendered/sentinel-02.yaml

# bootstrap
talosctl --talosconfig=.private/talosconfig bootstrap --nodes 10.131.128.10 --endpoints 10.131.128.10

# configure endpoints in talosconfig
talosctl --talosconfig=.private/talosconfig config endpoint 10.131.128.10 10.131.128.11 10.131.128.12

# test get disks
talosctl --talosconfig=.private/talosconfig -n 10.131.128.10,10.131.128.11,10.131.128.12 get disks

# merge into kubeconfig
talosctl --talosconfig=.private/talosconfig -n 10.131.128.10 kubeconfig

# needs tasks to render and apply
talosctl --talosconfig=.private/talosconfig machineconfig patch .private/controlplane.yaml --patch @patches/controlplane.yaml --patch @patches/sentinel-00.yaml --output .private/rendered/sentinel-00.yaml
talosctl --talosconfig=.private/talosconfig machineconfig patch .private/controlplane.yaml --patch @patches/controlplane.yaml --patch @patches/sentinel-01.yaml --output .private/rendered/sentinel-01.yaml
talosctl --talosconfig=.private/talosconfig machineconfig patch .private/controlplane.yaml --patch @patches/controlplane.yaml --patch @patches/sentinel-02.yaml --output .private/rendered/sentinel-02.yaml
talosctl --talosconfig=.private/talosconfig apply-config --nodes 10.131.128.10 --endpoints 10.131.128.10 --file ./.private/rendered/sentinel-00.yaml
talosctl --talosconfig=.private/talosconfig apply-config --nodes 10.131.128.11 --endpoints 10.131.128.11 --file ./.private/rendered/sentinel-01.yaml
talosctl --talosconfig=.private/talosconfig apply-config --nodes 10.131.128.12 --endpoints 10.131.128.12 --file ./.private/rendered/sentinel-02.yaml
```


## teardown
```bash
# wipe ceph cluster
kubectl --namespace rook-ceph patch cephcluster rook-ceph --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'
kubectl delete storageclasses ceph-block ceph-bucket ceph-filesystem
kubectl --namespace rook-ceph delete cephblockpools ceph-blockpool
kubectl --namespace rook-ceph delete cephobjectstore ceph-objectstore
kubectl --namespace rook-ceph delete cephfilesystem ceph-filesystem
kubectl --namespace rook-ceph delete cephcluster rook-ceph
helm --namespace rook-ceph uninstall rook-ceph-cluster

# wipe all disks. talos systemdisk is protected
talosctl -e 10.131.128.10 -n 10.131.128.11 wipe disk nvme0n1
talosctl -e 10.131.128.10 -n 10.131.128.11 wipe disk nvme1n1
talosctl -e 10.131.128.10 -n 10.131.128.11 wipe disk nvme2n1

talosctl -e 10.131.128.10 -n 10.131.128.12 wipe disk nvme0n1
talosctl -e 10.131.128.10 -n 10.131.128.12 wipe disk nvme1n1
talosctl -e 10.131.128.10 -n 10.131.128.12 wipe disk nvme2n1

talosctl -e 10.131.128.10 -n 10.131.128.10 wipe disk nvme0n1
talosctl -e 10.131.128.10 -n 10.131.128.10 wipe disk nvme1n1
talosctl -e 10.131.128.10 -n 10.131.128.10 wipe disk nvme2n1

# wipe cluster
talosctl --talosconfig=.private/talosconfig -n 10.131.128.11 -e 10.131.128.10 reset --system-labels-to-wipe EPHEMERAL,STATE --reboot --graceful=false
talosctl --talosconfig=.private/talosconfig -n 10.131.128.12 -e 10.131.128.10 reset --system-labels-to-wipe EPHEMERAL,STATE --reboot --graceful=false
talosctl --talosconfig=.private/talosconfig -n 10.131.128.10 -e 10.131.128.10 reset --system-labels-to-wipe EPHEMERAL,STATE --reboot --graceful=false
```
