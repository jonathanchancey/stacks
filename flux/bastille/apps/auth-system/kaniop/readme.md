# kaniop

[the helmrelease](app/helmrelease.yaml) manages the kanidm operator and its crds.
follow the [upstream upgrade guide](https://github.com/pando85/kaniop/blob/v0.25.0/Documentation/src/upgrade/index.md#minimum-supported-upgrade-source)
before changing the chart version.

## remove retired migration permissions

after upgrading from 0.20.0 to 0.25.0, run the
[cleanup script](../../../../../tools/resources/kaniop/cleanup-crd-migrator.sh)
with the `bastille` kubectl context available. helm leaves the migration hook
permissions behind. the script checks that the release is ready and the retired
jobs have finished, then removes and verifies the five release-specific objects.

```sh
nix develop --command bash tools/resources/kaniop/cleanup-crd-migrator.sh
```

retain migration backup secrets until they are no longer needed for recovery.
see [upstream's cleanup guide](https://github.com/pando85/kaniop/blob/v0.25.0/Documentation/src/upgrade/index.md#clean-up-migration-leftovers).
