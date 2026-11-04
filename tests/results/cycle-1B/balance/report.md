# Run-layer balance — 20 seed(s) × 4 policy(ies), 40 weeks

80 run(s), 8316 s wall clock, 4.7.2-stable (official).

| metric | cautious | minimal | military-first | accept-all |
|---|---|---|---|---|
| lowest fit officers | 5.55 [3–8] | 8.55 [2–15] | 4.95 [1–8] | 5.45 [3–9] |
| weeks under 12 fit | 22.70 [13–34] | 10.75 [0–38] | 26.85 [14–36] | 21.40 [10–31] |
| weeks below $0 | 5.05 [0–13] | 0 [0–0] | 7.95 [1–26] | 9.15 [2–20] |
| weeks below $0 (1-12) | 1.40 [0–5] | 0 [0–0] | 3.15 [1–11] | 2.10 [0–7] |
| account at week 40 | 6954.85 [-58335–44854] | 398966 [182749–608118] | 7940.80 [-54500–55219] | 4862.50 [-65384–39623] |
| lowest account | -28931 [-68306–3120] | 37291 [18402–40556] | -36557 [-164667–-1032] | -35080 [-128367–-2987] |
| highest account | 26302 [17385–44854] | 404018 [182749–608118] | 26470.30 [18061–56959] | 21663 [12495–58122] |
| situations unattended | 58.40 [50–73] | 85.05 [74–92] | 57.10 [46–70] | 42.35 [27–55] |
| officers killed | 20.70 [15–32] | 9.55 [4–18] | 16 [9–21] | 20.15 [11–28] |
| killed per operation | 0.31 [0.19–0.52] | 0.25 [0.10–0.50] | 0.25 [0.11–0.40] | 0.25 [0.12–0.35] |
| civilians killed | 4.80 [0–12] | 2.80 [0–10] | 4.95 [1–11] | 4.90 [0–11] |
| findings | 73.15 [39–104] | 41.05 [22–81] | 73.10 [50–97] | 83.10 [58–111] |
| allies lost at the end | 3 [3–3] | 2.10 [1–4] | 3.55 [3–4] | 3.55 [3–4] |
| allies won back | 0 [0–0] | 0.05 [0–1] | 0 [0–0] | 0 [0–0] |
| run score | -707.10 [-972–-397] | -431.10 [-972–-183] | -565.55 [-1018–-176] | -670.60 [-973–-222] |
| chief kept | 16/20 | 19/20 | 16/20 | 14/20 |

## Gate 1 bands — report-only

```
MISS roster-floor               cautious     >= 10  (got 3)
MISS roster-floor               minimal      >= 10  (got 2)
MISS roster-floor               military     >= 10  (got 1)
MISS roster-floor               accept_all   >= 10  (got 3)
MISS roster-weeks               cautious     <= 8  (got 34)
MISS roster-weeks               minimal      <= 8  (got 38)
MISS roster-weeks               military     <= 8  (got 36)
MISS roster-weeks               accept_all   <= 8  (got 31)
MISS money-deficit              cautious     <= 8  (got 13)
ok   money-deficit              minimal      <= 8  (got 0)
MISS money-deficit              military     <= 8  (got 26)
MISS money-deficit              accept_all   <= 8  (got 20)
ok   money-debt                 cautious     >= -75000  (got -68306)
ok   money-debt                 minimal      >= -75000  (got 18402)
MISS money-debt                 military     >= -75000  (got -164667)
MISS money-debt                 accept_all   >= -75000  (got -128367)
ok   money-end                  cautious     >= 0  (got 6954.85)
ok   money-end                  minimal      >= 0  (got 398966)
ok   money-end                  military     >= 0  (got 7940.80)
ok   money-end                  accept_all   >= 0  (got 4862.50)
MISS coverage                   cautious     <= 48  (got 58.40)
MISS coverage                   minimal      <= 48  (got 85.05)
MISS coverage                   military     <= 48  (got 57.10)
ok   coverage                   accept_all   <= 48  (got 42.35)
MISS deaths                     cautious     <= 8  (got 20.70)
MISS deaths                     minimal      <= 8  (got 9.55)
MISS deaths                     military     <= 8  (got 16)
MISS deaths                     accept_all   <= 8  (got 20.15)
MISS lethality                  cautious     <= 0.15  (got 0.52)
MISS lethality                  minimal      <= 0.15  (got 0.50)
MISS lethality                  military     <= 0.15  (got 0.40)
MISS lethality                  accept_all   <= 0.15  (got 0.35)
ok   civilians                  cautious     <= 6  (got 4.80)
ok   civilians                  minimal      <= 6  (got 2.80)
ok   civilians                  military     <= 6  (got 4.95)
ok   civilians                  accept_all   <= 6  (got 4.90)
MISS allies-held                cautious     <= 2  (got 3)
MISS allies-held                minimal      <= 2  (got 2.10)
MISS allies-held                military     <= 2  (got 3.55)
MISS allies-held                accept_all   <= 2  (got 3.55)
MISS ally-recovery              cautious     >= 0.25  (got 0)
MISS ally-recovery              minimal      >= 0.25  (got 0.05)
MISS ally-recovery              military     >= 0.25  (got 0)
MISS ally-recovery              accept_all   >= 0.25  (got 0)
MISS score                      cautious     >= 0  (got -707.10)
MISS score                      minimal      >= 0  (got -431.10)
MISS score                      military     >= 0  (got -565.55)
MISS score                      accept_all   >= 0  (got -670.60)
ok   election                   cautious     >= 0.50  (got 0.80)
ok   election                   minimal      >= 0.50  (got 0.95)
ok   election                   military     >= 0.50  (got 0.80)
ok   election                   accept_all   >= 0.50  (got 0.70)
```

36 band miss(es); report-only until P1.I (balance_bands.json "enforce").

## What each policy does

- **cautious** — Hire to 14, train, restraint contracts, no military hardware, answer the gravest two calls and keep high-trauma officers off crowd duty.
- **minimal** — No hiring, no courses, no contracts, no programs, every offer declined, cases left to lapse, one call a week.
- **military-first** — Military contracts and kit, Kettering's offers, cases cleared, hire to 16, three calls a week including crowd events.
- **accept-all** — Sign the cheapest contract and program on the desk, accept every offer and answer every event, hire to 18, let plans buy kit, three calls a week.