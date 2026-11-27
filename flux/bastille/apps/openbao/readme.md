# openbao

the singleton stores raft on ceph and unlocks with the sops-managed [static seal](server/app/seal.sops.yaml). keep the age identity and backup repository access recoverable outside bastille. retain the matching seal key for every retained backup. cert-manager issues the internal listener certificate independently of openbao.

[server.hcl](server/app/server.hcl) initializes an empty datastore. apply later policy or auth changes through the api as well. reserve workload creation, pod exec, secret access and operator token issuance in this namespace for trusted administrators and controllers. consumers authenticate remotely from their own namespaces.

for administrative access, request a short-lived token for `openbao/openbao-operator` with audience `openbao` and exchange it at `auth/kubernetes/login` with role `operator`. use tls with the [listener ca](../../components/openbao-ca/ca.crt). on first commissioning, create recovery shares at `sys/rotate/recovery/init` and escrow them encrypted outside the cluster before taking the baseline backup. keep their recovery location with the seal recovery instructions. test root generation on an isolated restore and revoke the generated token.

the [snapshot job](server/app/snapshot.yaml) publishes complete raft archives by atomic rename. size staging for two full archives plus overhead when expanding raft storage. volsync backs up the published archive through kopia.

## restore

1. restore the kopia recovery point to a new pvc using the [backup procedure](../../../../docs/bastille-backups.md) with `sourceIdentity.sourceName: openbao`, `sourceIdentity.sourceNamespace: openbao`, and `sourceIdentity.sourcePVCName: openbao-snapshots`.
2. start a temporary server in the openbao namespace with the same seal, listener, config and reviewer service account. give it empty raft storage, a read-only mount of the recovered claim, and distinct labels so the live service cannot select it.
3. connect directly to the temporary pod over loopback tls. exchange an operator service account token there and run `bao operator raft snapshot restore /recovered/openbao.snap`.
4. authenticate again after the backed-up roles replace the temporary state. verify a known value and policy, then remove the temporary resources. keep the production service selector and raft claim out of the drill.
