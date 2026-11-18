#!/usr/bin/env python3
"""Generates placeholder pixel art into assets/. Replace any file with real art
(same name and size) and the game picks it up. Needs Pillow.
Run from the project root:  python3 tools/make_placeholder_art.py [--preview out.png]
"""
import math, os, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 640, 288  # room area
C = {k: "#" + v for k, v in dict(
    dark="1a1c2c", purple="5d275d", red="b13e53", orange="ef7d57", yellow="ffcd75",
    lgreen="a7f070", green="38b764", dgreen="257179", navy="29366f", blue="3b5dc9",
    lblue="41a6f6", cyan="73eff7", white="f4f4f4", lgrey="94b0c2", grey="566c86",
    dgrey="333c57", brown="8b5a2b", dbrown="5c3a1a", tan="c8905a", fur="73400d").items()}


def box(d, x0, y0, x1, y1, fill, outline=None):
    """Rectangle covering pixels x0..x1-1, y0..y1-1."""
    d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=fill, outline=outline)


def new(w, h, bg=(0, 0, 0, 0)):
    im = Image.new("RGBA", (w, h), bg)
    return im, ImageDraw.Draw(im)


def save(im, *parts):
    path = os.path.join("assets", *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path)


def floor(d, y0, y1, c1, c2):
    box(d, 0, y0, W, y1, c1)
    y, step = y0 + 2, 5
    while y < y1:  # rows get farther apart toward the viewer
        d.line([0, y, W, y], fill=c2)
        y += step
        step += 3
    for i in range(-14, 15):  # boards fan out from a vanishing point
        d.line([320 + i * 14, y0, 320 + i * 62, y1], fill=c2)


def wall_panels(d, y1, base, dark, step=80):
    box(d, 0, 0, W, y1, base)
    for x in range(0, W, step):
        box(d, x, 0, x + 2, y1, dark)
    box(d, 0, 0, W, 6, dark)


def wainscot(d, y0, y1, base, rail, dark):
    box(d, 0, y0, W, y1, base)
    box(d, 0, y0, W, y0 + 4, rail)
    box(d, 0, y0 + 4, W, y0 + 6, dark)
    for x in range(0, W, 80):
        box(d, x, y0 + 8, x + 2, y1, dark)
    box(d, 0, y1 - 4, W, y1, dark)  # baseboard


def office_bg():
    im, d = new(W, H)
    wall_panels(d, 192, C["purple"], "#4a1f4a")
    wainscot(d, 150, 192, "#4f2050", C["red"], C["dark"])
    # window
    box(d, 246, 30, 394, 130, C["lgrey"])
    box(d, 252, 36, 388, 124, C["navy"])
    for x, y in [(262, 46), (300, 58), (340, 44), (372, 70), (276, 80)]:
        box(d, x, y, x + 2, y + 2, C["white"])
    d.ellipse([350, 48, 372, 70], fill=C["yellow"])
    for x, hh in [(254, 30), (280, 52), (306, 38), (330, 60), (356, 34), (372, 46)]:
        box(d, x, 124 - hh, x + 20, 124, C["dark"])
        for wy in range(124 - hh + 6, 120, 10):
            box(d, x + 5, wy, x + 8, wy + 3, C["yellow"])
    box(d, 316, 36, 322, 124, C["lgrey"])
    box(d, 252, 78, 388, 84, C["lgrey"])
    box(d, 240, 130, 400, 138, C["grey"])
    floor(d, 192, 288, C["navy"], "#22306b")
    return im


def hallway_bg():
    im, d = new(W, H)
    wall_panels(d, 180, C["dgreen"], "#1d5c64", 128)
    wainscot(d, 138, 180, "#1f6a73", C["green"], C["dark"])
    for x in (80, 300, 520):  # ceiling lights
        box(d, x, 0, x + 70, 10, C["white"])
        box(d, x - 8, 10, x + 78, 14, "#a7d9d0")
    box(d, 300, 28, 340, 44, C["green"])  # exit sign
    box(d, 304, 32, 336, 40, C["lgreen"])
    floor(d, 180, 288, C["dgrey"], "#2a3248")
    return im


def door(w=80, h=120, state=""):
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"])
    box(d, 3, 3, w - 3, h, C["grey"])
    box(d, w - 8, 3, w - 3, h, C["dgrey"])
    box(d, 12, 12, w - 14, 50, C["dgrey"])
    box(d, 15, 15, w - 17, 47, C["cyan"] if state == "" else C["lblue"])
    box(d, 15, 15, w // 2, 22, C["white"])
    box(d, 12, 62, w - 14, h - 10, C["dgrey"])
    box(d, 15, 65, w - 17, h - 13, "#667c96")
    box(d, w - 24, 66 + 12, w - 16, 84 + 12, C["yellow"])
    return im


def vending():
    w, h = 80, 124
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"])
    box(d, 3, 3, w - 3, h, C["red"])
    box(d, 3, 3, 8, h, "#c9566a")
    box(d, 8, 10, 56, 90, C["dark"])
    box(d, 10, 12, 54, 88, "#1f2b44")
    for r in range(4):
        y = 16 + r * 18
        box(d, 10, y + 14, 54, y + 16, C["lgrey"])
        for c in range(4):
            col = [C["yellow"], C["orange"], C["lgreen"], C["lblue"]][(r + c) % 4]
            if r == 3 and c != 1:
                continue  # nearly empty, as the joke says
            box(d, 13 + c * 10, y + 4, 21 + c * 10, y + 14, col)
    box(d, 62, 14, 74, 44, C["dgrey"])
    for r in range(3):
        box(d, 65, 18 + r * 9, 71, 23 + r * 9, C["yellow"])
    box(d, 62, 52, 74, 58, C["dark"])  # coin slot
    box(d, 8, 98, 70, 116, C["dark"])  # pickup flap
    box(d, 10, 100, 68, 114, "#7a2a38")
    return im


def lab_door(state=""):
    w, h = 100, 128
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"])
    if state == "open":
        box(d, 6, 8, w - 6, h, "#0f1f3a")
        for y in range(14, h, 10):
            box(d, 10, y, w - 10, y + 4, C["blue"])
        box(d, 6, 8, 14, h, C["dgrey"])
        box(d, w - 14, 8, w - 6, h, C["dgrey"])
        box(d, 40, 40, 60, 100, C["lblue"])
    else:
        box(d, 6, 8, w - 6, h, C["dgrey"])
        box(d, 10, 12, w // 2 - 2, h - 4, C["grey"])
        box(d, w // 2 + 2, 12, w - 10, h - 4, C["grey"])
        for y in range(20, h - 8, 16):
            box(d, 14, y, w // 2 - 6, y + 3, "#667c96")
            box(d, w // 2 + 6, y, w - 14, y + 3, "#667c96")
        box(d, 20, 22, 80, 40, C["dark"])
        try:
            f = ImageFont.truetype("assets/fonts/VT323.ttf", 16)
            d.text((29, 21), "SERVER", font=f, fill=C["lgreen"])
        except OSError:
            box(d, 26, 28, 74, 34, C["lgreen"])
        box(d, 42, 54, 58, 74, C["dark"])  # card reader
        box(d, 46, 58, 54, 62, C["red"])
    return im


def poster():
    w, h = 80, 100
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"])
    box(d, 3, 3, w - 3, h - 3, C["red"])
    box(d, 8, 8, w - 8, h - 8, C["yellow"])
    box(d, 14, 14, w - 14, 56, C["fur"])  # monkey face
    box(d, 24, 24, w - 24, 50, C["tan"])
    box(d, 30, 30, 36, 38, C["dark"]); box(d, 44, 30, 50, 38, C["dark"])
    box(d, 34, 44, 46, 47, C["dark"])
    for i, wd in enumerate((52, 40, 46)):
        box(d, 14, 62 + i * 9, 14 + wd, 67 + i * 9, C["dark"])
    return im


def desk():
    w, h = 200, 60
    im, d = new(w, h)
    box(d, 0, 0, w, 14, C["dbrown"])
    box(d, 2, 2, w - 2, 12, C["tan"])
    box(d, 0, 14, w, h, C["dbrown"])
    box(d, 4, 14, w - 4, h - 2, C["brown"])
    box(d, 4, 14, w - 4, 18, "#6b4320")
    box(d, 100, 28, 160, 54, "#4d3015")  # recess behind the drawer
    box(d, 8, 22, 90, 50, "#7b4f25")     # side panel
    box(d, 0, h - 4, 12, h, C["dark"]); box(d, w - 12, h - 4, w, h, C["dark"])
    return im


def mug():
    w, h = 20, 18
    im, d = new(w, h)
    box(d, 2, 2, 16, 18, C["dark"])
    box(d, 4, 4, 14, 16, C["white"])
    box(d, 4, 4, 14, 8, "#e6e8f0")   # empty: nothing in it
    box(d, 16, 6, 20, 14, C["dark"]); box(d, 16, 8, 18, 12, C["white"])
    return im


def clip_sprite():
    im, d = new(16, 10)
    d.line([(3, 7), (3, 2), (5, 1), (12, 1), (13, 3), (13, 7), (7, 7), (7, 4)], fill=C["lgrey"], width=1)
    return im


def drawer(state=""):
    w, h = 60, 24
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"])
    if state == "open":
        box(d, 2, 2, w - 2, h - 2, "#2a1a0a")
        box(d, 2, 2, w - 2, 5, C["dbrown"])
    else:
        box(d, 2, 2, w - 2, h - 2, C["brown"])
        box(d, 2, 2, w - 2, 5, "#a06f3a")
        box(d, 24, 9, 36, 14, C["yellow"])
        box(d, 28, 14, 32, 17, C["dark"])  # keyhole
    return im


def tail_points(bob):
    """Stem out from the hip, then an @-style spiral that stays clear of the body."""
    cx, cy = 8.0, 33.0 - bob
    pts = [(21.0, 37.0 - bob), (18.0, 40.0 - bob), (13.0, 40.0 - bob)]
    turns, r0, r1 = 1.0, 7.0, 3.0
    steps = 60
    for i in range(steps + 1):
        t = i / steps
        th = math.pi / 2 + t * turns * 2 * math.pi  # starts at the bottom, goes left, up, around
        r = r0 + (r1 - r0) * t
        pts.append((cx + r * math.cos(th), cy + r * math.sin(th)))
    return pts


def server_bg():
    im, d = new(W, H)
    rng = random.Random(5)
    box(d, 0, 0, W, 190, "#141a2e")
    for x in range(0, W, 40):                         # far-wall panel seams
        box(d, x, 20, x + 2, 190, "#0f1424")
    box(d, 0, 0, W, 16, "#0b0f1c")                    # ceiling cable tray
    box(d, 0, 16, W, 20, C["dgrey"])
    for x in (40, 140, 330, 470, 600):
        box(d, x, 20, x + 4, rng.randrange(40, 70), "#0b0f1c")
    # (the distant blinking lights are animated in code: see _after_art in scripts/rooms/server.gd)
    box(d, 0, 176, W, 190, "#0b0f1c")
    floor(d, 190, 288, "#1a2138", "#262f50")
    for x in range(560, 620, 8):                      # cable bundle on the right
        d.line([x, 20, x + rng.randrange(-8, 8), 130], fill=rng.choice([C["dark"], C["dgrey"], C["red"], C["blue"]]), width=3)
    return im


def rack(seed=1):
    """72x150. Racks sit side by side, so the 18x7 LED panels (pitch 4px) line up into one matrix.
    The game draws the lit LEDs on top of the unlit sockets drawn here."""
    im, d = new(72, 150)
    box(d, 0, 0, 72, 150, C["dark"])
    box(d, 1, 2, 72, 150, "#2a3248")
    box(d, 0, 6, 72, 42, "#0b0f1c")                             # LED panel recess
    for r in range(7):
        for c in range(18):
            box(d, 1 + c * 4, 10 + r * 4, 1 + c * 4 + 3, 10 + r * 4 + 3, "#16202a")
    for b in range(6):                                           # server blades
        y = 46 + b * 17
        box(d, 3, y, 70, y + 14, "#1a2036")
        box(d, 4, y + 1, 69, y + 2, "#3a4466")
        for j in range(5):
            box(d, 8 + j * 6, y + 5, 8 + j * 6 + 3, y + 8, "#1d2a2a")
        box(d, 44, y + 5, 66, y + 9, "#0b0f1c")
    return im


def dale_body():
    im, d = new(64, 88)
    box(d, 6, 32, 58, 88, C["dgrey"])                              # chair back
    box(d, 14, 40, 50, 86, C["blue"])                              # hoodie
    box(d, 14, 40, 50, 46, "#2d4cae")
    box(d, 24, 62, 40, 72, "#2d4cae")
    box(d, 8, 42, 16, 78, C["blue"]); box(d, 48, 42, 56, 78, C["blue"])   # long arms
    box(d, 6, 78, 16, 86, "#8b6a45"); box(d, 48, 78, 58, 86, "#8b6a45")  # hands
    box(d, 12, 2, 52, 14, C["blue"])                               # hood
    box(d, 16, 8, 48, 38, "#b8935f")                               # head
    hair = "#d3d8de"                                               # grey hair under the hood
    box(d, 16, 8, 48, 15, hair)
    box(d, 14, 11, 17, 27, hair); box(d, 47, 11, 50, 27, hair)     # side tufts
    box(d, 21, 15, 27, 18, hair); box(d, 36, 15, 41, 18, hair)     # a messy fringe
    box(d, 18, 9, 20, 14, "#9aa3ae"); box(d, 33, 9, 35, 13, "#9aa3ae"); box(d, 43, 9, 45, 14, "#9aa3ae")
    box(d, 19, 15, 45, 33, "#d9bf90")                              # face
    box(d, 21, 17, 29, 25, "#4a3520"); box(d, 35, 17, 43, 25, "#4a3520")  # eye patches
    box(d, 23, 21, 27, 22, C["white"]); box(d, 37, 21, 41, 22, C["white"])  # sleepy eyes
    box(d, 30, 25, 34, 28, C["dark"])                              # nose
    frame = "#e0a84a"                                              # reading glasses, low on the nose
    box(d, 20, 18, 30, 28, None, frame); box(d, 34, 18, 44, 28, None, frame)
    box(d, 30, 20, 34, 21, frame)                                  # bridge
    box(d, 17, 20, 20, 21, frame); box(d, 44, 20, 47, 21, frame)   # arms
    box(d, 22, 20, 24, 21, C["white"]); box(d, 36, 20, 38, 21, C["white"])  # glints
    grey, shade = "#d3d8de", "#9aa3ae"                             # sysadmin's grey beard
    box(d, 16, 22, 21, 36, grey); box(d, 43, 22, 48, 36, grey)     # sideburns
    box(d, 19, 30, 45, 38, grey)                                   # cheeks and jaw
    box(d, 22, 38, 42, 43, grey); box(d, 27, 43, 37, 47, grey)     # chin, a little pointy
    box(d, 25, 28, 39, 31, grey)                                   # moustache
    for x0, y0, y1 in ((21, 33, 39), (27, 39, 44), (33, 39, 45), (40, 33, 39)):
        box(d, x0, y0, x0 + 1, y1, shade)                          # a few darker strands
    box(d, 29, 32, 35, 33, "#4a3520")                              # slow smile, in the beard
    alpha = im.getchannel("A").filter(ImageFilter.MaxFilter(3))
    out = Image.new("RGBA", (64, 88), C["dark"])
    out.putalpha(alpha)
    out.alpha_composite(im)
    return out


def dale():
    """Dale at his console, wearing a pointy wizard hat: he is a sysadmin, after all. 64x122 (the hat adds 34px on top)."""
    body = dale_body()
    HAT = 34
    im = Image.new("RGBA", (64, 88 + HAT), (0, 0, 0, 0))
    im.alpha_composite(body, (0, HAT))
    hat, d = new(64, 88 + HAT)
    purple, light, gold = "#4a3a9a", "#6b5ac8", C["yellow"]
    d.ellipse([2, 34, 62, 48], fill="#33286e")                                     # the brim (seen from a bit above)
    d.ellipse([4, 33, 60, 45], fill=purple)
    d.polygon([(15, 40), (49, 40), (42, 22), (38, 10), (49, 3), (34, 5), (28, 20), (20, 32)], fill=purple)   # the cone, tip bent over
    d.polygon([(34, 5), (28, 20), (20, 32), (15, 40), (24, 40), (32, 24), (36, 10)], fill=light)             # the lit left side
    box(d, 15, 35, 49, 40, "#2a2060")                                              # the hatband
    box(d, 29, 34, 36, 41, gold); box(d, 31, 36, 34, 39, "#2a2060")                # a gold buckle
    for x, y in ((38, 22), (30, 15), (25, 28)):                                    # stars
        box(d, x, y, x + 2, y + 2, gold); box(d, x - 1, y + 1, x + 3, y + 2, gold)
    d.ellipse([39, 29, 46, 36], fill=gold); d.ellipse([41, 28, 48, 35], fill=purple)  # a crescent moon
    alpha = hat.getchannel("A").filter(ImageFilter.MaxFilter(3))                   # outline the hat like the rest
    outline = Image.new("RGBA", hat.size, C["dark"])
    outline.putalpha(alpha)
    outline.alpha_composite(hat)
    im.alpha_composite(outline)
    return im


def console():
    im, d = new(120, 84)
    box(d, 0, 50, 120, 84, C["dark"])
    box(d, 2, 52, 118, 82, C["brown"])
    box(d, 2, 52, 118, 58, C["tan"])
    box(d, 8, 60, 112, 64, "#6b4320")
    box(d, 28, 2, 102, 46, C["dark"])                              # monitor
    box(d, 31, 5, 99, 43, "#0f2b1d")
    try:
        f = ImageFont.truetype("assets/fonts/VT323.ttf", 14)
        d.text((35, 6), "INSERT", font=f, fill=C["lgreen"])
        d.text((35, 20), "MEDIA _", font=f, fill=C["lgreen"])
    except OSError:
        box(d, 35, 10, 80, 14, C["lgreen"])
    box(d, 58, 46, 72, 52, C["dgrey"])
    box(d, 36, 53, 94, 57, C["lgrey"])                             # keyboard
    box(d, 98, 44, 116, 54, C["dark"])                             # a USB port on the desk, with its little light
    box(d, 100, 47, 114, 51, C["lgrey"]); box(d, 102, 48, 112, 50, "#16171f")
    box(d, 104, 40, 108, 43, C["lgreen"])
    return im


def icon_paperclip():
    im, d = new(32, 32)
    clip = [(15, 19), (15, 10), (17, 8), (19, 10), (19, 24), (21, 26), (23, 24), (23, 8), (21, 5),
            (13, 5), (10, 8), (10, 23), (12, 26), (14, 24)]
    d.line(clip, fill=C["lgrey"], width=2)
    d.line([(10, 9), (10, 22)], fill=C["white"], width=1)       # shine on the long side
    alpha = im.getchannel("A").filter(ImageFilter.MaxFilter(3))   # 1px dark outline
    out = Image.new("RGBA", (32, 32), C["dark"])
    out.putalpha(alpha)
    out.alpha_composite(im)
    return out


def icon_keycard():
    im, d = new(32, 32)
    box(d, 3, 7, 29, 25, C["dark"])
    box(d, 4, 8, 28, 24, C["blue"])
    box(d, 4, 11, 28, 14, C["dark"])             # magnetic stripe
    box(d, 7, 16, 13, 21, C["yellow"])           # chip
    box(d, 9, 16, 11, 21, "#e0a84a")
    box(d, 16, 17, 25, 19, C["lblue"]); box(d, 16, 21, 22, 23, C["lblue"])
    box(d, 24, 9, 27, 11, C["lgreen"])           # status light
    return im


# ---------------------------------------------------------------- inventory icons (32x32)
def outlined(im):
    """Adds a 1px dark outline around whatever is drawn (same look as the first icons)."""
    alpha = im.getchannel("A").filter(ImageFilter.MaxFilter(3))
    out = Image.new("RGBA", im.size, C["dark"])
    out.putalpha(alpha)
    out.alpha_composite(im)
    return out


def draw_carafe(fill=None, w=34, h=40):
    """A glass coffee carafe: dark lid, glass neck and widening body with measure lines, a black handle, and
    (optionally) liquid in it. `fill` is the liquid color, or None for empty."""
    im, d = new(w, h)
    glass, edge = "#d8eef8", "#8fb8cc"
    body = [(10, 9), (22, 9), (26, 17), (28, 33), (25, h - 3), (7, h - 3), (4, 33), (6, 17)]
    d.polygon(body, fill=glass)                                                       # the glass
    if fill:
        d.polygon([(5.5, 21), (26.5, 21), (28, 33), (25, h - 3), (7, h - 3), (4, 33)], fill=fill)   # liquid
        d.line([(5.5, 21), (26.5, 21)], fill=C["white"], width=1)                      # the surface
    for y in (20, 26, 32):                                                            # measure lines
        d.line([(7, y), (11, y)], fill=edge, width=1)
    box(d, 12, 4, 20, 10, glass); box(d, 12, 4, 13, 10, edge)                         # the neck
    box(d, 8, 0, 24, 5, C["dgrey"]); box(d, 8, 0, 24, 2, "#4a4d60")                    # lid, with a lighter top
    box(d, 14, 0, 18, 2, C["lgrey"])                                 # lid knob
    d.arc([21, 12, 33, 34], 270, 90, fill="#9aa0b4", width=3)                          # handle (light, so it shows on the dark recess)
    d.line([(9, 12), (8, 30)], fill=C["white"], width=2)                               # a shine down the left
    return outlined(im)


def icon_carafe(water=False, coffee=False):
    fill = C["lblue"] if water else ("#5c3a1a" if coffee else None)
    art = draw_carafe(fill, 30, 32)
    im, d = new(32, 32)
    im.alpha_composite(art, (1, 0))
    return im


def spr_carafe(full=False):
    return draw_carafe("#5c3a1a" if full else None, 34, 40)


def icon_cup(fill=None):
    im, d = new(32, 32)
    d.polygon([(9, 9), (23, 9), (21, 27), (11, 27)], fill=C["white"])
    d.polygon([(10, 11), (22, 11), (20.5, 26), (11.5, 26)], fill="#e6e8f0")
    box(d, 9, 9, 23, 11, C["lgrey"])                                 # rim
    if fill:
        d.polygon([(10, 14), (22, 14), (20.6, 25), (11.4, 25)], fill=fill)
    box(d, 11, 14, 13, 24, C["white"]) if not fill else None
    return outlined(im)


def icon_coffee():
    im, d = new(32, 32)
    box(d, 7, 11, 22, 27, C["white"])                                # mug
    box(d, 8, 12, 21, 16, "#5c3a1a")                                 # coffee surface
    box(d, 8, 16, 21, 26, "#e6e8f0")
    d.arc([18, 14, 29, 24], 270, 90, fill=C["white"], width=3)       # handle
    for x, y in ((11, 4), (16, 2), (20, 5)):                         # steam
        d.line([(x, y + 6), (x + 2, y + 3), (x, y)], fill=C["lgrey"], width=1)
    return outlined(im)


def icon_coin():
    im, d = new(32, 32)
    d.ellipse([6, 6, 26, 26], fill="#e0a84a")
    d.ellipse([8, 8, 24, 24], fill=C["yellow"])
    d.ellipse([11, 11, 21, 21], outline="#e0a84a", width=1)
    box(d, 15, 12, 17, 20, "#e0a84a")
    box(d, 10, 10, 12, 14, C["white"])
    return outlined(im)


def icon_note(lines=3, color=None):
    im, d = new(32, 32)
    box(d, 6, 6, 26, 26, color or C["yellow"])
    box(d, 6, 22, 26, 26, "#e0a84a")
    for i in range(lines):
        box(d, 9, 10 + i * 4, 23 - (i % 2) * 4, 12 + i * 4, C["dbrown"])
    return outlined(im)


def icon_golf_clubs():
    im, d = new(32, 32)
    d.line([(8, 27), (22, 4)], fill=C["lgrey"], width=2)             # shaft
    d.line([(13, 27), (26, 8)], fill=C["white"], width=2)
    d.polygon([(4, 27), (14, 27), (14, 30), (4, 30)], fill=C["lgrey"])   # heads
    d.polygon([(9, 30), (19, 30), (19, 27), (13, 25)], fill=C["white"])
    box(d, 20, 2, 24, 8, C["dgrey"])                                 # grip
    return outlined(im)


def icon_golf_ball():
    im, d = new(32, 32)
    d.ellipse([7, 7, 25, 25], fill=C["white"])
    for x, y in ((12, 12), (17, 11), (20, 15), (13, 17), (18, 20), (11, 21)):
        box(d, x, y, x + 2, y + 2, "#cfd2dc")
    box(d, 10, 9, 13, 11, "#ffffff")
    return outlined(im)


def icon_key(color, tag=None):
    im, d = new(32, 32)
    d.ellipse([4, 8, 15, 19], outline=color, width=3)                # bow
    box(d, 14, 12, 28, 15, color)                                    # shaft
    box(d, 22, 15, 25, 20, color); box(d, 26, 15, 28, 18, color)     # teeth
    if tag:
        box(d, 5, 21, 13, 27, tag); box(d, 8, 22, 10, 24, C["dark"])
    return outlined(im)


def icon_usb():
    im, d = new(32, 32)
    box(d, 5, 12, 20, 21, C["dgrey"])                                # body
    box(d, 20, 13, 29, 20, C["lgrey"])                               # plug
    box(d, 22, 15, 24, 16, C["dark"]); box(d, 26, 15, 28, 16, C["dark"])
    box(d, 7, 14, 10, 17, C["red"])                                  # label
    box(d, 14, 18, 17, 19, C["lgreen"])                              # activity light
    return outlined(im)


def icon_flashlight():
    im, d = new(32, 32)
    d.polygon([(4, 11), (13, 13), (13, 20), (4, 22)], fill=C["yellow"])  # head
    box(d, 13, 14, 28, 19, C["dgrey"])                                 # body
    box(d, 17, 14, 19, 19, C["lgrey"]); box(d, 23, 14, 25, 19, C["lgrey"])
    box(d, 3, 12, 5, 21, C["white"])                                   # lens
    return outlined(im)


def icon_fuse():
    im, d = new(32, 32)
    box(d, 12, 6, 20, 26, "#e6e8f0")                                   # glass
    box(d, 10, 4, 22, 8, C["lgrey"]); box(d, 10, 24, 22, 28, C["lgrey"])  # caps
    d.line([(16, 8), (16, 12), (14, 14), (18, 17), (16, 20), (16, 24)], fill=C["orange"], width=1)  # filament
    return outlined(im)


def icon_green_card():
    im = icon_keycard()
    d = ImageDraw.Draw(im)
    box(d, 4, 8, 28, 24, C["green"])
    box(d, 4, 11, 28, 14, C["dark"])
    box(d, 7, 16, 13, 21, C["yellow"]); box(d, 9, 16, 11, 21, "#e0a84a")
    box(d, 16, 17, 25, 19, C["lgreen"]); box(d, 16, 21, 22, 23, C["lgreen"])
    box(d, 24, 9, 27, 11, C["white"])
    return im


def icon_chips():
    im, d = new(32, 32)
    d.polygon([(7, 6), (25, 6), (27, 27), (5, 27)], fill=C["orange"])  # bag
    box(d, 6, 6, 26, 10, C["red"])                                     # crimped top
    d.ellipse([10, 13, 22, 23], fill=C["yellow"])                      # banana slice
    d.ellipse([14, 16, 18, 20], fill="#e0a84a")
    return outlined(im)


def icon_mug(coffee=False, water=False):
    im, d = new(32, 32)
    box(d, 7, 9, 22, 27, C["white"])                                   # your mug
    box(d, 8, 10, 21, 14, "#5c3a1a" if coffee else (C["lblue"] if water else "#cfd2dc"))           # coffee surface / empty inside
    d.arc([18, 13, 29, 24], 270, 90, fill=C["white"], width=3)
    box(d, 9, 17, 20, 19, C["red"])                                    # a stripe, so it's recognisably "the" mug
    if coffee:
        for x, y in ((11, 3), (16, 1), (20, 4)):
            d.line([(x, y + 6), (x + 2, y + 3), (x, y)], fill=C["lgrey"], width=1)
    return outlined(im)


ICONS = {
    "mug": icon_mug, "mug_coffee": lambda: icon_mug(True), "mug_water": lambda: icon_mug(water=True),
    "carafe": icon_carafe, "carafe_water": lambda: icon_carafe(water=True),
    "paper_cup": icon_cup, "cup_water": lambda: icon_cup(C["lblue"]), "coffee": icon_coffee,
    "coin": icon_coin, "pin_note": lambda: icon_note(2, C["white"]), "code_note": lambda: icon_note(3),
    "serial_note": lambda: icon_note(4, "#cfe9f5"), "golf_ball": icon_golf_ball,
    "ceo_key": lambda: icon_key(C["yellow"], C["red"]), "janitor_key": lambda: icon_key(C["lgrey"], C["green"]),
    "usb_stick": icon_usb, "flashlight": icon_flashlight, "fuse": icon_fuse, "green_card": icon_green_card,
    "chips": icon_chips,
}


def make_icons():
    for name, fn in ICONS.items():
        save(fn(), "items", name + ".png")



# ---------------------------------------------------------------- backgrounds for the other rooms
def shade(hexcol, k):
    """Lightens (k>1) or darkens (k<1) a '#rrggbb' color."""
    r, g, b = (int(hexcol[i:i + 2], 16) for i in (1, 3, 5))
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(v * k))) for v in (r, g, b))


def ceiling_lights(d, xs, y=0, w=70):
    for x in xs:
        box(d, x, y, x + w, y + 10, C["white"])
        box(d, x - 8, y + 10, x + w + 8, y + 14, "#a7b0c0")


def night_window(d, x, y, w, h, seed=3):
    rng = random.Random(seed)
    box(d, x - 6, y - 6, x + w + 6, y + h + 6, C["lgrey"])
    box(d, x, y, x + w, y + h, C["navy"])
    for _ in range(max(6, w * h // 700)):
        sx, sy = x + rng.randrange(2, w - 2), y + rng.randrange(2, h // 2)
        box(d, sx, sy, sx + 2, sy + 2, C["white"])
    bx = x + 4
    while bx < x + w - 14:  # skyline with lit windows
        bw, bh = rng.randrange(12, 24), rng.randrange(h // 5, h // 2)
        box(d, bx, y + h - bh, min(bx + bw, x + w), y + h, C["dark"])
        for wy in range(y + h - bh + 5, y + h - 4, 9):
            for wx in range(bx + 3, min(bx + bw, x + w) - 4, 7):
                if rng.random() < 0.5:
                    box(d, wx, wy, wx + 3, wy + 3, C["yellow"])
        bx += bw + 3
    box(d, x + w // 2 - 3, y, x + w // 2 + 3, y + h, C["lgrey"])  # mullion


def room_bg(wall, floor1, horizon, trim=None, panels=True, wain=True, rail=None, floor2=None, step=80):
    """Generic room: a paneled wall with a rail and a perspective floor."""
    im, d = new(W, H)
    dark = shade(wall, 0.72)
    wall_panels(d, horizon, wall, dark, step) if panels else box(d, 0, 0, W, horizon, wall)
    if panels is False:
        box(d, 0, 0, W, 6, dark)
    if wain:
        wainscot(d, horizon - 42, horizon, shade(wall, 0.86), rail or shade(wall, 1.35), shade(wall, 0.5))
    floor(d, horizon, 288, floor1, floor2 or shade(floor1, 0.78))
    return im, d


def bg_elevator():
    im, d = room_bg("#6b6f80", "#3a3d4d", 192, panels=False, wain=False, rail="#9aa0b4")
    for x in range(0, W, 40):                                     # brushed-metal panel seams
        box(d, x, 6, x + 2, 192, "#585c6c")
    box(d, 0, 140, W, 146, "#a8abb8"); box(d, 0, 146, W, 148, "#3d4050")   # handrail
    box(d, 120, 0, 520, 12, C["white"]); box(d, 112, 12, 528, 16, "#a7b0c0")  # ceiling light strip
    for x in range(120, 520, 16):                                 # rubber floor ridges
        d.line([x, 200, x + (x - 320) // 6, 288], fill="#2e3140")
    return im


def bg_basement():
    im, d = room_bg("#4a4e5a", "#2b2d33", 180, panels=False, wain=False)
    for y, col in ((14, "#6b7080"), (30, "#8b5a2b")):             # overhead pipes
        box(d, 0, y, W, y + 8, col); box(d, 0, y + 8, W, y + 10, "#222530")
        for x in range(60, W, 120):
            box(d, x, y - 3, x + 8, y + 11, "#222530")
    for x in (190, 440):                                          # bare hanging bulbs
        d.line([x, 40, x, 60], fill=C["dark"]); d.ellipse([x - 6, 60, x + 6, 72], fill=C["yellow"])
    for x in range(0, W, 120):                                    # damp stains on the wall
        d.ellipse([x + 20, 110, x + 58, 150], fill="#42464f")
    box(d, 0, 170, W, 180, "#222530")
    return im


def bg_lobby():
    im, d = room_bg("#8a7a6a", "#b0a89c", 180, wain=True, rail="#c9b89a", step=100)
    for ix in range(0, W, 40):                                    # marble checker floor
        for iy in range(180, 288, 18):
            if (ix // 40 + (iy - 180) // 18) % 2 == 0:
                box(d, ix, iy, ix + 40, iy + 18, "#9c9488")
    ceiling_lights(d, (100, 300, 500))
    return im


def bg_floor3():
    im, d = room_bg("#5d4a6b", "#3b3045", 180, rail="#a77fb8", step=128)
    ceiling_lights(d, (80, 300, 520))
    for x in (160, 450):                                          # little wall lamps
        box(d, x, 80, x + 10, 96, C["yellow"])
    return im


def floor_shadows(im, spans, y, depth=9, alpha=110):
    """Soft dark ovals on the floor under things that stand against the wall, so they look planted."""
    layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(layer)
    for x0, x1 in spans:
        sd.ellipse([x0 - 5, y - 3, x1 + 5, y + depth], fill=(10, 8, 20, alpha))
    im.alpha_composite(layer.filter(ImageFilter.GaussianBlur(1.2)))


def bg_breakroom():
    """The wall ends at y=170 and the floor runs from there, so everything standing at y=190 is 20px into the floor."""
    im, d = new(W, H)
    wall_panels(d, 170, "#c9b26b", "#b09a58", 64)
    wainscot(d, 128, 170, "#a8934f", "#e8d28a", "#6a5a30")
    floor(d, 170, 288, "#7a6a55", "#665846")                       # plain lino with perspective lines: nothing like the wall
    box(d, 0, 166, W, 170, "#5a4a28")                              # baseboard where the wall meets the floor
    ceiling_lights(d, (120, 360), w=80)
    box(d, 372, 156, 408, 161, "#8b8f9c"); box(d, 372, 161, 408, 163, "#5a5e6c")   # a little shelf for the paper cups
    box(d, 498, 160, 568, 190, "#6a5a40"); box(d, 498, 160, 568, 166, "#c8b890")   # base cabinet under the microwave
    box(d, 502, 170, 564, 186, "#7a6a50")
    floor_shadows(im, [(20, 100), (230, 300), (330, 374), (420, 490), (498, 568), (570, 620)], 188)
    return im


def bg_accounting():
    im, d = room_bg("#6b5a4a", "#3b3045", 190, rail="#a08a6a", step=70)
    ceiling_lights(d, (140, 380))
    night_window(d, 150, 40, 100, 80)
    for x, w in ((106, 36), (560, 50)):                           # filing shelves (not behind the door at x=20..100)
        box(d, x, 60, x + w, 190, "#4a3a2a")
        for y in range(70, 186, 22):
            box(d, x + 4, y, x + w - 4, y + 14, "#c8905a"); box(d, x + 4, y + 14, x + w - 4, y + 16, "#2a1f15")
    return im


def bg_conference():
    im, d = room_bg("#4a5a6b", "#3a4252", 190, rail="#7b90a8", step=90)
    ceiling_lights(d, (120, 360), w=90)
    box(d, 0, 0, W, 4, "#2a3340")
    return im


def bg_boss():
    im, d = room_bg("#5a3a2a", "#3b2a22", 190, rail="#b07a4a", step=50)
    for x in range(0, W, 50):                                     # wood paneling grain
        box(d, x + 20, 8, x + 22, 148, "#4a2e20")
    ceiling_lights(d, (260,), w=100)
    return im


def bg_vp():
    im, d = room_bg("#5a4a7a", "#3b3045", 190, rail="#a58fd0", step=80)
    ceiling_lights(d, (100, 340), w=80)
    return im


def bg_ceo():
    im, d = room_bg("#2a2a3a", "#4a3a2a", 190, rail="#7a6a4a", step=110)
    night_window(d, 130, 30, 150, 110, seed=8)
    for x in (40, 320, 480):
        box(d, x, 6, x + 30, 12, C["yellow"])
    return im


def bg_itlab():
    im, d = room_bg("#3a4a5a", "#2b2f3a", 190, rail="#5a7a9a", step=70)
    for x in range(0, W, 8):                                      # cable tray along the ceiling
        box(d, x, 8, x + 5, 18, "#222530")
    for x, col in ((120, C["red"]), (300, C["blue"]), (450, C["lgreen"])):
        d.line([x, 18, x + 12, 60], fill=col, width=2)
    ceiling_lights(d, (200, 400), w=80)
    return im


def bg_closet():
    im, d = room_bg("#3a3d44", "#2b2d33", 190, panels=False, wain=False)
    for y in (80, 130, 170):                                      # shelf brackets on the wall
        box(d, 140, y, 520, y + 4, "#2a2d34")
    ceiling_lights(d, (300,), w=40)
    return im


def bg_itmgr():
    im, d = room_bg("#5a5a4a", "#3b3a2a", 190, rail="#9a9a7a", step=100)
    ceiling_lights(d, (150, 380), w=80)
    for y in range(50, 130, 8):                                   # window blinds
        box(d, 330, y, 460, y + 5, "#b8b8a0")
    box(d, 326, 46, 464, 50, "#7a7a60"); box(d, 326, 130, 464, 134, "#7a7a60")
    return im


BACKGROUNDS = {
    "elevator": bg_elevator, "basement": bg_basement, "lobby": bg_lobby, "floor3": bg_floor3,
    "breakroom": bg_breakroom, "accounting": bg_accounting, "conference": bg_conference,
    "boss": bg_boss, "vp": bg_vp, "ceo": bg_ceo, "itlab": bg_itlab, "closet": bg_closet, "itmgr": bg_itmgr,
}


def make_backgrounds():
    for room, fn in BACKGROUNDS.items():
        save(fn(), "rooms", room, "background.png")



# ---------------------------------------------------------------- doors and the elevator panel
def label(d, xy, text, color, size=14):
    try:
        d.text(xy, text, font=ImageFont.truetype("assets/fonts/VT323.ttf", size), fill=color)
    except OSError:
        pass


def wood_door(w=80, h=120, col="#8b5a2b", plate=None):
    """A plain office door with two raised panels and a handle. `plate`: tiny text on a brass plate."""
    im, d = new(w, h)
    dark = shade(col, 0.55)
    box(d, 0, 0, w, h, C["dark"])
    box(d, 3, 3, w - 3, h, col)
    box(d, w - 8, 3, w - 3, h, shade(col, 0.8))
    for y0, y1 in ((12, 52), (60, h - 10)):
        box(d, 12, y0, w - 14, y1, dark)
        box(d, 15, y0 + 3, w - 17, y1 - 3, shade(col, 1.15))
    box(d, w - 24, 62, w - 16, 66, C["yellow"]); box(d, w - 20, 62, w - 17, 74, C["yellow"])  # handle
    if plate:
        box(d, 16, 52, w - 26, 63, "#e0a84a")
        label(d, (19, 49), plate, C["dark"], 11)
    return im


def steel_door(w=80, h=120, open_=False):
    """Elevator doors: two brushed-steel slabs. Open: pulled apart to show the dark car."""
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"])
    box(d, 3, 3, w - 3, h, "#1a1c24" if open_ else "#9aa0b4")
    if open_:
        box(d, 10, 10, w - 10, h, "#2a2c38")                                # lit interior
        box(d, 12, 12, w - 12, 20, "#3a3d4d")
        box(d, 3, 3, 12, h, "#9aa0b4"); box(d, w - 12, 3, w - 3, h, "#9aa0b4")  # doors pulled aside
    else:
        box(d, w // 2 - 1, 3, w // 2 + 1, h, C["dark"])                    # center seam
        for x in range(8, w - 6, 6):
            box(d, x, 8, x + 1, h, "#b4bace")                                # brushed lines
        box(d, 3, 3, w - 3, 8, "#7c8296")
    box(d, w // 2 - 12, 4, w // 2 + 12, 12, C["dark"])                       # floor indicator
    box(d, w // 2 - 3, 6, w // 2 + 3, 10, C["red"] if not open_ else C["lgreen"])
    return im


def keypad_door(w=80, h=120, unlocked=False):
    im = wood_door(w, h, "#6a4a30")
    d = ImageDraw.Draw(im)
    box(d, w - 22, 40, w - 6, 76, C["dark"])                                  # keypad
    for i in range(3):
        for j in range(4):
            box(d, w - 20 + i * 5, 44 + j * 6, w - 18 + i * 5, 46 + j * 6, C["lgrey"])
    box(d, w - 20, 68, w - 8, 72, C["lgreen"] if unlocked else C["red"])      # the lock light: red, then green
    return im


def security_door(w=70, h=124, col=None, text="SERVER", unlocked=False):
    """Steel door with a card reader. `col`: color of the reader's light panel."""
    col = col or C["green"]
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"])
    box(d, 5, 6, w - 5, h, shade(col, 0.55))
    box(d, 9, 10, w - 9, h - 4, col)
    for y in range(18, h - 8, 14):
        box(d, 13, y, w - 13, y + 3, shade(col, 1.25))
    box(d, 14, 14, w - 14, 30, C["dark"])
    label(d, (18, 12), text[:6], C["lgreen"], 16)
    box(d, w // 2 - 7, 44, w // 2 + 7, 64, C["dark"]); box(d, w // 2 - 3, 48, w // 2 + 3, 52, C["lgreen"] if unlocked else C["red"])  # reader light
    return im


def glass_doors(w=100, h=128):
    """Lobby front doors: double glass doors, night outside."""
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"])
    for x0 in (5, w // 2 + 2):
        box(d, x0, 6, x0 + w // 2 - 7, h, C["lgrey"])
        box(d, x0 + 4, 10, x0 + w // 2 - 11, h - 6, C["navy"])
        for sx, sy in ((x0 + 10, 20), (x0 + 28, 36), (x0 + 16, 60)):
            box(d, sx, sy, sx + 2, sy + 2, C["white"])
        box(d, x0 + 4, 10, x0 + 12, 16, "#3b5dc9")
    box(d, w // 2 - 6, 60, w // 2 - 4, 84, C["yellow"]); box(d, w // 2 + 4, 60, w // 2 + 6, 84, C["yellow"])  # handles
    return im


def elevator_panel():
    """The 100x158 plate behind the floor buttons (the buttons and moving lights are drawn by code)."""
    w, h = 100, 158
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"])
    box(d, 2, 2, w - 2, h - 2, "#4a4d60")
    box(d, 4, 4, w - 4, h - 4, "#2b2d3a")
    for x, y in ((5, 5), (w - 8, 5), (5, h - 8), (w - 8, h - 8)):          # screws
        box(d, x, y, x + 3, y + 3, "#8a8fa4")
    for row in range(4):                                                    # button wells
        box(d, 22, 14 + row * 36, 62, 48 + row * 36, "#16171f")
    box(d, 64, 14, 94, 142, "#16171f")                                      # well for the light strip
    for y in range(14, 142, 15):
        box(d, 66, y + 2, 92, y + 3, "#232534")
    return im


def spr_no_smoking(w=44, h=44):
    im, d = new(w, h)
    d.ellipse([0, 0, w - 1, h - 1], fill=C["white"]); d.ellipse([3, 3, w - 4, h - 4], fill=C["white"])
    box(d, 10, 20, 31, 24, C["dgrey"]); box(d, 31, 20, 34, 24, C["orange"])        # the cigarette
    d.line([(24, 14), (28, 8)], fill=C["lgrey"], width=2)                           # smoke
    d.ellipse([0, 0, w - 1, h - 1], outline=C["red"], width=4)
    d.line([(8, 36), (36, 8)], fill=C["red"], width=4)
    return im


def spr_fire_sign(w=70, h=54):
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"]); box(d, 2, 2, w - 2, h - 2, C["yellow"])
    box(d, 6, 8, 22, 40, C["dgrey"]); box(d, 9, 11, 19, 37, C["lgrey"])             # the elevator
    d.polygon([(40, 38), (34, 26), (38, 18), (42, 26), (46, 14), (52, 30), (48, 38)], fill=C["red"])  # a flame
    d.polygon([(41, 38), (38, 30), (42, 26), (46, 32), (45, 38)], fill=C["orange"])
    d.line([(4, 42), (w - 4, 6)], fill=C["red"], width=3)                           # the slash
    label(d, (12, 40), "DO NOT USE", C["red"], 11)
    return im



def make_doors():
    elev = ("elevator", steel_door(), steel_door(open_=True))
    for room in ("basement", "lobby", "floor3"):
        save(steel_door(), "rooms", room, "elevator.png")
        save(steel_door(open_=True), "rooms", room, "elevator_open.png")
    save(steel_door(90, 120), "rooms", "hallway", "elevator.png")
    save(steel_door(90, 120, True), "rooms", "hallway", "elevator_open.png")
    save(steel_door(), "rooms", "elevator", "door.png")
    save(steel_door(open_=True), "rooms", "elevator", "door_open.png")
    save(elevator_panel(), "rooms", "elevator", "panel.png")
    save(spr_no_smoking(), "rooms", "elevator", "nosmoking.png")
    save(spr_fire_sign(), "rooms", "elevator", "firesign.png")
    for room in ("accounting", "boss", "breakroom", "closet", "conference", "itlab", "itmgr", "vp", "ceo"):
        save(door(), "rooms", room, "door.png")
    save(wood_door(plate="CONF"), "rooms", "hallway", "confdoor.png")
    save(keypad_door(), "rooms", "hallway", "bossdoor.png")
    save(keypad_door(unlocked=True), "rooms", "hallway", "bossdoor_open.png")
    save(wood_door(col="#6b6f80"), "rooms", "basement", "closet.png")
    save(security_door(100, 128, "#3b5dc9", "IT LAB"), "rooms", "basement", "labdoor.png")
    save(security_door(100, 128, "#3b5dc9", "IT LAB", True), "rooms", "basement", "labdoor_open.png")
    save(wood_door(col="#5a6b7a", plate="BREAK"), "rooms", "lobby", "breakdoor.png")
    save(glass_doors(), "rooms", "lobby", "front.png")
    save(wood_door(plate="ACCTG"), "rooms", "floor3", "accounting.png")
    save(wood_door(col="#7a5a9a", plate="VP"), "rooms", "floor3", "vp.png")
    save(wood_door(col="#3a2a2a", plate="CEO"), "rooms", "floor3", "ceo.png")
    save(wood_door(70, 118, "#6a6a52", plate="MGR"), "rooms", "itlab", "mgrdoor.png")
    save(security_door(70, 124), "rooms", "itlab", "greendoor.png")
    save(security_door(70, 124, unlocked=True), "rooms", "itlab", "greendoor_open.png")



# ---------------------------------------------------------------- break room and lobby objects
def spr_vending_machine(w=70, h=130):
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"]); box(d, 3, 3, w - 3, h - 2, "#2d4cae")
    box(d, 7, 8, w - 24, 76, C["dark"]); box(d, 9, 10, w - 26, 74, "#7ec8e8")      # window
    for r in range(3):
        for c in range(3):
            box(d, 12 + c * 12, 14 + r * 20, 20 + c * 12, 28 + r * 20, [C["red"], C["yellow"], C["lgreen"]][(r + c) % 3])
    box(d, w - 18, 10, w - 6, 40, C["dgrey"])                                       # coin / keypad panel
    box(d, w - 16, 14, w - 8, 18, C["yellow"]); box(d, w - 16, 24, w - 8, 36, C["lgrey"])
    box(d, 7, 84, w - 7, 110, C["dark"]); box(d, 12, 90, w - 12, 108, "#16171f")    # dispenser flap
    box(d, 7, 114, w - 7, 124, C["dgrey"])
    return im


def spr_cooler(w=44, h=90):
    im, d = new(w, h)
    box(d, 8, 0, w - 8, 34, "#a8d8f0"); box(d, 10, 2, w - 10, 32, C["lblue"])       # water bottle
    box(d, 12, 4, 16, 28, C["white"])
    box(d, 4, 34, w - 4, 38, C["dgrey"])
    box(d, 4, 38, w - 4, h, C["white"]); box(d, 4, 38, w - 4, 40, "#cfd2dc")
    box(d, 10, 46, 18, 52, C["lblue"]); box(d, 26, 46, 34, 52, C["red"])             # taps
    box(d, 10, 62, w - 10, 68, "#9aa0b4")                                            # drip tray
    box(d, 4, h - 4, w - 4, h, C["dgrey"])
    return outlined(im)


def spr_cups(w=30, h=30):
    """Two stacks of nested paper cups: white, with a blue band, a visible rim at the top and shaded sides."""
    im, d = new(w, h)

    def stack(x, top, bottom, wt, wb, n):
        # tapered body (wider at the top)
        cx = x + wt / 2
        d.polygon([(x, top), (x + wt, top), (cx + wb / 2, bottom), (cx - wb / 2, bottom)], fill="#f4f4f4")
        d.polygon([(cx + wt / 4, top), (x + wt, top), (cx + wb / 2, bottom), (cx + wb / 4, bottom)], fill="#cfd2dc")  # shade
        for k in range(n):                                                      # the rims of the cups nested inside
            y = top + 3 + k * 2
            d.line([(x + 1 + k * 0.1, y), (x + wt - 1 - k * 0.1, y)], fill="#aeb8c6", width=1)
        by = top + (bottom - top) * 0.55                                        # the blue band
        d.polygon([(x + 1, by), (x + wt - 1, by), (x + wt - 1.8, by + 5), (x + 1.8, by + 5)], fill=C["lblue"])
        d.ellipse([x - 1, top - 2, x + wt + 1, top + 3], fill="#e8eaf0", outline="#94b0c2")   # the open top...
        d.ellipse([x + 2, top - 1, x + wt - 2, top + 2], fill="#566c86")                        # ...and the dark inside

    stack(3, 6, h - 1, 14, 10, 5)      # a tall stack
    stack(18, 14, h - 1, 11, 8, 3)     # a shorter one beside it
    return outlined(im)


def spr_coffee_machine(state=""):
    """The machine itself, with a recess for the carafe (the carafe is its own object). state 'full': green light."""
    w, h = 70, 70
    im, d = new(w, h)
    box(d, 4, 0, w - 4, 20, C["dgrey"]); box(d, 6, 2, w - 6, 18, "#4a4d60")           # head
    box(d, 12, 6, 24, 12, C["red"]); box(d, 30, 6, 40, 12, C["lgreen"] if state == "full" else "#16171f")
    box(d, 4, 20, w - 4, 64, "#2b2d3a"); box(d, 4, 60, w - 4, h, C["dgrey"])         # body and base
    box(d, 14, 22, 56, 62, "#16171f")                                                  # the recess the carafe sits in
    box(d, 16, 60, 54, 64, "#6a6e7c"); box(d, 18, 60, 52, 61, "#9aa0b4")              # the warming plate
    return outlined(im)


def spr_microwave(w=56, h=40):
    im, d = new(w, h)
    box(d, 0, 0, w, h, "#8b8f9c"); box(d, 3, 3, w - 3, h - 3, "#6a6e7c")
    box(d, 5, 5, 38, h - 5, C["dark"]); box(d, 7, 7, 36, h - 7, "#2b3a4a")           # window
    box(d, 42, 8, w - 5, 16, C["lgreen"]); box(d, 42, 22, w - 5, 26, C["dgrey"])
    box(d, 43, 30, 47, 34, C["red"])
    return outlined(im)


def spr_fridge(w=50, h=120):
    im, d = new(w, h)
    box(d, 0, 0, w, h, "#cfd2dc"); box(d, 2, 2, w - 2, h - 2, C["white"])
    box(d, 2, 40, w - 2, 43, "#94b0c2")                                              # door split
    box(d, w - 9, 12, w - 6, 34, "#8a8fa4"); box(d, w - 9, 50, w - 6, 80, "#8a8fa4")  # handles
    box(d, 8, 20, 24, 32, C["yellow"]); box(d, 10, 22, 22, 24, C["dark"])             # a note ("STEVE - DO NOT TOUCH")
    box(d, 10, 26, 20, 28, C["dark"])
    box(d, 8, 52, 16, 58, C["red"])                                                    # magnet
    return outlined(im)


def spr_corkboard(w=80, h=60):
    im, d = new(w, h)
    box(d, 0, 0, w, h, "#5c3a1a"); box(d, 3, 3, w - 3, h - 3, "#c8905a")
    for x, y, c in ((8, 8, C["white"]), (30, 6, C["yellow"]), (52, 10, C["white"]), (14, 30, C["lblue"]),
                    (40, 32, C["white"])):
        box(d, x, y, x + 18, y + 16, c)
        box(d, x + 7, y, x + 11, y + 3, C["red"])                                      # pin
        for ly in (6, 10):
            box(d, x + 3, y + ly, x + 15, y + ly + 1, C["dgrey"])
    return im


def spr_reception_desk(w=140, h=66):
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"]); box(d, 2, 2, w - 2, 12, "#c8905a")                # counter top
    box(d, 2, 12, w - 2, h, "#8b5a2b")
    for x in range(8, w - 8, 36):
        box(d, x, 18, x + 30, h - 6, "#6a4220"); box(d, x + 3, 21, x + 27, h - 9, "#7a4e28")
    box(d, 8, 4, 22, 8, C["white"])                                                  # a clipboard on the top
    return im


def spr_plant(watered=False, w=24, h=26):
    im, d = new(w, h)
    box(d, 6, 16, 18, h, "#b13e53"); box(d, 5, 14, 19, 18, "#8f2f43")                # pot
    if not watered:
        d.line([(12, 14), (12, 6)], fill="#7a6a3a", width=2)
        d.line([(12, 9), (7, 5)], fill="#7a6a3a", width=1); d.line([(12, 8), (18, 3)], fill="#7a6a3a", width=1)
        box(d, 5, 3, 8, 5, "#6a5a2a"); box(d, 17, 1, 20, 3, "#6a5a2a")               # brown dead leaves
    else:
        d.line([(12, 14), (12, 5)], fill=C["green"], width=2)
        d.ellipse([3, 4, 12, 10], fill=C["lgreen"]); d.ellipse([12, 2, 22, 9], fill=C["green"])
        d.ellipse([9, 0, 15, 5], fill=C["yellow"])                                     # the first flower
    return outlined(im)


def spr_plant_big(w=56, h=94):
    """The giant plant: the same pot as the small one, sitting at the bottom."""
    im, d = new(w, h)
    box(d, 16, h - 26, 40, h, "#b13e53"); box(d, 14, h - 30, 42, h - 24, "#8f2f43")   # the pot
    d.line([(28, h - 30), (28, 10)], fill="#257179", width=4)                         # thick trunk
    for y, x0, x1, c in ((16, 4, 28, C["lgreen"]), (24, 28, 52, C["green"]), (36, 2, 28, C["green"]),
                         (46, 28, 54, C["lgreen"]), (58, 6, 28, C["lgreen"])):
        d.ellipse([x0, y - 7, x1, y + 8], fill=c)                                     # big leaves
    d.ellipse([20, 0, 36, 14], fill=C["green"])
    d.ellipse([23, 3, 33, 11], fill=C["yellow"])                                      # a huge flower
    d.ellipse([26, 5, 30, 9], fill="#e0a84a")
    return outlined(im)


def make_objects():
    save(spr_vending_machine(), "rooms", "breakroom", "vending.png")
    save(spr_cooler(), "rooms", "breakroom", "cooler.png")
    save(spr_cups(), "rooms", "breakroom", "cups.png")
    for st, suf in (("", ""), ("full", "_full")):
        save(spr_coffee_machine(st), "rooms", "breakroom", "coffeemachine" + suf + ".png")
    save(spr_carafe(), "rooms", "breakroom", "carafe.png")
    save(spr_carafe(True), "rooms", "breakroom", "carafe_full.png")
    save(spr_microwave(), "rooms", "breakroom", "microwave.png")
    save(spr_fridge(), "rooms", "breakroom", "fridge.png")
    save(spr_corkboard(), "rooms", "breakroom", "corkboard.png")
    save(spr_reception_desk(), "rooms", "lobby", "desk.png")
    save(spr_plant(), "rooms", "lobby", "plant.png")
    save(spr_plant(True), "rooms", "lobby", "plant_watered.png")
    save(spr_plant_big(), "rooms", "lobby", "plant_big.png")



# ---------------------------------------------------------------- 2nd and 3rd floor objects
def spr_desk(w, h, top="#c8905a", body="#8b5a2b", nameplate=None):
    """A desk. With a nameplate, a brass plate stands on top (the sprite is 14px taller to fit it)."""
    im, d = new(w, h)
    y0 = 14 if nameplate else 0                                                        # where the desk itself starts
    box(d, 0, y0, w, h, C["dark"]); box(d, 2, y0 + 2, w - 2, y0 + 14, top)            # desk top
    box(d, 2, y0 + 14, w - 2, h - 2, body)
    for x in (8, w - 46):                                                             # drawer stacks
        box(d, x, y0 + 20, x + 38, h - 6, shade(body, 0.8))
        for y in range(y0 + 24, h - 10, 16):
            box(d, x + 4, y, x + 34, y + 12, shade(body, 1.1)); box(d, x + 15, y + 5, x + 23, y + 7, C["yellow"])
    if nameplate:
        pw = max(48, len(nameplate) * 7 + 12)
        x0 = w // 2 - pw // 2
        box(d, x0, 0, x0 + pw, 16, C["dark"]); box(d, x0 + 2, 2, x0 + pw - 2, 14, "#e0a84a")   # the plate
        box(d, x0 + 3, 3, x0 + pw - 3, 13, "#f0c070")
        label(d, (x0 + pw // 2 - len(nameplate) * 3, 1), nameplate, "#3a2410", 13)
    return im


def spr_projector():
    im, d = new(120, 80)
    box(d, 0, 0, 120, 80, C["dark"]); box(d, 4, 4, 116, 76, C["white"])
    box(d, 4, 4, 116, 14, "#3b5dc9"); label(d, (8, 1), "Q4 Roadmap", C["white"], 14)
    for y in (24, 38, 52, 66):
        box(d, 10, y, 14, y + 4, C["dark"]); label(d, (18, y - 5), "Synergy", C["dgrey"], 14)
    return im


def banana_doodle(w=38, h=36):
    """A hand-drawn banana: a fat yellow crescent, thick in the middle, with a brown stem and dark tip."""
    k = 4
    mask = Image.new("L", (w * k, h * k), 0)
    md = ImageDraw.Draw(mask)
    cx, cy, R = 30, 2, 25
    n = 40
    for i in range(n + 1):
        u = i / n
        ang = math.radians(96 + 80 * u)
        x, y = cx + R * math.cos(ang), cy + R * math.sin(ang)
        r = 1.6 + 4.6 * math.sin(math.pi * u) ** 0.8              # thin at both ends, fat in the middle
        md.ellipse([(x - r) * k, (y - r) * k, (x + r) * k, (y + r) * k], fill=255)
    mask = mask.resize((w, h), Image.LANCZOS).point(lambda v: 255 if v > 100 else 0)
    body = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    body.paste(Image.new("RGBA", (w, h), "#f7d84a"), (0, 0), mask)
    ol = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ol.paste(Image.new("RGBA", (w, h), "#5c3a1a"), (0, 0), mask.filter(ImageFilter.MaxFilter(3)))
    ol.alpha_composite(body)
    d = ImageDraw.Draw(ol)
    sx, sy = cx + R * math.cos(math.radians(176)), cy + R * math.sin(math.radians(176))
    d.line([(sx, sy), (sx - 1, sy - 5)], fill="#5c3a1a", width=3)                        # stem, at the top end
    tx, ty = cx + R * math.cos(math.radians(96)), cy + R * math.sin(math.radians(96))
    d.rectangle([tx - 2, ty - 1, tx + 1, ty + 1], fill="#5c3a1a")                          # dark tip, bottom end
    return ol


def spr_whiteboard(w=110, h=70, words=None):
    im, d = new(w, h)
    box(d, 0, 0, w, h, "#8a8fa4"); box(d, 3, 3, w - 3, h - 6, C["white"]); box(d, 3, h - 6, w - 3, h - 2, "#6a6e7c")
    if words:
        for i, wd in enumerate(words):
            label(d, (8, 1 + i * 12), wd, ["#3b5dc9", C["red"], "#257179", C["dgrey"]][i % 4], 12)
    else:
        im.alpha_composite(banana_doodle(), (10, 10))
        d.line([(50, 28), (84, 28)], fill=C["red"], width=2); d.polygon([(84, 24), (92, 28), (84, 32)], fill=C["red"])
        label(d, (54, 32), "launch", C["blue"], 14)
        for x, y in ((12, 46), (30, 50)):
            d.line([(x, y), (x + 14, y + 2)], fill=C["dgrey"], width=1)
    return im


def spr_conf_table():
    im, d = new(280, 50)
    box(d, 0, 0, 280, 50, (0, 0, 0, 0))
    box(d, 0, 0, 280, 16, C["dark"]); box(d, 2, 2, 278, 14, "#a06a30")             # table top
    box(d, 2, 14, 278, 20, "#6a4220")
    for x in (12, 120, 240):
        box(d, x, 20, x + 8, 50, "#4a3018")                                          # legs
    for x in range(14, 270, 52):                                                      # chairs' backs, peeking above
        box(d, x, 6, x + 24, 12, C["dgrey"])
    return im


def spr_speakerphone(w=44, h=16):
    """A round conference speakerphone seen from a little above: a light rim so it stands out on the dark wood."""
    im, d = new(w, h)
    d.ellipse([0, 2, w - 1, h - 1], fill="#16171f")                                 # the base (a dark edge below)
    d.ellipse([0, 0, w - 1, h - 4], fill="#94b0c2")                                 # a light rim
    d.ellipse([3, 1, w - 4, h - 5], fill="#2b2d3a")                                 # the top
    for x in (12, 18, 24, 30):                                                      # speaker grille dots
        d.rectangle([x, 4, x + 1, 5], fill="#7c8296")
    d.ellipse([w // 2 - 3, h - 9, w // 2 + 3, h - 6], fill=C["red"])               # the "on" light
    return im


def spr_sticky(w=16, h=14, col=None):
    im, d = new(w, h)
    box(d, 0, 0, w, h, col or C["yellow"]); box(d, 0, h - 3, w, h, "#e0a84a")
    box(d, 3, 3, w - 3, 4, C["dgrey"]); box(d, 3, 6, w - 6, 7, C["dgrey"])
    return im


def spr_window_night(w, h, seed=3):
    im, d = new(w, h)
    night_window(d, 6, 6, w - 12, h - 12, seed)
    box(d, 0, 0, w, 3, C["lgrey"]); box(d, 0, h - 3, w, h, C["lgrey"])
    return im


def spr_painting(w=80, h=64):
    """The CEO's golf picture: a golfer lining up a putt on a green hill, with a flag."""
    im, d = new(w, h)
    box(d, 0, 0, w, h, "#7a5a1a"); box(d, 4, 4, w - 4, h - 4, C["lblue"])               # gilded frame, sky
    d.ellipse([-20, 38, w + 20, h + 30], fill=C["green"]); d.ellipse([-10, 44, w + 10, h + 40], fill=C["lgreen"])  # the green hill
    d.line([(58, 16), (58, 46)], fill=C["white"], width=1)                              # the flagpole
    d.polygon([(58, 16), (70, 20), (58, 25)], fill=C["red"])                            # the flag
    d.ellipse([54, 44, 62, 47], fill=C["dark"])                                         # the hole
    box(d, 20, 32, 28, 48, C["dgrey"]); d.ellipse([20, 22, 28, 32], fill=C["tan"])      # the golfer
    box(d, 19, 21, 30, 25, C["red"])                                                     # golf cap
    d.line([(28, 38), (38, 49)], fill=C["lgrey"], width=1)                              # the putter
    d.ellipse([40, 47, 43, 50], fill=C["white"])                                         # the ball
    return im


def spr_safe(open_=False, w=52, h=44):
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"]); box(d, 3, 3, w - 3, h - 3, "#3a3d4d")
    if open_:
        box(d, 6, 6, w - 6, h - 6, "#16171f"); box(d, 8, 8, w - 8, h - 8, "#222530")
        box(d, w - 8, 3, w - 3, h - 3, "#6a6e7c")                                        # the door, swung open
    else:
        box(d, 6, 6, w - 6, h - 6, "#4a4d60")
        d.ellipse([w // 2 - 8, h // 2 - 8, w // 2 + 8, h // 2 + 8], fill=C["dgrey"])    # the dial
        box(d, w // 2 - 1, h // 2 - 6, w // 2 + 1, h // 2, C["red"])
        box(d, w - 16, 8, w - 8, 18, C["dark"]); box(d, w - 14, 10, w - 10, 12, C["lgreen"])  # keypad
    return im


def spr_leather_chair(w=60, h=80):
    im, d = new(w, h)
    box(d, 10, 0, 50, 46, C["dark"]); box(d, 13, 3, 47, 44, "#6a3a22")                  # tall back
    box(d, 6, 40, 54, 60, C["dark"]); box(d, 9, 43, 51, 57, "#7a4a2a")                  # seat
    box(d, 28, 60, 32, 72, C["dgrey"]); box(d, 14, 72, 46, 78, C["dgrey"])              # stem and base
    return im


def spr_trophies(w=100, h=70):
    im, d = new(w, h)
    box(d, 0, 48, w, 54, "#6a4220"); box(d, 0, 20, w, 24, "#6a4220")                    # shelves
    for x in (8, 38, 70):
        d.polygon([(x, 2), (x + 18, 2), (x + 14, 14), (x + 4, 14)], fill=C["yellow"])    # cups
        box(d, x + 7, 14, x + 11, 18, "#e0a84a"); box(d, x + 3, 18, x + 15, 21, "#e0a84a")
    for x in (10, 44, 72):
        d.ellipse([x, 36, x + 12, 48], fill=C["white"]); box(d, x + 5, 28, x + 7, 40, C["lgrey"])  # golf-ball trophies
    box(d, 10, 56, 34, 70, C["red"]); label(d, (12, 55), "LEAD", C["white"], 12)         # participation ribbon
    return im


def spr_accountant(w=44, h=70):
    im, d = new(w, h)
    box(d, 8, 34, 36, 70, "#3b5dc9"); box(d, 8, 34, 36, 38, "#2b4a99")                  # shirt
    box(d, 20, 36, 24, 52, C["red"])                                                      # tie
    box(d, 12, 12, 32, 34, C["tan"])                                                      # head
    box(d, 10, 6, 34, 12, "#257179"); box(d, 6, 10, 38, 13, "#257179")                  # green visor
    box(d, 14, 18, 20, 24, C["white"]); box(d, 24, 18, 30, 24, C["white"])               # glasses
    box(d, 16, 20, 18, 22, C["dark"]); box(d, 26, 20, 28, 22, C["dark"])
    box(d, 18, 28, 26, 30, C["dbrown"])
    return outlined(im)


def spr_beans(w=60, h=18):
    im, d = new(w, h)
    for x0 in (2, 22, 42):
        for i in range(10):
            bx, by = x0 + (i % 5) * 3, h - 4 - (i // 5) * 3
            box(d, bx, by, bx + 3, by + 3, "#a0522d")
    return im


def spr_calculator(w=20, h=12):
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dgrey"]); box(d, 2, 1, w - 2, 4, C["lgreen"])
    for y in (6, 9):
        for x in (3, 8, 13):
            box(d, x, y, x + 3, y + 2, C["lgrey"])
    return im


def spr_orgchart():
    im, d = new(70, 80)
    box(d, 0, 0, 70, 80, "#8a8fa4"); box(d, 3, 3, 67, 77, C["white"])
    box(d, 24, 8, 46, 18, C["red"])
    d.line([(35, 18), (35, 26)], fill=C["dark"]); d.line([(14, 26), (56, 26)], fill=C["dark"])
    for x in (8, 28, 48):
        d.line([(x + 7, 26), (x + 7, 32)], fill=C["dark"]); box(d, x, 32, x + 14, 40, C["lblue"])
        d.line([(x + 7, 40), (x + 7, 48)], fill=C["dark"])
        box(d, x + 2, 48, x + 12, 54, C["lgrey"])
    box(d, 30, 64, 40, 74, C["fur"]); box(d, 33, 66, 37, 70, C["tan"])                    # the little monkey icon
    return im


def spr_hook(empty=False, w=22, h=30):
    im, d = new(w, h)
    box(d, 8, 0, 14, 6, C["dgrey"]); d.line([(11, 4), (11, 14)], fill=C["lgrey"], width=2)
    if not empty:
        d.ellipse([4, 14, 18, 28], outline=C["yellow"], width=2)                         # the ring
        box(d, 14, 18, 20, 26, "#e0a84a"); box(d, 15, 19, 17, 21, C["dark"])             # brass CEO key
    return im


def spr_phone(w=28, h=16):
    im, d = new(w, h)
    box(d, 0, 6, w, h, C["dark"]); box(d, 2, 8, w - 2, h - 1, "#2b2d3a")
    box(d, 0, 0, 10, 6, C["dark"]); box(d, w - 10, 0, w, 6, C["dark"]); box(d, 8, 1, w - 8, 4, C["dgrey"])  # handset
    box(d, w - 8, 9, w - 4, 12, C["red"])                                                # message light
    return im


def spr_donut(w=24, h=14):
    im, d = new(w, h)
    d.ellipse([0, 2, w, h], fill="#c8905a"); d.ellipse([1, 2, w - 1, h - 3], fill="#e8a0b0")
    d.ellipse([9, 5, 15, 9], fill=(0, 0, 0, 0)); box(d, 14, 6, w - 2, h - 2, "#c8905a")  # a bite taken out
    return outlined(im)


def spr_plaque(w=110, h=42):
    im, d = new(w, h)
    box(d, 0, 0, w, h, "#6a4220"); box(d, 4, 4, w - 4, h - 4, "#e0a84a")             # frame, brass plate
    box(d, 6, 6, w - 6, h - 6, "#f0c070")                                            # a lighter face, so the text stands out
    for i, t in enumerate(("Leadership", "is just delegation", "with better parking.")):
        label(d, (10, 6 + i * 10), t, "#3a2410", 10)
    return im


def spr_photo(w=60, h=46):
    im, d = new(w, h)
    box(d, 0, 0, w, h, "#7a5a1a"); box(d, 3, 3, w - 3, h - 3, C["lgrey"])
    box(d, 10, 14, 24, h - 3, C["dgrey"]); d.ellipse([12, 6, 22, 16], fill=C["tan"])      # the CEO in a suit
    box(d, 32, 12, 52, h - 3, "#2a2a2a"); d.ellipse([34, 4, 50, 18], fill="#3a3a3a")       # the gorilla
    box(d, 38, 8, 46, 14, "#5a4a3a"); box(d, 40, 9, 42, 11, C["white"]); box(d, 44, 9, 46, 11, C["white"])
    box(d, 36, 24, 48, 30, C["red"])                                                        # a tie, naturally
    box(d, 24, 26, 32, 29, C["tan"])                                                        # the handshake
    return im


def spr_sofa(w=110, h=60):
    im, d = new(w, h)
    box(d, 0, 10, w, h, C["dark"]); box(d, 4, 2, w - 4, 34, "#5a3a2a")                    # back
    box(d, 4, 4, w - 4, 8, "#7a4a2a")
    box(d, 0, 28, 14, h, "#4a2e20"); box(d, w - 14, 28, w, h, "#4a2e20")                  # arms
    box(d, 12, 30, w - 12, 50, "#6a3a22"); box(d, 54, 30, 56, 50, C["dark"])              # seat cushions
    box(d, 8, h - 6, 16, h, C["dark"]); box(d, w - 16, h - 6, w - 8, h, C["dark"])        # feet
    return im


def spr_terminal(w=62, h=46):
    im, d = new(w, h)
    box(d, 0, 0, w, h - 8, C["dark"]); box(d, 3, 3, w - 3, h - 11, "#16171f")         # the screen
    label(d, (7, 3), "INSERT", C["lgreen"], 14)                                       # two lines, so each is big enough to read
    label(d, (7, 15), "MEDIA", C["lgreen"], 14)
    box(d, 7, 31, 20, 33, C["lgreen"])                                                  # a blinking cursor, under the text
    box(d, w // 2 - 6, h - 8, w // 2 + 6, h - 4, C["dgrey"]); box(d, w // 2 - 16, h - 4, w // 2 + 16, h, C["dgrey"])
    return im


def spr_putter(w=40, h=10):
    im, d = new(w, h)
    d.line([(2, 3), (30, 8)], fill=C["lgrey"], width=2)
    box(d, 30, 6, 38, 10, C["white"])
    return im


def spr_golf_cup(w=28, h=12):
    im, d = new(w, h)
    d.ellipse([0, 0, w, h], fill="#6a6e7c"); d.ellipse([3, 2, w - 3, h - 2], fill=C["dark"])
    return im


def make_floor_objects():
    save(spr_projector(), "rooms", "conference", "projector.png")
    save(spr_whiteboard(), "rooms", "conference", "whiteboard.png")
    save(spr_conf_table(), "rooms", "conference", "table.png")
    save(spr_speakerphone(), "rooms", "conference", "phone.png")
    save(spr_sticky(), "rooms", "conference", "note.png")
    save(spr_window_night(110, 90, 4), "rooms", "boss", "window.png")
    save(spr_painting(), "rooms", "ceo", "painting.png")
    save(spr_safe(), "rooms", "ceo", "safe.png")
    save(spr_safe(True), "rooms", "ceo", "safe_open.png")
    save(spr_desk(160, 84, "#7a4a2a", "#5a3a2a", "THE BOSS"), "rooms", "boss", "desk.png")
    save(spr_leather_chair(), "rooms", "boss", "chair.png")
    save(spr_trophies(), "rooms", "boss", "trophies.png")
    save(spr_desk(160, 60, "#b8a888", "#7a6a50"), "rooms", "accounting", "desk.png")
    save(spr_beans(), "rooms", "accounting", "beans.png")
    save(spr_accountant(), "rooms", "accounting", "accountant.png")
    save(spr_calculator(), "rooms", "accounting", "calculator.png")
    save(spr_whiteboard(100, 70, ["synergy", "pivot", "circle back", "leverage", "the banana"]), "rooms", "vp", "whiteboard.png")
    save(spr_orgchart(), "rooms", "vp", "orgchart.png")
    save(spr_hook(), "rooms", "vp", "hook.png")
    save(spr_hook(True), "rooms", "vp", "hook_empty.png")
    save(spr_desk(180, 86, "#a58fd0", "#6a5a8a", "VP"), "rooms", "vp", "desk.png")
    save(spr_phone(), "rooms", "vp", "phone.png")
    save(spr_donut(), "rooms", "vp", "donut.png")
    save(spr_window_night(150, 110, 8), "rooms", "ceo", "window.png")
    save(spr_plaque(), "rooms", "ceo", "plaque.png")
    save(spr_photo(), "rooms", "ceo", "photo.png")
    save(spr_sofa(), "rooms", "ceo", "sofa.png")
    save(spr_desk(180, 86, "#5a4a3a", "#2a2a2a", "CEO"), "rooms", "ceo", "desk.png")
    save(spr_terminal(), "rooms", "ceo", "terminal.png")
    save(spr_putter(), "rooms", "ceo", "putter.png")
    save(spr_golf_cup(), "rooms", "ceo", "cup.png")



# ---------------------------------------------------------------- basement, IT, closet, office objects
def spr_fusebox(on=False, w=36, h=44):
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"]); box(d, 3, 3, w - 3, h - 3, "#8b8f9c")
    for y in (8, 18, 28):
        box(d, 7, y, w - 7, y + 6, "#4a4d60"); box(d, 9, y + 2, 14, y + 4, C["lgreen"] if on or y != 18 else C["red"])
    box(d, w - 14, 8, w - 9, 14, C["dark"])
    box(d, 5, h - 8, w - 5, h - 5, C["yellow"]) if on else box(d, 5, h - 8, w - 5, h - 5, C["red"])
    return im


def spr_network_board(w=90, h=70):
    im, d = new(w, h)
    box(d, 0, 0, w, h, "#8a8fa4"); box(d, 3, 3, w - 3, h - 3, C["white"])
    for (x, y) in ((12, 14), (44, 10), (70, 22), (24, 44), (58, 46)):
        box(d, x, y, x + 12, y + 8, C["lblue"])
    for a, b in (((18, 18), (48, 14)), ((50, 14), (74, 26)), ((18, 22), (28, 46)), ((30, 48), (62, 50)), ((74, 28), (62, 46))):
        d.line([a, b], fill=C["dgrey"], width=1)
    label(d, (30, 28), "here be dragons", C["red"], 9)
    d.line([(8, h - 12), (40, h - 9)], fill="#cfd2dc", width=3)                      # half-erased smudge
    return im


def spr_server_rack(w=60, h=130):
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"]); box(d, 3, 3, w - 3, h - 2, "#2a3248")
    for y in range(8, h - 10, 14):
        box(d, 6, y, w - 6, y + 10, "#16171f")
        for i, x in enumerate(range(10, w - 12, 8)):
            box(d, x, y + 3, x + 3, y + 6, "#0b0f1c")      # a dark LED socket (the lights themselves blink, see itlab.gd)
    return im


def spr_workbench(w=95, h=60):
    im, d = new(w, h)
    box(d, 0, 20, w, 28, C["dark"]); box(d, 2, 20, w - 2, 26, "#c8905a")            # bench top
    box(d, 4, 28, 10, h, "#4a3018"); box(d, w - 10, 28, w - 4, h, "#4a3018")
    box(d, 6, 6, 30, 20, "#8a8fa4"); box(d, 8, 8, 28, 16, "#2b3a4a")                 # a dismantled monitor
    box(d, 38, 12, 60, 20, C["dgrey"]); box(d, 40, 14, 58, 17, "#cfd2dc")           # a keyboard
    d.line([(64, 20), (74, 10), (84, 22)], fill=C["red"], width=1)                   # cables
    d.line([(60, 20), (70, 12), (90, 18)], fill=C["blue"], width=1)
    box(d, 66, 6, 76, 20, "#6a6e7c")                                                  # a PC case, open
    return im


def spr_small_key(w=18, h=12):
    im, d = new(w, h)
    d.ellipse([0, 1, 8, 9], outline=C["lgrey"], width=2); box(d, 7, 4, 17, 6, C["lgrey"]); box(d, 13, 6, 15, 9, C["lgrey"])
    return im


def spr_calendar(w=60, h=70):
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"]); box(d, 2, 2, w - 2, h - 2, C["white"]); box(d, 2, 2, w - 2, 14, C["red"])
    for r in range(5):
        for c in range(7):
            box(d, 5 + c * 7, 20 + r * 9, 9 + c * 7, 24 + r * 9, C["lgrey"])
    d.ellipse([30, 36, 42, 48], outline=C["red"], width=2)                           # today, circled
    label(d, (6, 56), "SHUTDOWN?", C["red"], 10)
    return im


def spr_cabinet(w=60, h=120):
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"]); box(d, 2, 2, w - 2, h - 2, "#8b8f9c")
    for y in (6, 42, 78):
        box(d, 5, y, w - 5, y + 32, "#6a6e7c"); box(d, 22, y + 12, 38, y + 16, C["lgrey"])
        box(d, 12, y + 4, 28, y + 10, C["white"])
    return im


def spr_mgr_computer(w=60, h=36):
    im, d = new(w, h)
    box(d, 8, 0, 52, 26, C["dark"]); box(d, 11, 3, 49, 23, "#16171f")
    label(d, (13, 1), "PASSWORD:", C["lgreen"], 10); box(d, 13, 14, 32, 16, C["lgreen"])
    box(d, 24, 26, 36, 30, C["dgrey"]); box(d, 16, 30, 44, 36, C["dgrey"])
    return im


def spr_drawer_lock(unlocked=False, w=40, h=24):
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"]); box(d, 2, 2, w - 2, h - 2, "#7a4a2a"); box(d, 14, 9, 26, 12, C["yellow"])
    box(d, 31, 4, 37, 10, C["lgreen"] if unlocked else C["red"])                    # the electronic lock's light
    return im


def spr_closet_shelves(w=150, h=110):
    im, d = new(w, h)
    for y in (2, 40, 78):
        box(d, 0, y + 26, w, y + 32, "#4a3018")
        for x, c in ((8, C["lblue"]), (26, C["yellow"]), (44, C["lgreen"]), (66, C["red"]), (90, C["white"]), (112, C["lblue"])):
            box(d, x, y + 6, x + 12, y + 26, c); box(d, x + 3, y + 2, x + 9, y + 6, C["dgrey"])  # bottles
    box(d, 126, 8, 146, 26, "#cfd2dc")                                              # a bucket of sponges
    return im


def spr_flashlight(w=30, h=12):
    im, d = new(w, h)
    box(d, 0, 2, 8, 10, C["yellow"]); box(d, 8, 3, w, 9, C["dgrey"]); box(d, 12, 3, 14, 9, C["lgrey"]); box(d, 20, 3, 22, 9, C["lgrey"])
    return outlined(im)


def spr_spare_fuse(w=18, h=14):
    im, d = new(w, h)
    box(d, 0, 0, w, h, "#e6e8f0"); box(d, 0, 0, 3, h, C["lgrey"]); box(d, w - 3, 0, w, h, C["lgrey"])
    d.line([(3, 7), (7, 4), (11, 9), (15, 7)], fill=C["orange"], width=1)
    return outlined(im)


def spr_mop(w=30, h=120):
    im, d = new(w, h)
    d.line([(15, 0), (15, 88)], fill="#c8905a", width=3)
    d.polygon([(6, 86), (24, 86), (28, 120), (2, 120)], fill="#cfd2dc")
    for x in range(5, 27, 4):
        d.line([(x, 92), (x - 1 + (x % 3), 119)], fill="#94b0c2", width=1)
    return outlined(im)


def spr_wet_floor_sign(w=36, h=60):
    im, d = new(w, h)
    d.polygon([(18, 0), (34, 58), (2, 58)], fill=C["yellow"]); d.polygon([(18, 10), (28, 54), (8, 54)], fill="#e0a84a")
    label(d, (10, 26), "WET", C["dark"], 9); label(d, (8, 35), "FLOOR", C["dark"], 9)
    return outlined(im)


def spr_bucket(w=44, h=40):
    im, d = new(w, h)
    d.polygon([(4, 8), (40, 8), (36, 38), (8, 38)], fill=C["grey"]); box(d, 4, 6, 40, 10, "#94b0c2")
    box(d, 8, 10, 40, 14, "#4a5a5a")                                                 # grey water
    d.arc([8, 0, 36, 16], 180, 360, fill=C["lgrey"], width=2)
    return outlined(im)


def spr_lobby_sign(w=100, h=28):
    im, d = new(w, h)
    box(d, 0, 0, w, h, "#5c3a1a"); box(d, 2, 2, w - 2, h - 2, C["white"])
    for i, t in enumerate(("If you worked here...", "you'd be at work now.")):
        label(d, (5, 1 + i * 11), t, C["dgrey"], 10)
    return im


def spr_office_computer(w=44, h=34):
    im, d = new(w, h)
    box(d, 2, 0, w - 2, 24, C["dark"]); box(d, 5, 3, w - 5, 21, "#16171f")
    label(d, (7, 1), "> _", C["lgreen"], 12)
    box(d, w // 2 - 4, 24, w // 2 + 4, 28, C["dgrey"]); box(d, 10, 28, w - 10, h, C["dgrey"])
    return im


def spr_receptionist(w=40, h=56):
    im, d = new(w, h)
    box(d, 8, 30, 32, h, "#b13e53"); box(d, 8, 30, 32, 34, "#8f2f43")                  # blouse
    box(d, 12, 8, 28, 30, C["tan"])                                                      # face
    box(d, 10, 2, 30, 12, "#5c3a1a"); box(d, 14, -1 + 1, 26, 3, "#5c3a1a")               # hair, with a bun on top
    box(d, 8, 10, 12, 20, "#5c3a1a"); box(d, 28, 10, 32, 20, "#5c3a1a")
    box(d, 14, 14, 18, 18, C["dark"]); box(d, 22, 14, 26, 18, C["dark"])                # wide, horrified eyes
    box(d, 15, 15, 17, 17, C["white"]); box(d, 23, 15, 25, 17, C["white"])
    box(d, 17, 22, 23, 27, C["dark"])                                                    # open mouth
    box(d, 6, 10, 9, 22, C["dgrey"]); box(d, 6, 20, 14, 23, C["dgrey"])                  # headset
    return outlined(im)


def spr_company_logo(w=56, h=56):
    """The company logo: a monkey face on a red disc, in a frame."""
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"]); box(d, 2, 2, w - 2, h - 2, C["white"])
    d.ellipse([5, 5, w - 6, h - 6], fill=C["red"])
    d.ellipse([9, 22, 19, 32], fill=C["fur"]); d.ellipse([w - 20, 22, w - 10, 32], fill=C["fur"])     # ears
    d.ellipse([11, 24, 17, 30], fill=C["tan"]); d.ellipse([w - 18, 24, w - 12, 30], fill=C["tan"])
    d.ellipse([14, 12, w - 15, h - 12], fill=C["fur"])                                                  # head
    d.ellipse([19, 26, w - 20, h - 12], fill=C["tan"])                                                  # muzzle
    box(d, 21, 22, 25, 27, C["dark"]); box(d, w - 26, 22, w - 22, 27, C["dark"])                        # eyes
    box(d, 25, 36, 27, 38, C["dbrown"]); box(d, w - 28, 36, w - 26, 38, C["dbrown"])                    # nostrils
    box(d, 24, 42, w - 24, 44, C["dbrown"])                                                              # a smile
    return im


def spr_memo(w=50, h=44):
    im, d = new(w, h)
    box(d, 0, 0, w, h, C["dark"]); box(d, 1, 1, w - 1, h - 1, C["white"])
    label(d, (4, 0), "MEMO", C["red"], 12)
    box(d, 3, 12, w - 3, 13, C["dgrey"])
    for y in range(16, h - 4, 5):
        box(d, 4, y, w - 4 - (y % 3) * 4, y + 1, C["lgrey"])
    box(d, w - 10, h - 12, w - 3, h - 5, C["red"])                                  # a "MORE MEMOS" stamp
    return im


def make_more_objects():
    save(spr_memo(), "rooms", "conference", "memo.png")
    save(spr_company_logo(), "rooms", "lobby", "logo.png")
    save(spr_receptionist(), "rooms", "lobby", "receptionist.png")
    save(spr_fusebox(), "rooms", "itlab", "fusebox.png")
    save(spr_fusebox(True), "rooms", "itlab", "fusebox_on.png")
    save(spr_network_board(), "rooms", "itlab", "whiteboard.png")
    save(spr_server_rack(), "rooms", "itlab", "rack.png")
    save(spr_workbench(), "rooms", "itlab", "bench.png")
    save(spr_small_key(), "rooms", "itlab", "key.png")
    save(spr_calendar(), "rooms", "itmgr", "calendar.png")
    save(spr_cabinet(), "rooms", "itmgr", "cabinet.png")
    save(spr_desk(180, 72, "#a8a888", "#7a7a60"), "rooms", "itmgr", "desk.png")
    save(spr_mgr_computer(), "rooms", "itmgr", "computer.png")
    save(spr_drawer_lock(), "rooms", "itmgr", "drawer.png")
    save(spr_drawer_lock(True), "rooms", "itmgr", "drawer_unlocked.png")
    save(spr_closet_shelves(), "rooms", "closet", "shelf.png")
    save(spr_flashlight(), "rooms", "closet", "flashlight.png")
    save(spr_spare_fuse(), "rooms", "closet", "fuse.png")
    save(spr_mop(), "rooms", "closet", "mop.png")
    save(spr_wet_floor_sign(), "rooms", "basement", "sign.png")
    save(spr_bucket(), "rooms", "basement", "bucket.png")
    save(spr_lobby_sign(), "rooms", "lobby", "sign.png")
    save(spr_office_computer(), "rooms", "office", "computer.png")



def monkey_sheet():
    # Frames: 0 = standing, 1..4 = walk cycle, 5..7 = the tail straightening (coffee!): a third, two thirds, fully straight.
    FW, FH, N, DX, EXTRA = 48, 48, 5, 12, 3  # frame is 48 wide; body (32 wide) sits DX px in, body center x=28
    sheet = Image.new("RGBA", (FW * (N + EXTRA), FH), (0, 0, 0, 0))
    fur, light = C["fur"], C["tan"]
    for i in range(N + EXTRA):
        stage = (i - N + 1) / EXTRA if i >= N else 0.0                  # 0 = curled ... 1 = straight
        im, d = new(32, FH)
        walk = 0 < i < N
        ph = (i - 1) % 4 if walk else 0
        bob = 1 if walk and ph in (1, 3) else 0
        lift = [0, 3, 0, 0][ph] if walk else 0
        lift2 = [0, 0, 0, 3][ph] if walk else 0
        arm = [0, 3, 0, -3][ph] if walk else 0
        box(d, 10, 38, 15, 47 - lift, "#52290a")                      # legs
        box(d, 17, 38, 22, 47 - lift2, "#52290a")
        box(d, 9, 22 - bob, 23, 39 - bob, fur)                         # body
        box(d, 12, 26 - bob, 21, 37 - bob, light)
        box(d, 12, 31 - bob, 20, 33 - bob, C["green"])                  # hoodie stripe
        box(d, 5, 25 - bob + arm // 2, 9, 35 - bob + arm // 2, fur)    # arms
        box(d, 23, 25 - bob - arm // 2, 27, 35 - bob - arm // 2, fur)
        box(d, 8, 6 - bob, 24, 23 - bob, fur)                          # head
        box(d, 4, 11 - bob, 8, 18 - bob, light); box(d, 24, 11 - bob, 28, 18 - bob, light)  # ears
        box(d, 11, 12 - bob, 23, 21 - bob, light)                      # face
        box(d, 14, 14 - bob, 16, 17 - bob, C["dark"]); box(d, 19, 14 - bob, 21, 17 - bob, C["dark"])
        box(d, 15, 19 - bob, 20, 20 - bob, C["dbrown"])
        box(d, 8, 7 - bob, 24, 10 - bob, C["red"])                      # headband
        box(d, 4, 8 - bob, 8, 10 - bob, C["red"])
        frame, fd = new(FW, FH)
        pts = tail_points(bob)
        if stage > 0.0:                                                 # blend each point toward a straight tail up and out
            x0, y0 = pts[0]
            n = len(pts) - 1
            straight = [(x0 + (3 - x0) * k / n, y0 + (4 - y0) * k / n) for k in range(n + 1)]
            pts = [(a[0] + (b[0] - a[0]) * stage, a[1] + (b[1] - a[1]) * stage) for a, b in zip(pts, straight)]
        fd.line(pts, fill="#a0662c", width=2)                           # tail, drawn behind the body
        ex, ey = pts[-1]
        box(fd, int(ex) - 1, int(ey) - 1, int(ex) + 1, int(ey) + 1, light)  # tail tip
        frame.alpha_composite(im, (DX, 0))
        alpha = frame.getchannel("A").filter(ImageFilter.MaxFilter(3))  # 1px outline
        out = Image.new("RGBA", (FW, FH), C["dark"])
        out.putalpha(alpha)
        out.alpha_composite(frame)
        sheet.paste(out, (i * FW, 0))
    return sheet


# name -> (image, rect x, y, sort_y or None) used by --preview
OFFICE = {"poster": (60, 48), "desk": (200, 168), "mug": (224, 150), "drawer": (300, 200), "door": (536, 112)}
HALL = {"door": (20, 100)}


def main():
    if "icons" in sys.argv:  # only the inventory icons (leaves the room art alone)
        make_icons()
        return
    if "more" in sys.argv:  # only the basement, IT, closet, lobby sign and office computer sprites
        make_more_objects()
        return
    if "floors" in sys.argv:  # only the 2nd and 3rd floor object sprites
        make_floor_objects()
        return
    if "objects" in sys.argv:  # only the break room and lobby object sprites
        make_objects()
        return
    if "doors" in sys.argv:  # only the door sprites and the elevator panel plate
        make_doors()
        return
    if "backgrounds" in sys.argv:  # only the backgrounds of the newer rooms
        make_backgrounds()
        return
    save(office_bg(), "rooms", "office", "background.png")
    save(hallway_bg(), "rooms", "hallway", "background.png")
    save(poster(), "rooms", "office", "poster.png")
    save(desk(), "rooms", "office", "desk.png")
    save(mug(), "rooms", "office", "mug.png")
    save(clip_sprite(), "rooms", "office", "clip.png")
    save(drawer(), "rooms", "office", "drawer.png")
    save(drawer("open"), "rooms", "office", "drawer_open.png")
    save(door(), "rooms", "office", "door.png")
    save(door(), "rooms", "hallway", "door.png")
    save(monkey_sheet(), "characters", "player.png")
    save(server_bg(), "rooms", "server", "background.png")
    save(door(), "rooms", "server", "door.png")
    for n in ("rack_a", "rack_b", "rack_c"):
        save(rack(), "rooms", "server", n + ".png")
    save(dale(), "rooms", "server", "dale.png")
    save(console(), "rooms", "server", "console.png")
    save(icon_paperclip(), "items", "paperclip.png")
    save(icon_keycard(), "items", "keycard.png")
    make_icons()
    make_backgrounds()
    make_doors()
    make_objects()
    make_floor_objects()
    make_more_objects()
    if "--preview" in sys.argv:
        out = sys.argv[sys.argv.index("--preview") + 1]
        sheet = Image.new("RGBA", (W, H * 2 + 8), (0, 0, 0, 255))
        for row, (room, items) in enumerate((("office", OFFICE), ("hallway", HALL))):
            base = Image.open(f"assets/rooms/{room}/background.png").convert("RGBA")
            for n, (x, y) in items.items():
                base.alpha_composite(Image.open(f"assets/rooms/{room}/{n}.png"), (x, y))
            mk = monkey_sheet().crop((48, 0, 96, 48))
            base.alpha_composite(mk, (320 - 28, 236 - 48))
            sheet.paste(base, (0, row * (H + 8)))
        sheet.save(out)


if __name__ == "__main__":
    main()
