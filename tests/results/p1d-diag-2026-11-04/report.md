# Run-layer balance — 1 seed(s) × 4 policy(ies), 40 weeks

4 run(s), 2914 s wall clock, 4.7.2-stable (official).

| metric | cautious | minimal | military-first | accept-all |
|---|---|---|---|---|
| lowest fit officers | 8 [8–8] | 14 [14–14] | 7 [7–7] | 6 [6–6] |
| weeks under 12 fit | 17 [17–17] | 0 [0–0] | 26 [26–26] | 14 [14–14] |
| weeks below $0 | 33 [33–33] | 0 [0–0] | 3 [3–3] | 33 [33–33] |
| weeks below $0 (1-12) | 10 [10–10] | 0 [0–0] | 3 [3–3] | 7 [7–7] |
| account at week 40 | -8723 [-8723–-8723] | 113457 [113457–113457] | 11236 [11236–11236] | 459 [459–459] |
| lowest account | -17910 [-17910–-17910] | 40494 [40494–40494] | -3090 [-3090–-3090] | -19643 [-19643–-19643] |
| highest account | 8046 [8046–8046] | 125638 [125638–125638] | 17837 [17837–17837] | 9171 [9171–9171] |
| situations unattended | 50 [50–50] | 83 [83–83] | 51 [51–51] | 34 [34–34] |
| officers killed | 29 [29–29] | 5 [5–5] | 15 [15–15] | 25 [25–25] |
| killed per operation | 0.39 [0.39–0.39] | 0.13 [0.13–0.13] | 0.21 [0.21–0.21] | 0.28 [0.28–0.28] |
| civilians killed | 2 [2–2] | 2 [2–2] | 3 [3–3] | 1 [1–1] |
| findings | 85 [85–85] | 22 [22–22] | 52 [52–52] | 67 [67–67] |
| allies lost at the end | 2 [2–2] | 1 [1–1] | 3 [3–3] | 3 [3–3] |
| allies won back | 0 [0–0] | 0 [0–0] | 0 [0–0] | 0 [0–0] |
| run score | -791 [-791–-791] | -264 [-264–-264] | -405 [-405–-405] | -554 [-554–-554] |
| chief kept | 1/1 | 1/1 | 1/1 | 1/1 |

## Gate 1 bands — asserting

```
MISS roster-floor               cautious     >= 10  (got 8)
ok   roster-floor               minimal      >= 10  (got 14)
MISS roster-floor               military     >= 10  (got 7)
MISS roster-floor               accept_all   >= 10  (got 6)
MISS roster-weeks               cautious     <= 8  (got 17)
ok   roster-weeks               minimal      <= 8  (got 0)
MISS roster-weeks               military     <= 8  (got 26)
MISS roster-weeks               accept_all   <= 8  (got 14)
MISS money-deficit              cautious     <= 8  (got 33)
ok   money-deficit              minimal      <= 8  (got 0)
ok   money-deficit              military     <= 8  (got 3)
MISS money-deficit              accept_all   <= 8  (got 33)
ok   money-debt                 cautious     >= -75000  (got -17910)
ok   money-debt                 minimal      >= -75000  (got 40494)
ok   money-debt                 military     >= -75000  (got -3090)
ok   money-debt                 accept_all   >= -75000  (got -19643)
MISS money-end                  cautious     >= 0  (got -8723)
ok   money-end                  minimal      >= 0  (got 113457)
ok   money-end                  military     >= 0  (got 11236)
ok   money-end                  accept_all   >= 0  (got 459)
MISS coverage                   cautious     <= 48  (got 50)
MISS coverage                   minimal      <= 48  (got 83)
MISS coverage                   military     <= 48  (got 51)
ok   coverage                   accept_all   <= 48  (got 34)
MISS deaths                     cautious     <= 8  (got 29)
ok   deaths                     minimal      <= 8  (got 5)
MISS deaths                     military     <= 8  (got 15)
MISS deaths                     accept_all   <= 8  (got 25)
MISS lethality                  cautious     <= 0.15  (got 0.39)
ok   lethality                  minimal      <= 0.15  (got 0.13)
MISS lethality                  military     <= 0.15  (got 0.21)
MISS lethality                  accept_all   <= 0.15  (got 0.28)
ok   civilians                  cautious     <= 6  (got 2)
ok   civilians                  minimal      <= 6  (got 2)
ok   civilians                  military     <= 6  (got 3)
ok   civilians                  accept_all   <= 6  (got 1)
ok   allies-held                cautious     <= 2  (got 2)
ok   allies-held                minimal      <= 2  (got 1)
MISS allies-held                military     <= 2  (got 3)
MISS allies-held                accept_all   <= 2  (got 3)
MISS ally-recovery              cautious     >= 0.25  (got 0)
MISS ally-recovery              minimal      >= 0.25  (got 0)
MISS ally-recovery              military     >= 0.25  (got 0)
MISS ally-recovery              accept_all   >= 0.25  (got 0)
MISS score                      cautious     >= 0  (got -791)
MISS score                      minimal      >= 0  (got -264)
MISS score                      military     >= 0  (got -405)
MISS score                      accept_all   >= 0  (got -554)
ok   election                   cautious     >= 0.50  (got 1)
ok   election                   minimal      >= 0.50  (got 1)
ok   election                   military     >= 0.50  (got 1)
ok   election                   accept_all   >= 0.50  (got 1)
```

28 band miss(es); report-only until P1.I (balance_bands.json "enforce").

## What each policy does

- **cautious** — Hire to 14 (an emergency lateral below 12 fit, a standing order for 18 on the books), train, restraint contracts, no military hardware, take the suggested raid kit, answer the gravest two calls and keep high-trauma officers off crowd duty.
- **minimal** — No hiring, no courses, no contracts, no programs, every offer declined, cases left to lapse, one call a week.
- **military-first** — Military contracts and kit, Kettering's offers, cases cleared, hire to 16 (an emergency lateral below 12 fit), three calls a week including crowd events.
- **accept-all** — Sign the cheapest contract and program on the desk, accept every offer and answer every event, hire to 18 (a standing order for 20 on the books), let plans buy kit, three calls a week.