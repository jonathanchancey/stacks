# conduit-00

academy database node

kubectl taint node conduit-00 workload=database:NoSchedule
```shell
kubectl taint node conduit-00 node-role.kubernetes.io/postgres=:NoSchedule
kubectl label node conduit-00 node-role.kubernetes.io/postgres=
```

https://cloudnative-pg.io/documentation/1.25/architecture/#proposed-node-label

kubectl taint node scribe-00 node-role.kubernetes.io/longhorn=:NoSchedule
kubectl taint node scribe-01 node-role.kubernetes.io/longhorn=:NoSchedule
kubectl taint node scribe-02 node-role.kubernetes.io/longhorn=:NoSchedule

