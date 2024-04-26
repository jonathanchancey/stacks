# homepage


## quick update

```bash
kubectl -n homepage scale deploy homepage --replicas 0
kubectl -n homepage apply -f configmap.yaml
kubectl -n homepage scale deploy homepage --replicas 1
```

