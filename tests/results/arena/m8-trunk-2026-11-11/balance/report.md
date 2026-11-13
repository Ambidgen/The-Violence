# Run-layer balance — 8 seed(s) × 4 policy(ies), 40 weeks

32 run(s), 10103 s wall clock, 4.7.2-stable (official).

| metric | cautious | minimal | military-first | accept-all |
|---|---|---|---|---|
| lowest fit officers | 5.88 [3–9] | 9.50 [1–14] | 6.88 [5–8] | 6.12 [2–11] |
| weeks under 12 fit | 16.38 [11–28] | 5.88 [0–18] | 16.62 [10–22] | 15.88 [4–25] |
| weeks below $0 | 31.50 [28–33] | 0 [0–0] | 10 [3–18] | 31.75 [28–35] |
| weeks below $0 (1-12) | 5.25 [4–7] | 0 [0–0] | 2.38 [0–6] | 6.62 [2–10] |
| account at week 40 | -13169 [-45545–-772] | 185232 [47477–452032] | 2404.88 [-73444–22313] | -23971.75 [-72473–-2285] |
| lowest account | -54810 [-113951–-19836] | 37533 [35492–38984] | -34126.62 [-73444–-2836] | -64189 [-118452–-14538] |
| highest account | 8583 [5766–11630] | 203429 [91159–452032] | 20043 [16070–22313] | 6471 [4616–8951] |
| situations unattended | 55.38 [46–68] | 87.75 [78–95] | 46.62 [39–55] | 37 [18–49] |
| officers killed | 16 [9–25] | 7.25 [3–16] | 12 [10–16] | 16 [11–20] |
| killed per operation | 0.17 [0.08–0.28] | 0.10 [0.05–0.25] | 0.11 [0.08–0.15] | 0.14 [0.09–0.19] |
| civilians killed | 5.12 [1–13] | 2.62 [1–4] | 5.50 [1–13] | 6.12 [2–12] |
| findings | 68.50 [58–84] | 37.50 [22–56] | 61.62 [47–88] | 79.88 [67–94] |
| allies lost at the end | 2.88 [2–3] | 1.12 [1–2] | 3 [2–4] | 3 [2–4] |
| allies won back | 2.12 [0–3] | 0 [0–0] | 0 [0–0] | 1.75 [1–3] |
| run score | -122.12 [-479–103] | 5.38 [-262–286] | 24 [-382–260] | 9.25 [-476–225] |
| chief kept | 8/8 | 8/8 | 8/8 | 6/8 |

## Gate 1 bands — asserting

```
MISS roster-floor               cautious     >= 10  (got 3)
MISS roster-floor               minimal      >= 10  (got 1)
MISS roster-floor               military     >= 10  (got 5)
MISS roster-floor               accept_all   >= 10  (got 2)
MISS roster-weeks               cautious     <= 8  (got 28)
MISS roster-weeks               minimal      <= 8  (got 18)
MISS roster-weeks               military     <= 8  (got 22)
MISS roster-weeks               accept_all   <= 8  (got 25)
MISS money-deficit              cautious     <= 8  (got 33)
ok   money-deficit              minimal      <= 8  (got 0)
MISS money-deficit              military     <= 8  (got 18)
MISS money-deficit              accept_all   <= 8  (got 35)
MISS money-debt                 cautious     >= -75000  (got -113951)
ok   money-debt                 minimal      >= -75000  (got 35492)
ok   money-debt                 military     >= -75000  (got -73444)
MISS money-debt                 accept_all   >= -75000  (got -118452)
MISS money-end                  cautious     >= 0  (got -13169)
ok   money-end                  minimal      >= 0  (got 185232)
ok   money-end                  military     >= 0  (got 2404.88)
MISS money-end                  accept_all   >= 0  (got -23971.75)
MISS coverage                   cautious     <= 48  (got 55.38)
MISS coverage                   minimal      <= 48  (got 87.75)
ok   coverage                   military     <= 48  (got 46.62)
ok   coverage                   accept_all   <= 48  (got 37)
MISS deaths                     cautious     <= 8  (got 16)
ok   deaths                     minimal      <= 8  (got 7.25)
MISS deaths                     military     <= 8  (got 12)
MISS deaths                     accept_all   <= 8  (got 16)
MISS lethality                  cautious     <= 0.15  (got 0.28)
MISS lethality                  minimal      <= 0.15  (got 0.25)
ok   lethality                  military     <= 0.15  (got 0.15)
MISS lethality                  accept_all   <= 0.15  (got 0.19)
ok   civilians                  cautious     <= 6  (got 5.12)
ok   civilians                  minimal      <= 6  (got 2.62)
ok   civilians                  military     <= 6  (got 5.50)
MISS civilians                  accept_all   <= 6  (got 6.12)
MISS allies-held                cautious     <= 2  (got 2.88)
ok   allies-held                minimal      <= 2  (got 1.12)
MISS allies-held                military     <= 2  (got 3)
MISS allies-held                accept_all   <= 2  (got 3)
ok   ally-recovery              cautious     >= 0.25  (got 2.12)
MISS ally-recovery              minimal      >= 0.25  (got 0)
MISS ally-recovery              military     >= 0.25  (got 0)
ok   ally-recovery              accept_all   >= 0.25  (got 1.75)
MISS score                      cautious     >= 0  (got -122.12)
ok   score                      minimal      >= 0  (got 5.38)
ok   score                      military     >= 0  (got 24)
ok   score                      accept_all   >= 0  (got 9.25)
ok   election                   cautious     >= 0.50  (got 1)
ok   election                   minimal      >= 0.50  (got 1)
ok   election                   military     >= 0.50  (got 1)
ok   election                   accept_all   >= 0.50  (got 0.75)
```

30 band miss(es); report-only until P1.I (balance_bands.json "enforce").

## What each policy does

- **cautious** — Hire to 14 (an emergency lateral below 12 fit, a standing order for 18 on the books), train, restraint contracts, no military hardware, take the suggested raid kit, answer the gravest two calls and keep high-trauma officers off crowd duty.
- **minimal** — No hiring, no courses, no contracts, no programs, every offer declined, cases left to lapse, one call a week.
- **military-first** — Military contracts and kit, Carrick's offers, cases cleared, hire to 16 (an emergency lateral below 12 fit), three calls a week including crowd events.
- **accept-all** — Sign the cheapest contract and program on the desk, accept every offer and answer every event, hire to 18 (a standing order for 20 on the books), let plans buy kit, three calls a week.