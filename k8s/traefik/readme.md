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

helm upgrade --namespace=traefik traefik traefik/traefik --values=values.yaml

kubectl apply -f default-headers.yaml
```