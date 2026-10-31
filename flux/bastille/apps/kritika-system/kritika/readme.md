# kritika

[kritika](https://kritika.home-operations.com/) reviews pull requests through a github app. configuration lives in [the helmrelease](app/helmrelease.yaml); [the flux kustomizations](ks.yaml) reconcile the database separately from the app.

## credentials and startup

the helmrelease references github app credentials and an openrouter key from `app/secrets.sops.yaml`. decrypt it with sops on a trusted machine to update them; never commit plaintext credentials.

1. register a github app using [upstream's permissions and events](https://kritika.home-operations.com/setup/#register-the-github-app). use `https://kritika-webhook.chancey.dev/hooks/github` for webhooks. its public route accepts only `POST /hooks/github`; the dashboard at `https://kritika.chancey.dev` uses internal `network/edge`.
2. set `KRITIKA_GITHUB_CLIENT_ID`, `KRITIKA_GITHUB_PRIVATE_KEY`, and `KRITIKA_OPENROUTER_API_KEY` in the encrypted app secret. set the github webhook secret to its `KRITIKA_GITHUB_WEBHOOK_SECRET` value. keep the helmrelease's `config.apps.github.accounts` aligned with the installation accounts.
3. install the app on the intended repositories, then enable them on the account's repositories page in kritika. check database extensions and roles, bucket binding, and helmrelease readiness before testing a review.

indexing uses voyage embeddings through openrouter. model, dimensions, prompts, and similarity threshold live under `config.embedding` in the helmrelease. after changing the model, dimensions, or document prompt, reindex enabled repositories from the queue page. see [upstream's embedding configuration](https://kritika.home-operations.com/models/#the-embedder).

rook creates the cache credentials in the `kritika-cache` secret. the bucket has a three-day expiry and a size cap; it is disposable cache, not a database backup.

## chatgpt sign-in

reviews use a chatgpt plus or pro plan. indexing uses separately billed openrouter embeddings; chatgpt cannot supply embeddings. automatic pr approval is disabled.

run these commands on the machine with your browser, using the same pod in both terminals:

```sh
kubectl -n kritika-system get pods -l app.kubernetes.io/name=kritika
kubectl -n kritika-system port-forward pod/POD_NAME 1455:1455 --address 127.0.0.1
```

```sh
kubectl -n kritika-system exec -it POD_NAME -- /kritika chatgpt login chatgpt
```

open the printed url and stop the forward after confirmation. tokens persist in postgres and refresh automatically; repeat sign-in if revoked. reviews share your plan's allowance; openrouter calls are billed separately. see [upstream's plan documentation](https://kritika.home-operations.com/models/#chatgpt-plans).

## database and isolation

the dedicated cnpg cluster uses postgres 18 and vectorchord, with separate owner, application, and runner credentials in `database/secrets.sops.yaml`. preserve those credentials and the database together. keep the vectorchord image version and `database/database.yaml` extension version aligned. image volumes require a compatible kubernetes/container runtime; see [upstream's database prerequisites](https://kritika.home-operations.com/database/).

two postgres instances use separate ceph volumes. replication is not a backup: no backup schedule is configured for this cluster. establish backups before relying on its review history and saved chatgpt session. the cluster is protected from flux pruning; removing its manifests does not delete it.

the chart's admission and network policies remain enabled. runners reach providers through kritika's gateway; only service pods get the extra ceph rgw egress rule. no `gvisor` runtime is assumed: add `runner.podTemplate.spec.runtimeClassName` only after installing and verifying a sandboxed runtime. fork reviews are excluded.
