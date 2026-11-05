# Run-layer balance — 8 seed(s) × 4 policy(ies), 40 weeks

32 run(s), 9391 s wall clock, 4.7.2-stable (official).

| metric | cautious | minimal | military-first | accept-all |
|---|---|---|---|---|
| lowest fit officers | 5.75 [2–8] | 9.12 [4–14] | 4.75 [2–7] | 4.75 [3–7] |
| weeks under 12 fit | 20.38 [9–33] | 6.88 [0–15] | 26.25 [15–32] | 16.25 [8–26] |
| weeks below $0 | 32.88 [27–37] | 0 [0–0] | 4.62 [1–11] | 35.62 [32–39] |
| weeks below $0 (1-12) | 6 [1–10] | 0 [0–0] | 3 [0–9] | 8.75 [7–12] |
| account at week 40 | -12324.75 [-21876–-4877] | 215117 [87932–287973] | 7988.88 [2273–14933] | -9856.75 [-28841–459] |
| lowest account | -36701 [-97179–-17910] | 38371 [35627–40494] | -10086.62 [-31019–-468] | -29838.62 [-50420–-16399] |
| highest account | 8338.12 [4162–10588] | 221096 [96050–287973] | 21891 [17837–27397] | 5724.12 [1374–9171] |
| situations unattended | 56.75 [48–69] | 86.88 [80–92] | 58.75 [48–70] | 38.50 [23–50] |
| officers killed | 22.38 [14–29] | 8.25 [5–13] | 17.38 [13–21] | 21.38 [12–29] |
| killed per operation | 0.32 [0.20–0.47] | 0.21 [0.13–0.33] | 0.27 [0.18–0.33] | 0.25 [0.14–0.35] |
| civilians killed | 5 [2–9] | 2.38 [0–6] | 4.88 [1–10] | 3.75 [1–7] |
| findings | 86.38 [76–109] | 40.88 [22–55] | 67.25 [52–84] | 85.25 [67–103] |
| allies lost at the end | 2.75 [2–3] | 1.38 [1–2] | 3 [1–4] | 3 [2–4] |
| allies won back | 0 [0–0] | 0 [0–0] | 0 [0–0] | 0 [0–0] |
| run score | -795 [-990–-514] | -403.62 [-601–-264] | -575 [-848–-234] | -615.88 [-995–-405] |
| chief kept | 8/8 | 8/8 | 8/8 | 8/8 |

## Gate 1 bands — asserting

```
MISS roster-floor               cautious     >= 10  (got 2)
MISS roster-floor               minimal      >= 10  (got 4)
MISS roster-floor               military     >= 10  (got 2)
MISS roster-floor               accept_all   >= 10  (got 3)
MISS roster-weeks               cautious     <= 8  (got 33)
MISS roster-weeks               minimal      <= 8  (got 15)
MISS roster-weeks               military     <= 8  (got 32)
MISS roster-weeks               accept_all   <= 8  (got 26)
MISS money-deficit              cautious     <= 8  (got 37)
ok   money-deficit              minimal      <= 8  (got 0)
MISS money-deficit              military     <= 8  (got 11)
MISS money-deficit              accept_all   <= 8  (got 39)
MISS money-debt                 cautious     >= -75000  (got -97179)
ok   money-debt                 minimal      >= -75000  (got 35627)
ok   money-debt                 military     >= -75000  (got -31019)
ok   money-debt                 accept_all   >= -75000  (got -50420)
MISS money-end                  cautious     >= 0  (got -12324.75)
ok   money-end                  minimal      >= 0  (got 215117)
ok   money-end                  military     >= 0  (got 7988.88)
MISS money-end                  accept_all   >= 0  (got -9856.75)
MISS coverage                   cautious     <= 48  (got 56.75)
MISS coverage                   minimal      <= 48  (got 86.88)
MISS coverage                   military     <= 48  (got 58.75)
ok   coverage                   accept_all   <= 48  (got 38.50)
MISS deaths                     cautious     <= 8  (got 22.38)
MISS deaths                     minimal      <= 8  (got 8.25)
MISS deaths                     military     <= 8  (got 17.38)
MISS deaths                     accept_all   <= 8  (got 21.38)
MISS lethality                  cautious     <= 0.15  (got 0.47)
MISS lethality                  minimal      <= 0.15  (got 0.33)
MISS lethality                  military     <= 0.15  (got 0.33)
MISS lethality                  accept_all   <= 0.15  (got 0.35)
ok   civilians                  cautious     <= 6  (got 5)
ok   civilians                  minimal      <= 6  (got 2.38)
ok   civilians                  military     <= 6  (got 4.88)
ok   civilians                  accept_all   <= 6  (got 3.75)
MISS allies-held                cautious     <= 2  (got 2.75)
ok   allies-held                minimal      <= 2  (got 1.38)
MISS allies-held                military     <= 2  (got 3)
MISS allies-held                accept_all   <= 2  (got 3)
MISS ally-recovery              cautious     >= 0.25  (got 0)
MISS ally-recovery              minimal      >= 0.25  (got 0)
MISS ally-recovery              military     >= 0.25  (got 0)
MISS ally-recovery              accept_all   >= 0.25  (got 0)
MISS score                      cautious     >= 0  (got -795)
MISS score                      minimal      >= 0  (got -403.62)
MISS score                      military     >= 0  (got -575)
MISS score                      accept_all   >= 0  (got -615.88)
ok   election                   cautious     >= 0.50  (got 1)
ok   election                   minimal      >= 0.50  (got 1)
ok   election                   military     >= 0.50  (got 1)
ok   election                   accept_all   >= 0.50  (got 1)
```

36 band miss(es); report-only until P1.I (balance_bands.json "enforce").

## What each policy does

- **cautious** — Hire to 14 (an emergency lateral below 12 fit, a standing order for 18 on the books), train, restraint contracts, no military hardware, take the suggested raid kit, answer the gravest two calls and keep high-trauma officers off crowd duty.
- **minimal** — No hiring, no courses, no contracts, no programs, every offer declined, cases left to lapse, one call a week.
- **military-first** — Military contracts and kit, Kettering's offers, cases cleared, hire to 16 (an emergency lateral below 12 fit), three calls a week including crowd events.
- **accept-all** — Sign the cheapest contract and program on the desk, accept every offer and answer every event, hire to 18 (a standing order for 20 on the books), let plans buy kit, three calls a week.