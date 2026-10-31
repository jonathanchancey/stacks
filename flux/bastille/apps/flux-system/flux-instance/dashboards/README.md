# flux dashboards

`flux-cluster.json` uses `flux_resource_info` from the flux operator for resource
readiness and suspension, including oci sources. controller reconciliation timings
come from the [pod monitor](../app/podmonitor.yaml). keep `honorLabels` disabled so
resource namespaces become `exported_namespace`, separate from the controller's
scrape namespace.

`flux-control-plane.json` shows controller health and activity. both dashboards
use the selected prometheus datasource; rate windows follow `$__rate_interval`
so they cover multiple scrapes. resource status follows the operator's reporting
interval. absent resource metrics must remain no-data rather than report healthy.

these local dashboards are based on grafana.com dashboards
[16714 revision 1](https://grafana.com/api/dashboards/16714/revisions/1/download) and
[21149 revision 1](https://grafana.com/api/dashboards/21149/revisions/1/download).
edit the json files and keep their uids stable. the configmap disables flux
substitution to preserve grafana variables; grafana operator imports the files.
