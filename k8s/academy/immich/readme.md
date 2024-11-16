# Immich

## Installation

```
helm repo add immich https://immich-app.github.io/immich-charts
helm repo update
helm upgrade --install -n immich immich immich/immich -f values.yaml

# reset values as needed
helm upgrade --install -n immich immich immich/immich -f values.yaml --reset-values
```

There are a few things that you are required to configure in your values.yaml before installing the chart:

You need to separately create a PVC for your library volume and configure immich.persistence.library.existingClaim to reference that PVC
You need to make sure that Immich has access to a redis, and postgresql instance. You can do this either by enabling them directly in the values.yaml, or by manually setting the entries under the env key to point to existing instances.
You need to set image.tag to the version you want to use, as this chart does not update with every Immich release.

## upstream charts

https://github.com/immich-app/immich-charts/blob/main/charts/immich/values.yaml
https://github.com/bjw-s/helm-charts/blob/main/charts/library/common/values.yaml
