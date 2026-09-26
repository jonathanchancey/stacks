#!/usr/bin/env bash
set -euo pipefail

theseus_package=$1
git_command=$2
python_command=$3
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
cd "$test_directory"

export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export MPLBACKEND=Agg MPLCONFIGDIR="$test_directory/matplotlib"

for command in analyze line-plot stack-plot survival-plot; do
    "$theseus_package/bin/git-of-theseus-$command" --help > /dev/null
done

"$git_command" init --quiet --initial-branch=main fixture
"$git_command" -C fixture config user.name 'Theseus test'
"$git_command" -C fixture config user.email 'theseus@example.invalid'
"$git_command" -C fixture config commit.gpgsign false
for year in 2020 2021 2022; do
    printf 'print("%s")\n' "$year" >> fixture/example.py
    "$git_command" -C fixture add example.py
    GIT_AUTHOR_DATE="$year-01-01T12:00:00Z" GIT_COMMITTER_DATE="$year-01-01T12:00:00Z" \
        "$git_command" -C fixture commit --quiet -m 'test: extend fixture'
done

"$theseus_package/bin/git-of-theseus-analyze" fixture \
    --branch main --procs 1 --quiet --outdir results
"$theseus_package/bin/git-of-theseus-stack-plot" results/cohorts.json --outfile stack.png
"$theseus_package/bin/git-of-theseus-line-plot" results/cohorts.json --outfile line.png
"$theseus_package/bin/git-of-theseus-survival-plot" results/survival.json --outfile survival.png

"$python_command" - <<'PY'
import json
from pathlib import Path

cohorts = json.loads(Path("results/cohorts.json").read_text())
assert cohorts["labels"] == [f"Code added in {year}" for year in (2020, 2021, 2022)]
assert cohorts["y"] == [[1, 1, 1], [0, 1, 1], [0, 0, 1]]
assert cohorts["ts"] == [f"{year}-01-01T12:00:00" for year in (2020, 2021, 2022)]
for name in ("stack", "line", "survival"):
    image = Path(f"{name}.png").read_bytes()
    assert image.startswith(b"\x89PNG\r\n\x1a\n"), f"Invalid PNG: {name}"
    assert len(image) > 1024, f"Empty plot: {name}"
PY
