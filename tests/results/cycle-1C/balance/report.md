# Run-layer balance — 20 seed(s) × 4 policy(ies), 40 weeks

80 run(s), 8661 s wall clock, 4.7.2-stable (official).

| metric | cautious | minimal | military-first | accept-all |
|---|---|---|---|---|
| lowest fit officers | 4.90 [2–9] | 8.55 [2–15] | 5 [1–8] | 5.55 [2–8] |
| weeks under 12 fit | 18.85 [3–34] | 10.75 [0–38] | 26.85 [14–35] | 20.10 [10–31] |
| weeks below $0 | 29.45 [20–38] | 0 [0–0] | 7.70 [1–26] | 32.75 [27–38] |
| weeks below $0 (1-12) | 6 [2–11] | 0 [0–0] | 3.15 [1–11] | 7.50 [3–12] |
| account at week 40 | -6742.70 [-38276–5607] | 398966 [182749–608118] | 5232.65 [-74803–31834] | -7221.90 [-31431–-16] |
| lowest account | -40405.50 [-176546–-6699] | 37291 [18402–40556] | -36658 [-166690–-1032] | -36899 [-107255–-7446] |
| highest account | 8233 [3232–12773] | 404018 [182749–608118] | 23454.50 [18061–31834] | 5598.90 [598–12916] |
| situations unattended | 55.80 [46–69] | 85.05 [74–92] | 57.60 [46–71] | 41.35 [25–59] |
| officers killed | 24.55 [15–32] | 9.55 [4–18] | 15.85 [9–20] | 21.90 [11–29] |
| killed per operation | 0.35 [0.19–0.49] | 0.25 [0.10–0.50] | 0.25 [0.11–0.38] | 0.27 [0.12–0.36] |
| civilians killed | 5.50 [1–18] | 2.80 [0–10] | 4.95 [1–12] | 5.65 [0–12] |
| findings | 86.85 [36–127] | 41.05 [22–81] | 72.95 [50–94] | 84.55 [63–126] |
| allies lost at the end | 3.10 [3–4] | 2.10 [1–4] | 3.55 [3–4] | 3.75 [3–4] |
| allies won back | 0 [0–0] | 0.05 [0–1] | 0 [0–0] | 0 [0–0] |
| run score | -892.10 [-1419–-276] | -431.10 [-972–-183] | -569.25 [-1045–-283] | -742.65 [-1232–-309] |
| chief kept | 12/20 | 19/20 | 15/20 | 15/20 |

## Gate 1 bands — report-only

```
MISS roster-floor               cautious     >= 10  (got 2)
MISS roster-floor               minimal      >= 10  (got 2)
MISS roster-floor               military     >= 10  (got 1)
MISS roster-floor               accept_all   >= 10  (got 2)
MISS roster-weeks               cautious     <= 8  (got 34)
MISS roster-weeks               minimal      <= 8  (got 38)
MISS roster-weeks               military     <= 8  (got 35)
MISS roster-weeks               accept_all   <= 8  (got 31)
MISS money-deficit              cautious     <= 8  (got 38)
ok   money-deficit              minimal      <= 8  (got 0)
MISS money-deficit              military     <= 8  (got 26)
MISS money-deficit              accept_all   <= 8  (got 38)
MISS money-debt                 cautious     >= -75000  (got -176546)
ok   money-debt                 minimal      >= -75000  (got 18402)
MISS money-debt                 military     >= -75000  (got -166690)
MISS money-debt                 accept_all   >= -75000  (got -107255)
MISS money-end                  cautious     >= 0  (got -6742.70)
ok   money-end                  minimal      >= 0  (got 398966)
ok   money-end                  military     >= 0  (got 5232.65)
MISS money-end                  accept_all   >= 0  (got -7221.90)
MISS coverage                   cautious     <= 48  (got 55.80)
MISS coverage                   minimal      <= 48  (got 85.05)
MISS coverage                   military     <= 48  (got 57.60)
ok   coverage                   accept_all   <= 48  (got 41.35)
MISS deaths                     cautious     <= 8  (got 24.55)
MISS deaths                     minimal      <= 8  (got 9.55)
MISS deaths                     military     <= 8  (got 15.85)
MISS deaths                     accept_all   <= 8  (got 21.90)
MISS lethality                  cautious     <= 0.15  (got 0.49)
MISS lethality                  minimal      <= 0.15  (got 0.50)
MISS lethality                  military     <= 0.15  (got 0.38)
MISS lethality                  accept_all   <= 0.15  (got 0.36)
ok   civilians                  cautious     <= 6  (got 5.50)
ok   civilians                  minimal      <= 6  (got 2.80)
ok   civilians                  military     <= 6  (got 4.95)
ok   civilians                  accept_all   <= 6  (got 5.65)
MISS allies-held                cautious     <= 2  (got 3.10)
MISS allies-held                minimal      <= 2  (got 2.10)
MISS allies-held                military     <= 2  (got 3.55)
MISS allies-held                accept_all   <= 2  (got 3.75)
MISS ally-recovery              cautious     >= 0.25  (got 0)
MISS ally-recovery              minimal      >= 0.25  (got 0.05)
MISS ally-recovery              military     >= 0.25  (got 0)
MISS ally-recovery              accept_all   >= 0.25  (got 0)
MISS score                      cautious     >= 0  (got -892.10)
MISS score                      minimal      >= 0  (got -431.10)
MISS score                      military     >= 0  (got -569.25)
MISS score                      accept_all   >= 0  (got -742.65)
ok   election                   cautious     >= 0.50  (got 0.60)
ok   election                   minimal      >= 0.50  (got 0.95)
ok   election                   military     >= 0.50  (got 0.75)
ok   election                   accept_all   >= 0.50  (got 0.75)
```

39 band miss(es); report-only until P1.I (balance_bands.json "enforce").

## What each policy does

- **cautious** — Hire to 14 (an emergency lateral below 12 fit, a standing order for 18 on the books), train, restraint contracts, no military hardware, take the suggested raid kit, answer the gravest two calls and keep high-trauma officers off crowd duty.
- **minimal** — No hiring, no courses, no contracts, no programs, every offer declined, cases left to lapse, one call a week.
- **military-first** — Military contracts and kit, Kettering's offers, cases cleared, hire to 16 (an emergency lateral below 12 fit), three calls a week including crowd events.
- **accept-all** — Sign the cheapest contract and program on the desk, accept every offer and answer every event, hire to 18 (a standing order for 20 on the books), let plans buy kit, three calls a week.