# homepage

## quick update

```bash
kubectl -n homepage scale deploy homepage --replicas 0
kubectl -n homepage apply -f configmap.yaml
kubectl -n homepage scale deploy homepage --replicas 1
```

## resources
https://simpleicons.org/?q=gatus
https://mdi.bessarabov.com/
https://github.com/walkxcode/dashboard-icons/tree/main/png
