#!/usr/bin/env python3
"""Reconcile explicitly enrolled OAuth clients; never delete clients or rotate keys."""
import base64
import json
import os
from pathlib import Path
import re
import ssl
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlsplit
from urllib.request import HTTPSHandler, HTTPRedirectHandler, Request, build_opener

OWNER = "identity.chancey.dev/client"
UUID_KEY = "identity.chancey.dev/kanidm-uuid"
NAME = re.compile(r"[a-z][a-z0-9_-]{0,62}\Z")
KUBE_NAME = re.compile(r"[a-z0-9](?:[a-z0-9.-]{0,251}[a-z0-9])?\Z")


class ReconcileError(Exception):
    """Messages are safe for logs; never include API response bodies or credentials."""


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class API:
    def __init__(self, url, token_file, ca_file=None):
        parsed = urlsplit(url)
        if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password:
            raise ReconcileError("API must use an authenticated HTTPS origin")
        self.url = url.rstrip("/")
        self.token_file = Path(token_file)
        self.opener = build_opener(NoRedirect(), HTTPSHandler(context=ssl.create_default_context(cafile=ca_file)))

    def call(self, method, path, body=None):
        token = self.token_file.read_text().strip()
        if not token or any(c.isspace() for c in token):
            raise ReconcileError("API token is missing or malformed")
        payload = None if body is None else json.dumps(body).encode()
        content_type = "application/merge-patch+json" if method == "PATCH" and path.startswith("/api/") else "application/json"
        request = Request(self.url + path, data=payload, method=method, headers={
            "Authorization": "Bearer " + token, "Content-Type": content_type, "Accept": "application/json",
        })
        try:
            with self.opener.open(request, timeout=20) as response:
                data = response.read(2 * 1024 * 1024 + 1)
                if len(data) > 2 * 1024 * 1024:
                    raise ReconcileError("API response exceeds the size limit")
                return json.loads(data) if data else None
        except HTTPError as error:
            error.close()
            # A missing GET is safe to inspect; all other failures stop this client.
            if error.code == 404 and method == "GET":
                return None
            raise ReconcileError(f"{method} request failed (HTTP {error.code})") from None
        except (URLError, TimeoutError, ValueError):
            raise ReconcileError(f"{method} request failed (transport or response error)") from None


def require(condition, message):
    if not condition:
        raise ReconcileError(message)


def validate_client(client):
    required = {"name", "displayName", "origin", "redirectURLs", "scopeMap", "secretName"}
    require(isinstance(client, dict) and required <= client.keys(), "Client declaration is incomplete")
    require(not client.keys() - required - {"adoptExisting"}, "Unknown client declaration field")
    require(isinstance(client["name"], str) and NAME.fullmatch(client["name"]), "Invalid client name")
    require(isinstance(client["secretName"], str) and KUBE_NAME.fullmatch(client["secretName"]), "Invalid Secret name")
    require(isinstance(client["displayName"], str) and bool(client["displayName"].strip()), "Display name is required")
    require(type(client.get("adoptExisting", False)) is bool, "adoptExisting must be a boolean")
    redirects = client["redirectURLs"]
    require(isinstance(redirects, list) and redirects and len(set(redirects)) == len(redirects), "Redirects must be a nonempty unique list")
    for url in [client["origin"], *redirects]:
        require(isinstance(url, str), "URLs must be strings")
        parsed = urlsplit(url)
        require(parsed.scheme == "https" and parsed.hostname and not parsed.username and not parsed.password and not parsed.fragment and "*" not in url, "URLs must be explicit HTTPS URLs")
    origin = urlsplit(client["origin"]).netloc
    require(all(urlsplit(url).netloc == origin for url in redirects), "Redirects must use the application origin")
    maps = client["scopeMap"]
    require(isinstance(maps, dict) and bool(maps), "At least one access group is required")
    for group, scopes in maps.items():
        require(NAME.fullmatch(group), "Invalid access group")
        require(isinstance(scopes, list) and "openid" in scopes and len(set(scopes)) == len(scopes), "Each group needs unique scopes including openid")
        require(all(isinstance(s, str) and re.fullmatch(r"[a-zA-Z0-9_:-]+", s) for s in scopes), "Invalid scope")


def parse_scope_maps(values):
    result = {}
    for value in values:
        group, separator, scopes = value.partition(": ")
        require(separator and scopes.startswith("{") and scopes.endswith("}"), "Unrecognized Kanidm scope-map response")
        try:
            items = json.loads("[" + scopes[1:-1] + "]")
        except ValueError:
            raise ReconcileError("Unrecognized Kanidm scope-map response") from None
        require(group and all(isinstance(s, str) for s in items) and group not in result, "Invalid Kanidm scope-map response")
        result[group] = set(items)
    return result


def reconcile_client(kube, kanidm, namespace, config_name):
    require(KUBE_NAME.fullmatch(namespace) and KUBE_NAME.fullmatch(config_name), "Invalid enrollment reference")
    prefix = f"/api/v1/namespaces/{namespace}"
    config = kube.call("GET", f"{prefix}/configmaps/{config_name}")
    require(config is not None, "Enrolled ConfigMap is missing")
    client = json.loads(config["data"]["client.json"])
    validate_client(client)
    name = client["name"]
    owner = f"{namespace}/{config_name}"
    marker = "managed by stacks kanidm-client-reconciler: " + owner
    secret_path = f"{prefix}/secrets/{client['secretName']}"
    secret = kube.call("GET", secret_path)
    require(secret is not None, "Flux must create the destination Secret first")
    annotations = secret["metadata"].get("annotations", {})
    require(annotations.get(OWNER) == owner, "Destination Secret is not enrolled for this client")

    # Validate every group before creating a client or changing access.
    desired = {}
    aliases = {}
    for group, scopes in client["scopeMap"].items():
        entry = kanidm.call("GET", f"/v1/group/{quote(group, safe='')}")
        require(entry is not None, "A declared access group does not exist")
        attrs = entry["attrs"]
        group_uuid = attrs["uuid"][0]
        for alias in [group, group_uuid, *attrs.get("name", []), *attrs.get("spn", [])]:
            aliases[alias] = group_uuid
        desired[group_uuid] = set(scopes)

    path = f"/v1/oauth2/{name}"
    entry = kanidm.call("GET", path)
    owned_attrs = {
        "displayname": [client["displayName"]], "oauth2_rs_origin_landing": [client["origin"]],
        "oauth2_rs_origin": sorted(client["redirectURLs"]), "oauth2_strict_redirect_uri": ["true"],
    }
    if entry is None:
        require(not annotations.get(UUID_KEY), "Previously managed client is missing; refusing automatic replacement")
        kanidm.call("POST", "/v1/oauth2/_basic", {"attrs": {
            "name": [name], "description": [marker], **owned_attrs,
        }})
        entry = kanidm.call("GET", path)
        require(entry is not None, "Created client is not yet readable; retry later")
    attrs = entry["attrs"]
    require("oauth2_resource_server_basic" in attrs.get("class", []), "Client is not confidential")
    current_uuid = attrs["uuid"][0]
    require(not annotations.get(UUID_KEY) or annotations[UUID_KEY] == current_uuid, "Client identity changed; manual review required")
    if marker not in " | ".join(attrs.get("description", [])).split(" | "):
        require(client.get("adoptExisting", False), "Existing client requires explicit adoptExisting")
        require(not any(v.startswith("managed by stacks kanidm-client-reconciler:") for v in " | ".join(attrs.get("description", [])).split(" | ")), "Client belongs to another declaration")
        owned_attrs["description"] = [" | ".join([*attrs.get("description", []), marker])]
    require(not attrs.get("oauth2_rs_sup_scope_map") and not attrs.get("oauth2_rs_claim_map"), "Supplemental scopes and claims require manual review")
    # These clients keep PKCE enabled and exact callback matching.
    if attrs.get("oauth2_allow_insecure_client_disable_pkce"):
        owned_attrs["oauth2_allow_insecure_client_disable_pkce"] = []
    if attrs.get("oauth2_allow_localhost_redirect") == ["true"]:
        owned_attrs["oauth2_allow_localhost_redirect"] = ["false"]
    changes = {key: value for key, value in owned_attrs.items() if sorted(attrs.get(key, [])) != sorted(value)}
    if changes:
        kanidm.call("PATCH", path, {"attrs": changes})

    current = parse_scope_maps(attrs.get("oauth2_rs_scope_map", []))
    normalized = {}
    # Remove undeclared access before granting or updating declared scopes.
    for group, scopes in current.items():
        key = aliases.get(group, group)
        if key not in desired:
            kanidm.call("DELETE", f"{path}/_scopemap/{quote(group, safe='')}")
        else:
            normalized[key] = scopes
    for group_uuid, scopes in desired.items():
        if normalized.get(group_uuid) != scopes:
            kanidm.call("POST", f"{path}/_scopemap/{group_uuid}", sorted(scopes))

    # Never ask Kanidm to reset secrets. Only deliver its existing credential.
    credential = kanidm.call("GET", path + "/_basic_secret")
    require(isinstance(credential, str) and bool(credential), "Client credential is not available")
    encoded = base64.b64encode(credential.encode()).decode()
    if secret.get("data", {}).get("client-secret") != encoded or annotations.get(UUID_KEY) != current_uuid:
        kube.call("PATCH", secret_path, {
            "metadata": {"resourceVersion": secret["metadata"]["resourceVersion"], "annotations": {UUID_KEY: current_uuid}},
            "data": {"client-secret": encoded},
        })


def reconcile_group(kanidm, group):
    require(isinstance(group, dict) and set(group) <= {"name", "description", "adoptExisting"} and {"name", "description"} <= group.keys(), "Invalid group declaration")
    name = group["name"]
    require(isinstance(name, str) and NAME.fullmatch(name) and not name.startswith(("idm_", "system_")), "Only ordinary application groups may be managed")
    require(isinstance(group["description"], str) and bool(group["description"].strip()), "Group description is required")
    require(type(group.get("adoptExisting", False)) is bool, "adoptExisting must be a boolean")
    marker = "managed by stacks kanidm-client-reconciler: group/" + name
    description = [group["description"] + " | " + marker]
    path = "/v1/group/" + name
    entry = kanidm.call("GET", path)
    if entry is None:
        kanidm.call("POST", "/v1/group", {"attrs": {
            "name": [name], "description": description, "entry_managed_by": ["idm_admin"],
        }})
    else:
        attrs = entry["attrs"]
        require("group" in attrs.get("class", []), "Existing entry is not a group")
        if marker not in " | ".join(attrs.get("description", [])).split(" | "):
            require(group.get("adoptExisting", False), "Existing group requires explicit adoptExisting")
            require(not any(v.startswith("managed by stacks kanidm-client-reconciler:") for v in " | ".join(attrs.get("description", [])).split(" | ")), "Group belongs to another declaration")
        if sorted(attrs.get("description", [])) != sorted(description):
            kanidm.call("PATCH", path, {"attrs": {"description": description}})
    # Membership and group lifecycle are deliberately outside this reconciler.


def main():
    kube_dir = Path("/var/run/secrets/kubernetes.io/serviceaccount")
    kube = API("https://kubernetes.default.svc", kube_dir / "token", str(kube_dir / "ca.crt"))
    kanidm = API(os.environ["KANIDM_URL"], "/bootstrap/token")
    registry = json.loads(Path("/config/registry.json").read_text())
    require(isinstance(registry, dict) and set(registry) == {"clients", "groups"}, "Invalid enrollment registry")
    seen = set()
    for ref in registry["clients"]:
        require(set(ref) == {"namespace", "configMap"}, "Invalid enrollment entry")
        key = (ref["namespace"], ref["configMap"])
        require(key not in seen, "Duplicate enrollment entry")
        seen.add(key)
    group_names = [group["name"] for group in registry["groups"]]
    require(len(group_names) == len(set(group_names)), "Duplicate group declaration")
    failed = False
    for group in registry["groups"]:
        try:
            reconcile_group(kanidm, group)
            print(f"group/{group['name']}: reconciled", flush=True)
        except ReconcileError as error:
            print(f"group reconciliation: {error}", file=sys.stderr, flush=True)
            failed = True
        except Exception:
            print("Group reconciliation failed; check declaration and API compatibility", file=sys.stderr, flush=True)
            failed = True
    for ref in registry["clients"]:
        try:
            reconcile_client(kube, kanidm, ref["namespace"], ref["configMap"])
            print(f"{ref['namespace']}/{ref['configMap']}: reconciled", flush=True)
        except ReconcileError as error:
            print(f"{ref['namespace']}/{ref['configMap']}: {error}", file=sys.stderr, flush=True)
            failed = True
        except Exception:
            # Tracebacks may include API payloads; keep errors deliberately bounded.
            print("Client reconciliation failed; check declaration and API compatibility", file=sys.stderr, flush=True)
            failed = True
    return int(failed)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        print("Reconciler initialization failed; check bootstrap Secret and configuration", file=sys.stderr)
        sys.exit(1)
