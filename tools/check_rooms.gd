extends SceneTree
## Static checks on every room: sprite sizes vs click areas, missing art, walk points, exits and spawns.
## Run: godot --headless --path . -s tools/check_rooms.gd      (exit code 1 if there are errors)
## ERROR = probably a bug. NOTE = placeholder only (a coloured rectangle with no sprite yet).

var errors := 0
var notes := 0
var spawns := {}   # room id -> spawn names


func _init() -> void:
	await process_frame
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var rooms := {}
	for id in main.ROOMS:
		var r = main.ROOMS[id].new()
		root.add_child(r)
		rooms[id] = r
		spawns[id] = r.spawns.keys()
	await process_frame
	for id in rooms:
		check_room(id, rooms[id])
	print("CHECK ROOMS: %d error(s), %d note(s)" % [errors, notes])
	quit(1 if errors > 0 else 0)


func err(room: String, text: String) -> void:
	errors += 1
	print("ERROR %s: %s" % [room, text])


func note(room: String, text: String) -> void:
	notes += 1
	print("note  %s: %s" % [room, text])


func check_room(id: String, r) -> void:
	if not ResourceLoader.exists("res://assets/rooms/%s/background.png" % id):
		note(id, "no background.png")
	for h: Dictionary in r.hotspots:
		var hid: String = h["id"]
		var rect: Rect2 = h["rect"]
		if rect.position.x < 0 or rect.position.y < 0 or rect.end.x > 640 or rect.end.y > 288:
			err(id, "%s: click area %s is outside the 640x288 room" % [hid, rect])
		# Art: <id>.png and every <id>_<state>.png must be the size of the click area.
		var has_art := false
		for path in art_files(id, hid):
			has_art = true
			var tex: Texture2D = load(path)
			var skip: bool = (id == "lobby" and hid == "plant" and path.ends_with("_big.png"))
			if tex and not skip and Vector2(tex.get_size()) != rect.size:
				err(id, "%s: %s is %s but the click area is %s" % [hid, path.get_file(), tex.get_size(), rect.size])
		if not has_art and (h["color"] as Color).a > 0.0:
			note(id, "%s has no sprite (draws a coloured rectangle)" % hid)
		# Walking.
		var w: Vector2 = h["walk"]
		if not r._on_floor(w):
			err(id, "%s: walk-to point %s is off the floor" % [hid, w])
		elif r._in_obstacle(w):
			err(id, "%s: walk-to point %s is inside an obstacle" % [hid, w])
		var base: float = h.get("sort_y", rect.end.y)
		if w.y < base:
			err(id, "%s: walk-to y=%d is behind its sort_y=%d (the monkey would be hidden)" % [hid, w.y, base])
		# Exits.
		if h.has("exit"):
			var target: String = h["exit"][0]
			if not spawns.has(target):
				err(id, "%s: exit goes to unknown room '%s'" % [hid, target])
			elif not (h["exit"][1] in spawns[target]) and h["exit"][1] != "default":
				err(id, "%s: room '%s' has no spawn '%s'" % [hid, target, h["exit"][1]])
	# A later hotspot on top of an earlier one wins the click. If it covers part of an exit (a door), you can't
	# click that part: that is how the accounting door got stuck. Hidden hotspots don't count.
	for i in r.hotspots.size():
		var a: Dictionary = r.hotspots[i]
		if not a.has("exit") or a["hidden"]:
			continue
		for j in range(i + 1, r.hotspots.size()):
			var b: Dictionary = r.hotspots[j]
			if b["hidden"]:
				continue
			var cut: Rect2 = (a["rect"] as Rect2).intersection(b["rect"])
			if cut.get_area() > 0.0:
				err(id, "%s (exit) is partly covered by %s: %s" % [a["id"], b["id"], cut])
	# Small things sitting on bigger things (a phone on a table) must be drawn in FRONT of them. Things draw in order
	# of their "sort_y" (the bottom edge unless set), and an earlier-added one loses a tie. If the small one would be
	# drawn first, the big one covers it.
	for i in r.hotspots.size():
		for j in range(i + 1, r.hotspots.size()):
			var a: Dictionary = r.hotspots[i]
			var b: Dictionary = r.hotspots[j]
			if a["hidden"] or b["hidden"] or not _drawn(id, a) or not _drawn(id, b):
				continue
			var ra: Rect2 = a["rect"]
			var rb: Rect2 = b["rect"]
			var cut := ra.intersection(rb).get_area()
			if cut <= 0.0:
				continue
			var small: Dictionary = a if ra.get_area() <= rb.get_area() else b
			var big: Dictionary = b if small == a else a
			if cut < 0.5 * (small["rect"] as Rect2).get_area():
				continue  # only partly overlapping: not "sitting on"
			var s_small: float = small.get("sort_y", (small["rect"] as Rect2).end.y)
			var s_big: float = big.get("sort_y", (big["rect"] as Rect2).end.y)
			var small_first: bool = r.hotspots.find(small) < r.hotspots.find(big)
			if s_small < s_big or (is_equal_approx(s_small, s_big) and small_first):
				err(id, "%s sits on %s but is drawn behind it (sort_y %s vs %s): raise its sort_y" % [small["id"], big["id"], s_small, s_big])
	for name in r.spawns:
		var p: Vector2 = r.spawns[name]
		if not r._on_floor(p):
			err(id, "spawn '%s' %s is off the floor" % [name, p])
		elif r._in_obstacle(p):
			err(id, "spawn '%s' %s is inside an obstacle" % [name, p])


## Does this hotspot draw anything (a sprite or a coloured placeholder)? Look-only details don't.
func _drawn(room: String, h: Dictionary) -> bool:
	return (h["color"] as Color).a > 0.0 or not art_files(room, h["id"]).is_empty()


func art_files(room: String, hid: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open("res://assets/rooms/%s" % room)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.ends_with(".png") and (f == hid + ".png" or f.begins_with(hid + "_")):
			out.append("res://assets/rooms/%s/%s" % [room, f])
	return out
