# Traefik

## resources

https://technotim.live/posts/host-rancher-securely/

https://www.youtube.com/watch?v=G4CmbYL9UPg


### ingressClass
Value of kubernetes.io/ingress.class annotation that identifies resource objects to be processed.

If the parameter is set, only resources containing an annotation with the same value are processed. Otherwise, resources missing the annotation, having an empty value, or the value traefik are processed.

source: https://doc.traefik.io/traefik/providers/kubernetes-crd/

```bash
helm install --namespace=traefik traefik traefik/traefik --values=values.yaml
kubectl apply -f default-headers.yaml
```

## automation

return all active ingressroutes

```bash
kubectl get ingressroute --all-namespaces -o jsonpath='{range .items[*]}{.spec.routes[*].match}{"\n"}{end}' | sed -e 's/Host(`/\n/g' -e 's/`)//g' | grep -v '^[[:space:]]*$'
```

## upgrade helm chart to v28
```shell
helm upgrade --namespace=traefik traefik traefik/traefik --values=values.yaml --version v27.0.2
kubectl apply --server-side --force-conflicts -k https://github.com/traefik/traefik-helm-chart/traefik/crds/
helm upgrade --namespace=traefik traefik traefik/traefik --values=values.yaml --version v27.0.2
# helm upgrade --namespace=traefik traefik traefik/traefik --values=values.yaml --version v28.0.0
```
