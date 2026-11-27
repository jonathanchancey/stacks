# openbao

the singleton stores raft on ceph and unlocks with the sops-managed [static seal](server/app/seal.sops.yaml). keep the age identity and backup repository access recoverable outside bastille. retain the matching seal key for every retained backup. cert-manager issues the internal listener certificate independently of openbao.

[server.hcl](server/app/server.hcl) initializes an empty datastore. apply later policy or auth changes through the api as well. the operator identity is administrative: restrict who can create tokens or pods using the `openbao-operator` service account in this namespace. request a short-lived token with audience `openbao` and exchange it at `auth/kubernetes/login` with role `operator`. use tls with the [listener ca](server/app/ca.crt).

the [snapshot job](server/app/snapshot.yaml) atomically replaces the last complete raft snapshot. volsync copies the staging claim into kopia. recover that claim to a separate volume using the [backup procedure](../../../../docs/bastille-backups.md). start an isolated server with empty raft storage and the matching seal, authenticate to that server, and run `bao operator raft snapshot restore` against the recovered file. verify a known value and policy before switching consumers.
