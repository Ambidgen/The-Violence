#!/usr/bin/env python3
"""The Violence: the two parse faults no static check here could see (added 2026-11-02).

`tools/gd47_check.py` checks bracket balance, duplicate members, indentation and the
`:=` constructs: it does not resolve names, so it cannot see a call with the wrong number
of arguments or an identifier that was never declared. `gdparse` parses; both fault classes
parse fine and only fail when the engine loads the script. That is how, on 2026-11-02, the
whole of `scripts/campaign/politics.gd` came to fail at runtime ("Identifier
SURPLUS_COOLDOWN not declared", then "Too many arguments for \"_poll()\" call") while every
static check in CI was green: the balance matrix's engine logs were the first thing to say
so, and they said it 80 times.

This checks exactly those two things, and nothing else:

  arity      a call to a function declared in the same file, or on a `const X = preload(..)`
             alias of a `.gd` file, passes more arguments than the function takes.
             (Too few arguments is not checked: a callback named `press` or `shot` shadows
             a method often enough that the check would cry wolf. Too many cannot.)
  concat     a `+` between a string literal and a number or an int()/float() call, which
             GDScript rejects at parse time ("Invalid operands String and int for +").
  names      a SCREAMING_CASE identifier used in an expression that is not declared in the
             file, is not a member of a preloaded file, and is not one of Godot's globals.

    python3 tools/gd_arity_check.py            # scripts/, tests/, tools/
    python3 tools/gd_arity_check.py --list     # print the files it reads

Exit 1 on a finding. Not a type checker: it knows nothing about what a value is, only how
many arguments a function takes and which constants exist.
"""

from __future__ import annotations
import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# Godot's global constants and enums, and GDScript's own functions' names.
GLOBALS = {
    "INF", "NAN", "PI", "TAU", "JSON", "TYPE_NIL", "TYPE_BOOL", "TYPE_INT", "TYPE_FLOAT",
    "TYPE_STRING", "TYPE_VECTOR2", "TYPE_RECT2", "TYPE_ARRAY", "TYPE_DICTIONARY", "TYPE_MAX",
    "CONNECT_ONE_SHOT", "CONNECT_DEFERRED", "CONNECT_PERSIST", "PROPERTY_HINT_NONE",
    "PROPERTY_USAGE_DEFAULT", "MOUSE_BUTTON_LEFT", "MOUSE_BUTTON_RIGHT", "MOUSE_BUTTON_MIDDLE",
    "MOUSE_BUTTON_WHEEL_UP", "MOUSE_BUTTON_WHEEL_DOWN", "HORIZONTAL_ALIGNMENT_LEFT",
    "HORIZONTAL_ALIGNMENT_CENTER", "HORIZONTAL_ALIGNMENT_RIGHT", "HORIZONTAL_ALIGNMENT_FILL",
    "VERTICAL_ALIGNMENT_TOP", "VERTICAL_ALIGNMENT_CENTER", "VERTICAL_ALIGNMENT_BOTTOM",
    "TEXT_DIRECTION_INHERITED", "AUTOWRAP_OFF", "AUTOWRAP_WORD_SMART",
    "RID", "VECTOR2", "RECT2", "TRANSFORM2D", "BASIS", "TRANSFORM3D", "PROJECTION",
}
GLOBALS |= {f"KEY_{k}" for k in (
    "ESCAPE ENTER KP_ENTER SPACE TAB BACKSPACE DELETE UP DOWN LEFT RIGHT HOME END "
    "PAGEUP PAGEDOWN F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12 SHIFT CTRL ALT META "
    "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9"
).split()}
GLOBALS |= {f"JOY_BUTTON_{i}" for i in range(24)}


def strip(text: str) -> str:
    """Comments and string literals replaced by spaces, length preserved."""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c == "#":
            j = text.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        elif text.startswith('"""', i):
            j = text.find('"""', i + 3)
            j = n if j < 0 else j + 3
            out.append(" " * (j - i))
            i = j
        elif c in "\"'":
            q, j = c, i + 1
            while j < n:
                if text[j] == "\\":
                    j += 2
                    continue
                if text[j] == q:
                    j += 1
                    break
                j += 1
            out.append(" " * (j - i))
            i = j
        else:
            out.append(c)
            i += 1
    return "".join(out)


def strip_comments(text: str) -> str:
    """Comments blanked, string literals kept (for the `+` check, which needs them)."""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c == "#":
            j = text.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        elif text.startswith('"""', i):
            j = text.find('"""', i + 3)
            j = n if j < 0 else j + 3
            out.append(text[i:j])
            i = j
        elif c in "\"'":
            q, j = c, i + 1
            while j < n:
                if text[j] == "\\":
                    j += 2
                    continue
                if text[j] == q:
                    j += 1
                    break
                j += 1
            out.append(text[i:j])
            i = j
        else:
            out.append(c)
            i += 1
    return "".join(out)


def string_spans(text: str) -> list[tuple[int, int]]:
    """Every string literal as (start, end), read left to right so quotes pair correctly."""
    spans, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c == "#":
            j = text.find("\n", i)
            i = n if j < 0 else j
        elif text.startswith('"""', i):
            j = text.find('"""', i + 3)
            j = n if j < 0 else j + 3
            spans.append((i, j))
            i = j
        elif c in "\"'":
            j = i + 1
            while j < n and text[j] != c:
                j += 2 if text[j] == "\\" else 1
            j = j + 1 if j < n else n
            spans.append((i, j))
            i = j
        else:
            i += 1
    return spans


def split_args(s: str) -> list[str]:
    if not s.strip():
        return []
    depth, cur, args = 0, "", []
    for ch in s:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            args.append(cur)
            cur = ""
        else:
            cur += ch
    args.append(cur)
    return args


def signatures(text: str) -> dict[str, list[tuple[int, int, int]]]:
    """name -> [(required, total, line)] over every declaration in one file."""
    out: dict[str, list[tuple[int, int, int]]] = {}
    for m in re.finditer(r"^\s*(?:static\s+)?func\s+(\w+)\s*\((.*?)\)\s*(?:->\s*[^:\n]+)?:",
                         text, re.M | re.S):
        parts = split_args(m.group(2))
        req = sum(1 for p in parts if "=" not in p)
        out.setdefault(m.group(1), []).append((req, len(parts), text[: m.start()].count("\n") + 1))
    return out


def call_args(text: str, start: int):
    """The argument text of a call whose '(' ends at start, and its offset."""
    depth, j = len("("), start
    while j < len(text) and depth:
        if text[j] in "([{":
            depth += 1
        elif text[j] in ")]}":
            depth -= 1
        j += 1
    return text[start:j - 1]


def preloads(text: str) -> dict[str, Path]:
    out = {}
    for m in re.finditer(r'const\s+(\w+)\s*=\s*preload\("res://([^"]+\.gd)"\)', text):
        out[m.group(1)] = ROOT / "scripts" / m.group(2) if not m.group(2).startswith("scripts/") else ROOT / m.group(2)
    return out


def declared(text: str) -> set[str]:
    names = set()
    for pat in (r"^\s*const\s+(\w+)", r"^\s*(?:static\s+)?var\s+(\w+)", r"^\s*(?:static\s+)?func\s+(\w+)",
                r"^class\s+(\w+)", r"^\s*enum\s+(\w+)"):
        names |= set(re.findall(pat, text, re.M))
    names |= set(re.findall(r"\bfor\s+(\w+)", text))
    for enum_body in re.findall(r"\benum\s*\{([^}]*)\}", text):
        names |= {v.strip() for v in enum_body.split(",") if v.strip()}
    names |= set(re.findall(r"\bvar\s+(\w+)", text))
    return names


def inherited(path: Path, cache: dict[Path, str], seen: set[Path] | None = None) -> set[str]:
    """Constants and vars a file gets from its `extends "res://..."` chain."""
    seen = seen or set()
    if path in seen or not path.exists():
        return set()
    seen.add(path)
    raw = cache_text(path, cache)
    names = declared(strip(raw))
    # the path is a string literal, so it has to be read before stripping blanks it out
    m = re.search(r'^extends\s+"res://([^"]+\.gd)"', raw, re.M)
    if m:
        names |= inherited(ROOT / m.group(1), cache, seen)
    return names


def check_file(path: Path, cache: dict[Path, str]) -> list[str]:
    problems = []
    raw = path.read_text()
    text = strip(raw)
    sigs = signatures(text)

    def arity(name: str, args_text: str, at: int, declared_in: Path):
        n = len(split_args(args_text))
        # this file's own signatures are already parsed above; a cache keyed by path would
        # go stale the moment a caller re-checks the same path with new text (the tests do)
        variants = sigs.get(name, []) if declared_in == path else cache_sigs(declared_in).get(name, [])
        if variants and n > max(t for _, t, _ in variants):
            line = text[:at].count("\n") + 1
            problems.append(f"{path}:{line}: {name}() takes at most "
                            f"{max(t for _, t, _ in variants)} argument(s), called with {n}")

    # 1. calls to this file's own functions
    for name, variants in sigs.items():
        for m in re.finditer(r"(?<![\w.])" + re.escape(name) + r"\s*\(", text):
            if text[max(0, m.start() - 5):m.start()].rstrip().endswith("func"):
                continue
            arity(name, call_args(text, m.end()), m.start(), path)

    # 2. calls on a preloaded .gd alias
    for alias, target in preloads(raw).items():
        if not target.exists():
            continue
        for m in re.finditer(re.escape(alias) + r"\.(\w+)\s*\(", text):
            arity(m.group(1), call_args(text, m.end()), m.start(), target)

    # 3. a `+` that can only be a string and a number (`"week " + 5`, `"x" + int(y)`)
    lit = strip_comments(raw)
    for start, end in string_spans(lit):
        after = lit[end:end + 40]
        if re.match(r"\s*\+\s*(?:int|float)\s*\(|\s*\+\s*\d", after):
            line = lit[:start].count("\n") + 1
            problems.append(f"{path}:{line}: string + number (a '+' between a literal and a "
                            f"number does not parse: use % formatting)")
    for m in re.finditer(r"\b(?:int|float)\s*\([^()]*\)\s*\+\s*\"", lit):
        line = lit[: m.start()].count("\n") + 1
        problems.append(f"{path}:{line}: number + string (a '+' between a number and a "
                        f"literal does not parse: use % formatting)")

    # 4. undeclared SCREAMING_CASE identifiers
    known = declared(text) | inherited(path, cache)
    for alias, target in preloads(raw).items():
        if target.exists():
            known |= {f"{alias}.{n}" for n in declared(strip(cache_text(target, cache)))}
    for m in re.finditer(r"(?<![\w.])([A-Z][A-Z0-9_]{2,})\b", text):
        name = m.group(1)
        if name in known or name in GLOBALS:
            continue
        if text[max(0, m.start() - 1):m.start()] == ".":
            continue
        line = text[:m.start()].count("\n") + 1
        problems.append(f"{path}:{line}: '{name}' is used but not declared in this file")
    return problems


_sigcache: dict[Path, dict] = {}


def cache_text(path: Path, cache: dict) -> str:
    if path not in cache:
        cache[path] = path.read_text()
    return cache[path]


def cache_sigs(path: Path) -> dict:
    if path not in _sigcache:
        _sigcache[path] = signatures(strip(cache_text(path, _textcache)))
    return _sigcache[path]


_textcache: dict[Path, str] = {}


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--list", action="store_true", help="print the files read")
    args = ap.parse_args(argv)

    files = sorted([p for d in ("scripts", "tests", "tools") for p in (ROOT / d).rglob("*.gd")
                    if "results" not in p.parts])
    if args.list:
        for p in files:
            print(p.relative_to(ROOT))
    problems = []
    for p in files:
        try:
            problems += check_file(p, _textcache)
        except Exception as exc:                     # a checker that crashes must say so
            problems.append(f"{p}: check failed: {exc}")
    for line in problems:
        print(line)
    print(f"gd_arity_check: {len(files)} file(s), {len(problems)} finding(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
