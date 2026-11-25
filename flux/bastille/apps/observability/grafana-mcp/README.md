# grafana mcp

the [helm release](app/helmrelease.yaml) serves streamable http at
`https://grafana-mcp.bastille.chancey.dev/mcp` through the internal gateway.
clients need network access to that gateway and a bearer token from
`grafana-mcp-secret` in the `observability` namespace.

the [service account](app/grafanaserviceaccount.yaml) uses the existing grafana
operator instance. the operator maintains its editor role and writes its grafana
token to `grafana-mcp-grafana-token`. this token stays in the cluster; clients use
the separate bearer token in [the encrypted secret](app/secrets.sops.yaml).
dashboard, datasource, prometheus, loki, and alerting tools are enabled, including
dashboard and alert edits. usage reporting is disabled.

for interactive prometheus charts, use `render_grafana_app` with
`query_prometheus` as the source in an mcp client that supports apps.
the [tool policy](app/configmap.yaml) excludes server-side png rendering.
clients parsing `query_prometheus_histogram` results should query
`histogram_sum(...)` separately when they need the native histogram sum.
