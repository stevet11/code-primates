extends Node2D
## Blinking LEDs. Each LED loops its own repeating on/off pattern.
## If `show` (a light_show.gd node) is set and active, LEDs that belong to the display matrix (they have
## a `cell`) show the words instead: lit in the show's color for the letters, dark elsewhere. LEDs with
## no cell (blade lights, the far wall) ignore the show and keep running their patterns.
## Add the node as a child of a room, then call add_led() for each light.

# [bit pattern, length]: bit n of the pattern is the LED's state on tick n, looping.
const PATTERNS := [
	[0b10101010, 8], [0b11001100, 8], [0b10000000, 8], [0b11110000, 8],
	[0b10010010, 8], [0b11101000, 8], [0b11111110, 8], [0b10001000, 8],
	[0b1010011100, 10], [0b110100, 6], [0b1000000000000100, 16],
]
const RATES := [1.0, 1.5, 2.0, 3.0]  # ticks per second (slow and calm)

var show  # optional light_show.gd node
var rate_scale := 1.0  # < 1 blinks slower (the IT lab rack uses 0.4)
var _leds: Array[Dictionary] = []
var _t := 0.0
var _rev := -1


## `rng` picks the LED's pattern, speed and starting offset (seed it for a repeatable layout).
func add_led(pos: Vector2, color: Color, rng: RandomNumberGenerator,
		cell: Vector2i = Vector2i(-1, -1), size: Vector2 = Vector2(3, 3)) -> void:
	var p: Array = PATTERNS[rng.randi() % PATTERNS.size()]
	_leds.append({"pos": pos, "color": color, "bits": p[0], "len": p[1],
			"rate": RATES[rng.randi() % RATES.size()], "phase": rng.randi() % 16,
			"size": size, "cell": cell, "on": false})


func _process(delta: float) -> void:
	_t += delta
	var changed := false
	for l in _leds:
		var tick: int = int(_t * l["rate"] * rate_scale) + int(l["phase"])
		var on: bool = ((int(l["bits"]) >> (tick % int(l["len"]))) & 1) == 1
		if on != l["on"]:
			l["on"] = on
			changed = true
	if show != null and show.revision != _rev:
		_rev = show.revision
		changed = true
	if changed:
		queue_redraw()


func _draw() -> void:
	var showing: bool = show != null and show.active
	for l in _leds:
		var c: Color = l["color"]
		var on: bool = l["on"]
		var cell: Vector2i = l["cell"]
		if showing and cell.x >= 0:
			on = false
			var sc = show.color_at(cell)
			if sc != null:
				c = sc
				on = true
		draw_rect(Rect2(l["pos"], l["size"]), c if on else c.darkened(0.8))
