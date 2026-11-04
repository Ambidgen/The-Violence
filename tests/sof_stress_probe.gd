extends SceneTree
## Compares the historical resistance-imposed ceiling with the new accumulator.
## The new columns assume repeated 0.15 stress inputs with *no decay*: they are
## theoretical exposure counts, not evidence that a habit occurred in a fight.
##   godot --headless --path . -s res://tests/sof_stress_probe.gd -- --n=10000 --seed=8675309
const Habits = preload("res://scripts/data/habits.gd")


func _init() -> void:
	var n := 10000
	var seed_v := 8675309
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--n="):
			n = int(String(arg).trim_prefix("--n="))
		elif String(arg).begins_with("--seed="):
			seed_v = int(String(arg).trim_prefix("--seed="))
	if n < 1:
		printerr("--n must be positive")
		quit(2)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var values: Array = []
	var old_reached := {}
	var inputs := {}
	var anxious_inputs := {}
	for hid in Habits.stress_bad_ids():
		old_reached[hid] = 0
		inputs[hid] = []
		anxious_inputs[hid] = []
	for i in n:
		var ech: Dictionary = Habits.vary(Habits.ECHELONS["sof"], rng)
		var resist := float(ech["resist"])
		values.append(resist)
		var gain := Habits.habit_stress_gain(0.15, resist)
		for hid in Habits.stress_bad_ids():
			var habit: Dictionary = Habits.bad_info(hid)
			var threshold: float = float(habit["t"]) - 0.12
			var anxious_threshold: float = float(habit["t"]) - 0.21
			if 1.0 - resist >= threshold:
				old_reached[hid] += 1
			inputs[hid].append(int(ceil(threshold / gain)))
			anxious_inputs[hid].append(int(ceil(anxious_threshold / gain)))
	values.sort()
	print("SOF varied resistance, n=%d seed=%d; min %.3f, median %.3f, max %.3f" % [n, seed_v,
		values[0], values[n / 2], values[-1]])
	print("id,name,threshold_alone,historical_raw_ceiling_reachable_pct,new_inputs_median,new_inputs_p95,new_anxiety_inputs_median")
	for hid in Habits.stress_bad_ids():
		var habit: Dictionary = Habits.bad_info(hid)
		inputs[hid].sort()
		anxious_inputs[hid].sort()
		print("%s,%s,%.2f,%.2f,%d,%d,%d" % [hid, habit["name"], float(habit["t"]) - 0.12,
			100.0 * old_reached[hid] / n, inputs[hid][n / 2], inputs[hid][mini(n - 1, int(n * 0.95))], anxious_inputs[hid][n / 2]])
	quit()
