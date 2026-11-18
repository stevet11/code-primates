extends "res://scripts/rooms/corridor.gd"


func _floor_letter() -> String:
	return "B"


func _floor_setup() -> void:
	room_id = "basement"
	wall_color = Color("4a4e5a")
	floor_color = Color("2b2d33")
	add_hotspot("sign", "Wet floor sign", Rect2(190, 120, 36, 60), Vector2(208, 200),
			"WET FLOOR. The floor is, in fact, dry. Someone is being cautious.", Color("ffcd75"))
	add_hotspot("bucket", "Mop bucket", Rect2(250, 140, 44, 40), Vector2(272, 200),
			"A mop bucket full of grey water. It has been there a while.", Color("566c86"))
	spawns["from_closet"] = Vector2(370, 212)
	spawns["from_itlab"] = Vector2(550, 212)
	add_hotspot("closet", "Janitor closet", Rect2(330, 60, 80, 120), Vector2(370, 196),
			"The janitor closet. Locked.", Color("333c57"), {"sort_y": horizon_y})
	add_hotspot("labdoor", "IT lab door", Rect2(500, 52, 100, 128), Vector2(550, 196),
			"The IT lab. A card reader is next to the door. It's locked.", Color("38b764"), {"sort_y": horizon_y})
	if Game.flag("closet_open"):
		_open(get_hotspot("closet"), "closet", "from_hall", "The janitor closet, standing open.")
	if Game.flag("itlab_open"):
		_open(get_hotspot("labdoor"), "itlab", "from_basement", "The IT lab, standing open.")


func _open(h: Dictionary, room: String, spawn: String, text: String) -> void:
	h["exit"] = [room, spawn]
	h["look"] = text
	h["state"] = "open"  # the reader's light turns green (art: <id>_open.png, if there is any)


func on_interact(h: Dictionary, verb: String, item: String) -> bool:
	match h["id"]:
		"closet":
			if verb == "Use" and item == "janitor_key":
				Game.set_flag("closet_open")
				_open(h, "closet", "from_hall", "The janitor closet, standing open.")
				Audio.play("unlock")
				Game.say("The key turns. The closet door creaks open.")
				return true
			if verb == "Use":
				Game.say("Locked. The lock looks older than the building.")
				return true
		"labdoor":
			if verb == "Use" and item == "keycard":
				Game.set_flag("itlab_open")
				_open(h, "itlab", "from_basement", "The IT lab, standing open.")
				Audio.play("unlock")
				Game.say("Beep! The reader flashes green. The IT lab door slides open.")
				return true
			if verb == "Use":
				Game.say("It wants a keycard.")
				return true
	return false
