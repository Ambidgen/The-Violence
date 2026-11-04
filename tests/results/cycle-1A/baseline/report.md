# Run-layer balance — 20 seed(s) × 4 policy(ies), 40 weeks

80 run(s), 7820 s wall clock, 4.7.2-stable (official).

| metric | cautious | minimal | military-first | accept-all |
|---|---|---|---|---|
| lowest fit officers | 5.40 [1–8] | 9.30 [4–16] | 5.55 [3–9] | 4.05 [0–9] |
| weeks under 12 fit | 23.60 [12–36] | 11.10 [0–38] | 26.30 [20–34] | 22.85 [10–32] |
| weeks below $0 | 8.10 [0–33] | 2.25 [0–23] | 10.20 [2–24] | 14.70 [0–35] |
| weeks below $0 (1-12) | 1.20 [0–5] | 0 [0–0] | 3.10 [0–11] | 2.55 [0–8] |
| account at week 40 | -15768 [-363589–36960] | 267324 [-89158–591246] | -18075.35 [-177450–21707] | -38497 [-268275–18686] |
| lowest account | -62485 [-474734–2752] | 11379.80 [-206510–40556] | -60116 [-205215–-2058] | -101314 [-387140–192] |
| highest account | 30294 [6404–56640] | 312882 [110690–591246] | 21098 [16029–28574] | 20759.70 [7881–48207] |
| situations unattended | 59.95 [49–72] | 84.75 [74–92] | 55.80 [45–63] | 45.40 [35–62] |
| officers killed | 20.70 [11–30] | 9.05 [4–15] | 14.70 [10–19] | 20.65 [10–29] |
| killed per operation | 0.32 [0.17–0.48] | 0.23 [0.10–0.39] | 0.22 [0.14–0.31] | 0.26 [0.11–0.38] |
| civilians killed | 10.95 [1–48] | 12.35 [1–39] | 10.20 [2–27] | 15.80 [4–44] |
| findings | 82.90 [49–165] | 66.20 [27–118] | 86 [48–136] | 111.40 [76–170] |
| allies lost at the end | 3.20 [3–4] | 2.80 [1–4] | 3.75 [3–4] | 3.90 [3–4] |
| allies won back | 0 [0–0] | 0.05 [0–1] | 0 [0–0] | 0 [0–0] |
| run score | -962.40 [-2330–-483] | -861.50 [-2033–-254] | -752.75 [-1371–-396] | -1190.15 [-2183–-662] |
| chief kept | 16/20 | 11/20 | 13/20 | 8/20 |

## Gate 1 bands — report-only

```
MISS roster-floor               cautious     >= 10  (got 1)
MISS roster-floor               minimal      >= 10  (got 4)
MISS roster-floor               military     >= 10  (got 3)
MISS roster-floor               accept_all   >= 10  (got 0)
MISS roster-weeks               cautious     <= 8  (got 36)
MISS roster-weeks               minimal      <= 8  (got 38)
MISS roster-weeks               military     <= 8  (got 34)
MISS roster-weeks               accept_all   <= 8  (got 32)
MISS money-deficit              cautious     <= 8  (got 33)
MISS money-deficit              minimal      <= 8  (got 23)
MISS money-deficit              military     <= 8  (got 24)
MISS money-deficit              accept_all   <= 8  (got 35)
MISS money-debt                 cautious     >= -75000  (got -474734)
MISS money-debt                 minimal      >= -75000  (got -206510)
MISS money-debt                 military     >= -75000  (got -205215)
MISS money-debt                 accept_all   >= -75000  (got -387140)
MISS money-end                  cautious     >= 0  (got -15768)
ok   money-end                  minimal      >= 0  (got 267324)
MISS money-end                  military     >= 0  (got -18075.35)
MISS money-end                  accept_all   >= 0  (got -38497)
MISS coverage                   cautious     <= 48  (got 59.95)
MISS coverage                   minimal      <= 48  (got 84.75)
MISS coverage                   military     <= 48  (got 55.80)
ok   coverage                   accept_all   <= 48  (got 45.40)
MISS deaths                     cautious     <= 8  (got 20.70)
MISS deaths                     minimal      <= 8  (got 9.05)
MISS deaths                     military     <= 8  (got 14.70)
MISS deaths                     accept_all   <= 8  (got 20.65)
MISS lethality                  cautious     <= 0.15  (got 0.48)
MISS lethality                  minimal      <= 0.15  (got 0.39)
MISS lethality                  military     <= 0.15  (got 0.31)
MISS lethality                  accept_all   <= 0.15  (got 0.38)
MISS civilians                  cautious     <= 6  (got 10.95)
MISS civilians                  minimal      <= 6  (got 12.35)
MISS civilians                  military     <= 6  (got 10.20)
MISS civilians                  accept_all   <= 6  (got 15.80)
MISS allies-held                cautious     <= 2  (got 3.20)
MISS allies-held                minimal      <= 2  (got 2.80)
MISS allies-held                military     <= 2  (got 3.75)
MISS allies-held                accept_all   <= 2  (got 3.90)
MISS ally-recovery              cautious     >= 0.25  (got 0)
MISS ally-recovery              minimal      >= 0.25  (got 0.05)
MISS ally-recovery              military     >= 0.25  (got 0)
MISS ally-recovery              accept_all   >= 0.25  (got 0)
MISS score                      cautious     >= 0  (got -962.40)
MISS score                      minimal      >= 0  (got -861.50)
MISS score                      military     >= 0  (got -752.75)
MISS score                      accept_all   >= 0  (got -1190.15)
ok   election                   cautious     >= 0.50  (got 0.80)
ok   election                   minimal      >= 0.50  (got 0.55)
ok   election                   military     >= 0.50  (got 0.65)
MISS election                   accept_all   >= 0.50  (got 0.40)
```

47 band miss(es); report-only until P1.I (balance_bands.json "enforce").

## What each policy does

- **cautious** — Hire to 14, train, restraint contracts, no military hardware, answer the gravest two calls and keep high-trauma officers off crowd duty.
- **minimal** — No hiring, no courses, no contracts, no programs, every offer declined, cases left to lapse, one call a week.
- **military-first** — Military contracts and kit, Kettering's offers, cases cleared, hire to 16, three calls a week including crowd events.
- **accept-all** — Sign the cheapest contract and program on the desk, accept every offer and answer every event, hire to 18, let plans buy kit, three calls a week.