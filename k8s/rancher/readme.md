# Rancher

https://ranchermanager.docs.rancher.com/pages-for-subheaders/install-upgrade-on-a-kubernetes-cluster#install-the-rancher-helm-chart

```fish
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
kubectl create namespace cattle-system
helm install rancher rancher-latest/rancher 
```


```zsh
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.k8s.chancey.dev \
  --set bootstrapPassword=admin \
  --set letsEncrypt.ingress.class=traefik

helm upgrade rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.k8s.chancey.dev \
  --set bootstrapPassword=admin \
  --set letsEncrypt.ingress.class=traefik

# correct
helm upgrade rancher rancher-latest/rancher \
          --namespace cattle-system \
          --set hostname=rancher.k8s.chancey.dev \
          --set bootstrapPassword=admin
```