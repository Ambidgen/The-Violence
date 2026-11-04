#!/usr/bin/env python3
"""List what is inside a Godot 4 .pck, or inside the pack embedded at the end of an .exe.

The Windows release of The Violence is a single file: the Godot runtime export
template with the game pack appended to it (``binary_format/embed_pck=true`` in
``export_presets.cfg``). This reads that pack back out without a Godot binary, so
a release can be audited on any machine:

    python3 tools/inspect_pck.py release/TheViolence.exe            # summary
    python3 tools/inspect_pck.py release/TheViolence.exe --list     # every path
    python3 tools/inspect_pck.py release/TheViolence.exe --extract /tmp/pck

Format reference: ``core/io/file_access_pack.cpp`` in the engine source. An
embedded pack ends with the magic, the pack size (u64) and the magic again, so
the pack can be located from the last 16 bytes of the file.

No third-party packages; Python 3.8+.
"""

from __future__ import annotations

import argparse
import hashlib
import struct
import sys
import zlib
from pathlib import Path

MAGIC = b"GDPC"
HEADER = struct.Struct("<4sIIIIIQ")  # magic, pack format, major, minor, patch, flags, file_base
PACK_FORMAT_VERSION = 2


def find_pack(data: bytes) -> int:
    """Return the offset where a .pck starts, or ``-1``.

    A plain .pck starts at 0. An embedded one is found from the trailer:
    ``... <pack bytes> <magic> <u64 size> <magic>``.
    """
    if data[:4] == MAGIC:
        return 0
    if len(data) < 16 or data[-4:] != MAGIC:
        return -1
    (size,) = struct.unpack_from("<Q", data, len(data) - 12)
    start = len(data) - 12 - size
    if start >= 0 and data[start : start + 4] == MAGIC:
        return start
    return -1


def read_pack(data: bytes, start: int) -> dict:
    if data[start : start + 4] != MAGIC:
        raise ValueError("no GDPC header at offset %d" % start)
    magic, fmt, major, minor, patch, flags, file_base = HEADER.unpack_from(data, start)
    if fmt != PACK_FORMAT_VERSION:
        raise ValueError("unsupported pack format %d (expected %d)" % (fmt, PACK_FORMAT_VERSION))
    if flags & 1:
        raise ValueError("pack directory is encrypted; this tool does not hold the key")

    pos = start + HEADER.size + 16 * 4  # 16 reserved u32
    if flags & 2:  # PACK_REL_FILEBASE: offsets are relative to the pack start
        file_base += start
    (count,) = struct.unpack_from("<I", data, pos)
    pos += 4
    files = []
    for _ in range(count):
        (path_len,) = struct.unpack_from("<I", data, pos)
        pos += 4
        # Paths are padded to 4 bytes; the stored length covers the padding.
        path = data[pos : pos + path_len].split(b"\0", 1)[0].decode("utf-8", "replace")
        pos += path_len
        offset, size = struct.unpack_from("<QQ", data, pos)
        pos += 16
        digest = data[pos : pos + 16]
        pos += 16
        (file_flags,) = struct.unpack_from("<I", data, pos)
        pos += 4
        files.append(
            {
                "path": path,
                "offset": offset,
                "size": size,
                "md5": digest.hex(),
                "flags": file_flags,
            }
        )
    return {
        "version": "%d.%d.%d" % (major, minor, patch),
        "start": start,
        "file_base": file_base,
        "end": len(data),
        "files": files,
    }


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("file", type=Path, help=".pck file or an exported executable")
    ap.add_argument("--list", action="store_true", help="print every path and size")
    ap.add_argument("--extract", type=Path, metavar="DIR", help="write the contents to DIR")
    ap.add_argument("--verify", action="store_true", help="check every file against its stored MD5")
    args = ap.parse_args(argv)

    data = args.file.read_bytes()
    start = find_pack(data)
    if start < 0:
        print("%s: no Godot pack found (not a .pck, and no embedded pack trailer)" % args.file, file=sys.stderr)
        return 1
    pack = read_pack(data, start)
    files = pack["files"]
    payload = sum(f["size"] for f in files)
    print("%s" % args.file)
    print("  embedded at   %d (0x%x), %d bytes of pack" % (start, start, len(data) - start))
    print("  made with     Godot %s" % pack["version"])
    print("  files         %d, %.1f MiB of payload" % (len(files), payload / (1024 * 1024)))

    if args.list or args.extract or args.verify:
        base = pack["file_base"]
        flags_note = {0: "", 1: " (removal)", 2: " (encrypted)"}
        ok = True
        for f in sorted(files, key=lambda x: x["path"]):
            blob = data[base + f["offset"] : base + f["offset"] + f["size"]]
            if args.verify and f["flags"] == 0:
                got = hashlib.md5(blob).digest()
                if got != bytes.fromhex(f["md5"]):
                    ok = False
                    print("  BAD MD5 %s" % f["path"], file=sys.stderr)
            if args.list:
                print("  %9d  %s%s" % (f["size"], f["path"], flags_note.get(f["flags"], "")))
            if args.extract and f["flags"] == 0:
                target = args.extract / f["path"].replace("res://", "", 1)
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(blob)
        if args.verify:
            print("  md5           %s" % ("all files match" if ok else "MISMATCH"))
            return 0 if ok else 1
    else:
        biggest = sorted(files, key=lambda x: -x["size"])[:8]
        print("  largest:")
        for f in biggest:
            print("  %9d  %s" % (f["size"], f["path"]))
    if args.extract:
        print("  extracted to  %s" % args.extract)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
