# kanidm

## upgrade policy

> Upgrades are supported from 1 release (minor version) before the current stable release.
>
> Example: A server running 1.2.0 may upgrade to version 1.3.0. A server running 1.2.0 may not upgrade to 1.4.0.

https://kanidm.github.io/kanidm/stable/support.html#upgrade-policy

https://hub.docker.com/r/kanidm/server/tags

## operator deployment

[`../../kaniop`](../../kaniop) installs the kaniop operator and its crds through
an oci helm chart. it does not create a `Kanidm` resource or adopt this release.
the chart's crd apply hooks remain enabled; do not disable helm hooks on upgrade.
operator permissions are cluster-wide, even though its deployment is in
`auth-system`.

## migration to kaniop

perform the migration in a separate change and maintenance window. keep the
server image pinned to the exact version and digest in [helmrelease.yaml](helmrelease.yaml);
do not combine a database upgrade with the ownership transfer. verify the running
image and configuration against git before proceeding.

### target configuration

use `kaniop.rs/v1beta1`, kind `Kanidm`, with a distinct name such as
`kanidm-managed` to avoid colliding with helm-owned resources. for kaniop 0.19.1:

- pin `spec.image` explicitly; its default is `kanidm/server:latest`. keep
  upgrade checks enabled. start with one `replicaGroups` entry named `default`,
  `replicas: 1`, and `primaryNode: true`; do not introduce replication.
- set `spec.domain` and `spec.origin` to the current toml values; the domain is
  immutable after creation.
- configure `storage.volumeClaimTemplate` with the current storage class, access
  mode, and sufficient capacity; omitted storage is ephemeral. there is no
  `existingClaim` field. the expected target pvc is
  `kanidm-data-kanidm-managed-default-0`. precreating and populating that new
  claim before creating the `Kanidm` resource requires a successful rehearsal;
  it is not a dedicated operator import api.
- set `tlsSecretName` to the existing certificate secret, `ldapPortName: ldaps`,
  and `securityContext` to the current uid/gid. the generated service is
  `kanidm-managed`, with https on 8443 and ldaps on 3636, not 443 and 636.
- mount an adapted copy of the current toml through `spec.volumes` and
  `spec.volumeMounts`, and select it with `spec.env` / `KANIDM_CONFIG`. change
  tls paths to `/etc/kanidm/tls/tls.crt` and `/etc/kanidm/tls/tls.key`. preserve
  the cidr-scoped proxy policy and online backups; do not replace that policy
  with `KANIDM_TRUST_X_FORWARD_FOR=true`, which trusts every source. provide a
  writable socket directory if retaining `KANIDM_ADMIN_BIND_PATH`.

this configuration path requires one replica and no operator backup schedule;
replication or operator backups select generated toml instead. kaniop 0.19.1's
backup/restore subsystem is experimental: use native kanidm backup/restore for
the migration, not `KanidmRestore` or `KanidmBackupSchedule`.

kaniop recovers both `admin` and `idm_admin` when its expected secret is absent,
even for an imported database. expect password rotation and securely retain
`kanidm-managed-admin-passwords`; deleting it can trigger recovery again. do not
assume the old administrator passwords survive adoption.

### preparation

1. verify kaniop's helm release is ready and its crds are established. confirm no
   existing kaniop resources would conflict with the planned cluster name.
2. record the current workload, service selectors, gateway route, backend tls
   policy, certificate, pvc, and backup resources. keep credential and client
   inventories outside this public repository. record recovery access that does
   not depend on kanidm login.
3. verify the latest volsync backup can be restored to a different pvc. also take
   a kanidm logical backup and store an encrypted copy outside the source volume.
   backups contain identity secrets; do not commit them or place them in logs.
4. preserve the original pvc and existing helm values for rollback. never attach
   the production pvc to a second server, rename it, or transfer its ownership to
   the operator. use separate target storage.

### rehearsal

restore a backup into an isolated target using the exact source server image.
kanidm requires backup and restore versions to match. do not use the operator's
default server image. use native `kanidmd database backup` / `database restore`
with the server stopped and the appropriate config, or copy the entire stopped
data volume, not individual sqlite files. a csi snapshot/clone is an alternative
only after verifying storage support and rehearsing recovery.

preserve the domain and origin from [resources/server.toml](resources/server.toml),
the certificate secret from [certificate.yaml](certificate.yaml), ldap support,
trusted proxy configuration, and storage permissions. do not expose the target
through the production route or dns. use a controlled test client with local
name resolution for the existing hostname so webauthn and oauth keep the correct
origin. block normal client access to the rehearsal copy.

verify database recovery, readiness, administrator access, password and passkey
login, oauth authorization and refresh, group authorization, and ldaps for the
clients actually in use. compare identity and oauth configuration privately,
including client secrets and signing keys; do not recreate users or oauth clients
from empty resources. verify proxy-derived client addresses and backup output.
rehearse restarting the target and restoring its backups.
measure recovery time before scheduling the cutover.

### cutover

1. freeze identity administration and block client traffic, including direct
   service and ldaps consumers. stop the old server before the final backup; an
   online rehearsal backup is not the final source of truth.
2. suspend the old flux kustomization and helm release before manually scaling its
   statefulset down. verify no reconciliation can restart it, and wait for the
   pod to terminate and the volume to detach. preserve the release, pvc, tls
   secret, route, and backup resources rather than uninstalling them.
3. take a final stopped-server backup and restore to fresh target storage using
   the rehearsed procedure. keep the original volume unchanged. do not start two
   independently writable copies of the same identity database for clients.
4. validate the operator-managed server privately, then change only the gateway
   backend and backend tls policy to its generated service and port. retain the
   hostname, certificate, and origin; handle ldaps consumers separately. keep
   traffic blocked until tls validation and the login checks pass.
5. reopen traffic and monitor authentication failures, oauth refresh, ldaps,
   operator reconciliation, and backup completion. arrange volsync protection for
   the actual target claim rather than assuming the existing `APP=kanidm`
   component protects it.

### rollback and retirement

before reopening traffic, rollback means stopping the target, restoring the old
route and tls policy, and resuming the old release on its untouched pvc. verify
its replica count and readiness before restoring access. never allow both
backends to receive client traffic.

after reopening traffic, the old pvc is stale: account changes, sessions, and
token state may exist only on the target. block traffic again and decide whether
to accept that loss or restore a same-version backup of the target into separate
rollback storage. do not silently restart the stale source or copy a running
sqlite database. rehearse this recovery path before cutover.

retire the old release and volume only after the agreed rollback window and a
successful target backup restore. separate the old route and certificate from
the retiring helm/flux inventory first so pruning cannot remove dependencies
still used by the target. adopt identity resources into git later, individually,
after checking their reconciliation and deletion behavior.

references:

- [kanidm 1.11.2 backup and restore](https://github.com/kanidm/kanidm/blob/v1.11.2/book/src/backup_and_restore.md)
- [kaniop chart](https://github.com/pando85/kaniop/tree/v0.19.1/charts/kaniop)
- [kaniop cluster api](https://github.com/pando85/kaniop/blob/v0.19.1/libs/operator/src/kanidm/crd.rs)
- [kaniop backup limitations](https://github.com/pando85/kaniop/blob/v0.19.1/Documentation/src/usage/backup-restore.md)
