#!/usr/bin/env python3
"""Synchronize generated Godot metadata from scripts/version.gd.

The GDScript constant is the canonical version. This small standard-library
script intentionally updates only the two metadata files that Godot cannot
populate from a script constant.

    python3 tools/sync_version.py            # rewrite the metadata (default)
    python3 tools/sync_version.py --check    # report drift, change nothing

--check is the CI form: it exits 1 when scripts/version.gd disagrees with
project.godot or export_presets.cfg, so a version bump that forgot two files
fails the build instead of shipping mixed metadata.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def main(argv):
    check = False
    for arg in argv:
        if arg != "--check":
            raise SystemExit(f"unknown argument: {arg} (only --check is accepted)")
        check = True

    source = (ROOT / "scripts/version.gd").read_text()
    match = re.search(r'^const\s+VALUE\s*:=\s*"([^"]+)"', source, re.MULTILINE)
    if not match:
        raise SystemExit("scripts/version.gd has no const VALUE")
    version = match.group(1)
    windows = version + ".0"

    changes = {
        "project.godot": [(r'config/version="[^"]+"', f'config/version="{version}"')],
        "export_presets.cfg": [
            (r'application/file_version="[^"]+"', f'application/file_version="{windows}"'),
            (r'application/product_version="[^"]+"', f'application/product_version="{windows}"'),
        ],
    }

    out_of_sync = []
    for name, replacements in changes.items():
        path = ROOT / name
        original = path.read_text()
        updated = original
        for pattern, replacement in replacements:
            updated, count = re.subn(pattern, replacement, updated)
            if count != 1:
                raise SystemExit(f"expected one {pattern} in {name}, found {count}")
        if updated == original:
            continue
        out_of_sync.append(name)
        if check:
            print(f"{name}: out of sync (expected {version} / Windows {windows})")
        else:
            path.write_text(updated)
            print(f"{name}: {version} (Windows {windows})")

    if check:
        if out_of_sync:
            print(
                "version metadata is out of sync with scripts/version.gd; "
                "run: python3 tools/sync_version.py",
                file=sys.stderr,
            )
            return 1
        print(f"version metadata is in sync: {version} (Windows {windows})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
