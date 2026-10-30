# development environment

the [flake](../flake.nix) defines the deployment and history-analysis tools.
`flake.lock` pins nixpkgs; the default development shell and `toolchain` package
contain deployment tools. the opt-in `theseus` shell adds history analysis and
plotting. enable nix's `nix-command` and `flakes` features.

## commands

enter an interactive shell with `nix develop`, or run commands explicitly:

```bash
nix develop --command task test-all CLUSTER=bastille NAMESPACE=default
nix develop --command task flux:test-ns CLUSTER=bastille NAMESPACE=automation
nix flake check --no-update-lock-file
```

the cluster and namespace arguments allow offline validation without a
kubeconfig. omit them to use the current kubectl context for tasks.

local tasks and ci use the same [flate package](../tools/nix/flate.nix).
update its version and all platform hashes together; renovate opens reviewed
version updates but does not refresh the hashes. update `flake.lock` for the
nixpkgs-provided tools.

[render settings](../tools/flate.yaml) select the kubernetes version, additional
api capabilities, and image platforms. update these alongside cluster upgrades.
flate renders without cluster access, but still downloads referenced charts and
sources. encrypted values remain placeholders; rendering does not prove live
credentials or health.

flate `0.6.5` can add namespaces to cluster-scoped admission policies in rendered
output. generated manifests are review artifacts; do not apply them.

## continuous integration

[ci](../.github/workflows/ci.yaml) checks the nix toolchain, workflows, flux
rendering, schemas, and changed image platforms. the aggregate `ci` check runs
for every pull request, including those whose expensive jobs are intentionally
skipped. rendering failures and cancelled jobs fail the aggregate check.

`task conform` checks authored manifests; `task conform-rendered` also checks
helm output. rendered checks use chart-provided crd schemas, matching kubernetes
built-in schemas, then home-operations schemas. missing schemas are listed in the
report and are not counted as validated resources.

pull requests compare explicit revisions and attach the complete rendered diff.
the separate comment workflow shows a collapsible inline preview, capped at
12,000 bytes, with the complete artifact linked below. it reads only diff text
without executing pull request code. image checks inspect registries without accessing the cluster.

after the workflow is available on the default branch, import
[the required-check ruleset](../.github/rulesets/ci.json) in the repository's
settings under rulesets. this adds the `ci` requirement alongside existing rules;
committing the file alone does not enable it. keep the required context and the
aggregate job's name identical. failed checks must remain blocking for renovate
updates.

## history analysis

use `nix develop .#theseus` for an interactive shell, or run the
[theseus tasks](../tools/taskfiles/theseus/taskfile.yaml) directly:

```bash
nix develop .#theseus --command task theseus:all CLUSTER=bastille NAMESPACE=default
```

the first invocation builds or downloads the history tools. they are excluded
from orb setup and the default shell, but remain covered by `nix flake check`.
update their package in [`tools/nix/git-of-theseus.nix`](../tools/nix/git-of-theseus.nix).

## certificate trust

the flake's `cacert` package pins the patched nss certificate source identified
in the [emudhra advisory](https://emudhra.we-have-a-problem.com/).

the development shell and `toolchain` executables set
`NIX_SSL_CERT_FILE`, `SSL_CERT_FILE`, `SSL_CERT_DIR`, and `REQUESTS_CA_BUNDLE`
to the patched nix stores, replacing inherited host paths even for absolute
profile invocations. legitimate chains under removed roots are also distrusted;
explicit application-specific ca settings, such as kubeconfig ca data, still apply.
host tools and independently created virtualenvs are outside this policy.

after a nixpkgs update, keep the source override until `nix flake check` rejects all
twelve advisory chains without it.
the trust check fixes verification time at disclosure so expired fixtures cannot
hide renewed trust. also check legitimate
https with python and the affected clients before removing the override.

## orbs

`.agents/setup` installs nix, builds `toolchain` into
`~/.local/state/stacks/orb-tools`, and caches the complete development shell
environment. its repository-scoped login hook is appended after existing
profile configuration, including the orb's environment loading. rerun setup
after changing the flake, lockfile, or nix packages;
open a new login shell afterward, or use `nix develop --command` immediately.

`.agents/resume` uses absolute toolchain paths for python and cloudflared and
checks that the local tunnel listener starts. it does not install packages or
grant cluster access. see [cloudflare](cloudflare.md) for access configuration;
inspect tunnel failures with `amp orb service logs bastille-api`.
