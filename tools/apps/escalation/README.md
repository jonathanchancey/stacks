# escalation

an experimental, standalone broker for human-approved, time-limited kubernetes
access. requests live in namespaced `AccessRequest` objects; approved grants use
dedicated service accounts and bindings. this is a prototype, not a production
security boundary or a signed upstream release.

## build and check

from this directory:

```sh
go test -race ./...
go vet ./...
go build .
docker build -t escalation:local .
helm lint chart
helm template escalation chart -n escalation --include-crds \
  --set enabled=true --set existingSecret=escalation-oidc
```

`bash test/e2e.sh` requires kind, docker, kubectl and helm. it creates and deletes
its own kubernetes 1.33 cluster, checking the chart's rbac/admission policies,
immutable requests, token issuance and revocation. add
`ESCALATION_TEST_WAIT_EXPIRY=1` to wait about twelve minutes and check that
kubernetes rejects the token while the broker is offline and grant objects remain.
the workflow runs the fast checks and disposable-cluster test on pull requests.
after both jobs pass on a push to `main`, it publishes
`ghcr.io/jonathanchancey/escalation:sha-<full-commit>` using `GITHUB_TOKEN`.
the image carries source and revision labels; the job summary records its digest
for deployment pinning. the package must be public for anonymous cluster pulls.
publishing does not deploy the image. manual runs can enable the expiry check
and `govulncheck` without publishing.

## configure and install

the tested baseline is kubernetes 1.33 with enforcing `ValidatingAdmissionPolicy`
support. the chart is disabled by default; even an explicit install must set
`enabled=true`. helm installs files in `crds/` independently of that flag: use
`--skip-crds` if only inspecting a disabled installation. helm does not upgrade
or remove the crd automatically. after reviewing schema compatibility with
existing requests, apply crd upgrades explicitly with
`kubectl apply -f chart/crds/accessrequests.yaml` before upgrading the release.

start with [chart/values.yaml](chart/values.yaml). save reviewed overrides outside
the checkout; do not put credentials into values. create the server namespace,
the separate grant namespace, and all target namespaces before installation.
create an existing secret in the server namespace with key `client-secret`;
the chart mounts it at `/run/oidc/client-secret` and never generates a secret.

set `config.namespace` to the helm release namespace, `config.grantNamespace`
to a separate dedicated namespace, and `image.repository`/`image.tag` to your
own built image. configure trusted workload issuers and human oidc settings.
review every profile's requester and approver restrictions, role, namespace
allowlist, and duration. referenced roles must already exist; the sample uses an
operator-created, reviewed `Role` named `escalation-observe` in `default`.
aggregated cluster roles such as `view` are rejected by the server. use integer
go durations such as `30m` or `1h30m`.
the approved duration includes a safety budget of 60 seconds for kubernetes jwt
validation leeway plus `clockSkewSeconds` (30 by default). durations must fit that
budget, the 600-second token minimum and one additional second; late pickup is
rejected rather than extending the deadline. synchronized clocks are required.

set `config.baseURL` to the externally served https origin. provide your own
tls ingress or reverse proxy; the chart exposes only a cluster-internal service
on port 8080. keep `config.listen` on that port. set `config.kubeServer` to an
api address reachable by clients receiving credentials, not merely a pod-only
address. `config.kubeCAFile` defaults to the pod's api ca; optional
`config.kubeTLSName` controls tls server name verification. another ca requires
an explicitly reviewed additional mount; the minimal chart does not add one.

```sh
helm upgrade --install escalation ./chart -n escalation \
  -f /path/to/reviewed-values.yaml --set enabled=true
```

the server receives `--config /etc/escalation/config.yaml`. `/readyz` and `/healthz`
drive probes; `/metrics` exposes reconciliation errors and overdue cleanup.
expose only the approval and api routes publicly, not metrics or probes.

## use

```sh
escalation request --url https://access.example.org --token-file /run/requester.jwt \
  --profile observe-v1 --namespace default --duration 30m \
  --reason 'inspect storage' --idempotency-key unique-job-identifier
escalation status --url https://access.example.org --token-file /run/requester.jwt --id request-...
escalation credentials --url https://access.example.org --token-file /run/requester.jwt \
  --id request-... --output /tmp/grant.kubeconfig
kubectl --kubeconfig /tmp/grant.kubeconfig get pods -n default
escalation revoke --url https://access.example.org --token-file /run/requester.jwt --id request-...
```

`--token-file -` reads from stdin. keep token files private. creation returns an
`approvalURL`: open it on a phone, sign in with the configured oidc provider, and
review the request before approving. login returns to the authorized request list.
sessions are memory-only and expire at id-token expiry or one hour, whichever is
sooner. workload tokens cannot approve, and same-identity self-approval is denied.

credentials go only to a new mode-0600 file, never stdout or the default kubeconfig.
use `--help` after each subcommand for flags. the json api is:

| route | contract |
| --- | --- |
| `GET /v1/profiles` | eligible profiles |
| `POST /v1/requests` | `{profile, namespace, duration, reason}` with `Idempotency-Key` |
| `GET /v1/requests` | authorized items and opaque `continue` cursor; pass it as a query parameter |
| `GET /v1/requests/{id}` | request, decision and enforcement status; never credentials |
| `POST /v1/requests/{id}/decision` | browser session, csrf token, `{version, scopeHash, decision}`; decision is `approve` or `deny` |
| `POST /v1/requests/{id}/credentials` | original requester bearer token only; no input overrides |
| `POST /v1/requests/{id}/revoke` | original requester or eligible human approver |

api callers use bearer authentication; human writes require `X-CSRF-Token` or the
embedded form token. retry creation with the same idempotency key and body. after
`409`, reload state rather than repeating a stale decision. credential retries can
mint another token for the same account, never extend the original deadline.
authenticated requests are limited to 60 per identity per minute with at most
1024 active rate-limit entries. completed records are removed seven days after
creation; preserve protected structured audit logs externally when needed longer.

## security and recovery

one nonroot replica uses `Recreate`, a read-only root filesystem, dropped
capabilities, and bounded memory. the server account can maintain requests only
in its namespace, create/delete grant accounts and issue tokens only in the
grant namespace, and create/delete bindings only in configured target namespaces.
role lookup and `bind` permissions name only configured roles. cluster bindings
require both `clusterGrants=true` and a cluster profile. no role definitions,
secret permissions, `escalate` permission, or automatic cluster-admin grants are
created. administrators must still review the privileges of referenced roles.
the server rejects direct credential/rbac persistence paths and common workload
creation/exec paths. these checks are not a proof that arbitrary custom-resource
permissions are safe: controllers, writable workloads and other credentials can
provide indirect privilege. the broker, approver provider and cluster
administrators are trusted; a compromised broker can use its allowlisted roles.

the admission policies restrict writes by this server identity: deterministic
`grant-<request-uid>` names and `escalation.stacks.dev/request` ownership labels,
disabled service account token automount, exact grant subjects and allowlisted
role references, and bounded, single-audience, unbound token requests. deletes
check `oldObject` as well. the policies cannot verify that a label refers to a real
approved request; application approval checks remain essential. do not reuse the
server account for other workloads or share the grant namespace.

to stop issuance, scale the deployment to zero. inspect outstanding requests and
owned grant bindings/accounts before removing only the affected grant objects.
already issued tokens require revocation of their service account or expiration;
do not assume uninstalling the server revokes them. preserve requests for audit
and investigate missing cleanup after a crash. removing profiles may prevent the
server from deleting older grants under the new policy; an administrator must
review and remove those explicitly before changing the allowlist. finish/revoke
outstanding grants before removing scopes or changing the grant namespace.
expiry limits new authenticated requests; existing streams and previous changes
can outlast access. early revocation is eventual, not instantaneous. configure
ingress and kubernetes audit logging not to record credential response bodies.

helm uninstall does not collect application-created grants or remove the crd.
back up request records before any explicit crd deletion. the prototype has
no high availability, ingress, network policy, external audit retention, or
automated disaster recovery. test admission denial and cleanup on a disposable
cluster before exposing it to real users. maintain policy/rbac templates alongside
profile changes. the crd lives in `chart/crds/accessrequests.yaml`; keep its
bounded structural spec schema in sync with `Spec`, `Profile`, and `Identity`
in the go package. unknown spec fields are pruned and the complete stored spec
is immutable. review schema limits before adding larger profiles or roles.
