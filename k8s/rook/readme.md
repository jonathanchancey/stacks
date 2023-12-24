# External Ceph Cluster

https://www.rook.io/docs/rook/latest/CRDs/Cluster/external-cluster/

```bash

kubectl apply -f common.yaml -f crds.yaml -f operator.yaml
kubectl apply -f common-external.yaml -f cluster-external.yaml


kubectl get storageclass
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass ceph-rbd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get storageclass
```