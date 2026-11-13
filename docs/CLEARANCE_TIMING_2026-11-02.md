# SOF assault clearance timing — 2 November 2026

This is a deterministic tactical-simulation study, not a real-world clearance-time prediction or a visual playtest. A single Special Operations squad assaults a single equal-sized Regular Infantry squad. Each map/size uses 3 seed(s), plus a matched movement-only control with no defenders.

## Key totals

- Fights: **180**; attacker/defender/draw outcomes **149/30/1** (1 fight timeouts). Game wins with defenders still fighting due to ammunition exhaustion: 0.
- Entire-room completion in the contested runs: **151/180** (0 had a skipped room; 0 hit the separate room-observation cap).
- Entire-room completion in movement-only controls: **180/180** (0 had a skipped room; 0 hit the separate room-observation cap).
- See [movement findings and fixes](CLEARANCE_DIAGNOSIS_2026-11-02.md) for the reproduced defects, before/after evidence, and interpretation of the slower cases.

## How to read the comparisons

- **Expected room travel** is an intentionally simplified reference: choose one reachable 0.25 m grid point nearest each interior room's label, assign the next point to the independent attacker that would arrive first, and sum profile-0 open-door navigation distances along each agent's route. Divide each by that agent's equipped walking speed; the largest individual travel time is the group estimate. The SOF preset walks at **1.3907 m/s** after its armour and kit penalties. The route's total metres and assigned points are in the JSONL. It assumes perfect independent parallel movement and ignores squad cohesion, entry, checking, combat, wounds, exposure avoidance and delays. A check room may be checked from its doorway rather than visited at the sampled interior point. **It is neither an optimal route nor a strict lower bound**, and it is not a prediction of combat duration. `Model m` is the sum of the independently assigned routes; `Actual m` is the sum of all attackers' measured movement until completion. These are person-metres, not wall-clock distances. `Serial s` repeats the one-operator route for the same map as an alternative non-splitting-squad reference; it still excludes every entry, check and delay and does not model the extra members' movement.
- **Room actual** is the first tick when the game's team bookkeeping marks every interior room as cleared or checked. A skipped room is not clear. Every ordinary clear was audited for an assigned member entering the room; a PF10 `checked` room can instead be inspected from the doorway. This is an engine-defined milestone, not proof that every square metre was physically searched. Normal fights end on an outcome; after a win with no defending fighters remaining, we continue the same surviving attackers and state with only the automatic match-end check disabled. The unopposed control disables that check from the start. Room-clearance observation is capped at 1,200 simulated seconds, including fight time. These extended times are **not normal in-game match durations**.
- The room table reports the mean of **completed** runs only, with the completion count / 3 alongside it. A loss, draw, unchecked room or capped run that has not already reached the room milestone is censored; an em dash means no run completed. A room milestone reached before a fight was subsequently lost is still recorded.
- **Defender-post travel** is a separate counterfactual: the same assignment model to all defenders' initial positions. It is **not** an expected time to kill, or a lower bound: soldiers can fire from range and defenders can move. The combat table reports normal in-game A/B/draw outcomes and the mean time only for A wins in which no defending fighters remain. A win by enemy ammunition exhaustion is counted as an A win, not as a neutralized defence.

## Room-clear timing by map and squad size

`Model` is the idealized independent route reference; `Serial s` is the same map's one-operator route. The unopposed and contested columns give actual mean total attacker movement and elapsed seconds for completed runs only. Counts are out of 3.

| Map | Size | Rooms | Model m | Model s | Serial s | Unopposed m | Unopposed s (done) | Contested m | Contested s (done) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 00 Test Range 01 - Shotgun House | 1v1 | 4 | 26.9 | 19.4 | 19.4 | 30.1 | 31.6 (3/3) | 34.1 | 33.8 (3/3) |
| 00 Test Range 01 - Shotgun House | 2v2 | 4 | 38.5 | 15.2 | 19.4 | 56.6 | 52.7 (3/3) | 58.6 | 55.1 (3/3) |
| 00 Test Range 01 - Shotgun House | 3v3 | 4 | 38.5 | 15.2 | 19.4 | 84.7 | 54.9 (3/3) | 102.2 | 65.9 (3/3) |
| 00 Test Range 01 - Shotgun House | 4v4 | 4 | 38.5 | 15.2 | 19.4 | 111.4 | 57.9 (3/3) | 121.3 | 63.6 (3/3) |
| 00 Test Range 01 - Shotgun House | 5v5 | 4 | 38.5 | 15.2 | 19.4 | 133.8 | 65.9 (3/3) | 166.1 | 76.1 (3/3) |
| 01 Lone Cabin | 1v1 | 1 | 7.7 | 5.5 | 5.5 | 8.4 | 8.0 (3/3) | 8.4 | 10.0 (3/3) |
| 01 Lone Cabin | 2v2 | 1 | 7.7 | 5.5 | 5.5 | 16.7 | 12.7 (3/3) | 16.8 | 15.9 (3/3) |
| 01 Lone Cabin | 3v3 | 1 | 7.7 | 5.5 | 5.5 | 26.7 | 16.5 (3/3) | 32.6 | 37.8 (3/3) |
| 01 Lone Cabin | 4v4 | 1 | 7.7 | 5.5 | 5.5 | 35.1 | 16.5 (3/3) | 49.1 | 31.3 (3/3) |
| 01 Lone Cabin | 5v5 | 1 | 7.7 | 5.5 | 5.5 | 36.0 | 16.6 (3/3) | 41.1 | 23.9 (3/3) |
| 02 Bunkhouse | 1v1 | 2 | 18.5 | 13.3 | 13.3 | 19.4 | 18.9 (3/3) | 26.9 | 22.9 (1/3) |
| 02 Bunkhouse | 2v2 | 2 | 29.1 | 13.0 | 13.3 | 41.0 | 32.1 (3/3) | 42.7 | 55.0 (2/3) |
| 02 Bunkhouse | 3v3 | 2 | 29.1 | 13.0 | 13.3 | 61.8 | 34.8 (3/3) | 59.4 | 52.3 (3/3) |
| 02 Bunkhouse | 4v4 | 2 | 28.8 | 12.9 | 13.3 | 87.5 | 39.4 (3/3) | 82.1 | 42.6 (3/3) |
| 02 Bunkhouse | 5v5 | 2 | 28.8 | 12.9 | 13.3 | 110.2 | 38.1 (3/3) | 121.5 | 48.6 (2/3) |
| 03 Corner Store | 1v1 | 3 | 29.3 | 21.1 | 21.1 | 33.3 | 32.0 (3/3) | 33.4 | 34.4 (3/3) |
| 03 Corner Store | 2v2 | 3 | 40.2 | 17.1 | 21.1 | 70.0 | 50.2 (3/3) | 71.8 | 52.6 (2/3) |
| 03 Corner Store | 3v3 | 3 | 57.7 | 15.5 | 21.1 | 106.5 | 70.3 (3/3) | 108.1 | 74.8 (2/3) |
| 03 Corner Store | 4v4 | 3 | 57.7 | 15.5 | 21.1 | 144.7 | 67.7 (3/3) | 147.6 | 88.8 (3/3) |
| 03 Corner Store | 5v5 | 3 | 57.7 | 15.5 | 21.1 | 174.9 | 71.9 (3/3) | 228.3 | 104.7 (3/3) |
| 04 Center-Hall Bungalow | 1v1 | 7 | 65.0 | 46.7 | 46.7 | 57.0 | 63.9 (3/3) | 57.2 | 67.0 (1/3) |
| 04 Center-Hall Bungalow | 2v2 | 7 | 61.1 | 22.7 | 46.7 | 89.5 | 71.6 (3/3) | 60.0 | 89.3 (2/3) |
| 04 Center-Hall Bungalow | 3v3 | 7 | 66.7 | 18.6 | 46.7 | 138.1 | 89.8 (3/3) | 106.9 | 90.4 (2/3) |
| 04 Center-Hall Bungalow | 4v4 | 7 | 76.0 | 18.6 | 46.7 | 185.6 | 101.7 (3/3) | 134.2 | 96.5 (2/3) |
| 04 Center-Hall Bungalow | 5v5 | 7 | 81.3 | 14.6 | 46.7 | 211.9 | 103.5 (3/3) | 158.2 | 125.4 (3/3) |
| 05 Duplex | 1v1 | 12 | 86.5 | 62.2 | 62.2 | 97.7 | 110.5 (3/3) | — | — (0/3) |
| 05 Duplex | 2v2 | 12 | 77.3 | 32.3 | 62.2 | 189.7 | 153.1 (3/3) | 159.0 | 153.5 (3/3) |
| 05 Duplex | 3v3 | 12 | 93.6 | 31.2 | 62.2 | 288.4 | 172.1 (3/3) | 275.7 | 177.2 (3/3) |
| 05 Duplex | 4v4 | 12 | 121.7 | 29.4 | 62.2 | 325.8 | 145.1 (3/3) | 298.1 | 178.7 (3/3) |
| 05 Duplex | 5v5 | 12 | 121.9 | 23.7 | 62.2 | 402.6 | 162.2 (3/3) | 396.4 | 198.5 (3/3) |
| 06 L-Shaped Ranch | 1v1 | 12 | 107.9 | 77.6 | 77.6 | 106.5 | 120.1 (3/3) | 109.4 | 125.3 (2/3) |
| 06 L-Shaped Ranch | 2v2 | 12 | 125.5 | 49.2 | 77.6 | 223.0 | 177.9 (3/3) | 196.2 | 181.7 (3/3) |
| 06 L-Shaped Ranch | 3v3 | 12 | 127.9 | 37.5 | 77.6 | 352.7 | 208.2 (3/3) | 359.3 | 220.5 (3/3) |
| 06 L-Shaped Ranch | 4v4 | 12 | 141.2 | 28.3 | 77.6 | 361.4 | 156.2 (3/3) | 380.4 | 186.8 (3/3) |
| 06 L-Shaped Ranch | 5v5 | 12 | 145.2 | 24.8 | 77.6 | 428.5 | 159.2 (3/3) | 337.0 | 172.1 (3/3) |
| 07 Roadside Motel | 1v1 | 14 | 166.2 | 119.5 | 119.5 | 163.6 | 162.0 (3/3) | 168.5 | 163.4 (1/3) |
| 07 Roadside Motel | 2v2 | 14 | 193.1 | 76.9 | 119.5 | 256.5 | 201.5 (3/3) | 250.2 | 204.2 (3/3) |
| 07 Roadside Motel | 3v3 | 14 | 212.5 | 61.9 | 119.5 | 363.9 | 222.1 (3/3) | 373.6 | 235.4 (3/3) |
| 07 Roadside Motel | 4v4 | 14 | 241.2 | 53.4 | 119.5 | 449.9 | 186.6 (3/3) | 432.1 | 189.5 (3/3) |
| 07 Roadside Motel | 5v5 | 14 | 254.8 | 50.8 | 119.5 | 555.1 | 191.9 (3/3) | 533.1 | 196.9 (3/3) |
| 08 Warehouse & Offices | 1v1 | 12 | 124.7 | 89.6 | 89.6 | 176.7 | 187.7 (3/3) | 182.8 | 194.8 (3/3) |
| 08 Warehouse & Offices | 2v2 | 12 | 169.4 | 61.8 | 89.6 | 319.7 | 226.7 (3/3) | 331.8 | 233.9 (3/3) |
| 08 Warehouse & Offices | 3v3 | 12 | 211.4 | 53.1 | 89.6 | 471.5 | 252.9 (3/3) | 475.4 | 259.3 (3/3) |
| 08 Warehouse & Offices | 4v4 | 12 | 259.9 | 49.3 | 89.6 | 530.5 | 205.2 (3/3) | 572.5 | 248.3 (3/3) |
| 08 Warehouse & Offices | 5v5 | 12 | 296.6 | 47.8 | 89.6 | 661.6 | 227.3 (3/3) | 680.4 | 262.7 (3/3) |
| 09 Walled Compound | 1v1 | 16 | 177.0 | 127.2 | 127.2 | 222.9 | 224.2 (3/3) | 222.2 | 223.5 (1/3) |
| 09 Walled Compound | 2v2 | 16 | 174.7 | 65.7 | 127.2 | 455.7 | 322.2 (3/3) | 464.5 | 326.7 (2/3) |
| 09 Walled Compound | 3v3 | 16 | 213.1 | 55.8 | 127.2 | 663.3 | 344.5 (3/3) | 645.2 | 345.0 (3/3) |
| 09 Walled Compound | 4v4 | 16 | 260.8 | 53.5 | 127.2 | 523.4 | 183.5 (3/3) | 608.0 | 265.5 (1/3) |
| 09 Walled Compound | 5v5 | 16 | 248.1 | 43.8 | 127.2 | 583.0 | 181.5 (3/3) | 593.7 | 402.0 (3/3) |
| 10 Apartment Block | 1v1 | 43 | 393.5 | 282.9 | 282.9 | 461.8 | 505.8 (3/3) | 462.6 | 506.9 (2/3) |
| 10 Apartment Block | 2v2 | 43 | 414.2 | 154.7 | 282.9 | 946.4 | 691.4 (3/3) | 951.9 | 715.0 (1/3) |
| 10 Apartment Block | 3v3 | 43 | 488.0 | 124.1 | 282.9 | 1432.8 | 768.9 (3/3) | 516.2 | 587.2 (1/3) |
| 10 Apartment Block | 4v4 | 43 | 564.5 | 113.2 | 282.9 | 1858.1 | 836.1 (3/3) | 1302.1 | 861.2 (3/3) |
| 10 Apartment Block | 5v5 | 43 | 610.9 | 92.8 | 282.9 | 2231.9 | 847.6 (3/3) | 1232.5 | 721.0 (2/3) |
| 11 Civic Plaza | 1v1 | 7 | 141.8 | 102.0 | 102.0 | 176.7 | 148.9 (3/3) | 176.9 | 150.8 (3/3) |
| 11 Civic Plaza | 2v2 | 7 | 228.1 | 88.3 | 102.0 | 299.5 | 211.5 (3/3) | 276.2 | 216.6 (3/3) |
| 11 Civic Plaza | 3v3 | 7 | 204.3 | 54.2 | 102.0 | 417.2 | 227.9 (3/3) | 386.8 | 246.4 (3/3) |
| 11 Civic Plaza | 4v4 | 7 | 189.9 | 54.2 | 102.0 | 556.0 | 236.6 (3/3) | 443.5 | 276.3 (3/3) |
| 11 Civic Plaza | 5v5 | 7 | 230.4 | 53.6 | 102.0 | 692.1 | 246.0 (3/3) | 612.2 | 258.4 (2/3) |

## Fight timing by map and squad size

`Post route` is travel to the defenders' starting posts, not an estimate of the shooting time. `Defeated actual` is conditional on an A win with zero defending fighters and gives its count / 3.

| Map | Size | Post route m | Post route s | A/B/draw | Defeated actual s (done) |
| --- | ---: | ---: | ---: | ---: | ---: |
| 00 Test Range 01 - Shotgun House | 1v1 | 19.8 | 14.2 | 3/0/0 | 29.4 (3/3) |
| 00 Test Range 01 - Shotgun House | 2v2 | 41.9 | 15.9 | 3/0/0 | 50.9 (3/3) |
| 00 Test Range 01 - Shotgun House | 3v3 | 42.3 | 16.2 | 3/0/0 | 58.5 (3/3) |
| 00 Test Range 01 - Shotgun House | 4v4 | 42.6 | 16.2 | 2/1/0 | 55.7 (2/3) |
| 00 Test Range 01 - Shotgun House | 5v5 | 44.1 | 16.2 | 3/0/0 | 57.9 (3/3) |
| 01 Lone Cabin | 1v1 | 8.5 | 6.1 | 3/0/0 | 4.0 (3/3) |
| 01 Lone Cabin | 2v2 | 17.2 | 6.3 | 3/0/0 | 2.7 (3/3) |
| 01 Lone Cabin | 3v3 | 26.4 | 6.6 | 3/0/0 | 30.9 (3/3) |
| 01 Lone Cabin | 4v4 | 26.4 | 6.6 | 3/0/0 | 21.0 (3/3) |
| 01 Lone Cabin | 5v5 | 33.2 | 6.6 | 2/1/0 | 16.2 (2/3) |
| 02 Bunkhouse | 1v1 | 21.7 | 15.6 | 1/2/0 | 17.9 (1/3) |
| 02 Bunkhouse | 2v2 | 39.7 | 15.6 | 2/1/0 | 26.7 (2/3) |
| 02 Bunkhouse | 3v3 | 60.6 | 16.0 | 3/0/0 | 34.6 (3/3) |
| 02 Bunkhouse | 4v4 | 59.8 | 15.6 | 3/0/0 | 39.4 (3/3) |
| 02 Bunkhouse | 5v5 | 60.0 | 15.6 | 2/1/0 | 41.4 (2/3) |
| 03 Corner Store | 1v1 | 20.4 | 14.7 | 3/0/0 | 19.5 (3/3) |
| 03 Corner Store | 2v2 | 42.3 | 15.7 | 2/1/0 | 41.0 (2/3) |
| 03 Corner Store | 3v3 | 44.3 | 16.1 | 2/1/0 | 52.9 (2/3) |
| 03 Corner Store | 4v4 | 43.7 | 16.4 | 3/0/0 | 57.8 (3/3) |
| 03 Corner Store | 5v5 | 73.1 | 21.1 | 3/0/0 | 64.1 (3/3) |
| 04 Center-Hall Bungalow | 1v1 | 12.3 | 8.8 | 1/2/0 | 9.9 (1/3) |
| 04 Center-Hall Bungalow | 2v2 | 23.1 | 8.9 | 2/1/0 | 54.3 (2/3) |
| 04 Center-Hall Bungalow | 3v3 | 36.8 | 9.9 | 2/1/0 | 37.1 (2/3) |
| 04 Center-Hall Bungalow | 4v4 | 39.3 | 9.9 | 2/1/0 | 33.0 (2/3) |
| 04 Center-Hall Bungalow | 5v5 | 51.2 | 10.0 | 3/0/0 | 42.0 (3/3) |
| 05 Duplex | 1v1 | 26.1 | 18.8 | 0/3/0 | — (0/3) |
| 05 Duplex | 2v2 | 52.2 | 19.1 | 3/0/0 | 85.9 (3/3) |
| 05 Duplex | 3v3 | 78.1 | 19.8 | 3/0/0 | 87.3 (3/3) |
| 05 Duplex | 4v4 | 77.3 | 19.5 | 3/0/0 | 102.5 (3/3) |
| 05 Duplex | 5v5 | 77.5 | 19.1 | 3/0/0 | 114.1 (3/3) |
| 06 L-Shaped Ranch | 1v1 | 9.6 | 6.9 | 2/1/0 | 6.0 (2/3) |
| 06 L-Shaped Ranch | 2v2 | 20.8 | 8.1 | 3/0/0 | 24.7 (3/3) |
| 06 L-Shaped Ranch | 3v3 | 25.4 | 10.9 | 3/0/0 | 27.1 (3/3) |
| 06 L-Shaped Ranch | 4v4 | 38.9 | 11.1 | 3/0/0 | 25.4 (3/3) |
| 06 L-Shaped Ranch | 5v5 | 36.9 | 10.9 | 3/0/0 | 25.0 (3/3) |
| 07 Roadside Motel | 1v1 | 40.0 | 28.8 | 1/2/0 | 150.6 (1/3) |
| 07 Roadside Motel | 2v2 | 82.4 | 30.5 | 3/0/0 | 173.7 (3/3) |
| 07 Roadside Motel | 3v3 | 80.8 | 29.3 | 3/0/0 | 184.1 (3/3) |
| 07 Roadside Motel | 4v4 | 82.0 | 29.9 | 3/0/0 | 144.0 (3/3) |
| 07 Roadside Motel | 5v5 | 80.4 | 29.3 | 3/0/0 | 143.8 (3/3) |
| 08 Warehouse & Offices | 1v1 | 39.1 | 28.1 | 3/0/0 | 103.0 (3/3) |
| 08 Warehouse & Offices | 2v2 | 46.4 | 33.4 | 3/0/0 | 126.0 (3/3) |
| 08 Warehouse & Offices | 3v3 | 85.1 | 33.1 | 3/0/0 | 144.9 (3/3) |
| 08 Warehouse & Offices | 4v4 | 89.6 | 33.1 | 3/0/0 | 159.5 (3/3) |
| 08 Warehouse & Offices | 5v5 | 130.7 | 33.1 | 3/0/0 | 173.8 (3/3) |
| 09 Walled Compound | 1v1 | 19.1 | 13.7 | 1/2/0 | 106.5 (1/3) |
| 09 Walled Compound | 2v2 | 39.0 | 14.5 | 2/1/0 | 251.1 (2/3) |
| 09 Walled Compound | 3v3 | 43.7 | 17.0 | 3/0/0 | 295.1 (3/3) |
| 09 Walled Compound | 4v4 | 64.6 | 17.0 | 1/2/0 | 247.2 (1/3) |
| 09 Walled Compound | 5v5 | 84.6 | 17.0 | 3/0/0 | 144.8 (3/3) |
| 10 Apartment Block | 1v1 | 11.3 | 8.1 | 2/1/0 | 239.7 (2/3) |
| 10 Apartment Block | 2v2 | 25.3 | 10.2 | 1/2/0 | 31.6 (1/3) |
| 10 Apartment Block | 3v3 | 27.2 | 10.6 | 1/1/1 | 67.6 (1/3) |
| 10 Apartment Block | 4v4 | 37.9 | 10.3 | 3/0/0 | 62.0 (3/3) |
| 10 Apartment Block | 5v5 | 38.0 | 10.2 | 2/1/0 | 57.6 (2/3) |
| 11 Civic Plaza | 1v1 | 44.0 | 31.7 | 3/0/0 | 51.2 (3/3) |
| 11 Civic Plaza | 2v2 | 89.2 | 32.5 | 3/0/0 | 40.4 (3/3) |
| 11 Civic Plaza | 3v3 | 135.5 | 33.7 | 3/0/0 | 51.2 (3/3) |
| 11 Civic Plaza | 4v4 | 135.6 | 34.2 | 3/0/0 | 62.4 (3/3) |
| 11 Civic Plaza | 5v5 | 179.3 | 33.7 | 2/1/0 | 106.4 (2/3) |

## Reproducibility and limits

- Maps 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11; squad sizes 1v1, 2v2, 3v3, 4v4, 5v5. These are the natural one-squad sizes. Initial A and B positions are the map's normal test-range spawns; B starts in hold and is prevented from automatically switching to hunt after 60 quiet seconds. Both sides use their full UI preset kits, experience and habits, including stress bad habits. No civilians, campaign state, police rules, night, or closed doors. Defenders can still react to contact and move defensively.
- Seeds are `811001 + 1000 * map_index + 7919 * repetition`, repetition 0–2. Seed pairing fixes the labels and setup, not the later random stream or behavior. 3 fight(s) per cell are an exploratory sample; mean completion times are conditional on success, not estimates of a population or causal effects. The 1,200-second room cap differs from normal fight limits (240–900 s).
- These records do not embed executable provenance. See the study's accompanying README for the engine used; an official-editor run and visual playtesting remain advisable.
- Raw records: [`maps-00-07.jsonl`](../tests/results/clearance-2026-11-02/maps-00-07.jsonl), [`maps-08-11.jsonl`](../tests/results/clearance-2026-11-02/maps-08-11.jsonl).
- Reproduce with `godot --headless --path . -s res://tests/clearance_study.gd -- --maps=0,1,2,3,4,5,6,7,8,9,10,11 --sizes=1,2,3,4,5 --n=3 --seed=811001 --max-room-seconds=1200 --out=res://build/clearance.jsonl`, then run `python3 tools/analyze_clearance_study.py build/clearance.jsonl --maps=0,1,2,3,4,5,6,7,8,9,10,11 --sizes=1,2,3,4,5 --n=3 --seed=811001 --output build/clearance-report.md`.
