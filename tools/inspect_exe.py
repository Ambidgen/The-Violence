#!/usr/bin/env python3
"""What a Windows release actually links against, and what it carries.

``TheViolence.exe`` is meant to be one file with nothing beside it, so the two
things worth checking are (a) that the only imported libraries are the ones
Windows itself always has, and (b) that the icon and version block are in the
binary, not patched in later by rcedit.

    python3 tools/inspect_exe.py release/TheViolence.exe

Prints: PE kind and subsystem, size, section list, imported DLLs, and the
resource types present (RT_ICON, RT_GROUP_ICON, RT_VERSION, RT_MANIFEST).

No third-party packages; Python 3.8+.
"""

from __future__ import annotations

import struct
import sys
from pathlib import Path

MACHINES = {0x014C: "x86 (32-bit)", 0x8664: "x86-64", 0xAA64: "ARM64"}
SUBSYSTEMS = {1: "native", 2: "Windows GUI", 3: "console"}
RESOURCE_TYPES = {
    1: "RT_CURSOR",
    2: "RT_BITMAP",
    3: "RT_ICON",
    4: "RT_MENU",
    5: "RT_DIALOG",
    6: "RT_STRING",
    9: "RT_ACCELERATOR",
    10: "RT_RCDATA",
    12: "RT_GROUP_CURSOR",
    14: "RT_GROUP_ICON",
    16: "RT_VERSION",
    24: "RT_MANIFEST",
}
# Every DLL a stock Windows 10/11 install always has. Anything outside this list
# would mean the exe needs a file shipped next to it.
SYSTEM_DLLS = {
    "kernel32.dll", "user32.dll", "gdi32.dll", "advapi32.dll", "shell32.dll", "ole32.dll",
    "oleaut32.dll", "shlwapi.dll", "ws2_32.dll", "wsock32.dll", "winmm.dll", "dsound.dll",
    "dinput8.dll", "imm32.dll", "bcrypt.dll", "crypt32.dll", "avrt.dll", "dwmapi.dll",
    "dwrite.dll", "wbemuuid.dll", "ntdll.dll", "iphlpapi.dll", "psapi.dll", "dbghelp.dll",
    "version.dll", "sapi.dll", "d3d9.dll", "d3d11.dll", "d3d12.dll", "dxgi.dll", "opengl32.dll",
    "setupapi.dll", "uxtheme.dll", "comdlg32.dll", "comctl32.dll", "msvcrt.dll", "wininet.dll",
    "secur32.dll", "mpr.dll", "netapi32.dll", "winhttp.dll", "rpcrt4.dll", "powrprof.dll",
    "userenv.dll", "shcore.dll", "dcomp.dll", "propsys.dll", "dnsapi.dll", "wlclient.dll",
    "ucrtbase.dll",
}
# The UCRT forwarders: always present on Windows 10 and 11 (and on 7/8 with the
# Universal CRT update). A mingw build links these instead of a private CRT.
SYSTEM_DLL_PREFIXES = ("api-ms-win-", "ext-ms-win-")


class PE:
    def __init__(self, data: bytes):
        self.data = data
        if data[:2] != b"MZ":
            raise ValueError("not an MZ executable")
        (e_lfanew,) = struct.unpack_from("<I", data, 0x3C)
        if data[e_lfanew : e_lfanew + 4] != b"PE\0\0":
            raise ValueError("no PE signature")
        coff = e_lfanew + 4
        (self.machine, self.sections_n, self.timestamp, _, _, self.opt_size,
         self.characteristics) = struct.unpack_from("<HHIIIHH", data, coff)
        opt = coff + 20
        (magic,) = struct.unpack_from("<H", data, opt)
        if magic not in (0x10B, 0x20B):
            raise ValueError("unknown optional header magic 0x%x" % magic)
        self.pe64 = magic == 0x20B
        self.subsystem = struct.unpack_from("<H", data, opt + (68 if self.pe64 else 68))[0]
        self.image_base = struct.unpack_from("<Q" if self.pe64 else "<I", data, opt + 24)[0]
        dd_off = opt + (112 if self.pe64 else 96)
        self.dirs = []
        for i in range(16):
            rva, size = struct.unpack_from("<II", data, dd_off + 8 * i)
            self.dirs.append((rva, size))
        self.sections = []
        sec = opt + self.opt_size
        for i in range(self.sections_n):
            name = data[sec + 40 * i : sec + 40 * i + 8].rstrip(b"\0").decode("ascii", "replace")
            vsize, vaddr, rawsize, rawptr = struct.unpack_from("<IIII", data, sec + 40 * i + 8)
            self.sections.append((name, vaddr, vsize, rawptr, rawsize))

    def off(self, rva: int) -> int:
        # `vsize` is the size the loader maps; the raw size can be larger (a pack
        # section stores 40 MB of file bytes behind an 8-byte `.pck` header).
        for _name, vaddr, vsize, rawptr, rawsize in self.sections:
            span = vsize if vsize else rawsize
            if vaddr <= rva < vaddr + span:
                return rawptr + (rva - vaddr)
        raise ValueError("rva 0x%x is not inside any section" % rva)

    def cstr(self, rva: int) -> str:
        o = self.off(rva)
        end = self.data.index(b"\0", o)
        return self.data[o:end].decode("ascii", "replace")

    def imports(self) -> list[str]:
        rva, size = self.dirs[1]
        if not rva:
            return []
        names = []
        o = self.off(rva)
        while True:
            (oft, _ts, _fc, name_rva, _ft) = struct.unpack_from("<IIIII", self.data, o)
            if not (oft or name_rva):
                break
            names.append(self.cstr(name_rva))
            o += 20
        return names

    def resource_types(self) -> list[int]:
        rva, size = self.dirs[2]
        if not rva:
            return []
        base = self.off(rva)
        types = []
        named, ids = struct.unpack_from("<HH", self.data, base + 12)
        for i in range(named + ids):
            (name_or_id, offset) = struct.unpack_from("<II", self.data, base + 16 + 8 * i)
            types.append(name_or_id & 0xFFFF)
        return sorted(types)


def is_system(dll: str) -> bool:
    return dll in SYSTEM_DLLS or dll.startswith(SYSTEM_DLL_PREFIXES)


def main(argv: list[str]) -> int:
    if not argv:
        print(__doc__)
        return 2
    path = Path(argv[0])
    data = path.read_bytes()
    try:
        pe = PE(data)
    except ValueError as exc:
        print("%s: %s" % (path, exc), file=sys.stderr)
        return 1

    print("%s  (%.1f MiB)" % (path, len(data) / (1024 * 1024)))
    print("  machine      %s" % MACHINES.get(pe.machine, hex(pe.machine)))
    print("  subsystem    %s" % SUBSYSTEMS.get(pe.subsystem, pe.subsystem))
    print("  image base   0x%x" % pe.image_base)
    print("  sections     %s" % ", ".join("%s(%dK)" % (s[0], s[4] // 1024) for s in pe.sections))

    dlls = sorted({d.lower() for d in pe.imports()})
    print("  imports      %d DLLs" % len(dlls))
    for d in dlls:
        print("    %-34s %s" % (d, "" if is_system(d) else "<- not a stock Windows library"))
    extra = [d for d in dlls if not is_system(d)]
    if extra:
        print("  NOTE         this exe expects %s next to it" % ", ".join(extra))

    types = pe.resource_types()
    print("  resources    %s" % (", ".join(RESOURCE_TYPES.get(t, "id %d" % t) for t in types) or "none"))
    missing = [n for t, n in ((3, "RT_ICON"), (14, "RT_GROUP_ICON"), (16, "RT_VERSION")) if t not in types]
    if missing:
        print("  NOTE         no %s" % ", ".join(missing))
    return 0 if not extra else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
