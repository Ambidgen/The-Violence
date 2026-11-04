extends "res://scripts/sim/level.gd"
## Map 11, Civic Plaza (v0.7): the open square where the
## candidates hold their rallies. A stage and a civic pavilion, a crowd pen behind crowd
## barriers, a fountain, food trucks, a cafe, the library and a kiosk. Wide open ground
## with few walls: everyone can see everyone, and every miss carries into the crowd.

## Where the crowd gathers, and the stage they face (read by the operation builder).
var crowd_rects: Array = [Rect2(19.0, 15.5, 26.0, 10.5), Rect2(20.0, 26.5, 7.0, 3.0), Rect2(37.0, 26.5, 7.0, 3.0)]
var stage_c := Vector2(32.0, 11.5)


func _init() -> void:
	id = "m11"
	map_name = "Civic Plaza"
	title = "THE VIOLENCE  -  11 CIVIC PLAZA"
	notes = ["CIVIC PAVILION, STAGE, CROWD PEN, CAFE, KIOSK", "PUBLIC EVENTS  ·  1 SQUARE = 1 m", "MAP 11  ·  SHEET 12 OF 12"]
	W = 64.0
	H = 46.0
	time_limit = 900.0
	default_sizes = [8, 4]
	fenced = false
	stage_hint = "Team A forms up on Bianchi Street and the side lanes; team B holds the buildings round the square."


func _build() -> void:
	# Civic pavilion and the stage
	_room("HALL", "CIVIC PAVILION", [Rect2(22, 2.5, 12, 6)])
	_room("OFFICE", "EVENT OFFICE", [Rect2(34, 2.5, 8, 6)])
	_room("STAGE", "STAGE", [Rect2(25, 9.5, 14, 4)], {"deck": true, "label": Vector2(32, 11.5)})
	_door(28, 8.5, 2.0, {"id": "HALL DOORS"})
	_door(34, 5.5, 0.9)
	_door(42, 6.5, 0.9, {"id": "OFFICE SIDE"})
	_window(24.5, 8.5, 1.6)
	_window(38.0, 8.5, 1.6)
	_window(31.5, 8.5, 1.2)
	# cafe on the west side
	_room("CAFE", "CAFE", [Rect2(2, 15, 9, 7)])
	_room("KITCHEN", "KITCHEN", [Rect2(2, 22, 9, 4)])
	_door(11, 18.5, 1.2, {"id": "CAFE DOOR"})
	_door(6.5, 22, 0.9)
	_door(2, 24, 0.9, {"id": "KITCHEN BACK"})
	_window(11, 16.2, 1.4)
	_window(11, 20.6, 1.0)
	_window(6.0, 15, 1.6)
	# library on the east side
	_room("LIBRARY", "READING ROOM", [Rect2(53, 14, 9, 8)])
	_room("STACKS", "STACKS", [Rect2(53, 22, 9, 6)])
	_door(53, 17, 1.2, {"id": "LIBRARY DOOR"})
	_door(57.5, 22, 0.9)
	_door(62, 25, 0.9, {"id": "STACKS BACK"})
	_window(53, 20, 1.4)
	_window(57.5, 14, 1.6)
	# kiosk on the south side of the square
	_room("KIOSK", "KIOSK", [Rect2(44, 33, 3, 3)])
	_door(45.5, 36, 0.9, {"id": "KIOSK"})
	_window(44, 34.5, 0.8)
	_auto_walls()
	# inside
	_p("furn/checkout", 24.0, 4.0, 2.4, 0.8, Geom.COVER, 1.1, 0.0, "reception desk")
	_p("furn/bookshelf", 22.3, 2.8, 0.5, 2.0, Geom.COVER, 2.0, 90.0, "display case")
	_p("furn/sofa", 30.0, 3.0, 2.0, 0.9, Geom.CONCEAL, 0.8)
	_p("furn/desk", 36.0, 3.2, 1.4, 0.7, Geom.CONCEAL, 0.75)
	_p("furn/cabinet", 40.8, 3.0, 0.6, 0.6, Geom.COVER, 1.3, 0.0, "filing cabinet")
	_p("furn/counter", 3.0, 15.4, 3.0, 0.7, Geom.COVER, 1.0, 0.0, "counter")
	for tx in [5.0, 8.0]:
		_p("furn/table", tx, 18.0, 1.0, 1.0, Geom.LOW, 0.75)
		_p("furn/table", tx, 20.0, 1.0, 1.0, Geom.LOW, 0.75)
	_p("furn/stove", 2.4, 24.8, 1.4, 0.7, Geom.COVER, 0.9, 0.0, "range")
	_p("furn/fridge", 9.8, 22.4, 0.8, 0.8, Geom.COVER, 1.8, 0.0, "fridge")
	_p("furn/desk", 55.5, 15.0, 2.0, 0.8, Geom.COVER, 1.0, 0.0, "circulation desk")
	for sy in [23.0, 25.0]:
		_p("furn/shelving", 54.0, sy, 6.5, 0.5, Geom.CONCEAL, 2.0, 0.0, "stacks")
	_p("furn/table", 58.5, 18.0, 2.0, 1.0, Geom.LOW, 0.75)
	_p("furn/counter", 44.3, 33.3, 2.4, 0.6, Geom.COVER, 1.0, 0.0, "kiosk counter")
	# the square
	_decor("dash_rect", {"r": Rect2(25, 9.5, 14, 4)})
	_p("yard/barrier", 21.0, 14.0, 22.0, 0.35, Geom.LOW, 1.1, 0.0, "crowd barrier")
	_p("yard/barrier", 18.4, 15.5, 0.35, 10.0, Geom.LOW, 1.1, 0.0, "crowd barrier")
	_p("yard/barrier", 45.3, 15.5, 0.35, 10.0, Geom.LOW, 1.1, 0.0, "crowd barrier")
	_pool(Rect2(28, 30, 8, 4))
	_p("yard/truck", 47.0, 17.5, 2.5, 7.5, Geom.COVER, 2.6, 90.0, "food truck")
	_p("yard/van", 14.0, 26.5, 2.1, 5.0, Geom.COVER, 1.9, 90.0, "food van")
	for bp in [Vector2(17.0, 31.0), Vector2(45.5, 31.0), Vector2(24.0, 36.0), Vector2(38.5, 36.0)]:
		_p("yard/bench", bp.x, bp.y, 1.6, 0.5, Geom.LOW, 0.45)
	for pp in [Vector2(17.0, 13.6), Vector2(45.8, 13.6), Vector2(26.0, 29.0), Vector2(36.8, 29.0)]:
		_p("yard/planter", pp.x, pp.y, 1.2, 1.2, Geom.COVER, 0.8, 0.0, "planter")
	for lp in [Vector2(14.0, 14.0), Vector2(50.0, 14.0), Vector2(14.0, 37.0), Vector2(50.0, 37.0), Vector2(32.0, 38.5)]:
		_wall(Rect2(lp - Vector2(0.1, 0.1), Vector2(0.2, 0.2)), "lamp post")
	_p("yard/bins", 12.2, 23.4, 0.8, 0.6, Geom.CONCEAL, 1.1, 0.0, "bins")
	_p("yard/dumpster", 0.4, 27.0, 1.1, 1.9, Geom.COVER, 1.4, 90.0, "dumpster")
	_p("yard/generator", 41.0, 10.5, 1.4, 1.0, Geom.COVER, 1.2, 0.0, "sound desk")
	_trunk(Vector2(16.0, 9.0), 4.0)
	_trunk(Vector2(48.0, 9.0), 4.0)
	_trunk(Vector2(12.0, 33.0), 3.8)
	_trunk(Vector2(52.0, 33.0), 3.8)
	_trunk(Vector2(20.5, 38.0), 3.6)
	_trunk(Vector2(43.0, 38.5), 3.6)
	# Bianchi Street along the south edge, cars at the kerb
	_decor("road", {"r": Rect2(0, 41.0, 64, 5.0), "axis": "h"})
	_decor("text", {"p": Vector2(0.4, 40.7), "text": "BIANCHI STREET"})
	for cx in [7.0, 19.0, 42.0, 55.0]:
		_p("yard/car", cx, 41.3, 4.4, 1.9, Geom.COVER, 1.45, 0.0, "car")
	stage_a = [{"r": Rect2(4.0, 43.4, 22.0, 2.4), "face": -PI / 2.0}, {"r": Rect2(38.0, 43.4, 22.0, 2.4), "face": -PI / 2.0},
		{"r": Rect2(0.4, 29.0, 2.6, 10.0), "face": 0.0}, {"r": Rect2(61.0, 29.0, 2.6, 10.0), "face": PI}]
