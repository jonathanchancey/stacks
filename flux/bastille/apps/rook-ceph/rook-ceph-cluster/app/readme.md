# Ceph

In talos, don't forget
```bash
kubectl label namespace rook-ceph pod-security.kubernetes.io/enforce=privileged
```
## Cleaning Up
Rook Ceph Cluster Removal

```bash
$ kubectl --namespace rook-ceph patch cephcluster rook-ceph --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'
cephcluster.ceph.rook.io/rook-ceph patched

$ kubectl delete storageclasses ceph-block ceph-bucket ceph-filesystem
storageclass.storage.k8s.io "ceph-block" deleted
storageclass.storage.k8s.io "ceph-bucket" deleted
storageclass.storage.k8s.io "ceph-filesystem" deleted

$ kubectl --namespace rook-ceph delete cephblockpools ceph-blockpool
cephblockpool.ceph.rook.io "ceph-blockpool" deleted

$ kubectl --namespace rook-ceph delete cephobjectstore ceph-objectstore
cephobjectstore.ceph.rook.io "ceph-objectstore" deleted

$ kubectl --namespace rook-ceph delete cephfilesystem ceph-filesystem
cephfilesystem.ceph.rook.io "ceph-filesystem" deleted
```
