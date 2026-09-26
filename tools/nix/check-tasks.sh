#!/usr/bin/env bash
set -euo pipefail

export MPLCONFIGDIR="$TMPDIR/matplotlib-tasks"
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null

# Included taskfiles must not redirect the existing Flux environment.
task --dry flux:test CLUSTER=test NAMESPACE=default > flux-command.txt 2>&1
grep -F "$PWD/tools/.venv/bin/flux-local" flux-command.txt

git -c init.defaultBranch=main init --quiet
git config user.name 'Test Fixture'
git config user.email test@example.invalid
mkdir -p fixture/nested
printf 'print("fixture")\n' > fixture/example.py
printf 'kind: ConfigMap\nmetadata:\n  name: fixture\n' > fixture/nested/example.yaml
git add fixture
GIT_AUTHOR_DATE=2024-01-01T00:00:00Z GIT_COMMITTER_DATE=2024-01-01T00:00:00Z \
  git -c commit.gpgsign=false -c core.hooksPath=/dev/null commit --quiet -m 'test: add history fixture'

# Run from a subdirectory; analysis-only arguments must not reach the plotter.
(
  cd fixture/nested
  task theseus:all CLUSTER=test NAMESPACE=default OUTDIR=output/all -- --procs 1 --quiet
)
test -s output/all/stack_plot.png

task theseus:analyze CLUSTER=test NAMESPACE=default OUTDIR=output/default -- --procs 1 --quiet
task theseus:analyze-extensions CLUSTER=test NAMESPACE=default OUTDIR=output/extensions -- --procs 1 --quiet

# YAML must be included by the explicit extension task, unlike upstream defaults.
python - <<'PY'
import json
from pathlib import Path

def total(name):
    data = json.loads(Path(f"output/{name}/cohorts.json").read_text())
    return sum(cohort[-1] for cohort in data["y"])

assert total("all") == total("extensions") > total("default") > 0
PY
