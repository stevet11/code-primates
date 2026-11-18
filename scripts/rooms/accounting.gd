extends "res://scripts/room.gd"
## Accounting (3rd floor). The accountant counts beans, one every 3 seconds, all game.
## Give them coffee, then talk: they lose count and mutter the PIN (4719) for the boss's safe.
## Flags: accountant_awake, knows_pin. Game.flags["bean_reset"] = playtime of the last lost count.

const FONT := preload("res://assets/fonts/VT323.ttf")
const BEAN_SECONDS := 3.0

var _label: Node2D
var _shown := -1


func _setup() -> void:
	room_id = "accounting"
	wall_color = Color("6b5a4a")
	floor_color = Color("3b3045")
	horizon_y = 190.0
	walk_poly = PackedVector2Array([Vector2(16, 198), Vector2(624, 198), Vector2(632, 284), Vector2(8, 284)])
	spawns = {"default": Vector2(320, 240), "from_hall": Vector2(60, 214)}
	obstacles.append(PackedVector2Array([Vector2(280, 170), Vector2(440, 170), Vector2(440, 214), Vector2(280, 214)]))

	add_hotspot("door", "Hallway door", Rect2(20, 70, 80, 120), Vector2(60, 206),
			"The door back to the hallway.", Color("566c86"), {"exit": ["floor3", "from_accounting"], "sort_y": horizon_y})
	add_hotspot("window", "Window", Rect2(150, 40, 100, 80), Vector2(200, 214),
			"The night sky over the city. The numbers on the other side of the glass don't add up either.")
	add_hotspot("desk", "Desk", Rect2(280, 150, 160, 60), Vector2(360, 226),
			"A desk covered in neat piles of beans.", Color("8b5a2b"), {"sort_y": 214.0})
	add_hotspot("beans", "Beans", Rect2(320, 134, 60, 18), Vector2(350, 226),
			"Beans. Counted, sorted and stacked in piles of ten.", Color("a9743a"), {"sort_y": 212.0})
	add_hotspot("accountant", "Accountant", Rect2(396, 100, 44, 70), Vector2(420, 226),
			"An accountant, counting beans. They never look up.", Color("2d4cae"), {"sort_y": 214.0})
	add_hotspot("calculator", "Calculator", Rect2(300, 140, 20, 12), Vector2(310, 226),
			"A calculator with the 7 worn off. It has been used a lot.", Color("cfd2dc"), {"sort_y": 212.0})
	# The filing shelves painted into the background: TPS reports, all the way up.
	add_hotspot("shelves_l", "Filing shelves", Rect2(106, 60, 36, 130), Vector2(124, 214),
			"Shelves of TPS reports, alphabetized by cover sheet. Not by content. Nobody reads the content.")
	add_hotspot("shelves_r", "Filing shelves", Rect2(560, 60, 50, 130), Vector2(585, 214),
			"More TPS reports. Each has a memo stapled to it about the new cover sheet.")
	if not Game.flags.has("bean_reset"):
		Game.flags["bean_reset"] = Game.playtime


func _after_art() -> void:
	_label = Node2D.new()
	_label.z_index = 60
	_label.draw.connect(_draw_count)
	add_child(_label)


func _bean_count() -> int:
	return int((Game.playtime - float(Game.flags.get("bean_reset", 0.0))) / BEAN_SECONDS)


func _draw_count() -> void:
	_label.draw_string(FONT, Vector2(386, 94), "%d..." % _bean_count(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
			Color("f4f4f4"))


func _process(delta: float) -> void:
	super(delta)
	if _bean_count() != _shown:
		_shown = _bean_count()
		_label.queue_redraw()
		if _shown > 0:
			Audio.play("blip", 1.5, -16.0)


func on_interact(h: Dictionary, verb: String, item: String) -> bool:
	match h["id"]:
		"accountant":
			if verb == "Use" and item == "coffee":
				if Game.flag("accountant_awake"):
					Game.say("They already have a coffee. Don't interrupt the count.")
				else:
					Game.remove_item("coffee")
					Game.set_flag("accountant_awake")
					Audio.play("combine")
					Game.say("You slide the coffee next to them. They sip without looking up. Their eyes open a little wider.")
				return true
			if verb == "Use" and item == "mug_coffee":
				Game.remove_item("mug_coffee")  # they keep the mug
				Game.set_flag("accountant_awake")
				Audio.play("pickup")
				Game.say("They take it without looking up. \"Oh, what a nice coffee mug! Thank you so much!\" They sip. They are keeping the mug.")
				return true
			if verb == "Use" and item == "chips":
				Game.remove_item("chips")
				Audio.play("combine")
				Game.say("They crunch a chip without looking up. Then they start counting the chips. You decide not to interrupt.")
				return true
			if verb == "Talk":
				await Game.talk("accountant")
				if Game.flag("accountant_awake"):
					Game.flags["bean_reset"] = Game.playtime  # they lost count, start over
				return true
			if verb == "Take":
				Game.say("You can't take an accountant. HR has rules.")
				return true
		"shelves_l", "shelves_r":
			if verb == "Take":
				Game.say("You pull out a TPS report. It needs a new cover sheet. You put it back.")
				return true
		"beans":
			if verb == "Take":
				Game.say("Hands off! Those are counted.")
				return true
	return false
