extends RefCounted
## The single runtime version source. Run tools/sync_version.py after changing it
## to update Godot's project and Windows export metadata, then commit all three.
##
## The version line (EA_TASKS P0.D1, decided 2026-10-28): 1.3.x is Early Access and
## 2.0 is the 1.0 release. Going down to 0.9 would have confused the save and legacy
## migrations, which are versioned forward only. CHANNEL is what the title and the
## credits say; bump VALUE to "2.0.0" and CHANNEL to "1.0" when the EA line ends.
const VALUE := "1.3.0"
const WINDOWS := VALUE + ".0"
const CHANNEL := "Early Access"
