#!/usr/bin/env -S uv run python
# /// script
# dependencies = ["jinja2"]
# ///
"""
Bastille App Template Generator

Riding a fine line here
https://xkcd.com/1205/
"""

import argparse
import sys
from pathlib import Path
from jinja2 import FileSystemLoader
from jinja2.sandbox import SandboxedEnvironment


def prompt(message, default=None):
    """Simple prompt with optional default"""
    if default:
        response = input(f"{message} [{default}]: ").strip()
        return response if response else default
    else:
        response = input(f"{message}: ").strip()
        if not response:
            print("This field is required!")
            return prompt(message, default)
        return response


def yes_no(message, default=False):
    """Yes/No prompt"""
    default_str = "Y/n" if default else "y/N"
    response = input(f"{message} [{default_str}]: ").strip().lower()
    if not response:
        return default
    return response.startswith("y")


def render_template(template_path, variables):
    """Render a Jinja2 template file with variables using sandboxed environment"""
    template_dir = template_path.parent
    template_name = template_path.name

    env = SandboxedEnvironment(loader=FileSystemLoader(template_dir))
    template = env.get_template(template_name)

    return template.render(**variables)


def create_directory_structure(base_path):
    """Create the directory structure"""
    dirs = [base_path, base_path / "app", base_path / "app" / "helm"]
    for dir_path in dirs:
        dir_path.mkdir(parents=True, exist_ok=True)


def parse_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Generate Bastille app deployment")
    parser.add_argument("--app-name", required=True, help="Application name")
    parser.add_argument(
        "--namespace", help="Kubernetes namespace (defaults to app name)"
    )
    parser.add_argument(
        "--image-repo", required=True, help="Container image repository"
    )
    parser.add_argument("--image-tag", default="latest", help="Container image tag")
    parser.add_argument("--service-port", default="80", help="Service port")
    parser.add_argument(
        "--hostname", help="Hostname (defaults to app-name.chancey.dev)"
    )
    parser.add_argument(
        "--component-type",
        default="common",
        choices=["common", "privileged"],
        help="Component type",
    )
    parser.add_argument(
        "--volsync-capacity", default="5Gi", help="Volsync backup capacity"
    )
    parser.add_argument("--no-route", action="store_true", help="Disable HTTPRoute")
    parser.add_argument(
        "--no-values", action="store_true", help="Disable helm values ConfigMap"
    )
    parser.add_argument("--enable-secrets", action="store_true", help="Enable secrets")
    parser.add_argument(
        "--enable-volsync", action="store_true", help="Enable Volsync backup"
    )
    parser.add_argument(
        "--output-dir",
        help="Custom output directory path (overrides default flux/bastille/apps/namespace/app-name)",
    )
    return parser.parse_args()


def main():
    print("Bastille App Template Generator")
    print("=" * 40)

    # Check if running with CLI args
    has_args = len(sys.argv) > 1
    has_cli_flags = any(arg.startswith("--") for arg in sys.argv[1:])
    has_app_name_only = (
        has_args and not sys.argv[1].startswith("-") and not has_cli_flags
    )

    if has_app_name_only:
        # Legacy mode: just app name as first arg
        app_name = sys.argv[1]
        variables = {}
        variables["APP_NAME"] = app_name
        variables["NAMESPACE"] = prompt("Namespace", variables["APP_NAME"])
        variables["IMAGE_REPO"] = prompt("Image repository (e.g., ghcr.io/org/app)")
        variables["IMAGE_TAG"] = prompt("Image tag", "latest")
        variables["SERVICE_PORT"] = prompt("Service port", "80")

        # Optional features
        variables["ENABLE_ROUTE"] = yes_no("Enable HTTPRoute?", True)
        if variables["ENABLE_ROUTE"]:
            variables["HOSTNAME"] = prompt(
                "Hostname", f"{variables['APP_NAME']}.chancey.dev"
            )

        variables["ENABLE_VALUES"] = yes_no("Enable helm values ConfigMap?", True)
        variables["ENABLE_SECRETS"] = yes_no("Enable secrets?", False)
        variables["ENABLE_VOLSYNC"] = yes_no("Enable Volsync backup?", False)

        if variables["ENABLE_VOLSYNC"]:
            variables["VOLSYNC_CAPACITY"] = prompt("Volsync capacity", "5Gi")

        variables["COMPONENT_TYPE"] = prompt("Component type", "common").lower()
        if variables["COMPONENT_TYPE"] not in ["common", "privileged"]:
            variables["COMPONENT_TYPE"] = "common"

        # Default output directory for interactive mode
        output_base = Path(f"flux/bastille/apps/{variables['NAMESPACE']}")
        app_output = output_base / variables["APP_NAME"]
    elif has_cli_flags:
        # CLI argument mode
        args = parse_args()
        variables = {}
        variables["APP_NAME"] = args.app_name
        variables["NAMESPACE"] = args.namespace or args.app_name
        variables["IMAGE_REPO"] = args.image_repo
        variables["IMAGE_TAG"] = args.image_tag
        variables["SERVICE_PORT"] = args.service_port
        variables["HOSTNAME"] = args.hostname or f"{args.app_name}.chancey.dev"
        variables["COMPONENT_TYPE"] = args.component_type
        variables["VOLSYNC_CAPACITY"] = args.volsync_capacity

        # Boolean flags
        variables["ENABLE_ROUTE"] = not args.no_route
        variables["ENABLE_VALUES"] = not args.no_values
        variables["ENABLE_SECRETS"] = args.enable_secrets
        variables["ENABLE_VOLSYNC"] = args.enable_volsync

        # Output directory - use custom path or default
        if args.output_dir:
            app_output = Path(args.output_dir).resolve()
            output_base = app_output.parent
        else:
            output_base = Path(f"flux/bastille/apps/{variables['NAMESPACE']}")
            app_output = output_base / variables["APP_NAME"]
    else:
        # Interactive mode: no arguments provided
        variables = {}
        variables["APP_NAME"] = prompt("Application name")
        variables["NAMESPACE"] = prompt("Namespace", variables["APP_NAME"])
        variables["IMAGE_REPO"] = prompt("Image repository (e.g., ghcr.io/org/app)")
        variables["IMAGE_TAG"] = prompt("Image tag", "latest")
        variables["SERVICE_PORT"] = prompt("Service port", "80")

        # Optional features
        variables["ENABLE_ROUTE"] = yes_no("Enable HTTPRoute?", True)
        if variables["ENABLE_ROUTE"]:
            variables["HOSTNAME"] = prompt(
                "Hostname", f"{variables['APP_NAME']}.chancey.dev"
            )

        variables["ENABLE_VALUES"] = yes_no("Enable helm values ConfigMap?", True)
        variables["ENABLE_SECRETS"] = yes_no("Enable secrets?", False)
        variables["ENABLE_VOLSYNC"] = yes_no("Enable Volsync backup?", False)

        if variables["ENABLE_VOLSYNC"]:
            variables["VOLSYNC_CAPACITY"] = prompt("Volsync capacity", "5Gi")

        variables["COMPONENT_TYPE"] = prompt("Component type", "common").lower()
        if variables["COMPONENT_TYPE"] not in ["common", "privileged"]:
            variables["COMPONENT_TYPE"] = "common"

        # Default output directory for interactive mode
        output_base = Path(f"flux/bastille/apps/{variables['NAMESPACE']}")
        app_output = output_base / variables["APP_NAME"]

    # Template directory
    template_dir = Path(__file__).parent

    print(f"\nCreating deployment at: {app_output}")

    # Create directory structure
    create_directory_structure(app_output)

    # Render and write templates using Jinja2
    templates = [
        "ks.yaml.j2",
        "app/kustomization.yaml.j2",
        "app/helmrelease.yaml.j2",
    ]

    if variables["ENABLE_VALUES"]:
        templates.append("app/helm/values.yaml.j2")

    if variables["ENABLE_SECRETS"]:
        templates.append("app/secrets.sops.yaml.j2")

    for template_file in templates:
        template_path = template_dir / template_file
        output_file = app_output / template_file.replace(".j2", "")

        if template_path.exists():
            content = render_template(template_path, variables)
            output_file.parent.mkdir(parents=True, exist_ok=True)
            with open(output_file, "w") as f:
                f.write(content)
            print(f"Created {output_file}")
        else:
            print(f"Warning: Template {template_path} not found")

    # Create namespace kustomization if it doesn't exist
    ns_kustomization = output_base / "kustomization.yaml"
    if not ns_kustomization.exists():
        content = render_template(template_dir / "kustomization.yaml.j2", variables)
        with open(ns_kustomization, "w") as f:
            f.write(content)
        print(f"Created {ns_kustomization}")

        # Remind to add namespace to main apps kustomization
        print(
            f"\nDont forget to add '{variables['NAMESPACE']}' to flux/bastille/apps/kustomization.yaml"
        )

    print("\nDeployment template created successfully!")
    print(f"Location: {app_output}")
    print("\nNext steps:")
    print("   1. Review and customize the generated files")
    if variables["ENABLE_SECRETS"]:
        print(f"   2. Add secrets to {app_output}/app/secrets.sops.yaml")
    print("   3. Commit and push to trigger Flux reconciliation")


if __name__ == "__main__":
    main()
