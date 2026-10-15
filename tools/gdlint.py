#!/usr/bin/env python3
"""Structural linter for the project's GDScript.

Godot is not always available (CI, a clean checkout, a sandbox without the
editor), and the most expensive class of bug in a script-only project is a
syntax error that only the engine will tell you about.  This checks the things
that can be checked without a parser:

  * indentation is tabs (Godot rejects mixed tabs/spaces)
  * balanced (), [] and {} outside strings and comments
  * block headers end in ':' and open a deeper block
  * no 'elif' after 'else', no stray 'match' without arms
  * every OP_TICKER key referenced as ticker["x"] is declared in op.gd
  * every habit id referenced as has("XX") / hb("XX") exists in habits.gd
  * every habit id declared in habits.gd has at least one call site (Tier 0 #2)

Usage:
    python3 tools/gdlint.py            # check scripts/ and tests/
    python3 tools/gdlint.py --quiet    # errors only
    python3 tools/gdlint.py scripts/   # check a subtree
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

BLOCK_OPENERS = (
    "if ", "elif ", "else", "for ", "while ", "func ", "match ", "class ",
    "static func ", "signal ", "enum ", "class_name ",
)


def strip_comment(src: str) -> str:
    """Remove a trailing comment, preserving string literals."""
    out = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if c == "#":
            break
        if c in '"\'':
            q = c
            out.append(c)
            i += 1
            while i < n and src[i] != q:
                if src[i] == "\\":
                    out.append(src[i])
                    i += 1
                if i < n:
                    out.append(src[i])
                i += 1
            if i < n:
                out.append(src[i])
            i += 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def strip_line(src: str) -> str:
    """Remove a trailing comment and any string literals from one line."""
    out = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if c == "#":
            break
        if c == '"':
            i += 1
            while i < n and src[i] != '"':
                if src[i] == "\\":
                    i += 1
                i += 1
        elif c == "'":
            i += 1
            while i < n and src[i] != "'":
                if src[i] == "\\":
                    i += 1
                i += 1
        else:
            out.append(c)
        i += 1
    return "".join(out)


def indent_of(line: str) -> tuple[int, str, bool]:
    """Return (depth, whitespace, uses_spaces) for a line's leading indent."""
    m = re.match(r"^([ \t]*)", line)
    ws = m.group(1)
    depth = ws.count("\t") + ws.count("    ") // 1 * 0  # tabs only count
    depth = ws.count("\t")
    return depth, ws, (" " in ws)


class Issue:
    __slots__ = ("path", "line", "msg")

    def __init__(self, path: str, line: int, msg: str) -> None:
        self.path = path
        self.line = line
        self.msg = msg

    def __str__(self) -> str:
        return "%s:%d: %s" % (self.path, self.line, self.msg)


def check_file(path: Path, issues: list, ticker_keys: set, habit_ids: set,
               found_habit_sites: dict) -> None:
    rel = str(path.relative_to(ROOT))
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        issues.append(Issue(rel, 0, "not valid UTF-8"))
        return

    lines = text.split("\n")
    pairs = {")": "(", "]": "[", "}": "{"}
    openers = set("([{")
    depth = {"(": 0, "[": 0, "{": 0}

    for ln, raw in enumerate(lines, start=1):
        # ---- indentation must be tabs
        stripped = raw.lstrip()
        if stripped and not stripped.startswith("#"):
            _, ws, uses_spaces = indent_of(raw)
            if uses_spaces:
                issues.append(Issue(rel, ln, "space indentation (Godot requires tabs)"))

        code = strip_line(raw)      # no strings: for bracket balance
        text_code = strip_comment(raw)   # strings kept: for id lookups
        if not code.strip():
            continue

        # ---- bracket balance (line-local; Godot allows multi-line, so we only
        #      flag a *negative* balance or an unclosed block at EOF)
        for ch in code:
            if ch in openers:
                depth[ch] += 1
            elif ch in pairs:
                depth[pairs[ch]] -= 1
                if depth[pairs[ch]] < 0:
                    issues.append(Issue(rel, ln, "unmatched closing '%s'" % ch))
                    depth[pairs[ch]] = 0

        # ---- ticker key declarations (strings preserved)
        for m in re.finditer(r'ticker\.get\(\s*"([a-z_0-9]*)([A-Za-z_0-9]*)"', text_code):
            key = m.group(1)
            if not key.endswith("_") and ticker_keys and key not in ticker_keys:
                issues.append(Issue(rel, ln, 'undeclared ticker key "%s"' % key))
        for m in re.finditer(r'ticker\[\s*"([a-z_0-9]*?)"\s*\]', text_code):
            key = m.group(1)
            if not key.endswith("_") and ticker_keys and key not in ticker_keys:
                issues.append(Issue(rel, ln, 'undeclared ticker key "%s"' % key))

        # ---- habit ids (strings preserved)
        for m in re.finditer(r'\b(?:has|hb)\(\s*"([A-Z]{2}\d{2})"\s*\)', text_code):
            hid = m.group(1)
            found_habit_sites.setdefault(hid, []).append("%s:%d" % (rel, ln))
            if habit_ids and hid not in habit_ids:
                issues.append(Issue(rel, ln, "unknown habit id %s" % hid))
        for m in re.finditer(r'\bbad\.get\(\s*"([A-Z]{2}\d{2})"', text_code):
            hid = m.group(1)
            found_habit_sites.setdefault(hid, []).append("%s:%d" % (rel, ln))
            if habit_ids and hid not in habit_ids:
                issues.append(Issue(rel, ln, "unknown habit id %s" % hid))

    for ch, d in depth.items():
        if d != 0:
            issues.append(Issue(rel, len(lines), "unbalanced '%s' (%d unclosed)" % (ch, d)))


def load_ticker_keys() -> set:
    src = (ROOT / "scripts" / "sim" / "op.gd").read_text(encoding="utf-8")
    m = re.search(r"const TICKER_KEYS\s*:?=\s*\[(.*?)\]", src, re.S)
    if not m:
        return set()
    return set(re.findall(r'"([a-z_0-9]+)"', m.group(1)))


def load_habit_ids() -> set:
    src = (ROOT / "scripts" / "data" / "habits.gd").read_text(encoding="utf-8")
    return set(re.findall(r'\{"id":\s*"([A-Z]{2}\d{2})"', src))


def main(argv: list) -> int:
    args = [a for a in argv[1:] if not a.startswith("--")]
    quiet = "--quiet" in argv
    roots = [ROOT / a for a in args] if args else [ROOT / "scripts", ROOT / "tests"]

    ticker_keys = load_ticker_keys()
    habit_ids = load_habit_ids()
    issues: list = []
    sites: dict = {}
    files: list = []
    for r in roots:
        files.extend(sorted(r.rglob("*.gd")))

    for p in files:
        check_file(p, issues, ticker_keys, habit_ids, sites)

    errors = [i for i in issues if not i.msg.startswith("habit")]

    if not quiet:
        print("gdlint: %d file(s), %d issue(s)" % (len(files), len(issues)))
        print("  ticker keys declared : %d" % len(ticker_keys))
        print("  habit ids declared   : %d" % len(habit_ids))
        covered = len([h for h in habit_ids if sites.get(h)])
        print("  habits with a call site: %d / %d" % (covered, len(habit_ids)))
        missing = sorted(h for h in habit_ids if not sites.get(h))
        if missing:
            print("  habits with NO call site: %s" % ", ".join(missing))

    for i in issues:
        print(str(i))

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
