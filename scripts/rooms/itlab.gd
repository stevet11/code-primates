extends "res://scripts/room.gd"

const Blinkers := preload("res://scripts/blinkers.gd")
## IT lab (basement). Flags: power_on (fuse box), knows_serial, lab_open (server door), janitor_key_taken.
## The janitor key is on the bench; the rack serial needs the flashlight; the fuse box needs the fuse.


func _setup() -> void:
	room_id = "itlab"
	wall_color = Color("3a4a5a")
	floor_color = Color("2b2f3a")
	horizon_y = 190.0
	walk_poly = PackedVector2Array([Vector2(16, 198), Vector2(624, 198), Vector2(632, 284), Vector2(8, 284)])
	spawns = {"default": Vector2(320, 240), "from_basement": Vector2(60, 214),
			"from_server": Vector2(590, 214), "from_itmgr": Vector2(500, 214)}
	obstacles.append(PackedVector2Array([Vector2(355, 190), Vector2(450, 190), Vector2(450, 226), Vector2(355, 226)]))

	add_hotspot("door", "Basement door", Rect2(20, 70, 80, 120), Vector2(60, 206),
			"The door back to the basement hallway.", Color("566c86"),
			{"exit": ["basement", "from_itlab"], "sort_y": horizon_y})
	add_hotspot("fusebox", "Fuse box", Rect2(120, 90, 36, 44), Vector2(138, 214),
			"A fuse box. One fuse is blown. The manager's office lights are out.", Color("8b8f9c"),
			{"sort_y": horizon_y})
	add_hotspot("whiteboard", "Whiteboard", Rect2(170, 50, 90, 70), Vector2(215, 214),
			"A half-erased network diagram. One arrow just says \"here be dragons\".", Color("dfe3ea"),
			{"sort_y": horizon_y})
	add_hotspot("rack", "Server rack", Rect2(280, 60, 60, 130), Vector2(310, 214),
			"A rack of blinking switches. A serial plate is on the back, but it's too dark to read.",
			Color("2a3248"), {"sort_y": horizon_y})
	add_hotspot("bench", "Workbench", Rect2(355, 150, 95, 60), Vector2(402, 232),
			"A bench of dismantled PCs and tangled cables. A sticky note on a monitor reads: \"pw = last 4 of the rack serial.\"",
			Color("8b5a2b"), {"sort_y": 226.0})
	add_hotspot("key", "Janitor's key", Rect2(420, 138, 18, 12), Vector2(430, 232),
			"A key on a ring, stuck under a keyboard. The tag says 'CLOSET'.", Color("ffcd75"), {"sort_y": 224.0})
	add_hotspot("mgrdoor", "IT manager's office", Rect2(470, 72, 70, 118), Vector2(505, 206),
			"The IT manager's office. The room is dark.", Color("1a1c2c"), {"sort_y": horizon_y})
	add_hotspot("greendoor", "Green door", Rect2(555, 66, 70, 124), Vector2(590, 206),
			"A green security door. A card reader next to it. SERVER ROOM.", Color("38b764"), {"sort_y": horizon_y})
	get_hotspot("key")["hidden"] = Game.flag("janitor_key_taken")
	if Game.flag("power_on"):
		_power(get_hotspot("mgrdoor"))
	if Game.flag("lab_open"):
		_open_green(get_hotspot("greendoor"))


## The rack's lights: slow, calm blinking (the sprite has the LED sockets dark; these are the lights).
func _after_art() -> void:
	var rack := get_hotspot("rack")["rect"] as Rect2
	var base: float = get_hotspot("rack").get("sort_y", rack.end.y)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var leds := Blinkers.new()
	leds.rate_scale = 0.4
	leds.position = Vector2(rack.position.x, base + 0.1)   # sorts just in front of the rack sprite
	add_child(leds)
	var colors := [Color("a7f070"), Color("a7f070"), Color("ffcd75"), Color("ef5a5a"), Color("41a6f6")]
	var top := rack.position.y - base
	for row in range(8, int(rack.size.y) - 10, 14):
		for i in 5:
			leds.add_led(Vector2(10 + i * 8, top + row + 3), colors[(i + row) % 5], rng)


func _power(h: Dictionary) -> void:
	h["exit"] = ["itmgr", "from_lab"]
	h["color"] = Color("566c86")
	h["look"] = "The IT manager's office. The lights are on."
	get_hotspot("fusebox")["look"] = "The fuse box. The new fuse is humming."
	get_hotspot("fusebox")["state"] = "on"


func _open_green(h: Dictionary) -> void:
	h["exit"] = ["server", "from_hall"]
	h["look"] = "The server room door, unlocked. The reader light is green."
	h["state"] = "open"  # the reader's light turns green


func on_interact(h: Dictionary, verb: String, item: String) -> bool:
	match h["id"]:
		"key":
			if verb == "Take":
				Game.add_item("janitor_key")
				Game.set_flag("janitor_key_taken")
				h["hidden"] = true
				Game.say("You take the janitor's key.")
				return true
		"fusebox":
			if verb == "Use" and item == "fuse":
				if Game.flag("power_on"):
					Game.say("It's fixed already.")
				else:
					Game.remove_item("fuse")
					Game.set_flag("power_on")
					_power(get_hotspot("mgrdoor"))
					Audio.play("unlock")
					Game.say("You swap the blown fuse. A light flickers on in the manager's office.")
				return true
			if verb == "Use":
				Game.say("You need a fuse to fix it.")
				return true
		"rack":
			if verb == "Use" and item == "flashlight":
				if Game.flag("knows_serial"):
					Game.say("The serial plate: XR-7-5189. You already wrote it down.")
				else:
					Game.set_flag("knows_serial")
					Game.add_item("serial_note")
					Game.say("You shine the flashlight behind the rack. The plate reads XR-7-5189. You write it down.")
				return true
		"mgrdoor":
			if verb == "Use" or verb == "Look":
				if not Game.flag("power_on"):
					if verb == "Use":
						Game.say("It's pitch black in there. You'd need the lights on.")
						return true
					return false
		"greendoor":
			if verb == "Use" and item == "green_card":
				Game.set_flag("lab_open")
				_open_green(h)
				Audio.play("unlock")
				Game.say("Beep! The reader flashes green. The server room door slides open.")
				await get_tree().create_timer(0.9).timeout
				Game.room_change_requested.emit("server", "from_hall")
				return true
			if verb == "Use":
				Game.say("The reader wants a green keycard.")
				return true
	return false
