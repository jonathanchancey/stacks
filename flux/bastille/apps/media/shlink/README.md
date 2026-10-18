# shlink

shlink serves short links and its api at `https://shlink.chancey.dev` through
`envoy-external`. use the cli or [hosted web client](https://app.shlink.io) to
manage links; this deployment does not include a web client.

## credentials and storage

`app/secret.sops.yaml` holds `INITIAL_API_KEY` and `DB_PASSWORD`. retrieve the api
key with sops or from the `shlink-secret` secret in `media`. the initial key is
only imported when no api keys exist; changing the secret does not rotate an
existing key. use `shlink api-key:generate` and `shlink api-key:disable` inside
the container to manage keys.

cloudnative-pg provisions the `shlink` role and database on `bastille-pg` in
[`database/cloudnative-pg/cluster`](../../database/cloudnative-pg/cluster).
keep `DB_PASSWORD` synchronized with `password` in that directory's
`shlink-secret.sops.yaml` when rotating credentials. deleting the database
resource retains the database; recovery uses the cluster's existing backups.

shlink runs migrations on startup. `/etc/shlink/data` is disposable cache;
short links live in postgres. keep a single replica with the recreate strategy
unless shared locking is configured. readiness and gatus use `/rest/health`.

geolocation is disabled without a maxmind license. to enable it, add
`GEOLITE_LICENSE_KEY` to the encrypted app secret and reference it in the
helmrelease's environment.
