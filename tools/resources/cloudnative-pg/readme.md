# cloudnative-pg backup checks

[`barman-upgrade-test.yaml`](barman-upgrade-test.yaml) starts on-demand plugin
backups. it is outside the flux tree and runs only when applied manually.
check the barman deployment and database sidecar images before applying it.

```sh
nix develop --command kubectl apply -f tools/resources/cloudnative-pg/barman-upgrade-test.yaml
nix develop --command kubectl -n database get backups -l app.kubernetes.io/part-of=barman-upgrade-test
```

wait for each backup's `status.phase` to become `completed`; inspect its
`status.error` if it becomes `failed`. these backups check archive creation,
not recovery. use an isolated restore to verify recovery separately.

both resources carry `stacks.chancey.dev/cleanup: required`. remove their
kubernetes records after inspection:

```sh
nix develop --command kubectl delete -f tools/resources/cloudnative-pg/barman-upgrade-test.yaml
```

remote backup objects remain subject to the objectstore retention policy.
