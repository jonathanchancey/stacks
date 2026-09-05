#!/usr/bin/env python3
"""Install Kanidm's JSON token output without printing or writing the token to disk."""
import base64
import json
import subprocess
import sys


def install(stream):
    try:
        result = json.load(stream)
        if (result.get("status") != "success" or result.get("action") != "api-token generate"
                or result.get("dest_user") != "kanidm-client-reconciler"):
            raise ValueError
        token = result["result"]
        if not isinstance(token, str) or not token or any(c.isspace() for c in token):
            raise ValueError
    except (ValueError, KeyError, AttributeError):
        print("Expected successful Kanidm JSON output for the reconciler API token; nothing changed.", file=sys.stderr)
        return 1
    secret = {
        "apiVersion": "v1", "kind": "Secret", "type": "Opaque",
        "metadata": {"name": "kanidm-client-reconciler-token", "namespace": "auth-system"},
        "data": {"token": base64.b64encode(token.encode()).decode()},
    }
    try:
        subprocess.run([
            "kubectl", "--context", "bastille", "apply", "--server-side",
            "--field-manager=kanidm-bootstrap", "-f", "-",
        ], input=json.dumps(secret), text=True, capture_output=True, check=True, timeout=30)
    except (OSError, subprocess.SubprocessError):
        # Kubernetes errors can echo submitted values. Never print their output.
        print("Token installation failed; check bastille access and the auth-system namespace.", file=sys.stderr)
        return 1
    print("Reconciler token installed in bastille/auth-system.")
    return 0


if __name__ == "__main__":
    sys.exit(install(sys.stdin))
