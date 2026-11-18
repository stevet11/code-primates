#!/usr/bin/env python3
"""Synthesizes all game audio into assets/audio/ (chiptune sound effects and music loops).
Pure Python, no dependencies. Run from the project root:  python3 tools/make_audio.py
Replace any generated file with your own (same name) and the game will use it.
"""
import math, os, random, struct, wave

SR = 22050
OUT = os.path.join("assets", "audio")


# ---------------------------------------------------------------- basics
def midi_freq(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


PC = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def parse_note(s):
    """'F#5' -> midi number."""
    pc = PC[s[0]]
    i = 1
    if s[i] in "#b":
        pc += 1 if s[i] == "#" else -1
        i += 1
    return 12 * (int(s[i:]) + 1) + pc


def chord_pcs(name):
    """'Cm' -> (root pitch class, [intervals]); 'Ab' -> major triad."""
    root = PC[name[0]]
    i = 1
    if len(name) > i and name[i] in "#b":
        root += 1 if name[i] == "#" else -1
        i += 1
    minor = name[i:] == "m"
    return root % 12, [0, 3, 7] if minor else [0, 4, 7]


def wave_at(kind, ph, duty):
    if kind == "square":
        return 1.0 if ph < duty else -1.0
    if kind == "tri":
        return 4.0 * abs(ph - 0.5) - 1.0
    if kind == "saw":
        return 2.0 * ph - 1.0
    raise ValueError(kind)


def tone(kind, freq, dur, vol=1.0, duty=0.5, att=0.004, dec=0.0, sus=1.0, rel=0.012,
         vib=0.0, sweep_to=None):
    """One note as a list of floats. dec>0: exponential decay (seconds) down to `sus`."""
    n = int(dur * SR)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = freq if sweep_to is None else freq + (sweep_to - freq) * (i / max(1, n - 1))
        if vib:
            f *= 1.0 + 0.012 * math.sin(2 * math.pi * 5.5 * t) * min(1.0, t / 0.25)
        ph = (ph + f / SR) % 1.0
        env = min(1.0, t / att)
        if dec > 0:
            env *= sus + (1.0 - sus) * math.exp(-t / dec)
        left = dur - t
        if left < rel:
            env *= left / rel
        out.append(wave_at(kind, ph, duty) * env * vol)
    return out


def noise(dur, vol=1.0, dec=0.03, hp=False, seed=1):
    rng = random.Random(seed)
    n = int(dur * SR)
    out = []
    prev = 0.0
    for i in range(n):
        x = rng.uniform(-1, 1)
        v = (x - prev) * 0.5 if hp else x
        prev = x
        out.append(v * vol * math.exp(-(i / SR) / dec))
    return out


def kick(vol=1.0):
    n = int(0.16 * SR)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = 45 + 110 * math.exp(-t / 0.03)
        ph += f / SR
        out.append(math.sin(2 * math.pi * ph) * math.exp(-t / 0.07) * vol)
    return out


def snare(vol=1.0):
    nz = noise(0.11, vol * 0.8, 0.04, seed=3)
    tn = tone("tri", 190, 0.11, vol * 0.5, dec=0.03)
    return [a + b for a, b in zip(nz, tn)]


def hat(vol=1.0, long=False):
    return noise(0.09 if long else 0.03, vol, 0.03 if long else 0.01, hp=True, seed=7)


def seq(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def mix_into(buf, start, samples):
    for i, v in enumerate(samples):
        j = start + i
        if j < len(buf):
            buf[j] += v


def save_wav(path, samples, peak=0.85):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    m = max(abs(s) for s in samples) or 1.0
    k = peak / m
    data = struct.pack("<%dh" % len(samples), *[int(max(-1.0, min(1.0, s * k)) * 32767) for s in samples])
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print("  %-34s %5.2fs" % (path, len(samples) / SR))


# ---------------------------------------------------------------- sound effects
def slide_door(opening, dur=0.5):
    """An original sliding-door whoosh (not a recording of anything): airy noise that swells while a soft
    tone sweeps up (opening) or down (closing), then a low thump when the door stops."""
    n = int(dur * SR)
    rng = random.Random(21 if opening else 22)
    out, prev, lp, ph = [], 0.0, 0.0, 0.0
    for i in range(n):
        t = i / n
        env = math.sin(math.pi * min(1.0, t * 1.1)) ** 1.5      # swell up and down
        x = rng.uniform(-1, 1)
        lp += (x - lp) * (0.25 + 0.4 * (t if opening else 1 - t))  # brighter as it goes (or dulls when closing)
        prev = x
        f = (260 + 700 * t) if opening else (960 - 700 * t)
        ph = (ph + f / SR) % 1.0
        out.append((lp * 0.55 + (4.0 * abs(ph - 0.5) - 1.0) * 0.18) * env)
    thump = []
    for i in range(int(0.14 * SR)):
        tt = i / SR
        thump.append(math.sin(2 * math.pi * (70 + 50 * math.exp(-tt / 0.03)) * tt) * math.exp(-tt / 0.05) * 0.8)
    return out + thump


def make_sfx(only=None):
    d = os.path.join(OUT, "sfx")
    n = lambda m: midi_freq(parse_note(m))
    sfx = {
        # short UI tick
        "click": tone("square", 1500, 0.035, 0.6, duty=0.25, dec=0.012, sweep_to=900),
        # rising arpeggio: got an item
        "pickup": seq(*[tone("square", n(x), 0.055, 0.5, duty=0.25, dec=0.05, sus=0.4)
                        for x in ("C5", "E5", "G5", "C6")], tone("square", n("E6"), 0.16, 0.5, duty=0.25, dec=0.1)),
        # two things made one
        "combine": seq(tone("square", n("G4"), 0.07, 0.5, duty=0.5, dec=0.06, sus=0.3),
                       tone("square", n("C5"), 0.07, 0.5, duty=0.5, dec=0.06, sus=0.3),
                       [a + b for a, b in zip(tone("square", n("E5"), 0.28, 0.45, duty=0.25, dec=0.15, sus=0.2),
                                              tone("tri", n("E4"), 0.28, 0.5))]),
        # "no"
        "error": seq(tone("square", 150, 0.09, 0.6, duty=0.5, dec=0.1, sweep_to=110),
                     [0.0] * int(0.03 * SR), tone("square", 120, 0.14, 0.6, duty=0.5, dec=0.12, sweep_to=80)),
        # door / room change: a quick downward whoosh
        "door": [a + b for a, b in zip(tone("tri", 420, 0.28, 0.5, dec=0.2, sweep_to=110),
                                       noise(0.28, 0.25, 0.1, seed=5))],
        # lock opening: tick tick, then a bright chime
        "unlock": seq(tone("square", 2200, 0.02, 0.6, duty=0.125, dec=0.01), [0.0] * int(0.07 * SR),
                      tone("square", 1700, 0.02, 0.6, duty=0.125, dec=0.01), [0.0] * int(0.09 * SR),
                      tone("square", n("G5"), 0.07, 0.45, duty=0.25, dec=0.05, sus=0.4),
                      tone("square", n("C6"), 0.22, 0.45, duty=0.25, dec=0.12, sus=0.3)),
        # elevator doors: sliding whoosh with a soft thump at the end
        "slide_open": slide_door(True),
        "slide_close": slide_door(False),
        # a plain beep (also used for the light show, pitched up/down)
        "beep": tone("square", 880, 0.11, 0.55, duty=0.5, dec=0.08, sus=0.5),
        # game saved: soft chime
        "save": seq(tone("tri", n("E5"), 0.09, 0.8, dec=0.08, sus=0.3), tone("tri", n("B5"), 0.3, 0.8, dec=0.18, sus=0.2)),
        # the ending: little fanfare
        "ending": seq(*[tone("square", n(x), l, 0.5, duty=0.25, dec=0.2, sus=0.5)
                        for x, l in (("C5", 0.11), ("C5", 0.11), ("C5", 0.11), ("G5", 0.3), ("E5", 0.11), ("G5", 0.11),
                                     ("C6", 0.6))]),
        # one tick of dialogue text; the game pitches it per speaker
        "blip": tone("square", 520, 0.045, 0.55, duty=0.25, dec=0.04, sus=0.3),
    }
    print("sound effects:")
    for name, s in sfx.items():
        if only is None or name in only:
            save_wav(os.path.join(d, name + ".wav"), s)


# ---------------------------------------------------------------- music
def bar_events(tokens, step0):
    """'G4:2 -:2 C5:4' -> [(step, midi, length)] starting at step0 (16th-note steps)."""
    ev, s = [], step0
    for tok in tokens.split():
        name, ln = tok.split(":")
        ln = int(ln)
        if name != "-":
            ev.append((s, parse_note(name), ln))
        s += ln
    return ev


BASS = {
    "walk": [(0, 0, 2), (2, 12, 2), (4, 0, 2), (6, 7, 2), (8, 0, 2), (10, 12, 2), (12, 0, 2), (14, 7, 2)],
    "easy": [(0, 0, 3), (4, 7, 3), (8, 12, 3), (12, 7, 3)],
    "drive": [(0, 0, 2), (2, 0, 2), (4, 0, 2), (6, 12, 2), (8, 0, 2), (10, 0, 2), (12, 0, 2), (14, 12, 2)],
}
DRUMS = {
    "rock": dict(kick=[0, 8], snare=[4, 12], hat=range(0, 16, 2)),
    "soft": dict(kick=[0, 10], snare=[4, 12], hat=range(2, 16, 4), snare_vol=0.35, hat_vol=0.5, kick_vol=0.7),
    "four": dict(kick=[0, 4, 8, 12], snare=[4, 12], hat=range(16), hat_vol=0.9),
}


def render_track(spec):
    step = 60.0 / spec["bpm"] / 4.0
    spb = int(step * SR)  # samples per 16th step
    bars = spec["chords"]
    passes = spec.get("passes", [dict(lead=True, arp=spec.get("arp", True))])
    total_steps = 16 * len(bars) * len(passes)
    tail = int(1.0 * SR)
    buf = [0.0] * (total_steps * spb + tail)
    drums = DRUMS[spec["drums"]]
    bass_pat = BASS[spec["bass"]]
    for p, ps in enumerate(passes):
        for b, chord in enumerate(bars):
            s0 = (p * len(bars) + b) * 16
            root, ivs = chord_pcs(chord)
            # lead
            if ps.get("lead", True):
                for st, m, ln in bar_events(spec["melody"][b], s0):
                    mix_into(buf, st * spb, tone("square", midi_freq(m + ps.get("lead_shift", 0)),
                                                 ln * step * 0.92, spec.get("lead_vol", 0.30),
                                                 duty=ps.get("duty", spec.get("duty", 0.5)), dec=0.35, sus=0.55, vib=1.0))
            # bass (triangle)
            for st, iv, ln in bass_pat:
                mix_into(buf, (s0 + st) * spb, tone("tri", midi_freq(36 + root + iv), ln * step * 0.9, 0.42))
            # arpeggio (thin pulse)
            if ps.get("arp", True):
                tones = [48 + root + iv for iv in ivs] + [60 + root]
                for st in range(16):
                    m = tones[st % 4] + 12
                    mix_into(buf, (s0 + st) * spb, tone("square", midi_freq(m), step * 0.8, spec.get("arp_vol", 0.085),
                                                        duty=0.125, dec=0.06, sus=0.3))
            # drums
            for st in drums["kick"]:
                mix_into(buf, (s0 + st) * spb, kick(0.55 * drums.get("kick_vol", 1.0)))
            for st in drums["snare"]:
                mix_into(buf, (s0 + st) * spb, snare(0.35 * drums.get("snare_vol", 1.0)))
            for st in drums["hat"]:
                accent = 1.0 if st % 4 == 0 else 0.6
                mix_into(buf, (s0 + st) * spb, hat(0.10 * accent * drums.get("hat_vol", 1.0)))
    # fold the tail back onto the start so the loop is seamless
    body = total_steps * spb
    for i in range(tail):
        buf[i] += buf[body + i]
    return buf[:body]


TRACKS = {
    # C minor, playful. Pass 1: melody + bass; pass 2: adds the arpeggio and a thinner lead.
    "title": dict(
        bpm=112, bass="walk", drums="rock", duty=0.5, lead_vol=0.28,
        passes=[dict(lead=True, arp=False, duty=0.5), dict(lead=True, arp=True, duty=0.25)],
        chords=["Cm", "Ab", "Eb", "Bb", "Cm", "Ab", "Bb", "G"],
        melody=["G4:2 C5:2 Eb5:4 D5:2 C5:2 Bb4:4", "C5:2 Eb5:2 Ab5:4 G5:2 Eb5:2 C5:4",
                "Bb4:2 Eb5:2 G5:4 F5:2 Eb5:2 D5:4", "D5:2 F5:2 Bb5:4 A5:2 F5:2 D5:4",
                "G5:4 Eb5:2 G5:2 C6:4 Bb5:4", "Ab5:4 Eb5:2 C5:2 Ab4:4 C5:4",
                "D5:2 F5:2 Bb5:2 D6:2 C6:4 Bb5:2 F5:2", "B4:2 D5:2 G5:4 F5:2 D5:2 B4:4"]),
    # F major, easy-going: for the office and hallway. 16 bars, two sections.
    "explore": dict(
        bpm=104, bass="easy", drums="soft", duty=0.25, lead_vol=0.26, arp_vol=0.07,
        chords=["F", "Dm", "Bb", "C", "F", "Am", "Bb", "C", "Gm", "C", "F", "Dm", "Bb", "C", "Dm", "C"],
        melody=["A4:4 C5:2 F5:2 E5:4 C5:4", "D5:4 A4:2 D5:2 F5:4 E5:2 D5:2",
                "D5:4 F5:2 Bb5:2 A5:4 F5:4", "G5:4 E5:2 C5:2 D5:4 E5:4",
                "C5:2 F5:2 A5:4 G5:2 F5:2 E5:4", "E5:4 A5:4 G5:2 E5:2 C5:4",
                "D5:2 F5:2 Bb5:4 C6:4 A5:4", "G5:4 E5:4 D5:4 C5:2 -:2",
                "Bb4:4 D5:2 G5:2 F5:4 D5:4", "E5:4 G5:2 C6:2 Bb5:4 G5:4",
                "A5:4 F5:2 C5:2 F5:8", "F5:4 A5:2 D6:2 C6:4 A5:4",
                "Bb5:4 F5:2 D5:2 F5:4 Bb4:4", "C5:2 E5:2 G5:4 E5:2 C5:2 G4:4",
                "D5:4 F5:4 A5:4 G5:2 F5:2", "E5:4 G5:4 C6:4 -:4"]),
    # E minor, tense and techy: for the server room. Pass 1 is the groove alone, pass 2 adds the lead.
    "server": dict(
        bpm=128, bass="drive", drums="four", duty=0.125, lead_vol=0.24, arp_vol=0.10,
        passes=[dict(lead=False, arp=True), dict(lead=True, arp=True)],
        chords=["Em", "Em", "C", "D", "Em", "Em", "Am", "B"],
        melody=["E5:1 -:1 E5:1 -:1 G5:2 -:2 B5:2 -:2 A5:1 -:1 G5:1 -:1",
                "E5:1 -:1 E5:1 -:1 B5:2 -:2 G5:2 -:2 F#5:2 -:2",
                "G5:1 -:1 G5:1 -:1 E5:2 -:2 C5:2 -:2 E5:2 -:2",
                "A5:1 -:1 A5:1 -:1 F#5:2 -:2 D5:2 -:2 F#5:2 -:2",
                "B5:2 -:2 G5:2 -:2 E5:2 -:2 G5:2 -:2",
                "B5:1 -:1 B5:1 -:1 E6:4 -:4 D6:2 -:2",
                "C6:2 -:2 A5:2 -:2 E5:2 -:2 A5:2 -:2",
                "D#6:2 -:2 B5:2 -:2 F#5:2 -:2 D#5:2 -:2"]),
    # A minor, slow and a little spooky: the basement, the IT lab and the closet.
    "basement": dict(
        bpm=80, bass="easy", drums="soft", duty=0.125, lead_vol=0.20, arp=False,
        chords=["Am", "F", "Dm", "E", "Am", "F", "E", "Am"],
        melody=["A4:4 -:4 E5:4 -:4", "F5:4 -:4 C5:4 -:4", "D5:4 -:2 F5:2 A4:4 -:4", "G#4:4 -:4 B4:4 -:4",
                "A4:2 C5:2 E5:4 D5:4 C5:4", "C5:4 A4:4 F4:8", "B4:4 G#4:4 E4:8", "A4:8 -:8"]),
    # C major, smooth lounge: the lobby and the break room.
    "lobby": dict(
        bpm=92, bass="easy", drums="soft", duty=0.5, lead_vol=0.22, arp_vol=0.06,
        chords=["C", "Am", "F", "G", "C", "Em", "F", "G"],
        melody=["E5:4 G5:2 E5:2 C5:4 -:4", "A4:4 C5:2 E5:2 A5:4 G5:4", "F5:4 A5:2 F5:2 C5:4 -:4",
                "G5:4 B4:2 D5:2 G5:4 F5:4", "E5:2 G5:2 C6:4 B5:2 G5:2 E5:4", "G5:4 E5:4 B4:4 E5:4",
                "A5:4 F5:2 C5:2 F5:4 A4:4", "G5:2 F5:2 E5:2 D5:2 C5:8"]),
    # D minor, corporate-smooth: the 3rd floor, where the executives are.
    "executive": dict(
        bpm=96, bass="walk", drums="soft", duty=0.25, lead_vol=0.22, arp_vol=0.06,
        chords=["Dm", "Bb", "F", "C", "Dm", "Gm", "A", "Dm"],
        melody=["F5:4 A5:2 F5:2 D5:4 -:4", "D5:4 F5:2 Bb5:2 A5:4 F5:4", "C5:4 F5:2 A5:2 G5:4 F5:4",
                "E5:4 G5:2 C6:2 Bb5:4 G5:4", "D5:2 F5:2 A5:4 G5:2 F5:2 D5:4", "G5:4 Bb5:4 A5:4 F5:4",
                "E5:4 A5:4 C#6:4 A5:4", "D5:8 -:8"]),
}


def make_music():
    print("music:")
    for name, spec in TRACKS.items():
        for b, m in enumerate(spec["melody"]):  # sanity check: every bar is 16 steps
            assert sum(int(t.split(":")[1]) for t in m.split()) == 16, (name, b + 1)
        assert len(spec["melody"]) == len(spec["chords"]) or len(spec["melody"]) * 1 == len(spec["chords"]), name
        save_wav(os.path.join(OUT, "music", name + ".wav"), render_track(spec), peak=0.8)


# ---------------------------------------------------------------- ambience (quiet looping room tones)
AMB_SECONDS = 8


def lowpass(x, k):
    out, y = [], 0.0
    for v in x:
        y += (v - y) * k
        out.append(y)
    return out


def loopable(buf, fade=0.5):
    """Folds the last `fade` seconds onto the start so the loop has no seam."""
    n = int(fade * SR)
    body = len(buf) - n
    out = buf[:body]
    for i in range(n):
        t = i / n
        out[i] = out[i] * t + buf[body + i] * (1 - t)
    return out


def hum(freq, vol, wobble=0.0, seconds=AMB_SECONDS):
    """A steady sine hum; `freq` should be a whole number so it loops."""
    return [vol * math.sin(2 * math.pi * freq * i / SR) * (1 + wobble * math.sin(2 * math.pi * i / SR / seconds))
            for i in range(int(seconds * SR))]


def air(vol, k, seed, seconds=AMB_SECONDS + 0.5):
    rng = random.Random(seed)
    return loopable([v * vol for v in lowpass([rng.uniform(-1, 1) for _ in range(int(seconds * SR))], k)])


def drip(freq=1700, dec=0.05, vol=0.6):
    n = int(0.25 * SR)
    return [vol * math.sin(2 * math.pi * (freq * (0.55 + 0.45 * math.exp(-(i / SR) / 0.02))) * (i / SR))
            * math.exp(-(i / SR) / dec) for i in range(n)]


def blip_gurgle(vol=0.5):
    n = int(0.35 * SR)
    out = []
    for i in range(n):
        t = i / SR
        f = 220 + 380 * math.exp(-t / 0.08)
        out.append(vol * math.sin(2 * math.pi * f * t) * math.exp(-t / 0.09))
    return out


def place(buf, events, samples_for):
    for sec, *args in events:
        mix_into(buf, int(sec * SR), samples_for(*args))
    return buf


def amb_office():
    n = AMB_SECONDS * SR
    b = [a + c + d for a, c, d in zip(hum(100, 0.10, 0.2), hum(200, 0.04, 0.3), air(0.18, 0.05, 3)[:n])]
    return b


def amb_breakroom():
    b = [a + c for a, c in zip(hum(60, 0.16, 0.3), hum(120, 0.06))]
    place(b, [(1.2, 0.5), (4.9, 0.4), (6.3, 0.3)], blip_gurgle)       # the water cooler, bubbling
    return b


def amb_basement():
    b = [a + c for a, c in zip(hum(55, 0.16, 0.4), air(0.22, 0.015, 9)[:AMB_SECONDS * SR])]
    place(b, [(0.9, 1700, 0.05, 0.5), (3.4, 1300, 0.06, 0.4), (5.2, 1900, 0.04, 0.45), (7.0, 1500, 0.05, 0.35)], drip)
    place(b, [(1.1, 1700, 0.05, 0.18), (3.6, 1300, 0.06, 0.15), (5.4, 1900, 0.04, 0.16), (7.2, 1500, 0.05, 0.12)], drip)  # echoes
    return b


def amb_lobby():
    return [a + c for a, c in zip(air(0.35, 0.03, 21)[:AMB_SECONDS * SR], hum(80, 0.05, 0.4))]   # air conditioning


def amb_it():
    n = AMB_SECONDS * SR
    return [a + c + d for a, c, d in zip(air(0.30, 0.12, 5)[:n], hum(120, 0.08, 0.2), hum(240, 0.03))]   # server fans


AMBIENCE = {"amb_office": amb_office, "amb_breakroom": amb_breakroom, "amb_basement": amb_basement,
            "amb_lobby": amb_lobby, "amb_it": amb_it}


def make_ambience(only=None):
    print("ambience:")
    for name, fn in AMBIENCE.items():
        if only is None or name in only:
            save_wav(os.path.join(OUT, "ambience", name + ".wav"), fn(), peak=0.5)



if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "ambience":  # `python3 tools/make_audio.py ambience`: only the room tones
        make_ambience()
    elif len(sys.argv) > 1 and sys.argv[1] == "music":   # only the music (all tracks)
        make_music()
    elif len(sys.argv) > 1:  # e.g. `python3 tools/make_audio.py slide_open slide_close`: only those effects
        make_sfx(only=sys.argv[1:])
    else:
        make_sfx()
        make_music()
        make_ambience()
