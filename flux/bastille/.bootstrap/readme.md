# boostrap

after tofu apply
task to

- fetch talosconfig output
- merge kubeconfig
  - test connection

kubectl apply -f namespace.yaml

kubectl create secret generic sops-age --namespace flux-system --from-literal=age.agekey=(keepassxc-cli show $VAULT_DIR/Passwords.kdbx stacks-age-key -a Password)

cloudflare-tunnel-id-secret

apply crds

```yaml
---
apiVersion: v1
kind: Secret
metadata:
    name: cloudflare-tunnel-id-secret
    namespace: network
stringData:
    CLOUDFLARE_TUNNEL_ID: BLANK
```

# renovate: datasource=github-releases depName=prometheus-operator/prometheus-operator

<https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.83.0/stripped-down-crds.yaml>
kubectl apply --server-side -f stripped-down-crds.yaml
