extends SceneTree
const Campaign = preload("res://scripts/campaign/campaign.gd")
func _init() -> void:
	for sd in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]:
		var c = Campaign.new()
		c.start(sd, true, "user://fresh_legacy_%d.json" % sd)
		var kinds = c.run.drafts.map(func(d): return d["kind"] + ":" + ",".join(d["cards"]))
		var dup: bool = false
		var doc: Array = c.run.drafts[0]["cards"]
		var proc: Array = c.run.drafts[1]["cards"] if c.run.drafts.size() > 1 else []
		# every inheritance that grants an item the procurement could also sell
		var picks: Array = []
		for cid in doc:
			var c2 = Campaign.new()
			c2.start(sd, true, "user://fresh_legacy_%d.json" % sd)
			c2.run.pick(c2, 0, cid)
			if c2.run.drafts.is_empty():
				continue
			for pc in c2.run.drafts[0]["cards"]:
				var before: int = c2.dept.balance
				var stock: Array = c2.run.armory.duplicate()
				var c3 = Campaign.new()
				c3.start(sd, true, "user://fresh_legacy_%d.json" % sd)
				c3.run.pick(c3, 0, cid)
				c3.run.pick(c3, 0, pc)
				if stock.size() == c3.run.armory.size() and c3.dept.balance < before:
					picks.append("%s -> %s wasted $%d" % [cid, pc, before - c3.dept.balance])
		print("seed %d %s | wasted-purchase combos: %s" % [sd, str(kinds), str(picks)])
	quit()
