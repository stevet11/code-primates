extends "res://scripts/room.gd"
## Boss's office (2nd floor): the door code (sticky note) gets you in. Nothing to solve in here.


func _setup() -> void:
	room_id = "boss"
	wall_color = Color("5a3a2a")
	floor_color = Color("3b2a22")
	horizon_y = 190.0
	walk_poly = PackedVector2Array([Vector2(16, 198), Vector2(624, 198), Vector2(632, 284), Vector2(8, 284)])
	spawns = {"default": Vector2(320, 240), "from_hall": Vector2(60, 214)}
	obstacles.append(PackedVector2Array([Vector2(260, 190), Vector2(420, 190), Vector2(420, 230), Vector2(260, 230)]))

	add_hotspot("door", "Hallway door", Rect2(20, 70, 80, 120), Vector2(60, 206),
			"The door back to the hallway.", Color("566c86"), {"exit": ["hallway", "from_boss"], "sort_y": horizon_y})
	add_hotspot("window", "Window", Rect2(130, 36, 110, 90), Vector2(180, 214),
			"A corner view of the city at night. Every light is somebody working late.", Color("1a1c2c"),
			{"sort_y": horizon_y})
	add_hotspot("desk", "Desk", Rect2(260, 146, 160, 84), Vector2(340, 244),
			"A huge, clean desk. Nothing on it but a nameplate: \"THE BOSS\".", Color("8b5a2b"), {"sort_y": 230.0})
	add_hotspot("chair", "Leather chair", Rect2(430, 140, 60, 80), Vector2(460, 244),
			"A leather chair. It looks more comfortable than a bed.", Color("1a1c2c"), {"sort_y": 220.0})
	add_hotspot("trophies", "Trophy shelf", Rect2(480, 50, 100, 70), Vector2(530, 214),
			"Trophies for golf, golf, golf and a participation ribbon for 'Leadership'.", Color("ffcd75"),
			{"sort_y": horizon_y})


func on_interact(h: Dictionary, verb: String, _item: String) -> bool:
	match h["id"]:
		"desk":
			if verb == "Use":
				# The hint: the safe's PIN is something the accountant says.
				Game.set_flag("boss_hint")
				Game.say("You open a drawer. Blank \"THE BOSS\" business cards, a golf-ball stress ball, and a sticky note: \"Safe PIN? Ask Accounting. The bean counter says it whenever he loses count.\"")
				return true
			if verb == "Take":
				Game.say("You take a pen. It's engraved \"THE BOSS\". It's so heavy it can't be a pen. You put it back.")
				return true
			if verb == "Talk":
				await Game.talk("bossdesk")
				return true
		"trophies":
			if verb == "Talk":
				await Game.talk("trophies")
				return true
			if verb == "Take":
				Game.say("They're bolted down. One plate says: \"Most Likely To Be Replaced By A Script\". It has your name on it.")
				return true
			if verb == "Use":
				Game.say("You polish a trophy with your sleeve. It's now slightly shinier. So are you.")
				return true
		"chair":
			if verb == "Use":
				Game.say("You sit in the leather chair and swivel. Wheee. You feel important for exactly four seconds.")
				return true
	return false
