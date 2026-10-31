#!/usr/bin/env python3
"""compare complete flate renders and retain newly introduced image references."""

import difflib
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


def resources(documents):
    if not isinstance(documents, list):
        raise ValueError("expected a json array of rendered resources")
    result = {}
    for document in documents:
        if document["kind"] == "Secret":
            continue
        metadata = document["metadata"]
        key = (document["apiVersion"], document["kind"], metadata.get("namespace", ""), metadata["name"])
        if key in result:
            raise ValueError(f"duplicate resource: {key}")
        result[key] = normalize(document)
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
