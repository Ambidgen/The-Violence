extends Node2D
## The plan's upper layer (1.4, crayon): walls, windows, room names, the title scrap and
## its stamps. It sits above the blood, so a stain slides under a wall and stops at its
## face. The strokes are recorded and boiled by the plan (view/floor_plan.gd).

var plan


func _draw() -> void:
	plan.replay_walls(self)
