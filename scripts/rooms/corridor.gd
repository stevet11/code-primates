extends "res://scripts/room.gd"
## Base for the simple floors reached by elevator. Subclasses override _floor_setup()
## and add their own hotspots. The elevator door is on the left, spawn "from_elevator".


func _floor_setup() -> void:
	pass


func _setup() -> void:
	horizon_y = 180.0
	walk_poly = PackedVector2Array([Vector2(16, 188), Vector2(624, 188), Vector2(632, 284), Vector2(8, 284)])
	spawns = {"default": Vector2(320, 240), "from_elevator": Vector2(60, 212)}
	add_hotspot("elevator", "Elevator", Rect2(20, 60, 80, 120), Vector2(60, 196),
			"The elevator.", Color("a8abb8"),
			{"exit": ["elevator", "default"], "sort_y": horizon_y})
	auto_doors = ["elevator"]
	_floor_setup()
	Game.flags["floor"] = _floor_letter()


func _floor_letter() -> String:
	return "2"
