# Rancher

https://ranchermanager.docs.rancher.com/pages-for-subheaders/install-upgrade-on-a-kubernetes-cluster#install-the-rancher-helm-chart

```zsh
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
kubectl create namespace cattle-system
```

```zsh
# correct
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.k8s.chancey.dev \
  --set bootstrapPassword=admin \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=jonathan22711@gmail.com \
  --set letsEncrypt.ingress.class=traefik
```

## Certs
Updating the Rancher Certificate

<https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/resources/update-rancher-certificate>

## Cleanup

https://github.com/rancher/rancher-cleanup
