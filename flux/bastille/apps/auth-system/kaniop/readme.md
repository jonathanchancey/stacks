# kaniop

[the helmrelease](app/helmrelease.yaml) manages the kanidm operator and its crds.
follow the [upstream upgrade guide](https://github.com/pando85/kaniop/blob/v0.25.0/Documentation/src/upgrade/index.md#minimum-supported-upgrade-source)
before changing the chart version.

## remove retired migration permissions

after upgrading from 0.20.0 to 0.25.0, confirm the `kaniop` helmrelease is ready on
0.25.0 and neither `kaniop-crd-migrate` nor `kaniop-crd-verify` is running in
`auth-system`. helm leaves the old migration hook permissions behind. delete
these release-specific objects:

```sh
kubectl delete clusterrole/kaniop-crd-migrator clusterrolebinding/kaniop-crd-migrator --ignore-not-found
kubectl -n auth-system delete role/kaniop-crd-migrator rolebinding/kaniop-crd-migrator serviceaccount/kaniop-crd-migrator --ignore-not-found
```

repeat the commands with `get` in place of `delete` and confirm both return no
objects. retain migration backup secrets until they are no longer needed for
recovery. see [upstream's cleanup guide](https://github.com/pando85/kaniop/blob/v0.25.0/Documentation/src/upgrade/index.md#clean-up-migration-leftovers).
