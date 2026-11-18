extends "res://scripts/room.gd"
## Break room: coffee puzzle. Take the carafe, fill it at the water cooler, brew, pour into a paper cup.
## Flags: carafe_taken, coffee_brewed.


func _setup() -> void:
	room_id = "breakroom"
	wall_color = Color("c9b26b")
	floor_color = Color("7a6a55")
	horizon_y = 190.0
	walk_poly = PackedVector2Array([Vector2(16, 198), Vector2(624, 198), Vector2(632, 284), Vector2(8, 284)])
	spawns = {"default": Vector2(320, 240), "from_lobby": Vector2(60, 214)}

	add_hotspot("door", "Lobby door", Rect2(20, 70, 80, 120), Vector2(60, 206),
			"The door back to the lobby.", Color("566c86"), {"exit": ["lobby", "from_breakroom"], "sort_y": horizon_y})
	add_hotspot("corkboard", "Corkboard", Rect2(130, 60, 80, 60), Vector2(170, 214),
			"Notices pinned all over it. One says: \"Janitor's key left somewhere in IT. Again.\"",
			Color("a9743a"), {"sort_y": horizon_y})
	add_hotspot("vending", "Vending machine", Rect2(230, 60, 70, 130), Vector2(265, 214),
			"A vending machine. Coins only. Everything costs more than it should. It looks like it wants to talk.",
			Color("b13e53"), {"talk": "vending", "sort_y": horizon_y})
	add_hotspot("cooler", "Water cooler", Rect2(330, 100, 44, 90), Vector2(352, 214),
			"A water cooler. Where office gossip goes to die.", Color("41a6f6"), {"sort_y": horizon_y})
	add_hotspot("cups", "Paper cups", Rect2(376, 126, 30, 30), Vector2(390, 214),
			"A stack of little paper cups.", Color("f4f4f4"), {"sort_y": horizon_y})
	add_hotspot("coffeemachine", "Coffee machine", Rect2(420, 120, 70, 70), Vector2(455, 214),
			"", Color("333c57"), {"sort_y": horizon_y})
	add_hotspot("carafe", "Carafe", CARAFE_RECT, Vector2(455, 216),
			"", Color("cfe9f5"), {"sort_y": 191.0})   # in front of the machine
	add_hotspot("microwave", "Microwave", Rect2(510, 120, 56, 40), Vector2(538, 214),
			"A microwave. It smells like someone's fish. It looks like it has opinions.", Color("8b8f9c"), {"sort_y": horizon_y})
	add_hotspot("fridge", "Fridge", Rect2(570, 70, 50, 120), Vector2(560, 214),
			"The fridge. A lunch is labelled: \"STEVE - DO NOT TOUCH.\"", Color("dfe3ea"), {"sort_y": horizon_y})
	_refresh_machine()


const CARAFE_RECT := Rect2(438, 146, 34, 40)


## The coffee machine and its carafe (a separate object you can see, take and use).
func _refresh_machine() -> void:
	var m := get_hotspot("coffeemachine")
	var c := get_hotspot("carafe")
	if Game.flag("coffee_brewed"):
		m["state"] = "full"                 # green light
		m["look"] = "The coffee machine. It's brewed a full carafe of coffee."
		c["state"] = "full"
		c["hidden"] = false
		c["look"] = "The glass carafe, full of fresh hot coffee. Pour it into a cup or your mug."
	elif Game.flag("carafe_taken"):
		m["state"] = ""
		m["look"] = "The coffee machine, with no carafe on its warming plate. It needs the carafe back, full of water."
		c["hidden"] = true
	else:
		m["state"] = ""
		m["look"] = "A coffee machine. The glass carafe on the warming plate is empty. It needs water."
		c["state"] = ""
		c["hidden"] = false
		c["look"] = "A glass carafe on the coffee machine's warming plate. It's empty. You could take it."


## What to do next, depending on how far along the coffee is.
func _coffee_hint() -> String:
	if Game.flag("coffee_brewed"):
		return "The machine has brewed fresh coffee. Pour it into a paper cup or your mug."
	if Game.has_item("carafe_water"):
		return "The carafe is full of water. Pour it into the coffee machine."
	if Game.has_item("carafe"):
		return "The carafe is empty. It needs water: try the water cooler."
	if Game.flag("carafe_taken"):
		return "The machine needs its carafe, full of water."
	return "The machine needs water. Take the empty carafe and fill it at the water cooler."


func _pour_into(item: String) -> bool:
	## A cup or mug used on the machine (or the carafe): fills with coffee if there is some.
	if not Game.flag("coffee_brewed"):
		Game.say("There's no coffee yet. " + _coffee_hint())
		return true
	if item == "paper_cup":
		Game.remove_item("paper_cup")
		Game.add_item("coffee")
		Game.say("You pour a cup of fresh coffee. Smells like productivity.")
	else:
		Game.remove_item("mug")
		Game.add_item("mug_coffee")
		Audio.play("combine")
		Game.say("You fill your own mug with fresh coffee. This is the good mug.")
	return true


func _coffee_interact(h: Dictionary, verb: String, item: String) -> bool:
	var is_carafe: bool = h["id"] == "carafe"
	if verb == "Take" or (verb == "Use" and item == "" and is_carafe):
		if not is_carafe:
			Game.say("You can't take the coffee machine. " + _coffee_hint())
		elif Game.flag("coffee_brewed"):
			Game.say("It's full of hot coffee. Pour it into a cup or your mug instead.")
		else:
			Game.set_flag("carafe_taken")
			Game.add_item("carafe")
			_refresh_machine()
			Game.say("You take the empty carafe. It needs water: try the water cooler.")
		return true
	if verb == "Use" and item == "":
		Game.say(_coffee_hint())
		return true
	if verb != "Use":
		return false
	match item:
		"mug_water", "cup_water":
			# Water poured straight in: the machine brews one serving into the same mug or cup.
			Game.remove_item(item)
			Game.add_item("mug_coffee" if item == "mug_water" else "coffee")
			Audio.play("combine")
			Game.say("You pour the water into the machine. It gurgles and fills your %s with fresh coffee." % ("mug" if item == "mug_water" else "cup"))
			return true
		"carafe_water":
			Game.remove_item("carafe_water")
			Game.set_flag("coffee_brewed")
			Audio.play("combine")
			_refresh_machine()
			Game.say("You pour the water in and slot the carafe back on the warming plate. The machine gurgles. Fresh coffee!")
			return true
		"carafe":
			Game.say("The carafe is empty. It needs water first: fill it at the water cooler.")
			return true
		"paper_cup", "mug":
			return _pour_into(item)
	return false


func on_interact(h: Dictionary, verb: String, item: String) -> bool:
	match h["id"]:
		"microwave":
			if verb == "Talk":
				await Game.talk("microwave")
				return true
		"corkboard":
			if verb == "Look":
				Game.set_flag("read_corkboard")
				return false  # the normal Look text
		"vending":
			if verb == "Use" and item == "coin":
				if Game.flag("chips_bought"):
					Game.say("The machine is out of everything but disappointment.")
				else:
					Game.set_flag("chips_bought")
					Game.remove_item("coin")
					Game.add_item("chips")
					Audio.play("combine")
					Game.say("Clunk. The machine thinks about it, then drops a bag of banana chips.")
				return true
			if verb == "Use":
				Game.say("Coins only. You're fresh out.")
				return true
		"cups":
			if verb == "Take":
				if Game.has_item("paper_cup"):
					Game.say("You already have a cup.")
				else:
					Game.add_item("paper_cup")
					Game.say("You take a paper cup.")
				return true
		"cooler":
			if verb == "Use" and item == "carafe":
				Game.remove_item("carafe")
				Game.add_item("carafe_water")
				Audio.play("combine")
				Game.say("Glug glug. The carafe is full of water.")
				return true
			if verb == "Use" and item == "paper_cup":
				Game.remove_item("paper_cup")
				Game.add_item("cup_water")
				Game.say("You fill the paper cup with water.")
				return true
			if verb == "Use" and item == "mug":
				Game.remove_item("mug")
				Game.add_item("mug_water")
				Game.say("You fill your mug with cold water. It's not what the mug is for.")
				return true
			if verb == "Use" and item == "mug_coffee":
				Game.say("The mug is already full of coffee. Water would only ruin it.")
				return true
			if verb == "Use" and item == "":
				Game.say("You take a sip. It tastes like plastic and regret.")
				return true
		"coffeemachine", "carafe":
			return _coffee_interact(h, verb, item)
	return false
