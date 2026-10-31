# kritika

[kritika](https://kritika.home-operations.com/) reviews pull requests through a github app. configuration lives in [the helmrelease](app/helmrelease.yaml); [the flux kustomizations](ks.yaml) reconcile the database separately from the app.

## credentials and startup

the app starts with admin login and no github connection. `app/secrets.sops.yaml` contains the admin password and a reserved github webhook secret. decrypt it with sops on a trusted machine to retrieve them; never commit plaintext credentials.

1. register a github app using [upstream's permissions and events](https://kritika.home-operations.com/setup/#register-the-github-app). use `https://kritika-webhook.chancey.dev/hooks/github` for webhooks. its public route accepts only `POST /hooks/github`; the dashboard at `https://kritika.chancey.dev` uses internal `network/edge`. restrict installations to the configured account and repositories that should receive reviews.
2. add `KRITIKA_OPENROUTER_API_KEY`, `KRITIKA_GITHUB_CLIENT_ID`, and `KRITIKA_GITHUB_PRIVATE_KEY` to the encrypted app secret. set the github webhook secret to the existing `KRITIKA_GITHUB_WEBHOOK_SECRET` value.
3. add the following under the helmrelease's `values.config`, merging `providers` and `review` with their existing entries. check database extensions and roles, bucket binding, and helmrelease readiness before testing a review.

```yaml
apps:
  github:
    accounts: [jonathanchancey]
    clientId: { env: KRITIKA_GITHUB_CLIENT_ID }
    privateKey: { env: KRITIKA_GITHUB_PRIVATE_KEY }
    webhookSecret: { env: KRITIKA_GITHUB_WEBHOOK_SECRET }
providers:
  openrouter: { type: openrouter, apiKey: { env: KRITIKA_OPENROUTER_API_KEY } }
review:
  fallback: openrouter/~openai/gpt-sol-latest
confidence:
  model: openrouter/deepseek/deepseek-v4.1-flash-1017
embedding:
  model: openrouter/voyageai/voyage-code-4
  dims: 1024
  documentPrompt: "Represent the document for retrieval: "
  queryPrompt: "Represent the query for retrieving supporting documents: "
  similarFloor: 0.3
```

rook creates the cache credentials in the `kritika-cache` secret. the bucket has a three-day expiry and a size cap; it is disposable cache, not a database backup.

## chatgpt sign-in

reviews use a chatgpt plus or pro plan. the optional openrouter configuration above adds paid fallback, deepseek confidence scoring, and embeddings. chatgpt cannot supply embeddings. automatic pr approval is disabled.

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
