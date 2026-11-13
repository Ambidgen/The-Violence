#!/bin/sh
# Capture one cutscene/prototype view to stills + a contact sheet, for review.
#
# This is the local half of the repo-only cutscene loop (see
# docs/CUTSCENE_CAPTURE.md); .github/workflows/cutscene-capture.yml runs the
# same script on a GitHub-hosted runner. It needs a *displayed* Godot — the
# headless RenderingServer renders nothing — so locally give it a desktop,
# and in CI it runs under Xvfb.
#
#   GODOT=/path/to/godot tools/cutscene_capture.sh
#   GODOT=godot tools/cutscene_capture.sh --which=cutscene --secs=12 --stills=1,4,8,11.5
#   GODOT=godot tools/cutscene_capture.sh --short=s01_week
#   tools/cutscene_capture.sh --dry-run            # print the commands, run nothing
#
# Env: GODOT (default: ~/godot/godot, else `godot` on PATH), XVFB=1 to wrap in
# xvfb-run yourself, PYTHON (default python3).
set -eu

WHICH=cutscene; SECS=12; STILLS=1,4,8; EVERY=0; SCENE=""; SHORT=""; DRY=0
SECS_SET=0; STILLS_SET=0
for a in "$@"; do
  case "$a" in
    --which=*) WHICH=${a#*=} ;;
    --secs=*) SECS=${a#*=}; SECS_SET=1 ;;
    --stills=*) STILLS=${a#*=}; STILLS_SET=1 ;;
    --every=*) EVERY=${a#*=} ;;
    --scene=*) SCENE=${a#*=} ;;
    --short=*) SHORT=${a#*=} ;;
    --dry-run) DRY=1 ;;
    -h|--help) grep '^#' "$0" | head -20; exit 0 ;;
    *) echo "cutscene_capture.sh: unknown arg: $a" >&2; exit 2 ;;
  esac
done

GODOT_BIN=${GODOT:-"$HOME/godot/godot"}
command -v "$GODOT_BIN" >/dev/null 2>&1 || GODOT_BIN=godot
NAME=${SCENE##*/}; NAME=${NAME%.gd}; [ -n "$SCENE" ] || NAME=$WHICH
[ -z "$SHORT" ] || NAME=$SHORT
OUT="build/cutscene-captures/$NAME"
PY=${PYTHON:-python3}

run() { echo "+ $*"; [ "$DRY" = 1 ] || "$@"; }
[ "$DRY" = 1 ] || command -v "$GODOT_BIN" >/dev/null 2>&1 || {
  echo "cutscene_capture.sh: no Godot binary (set GODOT=/path/to/godot; CI downloads it from GitHub Releases)" >&2; exit 1; }

PREFIX=""
if [ "${XVFB:-0}" = 1 ]; then PREFIX="xvfb-run -a"; fi

# Import first (headless is fine for importing; it keeps .godot/ warm and its
# logs out of the capture), then capture displayed at a fixed frame rate so
# the boil/draw-on timing reviewers see matches --fixed-fps elsewhere.
# shellcheck disable=SC2086
run $PREFIX "$GODOT_BIN" --headless --path . --import
# shellcheck disable=SC2086
if [ -n "$SHORT" ]; then
  if [ "$SECS_SET" = 1 ] && [ "$STILLS_SET" = 1 ]; then
    run $PREFIX "$GODOT_BIN" --path . --fixed-fps 30 --resolution 1600x900 \
      -s res://tests/cutscene_capture.gd -- --short="$SHORT" --secs="$SECS" --stills="$STILLS" --every="$EVERY" --out="$OUT"
  elif [ "$SECS_SET" = 1 ]; then
    run $PREFIX "$GODOT_BIN" --path . --fixed-fps 30 --resolution 1600x900 \
      -s res://tests/cutscene_capture.gd -- --short="$SHORT" --secs="$SECS" --every="$EVERY" --out="$OUT"
  elif [ "$STILLS_SET" = 1 ]; then
    run $PREFIX "$GODOT_BIN" --path . --fixed-fps 30 --resolution 1600x900 \
      -s res://tests/cutscene_capture.gd -- --short="$SHORT" --stills="$STILLS" --every="$EVERY" --out="$OUT"
  else
    run $PREFIX "$GODOT_BIN" --path . --fixed-fps 30 --resolution 1600x900 \
      -s res://tests/cutscene_capture.gd -- --short="$SHORT" --every="$EVERY" --out="$OUT"
  fi
elif [ -n "$SCENE" ]; then
  run $PREFIX "$GODOT_BIN" --path . --fixed-fps 30 --resolution 1600x900 \
    -s res://tests/cutscene_capture.gd -- \
    --scene="$SCENE" --secs="$SECS" --stills="$STILLS" --every="$EVERY" --out="$OUT"
else
  run $PREFIX "$GODOT_BIN" --path . --fixed-fps 30 --resolution 1600x900 \
    -s res://tests/cutscene_capture.gd -- \
    --which="$WHICH" --secs="$SECS" --stills="$STILLS" --every="$EVERY" --out="$OUT"
fi
run "$PY" tools/make_contact_sheet.py "$OUT" --title "cutscene capture: $NAME"
[ "$DRY" = 1 ] || echo "cutscene_capture.sh: review $OUT/contact-sheet.png"
