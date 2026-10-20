# public ca trust

[`components/public-ca`](../flux/bastille/components/public-ca) supplies the
public root bundle for selected outbound tls clients. namespace kustomizations
create a local configmap; helm values and flux deployment patches mount it at
`/etc/ssl/certs`. `SSL_CERT_FILE` selects its bundle and `SSL_CERT_DIR` restricts
directory lookup to the same mount, excluding the image's old hashed roots.

envoy's system-trust backend policies and oidc token connections use the same
mounted `ca-certificates.crt`. barman's
[`ObjectStore` resources](../flux/bastille/apps/database/cloudnative-pg/cluster/objectstore.yaml)
use `endpointCA`, which accepts only a secret. the database kustomization
generates that secret from the same public file; the plugin mounts it and sets
`AWS_CA_BUNDLE` for its backup clients, overriding botocore's bundled roots.

## source and updates

`ca-bundle.crt` is an unmodified, mpl-2.0-licensed
[mozilla bundle published by curl](https://curl.se/docs/caextract.html).
the current snapshot is
[`cacert-2026-10-20.pem`](https://curl.se/ca/cacert-2026-10-20.pem), with sha256
`796f1389bfea13c0ed78f663b765baaff54a508e5483786bd6ece73c5e3e3cbe`.
it excludes the trust paths affected by the
[emudhra compromise](https://emudhra.we-have-a-problem.com/).

to refresh it:

1. download a dated curl bundle and verify its published sha256 before replacing
   the file. preserve the upstream content and license.
2. change the dated resource name in its generator, the database secret
   generator, and all consumers (`rg public-ca-bundle flux/bastille`). changing
   the mount reference rolls controllers instead of relying on cached root
   pools to reload. retain the old resource until its consumers have switched.
3. verify the advisory's twelve offline chains are rejected with
   `openssl verify -purpose sslserver -no-CApath -no-CAstore -CAfile BUNDLE -untrusted CHAIN CHAIN`.
   also check normal git, registry, acme, identity-provider, cloud-api, and backup
   connections with the replacement bundle.
4. run `nix develop --command python3 tools/scripts/check-public-ca.py flux/bastille/components/public-ca/ca-bundle.crt`
   and `nix develop --command task test-all CLUSTER=bastille NAMESPACE=default`.
   the ca check also runs in kubeconform ci to prevent reintroducing affected roots.

## bootstrap and recovery

follow the [bootstrap instructions](../flux/bastille/bootstrap/readme.md) to seed
the configmaps before starting cert-manager and flux. namespace-level resources
are subsequently owned by `bastille-apps`, not by the dependent helm releases.

missing bundle resources or keys prevent pods from mounting their trust store.
restore the expected resource from the checked-in bundle before restarting
controllers. do not make mounts optional or disable tls verification.

if a legitimate service stops validating, inspect its full chain and update its
certificate or the reviewed bundle. do not restore a compromised root.

this configuration does not replace private kubernetes/runner mtls authorities,
talos/node trust, the api server's public oidc trust, ci container trust, or
application-embedded trust stores. barman pods must be recreated if they do not
yet mount the `endpointCA` secret; inspect their volumes and backup health before
treating the change as deployed.
