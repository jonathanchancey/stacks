"""Bootstrap must never leak a credential or install failed CLI output."""
import base64
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[2] / "tools/scripts/install-kanidm-reconciler-token.py"
spec = importlib.util.spec_from_file_location("bootstrap", SOURCE)
b = importlib.util.module_from_spec(spec)
spec.loader.exec_module(b)
RESULT = {"status": "success", "action": "api-token generate", "dest_user": "kanidm-client-reconciler", "result": "synthetic-secret"}


class BootstrapTests(unittest.TestCase):
    def test_token_only_reaches_kubernetes_stdin(self):
        with patch.object(b.subprocess, "run") as run, patch("sys.stdout", new_callable=io.StringIO) as output:
            self.assertEqual(b.install(io.StringIO(json.dumps(RESULT))), 0)
            args, kwargs = run.call_args
            self.assertNotIn("synthetic-secret", str(args))
            secret = json.loads(kwargs["input"])
            self.assertEqual(base64.b64decode(secret["data"]["token"]), b"synthetic-secret")
            self.assertEqual(secret["metadata"]["namespace"], "auth-system")
            self.assertEqual(args[0][1:3], ["--context", "bastille"])
            self.assertNotIn("synthetic-secret", output.getvalue())

    def test_failed_or_wrong_account_output_never_runs_kubectl(self):
        for value in ["", "not json", "null", "[]", json.dumps({**RESULT, "status": "failure"}),
                      json.dumps({**RESULT, "dest_user": "different-account"}),
                      json.dumps({**RESULT, "result": ""}), json.dumps({**RESULT, "result": "bad token"})]:
            with self.subTest(value=value), patch.object(b.subprocess, "run") as run, patch("sys.stderr", new_callable=io.StringIO):
                self.assertEqual(b.install(io.StringIO(value)), 1)
                run.assert_not_called()

    def test_kubernetes_errors_never_print_submitted_values(self):
        error = subprocess.CalledProcessError(1, "kubectl", output="synthetic-secret", stderr="synthetic-secret")
        with patch.object(b.subprocess, "run", side_effect=error), patch("sys.stderr", new_callable=io.StringIO) as output:
            self.assertEqual(b.install(io.StringIO(json.dumps(RESULT))), 1)
            self.assertNotIn("synthetic-secret", output.getvalue())


if __name__ == "__main__":
    unittest.main()
