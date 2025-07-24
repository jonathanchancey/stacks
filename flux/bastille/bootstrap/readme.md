# bootstrap

after tofu apply task to:

- fetch talosconfig output and merge kubeconfig
- apply crds, ns, and secrets
```bash
kubectl apply -f namespace.yaml
kubectl create secret generic sops-age --namespace flux-system --from-literal=age.agekey=(keepassxc-cli show $VAULT_DIR/Passwords.kdbx stacks-age-key -a Password)
kubectl create secret generic github-token-auth-ro --namespace flux-system --from-literal=username=jonathanchancey --from-literal=password=(keepassxc-cli show $VAULT_DIR/Passwords.kdbx "github pat flux-readonly-exp-06-2026" -a Password)
# renovate: datasource=github-releases depName=kubernetes-sigs/gateway-api
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/experimental-install.yaml

# renovate: datasource=github-releases depName=prometheus-operator/prometheus-operator
kubectl apply --server-side -f https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.83.0/stripped-down-crds.yaml

# ceph and kube-system label
kubectl label namespace rook-ceph pod-security.kubernetes.io/enforce=privileged
kubectl label namespace kube-system pod-security.kubernetes.io/enforce=privileged
```

# cilium note
before reloader, ensure changes propagated with

```bash
kubectl -n kube-system rollout restart deployment/cilium-operator
kubectl -n kube-system rollout restart ds/cilium
```

# cloudflare
cloudflare-tunnel-id-secret
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
