# wunbot

store `DISCORD_BOT_TOKEN` at `kv/media/wunbot` in openbao. the [sync job](app/sync.yaml) logs in as `wunbot-secret-sync` and patches the named kubernetes secret. wunbot reads the cached value at startup; reloader picks up changes. if openbao is unavailable the last successful value stays available. on a fresh cluster the first successful sync supplies the token.

the openbao [bootstrap policy and role](../../openbao/server/app/server.hcl) restrict the job to this path and service account. apply role changes to initialized storage through the operator api.
