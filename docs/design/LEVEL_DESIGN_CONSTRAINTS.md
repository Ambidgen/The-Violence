# The Violence — level design constraints

> **Code status (added when this was filed in the repo).** This document records the **1.5** level rules adopted 2026-10-27.
> The code that implements them (`tests/command_test.gd`, `scripts/campaign/deploy.gd`, `tests/strike.gd`, the
> `_border()` / `_zone()` / `_no_go()` map helpers, and maps 12–15) was written in a separate working session and is
> **not in this repository snapshot**: the tree here has twelve maps (`m00`–`m11`) and no zone/squad layer. See the
> top-level README, "Known gaps".

Adopted 2026-10-27 (1.5). These rules bind every level, existing and future.
`tests/command_test.gd` holds every map to them in the quick tier.

## 1. Two primary areas, always

Every level defines exactly two kinds of ground.

| Area | What it is | How a map defines it |
| --- | --- | --- |
| **Accessible zones** | Where the player may deploy squads. They run along the **border** of the map and follow what is really there: the street, the back alley, the lanes, an empty lot, the far row of a parking lot. | `_border(side, depth, name)` for a band along one edge; `_zone(name, rect)` for any other strip (still along the edge). Name each one for what it is ("Tannery Street", "the back alley"): the name is how the plan, the setup screen and the radio refer to it. |
| **Inaccessible zones** | Everything else. Each building and the ground immediately round it (`zone_margin`, 4 m by default) is named "the building"; a map adds others with `_no_go(name, rect)` (a walled compound, a yard you would have to climb into). | Automatic for buildings; `_no_go()` for the rest. Any ground not in an accessible zone is inaccessible, named or not. |

Accessible zones are cut where inaccessible ground overlaps them. A zone piece
narrower than 1.8 m or smaller than 6 m² is dropped. Each zone faces the nearest
building; squads that deploy there face their entry door, or that way.

Checks every map must pass (`command_test.gd`, "zones"):

- zones are authored by the map (no map relies on a default);
- at least one accessible zone and at least one inaccessible area;
- every accessible zone has room to deploy (30+ reachable half-metre cells);
- every accessible zone lies along the border (no more than 6 m in from an edge);
- no accessible zone touches a building (grown by 0.5 m);
- no point inside a building can be deployed on;
- at least one door leads into a building from outside (an entry point);
- the default deployment point for squads 1-5 is always deployable.

## 2. Squads, not officers

The player places **squads**, never individual officers. For each squad they choose:

1. a **deployment point**, which must lie inside an accessible zone (the setup screen
   and the plan refuse anything else and say why); the squad forms up in that zone
   round the point;
2. an **intended entry door** into the building (or leaves it to the squad leader).
   Entry is part of deployment, so it costs no order points.

The **ranking officer's squad is always Squad 1**: in the test range and in a plan, the
squads are reordered (phase lines follow) so the strike team commander leads Squad 1.

## 3. Places the commander knows by heart

Contact reports name where a contact happened. Inside, that is the room's title, so
rooms that repeat get numbers ("NO.2 KITCHEN", "ROOM 3", "TRAILER 4"). Outside, it is
the nearest **landmark** within 5 m: every named exterior prop ("the shed", "the
burnt-out car") is one automatically, and `_landmark(name, point)` adds others ("the
yard of no.1", "the lane"); failing that, the zone, or the side of the building. Name
exterior props for what a commander would call them.

## 4. Checklist for a new level

- [ ] `_border()` / `_zone()` for every street, lane, alley and lot along the edge
- [ ] `_no_go()` for anything walled or fenced that is not a building
- [ ] at least one exterior door per building, with an `id` a commander can say
      ("FRONT", "NO. 2 BACK", "ROLL-UP 1")
- [ ] room titles unique across the map (number repeated rooms)
- [ ] named exterior props; `_landmark()` for open spots worth naming
- [ ] `stage_a` kept only for classic sandbox matches (the old formation rows)
- [ ] add it to `scripts/maps/registry.gd` and run `tests/command_test.gd`

## Levels (1.5)

| # | Map | Accessible zones |
| --- | --- | --- |
| 00 | Test Range 01, Shotgun House | the street front, the north and south fence lines, the back fence |
| 01 | Lone Cabin | the track, the west, east and north treelines |
| 02 | Bunkhouse | the access road, the south, north and east fields |
| 03 | Corner Store | Main Street, the service alley, the west and east lots |
| 04 | Center-Hall Bungalow | the street, the east lane, the driveway side, the back lane |
| 05 | Duplex | the street, the back alley, the west and east driveways |
| 06 | L-Shaped Ranch | Ridge Road, the east yard, the back fence |
| 07 | Roadside Motel | the highway, the far parking row, the back lot, the verges |
| 08 | Warehouse & Offices | the service road, the west yard, the east car park, the truck yard |
| 09 | Walled Compound | the approach road, the west and east tracks, the north verge (inside the wall: inaccessible) |
| 10 | Apartment Block | the street, the back footpath |
| 11 | Civic Plaza | Civic Avenue, the west and east walks |
| 12 | Row Houses, Tannery Flats (new) | Tannery Street, the back alley, the vacant lot, the east lot |
| 13 | Auto Body Shop, Ironworks (new) | Furnace Street, the salvage yard, the west fence, the east lane |
| 14 | The Anchor Bar, Riverside (new) | River Road, the alley, the parking lot, the side street |
| 15 | Trailer Lot, Cinder Hollow (new) | County Road 9, the entrance drive, the back field, the tree line |
