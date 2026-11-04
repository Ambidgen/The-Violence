#!/usr/bin/env python3
"""
gd47_check.py - static checks for The Violence against Godot 4.7.x.

The engine's 4.7 GDScript analyzer is stricter than 4.4's. This is the audit that
was run over the tree for the 1.2.2 pass; it needs no Godot binary, so it can run
in CI or in a sandbox with no engine. It is a *linter*, not a compiler: it finds
the shapes that have broken this project, not every possible parse error. Run the
engine's own `--check-only` (or tests/_check.gd) alongside it.

    python3 tools/gd47_check.py            # check scripts/, tests/, tools/
    python3 tools/gd47_check.py scripts/   # or a subtree
    python3 tools/gd47_check.py --quiet    # only print problems

Checks
  1. bracket balance          - with strings and comments stripped out
  2. duplicate members        - const/var/enum/signal/func declared twice at class scope
                                (this is the damage a bad merge leaves behind)
  3. indentation              - GDScript requires tabs; leading spaces are a parse error
  4. untyped `:=` inference   - `var x := <untyped receiver>.method()` has no static type
                                and 4.7 rejects it (the 4.4 code relied on it twice)
  5. removed/renamed APIs     - the GDScript-incompatible changes from 4.4 -> 4.7
  6. statements in class scope- code that escaped its function after a bad merge
  7. indented members         - a class-scope `var`/`const` pushed under a comment by a bad
                                edit, which makes every later use of it undeclared

Exit code 0 = clean, 1 = problems found.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# ---------------------------------------------------------------- check 5 data
# GDScript-incompatible (source-breaking) API changes, Godot 4.4 -> 4.7.
# name -> (kind, note, replacement or "" if removed)
BREAKING_APIS = {
    "instance_reset_physics_interpolation": ("call", "removed in 4.5", ""),
    "instance_set_interpolated":            ("call", "removed in 4.5", ""),
    "get_rpc_config":                       ("call", "renamed in 4.5", "get_node_rpc_config"),
    "UPDATE_WIDTH_IN_PERCENT":              ("const", "renamed in 4.7", "UPDATE_WIDTH_UNIT"),
    "width_in_percent":                     ("arg",   "renamed in 4.7", "width_unit"),
    "height_in_percent":                    ("arg",   "renamed in 4.7", "height_unit"),
    "size_in_percent":                      ("arg",   "replaced in 4.5", "width_in_percent/height_in_percent"),
    "type_exists":                          ("call", "deprecated in 4.7", ""),
    "accessibility_live":                   ("prop", "type changed in 4.7", "AccessibilityServer.AccessibilityLiveMode"),
}

# Variant methods whose return type is known even when the receiver is untyped.
VARIANT_SAFE_METHODS = {
    "empty", "size", "has", "keys", "values", "duplicate", "get", "append", "erase",
    "clear", "is_empty", "to_upper", "to_lower", "strip_edges", "substr", "find",
    "split", "begins_with", "ends_with", "replace", "contains", "trim_prefix",
    "trim_suffix", "to_int", "to_float", "is_valid_float", "is_valid_int", "length",
    "distance_to", "length_squared", "distance_squared_to", "normalized", "angle",
    "dot", "cross", "lerp", "round", "abs", "clamp", "max", "min", "new", "instance",
    "instantiate", "stringify", "parse_string", "to_html", "get_base_dir", "get_file",
    "path_join", "is_absolute_path", "grow", "has_point", "intersects", "encloses",
    "get_center", "count", "all", "any", "filter", "map", "reduce", "slice", "sort",
    "sort_custom", "front", "back", "pop_back", "pop_front", "push_back", "push_front",
    "insert", "remove_at", "fill", "resize", "is_read_only", "assign",
}

# Global functions with a declared return type.
TYPED_GLOBALS = {
    "int", "float", "str", "bool", "String", "StringName", "NodePath", "Vector2",
    "Vector2i", "Vector3", "Vector4", "Color", "Rect2", "Rect2i", "Transform2D",
    "Array", "Dictionary", "PackedVector2Array", "PackedFloat32Array",
    "PackedInt32Array", "PackedInt64Array", "PackedByteArray", "PackedStringArray",
    "PackedColorArray", "round", "roundi", "floor", "floori", "ceil", "ceili",
    "abs", "absi", "sign", "signf", "maxi", "mini", "maxf", "minf", "clamp",
    "clampi", "clampf", "snapped", "snappedf", "snappedi", "sqrt", "pow", "exp",
    "log", "sin", "cos", "tan", "atan", "atan2", "deg_to_rad", "rad_to_deg",
    "fmod", "fposmod", "posmod", "wrap", "wrapi", "wrapf", "lerp", "lerpf",
    "lerp_angle", "smoothstep", "move_toward", "rotate_toward", "angle_difference",
    "absf", "is_equal_approx", "is_zero_approx", "is_finite", "is_inf", "is_nan",
    "is_same", "is_instance_valid", "len", "range", "load", "preload", "type",
    "typeof", "error_string", "linear_to_db", "db_to_linear", "str_to_var",
    "var_to_str", "nearest_po2", "randf", "randi", "randf_range", "randi_range",
}

# A top-level line is allowed to start with one of these.
CLASS_SCOPE_OK = re.compile(
    r"^(@\w+|const |var |enum |signal |func |class |class_name |extends |static |#|tool|$)")


# ---------------------------------------------------------------- helpers
def strip_strings_and_comments(text: str) -> str:
    """Blank out string literals and comments so brackets/text inside them do not
    look like code -- but keep every newline, so line numbers still line up with
    the real file. Handles GDScript escapes and triple-quoted strings."""
    out: list[str] = []
    i, n = 0, len(text)

    def blank(span: str) -> None:
        # preserve newlines so line numbering survives
        out.append('""' + ("\n" * span.count("\n")))

    while i < n:
        ch = text[i]
        # triple-quoted string (can span lines)
        if text.startswith('"""', i):
            j = text.find('"""', i + 3)
            j = n if j == -1 else j + 3
            blank(text[i:j])
            i = j
            continue
        # raw string r"..." (4.7 syntax)
        if ch == "r" and i + 1 < n and text[i + 1] in "\"'":
            q = text[i + 1]
            j = i + 2
            while j < n and text[j] != q:
                j += 2 if text[j] == "\\" else 1
            blank(text[i:min(j + 1, n)])
            i = min(j + 1, n)
            continue
        if ch in "\"'":
            j = i + 1
            while j < n:
                if text[j] == "\\":
                    j += 2
                    continue
                if text[j] == ch or text[j] == "\n":
                    break
                j += 1
            blank(text[i:min(j + 1, n)])
            i = min(j + 1, n)
            continue
        if ch == "#":
            j = text.find("\n", i)
            i = n if j == -1 else j
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def declared_return_types(text: str) -> dict[str, str | None]:
    """func name -> declared return type, or None when the function omits `->`."""
    out: dict[str, str | None] = {}
    for m in re.finditer(
            r"^\t?(?:static\s+)?func\s+(\w+)\s*\(([^)]*)\)\s*(->\s*([\w\[\]:.]+))?\s*:",
            text, re.M):
        out[m.group(1)] = m.group(4)
    return out


def untyped_members(text: str) -> set[str]:
    """Members declared `var foo` with no `: Type` and no `:=` initializer."""
    out: set[str] = set()
    for m in re.finditer(r"^(?:@\w+\s+)?(?:static\s+)?var\s+(\w+)\s*(?::\s*[\w\[\].]+\s*)?=\s*([^\n]*)",
                         text, re.M):
        name, init = m.group(1), (m.group(2) or "")
        # `:=` gives an inferred type; `= value` on a bare var does not help 4.7
        if init.lstrip().startswith("="):
            out.add(name)
        elif m.group(0).count(":=") == 0 and m.group(0).rstrip().endswith("="):
            out.add(name)
    # `var foo` with nothing after it at all
    for m in re.finditer(r"^(?:@\w+\s+)?(?:static\s+)?var\s+(\w+)\s*$", text, re.M):
        out.add(m.group(1))
    return out


# ---------------------------------------------------------------- checks
def check_file(path: Path, quiet: bool) -> list[str]:
    problems: list[str] = []
    raw = path.read_text(errors="replace")
    lines = raw.splitlines()

    code = strip_strings_and_comments(raw)
    code_lines = code.splitlines()

    # -- 3. indentation (on stripped text: GDScript requires tabs) ------------
    # Done on `code_lines` so that prose inside a multi-line string (the manual
    # text in front.gd, for one) is not mistaken for indented code.
    for i, line in enumerate(code_lines, 1):
        if line.strip() and line[0] == " ":
            problems.append(f"{path}:{i}: leading whitespace (GDScript requires tabs)")
            break

    # -- 1. bracket balance ---------------------------------------------------
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[tuple[str, int]] = []
    for idx, ch in enumerate(code):
        if ch in "([{":
            stack.append((ch, idx))
        elif ch in ")]}":
            if not stack or stack[-1][0] != pairs[ch]:
                ln = code.count("\n", 0, idx) + 1
                problems.append(f"{path}:{ln}: unbalanced '{ch}'")
                break
            stack.pop()
    else:
        if stack:
            ln = code.count("\n", 0, stack[-1][1]) + 1
            problems.append(f"{path}:{ln}: unclosed '{stack[-1][0]}'")

    # -- 2. duplicate members + 6. class-scope statements ---------------------
    # Both are line-based, so walk the *stripped* code and track bracket depth:
    # a line that opens a bracket continues onto the next, and GDScript allows
    # continuation inside (), [] and {} (that is what puts `}` at column 0).
    code_lines = code.splitlines()
    pairs = {")": "(", "]": "[", "}": "{"}
    depth = 0
    seen: dict[tuple[str, str], int] = {}
    for i, line in enumerate(code_lines, 1):
        if not line.strip():
            continue
        continuation = depth > 0
        # update depth for the *next* line
        for ch in line:
            if ch in "([{":
                depth += 1
            elif ch in ")]}":
                depth = max(0, depth - 1)
        if continuation or line[:1] in ("\t", " "):
            continue
        m = re.match(r"(?:(?:@\w+)\s+)?(?:static\s+)?(const|var|enum|signal|class|func)\s+(\w+)", line)
        if m:
            key = (m.group(1), m.group(2))
            if key in seen:
                problems.append(
                    f"{path}:{i}: duplicate {m.group(1)} '{m.group(2)}' (already at line {seen[key]})")
            else:
                seen[key] = i
            continue
        if not CLASS_SCOPE_OK.match(line):
            problems.append(f"{path}:{i}: statement at class scope (merge damage?): {line.strip()[:60]}")

    # -- 7. members indented out of scope -------------------------------------
    # A `var` at class scope that is indented under a comment reads as a local of nothing:
    # every use of it later in the file is "Identifier not declared", the script does not
    # compile, and every script that preloads it takes the fault too (main.gd's `_perf` and
    # `_run_start`, 2026-11-02: ops_ui.gd, the walk, and the game were all unloadable from
    # an edit that added two spaces of indent). Members of an inner `class` are legal, and
    # so are locals inside a `func`; anything else indented is a mistake.
    blocks: list[tuple[int, str]] = []          # (indent, "func"|"class"|"block")
    bdepth = 0
    stmt = ""                                   # the whole statement, across continuations
    stmt_ind = 0
    for i, line in enumerate(code_lines, 1):
        if not line.strip():
            continue
        cont = bdepth > 0
        if cont:
            stmt = stmt + " " + line.strip()
        else:
            stmt = line.strip()
            stmt_ind = len(line) - len(line.lstrip("\t"))
        for ch in line:
            if ch in "([{":
                bdepth += 1
            elif ch in ")]}":
                bdepth = max(0, bdepth - 1)
        # a multi-line signature opens its block on its last line, not its first
        opener = stmt.endswith(":") and bdepth == 0
        if cont and not opener:
            continue
        while blocks and blocks[-1][0] >= stmt_ind:
            blocks.pop()
        if stmt_ind > 0:
            kinds = [k for _, k in blocks]
            if "func" not in kinds and "class" not in kinds and \
                    re.match(r"(?:@\w+\s+)?(?:static\s+)?(?:const|var|enum|signal)\s+\w+", stmt):
                problems.append(f"{path}:{i}: member indented out of class scope: {stmt[:60]}")
        if opener:
            kind = "func" if re.match(r"(?:static\s+)?func\s", stmt) else (
                "class" if stmt.startswith("class ") else "block")
            blocks.append((stmt_ind, kind))

    # -- 4. untyped `:=` inference -------------------------------------------
    rets = declared_return_types(code)
    untyped = untyped_members(code)
    for i, line in enumerate(lines, 1):
        m = re.search(r"var\s+(\w+)\s*:=\s*(.+?)\s*(?:#.*)?$", line)
        if not m:
            continue
        rhs = m.group(2).strip()
        if rhs.endswith("\\"):
            continue
        why = None
        c = re.match(r"^([A-Za-z_]\w*)\s*\(", rhs)
        if c and c.group(1) in rets and rets[c.group(1)] is None and c.group(1) not in TYPED_GLOBALS:
            why = f"`{c.group(1)}()` has no `->` return type"
        d = re.match(r"^([A-Za-z_]\w*)\.(\w+)\s*[(\[]", rhs)
        if why is None and d and d.group(1) in untyped and d.group(2) not in VARIANT_SAFE_METHODS:
            why = f"`{d.group(1)}` is untyped so `.{d.group(2)}()` has no static type"
        if why is None and re.fullmatch(r"[A-Za-z_]\w*", rhs) and rhs in untyped:
            why = f"`{rhs}` is an untyped member"
        if why:
            problems.append(f"{path}:{i}: `:=` cannot infer a type in 4.7 - {why}")

    # -- 5. removed / renamed APIs (on stripped text) -------------------------
    for i, line in enumerate(code_lines, 1):
        for name, (kind, note, repl) in BREAKING_APIS.items():
            # Only a word boundary on the right: these are usually called as
            # `RenderingServer.instance_set_interpolated()`, i.e. preceded by a
            # dot, so a `(?<![.\w])` lookbehind would miss every real use.
            if re.search(r"(?<!\w)" + re.escape(name) + r"(?!\w)", line):
                fix = f" -> use {repl}" if repl else ""
                problems.append(f"{path}:{i}: '{name}' {note}{fix}")

    return problems


def main(argv: list[str]) -> int:
    args = [a for a in argv[1:] if not a.startswith("--")]
    quiet = "--quiet" in argv
    roots = [Path(a) for a in args] if args else [ROOT / "scripts", ROOT / "tests", ROOT / "tools"]

    files: list[Path] = []
    for r in roots:
        base = r if r.is_absolute() else ROOT / r
        if base.is_file():
            files.append(base)
        else:
            files.extend(sorted(base.rglob("*.gd")))

    if not files:
        print("no .gd files found under:", ", ".join(str(r) for r in roots))
        return 1

    all_problems: list[str] = []
    for f in files:
        all_problems.extend(check_file(f, quiet))

    print(f"gd47_check: {len(files)} GDScript files scanned")
    if all_problems:
        print(f"\n{len(all_problems)} problem(s):\n")
        for p in all_problems:
            print("  " + p)
        print("\nThese are the shapes that have broken this project on 4.7. Note that")
        print("this is a linter: it does not parse GDScript. Confirm with the engine:")
        print("  godot --headless --path . -s res://tests/_check.gd")
        return 1
    print("gd47_check: clean")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
