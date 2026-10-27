# blackbox exporter

[prometheus probes](app/probe.yaml) check the public https endpoints on
`network/envoy-external` once per minute. the exporter uses `dnsPolicy: None`
and public cloudflare resolvers in [the helmrelease](app/helmrelease.yaml), so
cluster or local split dns cannot hide a missing public dns record. allow udp
and tcp port 53 to those resolvers when changing egress policy.

[modules](app/config.yaml) verify tls and reject redirects. the immich probe
expects `ok` from `/share/healthcheck`. the flux webhook probe expects the 404
returned by an unsigned request to `/hook/`; it checks public dns and https
reachability, but does not validate a signed delivery or distinguish a missing
route that also returns 404. no receiver token is needed.

add public urls in the probes and expected responses in the modules. keep the
`cloudflare-tunnel-` job prefix so the [alerts](app/prometheusrule.yaml) cover
new endpoints. update these explicit targets when changing gateway httproutes.

inspect `probe_success`, `probe_http_status_code`, and `probe_duration_seconds`
in prometheus with `{job=~"cloudflare-tunnel-.+"}`. failures lasting five minutes
alert, including exporter scrape failures. certificate expiry warns at fourteen
days. if a target fails, check its public dns before inspecting cloudflared,
the gateway route, and its backend. these checks run inside the cluster through
the public edge; they cannot report an outage while prometheus itself is down.
