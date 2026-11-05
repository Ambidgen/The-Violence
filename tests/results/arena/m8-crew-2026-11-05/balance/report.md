# Run-layer balance — 8 seed(s) × 4 policy(ies), 40 weeks

32 run(s), 5808 s wall clock, 4.7.2-stable (official).

| metric | cautious | minimal | military-first | accept-all |
|---|---|---|---|---|
| lowest fit officers | 7 [3–11] | 10.12 [2–14] | 6.25 [2–9] | 8.12 [3–14] |
| weeks under 12 fit | 9.50 [1–24] | 4.88 [0–28] | 17.50 [11–33] | 9.62 [0–24] |
| weeks below $0 | 26.50 [2–36] | 0 [0–0] | 5.50 [2–11] | 31.62 [27–36] |
| weeks below $0 (1-12) | 4.50 [0–9] | 0 [0–0] | 2.38 [0–5] | 6.75 [4–10] |
| account at week 40 | -10918.75 [-47291–25557] | 181977 [133333–310641] | 3065.75 [-29154–18480] | -5898.62 [-17771–2759] |
| lowest account | -31965 [-79712–-9498] | 38938 [37653–40494] | -13373.50 [-69199–-1162] | -43176 [-126139–-11954] |
| highest account | 13646.62 [8308–41056] | 192112 [140178–320931] | 20961 [16942–30158] | 7095.12 [5768–9171] |
| situations unattended | 52.62 [45–60] | 86.50 [78–93] | 53.25 [42–66] | 30.12 [12–45] |
| officers killed | 19.25 [13–28] | 7.38 [4–11] | 14.50 [12–19] | 16.62 [13–21] |
| killed per operation | 0.26 [0.16–0.40] | 0.19 [0.10–0.30] | 0.20 [0.15–0.31] | 0.18 [0.12–0.23] |
| civilians killed | 3.50 [0–6] | 1.88 [0–6] | 5.62 [1–12] | 6.38 [2–13] |
| findings | 71.88 [43–90] | 33.25 [17–54] | 69.12 [54–98] | 80.12 [50–108] |
| allies lost at the end | 2.25 [0–3] | 1.38 [1–2] | 2.75 [1–4] | 2.62 [0–4] |
| allies won back | 0 [0–0] | 0 [0–0] | 0 [0–0] | 0 [0–0] |
| run score | -409.88 [-849–104] | -285.38 [-481–-68] | -407.62 [-682–-95] | -415.75 [-794–23] |
| chief kept | 8/8 | 8/8 | 8/8 | 6/8 |

## Gate 1 bands — asserting

```
MISS roster-floor               cautious     >= 10  (got 3)
MISS roster-floor               minimal      >= 10  (got 2)
MISS roster-floor               military     >= 10  (got 2)
MISS roster-floor               accept_all   >= 10  (got 3)
MISS roster-weeks               cautious     <= 8  (got 24)
MISS roster-weeks               minimal      <= 8  (got 28)
MISS roster-weeks               military     <= 8  (got 33)
MISS roster-weeks               accept_all   <= 8  (got 24)
MISS money-deficit              cautious     <= 8  (got 36)
ok   money-deficit              minimal      <= 8  (got 0)
MISS money-deficit              military     <= 8  (got 11)
MISS money-deficit              accept_all   <= 8  (got 36)
MISS money-debt                 cautious     >= -75000  (got -79712)
ok   money-debt                 minimal      >= -75000  (got 37653)
ok   money-debt                 military     >= -75000  (got -69199)
MISS money-debt                 accept_all   >= -75000  (got -126139)
MISS money-end                  cautious     >= 0  (got -10918.75)
ok   money-end                  minimal      >= 0  (got 181977)
ok   money-end                  military     >= 0  (got 3065.75)
MISS money-end                  accept_all   >= 0  (got -5898.62)
MISS coverage                   cautious     <= 48  (got 52.62)
MISS coverage                   minimal      <= 48  (got 86.50)
MISS coverage                   military     <= 48  (got 53.25)
ok   coverage                   accept_all   <= 48  (got 30.12)
MISS deaths                     cautious     <= 8  (got 19.25)
ok   deaths                     minimal      <= 8  (got 7.38)
MISS deaths                     military     <= 8  (got 14.50)
MISS deaths                     accept_all   <= 8  (got 16.62)
MISS lethality                  cautious     <= 0.15  (got 0.40)
MISS lethality                  minimal      <= 0.15  (got 0.30)
MISS lethality                  military     <= 0.15  (got 0.31)
MISS lethality                  accept_all   <= 0.15  (got 0.23)
ok   civilians                  cautious     <= 6  (got 3.50)
ok   civilians                  minimal      <= 6  (got 1.88)
ok   civilians                  military     <= 6  (got 5.62)
MISS civilians                  accept_all   <= 6  (got 6.38)
MISS allies-held                cautious     <= 2  (got 2.25)
ok   allies-held                minimal      <= 2  (got 1.38)
MISS allies-held                military     <= 2  (got 2.75)
MISS allies-held                accept_all   <= 2  (got 2.62)
MISS ally-recovery              cautious     >= 0.25  (got 0)
MISS ally-recovery              minimal      >= 0.25  (got 0)
MISS ally-recovery              military     >= 0.25  (got 0)
MISS ally-recovery              accept_all   >= 0.25  (got 0)
MISS score                      cautious     >= 0  (got -409.88)
MISS score                      minimal      >= 0  (got -285.38)
MISS score                      military     >= 0  (got -407.62)
MISS score                      accept_all   >= 0  (got -415.75)
ok   election                   cautious     >= 0.50  (got 1)
ok   election                   minimal      >= 0.50  (got 1)
ok   election                   military     >= 0.50  (got 1)
ok   election                   accept_all   >= 0.50  (got 0.75)
```

37 band miss(es); report-only until P1.I (balance_bands.json "enforce").

## What each policy does

- **cautious** — Hire to 14 (an emergency lateral below 12 fit, a standing order for 18 on the books), train, restraint contracts, no military hardware, take the suggested raid kit, answer the gravest two calls and keep high-trauma officers off crowd duty.
- **minimal** — No hiring, no courses, no contracts, no programs, every offer declined, cases left to lapse, one call a week.
- **military-first** — Military contracts and kit, Kettering's offers, cases cleared, hire to 16 (an emergency lateral below 12 fit), three calls a week including crowd events.
- **accept-all** — Sign the cheapest contract and program on the desk, accept every offer and answer every event, hire to 18 (a standing order for 20 on the books), let plans buy kit, three calls a week.