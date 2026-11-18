extends "res://scripts/room.gd"
## IT manager's office (basement). The computer's password is the last 4 digits of the rack serial.
## Flags: computer_unlocked, card_taken.


func _setup() -> void:
	room_id = "itmgr"
	wall_color = Color("5a5a4a")
	floor_color = Color("3b3a2a")
	horizon_y = 190.0
	walk_poly = PackedVector2Array([Vector2(16, 198), Vector2(624, 198), Vector2(632, 284), Vector2(8, 284)])
	spawns = {"default": Vector2(320, 240), "from_lab": Vector2(60, 214)}
	obstacles.append(PackedVector2Array([Vector2(270, 190), Vector2(450, 190), Vector2(450, 230), Vector2(270, 230)]))

	add_hotspot("door", "Lab door", Rect2(20, 70, 80, 120), Vector2(60, 206),
			"The door back to the IT lab.", Color("566c86"), {"exit": ["itlab", "from_itmgr"], "sort_y": horizon_y})
	add_hotspot("calendar", "Calendar", Rect2(140, 60, 60, 70), Vector2(170, 214),
			"The current date is circled. Under it, in red marker: \"SHUTDOWN?\"", Color("f4f4f4"),
			{"sort_y": horizon_y})
	add_hotspot("cabinet", "Filing cabinet", Rect2(480, 70, 60, 120), Vector2(510, 214),
			"A filing cabinet. Every drawer is stuffed with TPS reports. There's a label: \"TPS Reports (cover sheets attached, as required).\"",
			Color("8b8f9c"), {"sort_y": horizon_y})
	add_hotspot("desk", "Desk", Rect2(270, 160, 180, 72), Vector2(360, 244),
			"A messy desk with two monitors and a mug that says \"World's Okayest Manager\".", Color("8b5a2b"),
			{"sort_y": 230.0})
	add_hotspot("computer", "Computer", Rect2(320, 126, 60, 36), Vector2(350, 244),
			"The manager's computer. It's locked: PASSWORD REQUIRED.", Color("a7f070"), {"sort_y": 228.0})
	add_hotspot("drawer", "Desk drawer", Rect2(400, 190, 40, 24), Vector2(420, 246),
			"The desk drawer. An electronic lock blinks red.", Color("5c3a1a"), {"sort_y": 230.0})
	if Game.flag("computer_unlocked"):
		_unlock()


func _unlock() -> void:
	get_hotspot("computer")["look"] = "The computer, logged in. A pop-up says 'Drawer lock released'."
	get_hotspot("drawer")["look"] = "The desk drawer. The lock blinks green."
	get_hotspot("drawer")["state"] = "unlocked"


func on_interact(h: Dictionary, verb: String, item: String) -> bool:
	match h["id"]:
		"computer":
			if verb == "Use" and Game.too_sleepy("type a password"):
				return true
			if verb == "Use" and item == "serial_note":
				if Game.flag("computer_unlocked"):
					Game.say("You're already in.")
				else:
					Game.set_flag("computer_unlocked")
					_unlock()
					Audio.play("unlock")
					Game.say("Password: 5189. You're in! A pop-up appears: 'Drawer lock released.'")
				return true
			if verb == "Use":
				Audio.play("error")
				Game.say("PASSWORD REQUIRED. There was a sticky note about it in the lab: the last 4 of the rack serial.")
				return true
		"drawer":
			if verb == "Take" or verb == "Use":
				if not Game.flag("computer_unlocked"):
					Audio.play("error")
					Game.say("The drawer's electronic lock is red. The computer must control it.")
				elif Game.flag("card_taken"):
					Game.say("The drawer is empty.")
				else:
					Game.set_flag("card_taken")
					Game.add_item("green_card")
					Game.say("The drawer pops open. Inside is a green keycard: SERVER ROOM ACCESS.")
				return true
		"cabinet":
			if verb == "Use" or verb == "Take":
				Game.say("TPS reports. All of them. Each has a new cover sheet and a sticky note: \"Did you get the memo about the cover sheets?\"")
				return true
	return false
