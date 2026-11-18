extends Node
## Global game state (autoload "Game"): verb, inventory, story flags.

signal message(text: String)
signal inventory_changed
signal verb_changed
signal room_change_requested(room_id: String, spawn: String)
signal ending_requested(text: String)
signal title_requested

const GAME_TITLE := "CODE PRIMATES"  # working title
const ROOM_TITLES := {"office": "The Office", "hallway": "Hallway", "server": "Server Room",
		"breakroom": "Break Room", "accounting": "Accounting", "conference": "Conference Room", "boss": "Boss's Office", "vp": "VP Office", "itlab": "IT Lab", "closet": "Janitor Closet", "itmgr": "IT Manager Office", "ceo": "CEO Office", "elevator": "Elevator", "basement": "Basement", "lobby": "Lobby", "floor3": "3rd Floor"}
## Seconds of play between server room light shows (RED, GREEN, SOFTWARE). 180 = every 3 minutes;
## set to 300 for every 5 minutes.
const LIGHT_SHOW_INTERVAL := 180.0
const VERBS := ["Look", "Use", "Take", "Talk"]
const ITEMS := {
	"paperclip": {"name": "Paperclip", "desc": "A slightly bent paperclip."},
	"mug": {"name": "Coffee mug", "desc": "Your mug. \"Programmer: noun, a machine that turns coffee into code.\" It's empty."},
	"mug_water": {"name": "Mug of water", "desc": "Your mug, full of cold water. The monkey wants coffee, not this."},
	"mug_coffee": {"name": "Mug of coffee", "desc": "Your mug, full of fresh coffee. Maybe the monkey should drink it."},
	"keycard": {"name": "Keycard", "desc": "A keycard labelled 'IT LAB'."},
	"carafe": {"name": "Carafe", "desc": "An empty glass coffee carafe."},
	"carafe_water": {"name": "Carafe of water", "desc": "A carafe full of cold water from the cooler."},
	"paper_cup": {"name": "Paper cup", "desc": "A small paper cup."},
	"cup_water": {"name": "Cup of water", "desc": "A paper cup of cold water."},
	"coffee": {"name": "Cup of coffee", "desc": "Fresh, hot coffee. The good stuff. Maybe the monkey should drink it."},
	"coin": {"name": "Coin", "desc": "A coin. The vending machine takes coins only."},
	"pin_note": {"name": "PIN note", "desc": "A scrap of paper: '4719'. The accountant's lost count."},
	"code_note": {"name": "Sticky note", "desc": "A sticky note: 'Boss door: 3141. DON'T LOSE.'"},
	"golf_ball": {"name": "Silver golf ball", "desc": "The boss's solid silver golf ball. Heavy and absurdly expensive. It needs a putter and a hole."},
	"ceo_key": {"name": "CEO key", "desc": "A heavy brass key with a tag: 'CEO. Do not copy.'"},
	"usb_stick": {"name": "USB stick", "desc": "A USB stick labelled 'BACKUP - DO NOT LOSE'."},
	"janitor_key": {"name": "Janitor's key", "desc": "A ring with a single key tagged 'CLOSET'."},
	"flashlight": {"name": "Flashlight", "desc": "A flashlight. The batteries work. Miraculous."},
	"fuse": {"name": "Spare fuse", "desc": "A spare fuse, 20 amps."},
	"serial_note": {"name": "Serial note", "desc": "You wrote down the rack serial: XR-7-5189."},
	"green_card": {"name": "Green keycard", "desc": "A green keycard. SERVER ROOM ACCESS."},
	"chips": {"name": "Banana chips", "desc": "A bag of banana chips. Suspiciously crunchy."},
}

## Item combinations. Key: the two item ids sorted alphabetically and joined with "+".
## "result": the new item. "text": what the monkey says.
## Both items are used up, except any listed in the optional "keep" array.
## There are none at the moment. Example: "a+b": {"result": "c", "keep": ["a"], "text": "..."}.
const COMBOS := {}

## The Notes screen (N, or Pause > Notes): [flag, text]. A note shows once its flag is set (a flag of "" is always
## shown). Several are set by the story itself (clues you pick up); the rest by looking at things (see the rooms).
const NOTES := [
	["", "Goal: deploy to production. (It's a Friday.)"],
	["tried_sleepy", "Computers: the monkey can't use them until he has had a coffee. Brew one in the break room, then use the coffee on the monkey."],
	["read_corkboard", "Break room corkboard: the janitor's key is \"somewhere in IT\"."],
	["knows_hint", "Vending machine tip: the server room is in the basement, behind the IT lab. The IT lab needs a keycard from the office desk drawer."],
	["asked_terminal", "Dale (server room): the deploy terminal only accepts authorized media, a USB stick of the CEO's backups from upstairs."],
	["dale_ok", "Dale won't stop me deploying now that it's technically Saturday in Tokyo. I just need that USB stick."],
	["knows_serial", "Rack serial in the IT lab: XR-7-5189. The IT manager's computer password is the last 4 digits: 5189."],
	["boss_hint", "Note in the boss's desk drawer: the safe PIN is something the accountant says whenever he loses count."],
	["saw_keypad", "The boss's office (2nd floor) has a keypad and wants a 4-digit code."],
	["note_taken", "Boss's door code, from the sticky note in the conference room: 3141."],
	["knows_pin", "The accountant's PIN: 4719."],
	["painting_moved", "A safe is hidden behind the golf picture in the CEO's office. It wants a PIN."],
	["saw_ceo_lock", "The CEO's office (3rd floor) is locked. It needs a very important key."],
	["read_photo", "Note behind the CEO's photo: \"Server room backups go on the USB stick.\""],
	["putt_done", "Sank the putt in the CEO's office. The cup gave me a USB stick."],
	["usb_loaded", "The deploy package is on the USB stick. Take it to the CEO's terminal."],
]

var verb := "Look"
var held_item := ""
var hover_name := ""       # hotspot under the mouse
var hover_item := ""       # inventory item under the mouse (name)
var inventory: Array[String] = []
var flags := {}
var in_game := false
var menu_open := false
var ended := false
var playtime := 0.0  # seconds
var busy := false  # true while a dialogue is playing (room ignores clicks)
var dialogue_ui: Node


## Back to a fresh game state (new game / quit to title / before loading).
func reset() -> void:
	inventory.clear()
	flags.clear()
	tail_frame = -1
	verb = "Look"
	held_item = ""
	hover_name = ""
	hover_item = ""
	busy = false
	ended = false
	playtime = 0.0
	inventory_changed.emit()
	verb_changed.emit()


func _process(delta: float) -> void:
	if in_game and not menu_open and not ended:
		playtime += delta


## Ends the game with a full-screen message (Esc quits).
func ending(text: String) -> void:
	busy = true
	ended = true
	Audio.stop_music(1.0)
	Audio.play_ambience("")
	Audio.play("ending")
	ending_requested.emit(text)


## Plays assets/dialogue/<id>.txt and returns when it ends.
func talk(id: String) -> void:
	if dialogue_ui:
		await dialogue_ui.run(id)


func say(text: String) -> void:
	message.emit(text)


func set_verb(v: String) -> void:
	verb = v
	if v != "Use":
		held_item = ""
	verb_changed.emit()


func select_item(id: String) -> void:
	held_item = id
	verb = "Use"
	verb_changed.emit()


func add_item(id: String, quiet: bool = false) -> void:
	if id not in inventory:
		inventory.append(id)
		inventory_changed.emit()
		if not quiet:
			Audio.play("pickup")


## Combines two items if a recipe exists. Returns true if it did.
func try_combine(a: String, b: String) -> bool:
	var ids := [a, b]
	ids.sort()
	var recipe: Dictionary = COMBOS.get("+".join(ids), {})
	if recipe.is_empty():
		return false
	var keep: Array = recipe.get("keep", [])
	for id in ids:
		if id not in keep:
			remove_item(id)
	add_item(recipe["result"], true)
	Audio.play("combine")
	say(recipe["text"])
	return true


## The monkey can't do certain things (use a computer) until he has drunk a coffee. Flag: caffeinated.
## Returns true, after saying why, if he is still too sleepy.
func too_sleepy(action: String = "do that") -> bool:
	if flag("caffeinated"):
		return false
	set_flag("tried_sleepy")
	say("The words swim. I can't %s without coffee. (Drink one: use a cup of coffee on the monkey.)" % action)
	Audio.play("error", 1.0, -4.0)
	return true


## Using an item on the monkey himself (click him while holding it): coffee is drunk, water is refused.
func use_on_monkey(item: String) -> void:
	if item in ["coffee", "mug_coffee"]:
		drink_coffee(item)
	elif item == "chips":
		remove_item("chips")
		say("Crunch crunch crunch. Banana chips, mostly. You are, after all, a monkey. Delicious.")
		Audio.play("pickup", 0.8)
		set_verb("Look")
	elif item in ["mug_water", "cup_water"]:
		say("It's just water. The monkey needs coffee, not a drink of water.")
		Audio.play("error", 1.0, -4.0)
	else:
		say("That doesn't work on the monkey.")
		Audio.play("error", 1.0, -4.0)


func drink_coffee(which: String = "") -> void:
	var drink := which if which != "" else ("coffee" if has_item("coffee") else "mug_coffee")
	if not has_item(drink):
		return
	remove_item(drink)
	if drink == "mug_coffee":
		add_item("mug", true)  # the mug is empty again
	if flag("caffeinated"):
		say("You drink the coffee. Your hands are shaking a little. That's plenty.")
	else:
		set_flag("caffeinated")
		say("Glug glug glug. Your eyes snap open. Your fur stands on end. You could write code now!")
	Audio.play("pickup", 1.4)
	set_verb("Look")
	_tail_animation()


## The tail uncurls to straight, stays up a moment, then curls back. Frame index into the sheet's tail frames
## (player.gd draws it). Lives here, not in the player, so it survives the player node being replaced.
var tail_frame := -1


func _tail_animation() -> void:
	var was_busy := busy
	busy = true
	for i in 3:
		tail_frame = i
		await get_tree().create_timer(0.13).timeout
	await get_tree().create_timer(0.9).timeout
	for i in [1, 0]:
		tail_frame = i
		await get_tree().create_timer(0.13).timeout
	tail_frame = -1
	busy = was_busy


func has_item(id: String) -> bool:
	return id in inventory


func remove_item(id: String) -> void:
	inventory.erase(id)
	inventory_changed.emit()


func set_flag(name: String, value: bool = true) -> void:
	if value and in_game and not flags.get(name, false) and _is_note_flag(name):
		Audio.play("blip", 1.9, -10.0)  # a little tick: something went into the notes
	flags[name] = value


func _is_note_flag(name: String) -> bool:
	for n: Array in NOTES:
		if n[0] == name:
			return true
	return false


## The texts of the notes found so far.
func notes_found() -> Array[String]:
	var out: Array[String] = []
	for n: Array in NOTES:
		if n[0] == "" or flag(n[0]):
			out.append(n[1])
	return out


func flag(name: String) -> bool:
	return flags.get(name, false)
