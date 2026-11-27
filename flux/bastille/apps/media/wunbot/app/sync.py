import base64
import json
import re
import ssl
from contextlib import closing
from http.client import HTTPSConnection
from pathlib import Path


def request(connection, method, path, headers, payload=None):
    body = json.dumps(payload).encode() if payload is not None else None
    connection.request(method, path, body=body, headers=headers)
    with connection.getresponse() as response:
        if not 200 <= response.status < 300:
            raise RuntimeError(f"{method} {path} returned {response.status}")
        return json.load(response)


with closing(HTTPSConnection(
    "openbao.openbao.svc", 8200,
    context=ssl.create_default_context(cafile="/openbao/ca.crt"), timeout=15,
)) as bao:
    login = request(
        bao, "POST", "/v1/auth/kubernetes/login",
        {"Content-Type": "application/json"},
        {"role": "wunbot", "jwt": Path("/identity/token").read_text()},
    )
    secret = request(
        bao, "GET", "/v1/kv/data/media/wunbot",
        {"X-Vault-Token": login["auth"]["client_token"]},
    )
token = secret["data"]["data"]["DISCORD_BOT_TOKEN"]
if not isinstance(token, str) or not re.fullmatch(r"[!-~]+", token):
    raise ValueError("invalid discord token")

account = Path("/var/run/secrets/kubernetes.io/serviceaccount")
with closing(HTTPSConnection(
    "kubernetes.default.svc",
    context=ssl.create_default_context(cafile=account / "ca.crt"), timeout=15,
)) as kube:
    request(
        kube, "PATCH", "/api/v1/namespaces/media/secrets/wunbot-secret",
        {
            "Authorization": "Bearer " + (account / "token").read_text(),
            "Content-Type": "application/merge-patch+json",
        },
        {"data": {"DISCORD_BOT_TOKEN": base64.b64encode(token.encode()).decode()}},
    )
