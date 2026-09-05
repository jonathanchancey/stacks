# kanidm clients

Flux deploys a reconciler that runs every five minutes. Applications declare clients beside their manifests; [the registry](app/resources/registry.json) enrolls them and declares access groups. Group membership stays outside Git.

## bootstrap

From the repository root, authenticate as `idm_admin` and create the service account once:

```sh
kanidm login --name idm_admin
kanidm service-account create kanidm-client-reconciler "Kanidm client reconciler" idm_admin --name idm_admin
kanidm group add-members idm_oauth2_admins kanidm-client-reconciler --name idm_admin
kanidm group add-members idm_group_admins kanidm-client-reconciler --name idm_admin
kanidm service-account api-token generate kanidm-client-reconciler kubernetes --readwrite --name idm_admin --output json | python3 tools/scripts/install-kanidm-reconciler-token.py
```

The helper installs the token directly into `bastille/auth-system`; it does not print it or write a plaintext file. The account can manage OAuth clients and ordinary groups. Its Kubernetes permissions cover only explicitly enrolled ConfigMaps and destination Secrets.

After reconciliation succeeds, grant access using your regular account name:

```sh
kanidm group add-members kopia_users YOUR_ACCOUNT --name idm_admin
```

`basic_users` and `trusted_users` are available for future low risk and high trust services. Kopia uses only `kopia_users`.

## enroll a service

Copy Kopia's [client declaration](../../storage/kopia/app/resources/oidc-client.json) and [Secret/RBAC](../../storage/kopia/app/oidc-client.yaml), then enroll the ConfigMap in the registry. Configure the application's OIDC consumer to use the destination Secret. Keep callbacks exact and scopes minimal.

Existing clients and groups require explicit `adoptExisting: true`; review their access before opting in. Declared client callbacks and scope maps are authoritative. Membership is never overwritten, and removing a declaration does not delete the Kanidm entry or revoke access: retire it explicitly.

## check and recover

```sh
kubectl --context bastille -n auth-system get jobs -l app.kubernetes.io/name=kanidm-client-reconciler
kubectl --context bastille -n auth-system logs job/JOB_NAME
kubectl --context bastille -n storage get securitypolicy kopia-oidc
```

The stale reconciliation alert covers failures and missing bootstrap credentials. Replace an expired or revoked bootstrap token with the generation/install command above; revoke the old token after the new one works. Client secrets are copied from Kanidm, never reset. A changed client UUID requires manual review.

Back up the bootstrap Secret securely outside Git. A missing OIDC credential blocks the protected route until reconciliation succeeds.
