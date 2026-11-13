#!/bin/sh
# Play The Violence from this folder (the source folder or a release folder).
# 1. A Godot 4.4+ binary (4.7.2 tested) sitting in this folder runs the project files here.
# 2. Otherwise a godot on PATH does.
# 3. Otherwise the standalone TheViolence.x86_64 here, or in build/ or build/linux/.
# Anything after play.sh is passed on, e.g.  ./play.sh -- --ops
cd "$(dirname "$0")" || exit 1

if [ -f ./project.godot ]; then
  for candidate in ./Godot* ./godot*; do
    if [ -f "$candidate" ] && [ -x "$candidate" ]; then
      exec "$candidate" --path "$PWD" "$@"
    fi
  done
  if command -v godot >/dev/null 2>&1; then
    exec godot --path "$PWD" "$@"
  fi
fi

for bin in ./TheViolence.x86_64 ./release/TheViolence.x86_64 ./build/TheViolence.x86_64 ./build/linux/TheViolence.x86_64; do
  if [ -x "$bin" ]; then
    exec "$bin" "$@"
  fi
done

echo "Could not play The Violence from this folder." >&2
echo "Put a Godot 4.4+ binary here with the project files, or TheViolence.x86_64 (or build/)." >&2
exit 1
