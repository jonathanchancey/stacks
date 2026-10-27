# ceph security maintenance

[`helmrelease.yaml`](app/helmrelease.yaml) pins the ceph image for both daemons
and the toolbox. update its `cephImage.tag` to an official squid release and
matching digest. review the [ceph release notes](https://docs.ceph.com/en/latest/releases/squid/)
and [rook upgrade guide](https://rook.io/docs/rook/v1.20/Upgrade/ceph-upgrade/) first.

`cephClusterSpec.security.cephx` controls key rotation. increment
`keyGeneration` above the corresponding `status.cephx` generation for a new
rotation; leave the desired generation in git afterward. rook selects the
supported daemon cipher automatically.

csi uses `keyType: aes` until every host kernel supports `aes256k` (linux 7.0+;
7.2+ with fips). `keepPriorKeyCountMax: 1` keeps existing mounts working while
new mounts use rotated keys. retain prior keys until all affected volumes have
been remounted and verified. review the [rotation procedure](https://rook.io/docs/rook/v1.20/Storage-Configuration/Advanced/cephx-key-rotation/)
before changing ciphers or pruning keys.

before upgrading, require healthy storage, current application backups, and
protected recovery copies of the ceph configuration and authentication state.
afterward, check daemon versions, `status.cephx`, authentication key types, and
new volume provisioning, snapshots, restores, and existing application access.
old service-ticket warnings can take two to three hours to clear. aes client
compatibility warnings remain until client migration; keep them visible.
