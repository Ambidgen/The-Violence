# Run-layer balance — 8 seed(s) × 4 policy(ies), 40 weeks

32 run(s), 5732 s wall clock, 4.7.2-stable (official).

| metric | cautious | minimal | military-first | accept-all |
|---|---|---|---|---|
| lowest fit officers | 5.62 [2–11] | 9 [4–14] | 9 [7–12] | 7.25 [4–11] |
| weeks under 12 fit | 15.62 [2–26] | 6.75 [0–16] | 10.12 [0–19] | 8 [3–14] |
| weeks below $0 | 28.12 [1–36] | 0 [0–0] | 3.50 [0–14] | 34 [28–38] |
| weeks below $0 (1-12) | 5.38 [0–9] | 0 [0–0] | 1 [0–4] | 8 [3–10] |
| account at week 40 | -6040.62 [-50493–38920] | 231873 [152069–332880] | 10040.25 [4530–25619] | -10287.75 [-47143–-1106] |
| lowest account | -29149 [-92123–-2633] | 39439 [38059–40496] | -8037.12 [-27904–1026] | -43992 [-91758–-16099] |
| highest account | 14863.25 [8537–48164] | 240478 [159999–339533] | 20193 [16508–26358] | 7422.75 [5369–10006] |
| situations unattended | 53.88 [46–60] | 86.38 [80–92] | 44.38 [31–52] | 31.88 [27–39] |
| officers killed | 24 [6–34] | 9.12 [5–15] | 14.12 [12–18] | 21.38 [15–28] |
| killed per operation | 0.33 [0.08–0.48] | 0.23 [0.13–0.38] | 0.17 [0.14–0.21] | 0.23 [0.15–0.29] |
| civilians killed | 5.25 [0–12] | 2.88 [0–13] | 5 [0–12] | 7.75 [1–16] |
| findings | 76.12 [47–94] | 41.62 [24–64] | 55.25 [40–85] | 83.62 [60–109] |
| allies lost at the end | 2.50 [1–3] | 1.12 [1–2] | 2.50 [2–3] | 2.75 [2–3] |
| allies won back | 2.38 [1–3] | 0 [0–0] | 0 [0–0] | 2.62 [2–4] |
| run score | -589.25 [-975–-87] | -390.50 [-824–-222] | -285.62 [-632–-103] | -603 [-881–-304] |
| chief kept | 7/8 | 8/8 | 6/8 | 7/8 |

## Gate 1 bands — asserting

```
MISS roster-floor               cautious     >= 10  (got 2)
MISS roster-floor               minimal      >= 10  (got 4)
MISS roster-floor               military     >= 10  (got 7)
MISS roster-floor               accept_all   >= 10  (got 4)
MISS roster-weeks               cautious     <= 8  (got 26)
MISS roster-weeks               minimal      <= 8  (got 16)
MISS roster-weeks               military     <= 8  (got 19)
MISS roster-weeks               accept_all   <= 8  (got 14)
MISS money-deficit              cautious     <= 8  (got 36)
ok   money-deficit              minimal      <= 8  (got 0)
MISS money-deficit              military     <= 8  (got 14)
MISS money-deficit              accept_all   <= 8  (got 38)
MISS money-debt                 cautious     >= -75000  (got -92123)
ok   money-debt                 minimal      >= -75000  (got 38059)
ok   money-debt                 military     >= -75000  (got -27904)
MISS money-debt                 accept_all   >= -75000  (got -91758)
MISS money-end                  cautious     >= 0  (got -6040.62)
ok   money-end                  minimal      >= 0  (got 231873)
ok   money-end                  military     >= 0  (got 10040.25)
MISS money-end                  accept_all   >= 0  (got -10287.75)
MISS coverage                   cautious     <= 48  (got 53.88)
MISS coverage                   minimal      <= 48  (got 86.38)
ok   coverage                   military     <= 48  (got 44.38)
ok   coverage                   accept_all   <= 48  (got 31.88)
MISS deaths                     cautious     <= 8  (got 24)
MISS deaths                     minimal      <= 8  (got 9.12)
MISS deaths                     military     <= 8  (got 14.12)
MISS deaths                     accept_all   <= 8  (got 21.38)
MISS lethality                  cautious     <= 0.15  (got 0.48)
MISS lethality                  minimal      <= 0.15  (got 0.38)
MISS lethality                  military     <= 0.15  (got 0.21)
MISS lethality                  accept_all   <= 0.15  (got 0.29)
ok   civilians                  cautious     <= 6  (got 5.25)
ok   civilians                  minimal      <= 6  (got 2.88)
ok   civilians                  military     <= 6  (got 5)
MISS civilians                  accept_all   <= 6  (got 7.75)
MISS allies-held                cautious     <= 2  (got 2.50)
ok   allies-held                minimal      <= 2  (got 1.12)
MISS allies-held                military     <= 2  (got 2.50)
MISS allies-held                accept_all   <= 2  (got 2.75)
ok   ally-recovery              cautious     >= 0.25  (got 2.38)
MISS ally-recovery              minimal      >= 0.25  (got 0)
MISS ally-recovery              military     >= 0.25  (got 0)
ok   ally-recovery              accept_all   >= 0.25  (got 2.62)
MISS score                      cautious     >= 0  (got -589.25)
MISS score                      minimal      >= 0  (got -390.50)
MISS score                      military     >= 0  (got -285.62)
MISS score                      accept_all   >= 0  (got -603)
ok   election                   cautious     >= 0.50  (got 0.88)
ok   election                   minimal      >= 0.50  (got 1)
ok   election                   military     >= 0.50  (got 0.75)
ok   election                   accept_all   >= 0.50  (got 0.88)
```

35 band miss(es); report-only until P1.I (balance_bands.json "enforce").

## What each policy does

- **cautious** — Hire to 14 (an emergency lateral below 12 fit, a standing order for 18 on the books), train, restraint contracts, no military hardware, take the suggested raid kit, answer the gravest two calls and keep high-trauma officers off crowd duty.
- **minimal** — No hiring, no courses, no contracts, no programs, every offer declined, cases left to lapse, one call a week.
- **military-first** — Military contracts and kit, Kettering's offers, cases cleared, hire to 16 (an emergency lateral below 12 fit), three calls a week including crowd events.
- **accept-all** — Sign the cheapest contract and program on the desk, accept every offer and answer every event, hire to 18 (a standing order for 20 on the books), let plans buy kit, three calls a week.