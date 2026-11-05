# envoy gateways

[`envoy-internal`](app/gateway-internal.yaml) serves private routes. it keeps both
private vip addresses and dns aliases on one service.
[`envoy-external`](app/gateway-external.yaml) serves the
[cloudflared origin](../cloudflared/app/resources/config.yaml). each gateway has
its own proxy settings; their replica counts and shutdown settings are independent.

attach application routes to the gateway in `network`, using `https` or the
internal gateway's `https-bastille` listener. keep route names stable when changing
parents: authentication policies target routes by name. certificates belong in
[`certificate.yaml`](app/certificate.yaml), in the gateway's namespace.

[`traffic-policies.yaml`](app/traffic-policies.yaml) explicitly targets both
gateways with shared retries, compression, timeouts, forwarded-header trust, and
tls settings. [`https-redirect.yaml`](app/https-redirect.yaml) redirects their http
listeners. add new gateways to these references only when they need that behavior.

## crds

shared gateway api definitions are managed by
[gateway-api](../gateway-api/app/kustomization.yaml). the envoy controller chart
disables bundled crds to preserve that shared version.
[crds/ks.yaml](crds/ks.yaml) applies envoy-specific definitions from the controller
chart artifact; keep its source tag aligned with the controller chart when upgrading.

## replacing a gateway

renaming a gateway replaces its generated proxy resources. keep its service name,
dns annotations, route parents, network-policy selectors, topology selectors, and
dashboard filters consistent. manage generated services through the gateway and
`EnvoyProxy`, not direct edits.

allow a maintenance window when reusing vip addresses: old services must release
them before the replacement can acquire them. do not make old-gateway cleanup
depend on replacement readiness. issue required certificates in the destination
namespace before moving traffic, and verify every listener and route as well as
gateway readiness. preserve old dns aliases through cached cname expiry.

check authentication, websockets, object transfers, and cloudflared access after a
replacement. to roll back, restore gateway definitions and route parents together,
then reconcile their owning flux kustomizations and verify address ownership.
cilium still supplies cluster networking, bgp, and load-balancer allocation. its
gateway-api support remains enabled to preserve dataplane settings, but no cilium
gateway class or gateway is configured.
