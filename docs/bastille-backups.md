# Bastille backup and recovery runbook

Ceph replication provides availability; recovery depends on independent backups and successful restore tests. This deployment keeps application files in an encrypted Kopia repository on `vents.internal:/mnt/scale-worm/bastille/backup`, mounted as `/repository`. PostgreSQL uses CloudNativePG/Barman backups and WAL archival to the existing Backblaze B2 repositories.

## Coverage and schedules

Five applications use hourly, staggered VolSync sources. Retention keeps 24 hourly, 14 daily, 8 weekly, and 12 monthly recovery points; these categories overlap rather than representing an exact snapshot count.

| Namespace/application | Source PVC | Minute each hour |
| --- | --- | --- |
| automation/home-assistant | home-assistant | 05 |
| automation/zigbee | zigbee | 15 |
| automation/mosquitto | config-mosquitto-0 | 25 |
| auth-system/kanidm | kanidm | 35 |
| observability/grafana | grafana | 45 |

`media/homepage` retains its existing hourly backup and legacy restore component, with its existing 24-hour/7-day retention. It is separate from the five newly protected applications above.

CloudNativePG already schedules daily backups for `postgres` and `immich-postgres`. The added `bastille-pg-daily` schedule runs at 00:30 UTC and requests an immediate first backup. Preserve the matching Barman ObjectStore configuration and WAL archive when recovering; do not treat a raw database PVC snapshot as a replacement for native PostgreSQL recovery.

Explicit exclusions: the development workspace is disposable; NAS application data already has separate backups. Home Assistant's virtual environment and Immich machine-learning cache are rebuildable. Prometheus and Loki historical data are not backed up here; new telemetry regenerates, but past history would be lost.

## How application backups work

VolSync takes a Ceph CSI snapshot, provisions a temporary clone, and reads that clone into Kopia. The clone uses `ReadWriteOnce` so ext4 can replay its journal; the mover does not mount the application's original PVC. Snapshots capture filesystem state at a point in time, without guaranteeing application-level consistency across separate volumes or services.

Mover containers run as UID 0 with only the extra file-access capabilities `DAC_OVERRIDE`, `CHOWN`, and `FOWNER`, enabled by the namespace annotation `volsync.backube/privileged-movers: "true"`. They remain non-privileged containers. No mover `fsGroup` is set: recursively changing group ownership on a clone would alter the metadata recorded in the backup. Original application PVCs are not changed by these backup resources.

For another existing PVC, add `../../../../components/volsync/backup` to its Flux Kustomization, set `APP`, assign a staggered `VOLSYNC_SCHEDULE`, and set `VOLSYNC_SOURCE_PVC` if the claim name differs from `APP`. Mosquitto demonstrates the override. This component creates a source and repository Secret without taking ownership of the application PVC or adding a restore destination. Update the expected-source inventory in the VolSync PrometheusRule when adding coverage.

The NFS admission policy must match both Job `CREATE` and `UPDATE`: VolSync rebuilds Job templates during reconciliation. Keep the append-only volume/mount patches idempotent, with existence guards, and match the separate maintenance-job names and labels. A creation-only policy can lose the repository mount on a later update.

## Routine checks

- Check Flux, the ReplicationSource status, actual Kopia snapshots, and alerts together. A healthy application or bound PVC does not prove that a backup exists.
- Prometheus scrapes VolSync using its rotating service-account token and the metrics-reader RBAC binding. The dashboard depends on a healthy authenticated scrape.
- CloudNativePG alerts cover missing backup timestamps, failed backups, and base backups older than **36 hours**. The ObjectStore CRD must match the Barman operator: both now use v0.12.0. The old v0.5.0 CRD pruned the correctly spelled success/failure status timestamps, causing false zero-valued age metrics.
- `storage/kopia-verification` runs Sundays at 01:30 UTC. It reads the NAS mount read-only and verifies 100% of stored file contents, with two workers, a six-hour deadline, and no maintenance or snapshot creation. Failed, missing, overdue, and never-successful verification has alert coverage. Explicit `KOPIA_CACHE_DIRECTORY=/cache` is required because the image environment overrides the JSON cache path; logs use `/logs`.
- `storage/kopia` KopiaMaintenance runs daily at 09:30 UTC, owns maintenance as `maintenance@volsync`, and uses the existing repository Secret. Its timeout is three hours. Full maintenance checks repository structures; it does not replace full-file verification or restore testing.
- Review NAS capacity, storage health, and its independently managed backups. Keep clocks synchronized; repository maintenance relies on sensible timestamps.

Useful read-only checks:

```sh
kubectl --context bastille get replicationsources -A
kubectl --context bastille -n storage get kopiamaintenance,cronjobs,jobs
kubectl --context bastille -n database get backups,scheduledbackups
```

For an initial maintenance run, identify the CronJob from `KopiaMaintenance.status.activeCronJob` and create a uniquely named Job from that CronJob. Inspect its security context and `/repository` mount first. In VolSync v0.17.11, the separate `spec.trigger.manual` maintenance path hardcodes container UID 1000, overriding the intended UID 1012; the scheduled CronJob path honors the configured context. Run one maintenance job at a time.

## Safe isolated application restore

First confirm the expected repository, source identity, and an eligible stored snapshot. Choose a new PVC name and a new manual trigger for every attempt. The example restores the latest available Home Assistant snapshot into a separate claim; replace the example names before applying it. If selecting an older point, add `restoreAsOf` only after verifying the desired snapshot timestamp. The destination namespace must permit VolSync's file-access capabilities.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ha-recovery-check-20260905-01
  namespace: automation
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: ceph-block
  resources:
    requests:
      storage: 5Gi
---
apiVersion: volsync.backube/v1alpha1
kind: ReplicationDestination
metadata:
  name: ha-recovery-check-20260905-01
  namespace: automation
spec:
  trigger:
    manual: recovery-check-20260905-01
  kopia:
    repository: home-assistant-volsync-secret
    destinationPVC: ha-recovery-check-20260905-01
    copyMethod: Direct
    sourceIdentity:
      sourceName: home-assistant
      sourceNamespace: automation
    enableFileDeletion: false
    cacheCapacity: 1Gi
    cacheStorageClassName: openebs-hostpath
    cacheAccessModes: [ReadWriteOnce]
    cleanupCachePVC: true
    moverSecurityContext:
      runAsUser: 0
      runAsGroup: 1012
      runAsNonRoot: false
```

Never substitute the live application's PVC into a test destination. Mount the restored claim in an isolated inspection pod, compare file counts and ownership, validate database files and configuration, and test application recovery before planning a production switch. Preserve the original claim and avoid concurrent application writers during an actual recovery. Remove test resources only after recording the result and confirming their names.

Important v0.17.11 pitfalls:

- A paused Kopia source or destination can report completion, update timestamps, and consume `spec.trigger.manual` without moving data. After unpausing or aborting, use a **new** manual trigger. Reusing the consumed value does not retry the operation.
- A restore with no eligible snapshot can exit successfully with no files. Require actual mover restore logs and content checks; `lastManualSync` and `lastSyncTime` alone are insufficient.
- `enableFileDeletion: true` deletes destination contents **before** checking whether an eligible snapshot exists. Leave it false and restore into a new claim.
- The mover ignores ownership/permission errors by default. Check ownership after restoration. Its `additionalArgs` also reach repository connection commands, so adding restore-only flags there can break connection setup.
- `/restore/data` in a destination mover is the new PVC; source snapshots use `/data`. VolSync translates between those paths when selecting snapshots.

For PostgreSQL, recover to a separate CloudNativePG cluster using the original ObjectStore/server identity, then check recovery completion, database inventory, SQL integrity, roles/extensions, and application queries before changing application connections. A healthy recovered pod is only one part of the test.

## Recorded validation

Evidence recorded on 2026-09-05: all five new application backups completed without reported backup errors, and all five isolated restores passed the following checks.

| Restored application | Evidence |
| --- | --- |
| Home Assistant | Initially 57 files, approximately 54.45 MB; SQLite integrity passed and 24 JSON files parsed. SQLite checkpoint cleanup removed WAL/SHM files, leaving 55 files. |
| Zigbee | 7 files, 19,983 bytes; all ownership 1000:1000; 2 JSON files parsed. |
| Mosquitto | 1 file, 393,838 bytes; ownership 1000:1000. |
| Kanidm | 12 files, 6,845,148 bytes; `kanidm.db` SQLite integrity passed. |
| Grafana | 366 files, 53,363,076 bytes; all ownership 472:472; `grafana.db` SQLite integrity passed and 31 JSON files parsed. |

- `bastille-pg` native base backup succeeded at 18:14:27 UTC. Its isolated recovered cluster exposed all 6 databases; read-only heap scans covered 316 ordinary tables and counted 69,901 rows. PostgreSQL checksums are disabled; this does not claim exhaustive index or TOAST integrity validation. Original clusters remained ready.
- Full-file verification completed at **18:33:11 UTC**, reading 100% of 397 files, 118.7 MB, across 470 objects.
- Kopia maintenance completed at **18:36:00 UTC**, taking 1,210 seconds and cleaning 15,898 repository logs. Ownership is `maintenance@volsync`.
- Authenticated VolSync metrics are up. After aligning the Barman CRD to v0.12.0, backup timestamps for all three active database clusters are positive and correct. No current VolSync, Kopia, or CloudNativePG backup alerts are firing.
- All **24 original PVC identities and specifications** were checked and remain unchanged.

Repository validation passed all 80 tests and Kubeconform. Admission regression checks against the real Kubernetes API confirmed that unrelated init containers survive, repeated mutation does not duplicate injected fields, and Job updates retain the original immutable template. Prometheus rule checks passed, including 11 maintenance-alert scenarios.

Deploy these resources through `main` and verify that the affected Flux Kustomizations report the merged revision with `Ready=True`. Keep the successful maintenance and verification Job records. Temporary restore destinations, inspection Jobs, PVCs, and the isolated recovery cluster can be removed after comparing their identities with the original-volume inventory.

## Credentials and source references

Keep the SOPS age recovery key and Kopia repository password separately recoverable from the cluster and this repository. Encrypted backup blobs cannot be recovered without the password. Encryption does not prevent an authorized client or ransomware from deleting backups; retain the NAS's independently managed recovery protections. This change does not configure another remote copy of the Kopia repository.

Configuration and encrypted credentials, with no secret values included here:

- [VolSync repository Secret](../flux/bastille/components/volsync/secret.sops.yaml), [Kopia Secret](../flux/bastille/apps/storage/kopia/app/secret.sops.yaml), and [repository configuration](../flux/bastille/apps/storage/kopia/app/resources/repository.config).
- [Backup-only component](../flux/bastille/components/volsync/backup/kustomization.yaml), [maintenance](../flux/bastille/apps/storage/kopia/app/kopiamaintenance.yaml), and [verification](../flux/bastille/apps/storage/kopia/app/verification.yaml).
- [CloudNativePG configuration](../flux/bastille/apps/database/cloudnative-pg/cluster/kustomization.yaml) and [encrypted database credentials](../flux/bastille/apps/database/cloudnative-pg/app/secret.sops.yaml).
- Exact [VolSync v0.17.11 mover](https://github.com/perfectra1n/volsync/blob/v0.17.11/internal/controller/mover/kopia/mover.go), [state machine](https://github.com/perfectra1n/volsync/blob/v0.17.11/internal/controller/statemachine/machine.go), and [restore script](https://github.com/perfectra1n/volsync/blob/v0.17.11/mover-kopia/entry.sh).
- [Kopia verification guidance](https://kopia.io/docs/advanced/consistency/) and [CloudNativePG recovery documentation](https://cloudnative-pg.io/documentation/current/recovery/).
