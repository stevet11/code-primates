extends "res://scripts/room.gd"
## Conference room (2nd floor). The sticky note under the table has the boss's door code.


func _setup() -> void:
	room_id = "conference"
	wall_color = Color("4a5a6b")
	floor_color = Color("3a4252")
	horizon_y = 190.0
	walk_poly = PackedVector2Array([Vector2(16, 198), Vector2(624, 198), Vector2(632, 284), Vector2(8, 284)])
	spawns = {"default": Vector2(320, 250), "from_hall": Vector2(60, 214)}
	obstacles.append(PackedVector2Array([Vector2(180, 190), Vector2(460, 190), Vector2(460, 240), Vector2(180, 240)]))

	add_hotspot("door", "Hallway door", Rect2(20, 70, 80, 120), Vector2(60, 206),
			"The door back to the hallway.", Color("566c86"), {"exit": ["hallway", "from_conference"], "sort_y": horizon_y})
	add_hotspot("projector", "Projector screen", Rect2(260, 36, 120, 80), Vector2(320, 252),
			"A frozen slide: \"Q4 Roadmap\". Every bullet point is just the word \"Synergy\".", Color("f4f4f4"),
			{"sort_y": horizon_y})
	add_hotspot("whiteboard", "Whiteboard", Rect2(430, 50, 110, 70), Vector2(480, 214),
			"A sketch of a banana with an arrow labelled \"launch\". Nobody will explain it.", Color("dfe3ea"),
			{"sort_y": horizon_y})
	add_hotspot("memo", "Memo", Rect2(150, 70, 50, 44), Vector2(175, 214),
			"MEMO. To: All staff. Re: The upcoming meeting about memos. We need more memos for the meeting about memos. Please send memos about this memo by Friday. (Hard copy only.)",
			Color("f4f4f4"), {"sort_y": horizon_y})
	add_hotspot("table", "Conference table", Rect2(180, 190, 280, 50), Vector2(320, 252),
			"A long table surrounded by chairs. The chairs are better than yours.", Color("8b5a2b"),
			{"sort_y": 240.0})
	add_hotspot("phone", "Speakerphone", Rect2(298, 184, 44, 16), Vector2(320, 252),
			"A speakerphone. Someone is still on hold. Maybe you could talk to it.", Color("1a1c2c"), {"sort_y": 241.0})
	add_hotspot("note", "Sticky note", Rect2(412, 230, 16, 14), Vector2(420, 252),
			"A sticky note stuck under the edge of the table.", Color("ffcd75"), {"sort_y": 241.0})
	if Game.flag("note_taken"):
		get_hotspot("note")["hidden"] = true


func on_interact(h: Dictionary, verb: String, _item: String) -> bool:
	if h["id"] == "phone" and verb == "Talk":
		await Game.talk("speakerphone")
		return true
	if h["id"] == "memo" and verb == "Look":
		await Game.talk("memo")  # three short lines you click through, instead of one long message
		return true
	if h["id"] == "memo" and verb == "Take":
		Game.say("There's only one copy. The memo says you'd need more memos.")
		return true
	if h["id"] == "note":
		if verb == "Look":
			Game.say("It reads: \"Boss door: 3141. DON'T LOSE.\"")
			return true
		if verb == "Take":
			Game.add_item("code_note")
			Game.set_flag("note_taken")
			h["hidden"] = true
			Game.say("You peel the sticky note off. It has the boss's door code on it.")
			return true
	return false
