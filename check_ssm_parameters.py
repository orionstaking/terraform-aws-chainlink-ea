#!/usr/bin/env python3
"""Fail when an ea_secret_parameters entry has no SecureString in Parameter Store.

Terraform external data sources persist stdout in state, so this script prints
only {"ok": "true"}. DescribeParameters returns names and types, not values.
"""
import json
import subprocess
import sys


def describe(region, name):
    proc = subprocess.run(
        [
            "aws",
            "ssm",
            "describe-parameters",
            "--region",
            region,
            "--parameter-filters",
            f"Key=Name,Option=Equals,Values={name}",
            "--output",
            "json",
        ],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        detail = proc.stderr.strip().splitlines()
        sys.exit(detail[-1] if detail else f"describe-parameters failed for {name}")
    parameters = json.loads(proc.stdout).get("Parameters", [])
    return [item for item in parameters if item.get("Name") == name]


def main():
    query = json.load(sys.stdin)
    region = query["region"]
    names = json.loads(query["names"])
    if not isinstance(names, list):
        sys.exit("names must be a JSON list of parameter names")

    missing = []
    wrong_type = []
    for name in names:
        matches = describe(region, name)
        if not matches:
            missing.append(name)
            continue
        parameter_type = matches[0].get("Type")
        if parameter_type != "SecureString":
            wrong_type.append(f"{name} is {parameter_type}")

    if missing or wrong_type:
        lines = ["Create these SSM parameters before apply."]
        if missing:
            lines.append("Missing:")
            lines.extend(f"  {name}" for name in missing)
        if wrong_type:
            lines.append("Not SecureString:")
            lines.extend(f"  {name}" for name in wrong_type)
        sys.exit("\n".join(lines))

    json.dump({"ok": "true"}, sys.stdout)


if __name__ == "__main__":
    main()
