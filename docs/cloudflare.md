# cloudflare

cloudflare is managed by opentofu in `flux/bastille/apps/network/cloudflare/terraform`, reconciled by tofu-controller.
external-dns owns records generated from cluster resources; terraform must not manage those records.

## bootstrap

created by hand once, stored in `flux/bastille/apps/network/cloudflare/app/secrets.sops.yaml`:

| key | source |
| --- | --- |
| `cloudflare_api_token` | cloudflare api token scoped to this account; widen its permissions in place as terraform grows |
| `cloudflare_account_id` | cloudflare dashboard url |
| `bucket` | b2 bucket for state in `us-east-005` |
| `access_key`, `secret_key` | b2 application key restricted to that bucket |
| `state_passphrase` | random, at least 16 characters; encrypts state and plans client-side |

state lives in `s3://<bucket>/bastille/apps/network/cloudflare/terraform.tfstate`, encrypted by opentofu, so a cluster rebuild reuses it.

## break-glass

from `flux/bastille/apps/network/cloudflare/terraform`, with the values above exported:

```sh
export TF_VAR_cloudflare_api_token=... TF_VAR_cloudflare_account_id=... TF_VAR_state_passphrase=...
tofu init -backend-config="bucket=$BUCKET" -backend-config="access_key=$ACCESS_KEY" -backend-config="secret_key=$SECRET_KEY"
tofu plan
```

suspend the `Terraform` object first (`flux suspend` does not cover it; use `kubectl -n network patch terraform cloudflare --type merge -p '{"spec":{"suspend":true}}'`) so both do not apply at once.

## amp

the `amp-stacks` service token is written to `network/cloudflare-amp-stacks`; copy it into amp project secrets with `task amp:sync-access-token`.

set `KUBE_CA_DATA` in amp project environment variables to the base64 cluster ca from your kubeconfig:

```sh
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'
```

`.agents/setup` installs cloudflared; `.agents/resume` writes the orb kubeconfig and ensures the private `bastille-api` service in `.amp/services.yaml` is running.
login shells in this repository select that kubeconfig. `.agents/kube-token` supplies expiring thread-scoped workload identity tokens on demand.
the tunnel checks the cloudflare service token; kubernetes checks the workload identity against the [controlplane patch](../flux/bastille/talos/patches/controlplane.yaml) and grants the `amp:stacks` group read-only access through the built-in `view` role.
this does not grant talos api access or kubernetes secret access.

after changing project credentials, run `amp orb restart-processes` in an existing orb to refresh its environment, then `.agents/resume` if needed.
check `kubectl auth whoami`, `kubectl get pods -A`, and `kubectl auth can-i list secrets -A` (expected: `no`).
for connection failures, inspect `amp orb service logs bastille-api`; never expose this service through a portal or disable kubernetes tls verification.
