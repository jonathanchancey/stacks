# ceph security maintenance

[`helmrelease.yaml`](app/helmrelease.yaml) pins the ceph image for both daemons
and the toolbox. update its `cephImage.tag` to an official squid release and
matching digest. review the [ceph release notes](https://docs.ceph.com/en/latest/releases/squid/)
and [rook upgrade guide](https://rook.io/docs/rook/v1.20/Upgrade/ceph-upgrade/) first.

`cephClusterSpec.security.cephx` controls key rotation. increment
`keyGeneration` above all recorded generations for a new rotation. check
`status.cephx` and daemon pod-template `cephx-status` annotations; newly created
daemons can already record generation 1. leave the desired generation in git
afterward. rook selects the supported daemon cipher automatically.

csi `aes256k` requires ceph-csi `3.17.1` or newer and kernel support on
every host. on non-fips hosts, talos `1.13.10` and `1.14.0` backported support
to linux `6.18`; upstream requires linux `7.0` (`7.2` with fips). verify an isolated
strong-key volume mount on every host before migrating.

retain every potentially mounted credential generation with
`keepPriorKeyCountMax` during rotation, including generations retained by
previous rotations. check statefulset pvc retention before scaling down.
fully detach and remount each affected volume before pruning prior keys.
restrict `allowedCiphers` only after every authentication
key reports `aes256k` and client access has been verified. new or reinstalled
nodes must also retain kernel support. review the
[rotation procedure](https://rook.io/docs/rook/v1.20/Storage-Configuration/Advanced/cephx-key-rotation/)
before changing ciphers or pruning keys.

before upgrading, require healthy storage, current application backups, and
protected recovery copies of the ceph configuration and authentication state.
afterward, check daemon versions, `status.cephx`, authentication key types, and
new volume provisioning, snapshots, restores, and existing application access.
old service-ticket warnings can take two to three hours to clear. aes client
compatibility warnings remain until client migration; keep them visible.

managers use pod networking through `cephClusterSpec.mgr.hostNetwork: false`.
keep `cephClusterSpec.cephConfig.mgr.public_network` aligned with the pod cidr,
separate from the host networking used by the storage daemons.
verify the [dashboard route](app/httproute.yaml) through every gateway node
after manager or gateway networking changes.

before switching existing managers to pod networking, set their startup range
with `ceph config set mgr public_network <pod-cidr>`. rook applies `cephConfig`
after manager startup, so the range must be available before the rollout.

## object storage

[`cephObjectStores`](app/helmrelease.yaml) configures the s3 store, replicated
pools, gateway placement, and `ceph-bucket` storage class. gateways use pod
networking; the [internal route](app/httproute.yaml) terminates tls for
`https://s3.bastille.chancey.dev`. clients must use path-style access, region
`us-east-1`, and s3 access keys rather than browser authentication. route request
timeouts are disabled for large transfers; clients should set their own timeouts.

add an `ObjectBucketClaim` to the consuming application's kustomization, with a
unique bucket prefix and an appropriate quota:

```yaml
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: app-bucket
spec:
  generateBucketName: app-bucket
  storageClassName: ceph-bucket
  additionalConfig:
    maxSize: "10G"
```

rook creates a secret and configmap named after the claim in its namespace.
the secret contains `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`; the configmap
contains `BUCKET_HOST`, `BUCKET_PORT`, and `BUCKET_NAME`. configure the client
explicitly for https. keep credentials out of git. application buckets belong
with their consumers, not in the cluster chart.

`Retain` preserves buckets after claim deletion; `preservePoolsOnDelete` preserves
pools after store deletion. neither is a backup. keep claims and credential
secrets intact during application removal until recovery or deliberate cleanup
is planned. recreating a generated-name claim does not reconnect the old bucket;
use rook's [existing-bucket procedure](https://rook.io/docs/rook/v1.20/Storage-Configuration/Object-Storage-RGW/ceph-object-bucket-claim/)
for recovery. never delete retained pools as routine cleanup.

before enabling the store, check ceph health, free capacity, and schedulable
gateway resources. object data shares disks with block volumes; monitor ceph
capacity and use per-claim quotas. keep disaster-recovery backups outside this
cluster. after reconciliation, check `CephObjectStore` readiness, both rgw pods on
different hosts, and the route's `Accepted` and `ResolvedRefs` conditions. verify
a disposable bucket's upload/download, multipart transfer, and access through a
gateway restart before onboarding applications.
