# Authentik

https://goauthentik.io/docs/installation/kubernetes

```bash
helm repo add authentik https://charts.goauthentik.io
helm repo update
kubectl create namespace authentik
helm upgrade --install authentik authentik/authentik -f values.yaml -n authentik
```

## Redirect URL regex drafting

https://^[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+\.chancey\.dev$