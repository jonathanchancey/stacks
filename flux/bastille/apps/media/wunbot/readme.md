# wunbot

store `DISCORD_BOT_TOKEN` at `kv/media/wunbot` in openbao. the [sync job](app/sync.yaml) logs in as `wunbot-secret-sync` and patches the named kubernetes secret. wunbot reads the cached value at startup; reloader picks up changes. if openbao is unavailable the last successful value stays available. on a fresh cluster the first successful sync supplies the token.

## commissioning an initialized store

1. [log in as an openbao operator](../../openbao/readme.md). apply the `wunbot-policy` and `wunbot-role` requests from [server.hcl](../../openbao/server/app/server.hcl) to install the acl and its service account binding.
2. seed the current token through standard input at `kv/media/wunbot` before reconciling the sync job. keep the token out of command arguments and output.
3. run a uniquely named one-off job from `cronjob/wunbot-secret-sync` in `media`. verify it completes, the cached token matches the source, and wunbot is ready before retiring the old secret definition. remove the one-off job.
