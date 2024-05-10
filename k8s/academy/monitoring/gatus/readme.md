# gatus

```bash
kubectl create ns monitoring
kubens monitoring
helm repo add minicloudlabs https://minicloudlabs.github.io/helm-charts
helm install gatus -n monitoring minicloudlabs/gatus
```
