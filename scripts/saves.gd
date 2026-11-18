extends RefCounted
## Save files: user://saves/slot_N.json (slot 0 = autosave, 1-3 = manual).

const DIR := "user://saves/"
const VERSION := 1
const SLOTS := [0, 1, 2, 3]
## The test scripts in tools/ set this so they never write to your real saves (they start games, which autosave).
static var disabled := false


static func path(slot: int) -> String:
	return "%sslot_%d.json" % [DIR, slot]


static func write(slot: int, data: Dictionary) -> bool:
	if disabled:
		return false
	DirAccess.make_dir_recursive_absolute(DIR)
	data["version"] = VERSION
	data["time"] = Time.get_unix_time_from_system()
	var f := FileAccess.open(path(slot), FileAccess.WRITE)
	if f == null:
		push_error("Could not write save slot %d" % slot)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true


## Returns {} if the slot is empty or unreadable.
static func read(slot: int) -> Dictionary:
	if not FileAccess.file_exists(path(slot)):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path(slot)))
	if typeof(parsed) != TYPE_DICTIONARY or parsed.get("version", 0) != VERSION or not parsed.has("room"):
		return {}
	return parsed


## The slot with the most recent save, or -1.
static func newest() -> int:
	var best := -1
	var best_time := -1.0
	for slot in SLOTS:
		var d := read(slot)
		if not d.is_empty() and d.get("time", 0.0) > best_time:
			best_time = d["time"]
			best = slot
	return best


static func describe(slot: int) -> String:
	var label := "Auto" if slot == 0 else str(slot)
	var d := read(slot)
	if d.is_empty():
		return "%s. - empty -" % label
	var when := Time.get_datetime_string_from_unix_time(int(d.get("time", 0)), true).substr(5, 11)
	return "%s. %s - %d min - %s" % [label, Game.ROOM_TITLES.get(d["room"], d["room"]),
			int(d.get("playtime", 0.0) / 60.0), when]
