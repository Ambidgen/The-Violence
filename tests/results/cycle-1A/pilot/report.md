# Run-layer balance — 2 seed(s) × 4 policy(ies), 40 weeks

8 run(s), 2172 s wall clock, 4.7.2-stable (official).

| metric | cautious | minimal | military-first | accept-all |
|---|---|---|---|---|
| lowest fit officers | 5 [3–7] | 11 [7–15] | 5.50 [5–6] | 4.50 [4–5] |
| weeks under 12 fit | 15.50 [12–19] | 8 [0–16] | 25 [23–27] | 28 [24–32] |
| weeks below $0 | 35 [32–38] | 0 [0–0] | 1 [0–2] | 37 [37–37] |
| weeks below $0 (1-12) | 10 [9–11] | 0 [0–0] | 1 [0–2] | 9 [9–9] |
| account at week 40 | -4686.50 [-6551–-2822] | 200838 [87946–313729] | 7227.50 [6443–8012] | -7418.50 [-12789–-2048] |
| lowest account | -27272 [-28729–-25815] | 37190.50 [33887–40494] | -5680 [-11535–175] | -50894 [-86064–-15723] |
| highest account | 6059 [4072–8046] | 219409 [107869–330948] | 23145.50 [20607–25684] | 8048.50 [6926–9171] |
| situations unattended | 58.50 [50–67] | 88 [84–92] | 56.50 [55–58] | 49 [48–50] |
| officers killed | 27 [26–28] | 7.50 [4–11] | 16.50 [16–17] | 23.50 [20–27] |
| killed per operation | 0.39 [0.35–0.42] | 0.19 [0.10–0.28] | 0.23 [0.23–0.24] | 0.30 [0.25–0.36] |
| civilians killed | 8.50 [7–10] | 1.50 [1–2] | 1 [0–2] | 6.50 [6–7] |
| findings | 83 [77–89] | 31.50 [21–42] | 53 [53–53] | 79.50 [67–92] |
| allies lost at the end | 3 [3–3] | 1 [1–1] | 2.50 [2–3] | 3.50 [3–4] |
| allies won back | 0 [0–0] | 0 [0–0] | 0 [0–0] | 0 [0–0] |
| run score | -1065.50 [-1079–-1052] | -351 [-417–-285] | -410 [-449–-371] | -857 [-971–-743] |
| chief kept | 2/2 | 2/2 | 2/2 | 2/2 |

## Gate 1 bands — asserting

```
MISS roster-floor               cautious     >= 10  (got 3)
MISS roster-floor               minimal      >= 10  (got 7)
MISS roster-floor               military     >= 10  (got 5)
MISS roster-floor               accept_all   >= 10  (got 4)
MISS roster-weeks               cautious     <= 8  (got 19)
MISS roster-weeks               minimal      <= 8  (got 16)
MISS roster-weeks               military     <= 8  (got 27)
MISS roster-weeks               accept_all   <= 8  (got 32)
MISS money-deficit              cautious     <= 8  (got 38)
ok   money-deficit              minimal      <= 8  (got 0)
ok   money-deficit              military     <= 8  (got 2)
MISS money-deficit              accept_all   <= 8  (got 37)
ok   money-debt                 cautious     >= -75000  (got -28729)
ok   money-debt                 minimal      >= -75000  (got 33887)
ok   money-debt                 military     >= -75000  (got -11535)
MISS money-debt                 accept_all   >= -75000  (got -86064)
MISS money-end                  cautious     >= 0  (got -4686.50)
ok   money-end                  minimal      >= 0  (got 200838)
ok   money-end                  military     >= 0  (got 7227.50)
MISS money-end                  accept_all   >= 0  (got -7418.50)
MISS coverage                   cautious     <= 48  (got 58.50)
MISS coverage                   minimal      <= 48  (got 88)
MISS coverage                   military     <= 48  (got 56.50)
MISS coverage                   accept_all   <= 48  (got 49)
MISS deaths                     cautious     <= 8  (got 27)
ok   deaths                     minimal      <= 8  (got 7.50)
MISS deaths                     military     <= 8  (got 16.50)
MISS deaths                     accept_all   <= 8  (got 23.50)
MISS lethality                  cautious     <= 0.15  (got 0.42)
MISS lethality                  minimal      <= 0.15  (got 0.28)
MISS lethality                  military     <= 0.15  (got 0.24)
MISS lethality                  accept_all   <= 0.15  (got 0.36)
MISS civilians                  cautious     <= 6  (got 8.50)
ok   civilians                  minimal      <= 6  (got 1.50)
ok   civilians                  military     <= 6  (got 1)
MISS civilians                  accept_all   <= 6  (got 6.50)
MISS allies-held                cautious     <= 2  (got 3)
ok   allies-held                minimal      <= 2  (got 1)
MISS allies-held                military     <= 2  (got 2.50)
MISS allies-held                accept_all   <= 2  (got 3.50)
MISS ally-recovery              cautious     >= 0.25  (got 0)
MISS ally-recovery              minimal      >= 0.25  (got 0)
MISS ally-recovery              military     >= 0.25  (got 0)
MISS ally-recovery              accept_all   >= 0.25  (got 0)
MISS score                      cautious     >= 0  (got -1065.50)
MISS score                      minimal      >= 0  (got -351)
MISS score                      military     >= 0  (got -410)
MISS score                      accept_all   >= 0  (got -857)
ok   election                   cautious     >= 0.50  (got 1)
ok   election                   minimal      >= 0.50  (got 1)
ok   election                   military     >= 0.50  (got 1)
ok   election                   accept_all   >= 0.50  (got 1)
```

37 band miss(es); report-only until P1.I (balance_bands.json "enforce").

## What each policy does

- **cautious** — Hire to 14 (an emergency lateral below 12 fit, a standing order for 18 on the books), train, restraint contracts, no military hardware, take the suggested raid kit, answer the gravest two calls and keep high-trauma officers off crowd duty.
- **minimal** — No hiring, no courses, no contracts, no programs, every offer declined, cases left to lapse, one call a week.
- **military-first** — Military contracts and kit, Kettering's offers, cases cleared, hire to 16 (an emergency lateral below 12 fit), three calls a week including crowd events.
- **accept-all** — Sign the cheapest contract and program on the desk, accept every offer and answer every event, hire to 18 (a standing order for 20 on the books), let plans buy kit, three calls a week.