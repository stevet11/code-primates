extends "res://scripts/room.gd"
## VP office (3rd floor). The CEO's key hangs on the VP's keyring on a wall hook. Flag: vp_key_taken.


func _setup() -> void:
	room_id = "vp"
	wall_color = Color("5a4a7a")
	floor_color = Color("3b3045")
	horizon_y = 190.0
	walk_poly = PackedVector2Array([Vector2(16, 198), Vector2(624, 198), Vector2(632, 284), Vector2(8, 284)])
	spawns = {"default": Vector2(320, 240), "from_hall": Vector2(60, 214)}
	obstacles.append(PackedVector2Array([Vector2(250, 190), Vector2(430, 190), Vector2(430, 232), Vector2(250, 232)]))

	add_hotspot("door", "Hallway door", Rect2(20, 70, 80, 120), Vector2(60, 206),
			"The door back to the hallway.", Color("566c86"), {"exit": ["floor3", "from_vp"], "sort_y": horizon_y})
	add_hotspot("whiteboard", "Whiteboard", Rect2(130, 44, 100, 70), Vector2(180, 214),
			"Buzzwords: \"synergy\", \"pivot\", \"circle back\", \"leverage the banana\".", Color("dfe3ea"),
			{"sort_y": horizon_y})
	add_hotspot("orgchart", "Org chart", Rect2(470, 50, 70, 80), Vector2(505, 214),
			"The org chart. The CEO is at the top. At the very bottom is a tiny monkey icon. That's you.",
			Color("f4f4f4"), {"sort_y": horizon_y})
	add_hotspot("hook", "Keyring", Rect2(560, 60, 22, 30), Vector2(570, 214),
			"The VP's keyring hangs on a hook. One brass key has a tag: 'CEO'.", Color("ffcd75"),
			{"sort_y": horizon_y})
	add_hotspot("desk", "Desk", Rect2(250, 146, 180, 86), Vector2(340, 244),
			"A huge desk. Nameplate: \"Vice President of Meetings About Meetings.\" A half-eaten donut, a stress ball, and a calendar where every day says MEETING.",
			Color("8b5a2b"), {"sort_y": 232.0})
	add_hotspot("donut", "Donut", Rect2(284, 148, 24, 14), Vector2(296, 244),
			"A half-eaten donut. Someone has been ignoring it for days.", Color("e8a0b0"), {"sort_y": 233.0})
	add_hotspot("phone", "Phone", Rect2(380, 146, 28, 16), Vector2(394, 244),
			"A desk phone with a blinking message light.", Color("1a1c2c"), {"sort_y": 233.0})
	if Game.flag("vp_key_taken"):
		get_hotspot("hook")["look"] = "The empty hook."
		get_hotspot("hook")["state"] = "empty"


func on_interact(h: Dictionary, verb: String, _item: String) -> bool:
	match h["id"]:
		"hook":
			if verb == "Take" and not Game.flag("vp_key_taken"):
				Game.set_flag("vp_key_taken")
				Game.add_item("ceo_key")
				h["look"] = "The empty hook."
				h["state"] = "empty"
				Game.say("You lift the CEO's key off the VP's keyring. The VP is in a meeting. He won't notice.")
				return true
			if verb == "Take":
				Game.say("The hook is empty.")
				return true
		"donut":
			if verb == "Take" or verb == "Use":
				Game.say("You take a bite. It's stale. The VP will never notice, and neither will your taste buds.")
				return true
		"phone":
			if verb == "Use" or verb == "Talk":
				await Game.talk("vpphone")
				return true
	return false
