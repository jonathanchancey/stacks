#!/usr/bin/env python3
"""exercise ci selection and registry failure boundaries without network access."""

import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True


def load(name):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


changes = load("ci-changes")
images = load("check-images")


class ChangeSelection(unittest.TestCase):
    def test_docs_only(self):
        self.assertEqual(changes.select_jobs(["docs/development.md"]), {
            "tooling": False, "workflows": False, "render": False,
        })

    def test_shared_manifest(self):
        self.assertTrue(changes.select_jobs(["flux/bastille/components/example/kustomization.yaml"])["render"])

    def test_tooling_and_workflows(self):
        for path in ("flake.lock", "tools/scripts/flate.sh", ".github/workflows/ci.yaml"):
            self.assertTrue(all(changes.select_jobs([path]).values()))

    def test_missing_commit_fails(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, {
            "BASE_SHA": "0" * 39 + "1", "HEAD_SHA": "0" * 39 + "2",
            "EVENT_NAME": "pull_request",
            "GITHUB_OUTPUT": str(Path(directory, "outputs")),
        }):
            with self.assertRaises(Exception):
                changes.main()
            self.assertFalse(Path(directory, "outputs").exists())

    def test_diverged_docs_pull_request(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)

            def git(*arguments):
                return subprocess.check_output([
                    "git", "-c", "user.name=ci", "-c", "user.email=ci@example.invalid", *arguments,
                ], cwd=root, text=True).strip()

            def commit(path, content):
                file = root / path
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_text(content, encoding="utf-8")
                git("add", path)
                git("commit", "-qm", "test: fixture")
                return git("rev-parse", "HEAD")

            git("init", "-qb", "main")
            commit("docs/example.md", "baseline\n")
            git("checkout", "-qb", "docs")
            head = commit("docs/example.md", "docs change\n")
            git("checkout", "-q", "main")
            base = commit("flux/bastille/example.yaml", "upstream manifest\n")
            output = root / "outputs"
            original_cwd = Path.cwd()
            try:
                os.chdir(root)
                for event, render in (("pull_request", "false"), ("push", "true")):
                    with patch.dict(os.environ, {
                        "BASE_SHA": base, "HEAD_SHA": head, "EVENT_NAME": event,
                        "GITHUB_OUTPUT": str(output),
                    }), contextlib.redirect_stdout(io.StringIO()):
                        changes.main()
                    self.assertEqual(output.read_text(), f"tooling=false\nworkflows=false\nrender={render}\n")
                    output.unlink()
            finally:
                os.chdir(original_cwd)


class ImageChecks(unittest.TestCase):
    def setUp(self):
        self.architecture = "amd64"

        def crane(*arguments, env=None):
            self.assertEqual(arguments[0], "crane")
            self.assertEqual(Path(env["DOCKER_CONFIG"], "config.json").read_text(), "{}")
            if "missing" in arguments[-1]:
                raise subprocess.CalledProcessError(1, arguments)
            if arguments[1] == "digest":
                return "sha256:" + "a" * 64
            self.assertEqual(arguments[1:4], ("config", "--platform", "linux/amd64"))
            self.assertTrue(arguments[-1].endswith("@sha256:" + "a" * 64))
            return json.dumps({"os": "linux", "architecture": self.architecture})

        mocked_command = patch.object(images, "command", side_effect=crane)
        mocked_command.start()
        self.addCleanup(mocked_command.stop)
        quiet = contextlib.redirect_stdout(io.StringIO())
        quiet.__enter__()
        self.addCleanup(quiet.__exit__, None, None, None)

    def test_empty(self):
        images.check_images([], ["linux/amd64"])

    def test_available(self):
        images.check_images(["example.com/app:latest"], ["linux/amd64"])

    def test_missing_tag(self):
        with self.assertRaisesRegex(RuntimeError, "image validation failed"):
            images.check_images(["example.com/app:missing"], ["linux/amd64"])

    def test_wrong_architecture(self):
        self.architecture = "arm64"
        with self.assertRaisesRegex(RuntimeError, "image config declares"):
            images.check_images(["example.com/app:latest"], ["linux/amd64"])

    def test_invalid_input(self):
        for invalid in ({"images": []}, ["--help"], ["invalid image"]):
            with self.assertRaises(ValueError):
                images.check_images(invalid, ["linux/amd64"])

    def test_no_platforms(self):
        with self.assertRaises(ValueError):
            images.check_images([], [])


if __name__ == "__main__":
    unittest.main()
