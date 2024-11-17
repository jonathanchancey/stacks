# prometheus

```bash
kubens grafana
kubectl apply -k .
# edit deployment with new configmap
kubectl apply -f deploy.yaml
```

```
kubens grafana
kubectl scale deploy prometheus-server --replicas 0
kubectl apply -f config.yaml
kubectl scale deploy prometheus-server --replicas 1
```
