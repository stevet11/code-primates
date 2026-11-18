extends CanvasLayer
## Title screen, pause menu (Esc) and the save / load slot lists.

const Saves := preload("res://scripts/saves.gd")
enum Mode { NONE, TITLE, PAUSE, SAVE, LOAD, OPTIONS, CREDITS, HELP, NOTES }

const HELP := """[Playing]
Pick a verb (Look, Use, Take, Talk), then click things. Click the floor to walk.
To use an item: pick Use, click it in your inventory, then click the target (or the monkey).
Click an item twice to put it away. Use one item on another to combine them.

[Save and load]
Esc opens the pause menu: Save Game, Load Game, Options, Quit to Title.
F5 quick saves to slot 1, F9 quick loads it. The game also autosaves when you change rooms.
On the title screen, Continue loads your newest save; Load Game lets you pick one.

[Keys]
1-4 pick a dialogue choice. Space, Enter or a click reads on. N shows your notes (the clues you found).
Esc closes menus."""

const CREDITS := """[Game]
%s - a low-res adventure
Made with Godot Engine 4 (MIT license)

[Music]
All music, the elevator jazz included, and all sound effects:
synthesized by tools/make_audio.py

[Font]
VT323, The VT323 Project Authors (Peter Hull), SIL Open Font License"""

var _mode := Mode.NONE
var _root: Control
var _backdrop: ColorRect
var _art: Control
var _heading: Label
var _shadow: Label
var _sub: Label
var _list: VBoxContainer
var _credits: Label
var _notes_from_key := false
var _scroll: ScrollContainer   # the notes list scrolls (mouse wheel, Up/Down, PageUp/PageDown)
var _notes_label: Label


func _ready() -> void:
	layer = 40
	_root = Control.new()
	_root.size = Vector2(640, 360)
	_root.visible = false
	_root.mouse_filter = Control.MOUSE_FILTER_STOP  # blocks clicks from reaching the game
	add_child(_root)
	_backdrop = ColorRect.new()
	_backdrop.size = Vector2(640, 360)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_backdrop)

	# Title-screen art: the office, dimmed, with the monkey and Dale.
	_art = Control.new()
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_art)
	if ResourceLoader.exists("res://assets/rooms/office/background.png"):
		var bg := TextureRect.new()
		bg.texture = load("res://assets/rooms/office/background.png")
		bg.modulate = Color(0.35, 0.35, 0.45)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_art.add_child(bg)
	_add_sprite("res://assets/characters/player.png", Rect2(0, 0, 48, 48), Vector2(16, 196), 3.0)
	_add_sprite("res://assets/rooms/server/dale.png", Rect2(0, 0, 64, 122), Vector2(500, 128), 1.75)   # Dale, hat and all (64x122)

	_shadow = _make_label(Color("1a1c2c"))
	_heading = _make_label(Color("ffcd75"))
	_sub = _make_label(Color("94b0c2"))
	_sub.text = "a low-res adventure"
	_sub.add_theme_font_size_override("font_size", 26)
	_sub.position = Vector2(0, 112)

	_credits = Label.new()
	_credits.position = Vector2(40, 66)
	_credits.size = Vector2(560, 240)
	_credits.add_theme_font_size_override("font_size", 16)
	_credits.add_theme_color_override("font_color", Color("c7cad6"))
	_credits.autowrap_mode = TextServer.AUTOWRAP_WORD
	_credits.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_credits.visible = false
	_root.add_child(_credits)

	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(40, 62)
	_scroll.size = Vector2(560, 248)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.visible = false
	_root.add_child(_scroll)
	_notes_label = Label.new()
	_notes_label.custom_minimum_size = Vector2(540, 0)
	_notes_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_notes_label.add_theme_font_size_override("font_size", 16)
	_notes_label.add_theme_color_override("font_color", Color("c7cad6"))
	_scroll.add_child(_notes_label)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_root.add_child(_list)


func _add_sprite(path: String, region: Rect2, pos: Vector2, zoom: float) -> void:
	if not ResourceLoader.exists(path):
		return
	var at := AtlasTexture.new()
	at.atlas = load(path)
	at.region = region
	var tr := TextureRect.new()
	tr.texture = at
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.size = region.size * zoom
	tr.position = pos
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.add_child(tr)


func _make_label(color: Color) -> Label:
	var l := Label.new()
	l.size = Vector2(640, 90)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(l)
	return l


func _layout(title_mode: bool, heading: String, list_x: float, list_w: float) -> void:
	_root.visible = true
	_credits.visible = false
	_scroll.visible = false
	Game.menu_open = true
	Game.busy = true
	_art.visible = title_mode
	_sub.visible = title_mode
	_shadow.visible = title_mode
	_backdrop.color = Color("1a1c2c") if title_mode else Color(0.04, 0.05, 0.09, 0.85)
	var size := 80 if title_mode else 44
	for l in [_heading, _shadow]:
		l.text = heading
		l.add_theme_font_size_override("font_size", size)
		l.position = Vector2(0, 26 if title_mode else 20)
	_shadow.position += Vector2(3, 4)
	_list.position = Vector2(list_x, 154 if title_mode else 84)
	_list.size = Vector2(list_w, 190)


func _set_buttons(items: Array, font_size: int = 28, height: int = 36, gap: int = 4) -> void:
	_list.add_theme_constant_override("separation", gap)
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var first: Button = null
	for it: Dictionary in items:
		var b := Button.new()
		b.text = it["text"]
		b.custom_minimum_size = Vector2(0, height)
		b.disabled = it.get("disabled", false)
		b.add_theme_font_size_override("font_size", font_size)
		b.add_theme_color_override("font_color", Color("f4f4f4"))
		b.add_theme_color_override("font_hover_color", Color("ffcd75"))
		b.add_theme_color_override("font_focus_color", Color("ffcd75"))
		b.add_theme_color_override("font_disabled_color", Color("566c86"))
		for state in ["normal", "pressed", "disabled", "hover", "focus", "hover_pressed"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color("333c57") if state in ["hover", "focus", "hover_pressed"] else Color(0, 0, 0, 0)
			sb.set_content_margin_all(2)
			b.add_theme_stylebox_override(state, sb)
		b.pressed.connect(func(): Audio.play("click"))
		b.pressed.connect(it["cb"])
		_list.add_child(b)
		if first == null and not b.disabled:
			first = b
	if first:
		first.grab_focus.call_deferred()


func show_title() -> void:
	_mode = Mode.TITLE
	Audio.play_music("title")
	_layout(true, Game.GAME_TITLE, 200, 240)
	_set_buttons([
		{"text": "New Game", "cb": _new_game},
		{"text": "Continue", "cb": _continue, "disabled": Saves.newest() < 0},
		{"text": "Load Game", "cb": show_slots.bind(false), "disabled": Saves.newest() < 0},   # greyed out: no saves yet
		{"text": "Help", "cb": show_help},
		{"text": "Options", "cb": show_options},
		{"text": "Quit", "cb": func(): get_tree().quit()},
	], 26, 30, 1)


func show_pause() -> void:
	_mode = Mode.PAUSE
	_layout(false, "PAUSED", 200, 240)
	_set_buttons([
		{"text": "Resume", "cb": _close},
		{"text": "Save Game", "cb": show_slots.bind(true)},
		{"text": "Load Game", "cb": show_slots.bind(false)},
		{"text": "Notes", "cb": show_notes.bind(false)},
		{"text": "Help", "cb": show_help},
		{"text": "Options", "cb": show_options},
		{"text": "Quit to Title", "cb": func(): _close(); get_parent().quit_to_title()},
	], 28, 32, 2)


func show_options() -> void:
	_mode = Mode.OPTIONS
	_layout(false, "OPTIONS", 160, 320)
	_set_buttons([
		{"text": "Music: " + ("On" if Audio.music_on else "Off"),
				"cb": func(): Audio.set_music(not Audio.music_on); show_options()},
		{"text": "Sound effects: " + ("On" if Audio.sfx_on else "Off"),
				"cb": func(): Audio.set_sfx(not Audio.sfx_on); show_options()},
		{"text": "Credits", "cb": show_credits},
		{"text": "Back", "cb": _back},
	])


## Clues the monkey has found. `from_key`: opened with N (Back then closes the menu instead of showing Pause).
func show_notes(from_key: bool = false) -> void:
	_mode = Mode.NOTES
	_notes_from_key = from_key
	_layout(false, "NOTES", 240, 160)
	var found := Game.notes_found()
	var lines: Array[String] = []
	for t in found:
		lines.append("- " + t)
	if found.size() <= 1:
		lines.append("")
		lines.append("(Nothing else yet. Look around, talk to people, and try things.)")
	_notes_label.text = "\n\n".join(lines)
	_scroll.scroll_vertical = 0
	_scroll.visible = true
	_list.position = Vector2(240, 318)
	_set_buttons([{"text": "Back", "cb": _notes_back}])


func _notes_back() -> void:
	if _notes_from_key:
		_close()
	else:
		show_pause()


func show_help() -> void:
	_mode = Mode.HELP
	_layout(false, "HELP", 240, 160)
	_credits.text = HELP
	_credits.add_theme_font_size_override("font_size", 15)  # a lot of text: a bit smaller than the credits
	_credits.position.y = 62
	_credits.visible = true
	_list.position = Vector2(240, 318)
	_set_buttons([{"text": "Back", "cb": _back}])


func show_credits() -> void:
	_mode = Mode.CREDITS
	_layout(false, "CREDITS", 240, 160)
	_credits.text = CREDITS % Game.GAME_TITLE
	_credits.add_theme_font_size_override("font_size", 16)
	_credits.position.y = 66
	_credits.visible = true
	_list.position = Vector2(240, 316)
	_set_buttons([{"text": "Back", "cb": show_options}])


func show_slots(saving: bool) -> void:
	_mode = Mode.SAVE if saving else Mode.LOAD
	_layout(false, "SAVE GAME" if saving else "LOAD GAME", 90, 460)
	var rows: Array = []
	for slot in Saves.SLOTS:
		if saving and slot == 0:
			continue  # the autosave slot is written by the game
		var empty := Saves.read(slot).is_empty()
		rows.append({"text": Saves.describe(slot), "disabled": (not saving) and empty,
				"cb": _pick_slot.bind(slot)})
	rows.append({"text": "Back", "cb": _back})
	_set_buttons(rows, 22)


func _pick_slot(slot: int) -> void:
	if _mode == Mode.SAVE:
		if get_parent().save_slot(slot):
			_close()
			Audio.play("save")
			Game.say("Game saved (slot %d)." % slot)
	elif get_parent().load_slot(slot):
		_close()


func _back() -> void:
	if Game.in_game:
		show_pause()
	else:
		show_title()


func _new_game() -> void:
	_close()
	get_parent().start_new_game()


func _continue() -> void:
	var slot := Saves.newest()
	if slot >= 0 and get_parent().load_slot(slot):
		_close()


func _close() -> void:
	_mode = Mode.NONE
	_root.visible = false
	Game.menu_open = false
	Game.busy = false


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match _mode:
		Mode.NONE:
			if not Game.in_game or Game.busy or Game.ended:
				return
			if event.keycode == KEY_ESCAPE:
				show_pause()
			elif event.keycode == KEY_N:  # the notes
				show_notes(true)
			elif event.keycode == KEY_F5:  # quick save to slot 1
				if get_parent().save_slot(1):
					Game.say("Quick saved (slot 1).")
			elif event.keycode == KEY_F9:  # quick load from slot 1
				if not get_parent().load_slot(1):
					Game.say("No quick save in slot 1.")
			else:
				return
			get_viewport().set_input_as_handled()
		Mode.PAUSE:
			if event.keycode == KEY_ESCAPE:
				_close()
				get_viewport().set_input_as_handled()
		Mode.HELP:
			if event.keycode == KEY_ESCAPE:
				_back()
				get_viewport().set_input_as_handled()
		Mode.NOTES:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_N:
				_notes_back()
				get_viewport().set_input_as_handled()
			elif event.keycode in [KEY_UP, KEY_DOWN, KEY_PAGEUP, KEY_PAGEDOWN]:
				var step := 24 if event.keycode in [KEY_UP, KEY_DOWN] else 200
				_scroll.scroll_vertical += -step if event.keycode in [KEY_UP, KEY_PAGEUP] else step
				get_viewport().set_input_as_handled()
		Mode.CREDITS:
			if event.keycode == KEY_ESCAPE:
				show_options()
				get_viewport().set_input_as_handled()
		Mode.SAVE, Mode.LOAD, Mode.OPTIONS:
			if event.keycode == KEY_ESCAPE:
				_back()
				get_viewport().set_input_as_handled()
