extends "res://scripts/rooms/corridor.gd"


## The plant: dead -> perky (first watering, gives a coin) -> HUGE for a few minutes (water it again, or
## pour in a whole carafe) -> perky again. Flags: plant_watered; Game.flags["plant_big_until"] = playtime.
const BIG_SECONDS := 180.0
const PLANT_SMALL := Rect2(300, 96, 24, 26)
const PLANT_BIG := Rect2(284, 28, 56, 94)  # same pot position (bottom edge), but taller


func _floor_letter() -> String:
	return "G"


func _floor_setup() -> void:
	room_id = "lobby"
	spawns["from_breakroom"] = Vector2(420, 212)
	wall_color = Color("8a7a6a")
	floor_color = Color("b0a89c").darkened(0.35)
	add_hotspot("desk", "Receptionist desk", Rect2(200, 120, 140, 66), Vector2(270, 214),
			"A receptionist desk. Nobody is home.", Color("8b5a2b"))
	add_hotspot("plant", "Dead plant", Rect2(300, 96, 24, 26), Vector2(310, 214),
			"A dead looking plant. It looks like it gave up around 2019.", Color("5a6b2a"), {"sort_y": 186.0})
	add_hotspot("receptionist", "Receptionist", Rect2(228, 74, 40, 56), Vector2(250, 214),
			"The receptionist, standing behind the desk and staring at the giant plant in horror.",
			Color("b13e53"), {"sort_y": 185.0})  # sorts behind the desk
	_apply_plant()
	add_hotspot("logo", "Company logo", Rect2(232, 34, 56, 56), Vector2(260, 200),
			"The company logo: a monkey face on a red disc. Code Primates, Inc. The monkey looks very pleased about it.",
			Color("b13e53"), {"sort_y": horizon_y})
	add_hotspot("sign", "Sign", Rect2(114, 50, 100, 28), Vector2(160, 200),
			"\"If you worked here... you'd be at work right now.\"", Color("f4f4f4"))
	add_hotspot("breakdoor", "Break room door", Rect2(380, 60, 80, 120), Vector2(420, 196),
			"The break room.", Color("566c86"), {"exit": ["breakroom", "from_lobby"], "sort_y": horizon_y})
	add_hotspot("front", "Front doors", Rect2(500, 52, 100, 128), Vector2(550, 196),
			"The front doors. Closed and locked. The night sky stares back through the glass.", Color("41a6f6"),
			{"sort_y": horizon_y})


func _is_big() -> bool:
	return float(Game.flags.get("plant_big_until", 0.0)) > Game.playtime


## Sets the plant's look, size and name from the flags.
func _apply_plant() -> void:
	var h := get_hotspot("plant")
	get_hotspot("receptionist")["hidden"] = not _is_big()  # they only turn up to see the giant plant
	h.erase("talk")
	if _is_big():
		h["state"] = "big"
		h["rect"] = PLANT_BIG
		h["name"] = "Giant plant"
		h["look"] = "The plant is the size of a small tree. It is touching the ceiling."
	elif Game.flag("plant_watered"):
		h["state"] = "watered"
		h["rect"] = PLANT_SMALL
		h["name"] = "Plant"
		h["look"] = "The plant is green and perky. A small flower has even appeared."
	else:
		h["state"] = ""
		h["rect"] = PLANT_SMALL


func _process(delta: float) -> void:
	super(delta)
	var h := get_hotspot("plant")
	if h.get("state", "") == "big" and not _is_big():
		_apply_plant()
		_sync_art()
		queue_redraw()
		Game.say("The giant plant shrinks back to normal size, with a long, tired rustle.")


func _water(big: bool) -> void:
	var first := not Game.flag("plant_watered")
	Game.set_flag("plant_watered")
	if first:
		Game.add_item("coin")
	if big:
		Game.flags["plant_big_until"] = Game.playtime + BIG_SECONDS
		Audio.play("combine", 0.7)
		Game.say("The plant shudders... then WHOOSH! It shoots up to the ceiling, leaves everywhere." + (" Something shiny falls out of the soil: a coin!" if first else ""))
	else:
		Audio.play("pickup")
		Game.say("The plant perks up. Something shiny is in the soil: a coin! The receptionist's chair squeaks. \"That's the first time anything's grown here.\"")
	_apply_plant()
	_sync_art()
	queue_redraw()


func on_interact(h: Dictionary, verb: String, item: String) -> bool:
	if h["id"] == "receptionist":
		if verb == "Talk":
			await Game.talk("receptionist")
			return true
		return false
	if h["id"] != "plant":
		return false
	if verb == "Talk" and _is_big():
		await Game.talk("plant")
		return true
	if verb == "Use" and (item == "cup_water" or item == "mug_water"):
		if _is_big():
			Game.say("It's already enormous. It doesn't need a drop more.")
			return true
		Game.remove_item(item)
		if item == "mug_water":
			Game.add_item("mug", true)  # you keep your mug
		_water(Game.flag("plant_watered"))  # first cup: perks up. Second cup: it grows!
		return true
	if verb == "Use" and item == "carafe_water":
		if _is_big():
			Game.say("It's already enormous. It doesn't need a drop more.")
			return true
		Game.remove_item("carafe_water")
		Game.add_item("carafe")  # the plant drinks the lot; refill it at the cooler
		_water(true)
		return true
	if verb == "Use" and item == "coffee":
		Game.say("You hesitate. It would probably make things worse. Also, it's good coffee.")
		return true
	if verb == "Take":
		Game.say("It's a plant. It's staying put." if not _is_big() else "It's a tree now. It's staying put.")
		return true
	return false
