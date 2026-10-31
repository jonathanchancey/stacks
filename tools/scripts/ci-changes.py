#!/usr/bin/env python3
"""select ci jobs without filtering out the required workflow itself."""

import os
import re
import subprocess


def select_jobs(paths):
    tooling = any(
        path in {"flake.nix", "flake.lock", "taskfile.yaml"}
        or path.startswith(("tools/", ".agents/", ".github/workflows/"))
        for path in paths
    )
    workflows = tooling or any(path == ".github/zizmor.yaml" for path in paths)
    render = tooling or any(path.startswith("flux/") for path in paths)
    return {"tooling": tooling, "workflows": workflows, "render": render}


def main():
    base, head = os.environ["BASE_SHA"], os.environ["HEAD_SHA"]
    if not all(re.fullmatch(r"[0-9a-f]{40}", ref) for ref in (base, head)):
        raise ValueError("base and head must be full commit shas")
    if os.environ["EVENT_NAME"] == "pull_request":
        base = subprocess.check_output(["git", "merge-base", base, head], text=True).strip()
    if base == "0" * 40:
        command = ["git", "ls-tree", "-r", "--name-only", "-z", head]
    else:
        command = ["git", "diff", "--no-renames", "--name-only", "-z", base, head, "--"]
    paths = subprocess.check_output(command).decode("utf-8", "surrogateescape").split("\0")
    jobs = select_jobs(paths)
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
        for name, enabled in jobs.items():
            print(f"{name}={str(enabled).lower()}", file=output)
    print(", ".join(f"{name}={str(enabled).lower()}" for name, enabled in jobs.items()))


if __name__ == "__main__":
    main()
