extends "res://scripts/room.gd"


func _setup() -> void:
	room_id = "office"
	wall_color = Color("5d275d")
	floor_color = Color("29366f")
	horizon_y = 192.0
	walk_poly = PackedVector2Array([Vector2(16, 200), Vector2(624, 200), Vector2(632, 284), Vector2(8, 284)])
	spawns = {"default": Vector2(320, 240), "from_hall": Vector2(576, 214)}
	# The desk blocks the floor under and behind it.
	obstacles.append(PackedVector2Array([Vector2(200, 170), Vector2(400, 170), Vector2(400, 228), Vector2(200, 228)]))

	add_hotspot("poster", "Poster", Rect2(60, 48, 80, 100), Vector2(100, 220),
			"A poster: \"Ook! Nobody deploys on Fridays.\"", Color("b13e53"), {"talk": "poster"})
	add_hotspot("window", "Window", Rect2(246, 30, 148, 108), Vector2(300, 238),
			"Night falls over Silicon Gulch. Somewhere out there, someone is deploying on a Friday.")
	add_hotspot("desk", "Desk", Rect2(200, 168, 200, 60), Vector2(300, 236),
			"A desk buried under cables and coffee rings.", Color("8b5a2b"))
	add_hotspot("computer", "Computer", Rect2(282, 134, 44, 34), Vector2(300, 236),
			"Your computer. The cursor blinks, waiting for you to write something brilliant.", Color("a7f070"),
			{"sort_y": 229.0})
	add_hotspot("mug", "Mug", Rect2(224, 150, 20, 18), Vector2(236, 238),
			"Your coffee mug. Empty. It says: \"Programmer: noun, a machine that turns coffee into code.\"",
			Color("f4f4f4"), {"sort_y": 229.0})
	add_hotspot("clip", "Paperclip", Rect2(356, 152, 16, 10), Vector2(366, 236),
			"A paperclip lying on the desk, next to the keyboard.", Color("94b0c2"), {"sort_y": 229.0})
	add_hotspot("drawer", "Drawer", Rect2(300, 200, 60, 24), Vector2(330, 236),
			"A small locked drawer.", Color("5c3a1a"), {"sort_y": 229.0})
	add_hotspot("door", "Hallway door", Rect2(536, 72, 80, 120), Vector2(576, 206),
			"The door to the hallway.", Color("566c86"),
			{"exit": ["hallway", "from_office"], "sort_y": horizon_y})  # flat on the wall: player always in front

	if Game.flag("mug_taken"):
		get_hotspot("mug")["hidden"] = true
	if Game.flag("clip_taken"):
		get_hotspot("clip")["hidden"] = true
	if Game.flag("drawer_open"):
		get_hotspot("drawer")["color"] = Color("2a1a0a")
		get_hotspot("drawer")["state"] = "open"


func on_interact(h: Dictionary, verb: String, item: String) -> bool:
	match h["id"]:
		"computer":
			if verb == "Use":
				if Game.too_sleepy("write a single line of code"):
					return true
				Game.say("You type: print(\"hello world\"). It runs. Somewhere, a manager smiles.")
				return true
		"mug":
			if verb == "Take":
				Game.add_item("mug")
				Game.set_flag("mug_taken")
				h["hidden"] = true
				Game.say("You pick up your mug. It's empty. Tragic.")
				return true
		"clip":
			if verb == "Take":
				Game.add_item("paperclip")
				Game.set_flag("clip_taken")
				h["hidden"] = true
				Game.say("You pocket the paperclip.")
				return true
		"drawer":
			if verb == "Use" and item == "paperclip":
				if Game.flag("drawer_open"):
					Game.say("Already open.")
				else:
					Game.set_flag("drawer_open")
					Audio.play("unlock")
					Game.add_item("keycard")
					h["color"] = Color("2a1a0a")
					h["state"] = "open"
					Game.say("Click! Inside is a keycard.")
				return true
			if verb == "Use":
				Game.say("It's locked." if not Game.flag("drawer_open") else "Empty now.")
				return true
			if verb == "Look" and Game.flag("drawer_open"):
				Game.say("The drawer hangs open, empty.")
				return true
	return false
