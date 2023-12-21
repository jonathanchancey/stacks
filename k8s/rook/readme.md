# External Ceph Cluster

https://www.rook.io/docs/rook/latest/CRDs/Cluster/external-cluster/

```

kubectl apply -f common.yaml -f crds.yaml -f operator.yaml
kubectl apply -f common-external.yaml -f cluster-external.yaml 

```