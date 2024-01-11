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
  --set hostname=rancher.k8s.dcnt.company \
  --set bootstrapPassword=admin \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=jonathan22711@gmail.com \
  --set letsEncrypt.ingress.class=traefik


kubectl --kubeconfig $KUBECONFIG -n cattle-system exec $(kubectl --kubeconfig $KUBECONFIG -n cattle-system get pods -l app=rancher --no-headers | head -1 | awk '{ print $1 }') -c rancher -- reset-password

```


## Certs
Updating the Rancher Certificate

<https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/resources/update-rancher-certificate>

## Cleanup

https://github.com/rancher/rancher-cleanup
