# Code Primates: development notes

Godot 4 (built with 4.7.x; the project was written for 4.3+), GDScript only. Everything in `assets/` is generated
by scripts in `tools/` (pure Python, plus Pillow for the art), and any file can be replaced with real art or audio of
the same name.

Spoilers: `tools/playthrough.gd` plays the entire game, so it contains the full solution (see `SPOILERS.md`).

## Run, test, build
- Run: open the folder in Godot and press F5, or `godot --path .`
- Debug keys: F1 shows hotspots and the walkable floor, F2 plays the server room light show, F5 / F9 quick save / load.
- `godot --headless --path . -s tools/playthrough.gd`: plays every puzzle and dialogue (about 30 seconds; never writes saves).
- `godot --headless --path . -s tools/check_rooms.gd`: sprite sizes, missing art, walk points, exits and spawns, doors covered by
  other objects, and things drawn behind what they sit on.
- `godot --path . -s tools/screenshots.gd`: regenerates `docs/screenshots/` (needs a display; opens a window for a few seconds).
- `./build.sh` builds `build/` zips for Linux and Windows (needs the matching Godot export templates). The preset keeps the
  dialogue `.txt` files (`include_filter`), which Godot would otherwise leave out of an export.

## Layout
- `scripts/game.gd`: autoload. Verb, inventory, story flags, items, the Notes list, the coffee and tail logic.
- `scripts/room.gd`: base room: hotspots, floor polygon, depth scaling, auto-opening doors.
- `scripts/rooms/`: one script per room (override `_setup` and `on_interact`). `corridor.gd` is the base for the elevator-served floors.
- `scripts/player.gd`: the monkey. `scripts/ui.gd`: verb bar, message line, inventory, ending card and credits roll.
- `scripts/menu_ui.gd`: title screen, pause, Notes, Help, credits, save/load lists. `scripts/saves.gd` does the file I/O.
- `scripts/audio.gd`: autoload `Audio`: effects, music crossfades, room tones, settings.
- `scripts/blinkers.gd`, `scripts/light_show.gd`: blinking LEDs and the server room light show.
- `assets/dialogue/*.txt`: conversations (format in `assets/README.md`). `assets/rooms/<room>/`: backgrounds and hotspot sprites.

## Saves
3 manual slots plus an autosave (written whenever you change rooms), as JSON in Godot's user folder:
`~/.local/share/godot/app_userdata/Code Primates/saves/` on Linux, `%APPDATA%\Godot\app_userdata\Code Primates\saves\` on Windows.
They store the room, position, inventory and story flags, so new puzzle state belongs in `Game.flags` (via `Game.set_flag`).
Scripts in `tools/` set `Saves.disabled = true` so they never touch real saves.

## Art and audio
- `python3 tools/make_placeholder_art.py` (Pillow): all art. Add `icons`, `backgrounds`, `doors`, `objects`, `floors` or `more` to run one part.
  Art sizes and naming are in `assets/README.md`.
- `python3 tools/make_audio.py`: all sound effects, music loops and room tones. Add `music`, `ambience`, or sfx names to run part.
  Music per room is in `ROOM_MUSIC` and room tones in `ROOM_AMBIENCE`, both in `scripts/audio.gd`.
- Music and sound effects switch off separately under Options ("Sound effects" also switches off the room tones).

## Credits and licenses
See the README. The font is VT323 (SIL Open Font License, `assets/fonts/OFL.txt`).
