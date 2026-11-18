extends "res://scripts/room.gd"
## The elevator, shared by every floor. The current floor is kept in Game.flags["floor"] (saved).

const FLOORS := ["B", "G", "2", "3"]  # bottom to top
const FLOOR_ROOMS := {"B": "basement", "G": "lobby", "2": "hallway", "3": "floor3"}
const FLOOR_LABELS := {"B": "Basement", "G": "Ground Floor", "2": "2nd Floor", "3": "3rd Floor"}  # hover names
const FLOOR_NAMES := {"B": "the basement", "G": "the ground floor", "2": "the 2nd floor", "3": "the 3rd floor"}
const WALL := 120.0    # side walls: the car is the space between x=120 and x=520
const PANEL_X := 150.0
const STRIP := 9  # lights in the moving strip
const FONT := preload("res://assets/fonts/VT323.ttf")

var _panel: Node2D
var _has_plate := false
var _strip := -1   # lit strip index while moving, -1 when idle
var _moving := false


## Panel position of a floor's button: the highest floor is at the top, the basement at the bottom.
static func _button_rect(i: int) -> Rect2:
	return Rect2(PANEL_X + 12, 60 + (FLOORS.size() - 1 - i) * 36, 36, 30)


static func current_floor() -> String:
	return str(Game.flags.get("floor", "2"))


func _setup() -> void:
	room_id = "elevator"
	wall_color = Color("6b6f80")
	floor_color = Color("3a3d4d")
	horizon_y = 192.0
	walk_poly = PackedVector2Array([Vector2(132, 200), Vector2(508, 200), Vector2(516, 284), Vector2(124, 284)])
	spawns = {"default": Vector2(320, 240)}
	for i in FLOORS.size():
		var f: String = FLOORS[i]
		add_hotspot("btn_" + f, FLOOR_LABELS[f], _button_rect(i), Vector2(PANEL_X + 40, 215),
				"The button for %s." % FLOOR_NAMES[f], Color.TRANSPARENT, {"sort_y": horizon_y})
	add_hotspot("nosmoking", "No smoking sign", Rect2(268, 70, 44, 44), Vector2(290, 215),
			"NO SMOKING. A cigarette with a red slash through it. The monkey wasn't planning to.",
			Color("f4f4f4"), {"sort_y": horizon_y})
	add_hotspot("firesign", "Fire sign", Rect2(330, 70, 70, 54), Vector2(365, 215),
			"DO NOT USE IN CASE OF FIRE. Then how do you get out of the building? The sign doesn't say.",
			Color("ffcd75"), {"sort_y": horizon_y})
	add_hotspot("door", "Elevator door", Rect2(414, 72, 80, 120), Vector2(454, 206),
			"The doors to %s." % FLOOR_NAMES[current_floor()], Color("a8abb8"),
			{"exit": [FLOOR_ROOMS[current_floor()], "from_elevator"], "sort_y": horizon_y})


func _after_art() -> void:
	auto_doors = ["door"]
	# The panel plate (assets/rooms/elevator/panel.png, 100x158) is a Sprite2D added just before the overlay that
	# draws the buttons and lights, so it sits under them. (draw_texture() drew it as a plain white box.)
	var plate := _load_tex("panel")
	_has_plate = plate != null
	if plate:
		var spr := Sprite2D.new()
		spr.texture = plate
		spr.centered = false
		spr.position = Vector2(PANEL_X - 12, horizon_y)
		spr.offset = Vector2(0, 44 - horizon_y)
		add_child(spr)
	_panel = Node2D.new()
	_panel.position = Vector2(0, horizon_y)  # y-sorts like a wall object: the monkey draws in front
	_panel.draw.connect(_draw_panel)
	add_child(_panel)


func _draw_panel() -> void:
	_panel.draw_set_transform(Vector2(0, -horizon_y))
	# Side walls close the car in to a small room.
	for x in [0.0, 640.0 - WALL]:
		_panel.draw_rect(Rect2(x, 0, WALL, FLOOR_BOTTOM), Color("3d4050"))
	_panel.draw_rect(Rect2(WALL - 4, 0, 4, FLOOR_BOTTOM), Color("22242f"))
	_panel.draw_rect(Rect2(640.0 - WALL, 0, 4, FLOOR_BOTTOM), Color("22242f"))
	if not _has_plate:  # no panel.png: plain rectangles (the plate sprite is added in _after_art)
		_panel.draw_rect(Rect2(PANEL_X - 12, 44, 100, 158), Color("2b2d3a"))
		_panel.draw_rect(Rect2(PANEL_X - 12, 44, 100, 158), Color("141521"), false, 2.0)
	for i in FLOORS.size():
		var f: String = FLOORS[i]
		var lit: bool = f == current_floor() and not _moving
		var r := _button_rect(i)
		_panel.draw_rect(r, Color("ffcd75") if lit else Color("575a6e"))
		_panel.draw_string(FONT, r.position + Vector2(10, 22), f, HORIZONTAL_ALIGNMENT_LEFT, -1, 24,
				Color("1a1c2c") if lit else Color("c7cad6"))
	# Moving lights, like a starship console.
	for i in STRIP:
		var lit := _strip >= 0 and (i == _strip or i == _strip - 1 or i == _strip + 1)
		var bright := _strip >= 0 and i == _strip
		var c := Color("41a6f6") if lit else Color("23253a")
		if bright:
			c = Color("a7f0ff")
		_panel.draw_rect(Rect2(PANEL_X + 54, 60 + i * 15, 24, 10), c)


func _doors_enabled() -> bool:
	return not _moving


func on_interact(h: Dictionary, verb: String, _item: String) -> bool:
	if not str(h["id"]).begins_with("btn_"):
		return false
	if verb == "Look":
		return false
	var target: String = str(h["id"]).substr(4)
	if target == current_floor():
		Game.say("You're already on %s." % FLOOR_NAMES[target])
		return true
	await _travel(target)
	return true


func _travel(target: String) -> void:
	var from_i: int = FLOORS.find(current_floor())
	var to_i: int = FLOORS.find(target)
	var up: bool = to_i > from_i
	Game.busy = true
	_moving = true
	Audio.play("door")
	Game.say("The doors close. The elevator hums %s." % ("upward" if up else "downward"))
	# The lights travel opposite to the car, like the floor passing by. Strip index 0 is the top.
	var steps := 14 * absi(to_i - from_i) + 6
	for s in steps:
		var phase := s % STRIP
		_strip = phase if up else (STRIP - 1 - phase)
		_panel.queue_redraw()
		if s % 3 == 0:
			Audio.play("blip", 0.8 + 0.02 * s, -14.0)
		await get_tree().create_timer(0.09).timeout
	_strip = -1
	_moving = false
	Game.flags["floor"] = target
	var door := get_hotspot("door")
	door["exit"] = [FLOOR_ROOMS[target], "from_elevator"]
	door["look"] = "The doors to %s." % FLOOR_NAMES[target]
	_panel.queue_redraw()
	Audio.play("beep", 1.4)
	Game.say("Ding! You've arrived at %s." % FLOOR_NAMES[target])
	Game.busy = false
