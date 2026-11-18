extends "res://scripts/room.gd"


func _setup() -> void:
	room_id = "hallway"
	Game.flags["floor"] = "2"
	wall_color = Color("38b764")
	floor_color = Color("3b5dc9").darkened(0.5)
	horizon_y = 180.0
	walk_poly = PackedVector2Array([Vector2(16, 188), Vector2(624, 188), Vector2(632, 284), Vector2(8, 284)])
	spawns = {"default": Vector2(320, 240), "from_office": Vector2(60, 212), 			"from_elevator": Vector2(435, 212),
			"from_conference": Vector2(160, 212), "from_boss": Vector2(340, 212)}
	auto_doors = ["elevator"]

	add_hotspot("door", "Office door", Rect2(20, 60, 80, 120), Vector2(60, 196),
			"The door back to the office.", Color("566c86"), {"exit": ["office", "from_hall"], "sort_y": horizon_y})
	add_hotspot("confdoor", "Conference room", Rect2(120, 60, 80, 120), Vector2(160, 196),
			"The conference room. A sign says: 'Meeting in progress'. It's been that way for weeks.",
			Color("566c86"), {"exit": ["conference", "from_hall"], "sort_y": horizon_y})
	add_hotspot("bossdoor", "Boss's office", Rect2(300, 60, 80, 120), Vector2(340, 196),
			"The boss's office. There's a keypad by the door. It's locked.", Color("8b5a2b"), {"sort_y": horizon_y})
	add_hotspot("elevator", "Elevator", Rect2(390, 60, 90, 120), Vector2(435, 196),
			"The elevator.", Color("a8abb8"), {"exit": ["elevator", "default"], "sort_y": horizon_y})

	# Details painted into the background: Look-only hotspots (no sprite).
	add_hotspot("exitsign", "Exit sign", Rect2(300, 28, 40, 16), Vector2(335, 206),
			"An exit sign. It has been pointing at the same door for years.")
	for i in 3:
		add_hotspot("light%d" % i, "Ceiling light", Rect2([80, 300, 520][i], 0, 70, 14),
				Vector2([115, 335, 555][i], 200),
				"Fluorescent tubes. One of them flickers. Nobody has filed a ticket.")

	if Game.flag("boss_open"):
		get_hotspot("bossdoor")["exit"] = ["boss", "from_hall"]
		get_hotspot("bossdoor")["look"] = "The boss's office, unlocked. The keypad light is green."
		get_hotspot("bossdoor")["state"] = "open"


func on_interact(h: Dictionary, verb: String, item: String) -> bool:
	match h["id"]:
		"bossdoor":
			if verb == "Use" and item == "code_note":
				Game.set_flag("boss_open")
				h["exit"] = ["boss", "from_hall"]
				h["look"] = "The boss's office, unlocked. The keypad light is green."
				h["state"] = "open"  # the keypad light turns from red to green
				Audio.play("unlock")
				Game.say("You punch in 3-1-4-1. Beep! The lock clicks open.")
				return true
			if verb == "Use" or verb == "Look":
				Game.set_flag("saw_keypad")
			if verb == "Use":
				Game.say("The keypad wants a four digit code.")
				return true
	return false
