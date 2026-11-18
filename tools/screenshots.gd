extends SceneTree
## Takes the README screenshots into docs/screenshots/. Needs a display (it opens a window for a few seconds):
##   godot --path . -s tools/screenshots.gd
## It never writes saves. Shots are chosen to show off the look of the game without giving puzzles away.

const OUT := "res://docs/screenshots/"
var main
var G


func _init() -> void:
	await process_frame
	load("res://scripts/saves.gd").disabled = true
	G = root.get_node("Game")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(5)
	await shot("title")
	main.menu._close()          # hide the title screen, like pressing New Game
	main.start_new_game()
	await frames(8)
	await shot("office")
	await goto("elevator", Vector2(300, 244))
	await shot("elevator")
	await goto("breakroom", Vector2(300, 244))
	await shot("breakroom")
	await goto("lobby", Vector2(250, 244))
	await shot("lobby")
	await goto("server", Vector2(300, 244), 1.0)
	await shot("server")
	G.playtime = 41.0
	await goto("accounting", Vector2(300, 250))
	await shot("accounting")
	quit()


func frames(n: int) -> void:
	for i in n:
		await process_frame


func goto(room: String, pos: Vector2, extra_wait: float = 0.3) -> void:
	main._change_room(room, "default")
	await frames(4)
	main.current.player.position = pos
	await get_root_timer(extra_wait)
	await frames(4)


func get_root_timer(sec: float) -> void:
	await create_timer(sec).timeout


## Saves the viewport as a crisp 1280x720 PNG (the game draws at 640x360).
func shot(shot_name: String) -> void:
	await frames(3)
	var img: Image = root.get_viewport().get_texture().get_image()
	if img.get_width() != 1280:
		img.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	var path := ProjectSettings.globalize_path(OUT + shot_name + ".png")
	var err := img.save_png(path)
	print("%s: %s (%dx%d) err=%d" % [shot_name, path, img.get_width(), img.get_height(), err])
