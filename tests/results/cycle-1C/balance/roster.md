# Roster bleed — tests/results/cycle-1C/balance

5201 operations in 80 runs; 1437 officers killed, **0.28 per operation**.

## By policy

| policy | operations | killed | per operation |
|---|---|---|---|
| accept_all | 1668 | 438 | 0.26 |
| cautious | 1407 | 491 | 0.35 |
| military | 1336 | 317 | 0.24 |
| minimal | 790 | 191 | 0.24 |

## By situation type

| type | operations | killed | per op | share | officers sent | down per op (incl. killed) | by a suspect | by a colleague | bled out |
|---|---|---|---|---|---|---|---|---|---|
| gang | 1169 | 929 | 0.79 | 65% | 6.4 | 1.46 | 802 | 27 | 100 |
| hostage | 1051 | 354 | 0.34 | 25% | 6.2 | 0.49 | 230 | 3 | 121 |
| barricade | 686 | 105 | 0.15 | 7% | 4.8 | 0.31 | 85 | 0 | 20 |
| warrant | 617 | 31 | 0.05 | 2% | 5.0 | 0.08 | 28 | 0 | 3 |
| event | 1678 | 18 | 0.01 | 1% | 3.1 | 0.01 | 17 | 0 | 1 |

## By map

| map | operations | killed | per op | share | officers sent | down per op (incl. killed) | by a suspect | by a colleague | bled out |
|---|---|---|---|---|---|---|---|---|---|
| Warehouse & Offices | 1138 | 835 | 0.73 | 58% | 6.4 | 1.27 | 690 | 12 | 133 |
| Apartment Block | 421 | 271 | 0.64 | 19% | 6.4 | 1.17 | 225 | 16 | 30 |
| Duplex | 699 | 133 | 0.19 | 9% | 5.5 | 0.29 | 95 | 1 | 37 |
| Corner Store | 443 | 88 | 0.20 | 6% | 5.8 | 0.36 | 55 | 1 | 32 |
| Center-Hall Bungalow | 397 | 52 | 0.13 | 4% | 4.8 | 0.27 | 44 | 0 | 8 |
| Lone Cabin | 167 | 28 | 0.17 | 2% | 4.8 | 0.34 | 25 | 0 | 3 |
| Civic Plaza | 1678 | 18 | 0.01 | 1% | 3.1 | 0.01 | 17 | 0 | 1 |
| L-Shaped Ranch | 258 | 12 | 0.05 | 1% | 5.1 | 0.08 | 11 | 0 | 1 |

## The pairs that make most of the deaths (77% in 3)

| type · map | operations | killed | per op | share | officers sent | down per op (incl. killed) | by a suspect | by a colleague | bled out |
|---|---|---|---|---|---|---|---|---|---|
| gang · Warehouse & Offices | 748 | 658 | 0.88 | 46% | 6.5 | 1.63 | 577 | 11 | 70 |
| gang · Apartment Block | 421 | 271 | 0.64 | 19% | 6.4 | 1.17 | 225 | 16 | 30 |
| hostage · Warehouse & Offices | 390 | 177 | 0.45 | 12% | 6.3 | 0.60 | 113 | 1 | 63 |

## The roster week by week

Week-end snapshots with at least 12 fit (the 1.C exit wants 90% for cautious), and officer-weeks spent injured and at the academy, per run.

| policy | weeks >= 12 fit | injury-weeks per run | academy-weeks per run |
|---|---|---|---|
| accept_all | 50% | 87.7 | 47.1 |
| cautious | 53% | 76.2 | 51.0 |
| military | 33% | 80.5 | 4.8 |
| minimal | 73% | 29.3 | 0.0 |

