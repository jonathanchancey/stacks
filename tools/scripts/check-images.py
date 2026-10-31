#!/usr/bin/env python3
"""check newly rendered images anonymously for every configured platform."""

import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


def command(*arguments, env=None):
    return subprocess.check_output(arguments, text=True, env=env, timeout=120)


def check_images(images, platforms):
    if not isinstance(images, list) or not all(
        isinstance(image, str) and image and not re.search(r"\s", image) and not image.startswith("-")
        for image in images
    ):
        raise ValueError("expected a json array of image references")
    if not isinstance(platforms, list) or not platforms or not all(
        isinstance(platform, str) and re.fullmatch(r"[a-z0-9]+/[a-z0-9]+(?:/[a-z0-9]+)?", platform)
        for platform in platforms
    ):
        raise ValueError("imagePlatforms must list os/architecture platforms")

    failures = []
    # hosted ci and local checks both use anonymous registry access.
    with tempfile.TemporaryDirectory(prefix="image-check-auth-") as auth:
        Path(auth, "config.json").write_text("{}", encoding="utf-8")
        env = dict(os.environ, DOCKER_CONFIG=auth)
        for image in sorted(set(images)):
            try:
                digest = command("crane", "digest", image, env=env).strip()
                if not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
                    raise ValueError("registry returned an invalid image digest")
                reference = image.split("@", 1)[0] + "@" + digest
                for platform in platforms:
                    config = json.loads(command("crane", "config", "--platform", platform, reference, env=env))
                    expected = platform.split("/")
                    actual = [config.get("os"), config.get("architecture")]
                    if len(expected) == 3:
                        actual.append(config.get("variant"))
                    if actual != expected:
                        raise ValueError(f"{platform}: image config declares {actual}")
                    print(f"passed: {image} ({platform})")
            except (subprocess.SubprocessError, ValueError, OSError) as error:
                failures.append(f"{image}: {error}")
    if failures:
        raise RuntimeError("image validation failed:\n" + "\n".join(failures))
    print(f"checked {len(set(images))} new images for {', '.join(platforms)}")


def main():
    config = Path(__file__).resolve().parents[1] / "flate.yaml"
    platforms = json.loads(command("yq", "-o=json", ".imagePlatforms", str(config)))
    check_images(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")), platforms)


if __name__ == "__main__":
    main()
