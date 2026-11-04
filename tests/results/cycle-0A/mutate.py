# Break-one-assertion sweep for cycle 0.A: write tests/_mut_<name>.gd with the gate's
# condition forced to fail, run it with small args, expect exit 1; run the original with
# the same args and report its exit code. Usage: python3 mutate.py <proj> <godot>
import subprocess, sys, os, re, time
proj, godot = sys.argv[1], sys.argv[2]
CASES = [  # name, small args, [(old, new)]
 ("civ_test", ["--n=2"], [("gate_failed = not (b < a)", "gate_failed = true")]),
 ("equip_test", ["--n=2"], [("quit(0 if passed == tests.size() else 1)", "quit(0 if passed == tests.size() + 1 else 1)")]),
 ("lethality_test", ["--n=2"], [('int(agg["ops"]) == n and', 'int(agg["ops"]) == n + 1 and')]),
 ("maps_test", ["--map=4"], [("quit(1 if problems > 0 else 0)", "quit(1 if problems >= 0 else 0)")]),
 ("nav_door_test", ["--map=4"], [("quit(1 if problems > 0 else 0)", "quit(1 if problems >= 0 else 0)")]),
 ("op_test", ["--weeks=1", "--chief=sensible"], [("if hung > 0:", "if hung >= 0:")]),
 ("hold_test", ["--n=1", "--maps=4"], [("quit(0 if played > 0 else 1)", "quit(0 if played > 999999 else 1)")]),
 ("stall_test", ["--map=4"], [("quit(1 if stalls > 0 else 0)", "quit(1 if stalls >= 0 else 0)")]),
 ("fuzz_test", ["--n=3"], [("quit(1 if not missing.is_empty() else 0)", "quit(1 if missing.is_empty() or true else 0)")]),
 ("sim_test", ["--n=1"], [("quit(0 if played > 0 else 1)", "quit(0 if played > 999999 else 1)")]),
 ("perf", ["--map=4", "--na=3", "--nb=3", "--t=5"], [("quit(0 if ticks > 0 else 1)", "quit(0 if ticks > 999999999 else 1)")]),
 ("duel_probe", ["--n=1"], [("quit(0 if games > 0 else 1)", "quit(0 if games > 999999 else 1)")]),
 ("trace", ["--t=5"], [("quit(0 if steps > 0 else 1)", "quit(0 if steps > 99999999 else 1)")]),
 ("playtest", ["--n=1", "--cells=0"], [("quit(0 if rows > 0 else 1)", "quit(0 if rows > 999999 else 1)")]),
]
only = sys.argv[3:] 
env = dict(os.environ, XDG_DATA_HOME="/home/claude/w/xdg_mut")
def run(script, args, tmo=900):
    t = time.time()
    try:
        p = subprocess.run([godot, "--headless", "--path", proj, "-s", "res://tests/" + script] + (["--"] + args if args else []),
                           capture_output=True, text=True, timeout=tmo, env=env)
        out = p.stdout + p.stderr; rc = p.returncode
    except subprocess.TimeoutExpired:
        out, rc = "TIMEOUT", 124
    err = bool(re.search(r"SCRIPT ERROR|Parse Error|^ERROR:", out, re.M))
    return rc, err, time.time() - t, out
for name, args, subs in CASES:
    if only and name not in only: continue
    src = open(f"{proj}/tests/{name}.gd").read(); mut = src
    for a, b in subs:
        assert a in mut, (name, a); mut = mut.replace(a, b)
    mp = f"{proj}/tests/_mut_{name}.gd"; open(mp, "w").write(mut)
    try:
        rc0, e0, t0, o0 = run(f"{name}.gd", args)
        rc1, e1, t1, o1 = run(f"_mut_{name}.gd", args)
    finally:
        os.remove(mp)
    ok = (rc1 != 0)
    print(f"{name:16s} original exit {rc0}{' +ENGINE-ERROR' if e0 else ''} ({t0:.0f}s) | broken exit {rc1}{' +ENGINE-ERROR' if e1 else ''} ({t1:.0f}s) -> {'RED as expected' if ok else 'STILL GREEN: BAD'}", flush=True)
    if rc0 != 0 or e0:
        print("   original tail:", " | ".join(o0.strip().splitlines()[-4:])[:600], flush=True)
