#!/bin/sh
# Convert the rendered shorts for the game: Ogg Theora, 1280x720, loudness-normalised.
# Run from cinematics/ after `node scripts/render-shorts.mjs` (and `node scripts/manifest.mjs`).
#
#   sh scripts/to_game-shorts.sh              # every short in out/shorts
#   sh scripts/to_game-shorts.sh S01-Week     # just one
#   Q=5 sh scripts/to_game-shorts.sh          # Theora quality (default 5)
#
# ffmpeg: FFMPEG, else the Playwright/apt binary, else @ffmpeg-installer. The Remotion
# compositor's own ffmpeg cannot encode Theora or Vorbis, so it is never used here.
set -e
mkdir -p ../assets/cutscenes/shorts out/shorts/final

pick_ffmpeg() {
  if [ -n "$FFMPEG" ] && [ -x "$FFMPEG" ]; then echo "$FFMPEG"; return; fi
  if command -v ffmpeg >/dev/null 2>&1; then command -v ffmpeg; return; fi
  for p in /tmp/ffm/node_modules/@ffmpeg-installer/linux-x64/ffmpeg; do
    if [ -x "$p" ]; then echo "$p"; return; fi
  done
  echo ""
}
FF=$(pick_ffmpeg)
if [ -z "$FF" ]; then
  echo "No ffmpeg with libtheora/libvorbis found. Set FFMPEG=/path/to/ffmpeg." >&2
  exit 1
fi
echo "ffmpeg: $FF"

Q=${Q:-5}
list="$*"
if [ -z "$list" ]; then
  list=$(ls out/shorts/*.mp4 2>/dev/null | sed 's#.*/##; s#\.mp4$##' || true)
fi
if [ -z "$list" ]; then
  echo "Nothing rendered yet: run node scripts/render-shorts.mjs first." >&2
  exit 1
fi

for id in $list; do
  [ -f "out/shorts/$id.mp4" ] || { echo "skip $id (no out/shorts/$id.mp4)"; continue; }
  # the key comes from the registry, never from the id: s06_officer_down, not s06_officerdown
  key=$(node -e "import('./src/shorts/registry.js').then(m=>{const e=m.byId[process.argv[1]];process.stdout.write(e?e.key:'')})" "$id")
  if [ -z "$key" ]; then
    # or from an extension-less name in out/shorts
    key=$(node -e "import('./src/shorts/registry.js').then(m=>{const e=m.SHORTS.find(s=>s.key===process.argv[1]);process.stdout.write(e?e.key:'')})" "$id")
  fi
  if [ -z "$key" ]; then echo "skip $id (not in the registry)"; continue; fi
  # loudness-normalised master, then the game copy
  "$FF" -y -loglevel error -i "out/shorts/$id.mp4" -c:v copy \
    -af "loudnorm=I=-18:TP=-1.5:LRA=11" -c:a aac -b:a 192k -ar 48000 "out/shorts/final/$id.mp4"
  "$FF" -y -loglevel error -i "out/shorts/final/$id.mp4" \
    -vf "scale=1280:720:flags=lanczos" -r 30 -c:v libtheora -q:v "$Q" \
    -c:a libvorbis -q:a 5 -ar 44100 "../assets/cutscenes/shorts/$key.ogv"
  printf '%-22s %8s  %s\n' "$key.ogv" "$(du -h "../assets/cutscenes/shorts/$key.ogv" | cut -f1)" "$id"
done

# the manifest the game reads
node scripts/manifest.mjs
echo "done: $(ls ../assets/cutscenes/shorts/*.ogv | wc -l) videos in assets/cutscenes/shorts"
