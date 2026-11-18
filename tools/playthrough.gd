extends SceneTree
## Headless playthrough: runs every puzzle step through the rooms' on_interact and checks the result.
## Run: godot --headless --path . -s tools/playthrough.gd
## Not covered: walking, mouse clicks, rendering. Dialogues are played for real and advanced automatically.

var G
var main
var fails := 0


func _init() -> void:
	await process_frame
	load("res://scripts/saves.gd").disabled = true  # never touch the real saves (new games autosave)
	G = root.get_node("Game")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.start_new_game()
	await process_frame

	# Opening: paperclip -> drawer -> lab keycard.
	await step("office", "mug", "Take"); has("mug")
	await step("office", "clip", "Take"); has("paperclip")
	await step("office", "drawer", "Use", "paperclip"); has("keycard")

	check(G.too_sleepy("test"), "the monkey is sleepy before coffee")
	G.add_item("serial_note")
	await step("itmgr", "computer", "Use", "serial_note")
	check(not G.flag("computer_unlocked"), "computer refuses a sleepy monkey")
	G.remove_item("serial_note")

	# Ground floor: coffee, then the plant.
	await ride("G")
	await step("breakroom", "coffeemachine", "Use")   # with nothing: the machine gives a hint (needs water)
	await step("breakroom", "carafe", "Take"); has("carafe")
	await step("breakroom", "cooler", "Use", "carafe"); has("carafe_water")
	await step("breakroom", "coffeemachine", "Use", "carafe_water"); check(G.flag("coffee_brewed"), "coffee brewed")
	# Mug of water: the monkey refuses it, but pouring it into the machine makes coffee (no way to get stuck).
	await step("breakroom", "cooler", "Use", "mug"); has("mug_water")
	G.use_on_monkey("mug_water"); check(not G.flag("caffeinated"), "the monkey refuses water")
	await step("breakroom", "coffeemachine", "Use", "mug_water"); has("mug_coffee")
	G.drink_coffee("mug_coffee"); check(G.flag("caffeinated"), "mug of coffee, made from water, is drinkable")
	await talk("breakroom", "microwave")  # the microwave gag
	await step("breakroom", "cups", "Take"); has("paper_cup")
	await step("breakroom", "coffeemachine", "Use", "paper_cup"); has("coffee")
	G.drink_coffee(); check(G.flag("caffeinated"), "the monkey drank the coffee")
	await step("breakroom", "coffeemachine", "Use", "mug"); has("mug_coffee")  # your own mug, for the accountant
	await step("breakroom", "cups", "Take")
	await step("breakroom", "cooler", "Use", "paper_cup"); has("cup_water")
	await step("lobby", "plant", "Use", "cup_water"); has("coin")
	check(main.current.get_hotspot("plant")["state"] == "watered", "plant perks up")
	G.add_item("cup_water")  # a second cup: it grows huge, then shrinks again after a few minutes
	await step("lobby", "plant", "Use", "cup_water")
	check(main.current.get_hotspot("plant")["state"] == "big", "plant grows with a second cup")
	check(not main.current.get_hotspot("receptionist")["hidden"], "receptionist appears for the giant plant")
	await talk("lobby", "receptionist")
	await talk("lobby", "plant")
	G.playtime += 200.0
	await process_frame
	check(main.current.get_hotspot("receptionist")["hidden"], "receptionist leaves when the plant shrinks")
	check(main.current.get_hotspot("plant")["state"] == "watered", "plant shrinks back")

	await step("breakroom", "vending", "Use", "coin"); has("chips")

	# Basement: IT lab, closet, fuse, serial, computer, green keycard, server room.
	await ride("B")
	await step("basement", "labdoor", "Use", "keycard"); check(G.flag("itlab_open"), "lab open")
	check(main.current.get_hotspot("labdoor")["state"] == "open", "IT lab reader light turns green")
	await step("itlab", "key", "Take"); has("janitor_key")
	await step("basement", "closet", "Use", "janitor_key"); check(G.flag("closet_open"), "closet open")
	await step("closet", "flashlight", "Take"); has("flashlight")
	await step("closet", "fuse", "Take"); has("fuse")
	await step("itlab", "fusebox", "Use", "fuse"); check(G.flag("power_on"), "power on")
	check(main.current.get_hotspot("mgrdoor").has("exit"), "manager's door opens once the power is on")
	await step("itlab", "rack", "Use", "flashlight"); has("serial_note")
	await step("itmgr", "computer", "Use", "serial_note"); check(G.flag("computer_unlocked"), "computer unlocked")
	await step("itmgr", "drawer", "Take"); has("green_card")
	await step("itlab", "greendoor", "Use", "green_card"); check(G.flag("lab_open"), "server room open")
	check(main.current.get_hotspot("greendoor")["state"] == "open", "server door reader light turns green")

	# 3rd floor: accountant (coffee wakes them, the dialogue gives the PIN note).
	await ride("3")
	await step("accounting", "accountant", "Use", "mug_coffee"); check(G.flag("accountant_awake"), "accountant awake")
	check(not G.has_item("mug") and not G.has_item("mug_coffee"), "the accountant kept the mug")
	await step("accounting", "accountant", "Use", "chips"); check(not G.has_item("chips"), "accountant ate the chips")
	await talk("accounting", "accountant")  # asleep-or-not: runs the real dialogue, pressing Enter for you
	has("pin_note"); check(G.flag("knows_pin"), "accountant gave the PIN")
	await talk_dialogue("vpphone")  # the VP's voicemail menu (first choice, then it loops until hang up)
	await step("vp", "hook", "Take"); has("ceo_key")
	await step("floor3", "ceo", "Use", "ceo_key"); check(G.flag("ceo_open"), "ceo office open")

	# 2nd floor: sticky note, boss's office, painting, safe.
	await ride("2")
	await talk("conference", "phone")  # the speakerphone gag
	await talk_dialogue("memo")  # the memo, read a line at a time
	await step("conference", "memo", "Take")
	await step("conference", "note", "Take"); has("code_note")
	await step("hallway", "bossdoor", "Use", "code_note"); check(G.flag("boss_open"), "boss office open")
	check(main.current.get_hotspot("bossdoor")["state"] == "open", "boss keypad light turns green")
	await step("boss", "desk", "Use"); check(G.flag("boss_hint"), "boss desk hint found")
	await talk("boss", "trophies"); await talk("boss", "desk")  # the gag dialogues (the boss's office is optional)

	# CEO office: the putt, then the server terminal, then the ending.
	await ride("3")
	await step("ceo", "painting", "Use"); check(G.flag("painting_moved"), "golf picture moved")
	await step("ceo", "safe", "Use", "pin_note"); has("golf_ball")
	await step("ceo", "putter", "Use", "golf_ball"); has("usb_stick")  # the silver ball on the putter (or on the cup)
	await talk_dialogue("dale")  # all of Dale's conversation (the first choice every time, until it ends)
	check(G.flag("asked_terminal") and G.flag("dale_ok"), "Dale's hints and the Tokyo joke play out")
	await step("server", "console", "Use", "usb_stick"); check(G.flag("usb_loaded"), "usb loaded")
	await step("ceo", "terminal", "Use", "usb_stick"); check(G.ended, "game ended")

	G.add_item("chips"); G.use_on_monkey("chips")
	check(not G.has_item("chips"), "the monkey eats the banana chips")
	for f in ["tried_sleepy", "knows_serial", "note_taken", "knows_pin", "painting_moved", "putt_done", "usb_loaded"]:
		check(G.flag(f), "note flag set: " + f)
	check(G.notes_found().size() >= 8, "the Notes screen lists the clues (%d)" % G.notes_found().size())
	print("PLAYTHROUGH ", "PASSED" if fails == 0 else "FAILED (%d)" % fails)
	quit(1 if fails > 0 else 0)


## Enters a room and calls on_interact for one hotspot.
func step(room: String, hotspot: String, verb: String, item: String = "") -> void:
	if main.current == null or main.current.room_id != room:
		main._change_room(room, "default")
		await process_frame
	var h: Dictionary = main.current.get_hotspot(hotspot)
	if h.is_empty():
		check(false, "%s has no hotspot '%s'" % [room, hotspot])
		return
	await main.current.on_interact(h, verb, item)


## Talks to a hotspot (the real dialogue UI), pressing Enter on every line. Picks choice 1 if asked.
func talk(room: String, hotspot: String) -> void:
	if main.current == null or main.current.room_id != room:
		main._change_room(room, "default")
		await process_frame
	var ui = G.dialogue_ui
	var done := [false]
	var run := func():
		await main.current.on_interact(main.current.get_hotspot(hotspot), "Talk", "")
		done[0] = true
	run.call()
	var guard := 0
	while not done[0] and guard < 2000:
		guard += 1
		await process_frame
		if ui._state == ui.State.WAITING:
			ui._advance.emit()
		elif ui._state == ui.State.CHOOSING:
			ui._chosen.emit(0)
	check(done[0], "dialogue with %s finished" % hotspot)


## Plays a dialogue file straight through (same auto-advance as talk()).
func talk_dialogue(id: String) -> void:
	var ui = G.dialogue_ui
	var done := [false]
	var run := func():
		await G.talk(id)
		done[0] = true
	run.call()
	var guard := 0
	while not done[0] and guard < 3000:
		guard += 1
		await process_frame
		if ui._state == ui.State.WAITING:
			ui._advance.emit()
		elif ui._state == ui.State.CHOOSING:
			ui._chosen.emit(0)
	check(done[0], "dialogue %s finished" % id)


## Travels with the real elevator (checks the floor, then the exit leads to the right room).
func ride(floor_id: String) -> void:
	await process_frame  # lets a pending room change (the green door's, say) finish first
	await process_frame
	main._change_room("elevator", "default")
	await process_frame
	var el = main.current
	if el.room_id != "elevator":
		check(false, "not in the elevator")
		return
	await el._travel(floor_id)
	var exit_room: String = el.get_hotspot("door")["exit"][0]
	check(el.FLOOR_ROOMS[floor_id] == exit_room, "elevator door leads to floor " + floor_id)


func has(item: String) -> void:
	check(G.has_item(item), "has " + item)


func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", what)
