#!/usr/bin/env python3
"""Five original, deterministic trailer beds, mixed with the game's own sound effects.

No third-party samples or network services are used. Intermediates live in .cache, not in the game.
"""
from array import array
from math import exp, pi, sin
from pathlib import Path
import random
import wave

ROOT = Path(__file__).resolve().parents[1]
SFX = ROOT.parent / 'assets' / 'sfx'
OUTPUT = ROOT / '.cache' / 'audio'
OUTPUT.mkdir(parents=True, exist_ok=True)
RATE = 22050
LENGTH = 20
TAU = 2 * pi


def read_sfx(name):
    with wave.open(str(SFX / f'{name}.wav'), 'rb') as f:
        if f.getnchannels() != 1 or f.getsampwidth() != 2 or f.getframerate() != RATE:
            raise ValueError(f'Unexpected format in {name}.wav')
        samples = array('h')
        samples.frombytes(f.readframes(f.getnframes()))
        return [n / 32768 for n in samples]


sound = {name: read_sfx(name) for name in ['amb_city', 'radio', 'stamp', 'door', 'click', 'toll', 'sting', 'ram']}
# Cue points are deliberately matched to each trailer's editing beats.
configs = [
    dict(bpm=92, root=49, cues=[(.25, 'radio', .23), (3.85, 'stamp', .32), (7.6, 'door', .25), (11.7, 'radio', .25), (15.6, 'toll', .34), (16.3, 'sting', .16)]),
    dict(bpm=104, root=55, cues=[(.2, 'click', .25), (3.4, 'stamp', .30), (7.3, 'click', .22), (10.9, 'door', .27), (13.7, 'radio', .2), (16.1, 'toll', .3)]),
    dict(bpm=88, root=46.25, cues=[(.2, 'radio', .22), (3.8, 'stamp', .35), (7.8, 'click', .22), (11.6, 'stamp', .3), (15.0, 'toll', .3), (16.0, 'sting', .16)]),
    dict(bpm=112, root=51.91, cues=[(.15, 'click', .23), (3.1, 'stamp', .28), (7.1, 'click', .26), (10.9, 'door', .25), (14.8, 'toll', .3), (16.1, 'sting', .15)]),
    dict(bpm=96, root=43.65, cues=[(.2, 'radio', .36), (3.4, 'click', .24), (6.8, 'radio', .28), (10.6, 'door', .23), (14.8, 'ram', .25), (16.1, 'toll', .30)]),
]

for index, cfg in enumerate(configs, 1):
    rng = random.Random(2000 + index)
    count = RATE * LENGTH
    mixed = [0.0] * count
    beat = 60.0 / cfg['bpm']
    root = cfg['root']
    ambient = sound['amb_city']
    for i in range(count):
        t = i / RATE
        b = t % beat
        # A low, slightly unstable drone, sparse heartbeat and grainy percussion.
        drone = .065 * sin(TAU * root * t) + .028 * sin(TAU * (root * 1.498) * t + .25 * sin(t * .45))
        kick_env = exp(-b * 10.0)
        kick = .13 * kick_env * sin(TAU * (45 * b + 3.0 * (1 - exp(-b * 18))))
        tick_t = (t + beat / 2) % beat
        tick = .021 * exp(-tick_t * 45) * (rng.random() * 2 - 1)
        # A restrained, rising third leaves room for the effects and on-screen copy.
        tension = .027 * sin(TAU * (root * 2.01) * t) * (.25 + .75 * min(t / 15, 1))
        fade = min(1, t / .5, max(0, (20 - t) / .8))
        mixed[i] = (drone + kick + tick + tension + ambient[i % len(ambient)] * .055) * fade
    for at, name, gain in cfg['cues']:
        start = int(at * RATE)
        for j, sample in enumerate(sound[name]):
            if start + j >= count:
                break
            mixed[start + j] += sample * gain * min(1, max(0, (count - start - j) / (RATE * .5)))
    peak = max(abs(x) for x in mixed) or 1
    scale = min(.91 / peak, 1)
    output = array('h', (int(max(-1, min(1, x * scale)) * 32767) for x in mixed))
    target = OUTPUT / f'{index:02}.wav'
    with wave.open(str(target), 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(output.tobytes())
    print(f'{target.name}: {LENGTH}s, peak {peak * scale:.2f}')
