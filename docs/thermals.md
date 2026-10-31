# thermals

the `bastille thermals` dashboard uses node-exporter's `hwmon` and `thermal_zone`
collectors. edit queries and node scope in the [dashboard definition](../flux/bastille/apps/observability/kube-prometheus-stack/dashboards/thermals.json),
following the [dashboard workflow](grafana-dashboards.md).

use the node selector for comparisons and the detail metric selector for history.
the filterable inventory table retains every current value, including zero,
negative readings, limits, and alarm flags.

sensor availability comes from the kernel drivers and hardware. check
`/sys/class/hwmon` and `/sys/class/thermal` through `talosctl` when a reading is
missing, then check `node_scrape_collector_success` and the
[exporter configuration](../flux/bastille/apps/observability/kube-prometheus-stack/app/helm/values.yaml).
new sensors appear automatically within the dashboard's node scope.

motherboard channels can be unwired or uncalibrated. thermal zones can duplicate
cpu package readings, and nvme numbering can change. the dashboard does not infer
board-specific voltage scaling or safe temperature limits. metric names indicate
exporter units; other fields retain raw values. the
[hwmon collector](https://github.com/prometheus/node_exporter/blob/v1.11.1/collector/hwmon_linux.go)
also scales `node_hwmon_temp_crit_alarm_celsius` as a temperature despite its
underlying alarm-flag meaning.
