#!/bin/sh
# Convert rendered cutscenes for the game (Ogg Theora, 1280x720, loudness-normalised) and
# make loudness-normalised MP4 masters. Run from cinematics/ after `npm run render`.
set -e
mkdir -p ../assets/cutscenes out/final
for pair in "C1-PortCarrick c1_port_carrick" "C2-OutgoingChief c2_outgoing_chief" "C3-ThePlan c3_the_plan" "C4-FortyWeeks c4_forty_weeks"; do
  set -- $pair
  [ -f "out/$1.mp4" ] || continue
  ffmpeg -y -loglevel error -i "out/$1.mp4" -c:v copy -af "loudnorm=I=-18:TP=-1.5:LRA=11" -c:a aac -b:a 192k -ar 48000 "out/final/TheViolence-opening-$2.mp4"
  ffmpeg -y -loglevel error -i "out/final/TheViolence-opening-$2.mp4" -vf "scale=1280:720:flags=lanczos" -c:v libtheora -q:v 6 \
    -c:a libvorbis -q:a 5 -ar 44100 "../assets/cutscenes/$2.ogv"
  echo "$2: $(du -h ../assets/cutscenes/$2.ogv | cut -f1)"
done
