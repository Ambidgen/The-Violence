#!/bin/sh
# Build release/TheViolence.exe: one self-contained Windows executable, no DLLs,
# no installer, no Godot installation on the player's machine.
#
# The sandbox this was written in cannot download github.com release assets (the
# Godot editor and the official export templates both live there), so this script
# builds the two engine binaries it needs straight from the engine source:
#
#   1. a headless Linux editor  - runs the export step (scons platform=linuxbsd)
#   2. a Windows release template - becomes the body of TheViolence.exe
#                                   (scons platform=windows, cross-compiled)
#
# Cross-compiling to Windows uses zig as the compiler driver: the `ziglang` wheel
# from PyPI ships a complete clang + mingw-w64 sysroot, so no MinGW install and no
# apt packages are required. Anything zig cannot provide (headers, import libs,
# CRT) is inside the wheel.
#
# Usage:  tools/build_windows_exe.sh          (about 90 minutes on 2 cores)
#         JOBS=8 tools/build_windows_exe.sh   (faster on a real machine)
#
# Output: release/TheViolence.exe  (~110 MB, single file)
#
# Requirements: sh, curl, tar, python3 (>=3.8), gcc/g++ for the editor build.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=${WORK:-$ROOT/.build}
GODOT_TAG=${GODOT_TAG:-4.4.1-stable}     # the version the project is tested on
JOBS=${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}
PRESET=${PRESET:-Windows Desktop}
OUT=${OUT:-$ROOT/release/TheViolence.exe}

SRC=$WORK/godot
PREFIX=$WORK/mingw
VENV=$WORK/venv

say() { printf '\n=== %s\n' "$*"; }

mkdir -p "$WORK" "$ROOT/release"

# ---------------------------------------------------------------- 1. toolchain
say "toolchain (python venv: scons + zig)"
if [ ! -x "$VENV/bin/scons" ]; then
    python3 -m venv "$VENV"
    "$VENV/bin/pip" install --quiet "scons==4.8.1" ziglang
fi
SCONS=$VENV/bin/scons
ZIGEXE=$(ls $VENV/lib/python3*/site-packages/ziglang/zig | head -1)
"$ZIGEXE" version

# ------------------------------------------------------------- 2. engine source
say "engine source ($GODOT_TAG)"
if [ ! -f "$SRC/SConstruct" ]; then
    mkdir -p "$SRC"
    curl -sSL -o "$WORK/godot.tar.gz" \
        "https://codeload.github.com/godotengine/godot/tar.gz/refs/tags/$GODOT_TAG"
    tar xzf "$WORK/godot.tar.gz" -C "$SRC" --strip-components=1
fi

# Everything the release should carry in its Windows resources. The template is
# built with this file compiled in, so no rcedit step is needed at export time.
cp "$ROOT/icon.ico" "$SRC/platform/windows/godot.ico"
"$ROOT/tools/patch_rc.py" "$SRC/platform/windows/godot_res.rc"

# zig resolves `-lIPHLPAPI` case-sensitively, mingw does not.
"$ROOT/tools/patch_rc.py" --win-libs "$SRC/platform/windows/detect.py"

# --------------------------------------------------- 3. zig -> mingw-w64 shims
say "mingw-w64 shims (zig cc/c++, zig ar, zig rc)"
mkdir -p "$PREFIX/bin"
for name in gcc g++ clang clang++ ar windres; do
    target=$PREFIX/bin/x86_64-w64-mingw32-$name
    case $name in
        gcc|clang) exec_line="$ZIGEXE cc -target x86_64-windows-gnu \"\$@\"" ;;
        g++|clang++) exec_line="$ZIGEXE c++ -target x86_64-windows-gnu \"\$@\"" ;;
        ar) exec_line="$ZIGEXE ar \"\$@\"" ;;
        windres) exec_line="$ZIGEXE rc \$RCARGS \"\$RCINPUT\"" ;;
    esac
    {
        echo '#!/bin/sh'
        echo "export ZIG_GLOBAL_CACHE_DIR=\"\${ZIG_GLOBAL_CACHE_DIR:-$WORK/zig-cache}\""
        echo "export ZIG_LOCAL_CACHE_DIR=\"\${ZIG_LOCAL_CACHE_DIR:-$WORK/zig-local}\""
        case $name in
            gcc|g++)
                # Godot probes `gcc --version` and switches to clang mode when the
                # output says "clang". Report GCC so it takes the plain mingw path.
                echo 'for a in "$@"; do'
                echo '  if [ "$a" = "--version" ]; then echo "gcc (GCC) 14.2.0"; exit 0; fi'
                echo 'done'
                ;;
            windres)
                # windres CLI -> resinator CLI (zig rc)
                cat <<'INNER'
RCARGS=""; RCINPUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --target=*) shift;;
    --include-dir=*) RCARGS="$RCARGS /i ${1#--include-dir=}"; shift;;
    --include-dir) RCARGS="$RCARGS /i $2"; shift 2;;
    -I) RCARGS="$RCARGS /i $2"; shift 2;;
    -I*) RCARGS="$RCARGS /i ${1#-I}"; shift;;
    -D) RCARGS="$RCARGS /d $2"; shift 2;;
    -D*) RCARGS="$RCARGS /d ${1#-D}"; shift;;
    -i) RCINPUT="$2"; shift 2;;
    -o) RCARGS="$RCARGS /fo $2"; shift 2;;
    --output=*) RCARGS="$RCARGS /fo ${1#--output=}"; shift;;
    -*) shift;;
    *) RCINPUT="$1"; shift;;
  esac
done
INNER
                ;;
        esac
        echo "$exec_line"
    } > "$target"
    chmod +x "$target"
done
ln -sf x86_64-w64-mingw32-gcc "$PREFIX/bin/gcc"
ln -sf x86_64-w64-mingw32-g++ "$PREFIX/bin/g++"
ln -sf x86_64-w64-mingw32-ar "$PREFIX/bin/ar"
# 4.4.1's detect.py probes gcc-ar first for a MinGW archiver; without the name it
# stores the string "None" and the final static-library link fails with
# `sh: 1: None: not found`.
ln -sf x86_64-w64-mingw32-ar "$PREFIX/bin/x86_64-w64-mingw32-gcc-ar"
ln -sf x86_64-w64-mingw32-ar "$PREFIX/bin/gcc-ar"
ln -sf x86_64-w64-mingw32-windres "$PREFIX/bin/windres"
# zig's `ar` already writes an index; Godot only needs the touch to succeed.
printf '#!/bin/sh\nexit 0\n' > "$PREFIX/bin/x86_64-w64-mingw32-ranlib"
printf '#!/bin/sh\nexit 0\n' > "$PREFIX/bin/x86_64-w64-mingw32-gcc-ranlib"
chmod +x "$PREFIX/bin/x86_64-w64-mingw32-"*ranlib

# A pkg-config that answers --version and reports every library as missing. The
# editor is built without X11, Wayland, ALSA, PulseAudio, D-Bus, udev, fontconfig
# and speechd, so nothing is ever actually looked up.
mkdir -p "$PREFIX/stub"
printf '#!/bin/sh\ncase " $* " in *" --version "*) echo 1.8.1; exit 0;; esac\nexit 1\n' \
    > "$PREFIX/stub/pkg-config"
chmod +x "$PREFIX/stub/pkg-config"

# --------------------------------------------------------- 4. headless editor
say "editor build (linuxbsd, headless, $JOBS jobs)"
if [ ! -x "$SRC/bin/godot.linuxbsd.editor.x86_64" ]; then
    ( cd "$SRC" && env PATH="$PREFIX/stub:$VENV/bin:$PATH" $SCONS \
        platform=linuxbsd target=editor tools=yes \
        x11=no wayland=no alsa=no pulseaudio=no dbus=no speechd=no fontconfig=no udev=no \
        vulkan=no d3d12=no lto=none use_static_cpp=yes -j"$JOBS" )
fi
EDITOR=$SRC/bin/godot.linuxbsd.editor.x86_64
"$EDITOR" --headless --version

# ------------------------------------------------------ 5. Windows template
say "windows template build (cross-compiled with zig, $JOBS jobs)"
if [ ! -f "$SRC/bin/godot.windows.template_release.x86_64.exe" ]; then
    ( cd "$SRC" && env PATH="$PREFIX/bin:$PREFIX/stub:$VENV/bin:$PATH" MINGW_PREFIX="$PREFIX" $SCONS \
        platform=windows target=template_release tools=no arch=x86_64 \
        vulkan=no d3d12=no opengl3=yes lto=none use_static_cpp=yes windows_subsystem=gui -j"$JOBS" )
fi
TEMPLATE=$SRC/bin/godot.windows.template_release.x86_64.exe
ls -l "$TEMPLATE"

# --------------------------------------------------------- 6. install template
say "install template for the editor"
# A source build reports "4.4.1.stable.custom_build", but the editor looks its
# templates up under the plain "4.4.1.stable" directory.
VER=$("$EDITOR" --headless --version | tr -d '\r' | sed 's/\.custom_build$//')
TPL_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$VER
mkdir -p "$TPL_DIR"
cp "$TEMPLATE" "$TPL_DIR/windows_release_x86_64.exe"
printf '%s\n' "$VER" > "$TPL_DIR/version.txt"
echo "$TPL_DIR"

# ------------------------------------------------------------- 7. export game
say "import project"
# Note: importing rewrites every *.import file in the project (an older engine
# drops settings keys it does not know). Restore them afterwards if you do not
# want that in your working tree:  git checkout -- '**/*.import'
"$EDITOR" --headless --path "$ROOT" --import >/dev/null 2>&1 || true

say "export: $PRESET -> $OUT"
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
"$EDITOR" --headless --path "$ROOT" --export-release "$PRESET" "$OUT"

# ------------------------------------------------------------- 8. verify
say "verify"
ls -lh "$OUT"
python3 "$ROOT/tools/inspect_pck.py" "$OUT" --verify
printf '\nDone: %s\n' "$OUT"
