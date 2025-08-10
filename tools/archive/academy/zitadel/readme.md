# zitadel

```bash
kubectl create ns zitadel
kubens zitadel
kubectl apply -f certs-job.yaml
helm install --wait db bitnami/postgresql --version 15.1.2 --values postgres-values.yaml --values postgres-values-secrets.yaml
helm repo add zitadel https://charts.zitadel.com
helm upgrade --install zitadel zitadel/zitadel --values zitadel-values.yaml --values zitadel-values-secrets.yaml
# kubectl --namespace zitadel port-forward svc/zitadel 443:80
helm upgrade zitadel zitadel/zitadel --version 8.0.0 --reuse-values
```
