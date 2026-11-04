#!/usr/bin/env python3
"""Synthesise every sound effect The Violence uses (1.0). No samples: noise, filters and
envelopes, seeded, so the same script always writes the same files.

    python3 tools/make_sounds.py            # writes assets/sfx/*.wav (22.05 kHz, mono, 16-bit)

The palette is like the art's: dry and restrained. Shots are a sharp crack over a short
low body, by weapon class; the far versions are the same shots heard through walls or
from out of sight (low-passed, quieter, a longer tail). The rest: flashbang, sting-ball,
breaching (ram, kick, shotgun), gas, taser, the radio's squelch, an interface tick, a
rubber stamp, and two ambience beds (the city at night, the chief's office).
"""
import os
import wave

import numpy as np
from scipy.signal import butter, lfilter

SR = 22050
OUT = "assets/sfx"
RNG = np.random.default_rng(1977)


def t(sec):
    return np.arange(int(SR * sec)) / SR


def noise(sec):
    return RNG.standard_normal(int(SR * sec))


def lp(x, hz, order=2):
    b, a = butter(order, min(hz / (SR / 2), 0.99), "low")
    return lfilter(b, a, x)


def hp(x, hz, order=2):
    b, a = butter(order, min(hz / (SR / 2), 0.99), "high")
    return lfilter(b, a, x)


def bp(x, lo, hi, order=2):
    b, a = butter(order, [lo / (SR / 2), min(hi / (SR / 2), 0.99)], "band")
    return lfilter(b, a, x)


def env(sec, attack=0.001, decay=0.1):
    tt = t(sec)
    e = np.exp(-tt / decay)
    a = int(SR * attack)
    if a > 0:
        e[:a] *= np.linspace(0, 1, a)
    return e


def norm(x, peak=0.9):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def fade(x, sec=0.01):
    n = int(SR * sec)
    if n > 0 and len(x) > 2 * n:
        x = x.copy()
        x[-n:] *= np.linspace(1, 0, n)
    return x


def write(name, x, peak=0.9):
    x = fade(norm(x, peak))
    os.makedirs(OUT, exist_ok=True)
    data = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


# ------------------------------------------------------------------ shots
# crack (high, very short), body (low thump), tail (room), by class
SHOTS = {
    # crack: high-pass corner (Hz) and its weight; body: the thump's pitch; tail: the room
    "pistol":       {"crack": 1800, "cw": 0.45, "c_dec": 0.008, "body": 170, "b_dec": 0.05, "tail": 0.18, "len": 0.45, "gain": 0.8},
    "pistol_heavy": {"crack": 1500, "cw": 0.40, "c_dec": 0.010, "body": 130, "b_dec": 0.07, "tail": 0.25, "len": 0.55, "gain": 0.9},
    "smg":          {"crack": 2000, "cw": 0.45, "c_dec": 0.007, "body": 190, "b_dec": 0.04, "tail": 0.14, "len": 0.35, "gain": 0.75},
    "rifle":        {"crack": 2400, "cw": 0.60, "c_dec": 0.007, "body": 115, "b_dec": 0.06, "tail": 0.30, "len": 0.65, "gain": 0.95},
    "rifle_loud":   {"crack": 2300, "cw": 0.60, "c_dec": 0.008, "body": 100, "b_dec": 0.08, "tail": 0.35, "len": 0.75, "gain": 1.0},
    "rifle_heavy":  {"crack": 2000, "cw": 0.55, "c_dec": 0.010, "body": 80, "b_dec": 0.11, "tail": 0.45, "len": 0.9, "gain": 1.0},
    "shotgun":      {"crack": 1200, "cw": 0.30, "c_dec": 0.012, "body": 75, "b_dec": 0.12, "tail": 0.40, "len": 0.85, "gain": 1.0},
}


def shot(p, far=False):
    L = p["len"] * (1.6 if far else 1.0)
    crack = bp(noise(L), p["crack"], 7000) * env(L, 0.0005, p["c_dec"])
    thump = lp(noise(L), p["body"] * 4, 3) * env(L, 0.002, p["b_dec"]) * 6.0
    thump += np.sin(2 * np.pi * p["body"] * t(L)) * env(L, 0.001, p["b_dec"] * 0.8) * 1.2
    tail = bp(noise(L), 250, 1800) * env(L, 0.01, p["tail"]) * 0.5
    x = crack * p["cw"] * 3.0 + thump + tail
    if far:
        x = lp(x, 900, 3) + lp(noise(L), 400) * env(L, 0.02, p["tail"] * 1.6) * 0.15
        x = norm(x, 1.0) * 0.55
    return x * p["gain"]


# ------------------------------------------------------------------ the rest
def flashbang():
    L = 2.4
    boom = lp(noise(L), 200, 3) * env(L, 0.001, 0.25) * 9.0
    boom += np.sin(2 * np.pi * 55 * t(L)) * env(L, 0.001, 0.2) * 1.5
    crack = bp(noise(L), 1500, 6000) * env(L, 0.0003, 0.02) * 1.0
    ring = np.sin(2 * np.pi * 3600 * t(L)) * env(L, 0.05, 0.9) * 0.03
    return boom + crack + ring


def sting():
    L = 1.2
    pop = lp(noise(L), 600) * env(L, 0.001, 0.06) * 2.0
    rattle = bp(noise(L), 1500, 5000) * env(L, 0.005, 0.18) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 23 * t(L)))) * 0.6
    return pop + rattle


def ram():
    L = 0.7
    thud = lp(noise(L), 160, 3) * env(L, 0.002, 0.08) * 3.0
    splinter = bp(noise(L), 900, 4000) * env(L, 0.004, 0.05) * 0.9
    return thud + splinter + np.sin(2 * np.pi * 70 * t(L)) * env(L, 0.001, 0.07)


def kick():
    L = 0.5
    return lp(noise(L), 260, 3) * env(L, 0.002, 0.05) * 2.5 + bp(noise(L), 600, 2500) * env(L, 0.003, 0.03) * 0.6


def door():
    L = 0.6
    creak = np.sin(2 * np.pi * (180 + 60 * t(L)) * t(L)) * env(L, 0.08, 0.25) * 0.25
    latch = bp(noise(L), 1500, 5000) * env(L, 0.001, 0.015) * 0.8
    return creak + latch


def gas():
    L = 2.0
    pop = lp(noise(L), 500) * env(L, 0.001, 0.04) * 1.6
    hiss = hp(noise(L), 2500) * (env(L, 0.15, 1.2)) * 0.35
    return pop + hiss


def taser():
    L = 1.1
    clicks = (np.sign(np.sin(2 * np.pi * 19 * t(L))) > 0.95).astype(float)
    buzz = bp(noise(L), 2000, 7000) * (0.4 + 0.6 * (np.sin(2 * np.pi * 19 * t(L)) > 0)) * env(L, 0.005, 0.8) * 0.6
    pop = hp(noise(L), 1200) * env(L, 0.0005, 0.01)
    return buzz + pop + clicks * 0.02


def radio():
    L = 0.42
    tt = t(L)
    squelch = bp(noise(L), 900, 3200) * 0.35
    gate = ((tt < 0.06) | (tt > 0.34)).astype(float)
    tone = np.sin(2 * np.pi * 1450 * tt) * (tt < 0.03) * 0.3
    return squelch * gate + tone


def click():
    L = 0.06
    return bp(noise(L), 1800, 6000) * env(L, 0.0005, 0.006)


def stamp():
    L = 0.4
    return lp(noise(L), 300, 3) * env(L, 0.001, 0.035) * 2.0 + bp(noise(L), 1000, 3000) * env(L, 0.001, 0.01) * 0.6


def toll():
    # a fallen name in the ledger: a muted, low, wooden knock, twice
    L = 0.9
    tt = t(L)
    k = np.sin(2 * np.pi * 110 * tt) * env(L, 0.002, 0.12) + np.sin(2 * np.pi * 165 * tt) * env(L, 0.002, 0.08) * 0.5
    k2 = np.zeros_like(k)
    o = int(SR * 0.28)
    k2[o:] = k[: len(k) - o] * 0.6
    return lp(k + k2, 900)


def loop_bed(L, make):
    """A seamless loop: build L + 1 s, crossfade the extra second into the start."""
    x = make(L + 1.0)
    n = SR
    head = x[:n] * np.linspace(0, 1, n) + x[-n:] * np.linspace(1, 0, n)
    return np.concatenate([head, x[n:-n]])


def city(L):
    tt = t(L)
    rumble = lp(noise(L), 120, 3) * (0.7 + 0.3 * np.sin(2 * np.pi * 0.05 * tt))
    air = bp(noise(L), 300, 1200) * 0.12 * (0.6 + 0.4 * np.sin(2 * np.pi * 0.11 * tt + 1.0))
    # a far siren drifting through, once
    s0, s1 = int(SR * L * 0.42), int(SR * L * 0.62)
    siren = np.zeros_like(tt)
    seg = tt[s0:s1] - tt[s0]
    siren[s0:s1] = np.sin(2 * np.pi * (650 + 180 * np.sin(2 * np.pi * 0.7 * seg)) * seg) * np.hanning(s1 - s0) * 0.05
    return rumble + air + lp(siren, 1500)


def office(L):
    tt = t(L)
    hum = np.sin(2 * np.pi * 60 * tt) * 0.04 + np.sin(2 * np.pi * 120 * tt) * 0.015
    room = lp(noise(L), 500) * 0.25
    tick = np.zeros_like(tt)
    for k in range(int(L)):
        i = int(SR * (k + 0.5))
        m = min(len(tt) - i, int(SR * 0.02))
        tick[i:i + m] = bp(noise(0.02), 2000, 6000)[:m] * np.exp(-np.arange(m) / (SR * 0.003)) * 0.18
    return hum + room + tick


def main():
    for name, p in SHOTS.items():
        for v in (1, 2):
            write("shot_%s_%d" % (name, v), shot(p))
        write("far_%s" % name, shot(p, True), 0.6)
    write("flashbang", flashbang())
    write("sting", sting())
    write("ram", ram())
    write("kick", kick())
    write("door", door(), 0.5)
    write("gas", gas(), 0.7)
    write("taser", taser(), 0.6)
    write("radio", radio(), 0.45)
    write("click", click(), 0.35)
    write("stamp", stamp(), 0.8)
    write("toll", toll(), 0.6)
    write("amb_city", loop_bed(40.0, city), 0.5)
    write("amb_office", loop_bed(30.0, office), 0.35)
    print("wrote %d sounds to %s" % (len(os.listdir(OUT)), OUT))


if __name__ == "__main__":
    main()
