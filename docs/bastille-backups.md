# backup and recovery

Application PVCs use VolSync snapshots and an encrypted Kopia repository on NFS. PostgreSQL uses native CloudNativePG/Barman backups and WAL archival.

## configuration

- [Backup component](../flux/bastille/components/volsync/backup/kustomization.yaml): add to an application's Flux Kustomization, set `APP`, and override `VOLSYNC_SOURCE_PVC` when the claim name differs. Set `VOLSYNC_SCHEDULE` to spread backups across the hour.
- [ReplicationSource template](../flux/bastille/components/volsync/backup/replicationsource.yaml): retention and temporary snapshot-clone settings. This component does not create or take ownership of the application's PVC.
- [Maintenance](../flux/bastille/apps/storage/kopia/app/kopiamaintenance.yaml) and [verification](../flux/bastille/apps/storage/kopia/app/verification.yaml): repository maintenance and read-only full-file checks.
- [Database configuration](../flux/bastille/apps/database/cloudnative-pg/cluster/kustomization.yaml): native database backup schedules and monitoring.

Update the expected-source inventory in the VolSync PrometheusRule when adding coverage. Keep operational inventories and restore-test results outside the public repository.

## recovery

1. Confirm the repository, source identity, and a complete snapshot with no reported file errors. Failed backup attempts can leave incomplete snapshots.
2. Create a separate destination PVC and ReplicationDestination. Never use a live application's PVC for a restore test.
3. Set the correct `sourceIdentity`, use `copyMethod: Direct`, and leave `enableFileDeletion: false`. Select a verified recovery point with `restoreAsOf` when necessary.
4. Inspect restored files, ownership, configuration, and database integrity. A successful job alone does not prove a usable recovery.
5. Test application recovery in isolation before changing production connections. Remove only the identified test resources afterward.

For PostgreSQL, recover into a separate CloudNativePG cluster using the original backup source. Validate recovery and application queries before switching connections.

Keep the Kopia password and SOPS recovery key recoverable independently of the cluster. Encryption does not protect against backup deletion; maintain independent recovery copies or protected snapshots.

## implementation notes

- Snapshot clones use `ReadWriteOnce` so the filesystem can replay its journal. Movers do not mount the original application PVC. Filesystem snapshots do not guarantee consistency across services or volumes.
- Movers need the configured file-access capabilities to preserve ownership. Avoid adding an `fsGroup` that would rewrite backed-up metadata.
- Admission patches must be idempotent and cover both Job creation and updates, while preserving unrelated init containers.
- The VolSync dashboard requires authenticated Prometheus scraping and the correct datasource UID. Keep the Barman ObjectStore CRD aligned with the installed operator.
- Maintenance does not replace full-file verification or restore testing. Use the generated maintenance CronJob for an initial run and run only one maintenance job at a time.

The installed VolSync v0.17.11 has recovery caveats: paused operations can consume manual triggers without moving data; use a new trigger after unpausing. Restores with no eligible snapshot can exit successfully with no files, and permission errors may be ignored. Always inspect the restored content. Clear completed manual source triggers to resume scheduled backups.

## references

- [VolSync restore implementation](https://github.com/perfectra1n/volsync/blob/v0.17.11/mover-kopia/entry.sh)
- [Kopia verification](https://kopia.io/docs/advanced/consistency/)
- [CloudNativePG recovery](https://cloudnative-pg.io/documentation/current/recovery/)
