# PrivateBin



## install
```bash
helm repo add privatebin https://privatebin.github.io/helm-chart
helm repo update
helm install privatebin privatebin/privatebin -n privatebin --create-namespace --values values.yaml
```

```yaml
helm upgrade privatebin privatebin/privatebin -n privatebin --values values.yaml
```