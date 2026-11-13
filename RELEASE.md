# The Violence v1.3.0 — Windows build update (2026-10-30)

Rebuilt from the current tree (includes the test range scrolling fix) with the
**official Godot 4.7.2 Windows export template** and the 4.7.2 editor, not the
from-source build described below (release assets are reachable again, so the
90-minute engine compile is no longer needed):

```sh
# one time: install the 4.7.2 templates from godot-builds into ~/.local/share/godot/export_templates/4.7.2.stable/
godot --headless --path . --export-release "Windows Desktop" release/TheViolence.exe
```

```
release/TheViolence.exe   158.3 MiB (166,001,600 bytes)
SHA-256  7f4f6def67193e59dd968f159a370acbd68017839284da7fe64fef82bbe9d8f4
```

Checked: valid x86-64 GUI PE with a 54 MiB `pck` section; the embedded pack boots
under the 4.7.2 runtime for 300 frames with no script errors. `tools/inspect_pck.py` only
reads pack format 2 (Godot 4.4), so `--verify` does not work on this build yet. Not run on
Windows hardware, and unsigned. The stock template carries no game icon or version block
(rcedit is Windows-only); the 4.4.1 build below compiled them in.

---

# The Violence v1.2.1 — Windows release

```
release/TheViolence.exe      107 MiB      one file, nothing beside it
```

Double-click it, or run `Play.bat`. There is no installer, no Godot install, no
`data.pck`, no DLLs to copy, no runtime to download. The engine, the compiled
GDScript, every SVG, every sound and all eighteen cutscene videos are inside
that one file.

- **Machine:** x86-64, Windows GUI subsystem
- **Runs on:** Windows 10 and 11 (64-bit). The renderer is `gl_compatibility`,
  so the machine needs an OpenGL 3.3 driver — Intel HD 4000 and newer, any
  AMD/NVIDIA card from the last decade.
- **Imports:** 33 libraries, every one of them a stock Windows DLL
  (`kernel32`, `user32`, `gdi32`, `dwrite`, `avrt`, the UCRT forwarders…).
  Nothing is loaded from the game folder. `tools/inspect_exe.py` prints the list.
- **Unsigned.** SmartScreen will show "Windows protected your PC" on first run
  until the exe is code-signed; *More info → Run anyway* starts it.

## What is in it

`tools/inspect_pck.py release/TheViolence.exe --verify` reads the pack back out
of the executable, without Godot, and checks every file against its stored MD5:

| | |
| --- | --- |
| files | 498 |
| payload | 42.8 MiB |
| verified | all files match |
| textures (`*.ctex`) | 124 |
| sounds (`*.sample`) | 34 |
| cutscenes (`*.ogv`) | 18 |
| compiled scripts (`*.gdc`) | 76 |

The pack is written into the PE `pck` section, so the game data sits inside the
image rather than trailing the file; both the section and the end-of-file
trailer resolve. `tests/`, `tools/`, the markdown sources and the Remotion
sources under `cinematics/` are excluded by the preset's `exclude_filter`.

## How it was built

The environment this was produced in cannot reach `github.com` release assets,
so the Godot editor and the official Windows export template could not simply be
downloaded. `tools/build_windows_exe.sh` builds both from the engine source
instead:

1. **Engine source** — `godotengine/godot` 4.4.1-stable (the version
   `project.godot` targets) via `codeload.github.com`.
2. **Headless Linux editor** — `scons platform=linuxbsd target=editor
   x11=no wayland=no alsa=no pulseaudio=no dbus=no ... lto=none`. About 46
   minutes on two cores; it is only used to run the export.
3. **Windows export template** — `scons platform=windows target=template_release
   tools=no arch=x86_64 vulkan=no d3d12=no opengl3=yes lto=none`,
   cross-compiled with zig's bundled clang + mingw-w64 sysroot
   (`pip install ziglang`). No MinGW installation, no apt packages.
4. **Branding compiled in, not patched on** — `tools/patch_rc.py` writes the
   game's icon (`icon.ico`, seven sizes) and its version block
   (`The Violence 1.2.1.0`) into `platform/windows/godot_res.rc` before the
   template is linked, so no rcedit pass is needed at export time.
5. **Export** — the editor imports the project and runs
   `--export-release "Windows Desktop" release/TheViolence.exe` with the
   preset's `binary_format/embed_pck=true`, which appends the pack.

Reproduce with:

```sh
tools/build_windows_exe.sh            # ~90 minutes on two cores
JOBS=8 tools/build_windows_exe.sh     # on a real machine
```

Requires `python3` (for `venv`), `curl`, `tar` and a C/C++ toolchain for the
editor build. Everything else is installed into `.build/` (git-ignored).

## Verification done here

- `tools/inspect_exe.py` — PE machine, subsystem, section list, import table,
  resource types (`RT_ICON`, `RT_GROUP_ICON`, `RT_VERSION`, `RT_MANIFEST`).
- `tools/inspect_pck.py --verify` — 498 files, every MD5 matches, no test or
  documentation paths.
- The exported pack was extracted from the exe and run with a Godot 4.4.1
  runtime: `godot --headless --main-pack theviolence.pck --quit-after 600`
  boots the game and runs 600 frames with no script errors — the same pack the
  Windows binary loads.
- `tests/_check.gd` loads every script in the project: clean.

**Not** verified here: an actual run on Windows hardware — the build host is
Linux and no Windows machine or emulator is available. The engine layer is the
only untested part; the game data that boots is byte-identical to the pack that
was exercised above.

## Where the file lives

`release/TheViolence.exe` is in this working tree but is **not committed**: GitHub
refuses any file larger than 100 MB, and this one is 107 MiB, so committing it
would make the branch unpushable. Publish it as a GitHub Release asset (or move
it to Git LFS) rather than into the tree — `release/*` is git-ignored for that
reason.

## Checksums

```
112,632,384 bytes
SHA-256  4f6b946b1e81e1697f4eaf51844c54e2c1b272406d27ea288d354f4eaa5cbdf8
```

Exporting twice from the same tree produced byte-identical files.

One warning is expected and harmless: *"Resources Modification: Could not start
rcedit executable"*. rcedit is a Windows-only icon/version patcher; this build
does not need it because the icon and version block are already compiled into
the template (step 4 above).
