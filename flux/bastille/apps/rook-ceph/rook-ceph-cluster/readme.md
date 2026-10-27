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
