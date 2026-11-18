# Art spec

Everything is optional: any missing image falls back to the colored placeholder.
Game area is **640x288** (the bottom 72px of the 640x360 screen is the UI).
After adding or changing PNGs, open the project in the Godot editor once (or run
`godot --headless --path . --import`) so they get imported. Save PNGs with transparency.

## Rooms: `assets/rooms/<room_id>/`
| file | size | notes |
|---|---|---|
| `background.png` | 640x288 | wall + floor, drawn behind everything |
| `<hotspot_id>.png` | any | top-left sits on the hotspot rect's top-left (see `add_hotspot` in the room script) |
| `<hotspot_id>_<state>.png` | any | used when the hotspot's `state` is set, e.g. `drawer_open.png` |
| `foreground.png` | 640x288 | optional; always drawn over the player (railings, pillars) |

**Walk-behind:** things sort by their bottom edge. The player is drawn behind an object
while the player's feet are above that edge. Override with `{"sort_y": 229.0}` in the
hotspot's extra dict (used for the mug and drawer so they sit on top of the desk).
Things flat against the wall (doors, wall units) use `"sort_y": horizon_y` so the player is never
behind them. If an object can hide the player completely, keep that area out of `walk_poly`.

## Inventory icons: `assets/items/<item_id>.png`
32x32, transparent background, leave a 1-2px margin. The item id is the key in `ITEMS` in `scripts/game.gd`.
The bar holds 16 icons (2 rows of 8). The item's name shows in the action line while the mouse is over the icon.
Without an icon file, the button shows the first three letters of the name.

## Combining items
Recipes are in `COMBOS` in `scripts/game.gd`: key = the two item ids sorted alphabetically, joined with `+`.
Each has `result`, `text`, and an optional `keep` list of items that are not used up (do this for anything
a puzzle needs later, so a combo can't make the game unwinnable). In game: pick Use, click one item, then
click another. Click the selected item again to put it away. There are no recipes at the moment (`COMBOS` is empty).

## Obstacles
Solid furniture needs a footprint so the player walks around it, not through it. In the room's `_setup()`:
`obstacles.append(PackedVector2Array([Vector2(200, 170), Vector2(400, 170), Vector2(400, 228), Vector2(200, 228)]))`
Each footprint must be convex (a rectangle is fine) and may extend above the floor. The bottom edge should match
the object's sort line. F1 draws footprints in red.

## Player: `assets/characters/player.png`
Horizontal strip of 48x48 frames. Frame 0 = standing, frames 1..N = walk cycle
(plays at 8 fps). The character's feet and body center are at x=28, bottom edge
(the extra width on the left is for the tail; change `ANCHOR_X` in player.gd if you move it). Faces right; the game mirrors it for left.
The sprite is scaled by depth (0.55x at the back wall up to 1x at the front).

## Placeholder art
`python3 tools/make_placeholder_art.py` regenerates the current stand-in art (needs Pillow).
It overwrites files, so don't run it once you've replaced them with your own.

## Debug
Press **F1** in game to outline hotspots (yellow), walk-to points (cyan) and the floor (green).

## Audio: `assets/audio/`
`sfx/<name>.wav` (click, pickup, combine, error, door, unlock, beep, save, ending, blip) and
`music/<track>.wav` (title, explore, server). Replace any file (WAV, any length) and the game uses it;
music loops automatically. Play a sound with `Audio.play("name", pitch, volume_db)` and pick a room's
track in `ROOM_MUSIC` in `scripts/audio.gd`. `blip` is the dialogue text tick, pitched per speaker in
`BLIP_PITCH` in `scripts/dialogue_ui.gd`. `python3 tools/make_audio.py` regenerates the stand-ins
(it overwrites files, so don't run it after you've replaced them with your own).

## Server racks (`rack_a/b/c.png`)
72x150, drawn side by side with no gaps. The top 18x7 grid of LED sockets (3x3 px, 4px pitch, from (1,10))
and the blade sockets below are drawn dark in the art; `_after_art()` in `scripts/rooms/server.gd`
animates lights over them, so keep those positions if you redraw the racks.

## Dialogue: `assets/dialogue/<id>.txt`
Start one by adding `{"talk": "<id>"}` to a hotspot's extra dict (runs when the player uses Talk on it),
or call `await Game.talk("<id>")` from a room's `on_interact`. Example: `vending.txt`.

```
# comment
== start                      a node; every conversation begins at "start"
-> first [if !met_vending]     jump to node "first" if the flag is not set
Vending Machine: Hello.       a spoken line (Speaker: text). Click / Space / Enter to advance.
! set met_vending              commands: set <flag>, clear <flag>, give <item>, take <item>
* Ask about snacks -> snacks   a choice; shown after the node's lines, jumps to node "snacks"
* Got a keycard -> kc [if has:keycard] [once]
* Bye -> end                   "end" finishes the conversation
```
- Conditions: `flag`, `!flag`, `has:item`, `!has:item` (any number of `[if ...]`).
- `[once]` hides a choice after it has been picked.
- Choices appear in the bottom bar (max 4, about 70 characters each) and are also spoken by the monkey.
  Number keys 1-4 pick them too.
- Spoken lines show at the top of the room: the box grows to fit, so keep them to about 3 lines (roughly 150 characters).
- Speaker colors are in `SPEAKER_COLORS` in `scripts/dialogue_ui.gd`.
- In an exported build, add `*.txt` to the export's "Filters to export non-resource files".
