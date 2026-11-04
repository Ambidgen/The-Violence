# Godot setup and crayon-short review

The project targets Godot **4.7.2-stable** as its primary engine and retains quick
compatibility checks for 4.4.1-stable. The exact versions used in CI are pinned in
`.github/workflows/ci.yml`.

## Install and import

Install the official Godot 4.7.2-stable editor/standard Linux build from the Godot
release page, unzip it, then run the import helper from the repository root:

```sh
GODOT="$HOME/godot/godot" tools/import_godot_project.sh
```

The helper verifies the version and runs Godot's headless resource import. Godot builds
its `.godot/` cache locally; that directory is ignored by Git. To use another install,
set `GODOT=/path/to/godot`. The game currently declares features 4.4 and 4.7 in
`project.godot`; use the CI compatibility jobs before treating 4.4.1 as a release target.

## Preview native shorts

The 14 campaign interstitials are now authored as native, prop-driven crayon drawings in
`scripts/view/crayon_short.gd`. `scripts/ui/shorts.gd` reads each duration/default/slot
from `assets/cutscenes/shorts/shorts.json`, supplies the campaign values and plays the
matching cutscene cues. Existing Ogg Theora exports are retained as source/reference
artifacts; the runtime does not load them, and the Windows/Linux export presets exclude
`.ogv` files from shipped builds.

Capture one composition (needs a display; use Xvfb on a server):

```sh
GODOT="$HOME/godot/godot" tools/cutscene_capture.sh --short=s01_week
GODOT="$HOME/godot/godot" tools/cutscene_capture.sh --short=s11_election --stills=1,5,9
```

The capture harness reads the selected short's default props and duration from the same
manifest and writes a contact sheet to `build/cutscene-captures/<key>/`. CI's
`cutscene-capture` workflow accepts a short key in its `short` input. The capture workflow
is a review aid; the regular headless test suites remain the gameplay/runtime gate.
