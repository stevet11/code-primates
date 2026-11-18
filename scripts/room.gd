extends Node2D
const PlayerScript := preload("res://scripts/player.gd")
## Base class for a room. Subclasses override _setup() and on_interact().
## Room area is 320x144; the bottom 36px of the 320x180 screen is the UI.

const FLOOR_BOTTOM := 288.0
const ART_DIR := "res://assets/rooms/"

var room_id := ""
var wall_color := Color("5d275d")
var floor_color := Color("29366f")
var horizon_y := 192.0  # where the wall meets the floor
var walk_poly := PackedVector2Array()  # keep convex
## Blocked floor footprints (convex), e.g. under a desk. The player walks around them.
## They may extend above the floor; only the part on the floor matters.
var obstacles: Array[PackedVector2Array] = []
const AVOID_MARGIN := 5.0
var spawns := {"default": Vector2(320, 240)}
var entry := "default"
var hotspots: Array[Dictionary] = []
var player
var debug_overlay := false
var _has_bg := false
var _debug: Node2D


func _ready() -> void:
	y_sort_enabled = true  # children sort by their y: things lower on screen draw in front
	_setup()
	_build_art()
	_after_art()
	player = PlayerScript.new()
	player.room = self
	player.position = spawns.get(entry, spawns["default"])
	add_child(player)


## Override: set colors, walk_poly, spawns, and call add_hotspot().
func _setup() -> void:
	pass


## Override: runs after the art is built (add animated extras here).
func _after_art() -> void:
	pass


## Override: return true if you handled the interaction.
## May contain `await` (e.g. await Game.talk("id")).
func on_interact(_h: Dictionary, _verb: String, _item: String) -> bool:
	return false


func add_hotspot(id: String, label: String, rect: Rect2, walk: Vector2, look: String,
		color: Color = Color.TRANSPARENT, extra: Dictionary = {}) -> void:
	var h := {"id": id, "name": label, "rect": rect, "walk": walk,
			"look": look, "color": color, "hidden": false,
			"state": "", "sprite": null, "has_art": false}
	h.merge(extra, true)
	hotspots.append(h)


## Art lookup: res://assets/rooms/<room_id>/<name>.png (optional, falls back to rectangles).
func _load_tex(art_name: String) -> Texture2D:
	var path := "%s%s/%s.png" % [ART_DIR, room_id, art_name]
	return load(path) if ResourceLoader.exists(path) else null


func _build_art() -> void:
	var bg := _load_tex("background")
	if bg:
		_has_bg = true
		var b := Sprite2D.new()
		b.texture = bg
		b.centered = false
		b.z_index = -100
		add_child(b)
	# Hotspot sprites: image top-left sits on the hotspot rect's top-left.
	# They sort against the player by "sort_y" (default: bottom of the rect).
	for h in hotspots:
		var spr := Sprite2D.new()
		spr.centered = false
		var r: Rect2 = h["rect"]
		var base: float = h.get("sort_y", r.end.y)
		spr.position = Vector2(r.position.x, base)
		spr.offset = Vector2(0, r.position.y - base)
		add_child(spr)
		h["sprite"] = spr
		if h["walk"].y < base:
			push_warning("Room '%s': hotspot '%s' walk-to y=%d is behind its sort_y=%d; the player will be hidden behind it"
					% [room_id, h["id"], h["walk"].y, base])
	# Optional foreground layer: always draws over the player.
	var fg := _load_tex("foreground")
	if fg:
		var f := Sprite2D.new()
		f.texture = fg
		f.centered = false
		f.position = Vector2(0, FLOOR_BOTTOM + 10)
		f.offset = Vector2(0, -(FLOOR_BOTTOM + 10))
		add_child(f)
	_debug = Node2D.new()
	_debug.z_index = 200
	_debug.draw.connect(_draw_debug)
	add_child(_debug)
	_sync_art()


## Picks <id>.png, or <id>_<state>.png when the hotspot has a state (e.g. "open").
func _sync_art() -> void:
	for h in hotspots:
		var spr: Sprite2D = h["sprite"]
		# The click area can change (the giant plant): keep the sprite on it.
		var r: Rect2 = h["rect"]
		var base: float = h.get("sort_y", r.end.y)
		spr.position = Vector2(r.position.x, base)
		spr.offset = Vector2(0, r.position.y - base)
		var state: String = h["state"]
		var tex: Texture2D = null
		if state != "":
			tex = _load_tex("%s_%s" % [h["id"], state])
		if tex == null:
			tex = _load_tex(h["id"])
		spr.texture = tex
		spr.visible = tex != null and not h["hidden"]
		h["has_art"] = tex != null


func _draw_debug() -> void:
	if not debug_overlay:
		return
	for h in hotspots:
		if not h["hidden"]:
			_debug.draw_rect(h["rect"], Color(1, 1, 0, 0.9), false, 1.0)
			_debug.draw_circle(h["walk"], 3.0, Color(0, 1, 1, 0.9))
	if walk_poly.size() > 2:
		_debug.draw_polyline(walk_poly + PackedVector2Array([walk_poly[0]]), Color(0, 1, 0, 0.9), 1.0)
	for o in obstacles:
		_debug.draw_polyline(o + PackedVector2Array([o[0]]), Color(1, 0.2, 0.2, 0.9), 1.0)


func get_hotspot(id: String) -> Dictionary:
	for h in hotspots:
		if h["id"] == id:
			return h
	return {}


func depth_scale(y: float) -> float:
	var t := clampf((y - horizon_y) / (FLOOR_BOTTOM - horizon_y), 0.0, 1.0)
	return lerpf(0.55, 1.0, t)


func _inflated(o: PackedVector2Array) -> PackedVector2Array:
	var res := Geometry2D.offset_polygon(o, AVOID_MARGIN, Geometry2D.JOIN_MITER)
	return res[0] if res.size() > 0 else o


func _on_floor(p: Vector2) -> bool:
	return walk_poly.size() < 3 or Geometry2D.is_point_in_polygon(p, walk_poly)


func _in_obstacle(p: Vector2) -> bool:
	for o in obstacles:
		if Geometry2D.is_point_in_polygon(p, o):
			return true
	return false


func _segment_clear(a: Vector2, b: Vector2) -> bool:
	for o in obstacles:
		for i in o.size():
			if Geometry2D.segment_intersects_segment(a, b, o[i], o[(i + 1) % o.size()]) != null:
				return false
		if Geometry2D.is_point_in_polygon((a + b) * 0.5, o):
			return false
	return true


## If p is inside an obstacle, the nearest spot just outside it (and on the floor).
func _push_out(p: Vector2) -> Vector2:
	for o in obstacles:
		if not Geometry2D.is_point_in_polygon(p, o):
			continue
		var inf := _inflated(o)
		var best := p
		var best_d := INF
		for i in inf.size():
			var c := Geometry2D.get_closest_point_to_segment(p, inf[i], inf[(i + 1) % inf.size()])
			if _on_floor(c) and p.distance_squared_to(c) < best_d:
				best_d = p.distance_squared_to(c)
				best = c
		return best
	return p


## Waypoints from `from` to `to` (clamped to the floor), going around obstacles.
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	to = _push_out(clamp_to_floor(to))
	if obstacles.is_empty() or _segment_clear(from, to):
		return PackedVector2Array([from, to])
	var pts: Array[Vector2] = [from, to]
	for o in obstacles:
		for v in _inflated(o):
			if _on_floor(v) and not _in_obstacle(v):
				pts.append(v)
	var astar := AStar2D.new()
	for i in pts.size():
		astar.add_point(i, pts[i])
	for i in pts.size():
		for j in range(i + 1, pts.size()):
			if _segment_clear(pts[i], pts[j]):
				astar.connect_points(i, j)
	var path := astar.get_point_path(0, 1)
	return path if path.size() >= 2 else PackedVector2Array([from, to])


func clamp_to_floor(p: Vector2) -> Vector2:
	if walk_poly.size() < 3 or Geometry2D.is_point_in_polygon(p, walk_poly):
		return p
	var best := p
	var best_d := INF
	for i in walk_poly.size():
		var c := Geometry2D.get_closest_point_to_segment(
				p, walk_poly[i], walk_poly[(i + 1) % walk_poly.size()])
		var d := p.distance_squared_to(c)
		if d < best_d:
			best_d = d
			best = c
	return best


func _hotspot_at(p: Vector2) -> Dictionary:
	for i in range(hotspots.size() - 1, -1, -1):
		var h := hotspots[i]
		if not h["hidden"] and (h["rect"] as Rect2).has_point(p):
			return h
	return {}


func _process(_delta: float) -> void:
	var mp := get_global_mouse_position()
	var h := _hotspot_at(mp)
	Game.hover_name = h.get("name", "") if mp.y < FLOOR_BOTTOM and not Game.busy else ""
	if Game.held_item != "" and not Game.busy and player != null and _on_player(mp):
		Game.hover_name = "Monkey"  # so the action line reads e.g. "Use Mug of coffee on Monkey"
	_update_auto_doors()


## Hotspot ids in `auto_doors` slide open (with a sound) when the monkey is close, and shut again
## when they walk away. Draws <id>_open.png if it exists. Override _doors_enabled() to hold them shut.
var auto_doors: Array[String] = []
const DOOR_RANGE := 110.0


func _doors_enabled() -> bool:
	return true


func _update_auto_doors() -> void:
	if player == null or auto_doors.is_empty():
		return
	for id in auto_doors:
		var d := get_hotspot(id)
		if d.is_empty():
			continue
		if not d.has("closed_color"):
			d["closed_color"] = d["color"]
		var near: bool = _doors_enabled() and player.position.distance_to(d["walk"]) < DOOR_RANGE
		if near != (d["state"] == "open"):
			d["state"] = "open" if near else ""
			d["color"] = Color("1a1c2c") if near else d["closed_color"]
			Audio.play("slide_open" if near else "slide_close", 1.0, -6.0)
			_sync_art()
			queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		debug_overlay = not debug_overlay  # F1: show hotspots and walkable floor
		_debug.queue_redraw()
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		if p.y >= FLOOR_BOTTOM or Game.busy:
			return
		get_viewport().set_input_as_handled()
		if Game.held_item != "" and _on_player(p):
			Game.use_on_monkey(Game.held_item)  # coffee: he drinks it. Water: he refuses.
			Game.set_verb("Look")
			return
		var h := _hotspot_at(p)
		if h.is_empty():
			Audio.play("click", 1.3, -8.0)
			player.walk_to(p)
		else:
			_activate(h)


func _on_player(p: Vector2) -> bool:
	var sc: float = depth_scale(player.position.y)
	return Rect2(player.position + Vector2(-18, -54) * sc, Vector2(36, 56) * sc).has_point(p)


func _activate(h: Dictionary) -> void:
	Audio.play("click", 1.0, -6.0)
	var verb := Game.verb
	var item := Game.held_item
	var arrived: bool = await player.walk_to(h["walk"])
	if not arrived:
		return
	if h.has("exit") and verb != "Look":
		Game.room_change_requested.emit(h["exit"][0], h["exit"][1])
		return
	# Hotspots with {"talk": "<dialogue id>"} start that conversation on Talk.
	if verb == "Talk" and h.has("talk"):
		await Game.talk(h["talk"])
	else:
		var handled: bool = await on_interact(h, verb, item)
		if not handled:
			_default_response(h, verb, item)
	if item != "":
		Game.set_verb("Look")
	_sync_art()
	queue_redraw()


func _default_response(h: Dictionary, verb: String, item: String) -> void:
	if verb != "Look":
		Audio.play("error", 1.0, -4.0)
	match verb:
		"Look": Game.say(h["look"])
		"Take": Game.say("I can't take that.")
		"Talk": Game.say("It has nothing to say.")
		"Use":
			Game.say("That doesn't work." if item != "" else "I can't use that.")


func _draw() -> void:
	# Placeholder rectangles, used only where no art exists yet.
	if not _has_bg:
		draw_rect(Rect2(0, 0, 640, horizon_y), wall_color)
		draw_rect(Rect2(0, horizon_y, 640, FLOOR_BOTTOM - horizon_y), floor_color)
		draw_rect(Rect2(0, horizon_y - 4, 640, 4), wall_color.darkened(0.4))
	for h in hotspots:
		if not h["hidden"] and not h["has_art"] and (h["color"] as Color).a > 0.0:
			draw_rect(h["rect"], h["color"])
