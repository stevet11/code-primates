extends "res://scripts/room.gd"

const Blinkers := preload("res://scripts/blinkers.gd")
const LightShow := preload("res://scripts/light_show.gd")
const RACKS := ["rack_a", "rack_b", "rack_c"]
var _show
# Mostly calm green, with the odd amber, blue or red light.
const LED_COLORS := [Color("a7f070"), Color("a7f070"), Color("a7f070"), Color("a7f070"), Color("a7f070"),
		Color("a7f070"), Color("a7f070"), Color("ffcd75"), Color("41a6f6"), Color("ef5a5a")]


func _setup() -> void:
	room_id = "server"
	wall_color = Color("141a2e")
	floor_color = Color("1a2138")
	horizon_y = 190.0
	walk_poly = PackedVector2Array([Vector2(8, 198), Vector2(632, 198), Vector2(636, 284), Vector2(4, 284)])
	spawns = {"default": Vector2(60, 232), "from_hall": Vector2(60, 214)}
	# Dale's chair and the console desk stand a little off the wall.
	obstacles.append(PackedVector2Array([Vector2(340, 190), Vector2(402, 190), Vector2(402, 214), Vector2(340, 214)]))
	obstacles.append(PackedVector2Array([Vector2(408, 190), Vector2(532, 190), Vector2(532, 214), Vector2(408, 214)]))

	add_hotspot("door", "IT lab door", Rect2(20, 70, 80, 120), Vector2(60, 206),
			"The door back to the IT lab.", Color("566c86"),
			{"exit": ["itlab", "from_server"], "sort_y": horizon_y})
	# Three racks side by side (72px each, no gaps) so their LED panels form one 54x7 matrix.
	add_hotspot("rack_a", "Server rack", Rect2(112, 40, 72, 150), Vector2(148, 214),
			"Rows of blinking lights. Each one is an outage waiting to happen.", Color("2a3248"),
			{"sort_y": horizon_y})
	add_hotspot("rack_b", "Server rack", Rect2(184, 40, 72, 150), Vector2(220, 214),
			"This one is labelled 'PROD'. Someone has added 'please no' in marker.", Color("2a3248"),
			{"sort_y": horizon_y})
	add_hotspot("rack_c", "Server rack", Rect2(256, 40, 72, 150), Vector2(292, 214),
			"The lights on this bank sometimes spell things. Nobody knows why. Nobody has asked.",
			Color("2a3248"), {"sort_y": horizon_y})
	add_hotspot("dale", "Dale", Rect2(342, 92, 64, 122), Vector2(372, 232),
			"Dale, the night sysadmin. He's a sloth. Everything takes a while. He wears a pointy wizard hat, as sysadmins do.", Color("2d4cae"),
			{"talk": "dale", "sort_y": 214.0})
	add_hotspot("console", "Deploy terminal", Rect2(410, 130, 120, 84), Vector2(470, 232),
			"The screen reads: DEPLOY TO PRODUCTION? INSERT AUTHORIZED MEDIA TO CONTINUE.",
			Color("8b5a2b"), {"sort_y": 214.0})
	add_hotspot("cables", "Cables", Rect2(570, 16, 60, 120), Vector2(600, 214),
			"Cable spaghetti. One of these matters. Nobody knows which.")


## Every light in this room blinks in repeating patterns: the three rack LED panels (which spell
## words during the light show), the blade lights below them, and the far wall. Only the panels
## are taken over by the show; the blade and far-wall lights keep blinking throughout.
func _after_art() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	_show = LightShow.new()
	add_child(_show)
	var far := Blinkers.new()
	far.show = _show
	far.z_index = -99  # above the background, below everything else
	add_child(far)
	for i in 60:
		far.add_led(Vector2(rng.randi_range(2, 157) * 4, rng.randi_range(10, 29) * 6),
				LED_COLORS[rng.randi() % LED_COLORS.size()], rng, Vector2i(-1, -1), Vector2(2, 2))
	for i in RACKS.size():
		var r: Rect2 = get_hotspot(RACKS[i])["rect"]
		var base: float = get_hotspot(RACKS[i])["sort_y"]
		var top := r.position.y - base  # rack top, relative to the node
		var led := Blinkers.new()
		led.show = _show
		led.position = Vector2(r.position.x, base + 0.1)  # sorts just in front of the rack sprite
		add_child(led)
		for col in 18:    # the 18x7 LED panel at the top of the rack (matches the art)
			for row in 7:
				led.add_led(Vector2(1 + col * 4, top + 10 + row * 4),
						LED_COLORS[rng.randi() % LED_COLORS.size()], rng, Vector2i(i * 18 + col, row))
		for blade in 6:   # the server blades below it
			for j in 5:
				led.add_led(Vector2(8 + j * 6, top + 46 + blade * 17 + 5),
						LED_COLORS[rng.randi() % LED_COLORS.size()], rng)


func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		_show.trigger()  # F2: play the light show now (for testing)


func on_interact(h: Dictionary, verb: String, item: String) -> bool:
	match h["id"]:
		"console":
			if verb == "Use" and Game.too_sleepy("operate a terminal"):
				return true
			if verb == "Use" and item == "usb_stick":
				if Game.flag("usb_loaded"):
					Game.say("Already done: the deploy package is on the stick. Now take it to the CEO's terminal, upstairs in the CEO's office on the 3rd floor.")
				else:
					Game.set_flag("usb_loaded")
					Audio.play("combine")
					Game.say("You plug the stick in. Progress bar... 100%. The deploy package is on the stick. Now someone with authority has to sign off on it. The CEO's terminal, on the 3rd floor, would do.")
				return true
			if verb == "Use" and item == "":
				Audio.play("error")
				Game.say("The terminal says: INSERT AUTHORIZED MEDIA. Dale watches you, slowly.")
				return true
	return false
