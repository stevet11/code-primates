extends "res://scripts/rooms/corridor.gd"


func _floor_letter() -> String:
	return "3"


func _floor_setup() -> void:
	room_id = "floor3"
	wall_color = Color("5d4a6b")
	floor_color = Color("3b3045")
	spawns["from_accounting"] = Vector2(240, 212)
	add_hotspot("accounting", "Accounting", Rect2(200, 60, 80, 120), Vector2(240, 196),
			"Accounting. You can hear someone counting behind the door.", Color("566c86"),
			{"exit": ["accounting", "from_hall"], "sort_y": horizon_y})
	spawns["from_vp"] = Vector2(370, 212)
	spawns["from_ceo"] = Vector2(520, 212)
	add_hotspot("vp", "VP office", Rect2(330, 60, 80, 120), Vector2(370, 196),
			"The VP's office. A tiny sign says 'In a meeting.'", Color("566c86"),
			{"exit": ["vp", "from_hall"], "sort_y": horizon_y})
	add_hotspot("ceo", "CEO office", Rect2(480, 60, 80, 120), Vector2(520, 196),
			"The CEO's office. Locked.", Color("b13e53"), {"sort_y": horizon_y})
	if Game.flag("ceo_open"):
		_open_ceo(get_hotspot("ceo"))


func _open_ceo(h: Dictionary) -> void:
	h["exit"] = ["ceo", "from_hall"]
	h["look"] = "The CEO's office, standing open."


func on_interact(h: Dictionary, verb: String, item: String) -> bool:
	if h["id"] == "ceo" and verb == "Use":
		if item == "ceo_key":
			Game.set_flag("ceo_open")
			_open_ceo(h)
			Audio.play("unlock")
			Game.say("The brass key turns. The CEO's office is open.")
		else:
			Game.set_flag("saw_ceo_lock")
			Game.say("It's locked. It would take a very important key.")
		return true
	return false
