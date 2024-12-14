# cert-manager

https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/resources/upgrade-cert-manager


```
kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.7/cert-manager.crds.yaml


helm install \
  cert-manager jetstack/cert-manager \
  --set installCRDs=true \
  --version v1.12.7 \
  --namespace cert-manager
```

```
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager --values values.yaml
```