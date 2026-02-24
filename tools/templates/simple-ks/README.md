# Bastille App Template

Template for creating new Flux app deployments

## Template Variables

- `{{ APP_NAME }}` - Name of application
- `{{ NAMESPACE }}` - Target namespace
- `{{ CHART_URL }}` - OCI chart URL e.g. `oci://ghcr.io/org/charts/app`
- `{{ CHART_VERSION }}` - Chart version
- `{{ HOSTNAME }}` - External hostname e.g. `app.bastille.chancey.dev`
- `{{ SERVICE_PORT }}` - Service port number
- `{% if ENABLE_VALUES %}` - Enable values.yaml ConfigMap generation
- `{% if ENABLE_HTTPROUTE %}` - Include HTTPRoute
