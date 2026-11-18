extends CanvasLayer
## Plays dialogue scripts: lines appear over the top of the room with a typewriter
## effect (click / Space / Enter to advance); choices replace the bottom bar.

const Parser := preload("res://scripts/dialogue_parser.gd")
const DIR := "res://assets/dialogue/"
const CHARS_PER_SEC := 60.0
const TEXT_SIZE := 26
const CHOICE_SIZE := 20
const BLIP_PITCH := {"Monkey": 1.0, "Dale": 0.45, "Vending Machine": 1.7, "Poster": 1.3}  # text blip per speaker
const SPEAKER_COLORS := {"Monkey": "ffcd75", "Vending Machine": "ef7d57", "Poster": "73eff7", "Dale": "a7f070"}

signal _advance
signal _chosen(index: int)

enum State { IDLE, TYPING, WAITING, CHOOSING }
var _state := State.IDLE
var _strip: ColorRect
var _name: Label
var _text: Label
var _more: ColorRect
var _choice_panel: ColorRect
var _choice_buttons: Array[Button] = []
var _typed := 0.0
var _blips := 0
var _speaker := ""
var _t := 0.0


func _ready() -> void:
	layer = 11
	Game.dialogue_ui = self

	_strip = ColorRect.new()
	_strip.color = Color(0.1, 0.11, 0.17, 0.9)
	_strip.size = Vector2(640, 80)
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strip.visible = false
	add_child(_strip)
	_name = _make_label(Vector2(8, 2), Vector2(624, 24))
	_strip.add_child(_name)
	_text = _make_label(Vector2(8, 26), Vector2(624, 60))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_constant_override("line_spacing", 0)
	_text.add_theme_color_override("font_color", Color("f4f4f4"))
	_strip.add_child(_text)
	_more = ColorRect.new()
	_more.color = Color("ffcd75")
	_more.position = Vector2(620, 78)
	_more.size = Vector2(8, 8)
	_more.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strip.add_child(_more)

	_choice_panel = ColorRect.new()
	_choice_panel.color = Color("1a1c2c")
	_choice_panel.position = Vector2(0, 288)
	_choice_panel.size = Vector2(640, 72)
	_choice_panel.visible = false
	add_child(_choice_panel)
	for i in 4:
		var b := Button.new()
		b.position = Vector2(4, i * 18 - 3)
		b.size = Vector2(632, 18)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.clip_text = true
		b.add_theme_font_size_override("font_size", CHOICE_SIZE)
		b.add_theme_color_override("font_color", Color("f4f4f4"))
		b.add_theme_color_override("font_hover_color", Color("ffcd75"))
		for state in ["normal", "hover", "pressed", "focus"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color("333c57") if state == "hover" else Color(0, 0, 0, 0)
			sb.set_content_margin_all(0)
			sb.content_margin_left = 4
			b.add_theme_stylebox_override(state, sb)
		b.pressed.connect(func(): _chosen.emit(i))
		_choice_panel.add_child(b)
		_choice_buttons.append(b)


func _make_label(pos: Vector2, size: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", TEXT_SIZE)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Plays dialogue <id> (assets/dialogue/<id>.txt) and returns when it ends.
func run(id: String) -> void:
	var path := "%s%s.txt" % [DIR, id]
	if not FileAccess.file_exists(path):
		push_error("No dialogue file: " + path)
		return
	var nodes := Parser.parse(id, FileAccess.get_file_as_string(path))
	if not nodes.has("start"):
		push_error("Dialogue %s has no '== start' node" % id)
		return
	Game.busy = true
	var cur := "start"
	var hops := 0
	while cur != "end" and hops < 500:
		hops += 1
		if not nodes.has(cur):
			push_error("Dialogue %s: no node '%s'" % [id, cur])
			break
		var next := ""
		var choices: Array[Dictionary] = []
		for it: Dictionary in nodes[cur]:
			if it["type"] == "say":
				await _say(it["speaker"], it["text"])
			elif it["type"] == "cmd":
				_command(it["cmd"], it["arg"])
			elif it["type"] == "goto":
				if _conds_ok(it["conds"]):
					next = it["target"]
					break
			elif it["type"] == "choice":
				if _conds_ok(it["conds"]) and not (it["once"] and Game.flag(it["key"])):
					choices.append(it)
		if next == "" and not choices.is_empty():
			var picked := await _choose(choices)
			if picked["once"]:
				Game.set_flag(picked["key"])
			await _say("Monkey", picked["text"])
			next = picked["target"]
		elif next == "":
			next = "end"
		cur = next
	_strip.visible = false
	_state = State.IDLE
	Game.busy = false


func _say(speaker: String, text: String) -> void:
	_strip.visible = true
	_name.text = speaker
	_name.add_theme_color_override("font_color", Color(SPEAKER_COLORS.get(speaker, "f4f4f4")))
	_text.text = text
	# Size the strip to fit the wrapped text.
	var text_h := _text.get_theme_font("font").get_multiline_string_size(
			text, HORIZONTAL_ALIGNMENT_LEFT, 624, TEXT_SIZE).y
	_strip.size.y = 26.0 + text_h + 10.0
	_more.position.y = _strip.size.y - 14.0
	_text.visible_characters = 0
	_typed = 0.0
	_blips = 0
	_speaker = speaker
	_state = State.TYPING
	await _advance
	_state = State.IDLE


func _choose(choices: Array[Dictionary]) -> Dictionary:
	_strip.visible = false
	for i in _choice_buttons.size():
		var b := _choice_buttons[i]
		b.visible = i < choices.size()
		if i < choices.size():
			b.text = "%d. %s" % [i + 1, choices[i]["text"]]
	if choices.size() > _choice_buttons.size():
		push_warning("More than 4 choices; extra ones are hidden")
	_choice_panel.visible = true
	_state = State.CHOOSING
	var idx: int = await _chosen
	_choice_panel.visible = false
	_state = State.IDLE
	return choices[idx]


func _command(cmd: String, arg: String) -> void:
	match cmd:
		"set": Game.set_flag(arg)
		"clear": Game.set_flag(arg, false)
		"give": Game.add_item(arg)
		"take": Game.remove_item(arg)
		_: push_error("Unknown dialogue command: " + cmd)


func _conds_ok(conds: Array) -> bool:
	for c in conds:
		var cond: String = c
		var negate := cond.begins_with("!")
		var name := cond.trim_prefix("!").strip_edges()
		var value: bool = Game.has_item(name.substr(4)) if name.begins_with("has:") else Game.flag(name)
		if value == negate:
			return false
	return true


func _process(delta: float) -> void:
	_t += delta
	if _state == State.TYPING:
		_typed += delta * CHARS_PER_SEC
		_text.visible_characters = int(_typed)
		if int(_typed) - _blips >= 2:  # a blip every couple of letters
			_blips = int(_typed)
			Audio.play("blip", BLIP_PITCH.get(_speaker, 1.0) * randf_range(0.93, 1.07), -7.0)
		if _typed >= _text.text.length():
			_state = State.WAITING
	_more.visible = _state == State.WAITING and fmod(_t, 0.8) < 0.5


func _input(event: InputEvent) -> void:
	if _state == State.CHOOSING:
		if event is InputEventKey and event.pressed and not event.echo:
			var i: int = event.keycode - KEY_1
			if i >= 0 and i < 4 and _choice_buttons[i].visible:
				get_viewport().set_input_as_handled()
				_chosen.emit(i)
		return
	if _state != State.TYPING and _state != State.WAITING:
		return
	var go := false
	if event is InputEventMouseButton:
		go = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventKey:
		go = event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	if not go:
		return
	get_viewport().set_input_as_handled()
	if _state == State.TYPING:
		_text.visible_characters = -1  # finish typing instantly
		_state = State.WAITING
	else:
		_advance.emit()
