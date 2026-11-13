#!/bin/sh
# Verify the repository's primary Godot version and populate the ignored .godot/ import cache.
# Install Godot 4.7.2-stable first, or point GODOT at an existing compatible binary.
set -eu

if [ -n "${GODOT:-}" ]; then
  GODOT_BIN=$GODOT
elif [ -x "$HOME/godot/godot" ]; then
  GODOT_BIN="$HOME/godot/godot"
elif command -v godot >/dev/null 2>&1; then
  GODOT_BIN=$(command -v godot)
else
  echo "import_godot_project.sh: Godot 4.7.2-stable not found; set GODOT=/path/to/godot" >&2
  exit 1
fi

VERSION=$("$GODOT_BIN" --version)
case "$VERSION" in
  4.7.2*) ;;
  *)
    echo "import_godot_project.sh: expected Godot 4.7.2-stable, found $VERSION" >&2
    exit 1
    ;;
esac

echo "Importing The Violence with Godot $VERSION"
"$GODOT_BIN" --headless --path . --import
