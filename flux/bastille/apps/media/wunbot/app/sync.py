import base64
import json
import ssl
from pathlib import Path
from urllib.request import Request, urlopen


def request(url, ca, headers, payload, method="POST"):
    req = Request(url, json.dumps(payload).encode(), headers, method=method)
    with urlopen(req, context=ssl.create_default_context(cafile=ca), timeout=15) as response:
        return json.load(response)


bao = "https://openbao.openbao.svc:8200/v1"
ca = "/openbao/ca.crt"
login = request(
    f"{bao}/auth/kubernetes/login",
    ca,
    {"Content-Type": "application/json"},
    {"role": "wunbot", "jwt": Path("/identity/token").read_text()},
)
read = Request(
    f"{bao}/kv/data/media/wunbot",
    headers={"X-Vault-Token": login["auth"]["client_token"]},
)
with urlopen(read, context=ssl.create_default_context(cafile=ca), timeout=15) as response:
    token = json.load(response)["data"]["data"]["DISCORD_BOT_TOKEN"]
if not isinstance(token, str) or not token.strip():
    raise ValueError("missing discord token")

account = Path("/var/run/secrets/kubernetes.io/serviceaccount")
request(
    "https://kubernetes.default.svc/api/v1/namespaces/media/secrets/wunbot-secret",
    account / "ca.crt",
    {
        "Authorization": "Bearer " + (account / "token").read_text(),
        "Content-Type": "application/merge-patch+json",
    },
    {"data": {"DISCORD_BOT_TOKEN": base64.b64encode(token.encode()).decode()}},
    method="PATCH",
)
