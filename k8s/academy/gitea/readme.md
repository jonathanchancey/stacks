# native helm install

```shell
helm upgrade --install -n gitea gitea gitea-charts/gitea --version 10.6.0 --values values.yaml --values secrets.sops.yaml
```
