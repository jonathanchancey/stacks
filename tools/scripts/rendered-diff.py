#!/usr/bin/env python3
"""compare complete flate renders and retain newly introduced image references."""

import base64
import binascii
import difflib
import hashlib
import json
from pathlib import Path
import sys


STRIP_ATTRIBUTES = {"helm.sh/chart", "app.kubernetes.io/version", "chart"}


def normalize(value):
    if isinstance(value, list):
        return [normalize(item) for item in value]
    if not isinstance(value, dict):
        return value
    value = {key: normalize(item) for key, item in value.items()}
    metadata = value.get("metadata")
    if not isinstance(metadata, dict):
        return value
    for field in ("annotations", "labels"):
        if metadata.get(field) is None:
            metadata.pop(field, None)
        elif isinstance(metadata[field], dict):
            metadata[field] = {
                key: item for key, item in metadata[field].items()
                if key not in STRIP_ATTRIBUTES and not key.startswith("checksum/")
            }
            if not metadata[field]:
                del metadata[field]
    return value


def binary_summary(value):
    if not isinstance(value, str):
        return "<redacted binary data>"
    try:
        data = base64.b64decode(value.strip().replace("\n", "").replace("\r", ""), validate=True)
        length = f"{len(data)} bytes"
    except (binascii.Error, ValueError):
        data = value.encode("utf-8")
        length = f"{len(value)} base64 chars"
    return f"<redacted binary data: {length} sha256:{hashlib.sha256(data).hexdigest()[:16]}>"


def resources(documents):
    if not isinstance(documents, list):
        raise ValueError("expected a json array of rendered resources")
    result = {}
    for document in documents:
        if document["kind"] == "Secret":
            continue
        metadata = document["metadata"]
        key = (document["apiVersion"], document["kind"], metadata.get("namespace", ""), metadata["name"])
        normalized = normalize(document)
        if document["kind"] == "ConfigMap" and isinstance(document.get("binaryData"), dict):
            normalized["binaryData"] = {name: binary_summary(value) for name, value in document["binaryData"].items()}
        result.setdefault(key, []).append(normalized)
    for key, documents in result.items():
        if len(documents) > 1 and key[1] != "ServiceAccount":
            raise ValueError(f"duplicate resource: {key}")
        copies = {json.dumps(document, sort_keys=True): document for document in documents}
        ordered = [copies[value] for value in sorted(copies)]
        if len(ordered) == 1:
            result[key] = ordered[0]
            continue
        # authored and chart-generated service accounts can share a body.
        # retain both metadata variants so ownership and label changes stay visible.
        shapes = []
        for document in ordered:
            shape = {**document, "metadata": {name: value for name, value in document["metadata"].items()
                                               if name not in ("labels", "annotations")}}
            shapes.append(shape)
        if any(shape != shapes[0] for shape in shapes[1:]):
            raise ValueError(f"duplicate resource with conflicting contents: {key}")
        result[key] = ordered
    return result


def rendered_diff(before, after):
    before, after = resources(before), resources(after)
    chunks = []
    for key in sorted(before.keys() | after.keys()):
        name = "/".join(part for part in key if part)
        lines = lambda value: (json.dumps(value, indent=2, sort_keys=True) + "\n").splitlines(keepends=True)
        left = lines(before[key]) if key in before else []
        right = lines(after[key]) if key in after else []
        chunks.extend(difflib.unified_diff(left, right, fromfile=f"base/{name}", tofile=f"head/{name}"))
    return "".join(chunks)


def new_images(before, after):
    for images in (before, after):
        if not isinstance(images, list) or not all(isinstance(image, str) for image in images):
            raise ValueError("expected a json array of image references")
    return sorted(set(after) - set(before))


def main():
    snapshot, output = map(Path, sys.argv[1:])
    read = lambda name: json.loads((snapshot / name).read_text(encoding="utf-8"))
    (output / "flux.diff").write_text(rendered_diff(read("base.json"), read("head.json")), encoding="utf-8")
    images = new_images(read("base-images.json"), read("head-images.json"))
    (output / "images.json").write_text(json.dumps(images) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
