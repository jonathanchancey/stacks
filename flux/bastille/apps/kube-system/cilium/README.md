# hubble certificates

hubble uses cert-manager for internal mutual tls. the [ca resources](app/certs/hubble.yaml)
bootstrap a private ca in `kube-system`; the [helmrelease](app/helmrelease.yaml)
selects its namespaced issuer. the cilium chart creates `hubble-server-certs` and
`hubble-relay-client-certs` certificate resources with 90-day lifetimes.
cert-manager renews their secrets, and hubble reloads them automatically.

inspect issuance with `kubectl -n kube-system get issuers,certificates,certificaterequests`.
if renewal fails, check the certificate and issuer conditions and restore the
issuer before forcing renewal with `cmctl renew -n kube-system <certificate>`.

the ca has a ten-year lifetime and renews one year before expiry. ca renewal does
not trigger leaf renewal: after a ca change, renew both hubble certificates and
verify relay connectivity. plan for a temporary interruption while peers reload
the new trust material. do not delete the ca secret to repair a leaf certificate.

cluster bootstrap must install cilium networking before cert-manager; enable this
hubble configuration after cert-manager is ready. the helmrelease dependency
enforces that order for gitops reconciliation. gateway https certificates remain
separate in [chancey-dev.yaml](app/certs/chancey-dev.yaml).
