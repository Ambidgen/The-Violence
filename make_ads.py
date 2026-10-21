#!/usr/bin/env python3
"""The Violence: a series of short video ads, cut from the game itself (1.1).

Every shot is recorded from the game with Godot's movie writer (deterministic: fixed
30 fps, fixed seeds), every title card is drawn by tools/ad_card.gd in the game's own
hand, and every sound is one of the game's synthesised effects, placed where the game
played it (--soundlog + tools/mix_soundtrack.py). Needs xvfb-run, godot and ffmpeg.

    python3 tools/make_ads.py OUT_DIR [--only plan,weeks,hands,city] [--keep]
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import wave

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
W, H, FPS = 1920, 1080, 30
PAPER = "0xEDEDE8"
GODOT = os.environ.get("GODOT", "godot")
sys.path.insert(0, os.path.join(ROOT, "tools"))


def run(cmd, timeout=3600):
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=timeout)
    errs = [l for l in (r.stdout + r.stderr).splitlines() if "SCRIPT ERROR" in l]
    if errs:
        print("\n".join(errs[:5]))
    return r


def ffmpeg(args):
    r = subprocess.run(["ffmpeg", "-y", "-loglevel", "error"] + args, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr)


# ------------------------------------------------------------------ recording
def record(out, name, hooks, ui_scale=None, city=False):
    """Record the game with the given hooks until they quit it. Returns the frame dir."""
    d = os.path.join(out, "rec", name)
    if os.path.isdir(d) and os.path.exists(os.path.join(d, "done")):
        return d
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    cmd = ["xvfb-run", "-a", "-s", f"-screen 0 {W}x{H}x24", GODOT, "--path", ".", "--resolution", f"{W}x{H}",
           "--write-movie", os.path.join(d, "f.png"), "--fixed-fps", str(FPS), "--"] + hooks + \
          [f"--soundlog={os.path.join(d, 'log.jsonl')}"]
    if ui_scale:
        cmd.append(f"--ui-scale={ui_scale}")
    print("  recording", name, "...", flush=True)
    run(cmd)
    n = len([f for f in os.listdir(d) if f.endswith(".png")])
    print("   ", n, "frames")
    open(os.path.join(d, "done"), "w").write(str(n))
    return d


def frames_in(d):
    return len([f for f in os.listdir(d) if f.endswith(".png")])


def live_start(d):
    """Seconds into a recording of the first frame past a loading screen (a nearly blank page)."""
    from PIL import Image
    n = frames_in(d)
    for i in range(0, n, 3):
        im = Image.open(os.path.join(d, "f%08d.png" % i)).convert("L").resize((96, 54))
        a = np.asarray(im, dtype=np.float32)
        if a.mean() < 232.0 or a.std() > 16.0:      # the loading page is bright and nearly bare
            return i / FPS
    return 0.0


def first_sound(d, prefix="shot_"):
    """Seconds into a recording of the first sound whose name starts with prefix."""
    try:
        for l in open(os.path.join(d, "log.jsonl")):
            e = json.loads(l)
            if e["s"].startswith(prefix):
                return (e["f"] - 1) / FPS
    except OSError:
        pass
    return None


def soundtrack(d, out_wav):
    log = os.path.join(d, "log.jsonl")
    n = frames_in(d)
    if not os.path.exists(log) or os.path.getsize(log) == 0:
        open(log, "w").write("")
    subprocess.run([sys.executable, os.path.join(ROOT, "tools", "mix_soundtrack.py"), log, out_wav,
                    "--frames", str(n), "--fps", str(FPS)], check=True, capture_output=True)


# ------------------------------------------------------------------ segments
def seg_clip(out, name, rec_dir, start, dur, crop=None, crop_to=None, gain=0.0, freeze=False):
    """A cut from a recording: start/dur in seconds; crop (x, y, w, h) in the frame,
    optionally moving to crop_to over the shot (a slow push-in)."""
    wav = os.path.join(out, "seg", name + ".wav")
    soundtrack(rec_dir, wav)
    n = frames_in(rec_dir)
    start = max(0.0, min(start, n / FPS - 0.5))
    dur = min(dur, n / FPS - start)
    vf = []
    if crop:
        # a push-in from one 16:9 box to another: scale the frame up over time, crop a
        # full frame out of it (crop's size cannot change per frame, its position can)
        x0, y0, w0, h0 = crop
        x1, y1, w1, h1 = crop_to or crop
        p = f"(min(if(isnan(t),0,t)/{dur:.3f},1))"
        e = f"(3*{p}*{p}-2*{p}*{p}*{p})"
        z = f"({W}/({w0}+({w1}-{w0})*{e}))"
        cx = f"({x0}+({x1}-{x0})*{e})"
        cy = f"({y0}+({y1}-{y0})*{e})"
        vf.append(f"scale=w='max({W},ceil(iw*{z}/2)*2)':h='max({H},ceil(ih*{z}/2)*2)':eval=frame:flags=bicubic")
        vf.append(f"crop={W}:{H}:x='min({cx}*{z},iw-{W})':y='min({cy}*{z},ih-{H})'")
        vf.append("setsar=1")
        if freeze:   # one frame held: the camera may move on in the recording, the page should not
            still = os.path.join(rec_dir, "f%08d.png" % min(frames_in(rec_dir) - 1, int(start * FPS)))
            return _encode(out, name, ["-loop", "1", "-framerate", str(FPS), "-i", still], wav, start, dur, vf, gain,
                           vstart=0.0)
        return _encode(out, name, ["-framerate", str(FPS), "-start_number", "0", "-i", os.path.join(rec_dir, "f%08d.png")],
                       wav, start, dur, vf, gain)
    vf.append(f"scale={W}:{H}:flags=lanczos,setsar=1")
    return _encode(out, name, ["-framerate", str(FPS), "-start_number", "0", "-i", os.path.join(rec_dir, "f%08d.png")],
                   wav, start, dur, vf, gain)


def seg_card(out, name, dur, sfx=None, **card):
    """A title card held for dur seconds with a slow push-in; sfx: [(t, sound, dB)]."""
    png = os.path.join(out, "seg", name + ".png")
    args = [f"--out={png}", f"--w={W}", f"--h={H}"] + [f"--{k}={v}" for k, v in card.items()]
    run(["xvfb-run", "-a", "-s", f"-screen 0 {W}x{H}x24", GODOT, "--path", ".", "--resolution", f"{W}x{H}",
         "-s", "res://tools/ad_card.gd", "--"] + args)
    wav = os.path.join(out, "seg", name + ".wav")
    log = os.path.join(out, "seg", name + ".jsonl")
    with open(log, "w") as f:
        f.write(json.dumps({"f": 1, "s": "amb_office", "db": -14.0, "pan": 0.0, "loop": True}) + "\n")
        for t, s, db in (sfx or []):
            f.write(json.dumps({"f": 1 + int(t * FPS), "s": s, "db": db, "pan": 0.0, "loop": False}) + "\n")
    subprocess.run([sys.executable, os.path.join(ROOT, "tools", "mix_soundtrack.py"), log, wav,
                    "--frames", str(int(dur * FPS) + 2), "--fps", str(FPS)], check=True, capture_output=True)
    z = f"1+0.035*t/{dur:.3f}"
    vf = [f"scale=w='iw*({z})':h='ih*({z})':eval=frame", f"crop={W}:{H}", "setsar=1"]
    return _encode(out, name, ["-loop", "1", "-framerate", str(FPS), "-i", png], wav, 0.0, dur, vf, 0.0)


def _encode(out, name, vin, wav, start, dur, vf, gain, vstart=None):
    mp4 = os.path.join(out, "seg", name + ".mp4")
    fade = 0.18
    vf = vf + [f"fade=t=in:st=0:d={fade}:color={PAPER}", f"fade=t=out:st={dur - fade:.3f}:d={fade}:color={PAPER}",
               "format=yuv420p"]
    af = [f"volume={gain}dB", f"afade=t=in:st=0:d={fade}", f"afade=t=out:st={dur - fade:.3f}:d={fade}"]
    vs = start if vstart is None else vstart
    ffmpeg(["-ss", f"{vs:.3f}"] + vin + ["-ss", f"{start:.3f}", "-i", wav, "-t", f"{dur:.3f}",
            "-vf", ",".join(vf), "-af", ",".join(af), "-r", str(FPS),
            "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-c:a", "aac", "-b:a", "192k", "-ar", "48000",
            "-ac", "2", mp4])
    return mp4


def assemble(out, name, segs):
    lst = os.path.join(out, "seg", name + ".txt")
    with open(lst, "w") as f:
        for s in segs:
            f.write(f"file '{os.path.abspath(s)}'\n")
    dst = os.path.join(out, f"TheViolence-ad-{name}.mp4")
    ffmpeg(["-f", "concat", "-safe", "0", "-i", lst, "-c:v", "copy", "-af", "loudnorm=I=-16:TP=-1.5:LRA=11",
            "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-movflags", "+faststart", dst])
    print("  ->", dst)
    return dst


END = dict(kind="end", text="v1.1  ·  Windows and Linux|A tactical command game about the gap between the plan and the room.")


# ------------------------------------------------------------------ the ads
def ad_plan(out):
    """1. THE PLAN: theory against application."""
    plan = record(out, "plan_screen", ["--ops", "--new-campaign", "--ops-select=0", "--hold=150"], ui_scale=1.5)
    run_ = record(out, "plan_run3", ["--ops", "--new-campaign", "--ops-select=0", "--ops-run", "--speed=1", "--nofog",
                                     "--cam=action", "--camzoom=3.2", "--clean", "--shot=/dev/null", "--shot-at=99",
                                     "--shot-wait=150"])
    deb = record(out, "plan_debrief", ["--ops", "--new-campaign", "--ops-select=0", "--ops-run", "--speed=10",
                                       "--shot=/dev/null", "--shot-at=99", "--shot-wait=200"], ui_scale=1.3)
    end_t = frames_in(deb) / FPS
    segs = [
        seg_card(out, "plan_c1", 2.6, [(0.1, "stamp", -4)], kind="line", text="EVERY OPERATION|IS A PLAN."),
        seg_clip(out, "plan_s1", plan, 1.0, 3.8, crop=(0, 0, 1920, 1080), crop_to=(40, 300, 880, 495)),
        seg_clip(out, "plan_s1b", plan, 2.0, 3.0, crop=(1100, 430, 820, 461), crop_to=(1110, 450, 720, 405)),
        seg_card(out, "plan_c2", 2.2, [(0.1, "radio", -6)], kind="line", text="UNTIL IT MEETS|A *ROOM*."),
        seg_clip(out, "plan_s2", run_, 5.0, 9.0),
        seg_card(out, "plan_c3", 2.4, [(0.1, "stamp", -4)], kind="line", text="YOU PLAN.|THEY DECIDE.", red=2),
        seg_clip(out, "plan_s3", run_, frames_in(run_) / FPS - 3.6, 3.2),
        seg_clip(out, "plan_s4", deb, end_t - 6.3, 2.6, crop=(1190, 0, 730, 411), crop_to=(1200, 10, 640, 360), freeze=True),
        seg_clip(out, "plan_s5", deb, end_t - 6.3, 3.0, crop=(0, 700, 760, 428), crop_to=(20, 840, 480, 270), freeze=True),
        seg_card(out, "plan_end", 4.5, [(0.2, "toll", -6)], **END),
    ]
    return assemble(out, "1-the-plan", segs)


def ad_weeks(out):
    """2. FORTY WEEKS: the department, the press, the election."""
    board = record(out, "weeks_board", ["--ops", "--new-campaign", "--hold=120"], ui_scale=1.5)
    ia = record(out, "weeks_ia", ["--ops", "--new-campaign", "--ops-demo-cases", "--ops-screen=cases", "--hold=120"], ui_scale=1.5)
    hall = record(out, "weeks_hall", ["--ops", "--new-campaign", "--ops-weeks=14", "--ops-screen=cityhall", "--hold=120"], ui_scale=1.5)
    press = record(out, "weeks_press", ["--ops", "--new-campaign", "--ops-weeks=14", "--hold=120"], ui_scale=1.5)
    # election night from a campaign actually played to the end (tests/op_test.gd --save), when given
    played = os.environ.get("AD_CAMPAIGN", "")
    if played:
        dst = os.path.expanduser("~/.local/share/godot/app_userdata/The Violence/campaign.json")
        shutil.copy(played, dst)
        night = record(out, "weeks_night_played", ["--ops", "--hold=150"], ui_scale=1.5)
    else:
        night = record(out, "weeks_night", ["--ops", "--new-campaign", "--ops-weeks=40", "--hold=150"], ui_scale=1.5)
    panel = lambda y: (1040, y, 880, 495)
    segs = [
        seg_card(out, "weeks_c1", 3.0, [(0.1, "stamp", -4)], kind="line", size="96",
                 text="FORTY WEEKS.|ONE DEPARTMENT.|ONE *ELECTION*."),
        seg_clip(out, "weeks_s1", board, 1.0, 3.2, crop=(1040, 0, 880, 495), crop_to=(1040, 60, 840, 473)),
        seg_card(out, "weeks_c2", 2.4, [(0.1, "click", -2)], kind="line", text="EVERY ROUND|IS ON THE *RECORD*."),
        seg_clip(out, "weeks_s2", ia, 1.0, 3.2, crop=panel(0), crop_to=(1040, 40, 800, 450)),
        seg_card(out, "weeks_c3", 2.4, [(0.1, "radio", -6)], kind="line", text="THE PRESS PRINTS|WHAT IT CAN *PROVE*."),
        seg_clip(out, "weeks_s3", press, 1.0, 3.2, crop=(1040, 80, 880, 495), crop_to=(1040, 120, 800, 450)),
        seg_clip(out, "weeks_s4", hall, 1.0, 3.2, crop=panel(0), crop_to=(1040, 20, 800, 450)),
        seg_card(out, "weeks_c4", 2.6, [(0.1, "toll", -6)], kind="line", size="92",
                 text="ON ELECTION NIGHT|THE CITY DECIDES|WHAT HAPPENS TO *YOU*."),
        seg_clip(out, "weeks_s5", night, 1.0, 4.4, crop=(1090, 0, 830, 467), crop_to=(1095, 170, 825, 464)),
        seg_card(out, "weeks_end", 4.5, [(0.2, "stamp", -4)], **END),
    ]
    return assemble(out, "2-forty-weeks", segs)


def ad_hands(out):
    """3. HANDS OFF: the officers decide; the animated figures up close."""
    breach = record(out, "hands_breach", ["--autorun", "--map=4", "--na=4", "--nb=4", "--police", "--civ=3",
                                          "--speed=0.75", "--cam=action", "--camzoom=3.4", "--clean",
                                          "--shot=/dev/null", "--shot-at=16"])
    fight = record(out, "hands_fight2", ["--autorun", "--map=6", "--na=6", "--nb=5", "--speed=0.75",
                                         "--cam=team", "--camzoom=2.6", "--clean", "--seed=4242",
                                         "--shot=/dev/null", "--shot-at=40"])
    abort = record(out, "hands_abort2", ["--ops", "--new-campaign", "--ops-select=1", "--ops-run", "--speed=1", "--nofog",
                                         "--ops-abort-at=7", "--cam=team", "--camzoom=2.4", "--clean",
                                         "--shot=/dev/null", "--shot-at=99", "--shot-wait=30"])
    t_fire = first_sound(fight)
    t_fire = 8.0 if t_fire is None else max(0.0, t_fire - 1.5)
    segs = [
        seg_card(out, "hands_c1", 2.4, [(0.1, "click", -2)], kind="line", text="YOU DON'T PULL|THE TRIGGER."),
        seg_clip(out, "hands_s1", breach, 4.0, 7.0),
        seg_card(out, "hands_c2", 3.0, [(0.1, "radio", -6)], kind="line", size="92",
                 text="THEY DO.|BY THEIR TRAINING.|THEIR HABITS. THEIR *NERVE*."),
        seg_clip(out, "hands_s2", fight, t_fire, 9.0),
        seg_card(out, "hands_c3", 2.6, [(0.1, "stamp", -4)], kind="line", text="THE ONLY ORDER YOU CAN GIVE:|*ABORT*."),
        seg_clip(out, "hands_s3", abort, 6.6, 4.5),
        seg_card(out, "hands_end", 4.5, [(0.2, "toll", -6)], **END),
    ]
    return assemble(out, "3-hands-off", segs)


def ad_city(out):
    """4. PORT CARRICK: the endless battle."""
    wide = record(out, "city_wide3", ["--city", "--warp=90", "--speed=1", "--clean",
                                      "--shot=/dev/null", "--shot-at=104"])
    near = record(out, "city_near2", ["--city", "--follow", "--follow-zoom=0.95", "--warp=120", "--speed=1", "--clean",
                                      "--shot=/dev/null", "--shot-at=140"])
    segs = [
        seg_card(out, "city_c1", 2.8, [(0.1, "radio", -6)], kind="line", size="92",
                 text="PORT CARRICK.|ONE KILOMETRE.|TWO HUNDRED AND FIFTY LOTS."),
        seg_clip(out, "city_s1", wide, live_start(wide) + 0.5, 5.0, crop=(0, 0, 1920, 1080), crop_to=(80, 170, 1200, 675)),
        seg_card(out, "city_c2", 2.8, [(0.1, "stamp", -4)], kind="line", size="96",
                 text="FOUR GANGS.|SIX PRECINCTS.|THREE HOSPITALS."),
        seg_clip(out, "city_s2", near, live_start(near) + 3.5, 7.0, crop=(240, 135, 1440, 810), crop_to=(320, 220, 1280, 720)),
        seg_card(out, "city_c3", 2.2, [(0.1, "toll", -6)], kind="line", text="IT *NEVER* ENDS."),
        seg_card(out, "city_end", 4.5, [(0.2, "stamp", -4)], **END),
    ]
    return assemble(out, "4-port-carrick", segs)


ADS = {"plan": ad_plan, "weeks": ad_weeks, "hands": ad_hands, "city": ad_city}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--only", default=",".join(ADS))
    a = ap.parse_args()
    os.makedirs(os.path.join(a.out, "seg"), exist_ok=True)
    for k in a.only.split(","):
        print("ad:", k, flush=True)
        ADS[k](os.path.abspath(a.out))


if __name__ == "__main__":
    main()
