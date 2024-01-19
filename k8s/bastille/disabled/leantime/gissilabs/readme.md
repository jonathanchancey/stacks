# leantime

```yaml
helm repo add gissilabs https://gissilabs.github.io/charts/
helm repo update
helm install leantime gissilabs/leantime -n leantime --create-namespace --values values.yaml
helm upgrade leantime gissilabs/leantime -n leantime --values values.yaml
```



```bash

# Use existing secret for user, user password and root password. Default keys are 'database-root', 'database-user' and 'database-password'.
existingSecret: leantime-database

## Use existing secret for SMTP username and password. Keys are 'smtp-user' and 'smtp-password'
existingSecret: leantime-smtp

```