extends Node

const Saves := preload("res://scripts/saves.gd")
const ROOMS := {
	"office": preload("res://scripts/rooms/office.gd"),
	"hallway": preload("res://scripts/rooms/hallway.gd"),
	"server": preload("res://scripts/rooms/server.gd"),
	"elevator": preload("res://scripts/rooms/elevator.gd"),
	"basement": preload("res://scripts/rooms/basement.gd"),
	"breakroom": preload("res://scripts/rooms/breakroom.gd"),
	"accounting": preload("res://scripts/rooms/accounting.gd"),
	"conference": preload("res://scripts/rooms/conference.gd"),
	"boss": preload("res://scripts/rooms/boss.gd"),
	"vp": preload("res://scripts/rooms/vp.gd"),
	"ceo": preload("res://scripts/rooms/ceo.gd"),
	"itlab": preload("res://scripts/rooms/itlab.gd"),
	"closet": preload("res://scripts/rooms/closet.gd"),
	"itmgr": preload("res://scripts/rooms/itmgr.gd"),
	"lobby": preload("res://scripts/rooms/lobby.gd"),
	"floor3": preload("res://scripts/rooms/floor3.gd"),
}

var current
var menu


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)  # closing the window goes through Audio.quit_game(), see _notification
	add_child(preload("res://scripts/ui.gd").new())
	add_child(preload("res://scripts/dialogue_ui.gd").new())
	menu = preload("res://scripts/menu_ui.gd").new()
	add_child(menu)
	Game.room_change_requested.connect(_change_room, CONNECT_DEFERRED)
	Game.title_requested.connect(quit_to_title)
	menu.show_title()  # also starts the title music


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Audio.quit_game()


func start_new_game() -> void:
	Game.reset()
	Game.in_game = true
	_change_room("office", "default")


func quit_to_title() -> void:
	_clear_room()
	Audio.play_ambience("")
	Game.reset()
	Game.in_game = false
	menu.show_title()


## Returns false if the slot is empty or broken.
func load_slot(slot: int) -> bool:
	var d := Saves.read(slot)
	if d.is_empty() or not ROOMS.has(d["room"]):
		return false
	Game.reset()
	Game.flags = d.get("flags", {})
	for id in d.get("inventory", []):
		if Game.ITEMS.has(id):
			Game.inventory.append(id)
	Game.inventory_changed.emit()
	Game.playtime = d.get("playtime", 0.0)
	Game.in_game = true
	var p: Array = d.get("pos", [320, 240])
	_change_room(d["room"], "default", Vector2(p[0], p[1]), false)
	_loaded_feedback(slot)
	return true


## So you can tell a load happened: a fade up from black, a chime, and a message.
func _loaded_feedback(slot: int) -> void:
	Audio.play("save", 1.3)
	Game.say("Autosave loaded." if slot == 0 else "Game loaded (slot %d)." % slot)
	var layer := CanvasLayer.new()
	layer.layer = 35
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.size = Vector2(640, 360)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	add_child(layer)
	var t := create_tween()
	t.tween_property(black, "color:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(layer.queue_free)


func save_slot(slot: int) -> bool:
	if current == null:
		return false
	return Saves.write(slot, {
		"room": current.room_id,
		"pos": [current.player.position.x, current.player.position.y],
		"inventory": Array(Game.inventory),
		"flags": Game.flags,
		"playtime": Game.playtime,
	})


func _clear_room() -> void:
	if current:
		remove_child(current)
		current.queue_free()
		current = null


func _change_room(id: String, spawn: String, pos: Vector2 = Vector2.INF, autosave: bool = true) -> void:
	var was_in_room: bool = current != null
	_clear_room()
	if autosave and was_in_room:
		Audio.play("door")
	Audio.play_music(Audio.ROOM_MUSIC.get(id, "explore"))
	Audio.play_ambience(Audio.ROOM_AMBIENCE.get(id, ""))
	current = ROOMS[id].new()
	current.entry = spawn
	add_child(current)
	if pos != Vector2.INF:
		current.player.position = pos
	if autosave and Game.in_game:
		save_slot(0)
