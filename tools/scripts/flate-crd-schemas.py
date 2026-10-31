#!/usr/bin/env python3
"""extract strict json schemas from the crds in a flate render."""

import json
from pathlib import Path
import re
import sys


def schema(value):
    if isinstance(value, list):
        return [schema(item) for item in value]
    if not isinstance(value, dict):
        return value
    result = dict(value)
    for key in ("properties", "patternProperties", "definitions", "$defs"):
        if key in result:
            result[key] = {name: schema(item) for name, item in result[key].items()}
    for key in ("items", "additionalProperties", "not", "allOf", "anyOf", "oneOf"):
        if key in result:
            result[key] = schema(result[key])
    if result.get("x-kubernetes-int-or-string"):
        result.pop("type", None)
        result["anyOf"] = [{"type": "integer"}, {"type": "string"}]
    if result.pop("nullable", False):
        if isinstance(result.get("type"), str):
            result["type"] = [result["type"], "null"]
        elif "anyOf" in result:
            result["anyOf"].append({"type": "null"})
    if (
        result.get("type") in ("object", ["object", "null"])
        and "properties" in result
        and not result.get("x-kubernetes-preserve-unknown-fields")
    ):
        result.setdefault("additionalProperties", False)
    return result


output = Path(sys.argv[1])
for line in sys.stdin:
    crd = json.loads(line)
    spec = crd["spec"]
    if not re.fullmatch(r"[a-z0-9]+(?:[.-][a-z0-9]+)*", spec["group"]):
        raise ValueError("invalid crd group")
    directory = output / spec["group"]
    directory.mkdir(parents=True, exist_ok=True)
    for version in spec["versions"]:
        if not version.get("served", True):
            continue
        document = schema(version["schema"]["openAPIV3Schema"])
        # kubernetes supplies these fields even when a crd omits their schemas.
        properties = document.setdefault("properties", {})
        for key, field_type in (("apiVersion", "string"), ("kind", "string"), ("metadata", "object")):
            properties.setdefault(key, {"type": field_type})
        filename = f'{spec["names"]["kind"].lower()}_{version["name"]}.json'
        if Path(filename).name != filename:
            raise ValueError("invalid crd kind or version")
        (directory / filename).write_text(json.dumps(document))
