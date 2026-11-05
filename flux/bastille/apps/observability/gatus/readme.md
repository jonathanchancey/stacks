# gatus

[the sidecar](app/helmrelease.yaml) uses `--auto-httproute` to discover routes in
all namespaces and write endpoint configuration for gatus to reload. routes use
https, the first hostname, and the first usable path match. aliases need separate
explicit checks.

put exceptions on the route's metadata, or under its chart's route annotations:

```yaml
annotations:
  gatus.home-operations.com/endpoint: |-
    path: /health
    conditions: ["[STATUS] == 200"]
```

`name` preserves an endpoint's identity when its route name differs. `path`,
`conditions`, and `client` override health behavior beside the route; see the
[sidecar reference](https://github.com/home-operations/gatus-sidecar/tree/0.6.1#annotations).
set `gatus.home-operations.com/enabled: "false"` on routes that cannot provide a
meaningful check, such as a post-only webhook.

internal routes receive http availability checks too. the
[base configuration](app/resources/config.yaml) defines metrics, connectivity,
and postgresql storage; [alert rules](app/prometheusrule.yaml) handle failures.
