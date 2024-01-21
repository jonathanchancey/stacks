# synapse

## install

```bash
kubectl create namespace synapse
helm repo add ananace-charts https://ananace.gitlab.io/charts
helm upgrade --install=true synapse ananace-charts/matrix-synapse --version 3.7.15 --values values.yaml
```
