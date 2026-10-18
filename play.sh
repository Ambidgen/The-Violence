#!/bin/sh
# Play The Violence from this folder.
# Uses a runtime sitting here with the project files, then a Godot on PATH,
# then the embedded build/TheViolence.x86_64 if that is all that is present.
cd "$(dirname "$0")" || exit 1

run_project() {
  runtime=$1
  shift
  exec "$runtime" --path "$PWD" "$@"
}

for candidate in ./Godot* ./godot*; do
  if [ -f "$candidate" ] && [ -x "$candidate" ]; then
    run_project "$candidate" "$@"
  fi
done

if command -v godot >/dev/null 2>&1; then
  run_project godot "$@"
fi

if [ -x ./TheViolence.x86_64 ]; then
  exec ./TheViolence.x86_64 "$@"
fi
if [ -x ./build/TheViolence.x86_64 ]; then
  exec ./build/TheViolence.x86_64 "$@"
fi

echo "Could not play The Violence from this folder." >&2
echo "Put a Godot 4.4+ binary in this folder with the rest of the project, or build/TheViolence.x86_64." >&2
exit 1
