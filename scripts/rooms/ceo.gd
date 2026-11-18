extends "res://scripts/room.gd"
## CEO office (3rd floor): swing the golf picture aside to find the safe (the accountant's PIN opens it, it holds
## the silver golf ball); the putt gives the USB stick; the terminal is the end-game.
## Flags: painting_moved, safe_open, putt_done, usb_loaded (set at the server room terminal).


func _setup() -> void:
	room_id = "ceo"
	wall_color = Color("2a2a3a")
	floor_color = Color("4a3a2a")
	horizon_y = 190.0
	walk_poly = PackedVector2Array([Vector2(16, 198), Vector2(624, 198), Vector2(632, 284), Vector2(8, 284)])
	spawns = {"default": Vector2(320, 240), "from_hall": Vector2(60, 214)}
	obstacles.append(PackedVector2Array([Vector2(300, 190), Vector2(480, 190), Vector2(480, 232), Vector2(300, 232)]))

	add_hotspot("door", "Hallway door", Rect2(20, 70, 80, 120), Vector2(60, 206),
			"The door back to the hallway.", Color("566c86"), {"exit": ["floor3", "from_ceo"], "sort_y": horizon_y})
	add_hotspot("window", "Window", Rect2(130, 30, 150, 110), Vector2(200, 214),
			"The whole city at night. From up here, everyone looks like a bean counter.", Color("1a1c2c"),
			{"sort_y": horizon_y})
	add_hotspot("plaque", "Plaque", Rect2(495, 50, 110, 42), Vector2(550, 214),
			"\"Leadership is just delegation with better parking.\"", Color("ffcd75"), {"sort_y": horizon_y})
	add_hotspot("photo", "Framed photo", Rect2(520, 100, 60, 46), Vector2(550, 214),
			"The CEO shaking hands with a gorilla. Both look tired. Both are wearing suits.", Color("dfe3ea"),
			{"sort_y": horizon_y})
	add_hotspot("painting", "Golf picture", Rect2(330, 28, 80, 64), Vector2(370, 242),
			"A painting of a golfer lining up a putt on a very green hill. There's a faint outline behind it.",
			Color("41a6f6"), {"sort_y": horizon_y})
	add_hotspot("safe", "Safe", Rect2(344, 42, 52, 44), Vector2(370, 242),
			"A wall safe with a keypad. It wants a PIN.", Color("333c57"), {"sort_y": horizon_y})
	add_hotspot("sofa", "Leather sofa", Rect2(120, 150, 110, 60), Vector2(170, 232),
			"A leather sofa. A small gold plate says: 'Do not sit on this.'", Color("5a3a2a"), {"sort_y": 214.0})
	add_hotspot("desk", "Giant desk", Rect2(300, 146, 180, 86), Vector2(390, 244),
			"A desk the size of a small boat.", Color("8b5a2b"), {"sort_y": 232.0})
	add_hotspot("terminal", "CEO terminal", Rect2(306, 114, 62, 46), Vector2(337, 244),
			"The CEO's terminal. Its screen says: INSERT AUTHORIZED MEDIA.", Color("a7f070"), {"sort_y": 228.0})
	add_hotspot("putter", "Putter", Rect2(70, 232, 40, 10), Vector2(90, 260),
			"The CEO's putter, abandoned on the carpet next to a practice cup. All it needs is a ball.", Color("cfd2dc"),
			{"sort_y": 256.0})
	add_hotspot("cup", "Golf cup", Rect2(150, 252, 28, 12), Vector2(165, 262),
			"A golf practice cup set into the carpet. Someone could putt a ball into it.", Color("1a1c2c"), {"sort_y": 260.0})
	get_hotspot("safe")["hidden"] = not Game.flag("painting_moved")
	get_hotspot("painting")["hidden"] = Game.flag("painting_moved")
	if Game.flag("safe_open"):
		get_hotspot("safe")["look"] = "The safe, standing open and empty."
		get_hotspot("safe")["state"] = "open"
	if Game.flag("putt_done"):
		get_hotspot("cup")["look"] = "The practice cup. Empty. Hole in one."


func on_interact(h: Dictionary, verb: String, item: String) -> bool:
	match h["id"]:
		"painting":
			if verb == "Use" or verb == "Take":
				Game.set_flag("painting_moved")
				h["hidden"] = true
				get_hotspot("safe")["hidden"] = false
				Audio.play("door", 1.2, -6.0)
				Game.say("You swing the golf picture aside. Behind it is a wall safe with a keypad.")
				return true
		"safe":
			if Game.flag("safe_open"):
				if verb == "Look":
					return false
				Game.say("The safe is empty.")
				return true
			if verb == "Use" and item == "pin_note":
				Game.set_flag("safe_open")
				Audio.play("unlock")
				Game.add_item("golf_ball")
				h["look"] = "The safe, standing open and empty."
				h["state"] = "open"
				Game.say("You punch in 4-7-1-9. Click! Inside is a solid silver golf ball, with a note in the CEO's handwriting: \"Do not putt in the office.\"")
				return true
			if verb == "Use":
				Audio.play("error")
				Game.say("The keypad wants a PIN. An accountant might know one.")
				return true
		"cup", "putter":
			# The putter stays here in the room. Use the silver golf ball on the putter or on the hole.
			if verb == "Use" and item == "golf_ball":
				if Game.flag("putt_done"):
					Game.say("You've already made the putt. No need to show off.")
				else:
					await _putt()
				return true
			if verb == "Take" and h["id"] == "putter":
				Game.say("The putter belongs to the CEO, and it stays on the CEO's carpet. All it needs is a ball.")
				return true
			if verb == "Use" and item == "":
				Game.say("A putter and a golf cup, but no ball. Maybe the safe behind the golf picture has one."
						if not Game.has_item("golf_ball") else "Try using the golf ball on it.")
				return true
		"terminal":
			if verb == "Use" and Game.too_sleepy("operate a terminal"):
				return true
			if verb == "Use" and item == "usb_stick":
				if Game.flag("usb_loaded"):
					await _finish()
				else:
					Game.say("The stick is blank. It needs the deploy package from the server room first.")
				return true
			if verb == "Use":
				Audio.play("error")
				Game.say("INSERT AUTHORIZED MEDIA. You don't have any that works yet.")
				return true
		"photo":
			if verb == "Use" or verb == "Take":
				Game.set_flag("read_photo")
				Game.say("Behind the photo is a note: \"Server room backups go on the USB stick. -Mgmt\"")
				return true
	return false


const BALL_START := Vector2(130, 258)   # where the monkey sets the ball down
const BALL_CUP := Vector2(164, 258)     # the middle of the golf cup
const PUTTER_PIVOT := Vector2(7, -24)   # the monkey's hands, in the monkey's own coordinates (facing right)


## The putt, as a little cutscene: fetch the putter, set the ball down, two practice swings, a real swing, and
## the ball rolls into the cup. Then the USB stick pops up and the putter goes back on the carpet.
func _putt() -> void:
	Game.busy = true
	Game.set_verb("Look")
	# 1. Get the putter.
	await player.walk_to(Vector2(90, 260))
	var h := get_hotspot("putter")
	h["hidden"] = true
	_sync_art()
	queue_redraw()
	var held := Node2D.new()                      # drawn with the monkey, so it follows him
	held.position = PUTTER_PIVOT
	held.draw.connect(func():
		held.draw_line(Vector2.ZERO, Vector2(8, 22), Color("94b0c2"), 2.0)           # shaft
		held.draw_rect(Rect2(6, 21, 11, 4), Color("cfd2dc"))                           # head
		held.draw_rect(Rect2(-1, -1, 4, 6), Color("333c57")))                          # grip
	player.add_child(held)
	Audio.play("pickup")
	Game.say("You pick up the CEO's putter.")
	await get_tree().create_timer(0.8).timeout
	# 2. Set the ball down.
	await player.walk_to(Vector2(110, 260))
	player.facing = 1.0                           # face the cup
	var ball := Node2D.new()
	ball.z_index = 1                              # always above the flat cup sprite, so you see it roll over the hole
	ball.position = BALL_START
	ball.draw.connect(func():
		ball.draw_circle(Vector2(0, 1.5), 3.2, Color(0, 0, 0, 0.3))                   # shadow
		ball.draw_circle(Vector2.ZERO, 3.2, Color("cfd2dc"))
		ball.draw_rect(Rect2(-2, -2, 2, 2), Color.WHITE))                              # shine
	add_child(ball)
	Game.remove_item("golf_ball")
	Audio.play("blip", 0.7)
	Game.say("You set the silver ball down in front of the putter.")
	await get_tree().create_timer(0.9).timeout
	# 3. Two practice swings.
	Game.say("A practice swing...")
	for i in 2:
		var t := create_tween()
		t.tween_property(held, "rotation", 0.7, 0.35).set_trans(Tween.TRANS_SINE)
		t.tween_property(held, "rotation", -0.4, 0.2).set_trans(Tween.TRANS_QUAD)
		t.tween_property(held, "rotation", 0.0, 0.25)
		await t.finished
		Audio.play("blip", 0.5, -6.0)
		if i == 0:
			Game.say("...and another.")
		await get_tree().create_timer(0.3).timeout
	Game.say("Okay. For real this time.")
	await get_tree().create_timer(0.8).timeout
	# 4. The real swing: a slow backswing, a fast forward swing, and the ball rolls into the cup.
	var swing := create_tween()
	swing.tween_property(held, "rotation", 0.9, 0.6).set_trans(Tween.TRANS_SINE)
	swing.tween_interval(0.15)
	swing.tween_property(held, "rotation", -0.5, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await swing.finished
	Audio.play("click", 0.6)
	var roll := create_tween()
	roll.tween_property(ball, "position:x", BALL_CUP.x, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var back := create_tween()
	back.tween_property(held, "rotation", 0.0, 0.5)
	await roll.finished
	# 5. In the hole.
	var drop := create_tween().set_parallel(true)       # it tips in: smaller, darker and a touch lower
	drop.tween_property(ball, "scale", Vector2(0.15, 0.15), 0.35).set_trans(Tween.TRANS_QUAD)
	drop.tween_property(ball, "position:y", BALL_CUP.y + 3.0, 0.35)
	drop.tween_property(ball, "modulate", Color(0.25, 0.25, 0.3), 0.35)
	await drop.finished
	ball.queue_free()
	Audio.play("combine", 1.2)
	await get_tree().create_timer(0.7).timeout
	Audio.play("pickup")
	Game.set_flag("putt_done")
	Game.add_item("usb_stick")
	get_hotspot("cup")["look"] = "The practice cup. Empty. Hole in one."
	Game.say("PLINK. Hole in one! The cup pops up a USB stick labelled 'BACKUP - DO NOT LOSE'.")
	await get_tree().create_timer(1.2).timeout
	# 6. The putter goes back on the carpet.
	held.queue_free()
	h["hidden"] = false
	_sync_art()
	queue_redraw()
	Game.busy = false


func _finish() -> void:
	Game.busy = true
	Game.say("You insert the stick. The terminal beeps. The deploy package runs under the CEO's own login.")
	await get_tree().create_timer(3.0).timeout
	Game.ending("Deployed to production.\n\nThe CEO approved it. (They never knew.)\n\nIt was a Friday.\n\nThe end.")
