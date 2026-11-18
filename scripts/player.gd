extends Node2D
## Placeholder monkey. Origin is at the feet; scale follows depth.

const SPEED := 110.0

## Optional art: res://assets/characters/player.png, a horizontal strip of 48x48
## frames. Frame 0 = standing; frames 1..N = walk cycle. Feet at bottom-center.
const SHEET := "res://assets/characters/player.png"
const FRAME_W := 48
const ANCHOR_X := 28.0  # x in the frame that sits on the player's position (body center)
const FRAME_H := 48
const WALK_FRAMES := 4       # frames 1..4 are the walk cycle
const TAIL_FRAME_0 := 5      # frames 5..7: the tail straightening (see tools/make_placeholder_art.py)
const TAIL_FRAMES := 3

var room
var tex: Texture2D
var moving := false
var facing := 1.0
var _path := PackedVector2Array()
var _i := 0
var _token := 0
var _t := 0.0


func _ready() -> void:
	if ResourceLoader.exists(SHEET):
		tex = load(SHEET)


## Walks to p (clamped to the floor, around obstacles). Returns true if it
## arrived, false if a newer walk_to() interrupted it.
func walk_to(p: Vector2) -> bool:
	_path = room.find_path(position, p)
	_i = 1
	moving = true
	_token += 1
	var mine := _token
	while moving and mine == _token:
		await get_tree().process_frame
	return mine == _token


func _process(delta: float) -> void:
	_t += delta
	var s: float = room.depth_scale(position.y)
	if moving:
		var remaining: float = SPEED * s * delta
		while remaining > 0.0 and _i < _path.size():
			var d := _path[_i] - position
			var dist := d.length()
			if absf(d.x) > 0.1:
				facing = signf(d.x)
			if dist <= remaining:
				position = _path[_i]
				remaining -= dist
				_i += 1
			else:
				position += d / dist * remaining
				remaining = 0.0
		if _i >= _path.size():
			moving = false
	scale = Vector2(s * facing, s)
	queue_redraw()


func _draw() -> void:
	if tex:
		draw_rect(Rect2(-12, -2, 24, 4), Color(0, 0, 0, 0.35))  # shadow
		var frames := int(tex.get_width() / FRAME_W)
		var f := 0
		if Game.tail_frame >= 0 and frames >= TAIL_FRAME_0 + TAIL_FRAMES:
			f = TAIL_FRAME_0 + Game.tail_frame   # the tail animation (driven by Game.drink_coffee)
		elif moving and frames > 1:
			f = 1 + int(_t * 8.0) % WALK_FRAMES
		draw_texture_rect_region(tex, Rect2(-ANCHOR_X, -FRAME_H, FRAME_W, FRAME_H),
				Rect2(f * FRAME_W, 0, FRAME_W, FRAME_H))
		return
	var bob := floorf(absf(sin(_t * 10.0)) * 3.0) if moving else 0.0
	var fur := Color("73400d")
	var light := Color("c8905a")
	draw_rect(Rect2(-12, -2, 24, 4), Color(0, 0, 0, 0.35))                # shadow
	draw_rect(Rect2(-6, -16, 4, 16), fur.darkened(0.3))                    # legs
	draw_rect(Rect2(2, -16, 4, 16), fur.darkened(0.3))
	draw_line(Vector2(-8, -20 - bob), Vector2(-16, -30 - bob), fur, 2.0)  # tail
	draw_rect(Rect2(-8, -34 - bob, 16, 20), fur)                          # body
	draw_rect(Rect2(-8, -48 - bob, 16, 14), fur)                           # head
	draw_rect(Rect2(-12, -46 - bob, 4, 6), light)                         # ears
	draw_rect(Rect2(8, -46 - bob, 4, 6), light)
	draw_rect(Rect2(-2, -44 - bob, 10, 8), light)                         # face
	draw_rect(Rect2(4, -44 - bob, 2, 2), Color.BLACK)                    # eye
