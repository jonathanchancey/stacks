# development environment

the [flake](../flake.nix) defines the deployment and history-analysis tools.
`flake.lock` pins nixpkgs; the default development shell and `toolchain` package
contain deployment tools. the opt-in `theseus` shell adds history analysis and
plotting. enable nix's `nix-command` and `flakes` features.

## commands

enter an interactive shell with `nix develop`, or run commands explicitly:

```bash
nix develop --command task test-all CLUSTER=bastille NAMESPACE=default
nix develop --command flux-local get ks --path flux/bastille --all-namespaces
nix flake check --no-update-lock-file
```

the cluster and namespace arguments allow offline validation without a
kubeconfig. omit them to use the current kubectl context for tasks.

flux-local includes its python dependencies and external commands through nix;
no virtualenv or pip installation is needed. update its version and source hash in
[`tools/nix/flux-local.nix`](../tools/nix/flux-local.nix) alongside the image tags
in [flux ci](../.github/workflows/flux-diff.yaml); flake checks enforce agreement.
update `flake.lock` to change the nixpkgs-provided dependencies.

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
in the [emudhra advisory](https://emudhra.we-have-a-problem.com/). flux-local's
certifi dependency uses the same bundle, including its environment-free fallback.

`replaceDependencies` replaces certifi in the built flux-local dependency tree
without recompiling its python dependents. keep the replacement's package name,
version, and layout identical to upstream certifi. this uses import-from-derivation:
evaluating flux-local can fetch or build packages and requires a native builder.

the development shell and `toolchain` executables set
`NIX_SSL_CERT_FILE`, `SSL_CERT_FILE`, `SSL_CERT_DIR`, and `REQUESTS_CA_BUNDLE`
to the patched nix stores, replacing inherited host paths even for absolute
profile invocations. legitimate chains under removed roots are also distrusted;
explicit application-specific ca settings, such as kubeconfig ca data, still apply.
host tools and independently created virtualenvs are outside this policy.

after a nixpkgs update, keep the source override until `nix flake check` rejects all
twelve advisory chains without it; then remove the certifi replacement too.
the trust check fixes verification time at disclosure so expired fixtures cannot
hide renewed trust. also check legitimate
https with python and the affected clients before removing the override.
go clients on macos use native system trust; keep macos security updates current.

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
