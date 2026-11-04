#!/usr/bin/env python3
"""Find which top-level block of a GDScript file the engine cannot parse.

The static checks in tools/ (bracket balance, duplicate members, `:=` in 4.7,
arity, and three hand-written indentation scanners) all accept
`scripts/ui/ops_ui.gd`, while Godot 4.7.2 refuses it with "Unindent doesn't
match the previous indentation level" and prints no line (EA_TASKS B6). The
engine is the only oracle for that error, so this script uses it: it splits the
file at top-level block boundaries, then bisects on *ranges of blocks*, writing
a scratch script into the project (so `res://` preloads still resolve) and
asking the engine to parse it with `--check-only`.

Monotone assumption: the fault lives inside one block, so any range that
contains that block fails and any range that does not is silent. Errors the
missing blocks cause (unknown identifiers) are ignored -- only the message we
are chasing counts.

    GODOT=~/godot/godot python3 tools/parse_bisect.py scripts/ui/ops_ui.gd
    GODOT=~/godot/godot python3 tools/parse_bisect.py <file> --needle "Unindent"

Exit code 0 when the fault was located, 1 when the engine never reported it
(the whole file parsed, or the needle never matched).
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRATCH = ROOT / "parse_bisect_probe.gd"  # res://parse_bisect_probe.gd while the probe runs

# A top-level block starts at column 0 with one of these. Comments and blank
# lines stay attached to the block that follows them.
BLOCK = re.compile(
    r"^(func |static func |const |var |@|class |signal |enum |## |# )"
)


def split_blocks(lines):
    """Return (prologue, blocks) with blocks as lists of lines, each starting at column 0."""
    starts = []
    for i, line in enumerate(lines):
        if line and not line[0].isspace() and BLOCK.match(line):
            starts.append(i)
    if not starts:
        return lines, []
    prologue = lines[: starts[0]]
    # A run of `##`/`#` lines directly above a func/const belongs with it; since
    # both are matched by BLOCK, treat consecutive comment runs as their own
    # blocks -- harmless: they never carry the fault and cost one level each.
    bounds = starts + [len(lines)]
    blocks = [lines[bounds[k]: bounds[k + 1]] for k in range(len(starts))]
    return prologue, blocks


def name_of(block):
    for line in block:
        if line.strip() and not line.lstrip().startswith("#"):
            return line.strip()[:70]
    return "(comment)"


def verify(godot, needle, prologue, blocks, chosen):
    text = "".join(prologue + [l for i in chosen for l in blocks[i]])
    SCRATCH.write_text(text)
    try:
        out = subprocess.run(
            [godot, "--headless", "--path", str(ROOT), "--check-only", "-s",
             "res://" + SCRATCH.name],
            capture_output=True, text=True, timeout=180,
        )
    except subprocess.TimeoutExpired:
        return True  # a hang is not a parse answer; treat as "not this range"
    finally:
        if SCRATCH.exists():
            SCRATCH.unlink()
    blob = out.stdout + out.stderr
    return needle in blob


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("--needle", default="Unindent doesn't match")
    args = ap.parse_args()

    godot = os.environ.get("GODOT", "godot")
    path = Path(args.file)
    lines = path.read_text().splitlines(keepends=True)
    prologue, blocks = split_blocks(lines)
    print(f"{path}: {len(blocks)} top-level blocks, prologue {len(prologue)} lines")

    everything = list(range(len(blocks)))
    if not verify(godot, args.needle, prologue, blocks, everything):
        print(f"the engine does NOT report {args.needle!r} for the whole file")
        return 1

    lo, hi = 0, len(blocks)  # [lo, hi) always contains the fault
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if verify(godot, args.needle, prologue, blocks, list(range(lo, mid))):
            hi = mid
        elif verify(godot, args.needle, prologue, blocks, list(range(mid, hi))):
            lo = mid
        else:
            print(f"not localised: neither half of blocks {lo}..{hi} fails on its own")
            for i in range(lo, hi):
                print(f"  {i}: {name_of(blocks[i])}")
            return 1
        print(f"  narrowed to blocks {lo}..{hi}")

    block = blocks[lo]
    print(f"\nblock {lo} of {len(blocks)}: {name_of(block)}")
    for n, line in enumerate(block, 1):
        print(f"  {n:4d}| {line.rstrip()}")
    print(f"\nthe fault is in or at the end of block {lo}: {name_of(block)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
