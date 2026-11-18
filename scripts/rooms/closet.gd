extends "res://scripts/room.gd"
## Janitor closet (basement). Take the flashlight and the spare fuse. Flags: flashlight_taken, fuse_taken.


func _setup() -> void:
	room_id = "closet"
	wall_color = Color("3a3d44")
	floor_color = Color("2b2d33")
	horizon_y = 190.0
	walk_poly = PackedVector2Array([Vector2(16, 198), Vector2(624, 198), Vector2(632, 284), Vector2(8, 284)])
	spawns = {"default": Vector2(320, 240), "from_hall": Vector2(60, 214)}
	add_hotspot("door", "Basement door", Rect2(20, 70, 80, 120), Vector2(60, 206),
			"The door back to the basement hallway.", Color("566c86"),
			{"exit": ["basement", "from_closet"], "sort_y": horizon_y})
	add_hotspot("shelf", "Shelves", Rect2(150, 60, 150, 110), Vector2(220, 214),
			"Shelves of cleaning supplies: bleach, sponges, and many mysterious bottles.", Color("5a4a3a"),
			{"sort_y": horizon_y})
	add_hotspot("flashlight", "Flashlight", Rect2(340, 100, 30, 12), Vector2(355, 214),
			"A flashlight on a shelf.", Color("ffcd75"), {"sort_y": horizon_y})
	add_hotspot("fuse", "Spare fuse", Rect2(400, 120, 18, 14), Vector2(409, 214),
			"A spare fuse in a little box marked 'SPARE'.", Color("ef5a5a"), {"sort_y": horizon_y})
	add_hotspot("mop", "Mop", Rect2(480, 60, 30, 120), Vector2(495, 214),
			"A mop. It has seen things.", Color("cfd2dc"), {"sort_y": horizon_y})
	get_hotspot("flashlight")["hidden"] = Game.flag("flashlight_taken")
	get_hotspot("fuse")["hidden"] = Game.flag("fuse_taken")


func on_interact(h: Dictionary, verb: String, _item: String) -> bool:
	if verb == "Take":
		if h["id"] == "flashlight":
			Game.add_item("flashlight")
			Game.set_flag("flashlight_taken")
			h["hidden"] = true
			Game.say("You take the flashlight.")
			return true
		if h["id"] == "fuse":
			Game.add_item("fuse")
			Game.set_flag("fuse_taken")
			h["hidden"] = true
			Game.say("You take the spare fuse.")
			return true
	return false
