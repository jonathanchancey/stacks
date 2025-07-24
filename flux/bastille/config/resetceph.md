talosctl -e 10.131.181.87 -n 10.131.181.83,10.131.181.86,10.131.181.87 get systemdisk
NODE            NAMESPACE   TYPE         ID            VERSION   DISK
10.131.181.83   runtime     SystemDisk   system-disk   1         nvme1n1
10.131.181.86   runtime     SystemDisk   system-disk   1         nvme2n1
10.131.181.87   runtime     SystemDisk   system-disk   1         nvme0n1

talosctl -e 10.131.181.87 -n 10.131.181.83,10.131.181.86,10.131.181.87 get systemdisk



talosctl -e 10.131.181.87 -n 10.131.181.83 wipe disk nvme0n1
talosctl -e 10.131.181.87 -n 10.131.181.83 wipe disk nvme1n1
talosctl -e 10.131.181.87 -n 10.131.181.83 wipe disk nvme2n1

talosctl -e 10.131.181.87 -n 10.131.181.86 wipe disk nvme0n1
talosctl -e 10.131.181.87 -n 10.131.181.86 wipe disk nvme1n1
talosctl -e 10.131.181.87 -n 10.131.181.86 wipe disk nvme2n1

talosctl -e 10.131.181.87 -n 10.131.181.87 wipe disk nvme0n1
talosctl -e 10.131.181.87 -n 10.131.181.87 wipe disk nvme1n1
talosctl -e 10.131.181.87 -n 10.131.181.87 wipe disk nvme2n1


kubectl --namespace rook-ceph patch cephcluster rook-ceph --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'
kubectl delete storageclasses ceph-block ceph-bucket ceph-filesystem
kubectl --namespace rook-ceph delete cephblockpools ceph-blockpool
kubectl --namespace rook-ceph delete cephobjectstore ceph-objectstore
kubectl --namespace rook-ceph delete cephfilesystem ceph-filesystem
kubectl --namespace rook-ceph delete cephcluster rook-ceph
helm --namespace rook-ceph uninstall rook-ceph-cluster
helm --namespace rook-ceph uninstall rook-ceph

kubens rook-ceph
kubectl label namespace rook-ceph pod-security.kubernetes.io/enforce=privileged
kubectl apply -f disk-clean.yaml
kubectl delete pod disk-clean0
kubectl delete pod disk-clean1
kubectl delete pod disk-clean2

kubectl wait --timeout=900s --for=jsonpath='{.status.phase}=Succeeded' pod disk-clean
