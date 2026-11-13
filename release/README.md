# release/

`TheViolence.exe` — the single-file Windows build — belongs in this folder.

It is not committed: GitHub rejects files over 100 MB and this one is about 158 MiB.
Attach it to a GitHub Release instead.

Build it from the project with the **official Godot 4.7.2 export templates** (Editor →
Manage Export Templates, or unpack `Godot_v4.7.2-stable_export_templates.tpz` into the
export_templates folder for `4.7.2.stable`):

```sh
godot --headless --path . --export-release "Windows Desktop" build/TheViolence.exe
```

The "Windows Desktop" preset embeds the game pack in the executable and sets the icon
and version information itself. `tools/build_windows_exe.sh` (which compiles the engine
from source, for a machine that cannot download the templates) still works but is no
longer needed.

Last build: 2026-10-30 from `cycle-1C-roster` (commit 3a69d93), SHA-256
`ef570fa238de54c27e6f9ef2ec959d3b1d225a832a6920dfe6a62015e8ddc657`. Not yet run on
Windows by the build: see `../RELEASE.md`.
