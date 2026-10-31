#!/usr/bin/env python3
"""exercise ci selection and registry failure boundaries without network access."""

import contextlib
import importlib.util
import io
import json
import os
import shutil
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
rendered = load("rendered-diff")


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


class RenderedDiff(unittest.TestCase):
    def document(self, image="example.com/app:old", **metadata):
        return {"apiVersion": "apps/v1", "kind": "Deployment",
                "metadata": {"name": "app", "namespace": "media", **metadata},
                "spec": {"template": {"spec": {"containers": [{"name": "app", "image": image}]}}}}

    def test_resource_pairing_and_image_change(self):
        source = {"apiVersion": "source.toolkit.fluxcd.io/v1", "kind": "OCIRepository",
                  "metadata": {"name": "app-template", "namespace": "media"}, "spec": {"ref": {"tag": "5.3.0"}}}
        diff = rendered.rendered_diff([source, self.document()], [self.document("example.com/app:new"), source])
        self.assertIn('-            "image": "example.com/app:old"', diff)
        self.assertIn('+            "image": "example.com/app:new"', diff)
        self.assertNotIn("OCIRepository", diff)

    def test_chart_noise_and_secret_are_excluded(self):
        before = self.document(labels={"helm.sh/chart": "chart-1"})
        after = self.document(labels={"helm.sh/chart": "chart-2"}, annotations={"checksum/config": "new"})
        secret = {"kind": "Secret", "data": {"password": "private"}}
        self.assertEqual(rendered.rendered_diff([before, secret], [after]), "")

    def test_binary_payload_keeps_only_content_summary(self):
        document = {"apiVersion": "v1", "kind": "ConfigMap", "metadata": {"name": "crds"},
                    "binaryData": {"bundle": "YWFh" * 1000}}
        diff = rendered.rendered_diff([], [document])
        self.assertIn("3000 bytes sha256:", diff)
        self.assertNotIn(document["binaryData"]["bundle"], diff)
        self.assertEqual(document["binaryData"]["bundle"], "YWFh" * 1000)
        changed = {**document, "binaryData": {"bundle": "YmJi" * 1000}}
        self.assertIn("sha256:", rendered.rendered_diff([document], [changed]))
        self.assertNotEqual(rendered.binary_summary("invalid!"), rendered.binary_summary("invalid?"))
        self.assertEqual(rendered.binary_summary("YWFh\n"), rendered.binary_summary("YWFh"))

    def test_null_chart_metadata(self):
        self.assertEqual(rendered.rendered_diff([self.document(labels=None)], [self.document()]), "")

    def test_additions_deletions_and_duplicates(self):
        self.assertIn("+", rendered.rendered_diff([], [self.document()]))
        self.assertIn("-", rendered.rendered_diff([self.document()], []))
        with self.assertRaisesRegex(ValueError, "duplicate resource"):
            rendered.resources([self.document(), self.document()])

    def test_new_images_only(self):
        self.assertEqual(rendered.new_images(["example.com/app:old"], ["example.com/app:new", "example.com/app:new"]),
                         ["example.com/app:new"])
        with self.assertRaises(ValueError):
            rendered.new_images([], {"image": "example.com/app:new"})


class SharedChartRendering(unittest.TestCase):
    @unittest.skipUnless(shutil.which("flate") and shutil.which("yq"), "requires the pinned development shell")
    def test_full_revision_diff_keeps_unchanged_shared_source(self):
        scripts = Path(__file__).resolve().parent
        with tempfile.TemporaryDirectory(prefix="ci-shared-chart-") as directory:
            root = Path(directory)

            def write(path, value):
                target = root / path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(json.dumps(value), encoding="utf-8")

            def git(*arguments):
                return subprocess.check_output([
                    "git", "-c", "user.name=ci", "-c", "user.email=ci@example.invalid", *arguments,
                ], cwd=root, text=True).strip()

            def kustomization(name):
                return {"apiVersion": "kustomize.toolkit.fluxcd.io/v1", "kind": "Kustomization",
                        "metadata": {"name": name, "namespace": "media"},
                        "spec": {"interval": "1h", "targetNamespace": "media",
                                 "path": f"./flux/bastille/apps/media/{name}/app",
                                 "sourceRef": {"kind": "GitRepository", "name": "flux-system", "namespace": "flux-system"}}}

            for name, manifests in (("shared", ["source.yaml", "chart.yaml"]), ("app", ["release.yaml"])):
                prefix = f"flux/bastille/apps/media/{name}"
                write(f"{prefix}/ks.yaml", kustomization(name))
                write(f"{prefix}/app/kustomization.yaml", {
                    "apiVersion": "kustomize.config.k8s.io/v1beta1", "kind": "Kustomization", "resources": manifests,
                })
            write("flux/bastille/apps/media/shared/app/source.yaml", {
                "apiVersion": "source.toolkit.fluxcd.io/v1", "kind": "GitRepository",
                "metadata": {"name": "shared-chart"}, "spec": {
                    "interval": "1h", "url": "https://example.invalid/shared-chart", "ref": {"branch": "main"},
                },
            })
            write("flux/bastille/apps/media/shared/app/chart.yaml", {
                "apiVersion": "source.toolkit.fluxcd.io/v1", "kind": "HelmChart",
                "metadata": {"name": "shared-chart"}, "spec": {"interval": "1h", "chart": "./charts/app",
                "sourceRef": {"kind": "GitRepository", "name": "shared-chart"}},
            })
            release_path = "flux/bastille/apps/media/app/app/release.yaml"
            release = {"apiVersion": "helm.toolkit.fluxcd.io/v2", "kind": "HelmRelease",
                       "metadata": {"name": "app"}, "spec": {"interval": "1h",
                       "chartRef": {"kind": "HelmChart", "name": "shared-chart"},
                       "values": {"image": "example.com/app:v1"}}}
            write(release_path, release)
            write("charts/app/Chart.yaml", {"apiVersion": "v2", "name": "app", "version": "1.0.0"})
            template = root / "charts/app/templates/pod.yaml"
            template.parent.mkdir(parents=True)
            template.write_text("apiVersion: v1\nkind: Pod\nmetadata:\n  name: app\nspec:\n  containers:\n    - name: app\n      image: {{ .Values.image }}\n", encoding="utf-8")
            (root / "tools/scripts").mkdir(parents=True)
            for name in ("ci-diff.sh", "flate.sh", "rendered-diff.py"):
                shutil.copy2(scripts / name, root / "tools/scripts" / name)
            shutil.copy2(scripts.parent / "flate.yaml", root / "tools/flate.yaml")
            # registry behavior is covered separately; this fixture never uses the network.
            (root / "tools/scripts/check-images.py").write_text("", encoding="utf-8")
            git("init", "-qb", "main")
            git("remote", "add", "origin", "https://example.invalid/shared-chart")
            git("add", ".")
            git("commit", "-qm", "test: shared chart baseline")
            base = git("rev-parse", "HEAD")
            release["spec"]["values"]["image"] = "example.com/app:v2"
            write(release_path, release)
            git("add", release_path)
            git("commit", "-qm", "test: update consumer image")
            output = root / "artifacts"
            result = subprocess.run(["bash", "tools/scripts/ci-diff.sh"], cwd=root, text=True, capture_output=True,
                                    env={**os.environ, "BASE_SHA": base, "HEAD_SHA": git("rev-parse", "HEAD"),
                                         "DIFF_DIR": str(output), "KUBECONFIG": "/dev/null", "FLATE_RESTRICT_EGRESS": "true"})
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            diff = (output / "flux.diff").read_text(encoding="utf-8")
            self.assertIn("Pod/media/app", diff)
            self.assertIn('"image": "example.com/app:v2"', diff)
            self.assertNotIn("GitRepository", diff)
            self.assertEqual(json.loads((output / "images.json").read_text()), ["example.com/app:v2"])


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
