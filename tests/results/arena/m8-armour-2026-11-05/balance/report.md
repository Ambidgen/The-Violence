# Run-layer balance — 8 seed(s) × 4 policy(ies), 40 weeks

32 run(s), 7465 s wall clock, 4.7.2-stable (official).

| metric | cautious | minimal | military-first | accept-all |
|---|---|---|---|---|
| lowest fit officers | 11.75 [7–14] | 12.50 [6–16] | 8.88 [7–11] | 8.75 [6–11] |
| weeks under 12 fit | 0.75 [0–4] | 3.25 [0–22] | 8.62 [1–16] | 6.12 [2–16] |
| weeks below $0 | 18.25 [1–32] | 0 [0–0] | 7.50 [1–18] | 32.25 [28–38] |
| weeks below $0 (1-12) | 3 [0–7] | 0 [0–0] | 1.38 [0–4] | 6.88 [1–10] |
| account at week 40 | -3672.25 [-48311–13251] | 162339 [51997–362848] | 7820.62 [1995–12183] | -32223.38 [-137362–-4324] |
| lowest account | -20743.50 [-48311–-6653] | 35247 [8386–40496] | -17802.75 [-46710–-1836] | -52641 [-140742–-16314] |
| highest account | 11621.12 [9768–16595] | 176182 [76048–368188] | 19221 [14857–22618] | 7016 [3383–11772] |
| situations unattended | 47.88 [41–53] | 86 [79–92] | 41.12 [30–50] | 25 [18–36] |
| officers killed | 14.62 [5–28] | 5.88 [2–10] | 11.62 [6–15] | 16.25 [9–25] |
| killed per operation | 0.18 [0.06–0.35] | 0.15 [0.05–0.25] | 0.14 [0.06–0.17] | 0.16 [0.08–0.26] |
| civilians killed | 3.88 [2–7] | 3.12 [0–7] | 6.12 [3–10] | 6.12 [1–9] |
| findings | 57 [40–76] | 37 [14–56] | 59.38 [39–80] | 77.38 [60–90] |
| allies lost at the end | 1.50 [0–3] | 1.12 [1–2] | 2.25 [1–3] | 2.50 [2–3] |
| allies won back | 1.50 [0–3] | 0 [0–0] | 0 [0–0] | 2.25 [1–3] |
| run score | -246.62 [-552–143] | -321 [-598–-96] | -303.12 [-441–-167] | -365.12 [-654–-15] |
| chief kept | 7/8 | 8/8 | 7/8 | 6/8 |

## Gate 1 bands — asserting

```
MISS roster-floor               cautious     >= 10  (got 7)
MISS roster-floor               minimal      >= 10  (got 6)
MISS roster-floor               military     >= 10  (got 7)
MISS roster-floor               accept_all   >= 10  (got 6)
ok   roster-weeks               cautious     <= 8  (got 4)
MISS roster-weeks               minimal      <= 8  (got 22)
MISS roster-weeks               military     <= 8  (got 16)
MISS roster-weeks               accept_all   <= 8  (got 16)
MISS money-deficit              cautious     <= 8  (got 32)
ok   money-deficit              minimal      <= 8  (got 0)
MISS money-deficit              military     <= 8  (got 18)
MISS money-deficit              accept_all   <= 8  (got 38)
ok   money-debt                 cautious     >= -75000  (got -48311)
ok   money-debt                 minimal      >= -75000  (got 8386)
ok   money-debt                 military     >= -75000  (got -46710)
MISS money-debt                 accept_all   >= -75000  (got -140742)
MISS money-end                  cautious     >= 0  (got -3672.25)
ok   money-end                  minimal      >= 0  (got 162339)
ok   money-end                  military     >= 0  (got 7820.62)
MISS money-end                  accept_all   >= 0  (got -32223.38)
ok   coverage                   cautious     <= 48  (got 47.88)
MISS coverage                   minimal      <= 48  (got 86)
ok   coverage                   military     <= 48  (got 41.12)
ok   coverage                   accept_all   <= 48  (got 25)
MISS deaths                     cautious     <= 8  (got 14.62)
ok   deaths                     minimal      <= 8  (got 5.88)
MISS deaths                     military     <= 8  (got 11.62)
MISS deaths                     accept_all   <= 8  (got 16.25)
MISS lethality                  cautious     <= 0.15  (got 0.35)
MISS lethality                  minimal      <= 0.15  (got 0.25)
MISS lethality                  military     <= 0.15  (got 0.17)
MISS lethality                  accept_all   <= 0.15  (got 0.26)
ok   civilians                  cautious     <= 6  (got 3.88)
ok   civilians                  minimal      <= 6  (got 3.12)
MISS civilians                  military     <= 6  (got 6.12)
MISS civilians                  accept_all   <= 6  (got 6.12)
ok   allies-held                cautious     <= 2  (got 1.50)
ok   allies-held                minimal      <= 2  (got 1.12)
MISS allies-held                military     <= 2  (got 2.25)
MISS allies-held                accept_all   <= 2  (got 2.50)
ok   ally-recovery              cautious     >= 0.25  (got 1.50)
MISS ally-recovery              minimal      >= 0.25  (got 0)
MISS ally-recovery              military     >= 0.25  (got 0)
ok   ally-recovery              accept_all   >= 0.25  (got 2.25)
MISS score                      cautious     >= 0  (got -246.62)
MISS score                      minimal      >= 0  (got -321)
MISS score                      military     >= 0  (got -303.12)
MISS score                      accept_all   >= 0  (got -365.12)
ok   election                   cautious     >= 0.50  (got 0.88)
ok   election                   minimal      >= 0.50  (got 1)
ok   election                   military     >= 0.50  (got 0.88)
ok   election                   accept_all   >= 0.50  (got 0.75)
```

31 band miss(es); report-only until P1.I (balance_bands.json "enforce").

## What each policy does

- **cautious** — Hire to 14 (an emergency lateral below 12 fit, a standing order for 18 on the books), train, restraint contracts, no military hardware, take the suggested raid kit, answer the gravest two calls and keep high-trauma officers off crowd duty.
- **minimal** — No hiring, no courses, no contracts, no programs, every offer declined, cases left to lapse, one call a week.
- **military-first** — Military contracts and kit, Kettering's offers, cases cleared, hire to 16 (an emergency lateral below 12 fit), three calls a week including crowd events.
- **accept-all** — Sign the cheapest contract and program on the desk, accept every offer and answer every event, hire to 18 (a standing order for 20 on the books), let plans buy kit, three calls a week.