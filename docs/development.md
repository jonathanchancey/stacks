# development environment

the [flake](../flake.nix) defines the deployment and history-analysis tools.
`flake.lock` pins nixpkgs; the default development shell and `toolchain` package
use the same tool list. enable nix's `nix-command` and `flakes` features.

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

## certificate trust

the flake's `cacert` package pins the patched nss certificate source identified
in the [emudhra advisory](https://emudhra.we-have-a-problem.com/). flux-local's
certifi dependency uses the same bundle, including its environment-free fallback.
the development shell and `toolchain` executables set
`NIX_SSL_CERT_FILE`, `SSL_CERT_FILE`, `SSL_CERT_DIR`, and `REQUESTS_CA_BUNDLE`
to the patched nix stores, replacing inherited host paths even for absolute
profile invocations. legitimate chains under removed roots are also distrusted;
explicit application-specific ca settings, such as kubeconfig ca data, still apply.
host tools and independently created virtualenvs are outside this policy.

after a nixpkgs update, keep the source override until `nix flake check` rejects all
twelve advisory chains without it. the trust check fixes verification time at
disclosure so expired fixtures cannot hide renewed trust. also check legitimate
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
