# The Violence — visual overhaul: "a child is drawing this, right now"

Prepared 2026-10-27 from three reference plates (pencil and wax crayon on cream paper: a
police compound at night seen from above, a riot line in the rain at a contested
election, a lone figure in a wet alley under a streetlamp). This replaces the red-ink
floor-plan look. It is not a recolour: every top-down asset is redrawn in code as
strokes, and the page keeps moving.

**Prototype 2 (2026-10-27)** supersedes the first sketch. It was rebuilt from a second
set of nine plates (below) and comes as three working prototypes in the engine:

| Prototype | File | What it shows |
| --- | --- | --- |
| In-game, top-down | `scripts/view/proto/topdown_view.gd` | A night warrant on the Center-Hall Bungalow (map 4): the page draws itself; rain; a cruiser smearing red and blue; sodium pools; rooms drawn up out of the dark as officers see in; weapon-light cones; a red-lit hall; window light thrown across floors; a shooting, the blood drawn on slowly, the evidence markers. Fog hides people until their room is seen. |
| Menu | `scripts/view/proto/menu_view.gd` | Port Carrick from the air under orange smog, chimneys pouring black smoke, rain; the title printed on in crayon capitals and underlined in red; the menu as torn paper scraps; the hovered one circled in red, drawn as you watch; a Ledger cutting. |
| Cutscene | `scripts/view/proto/cutscene_view.gd` | Election night: a crossroads from a high corner, a true 3D scene projected by hand so the slow camera move has parallax; brick blocks with VOTE posters, a crowd with signs behind yellow-and-black barriers, a riot line with round shields stepping forward, a sweeping searchlight, a police van, captions printed on, and the stamp. |

Render any of them with
`godot --path . --fixed-fps 30 -s res://tests/proto_capture.gd -- --which=topdown --secs=13 --out=/tmp/td`
(needs a display). The library is `scripts/view/crayon.gd`.

### Prototype 2: what changed after the second plates

The second plates (a riot line at a crossroads; an evidence scene from above with a cap,
a belt and a blood trail into a drain; a police van in red-and-blue smear and steam;
smog-orange housing blocks; an interrogation room under one bulb; a looted storefront;
an apartment cut away from above with a red hallway; a graffiti alley; a police compound
with orange light cones) are **darker, denser and more detailed** than the first:

- **Toned grey paper**, not cream, with thumbprints and grime at the margins.
- **Charcoal over everything:** fills are two crossing layers of hatching, so dark
  values dominate and paper shows only where light is.
- **Light is drawn as a shape** — cones, pools, window spill thrown across a floor —
  scribbled hard in amber and orange over the dark, never as a gradient.
- **Police colour is a smear:** red and blue laid on the wet street like pastel.
- **Detail is rough but specific:** window grids, brick courses, posters, signs,
  evidence tents, furniture with its one telling detail.
- **Lettering is drawn, not typeset:** a single-stroke capital font of our own
  (`Crayon.GLYPHS`), so every word wobbles, is gone over twice, and can be printed on
  stroke by stroke.


## Status (2026-11-03): one look

The opening scenes' bright child's crayon (cream paper, saturated wax, notebook-paper
captions) is now the reference for the whole game; it supersedes the darker grey-paper
"prototype 2" plates below wherever they disagree. Shorts, title, board map, plans, fog,
figures, props and UI chrome were moved to it on 3 November (see the changelog, and the
before/after renders in `tests/results/visual-2026-11-03/`).

## Status (2026-11-02): gameplay, menus, and the opening are converted

The four opening scenes and fourteen campaign shorts now run as native crayon drawings in Godot. Opening timelines live in `scripts/view/proto/`; the short-form set is data-driven by `assets/cutscenes/shorts/shorts.json` and drawn by `scripts/view/crayon_short.gd`. Their legacy Remotion renders remain archived as references.

| Area | What changed | Where |
| --- | --- | --- |
| The page | The plan is a child's drawing: the briefing in daylight pencil on cream (yard scribbled green, each room its own crayon, tiles in wet rooms), the operation at night in charcoal. Walls pressed hard, windows cobalt, room names in wobbly capitals, the title block a scrap, the stamps drawn. Recorded once per state into three boil variants and replayed. | `view/crayon_plan.gd`, `view/sketch.gd`, `view/floor_plan.gd` |
| Doors | Orange leaves, live: open at a right angle with a faint swing, shut across the gap, a bolt when locked, splinters when forced. | `view/doors_view.gd` |
| Props and vehicles | All 63 furniture, yard and vehicle sprites redrawn in crayon with their one telling detail (pillows, burner rings, toilet seat, wheels sticking out, POLICE on the roof). | `view/crayon_props.gd` |
| Figures | Pebble bodies in their side's colour (police navy with a badge, suspects olive-umber with a hood, civilians in their own bright coat), big round heads (cap, helmet, hair), whole arms ending in mittens, big dark boots always drawn. A pale rim in the side's colour keeps them readable at night. | `view/crayon_figures.gd`, `view/rig.gd` |
| Carries | Every combatant has a low carry (muzzle down, short from above), a high carry (muzzle up by the face, foreshortened), and weaponless: handgun holstered at the hip, long gun slung across the back. Relaxed = low carry or holstered; ready but not aiming = high carry; aiming = aim. | `view/rig.gd`, `view/actor_view.gd`, `view/replay_view.gd` |
| Deaths | Every look (police, suspects, civilians, medics) has eight death sprites, chosen by the direction the killing round travelled relative to the facing: from behind they pitch forward face down, from the front they go over backwards face up, from either side they fold onto that side; diagonals in between. A police cap is knocked off beside the head. Someone who bleeds out settles into the pose of their last hit. Review sheet: `tests/carry_death_gallery.gd`. | `view/crayon_figures.gd` (`dead`) |
| Blood | Physical: each hit throws droplets along the round's path (and some back-spatter), each flown as a ballistic body from the wound height (head, chest, legs; lower when crouched) under gravity, stopped by walls; on the floor it leaves a teardrop stretched along its flight (width/length = sin of impact angle) with satellites when it lands fast, on a wall a streak along the face. Droplets are drawn in the air with their shadows until they land. Residue: stains dry red to brown over a couple of minutes, and anyone who walks through a pool tracks footprints for a few steps. Gore off hides it all; fog hides what nobody has seen. | `view/decals.gd` |
| Fog | Charcoal hatching laid on in world space by a shader: one direction over ground once seen, crossing strokes over ground never seen, boiling with the page. | `shaders/crayon_fog.gdshader`, `view/fog.gd` |
| Sprites boil | Every sprite is three baked variants played as an AnimatedTexture at the boil rate. | `tools/bake_crayon.gd` -> `assets/crayon/`, `view/decals.gd` (`tex`) |
| Menus and UI | The title page is Port Carrick under orange smog (from the menu prototype), the title printed on in crayon and underlined in red, the menu as torn scraps with a red scribble ring and arrow on the hovered one, the Ledger cutting. Every panel and button is a hand-drawn box (`ui/crayon_box.gd`); one hand for all text (Patrick Hand, OFL, `fonts/`). | `ui/front.gd`, `ui/ui.gd`, `ui/crayon_box.gd` |
| Settings | "Line boil" on/off (off stills every line). | `ui/settings.gd` |

Rebuild the sprites after changing a painter: `godot --path . -s res://tools/bake_crayon.gd` (needs a
display), then `godot --headless --path . --import`.

## What the plates say

| Plate | What it teaches |
| --- | --- |
| Police compound, above | Top-down is fine for a child: they draw what they know, not what they see — roofs, cars, lamps, fences all flattened and outlined. Ground is **dense graphite scribble**, never flat. Light is **ochre/orange radiating strokes**, not gradients. Only a few things get colour: the lamps, the cruiser, a brick wall. |
| Riot line in the rain | Crowds are **heads and raised arms**; police are dark **helmets and round shields**; barriers are bright orange. A searchlight is a **yellow wedge scribbled hard**. Rain is **cobalt slashes over everything**, including the people. Posters ("VOTE") are drawn with letters the child half-knows. |
| Alley under a lamp | **Heavy wax colour everywhere**: brick red, umber, cobalt, green, orange, layered and smeared. Cobbles are loops. Puddles are blue-and-orange reflections. The figure is small, dark, alone, with big shoes. Paper shows at the edges; thumb smudges and grime at the margins. |

## The rules

1. **Everything is strokes.** No flat fills, no gradients, no clean geometry. Fills are
   back-and-forth crayon at a slant, layered in two or three colours, paper showing
   through; edges are pressed harder.
2. **Lines boil.** Every stroke is redrawn about eight times a second with a slightly
   different wobble. Nothing on the page is ever perfectly still.
3. **The page is drawn while you watch.** A map draws itself in order — the ground, the
   rooms, the walls, then the furniture, then the people — when an operation opens.
   Fog of war is *undrawn* paper: rooms are drawn in as officers see them. Blood, bullet
   holes and tracks are drawn on in the moment, slowly, as a child would add them.
4. **A child making sense of violence.** Proportions follow importance, not anatomy:
   heads are big, **arms are always whole — shoulder, elbow, a mitten of a hand — and
   reach for what they hold; shoes are big, dark and always drawn**, sticking out from
   under the body and swapping as they walk. Guns are black sticks pressed too hard.
   Officers look like officers because of what a child notices: the dark uniform, the
   helmet, the shield, the car with the blue light.
5. **Colour carries meaning, sparingly.** Graphite and umber are the world. Police are
   navy. Lamplight and muzzle flash are ochre and orange. Rain and glass are cobalt.
   Red is reserved for blood and the "VOTE" crosses — still the strongest colour on the
   page, now one of a few. (This supersedes the single-crimson-accent rule.)
6. **Readability survives.** The sim needs instant reads: a contrasting outline per
   faction (navy police, umber/olive suspects, bright civilians), a scribbled vision
   wedge, and the boil scaled down (to 0) for screenshots and for players who need still
   lines (an accessibility setting).

## Palette (from the plates)

| Token | Hex | Use |
| --- | --- | --- |
| PAPER_GREY | `#8d8a83` | the page (toned); PAPER_CREAM `#e6dfcd` for scraps and posters |
| SLATE | `#3b4350` | wet asphalt, night rooms (SLATE_LIGHT `#5d6878` lit) |
| AMBER / TAPE | `#f0b53b` / `#e7c93b` | bulbs, searchlights / warning tape, barriers |
| BLUE | `#3b6fd6` | police light |
| GRAPHITE | `#3a3632` | ground scribble, outlines |
| CHARCOAL | `#1d1b19` | walls, guns, shoes, hard outlines |
| BRICK | `#7d3324` | walls, brick buildings |
| UMBER | `#5b3c27` | earth, furniture, mud |
| OCHRE | `#e8b43c` | lamplight, searchlights, muzzle flash |
| ORANGE | `#e2652a` | barriers, doors, fire, the cruiser's glow |
| COBALT | `#3d63b2` | rain, glass, puddles, police lights |
| SAP | `#4f6a3a` | hedges, suspects' jackets, grime |
| NAVY | `#24304f` | police uniforms |
| SKIN | `#e0a982` | heads and hands (with variation per person) |
| RED | `#b8262a` | blood, the crossed vote |

## The asset rebuild (what gets redrawn)

All of these exist today as SVGs from `tools/make_placeholders.py` or as code in
`scripts/view/`. Each becomes a Crayon draw function with its own seed, so every
instance wobbles differently.

| Group | Today | Rebuild |
| --- | --- | --- |
| Figures (`view/rig.gd`, 14 SVG rigs) | ink torso, head, code-drawn arms and feet | `Crayon.figure`: big head with scribbled hair or helmet, pebble body in uniform colour, whole arms with mittens on the weapon, big shoes in a walk cycle; down pose with limbs flung; kit drawn on top (plates as a scribbled vest, shield as a big round disc, gas mask as a snout, ram as a log) |
| Floor plan (`view/floor_plan.gd`, `plan_walls.gd`) | poche walls, grid, title block | brick-and-charcoal walls pressed hard, rooms in layered grey/umber, doors as orange leaves, windows as cobalt dashes, room names in wobbly child capitals; the title block becomes a scrawled note in the corner |
| Furniture (34 SVGs) | plan-view outlines | each piece a coloured box with the one detail a child would draw (pillows on the bed, rings on the stove, a seat on the toilet) |
| Yard and street (23 SVGs, 4 vehicles) | outlines | cars as boxes with wheels sticking out (and a blue light on the cruiser), trees as green loops, bins as cylinders with lids, fences as cross-hatching |
| Effects (`view/decals.gd`, fx SVGs) | red-ink blood, scuffs, casings | blood as a red crayon pool drawn on slowly, muzzle flash as an ochre star, bullet holes as charcoal dots pressed through, casings as tiny orange dashes, tracks as faint graphite loops |
| Fog (`view/fog.gd`) | grey veil | *undrawn paper*: unseen rooms are blank or only lightly sketched in pencil; seen rooms are coloured in |
| UI chrome (`ui/*.gd`) | Open Sans on paper cards | keep the readable font for text, but cards become torn sketchbook paper with crayon underlines; buttons get a scribbled box |
| Opening (four scenes) | legacy Remotion videos | replaced in-game by the native crayon scenes `opening_view`, `presser_view`, `jeremy_view`, and `fettick_view`; legacy `.ogv` files remain as source artifacts but are excluded from game exports |
| Campaign shorts (14 scenes) | legacy Remotion, `.ogv` | replaced at runtime by fourteen prop-driven native crayon interstitials; legacy exports retained for reference and excluded from game exports |

## Technical approach

- **Code-drawn, not bitmaps.** The prototype draws everything with `draw_polyline` /
  `draw_colored_polygon`. That is what makes the boil and the draw-on possible.
- **Boil cost.** A full map is thousands of strokes. Two layers: the static world
  (ground, walls, furniture) renders into a `SubViewport` once per boil frame (8 fps) and
  is reused between; only people, effects and rain redraw every frame. The existing
  `Rig.detail` LOD and `Rig.view` culling carry over.
- **Paper grain** is a baked texture (`Crayon.paper_texture`); a canvas shader for wax
  grain over fills (noise-masked alpha) is the next step after the prototype.
- **Presentation only.** As today, nothing here touches the simulation; replays and the
  determinism fixture are unaffected.
- **Settings:** "Line boil" (on / gentle / off) and "Draw-on" (on / instant) join red
  ink and gore.

## Phases

1. **Prototype** — done: the library; three prototypes (in-game, menu, cutscene) with stills and clips.
2. **Figures** — port `rig.gd`'s poses (aim, reload, door, throw, cuffs, dressing, fall)
   to `Crayon.figure`; kit overlays; faction outlines. Gate: `tests/rig_gallery.gd`
   re-rendered in crayon.
3. **The page** — floor plan, walls, doors, windows, furniture, yards; SubViewport cache;
   draw-on at operation start. Gate: all twelve maps render under 4 ms per frame at
   1600×900 on the compatibility renderer.
4. **Fog and effects** — undrawn-paper fog, blood and holes drawn on, rain.
5. **UI and the front end** — sketchbook cards, scribbled buttons, title page redrawn.
6. **Cutscenes** — runtime migration complete: the opening and all fourteen shorts are native crayon drawings; capture and performance review remain.

## Open question

Your note ended "…trying to make sense of thier… Arms and shoes should be full…" and was
cut off. The prototype reads it as: *a child trying to make sense of their world, with
arms and shoes always drawn in full.* Confirm or correct before phase 2.
