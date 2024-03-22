# homepage


## quick update

```bash
kubectl scale deploy homepage --replicas 0
kubectl apply -f configmap.yaml
kubectl scale deploy homepage --replicas 1
```

