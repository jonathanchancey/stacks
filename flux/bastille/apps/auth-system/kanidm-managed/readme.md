# kanidm managed

this is the dormant kaniop target for [`kanidm`](../kanidm/app/readme.md).
[`ks.yaml`](ks.yaml) is unreferenced by the namespace kustomization, and both flux
kustomizations are suspended. activation requires a separate maintenance window.

## configuration

[`app/kanidm.yaml`](app/kanidm.yaml) defines the pinned image and single primary
replica. [`app/resources/server.toml`](app/resources/server.toml) configures the
origin, proxy cidrs, ldaps, and online backups. keep domain and origin consistent
between both files. the existing `kanidm-tls` certificate remains in the old
deployment's flux inventory.

the custom `KANIDM_CONFIG` requires one replica and no kaniop backup schedule.
replication and operator backup schedules select generated toml instead. restart
the target pod after changing the configmap; its file is mounted with `subPath`.
the generated service is `kanidm-managed`, with https on `8443` and ldaps on
`3636`. production routes and backend tls policy remain in the old deployment.
flux checks the generated statefulset's readiness; authentication tests remain
part of the private validation before cutover.

## restore before startup

1. establish recovery access independent of kanidm. verify the pinned kaniop
   release and crds are ready, then block normal clients from the new target.
   capture the existing domain display name and logo privately. kaniop 0.19.1
   removes imported logos when `domainAppearance.image` is absent; configure
   `spec.domainAppearance.displayName` and `image.url` for required branding before
   operator reconciliation.
2. leave the app kustomization suspended. apply only [`app/pvc.yaml`](app/pvc.yaml)
   in `auth-system` and wait for the separate target claim to bind. never mount,
   rename, or transfer the production `kanidm` pvc to kaniop.
3. restore a same-version native kanidm backup into
   `kanidm-data-kanidm-managed-default-0` using the pinned image, a matching config,
   and uid/gid `1000`. do this with no target server running. remove the restore
   pod and verify the volume has detached before creating the `Kanidm` resource.
   prepopulating the operator's expected claim name requires a successful rehearsal.
   kanidm 1.11.2 backups use gzip by default; retain the `.json.gz` suffix because
   restore selects decompression by filename.
4. register this directory in the namespace kustomization while keeping both
   resources suspended. resume only `kanidm-managed` after confirming the claim
   contains the restored database. verify readiness, identity and oauth
   configuration, administrator access, password/passkey login, oauth refresh,
   group authorization, ldaps, proxy client addresses, and a second backup restore
   privately. keep the existing hostname and origin when testing.

retain encrypted logical backups outside both source and target volumes. keep
their decryption material accessible without kanidm and independent of the
operator's administrator password bootstrap. use native backup/restore rather
than kaniop's experimental backup and restore resources.

## administrator bootstrap

kaniop generates `kanidm-managed-admin-passwords` by recovering both `admin` and
`idm_admin` on the restored target. this does not change the old instance's
passwords. keep these credentials outside sops and git. deleting this secret can
rotate the passwords again; deleting the `Kanidm` resource also removes its owned
secret. retain the secret across restarts and recovery.

before declaring the final migration complete, have the user retrieve
`ADMIN_PASSWORD` and `IDM_ADMIN_PASSWORD` directly in a trusted local terminal and
save both in their password manager. keep them out of agent tools, chat, logs,
and repository files. rehearsal credentials are not final production credentials.

## cutover and rollback

cutover requires a separate maintenance window: freeze identity changes and all
client traffic, suspend the old flux kustomization and helm release, stop its
server, and take a final stopped-server backup. repeat the rehearsed native
restore on separate target storage with the target stopped. preserve the old
pvc. validate privately before changing the gateway backend and backend tls
policy to `kanidm-managed:8443`; migrate direct ldaps consumers separately.

resume `kanidm-managed-backup` when the final target is ready for cutover. it uses
the shared [volsync backup component](../../../components/volsync/backup), with an
independent `APP=kanidm-managed` and the operator's actual claim name. confirm a
completed backup and restore before retiring rollback storage.

before reopening traffic, rollback means stopping the target, restoring the old
route/tls policy, and resuming the original server on its untouched pvc. allow
only one backend to accept traffic. after reopening traffic, the old pvc is stale:
block clients again and explicitly accept lost changes or restore a same-version
target backup into separate rollback storage. do not silently restart stale data.

the target pvc is protected from flux pruning and retained on statefulset scale
down or deletion. generated secrets are not retained when deleting `Kanidm`. to
stop the target, suspend app reconciliation, set `replicas: 0` on its `Kanidm`,
and wait for its pod to terminate before touching data. retire the old release
after the rollback window and a successful target backup restore. first move the
still-needed route and certificate into separately reconciled or retained
ownership; removing them from the old inventory with pruning enabled deletes them.

references: [kaniop 0.19.1 api](https://github.com/pando85/kaniop/blob/v0.19.1/libs/operator/src/kanidm/crd.rs),
[administrator bootstrap](https://github.com/pando85/kaniop/blob/v0.19.1/libs/operator/src/kanidm/reconcile/secret.rs),
[kanidm 1.11.2 backup and restore](https://github.com/kanidm/kanidm/blob/v1.11.2/book/src/backup_and_restore.md).
