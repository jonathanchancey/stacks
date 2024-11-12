

```bash
helm repo add blakeblackshear https://blakeblackshear.github.io/blakeshome-charts/
helm repo update
helm upgrade --install -n frigate frigate blakeblackshear/frigate -f values.yaml
```