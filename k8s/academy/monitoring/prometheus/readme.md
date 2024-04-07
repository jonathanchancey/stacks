# prometheus

```bash
kubens grafana
kubectl scale deploy prometheus-server --replicas 0
kubectl apply -f config.yaml
kubectl scale deploy prometheus-server --replicas 1
```
