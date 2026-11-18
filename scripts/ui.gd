extends CanvasLayer
## Bottom strip: action line + verb buttons on the left, inventory icons on the right.

var _msg: Label
var _say: Label
var _say_bg: ColorRect
var _inv: Control
var _verb_buttons := {}
var _msg_text := ""
var _end_layer: CanvasLayer
var _end_label: Label
var _ended := false
var _roll: Label
var _roll_wait := 0.0
var _rolling := false
var _msg_time := 0.0


const ROLL_DELAY := 4.0   # seconds the ending card shows before the credits roll
const ROLL_SPEED := 34.0  # pixels per second
const ROLL := """CODE PRIMATES

a game about a monkey at work


STARRING

The Monkey
as Himself

Dale the Sloth
as Slowly

The Accountant
as 4,719

The Vending Machine
as Itself, Mostly

The Dead Plant
as The Dead Plant (revived, uncredited)

The Receptionist
who was not there
(until the plant)

The CEO's Gorilla
as The CEO's Gorilla


Best Boy: The Banana
Key Grip: The Janitor (whose key you borrowed)
Stunt Double: The Paperclip
Craft Services: One Coffee Machine, Carafe Sold Separately
Sound Department: A Computer Pretending To Be A Synthesizer
Lighting: Fluorescent, Flickering
Continuity: The Exit Door (it was a poster)
Meetings Attended: All of Them


MUSIC

"Elevator - Elevator Music"
by andriih (Pixabay)

Everything else: beeps and boops by tools/make_audio.py

FONT

VT323, The VT323 Project Authors (Peter Hull)
SIL Open Font License

MADE WITH

Godot Engine 4
Too much coffee
Some of it fresh


NO MONKEYS WERE HARMED
IN THE MAKING OF THIS GAME

No sloths, gorillas or other animals were harmed either.
Several beans were counted.
One donut was left unfinished.


Any resemblance to your actual workplace
is entirely your problem.

Deployed on a Friday.


THE END"""

func _ready() -> void:
	layer = 10
	var panel := ColorRect.new()
	panel.color = Color("1a1c2c")
	panel.position = Vector2(0, 288)
	panel.size = Vector2(640, 72)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	_msg = Label.new()
	_msg.position = Vector2(8, 0)
	_msg.size = Vector2(316, 24)
	_msg.add_theme_font_size_override("font_size", 22)
	_msg.add_theme_color_override("font_color", Color("f4f4f4"))
	_msg.clip_text = true
	_msg.position = Vector2(8, 2)
	panel.add_child(_msg)

	# Spoken/message text overlays the top of the room, wrapped.
	_say_bg = ColorRect.new()
	_say_bg.color = Color(0.1, 0.11, 0.17, 0.8)
	_say_bg.size = Vector2(640, 60)
	_say_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_say_bg.visible = false
	add_child(_say_bg)
	_say = Label.new()
	_say.position = Vector2(8, 6)
	_say.size = Vector2(624, 48)
	_say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_say.add_theme_font_size_override("font_size", 26)
	_say.add_theme_constant_override("line_spacing", 0)
	_say.add_theme_color_override("font_color", Color("ffcd75"))
	_say.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_say_bg.add_child(_say)

	for i in Game.VERBS.size():
		var v: String = Game.VERBS[i]
		var b := _make_button(v, Vector2(76, 22))
		b.toggle_mode = true
		b.position = Vector2(8 + i * 80, 24)
		b.pressed.connect(func(): Audio.play("click"); Game.set_verb(v))
		panel.add_child(b)
		_verb_buttons[v] = b

	var divider := ColorRect.new()
	divider.color = Color("333c57")
	divider.position = Vector2(326, 4)
	divider.size = Vector2(2, 64)
	panel.add_child(divider)

	_inv = Control.new()
	_inv.position = Vector2(332, 2)
	panel.add_child(_inv)

	# Full-screen ending card.
	_end_layer = CanvasLayer.new()
	_end_layer.layer = 30
	_end_layer.visible = false
	add_child(_end_layer)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.size = Vector2(640, 360)
	_end_layer.add_child(black)
	_end_label = Label.new()
	_end_label.position = Vector2(20, 70)
	_end_label.size = Vector2(600, 200)
	_end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_end_label.add_theme_font_size_override("font_size", 40)
	_end_label.add_theme_color_override("font_color", Color("ffcd75"))
	_end_layer.add_child(_end_label)
	_roll = Label.new()
	_roll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_roll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_roll.add_theme_font_size_override("font_size", 24)
	_roll.add_theme_color_override("font_color", Color("f4f4f4"))
	_roll.visible = false
	_end_layer.add_child(_roll)
	var hint := Label.new()
	hint.text = "Enter: title screen      Esc: quit"
	hint.position = Vector2(20, 330)
	hint.size = Vector2(600, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color("566c86"))
	_end_layer.add_child(hint)
	Game.ending_requested.connect(_on_ending)

	Game.message.connect(_on_message)
	Game.verb_changed.connect(_refresh_verbs)
	Game.verb_changed.connect(_refresh_inventory)  # highlights the held item
	Game.inventory_changed.connect(_refresh_inventory)
	_refresh_verbs()


func _make_button(text: String, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 22)
	var colors := {"normal": "3b5dc9", "hover": "41a6f6", "pressed": "ef7d57", "hover_pressed": "ffcd75"}
	for state in colors:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(colors[state])
		sb.set_content_margin_all(0)
		b.add_theme_stylebox_override(state, sb)
	return b


func _refresh_verbs() -> void:
	for v in _verb_buttons:
		(_verb_buttons[v] as Button).set_pressed_no_signal(v == Game.verb)


const ICON_DIR := "res://assets/items/"
const ICON := 32     # icon button size
const ICON_COLS := 8
const ICON_PITCH := Vector2(37, 34)


func _refresh_inventory() -> void:
	Game.hover_item = ""
	for c in _inv.get_children():
		c.queue_free()
	for i in Game.inventory.size():
		var b := _make_item_button(Game.inventory[i])
		b.position = Vector2((i % ICON_COLS) * ICON_PITCH.x, floorf(i / float(ICON_COLS)) * ICON_PITCH.y)
		_inv.add_child(b)


## An icon button (assets/items/<id>.png, 32x32). Without art it shows the first letters of the name.
func _make_item_button(id: String) -> Button:
	var item_name: String = Game.ITEMS[id]["name"]
	var b := Button.new()
	b.size = Vector2(ICON, ICON)
	b.custom_minimum_size = b.size
	b.focus_mode = Control.FOCUS_NONE
	b.clip_text = true
	var path := ICON_DIR + id + ".png"
	if ResourceLoader.exists(path):
		b.icon = load(path)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.expand_icon = false
	else:
		b.text = item_name.substr(0, 3)
		b.add_theme_font_size_override("font_size", 22)
	var held: bool = Game.held_item == id
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("41a6f6") if state.begins_with("hover") else Color("333c57")
		sb.set_border_width_all(2)
		sb.border_color = Color("ffcd75") if held else Color("566c86")
		sb.set_content_margin_all(0)
		b.add_theme_stylebox_override(state, sb)
	b.pressed.connect(func(): _on_item_clicked(id))
	b.mouse_entered.connect(func(): Game.hover_item = item_name)
	b.mouse_exited.connect(func(): Game.hover_item = "")
	return b


func _on_item_clicked(id: String) -> void:
	Audio.play("click")
	if Game.verb == "Use" and Game.held_item == id:
		Game.set_verb("Look")  # click the selected item again to put it away
	elif Game.verb == "Use" and Game.held_item != "":
		var other: String = Game.held_item
		Game.set_verb("Look")
		if not Game.try_combine(other, id):
			Audio.play("error")
			Game.say("I can't combine those.")
	elif Game.verb == "Use":
		Game.select_item(id)
	else:
		Game.say(Game.ITEMS[id]["desc"])


func _on_ending(text: String) -> void:
	_ended = true
	_msg_time = 0.0
	_end_label.text = text
	_end_label.visible = true
	_roll.visible = false
	_end_layer.visible = true
	_roll_wait = ROLL_DELAY
	_rolling = false


## Credits roll after the ending card: starts below the screen and scrolls up, then holds on THE END.
func _update_roll(delta: float) -> void:
	if not _ended:
		return
	if _roll_wait > 0.0:
		_roll_wait -= delta
		if _roll_wait <= 0.0:
			_end_label.visible = false
			_roll.text = ROLL
			_roll.size = Vector2(560, 0)
			_roll.position = Vector2(40, 330)
			_roll.visible = true
			_rolling = true
	elif _rolling:
		_roll.position.y -= ROLL_SPEED * delta
		var bottom := _roll.position.y + _roll.get_minimum_size().y
		if bottom < 170.0:  # the last line settles in the middle of the screen
			_roll.position.y += 170.0 - bottom
			_rolling = false


func _unhandled_key_input(event: InputEvent) -> void:
	if not (_ended and event is InputEventKey and event.pressed):
		return
	if event.keycode == KEY_ESCAPE:
		get_tree().quit()
	elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		_ended = false
		_end_layer.visible = false
		Game.title_requested.emit()


func _on_message(text: String) -> void:
	_msg_text = text
	_msg_time = maxf(4.0, 2.0 + text.length() * 0.055)  # longer messages stay up longer (about 18 characters a second)


func _process(delta: float) -> void:
	_update_roll(delta)
	_say_bg.visible = _msg_time > 0.0
	if _msg_time > 0.0:
		_msg_time -= delta
		if _say.text != _msg_text:
			_say.text = _msg_text
			var h := _say.get_theme_font("font").get_multiline_string_size(
					_msg_text, HORIZONTAL_ALIGNMENT_LEFT, 624, 26).y
			_say_bg.size.y = h + 12.0
	var t: String = Game.verb
	if Game.held_item != "":
		t = "Use " + Game.ITEMS[Game.held_item]["name"] + " on"
	var hovered: String = Game.hover_item if Game.hover_item != "" else Game.hover_name
	if hovered != "":
		t += " " + hovered
	_msg.text = t
