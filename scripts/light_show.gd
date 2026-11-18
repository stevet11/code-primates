extends Node
## The server room's periodic light show: the rack LED panels spell RED, GREEN, then SOFTWARE.
## It runs for the first ~11 seconds of every Game.LIGHT_SHOW_INTERVAL seconds of play time (so
## the first one is at 3:00). Call trigger() to play it immediately (the server room binds F2).

const COLS := 54   # 3 racks x 18 LED columns
const ROWS := 7
const HOLD := 3.0  # seconds each word stays lit
const GAP := 0.6   # dark pause between words
const WORDS := [["RED", Color("ff3b3b")], ["GREEN", Color("3bff6e")], ["SOFTWARE", Color("5cc8ff")]]
const FONT := {  # 5x7 dot-matrix letters
	"R": ["XXXX.", "X...X", "X...X", "XXXX.", "X.X..", "X..X.", "X...X"],
	"E": ["XXXXX", "X....", "X....", "XXXX.", "X....", "X....", "XXXXX"],
	"D": ["XXXX.", "X...X", "X...X", "X...X", "X...X", "X...X", "XXXX."],
	"G": [".XXX.", "X...X", "X....", "X.XXX", "X...X", "X...X", ".XXX."],
	"N": ["X...X", "XX..X", "X.X.X", "X..XX", "X...X", "X...X", "X...X"],
	"S": [".XXXX", "X....", "X....", ".XXX.", "....X", "....X", "XXXX."],
	"O": [".XXX.", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX."],
	"F": ["XXXXX", "X....", "X....", "XXXX.", "X....", "X....", "X...."],
	"T": ["XXXXX", "..X..", "..X..", "..X..", "..X..", "..X..", "..X.."],
	"W": ["X...X", "X...X", "X...X", "X.X.X", "X.X.X", "XX.XX", "X...X"],
	"A": [".XXX.", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X"],
}

var active := false
var revision := 0  # bumps whenever what's lit changes, so LEDs know to redraw
var _built: Array[Dictionary] = []
var _cells := {}
var _color := Color.WHITE
var _key := -2
var _manual := -1.0


func _ready() -> void:
	for w in WORDS:
		_built.append(_cells_for(w[0]))


func trigger() -> void:
	_manual = 0.0


## The color to light `cell` in, or null if it should be dark.
func color_at(cell: Vector2i):
	return _color if _cells.has(cell) else null


func _cells_for(text: String) -> Dictionary:
	var cells := {}
	var x0 := (COLS - (text.length() * 6 - 1)) / 2
	for i in text.length():
		var glyph: Array = FONT[text[i]]
		for r in ROWS:
			for c in 5:
				if glyph[r][c] == "X":
					cells[Vector2i(x0 + i * 6 + c, r)] = true
	return cells


func _process(delta: float) -> void:
	var slot := HOLD + GAP
	var total := slot * WORDS.size()
	var ph := -1.0  # seconds into the show, or -1 for no show
	if _manual >= 0.0:
		_manual += delta
		if _manual < total:
			ph = _manual
		else:
			_manual = -1.0
	elif Game.playtime >= Game.LIGHT_SHOW_INTERVAL:
		var p := fmod(Game.playtime, Game.LIGHT_SHOW_INTERVAL)
		if p < total:
			ph = p
	var key := -1
	if ph >= 0.0:
		var w := int(ph / slot)
		key = w * 2 + (0 if ph - w * slot < HOLD else 1)  # even = word lit, odd = pause
	if key == _key:
		return
	_key = key
	active = key >= 0
	if active:
		var w := key / 2
		_cells = _built[w] if key % 2 == 0 else {}
		_color = WORDS[w][1]
		if key % 2 == 0:
			Audio.play("beep", [0.75, 1.0, 1.4][w], -4.0)  # a tone for each word
	else:
		_cells = {}
	revision += 1
