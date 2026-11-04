#!/usr/bin/env python3
"""Build a recording's soundtrack from the game's sound log (1.1).

The game, run with --soundlog=log.jsonl beside --write-movie, writes one line per sound it
plays: the frame, the sound, its volume and pan. This mixes the same WAVs (assets/sfx) at
those frames, with the default bus levels, into a 48 kHz stereo WAV the length of the video.

    python3 tools/mix_soundtrack.py log.jsonl out.wav --frames 300 --fps 30 [--start 0] [--gain 0]
"""
import argparse
import json
import os
import wave

import numpy as np
from scipy.signal import resample_poly

SR = 48000
SFX = os.path.join(os.path.dirname(__file__), "..", "assets", "sfx")
BUS = {"amb": 0.5, "fx": 0.9}     # the default Ambience and Effects volumes
MASTER = 0.8
_cache = {}


def load(name):
    if name not in _cache:
        with wave.open(os.path.join(SFX, name + ".wav")) as w:
            d = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float32) / 32768.0
            sr = w.getframerate()
        _cache[name] = resample_poly(d, SR // 150, sr // 150) if sr != SR else d
    return _cache[name]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("log")
    ap.add_argument("out")
    ap.add_argument("--frames", type=int, required=True)
    ap.add_argument("--fps", type=float, default=30.0)
    ap.add_argument("--start", type=int, default=None, help="the process frame of video frame 0")
    ap.add_argument("--gain", type=float, default=0.0, help="overall gain, dB")
    a = ap.parse_args()
    ev = [json.loads(l) for l in open(a.log) if l.strip()]
    n = int(a.frames / a.fps * SR)
    mix = np.zeros((n, 2), np.float32)
    f0 = a.start if a.start is not None else 1
    t_of = lambda f: (f - f0) / a.fps
    # ambience beds: each runs until the next change
    beds = [e for e in ev if e.get("loop")]
    for i, e in enumerate(beds):
        if not e["s"]:
            continue
        t0 = max(0.0, t_of(e["f"]))
        t1 = t_of(beds[i + 1]["f"]) if i + 1 < len(beds) else a.frames / a.fps
        s0, s1 = int(t0 * SR), min(n, int(t1 * SR))
        if s1 <= s0:
            continue
        d = load(e["s"])
        reps = np.tile(d, (s1 - s0) // len(d) + 2)[: s1 - s0]
        g = 10 ** (e["db"] / 20.0) * BUS["amb"]
        fade = np.minimum(1.0, np.arange(s1 - s0) / (0.4 * SR))
        mix[s0:s1, 0] += reps * g * fade
        mix[s0:s1, 1] += reps * g * fade
    for e in ev:
        if e.get("loop") or not e["s"]:
            continue
        t = t_of(e["f"])
        if t < 0 or t >= a.frames / a.fps:
            continue
        d = load(e["s"])
        s0 = int(t * SR)
        s1 = min(n, s0 + len(d))
        g = 10 ** (e["db"] / 20.0) * BUS["fx"]
        pan = float(e.get("pan", 0.0))
        lg, rg = np.sqrt((1 - pan) / 2) * 1.41, np.sqrt((1 + pan) / 2) * 1.41
        mix[s0:s1, 0] += d[: s1 - s0] * g * lg
        mix[s0:s1, 1] += d[: s1 - s0] * g * rg
    mix *= MASTER * 10 ** (a.gain / 20.0)
    # a gentle limiter: nothing past -1 dBFS
    peak = np.max(np.abs(mix)) if len(mix) else 0
    lim = 10 ** (-1 / 20)
    if peak > lim:
        mix = np.tanh(mix / lim) * lim
    with wave.open(a.out, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((mix * 32767).astype(np.int16).tobytes())
    print("mixed %d sounds into %.1f s" % (len(ev), a.frames / a.fps))


if __name__ == "__main__":
    main()
