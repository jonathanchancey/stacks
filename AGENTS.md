# agents.md

for commits, use lowercase conventional commits matching git history
for branch names, use conventional branch v1.0.0 like fix, chore, and feat/add-login-page
use lowercase in all prose and artifacts, preserve case-sensitive literals
do not use emoji in responses or code
do not edit the main project readme without explicit consent
you may edit readme files in subdirectories to prevent drift

## documentation

- write for someone learning how the feature works in this repo and maintaining it later, including future agents. explain where to look and how to make changes. avoid writing in the context of the current task
- a detailed first draft is fine, always make a second pass to reduce it to the minimum needed to use or maintain the feature later
- keep essential setup, usage, recovery steps, and caveats. link to configuration instead of duplicating it
- omit change rationale, implementation history, rollout logs, and validation results
- this is a public repo, keep private operational details such as database sizes/counts and internal inventories out of docs and pr descriptions

## common development commands

### taskfile

the repository uses [task](https://taskfile.dev/) as the primary task runner

when creating/editing a task, do not embed long scripts and keep things taskfile-native

```bash
# kubeconform
task conform

# full test suite
task test-all
```

## implementation notes

- use `https://k8s-schemas.home-operations.com` for kubernetes and kustomize yaml schemas. upstream schemas remain appropriate for unpublished api versions, tool configuration, and chart values
- always use ocirepository over helmrepository

## file patterns

- `flux/<cluster>/apps/<namespace>/app` pattern within flux
- `*.sops.yaml`: encrypted secrets
- `ks.yaml`: flux kustomizations
- `helmrelease.yaml`: flux helmrelease definitions
- `kustomization.yaml`: vanilla kustomizations

## in closing

this repository is public, and the user takes great pride in it. treat every change as public-facing work: keep it thoughtful, polished, minimal, and consistent with the repo's established style.
