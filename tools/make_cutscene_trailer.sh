#!/bin/sh
# Encode one crayon cutscene trailer variant from captured frames.
#
# The scene itself is unchanged (scripts/view/proto/cutscene_view.gd via
# tests/cutscene_capture.gd --every=1); the variant is a slight, deliberate
# grade deviation applied at encode time so three prototypes differ only in
# hand/grade, not in staging, camera or timing:
#
#   pencil-light     lifted, lower-contrast, less saturated — softer pencil
#   charcoal-night   darker, harder contrast — charcoal pressed harder
#   warm-paper       warm colour balance — aged/cream paper stock
#
#   tools/make_cutscene_trailer.sh --variant=charcoal-night \
#       --frames=build/cutscene-captures/cutscene --out=build/trailers
#   tools/make_cutscene_trailer.sh --variant=warm-paper --frames=DIR --dry-run
#
# Writes <out>/<variant>.mp4 (review) and <out>/<variant>.ogv (Godot-ready,
# Ogg Theora; silent — the prototype view has no sound design yet). Encoded at
# 1280x720 (the trailers/ spec): full-res crayon hatch noise inflates crf18
# encodes to >100 MB for 12 s, which helps nobody reviewing a prototype.
# Needs ffmpeg with libx264 + libtheora (CI installs the distro ffmpeg).
set -eu

VARIANT=""; FRAMES=""; OUT=""; FPS=30; DRY=0
for a in "$@"; do
  case "$a" in
    --variant=*) VARIANT=${a#*=} ;;
    --frames=*) FRAMES=${a#*=} ;;
    --out=*) OUT=${a#*=} ;;
    --fps=*) FPS=${a#*=} ;;
    --dry-run) DRY=1 ;;
    -h|--help) grep '^#' "$0" | head -30; exit 0 ;;
    *) echo "make_cutscene_trailer.sh: unknown arg: $a" >&2; exit 2 ;;
  esac
done
[ -n "$VARIANT" ] && [ -n "$FRAMES" ] && [ -n "$OUT" ] || {
  echo "usage: make_cutscene_trailer.sh --variant=V --frames=DIR --out=DIR" >&2; exit 2; }

case "$VARIANT" in
  pencil-light)    FILTER="eq=brightness=0.07:contrast=0.86:saturation=0.80" ;;
  charcoal-night)  FILTER="eq=brightness=-0.08:contrast=1.20:saturation=0.88" ;;
  warm-paper)      FILTER="colorbalance=rs=0.14:gs=0.04:bs=-0.14:rm=0.08:gm=0.02:bm=-0.08,eq=saturation=1.10:contrast=0.98" ;;
  baseline)        FILTER="null" ;;
  *) echo "make_cutscene_trailer.sh: unknown variant '$VARIANT' (pencil-light|charcoal-night|warm-paper|baseline)" >&2; exit 2 ;;
esac

run() { echo "+ $*"; [ "$DRY" = 1 ] || "$@"; }
if [ "$DRY" = 0 ]; then
  command -v ffmpeg >/dev/null 2>&1 || { echo "make_cutscene_trailer.sh: ffmpeg not found (CI installs it)" >&2; exit 1; }
  n=$(find "$FRAMES" -maxdepth 1 -name 'frame_*.jpg' | wc -l)
  [ "$n" -ge 30 ] || { echo "make_cutscene_trailer.sh: only $n frame(s) in $FRAMES — capture with --every=1 first" >&2; exit 1; }
  echo "make_cutscene_trailer.sh: $VARIANT from $n frames @ ${FPS}fps (filter: $FILTER)"
  mkdir -p "$OUT"
fi

run ffmpeg -y -framerate "$FPS" -i "$FRAMES/frame_%04d.jpg" \
  -vf "$FILTER,scale=w=1280:h=720:flags=lanczos,format=yuv420p" -c:v libx264 -crf 23 -movflags +faststart -an "$OUT/$VARIANT.mp4"
run ffmpeg -y -framerate "$FPS" -i "$FRAMES/frame_%04d.jpg" \
  -vf "$FILTER,scale=w=1280:h=720:flags=lanczos" -c:v libtheora -q:v 6 -an "$OUT/$VARIANT.ogv"
[ "$DRY" = 1 ] || ls -la "$OUT/$VARIANT.mp4" "$OUT/$VARIANT.ogv"
