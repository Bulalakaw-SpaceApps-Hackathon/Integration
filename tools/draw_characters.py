"""Pixel-art characters for Bulalakaw Station, based on the team's hand-drawn sheets
(assets/source/characters/CH-01..05, CH-06 EVA suits, CH-07/08 portraits, CH-09 heads).

Writes into assets/sprites/characters/:
  char_commander.png, crew_<id>.png, crew_<id>_eva.png
      one row of 16 frames, 32x48 each: walk DOWN 0-3, LEFT 4-7, RIGHT 8-11, UP 12-15
      (frame 0 of each direction is the standing pose)
  portrait_<id>.png   3 frames of 96x96: happy, worried, neutral (pixelized from the drawings)
  head_<id>.png       24x24 (pixelized from the drawings)
and updates data/assets.json so the game knows the new sizes.

Usage: python3 tools/draw_characters.py <project root>
"""
import sys, os, json
from PIL import Image, ImageDraw

ROOT = sys.argv[1]
SRC = ROOT + "/assets/source/characters/"
OUT = ROOT + "/assets/sprites/characters/"
def H(h): return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
INK, WHITE, CLEAR = H("2b1a2e"), H("fff6ec"), (0, 0, 0, 0)
SUIT, SUIT_D, SHOE = H("2f4fe0"), H("1f2f9c"), H("2b1a2e")
BLUSH = H("f08a6a")
W, HH = 32, 48

# id: skin, skin shade, hair, hair shade, style, extras
CHARS = {
    "commander": dict(skin=H("ffd9b8"), hair=H("2b2630"), hair_d=H("15121a"), style="bob"),
    "lani":      dict(skin=H("f0b88a"), hair=H("ff3fd0"), hair_d=H("c020a0"), style="braid", glasses=True),
    "maya":      dict(skin=H("ffe3c8"), hair=H("ffe400"), hair_d=H("d0a800"), style="long", sprout=True),
    "mateo":     dict(skin=H("b9794c"), hair=H("35c9d8"), hair_d=H("1f8fa0"), style="spiky"),
    "carlo":     dict(skin=H("ffe3c8"), hair=H("3fe04a"), hair_d=H("20a030"), style="curly"),
}
SRC_ID = {"commander": "CH-01", "lani": "CH-02", "maya": "CH-03", "mateo": "CH-04", "carlo": "CH-05"}
EVA = {"lani": (H("ff8fe0"), H("d050b0"), "arrow"), "maya": (H("ffe9a0"), H("d0b050"), "sprout"),
       "mateo": (H("a8f0f4"), H("50b8c8"), "ball"), "carlo": (H("b8f4b0"), H("58c060"), "prop")}
VISOR, VISOR_L = H("5fe8ff"), H("c8fbff")


def outline(im):
    """1 px INK outline around everything opaque (the game's sprite style)."""
    px = im.load(); out = im.copy(); op = out.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0 and any(0 <= x + dx < w and 0 <= y + dy < h and px[x + dx, y + dy][3] > 0
                                        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                op[x, y] = INK
    return out


def legs(d, view, ph, col, bob):
    """Two legs + shoes. ph 0/2 = feet together, 1 = left (near) foot forward, 3 = right."""
    top = 37 + bob
    if view in ("down", "up"):
        for i, x in enumerate((11, 17)):
            lift = 2 if (ph == 1 and i == 0) or (ph == 3 and i == 1) else 0
            d.rectangle((x, top, x + 3, 44 - lift), fill=col)
            d.rectangle((x, 44 - lift, x + 3, 45 - lift), fill=SHOE)
    else:
        s = {0: (0, 0), 1: (3, -3), 2: (0, 0), 3: (-3, 3)}[ph]
        for i, dx in enumerate(s):
            x = 14 + dx
            lift = 1 if dx != 0 and i == 1 else 0
            d.rectangle((x, top, x + 3, 44 - lift), fill=col if i == 0 else SUIT_D if col == SUIT else col)
            d.rectangle((x, 44 - lift, x + 4, 45 - lift), fill=SHOE)


def body(d, view, ph, col, col_d, skin, bob):
    y0 = 27 + bob
    swing = {0: 0, 1: 2, 2: 0, 3: -2}[ph]
    if view in ("down", "up"):
        d.rectangle((10, y0, 21, 38 + bob), fill=col)
        d.line((10, 38 + bob, 21, 38 + bob), fill=col_d)
        for i, x in enumerate((8, 22)):                       # arms swing opposite to the legs
            dy = swing if i == 0 else -swing
            d.rectangle((x, y0 + 1, x + 1, y0 + 7 + dy // 2), fill=col)
            d.rectangle((x, y0 + 8 + dy // 2, x + 1, y0 + 9 + dy // 2), fill=skin)
        if view == "down":
            d.line((14, y0, 17, y0), fill=WHITE)             # collar
    else:
        d.rectangle((11, y0, 20, 38 + bob), fill=col)
        d.line((11, 38 + bob, 20, 38 + bob), fill=col_d)
        ax = 15 + swing
        d.rectangle((ax, y0 + 2, ax + 2, y0 + 8), fill=col_d)
        d.rectangle((ax, y0 + 9, ax + 2, y0 + 10), fill=skin)


def head(d, view, c, bob, worried=False):
    y0 = 6 + bob
    skin = c["skin"]
    if view == "right":
        d.ellipse((6, y0, 26, y0 + 21), fill=skin)
    else:
        d.ellipse((5, y0, 26, y0 + 21), fill=skin)
    hair, hd = c["hair"], c["hair_d"]
    st = c["style"]
    # ---- hair (drawn per view)
    if view == "down":
        d.pieslice((5, y0 - 1, 26, y0 + 20), 180, 360, fill=hair)                # cap
        d.rectangle((5, y0 + 9, 7, y0 + 13), fill=hair); d.rectangle((24, y0 + 9, 26, y0 + 13), fill=hair)
        d.rectangle((8, y0 + 8, 23, y0 + 9), fill=hair)                          # fringe
        if st == "bob":
            d.rectangle((5, y0 + 9, 7, y0 + 17), fill=hair); d.rectangle((24, y0 + 9, 26, y0 + 17), fill=hair)
            d.polygon([(10, y0 + 9), (15, y0 + 12), (12, y0 + 9)], fill=hair)
        if st == "braid":
            for x in range(6, 26, 4): d.ellipse((x, y0 - 3, x + 4, y0 + 2), fill=hair)       # swept-up waves
            for k in range(4): d.ellipse((23 - k % 2, y0 + 14 + k * 4, 27 - k % 2, y0 + 18 + k * 4), fill=hd if k % 2 else hair)
        if st == "long":
            d.rectangle((4, y0 + 8, 7, y0 + 27), fill=hair); d.rectangle((24, y0 + 8, 27, y0 + 27), fill=hair)
            d.line((7, y0 + 10, 7, y0 + 27), fill=hd); d.line((24, y0 + 10, 24, y0 + 27), fill=hd)
        if st == "spiky":
            for x in (6, 11, 16, 21): d.polygon([(x, y0 + 2), (x + 3, y0 - 6), (x + 5, y0 + 2)], fill=hair)
            d.polygon([(3, y0 + 8), (6, y0 + 2), (8, y0 + 8)], fill=hair)
        if st == "curly":
            for (x, y) in ((3, 2), (8, -3), (14, -4), (20, -3), (24, 2), (3, 8), (25, 8)):
                d.ellipse((x, y0 + y, x + 6, y0 + y + 6), fill=hair)
            for (x, y) in ((9, 1), (17, 0), (22, 5)): d.point((x, y0 + y), fill=hd)
        # ---- face
        ey = y0 + 12
        for x in (10, 19):
            d.rectangle((x, ey, x + 1, ey + 2), fill=INK)
            d.point((x, ey), fill=WHITE)
        d.point((8, ey + 4), fill=BLUSH); d.point((23, ey + 4), fill=BLUSH)
        if worried: d.line((14, ey + 6, 17, ey + 6), fill=INK)
        else: d.line((14, ey + 5, 17, ey + 5), fill=H("c0503a"))
        if c.get("glasses"):
            d.rectangle((8, ey - 1, 13, ey + 3), outline=H("8a8fa0")); d.rectangle((17, ey - 1, 22, ey + 3), outline=H("8a8fa0"))
            d.line((13, ey + 1, 17, ey + 1), fill=H("8a8fa0"))
    elif view == "up":
        d.ellipse((5, y0 - 1, 26, y0 + 18), fill=hair)                            # back of the head: all hair
        d.rectangle((5, y0 + 8, 26, y0 + 15), fill=hair)
        d.line((9, y0 + 16, 22, y0 + 16), fill=hd)
        if st == "braid":
            for k in range(4): d.ellipse((13, y0 + 15 + k * 4, 18, y0 + 20 + k * 4), fill=hd if k % 2 else hair)
            for x in range(6, 26, 4): d.ellipse((x, y0 - 3, x + 4, y0 + 2), fill=hair)
        if st == "long":
            d.rectangle((4, y0 + 8, 27, y0 + 27), fill=hair)
            for x in (9, 15, 21): d.line((x, y0 + 12, x, y0 + 27), fill=hd)
        if st == "spiky":
            for x in (6, 11, 16, 21): d.polygon([(x, y0 + 2), (x + 3, y0 - 6), (x + 5, y0 + 2)], fill=hair)
        if st == "curly":
            for (x, y) in ((3, 2), (8, -3), (14, -4), (20, -3), (24, 2), (3, 8), (25, 8), (6, 13), (20, 13), (13, 14)):
                d.ellipse((x, y0 + y, x + 6, y0 + y + 6), fill=hair)
        if st == "bob":
            d.rectangle((5, y0 + 8, 26, y0 + 18), fill=hair)
    else:   # right-facing profile (left is this, mirrored)
        d.pieslice((6, y0 - 1, 26, y0 + 20), 170, 350, fill=hair)
        d.rectangle((6, y0 + 8, 13, y0 + 15), fill=hair)                          # hair covers the back half
        d.rectangle((14, y0 + 7, 21, y0 + 8), fill=hair)
        if st == "bob": d.rectangle((6, y0 + 8, 12, y0 + 18), fill=hair)
        if st == "braid":
            for x in range(7, 24, 4): d.ellipse((x, y0 - 3, x + 4, y0 + 2), fill=hair)
            for k in range(4): d.ellipse((7, y0 + 14 + k * 4, 12, y0 + 19 + k * 4), fill=hd if k % 2 else hair)
        if st == "long":
            d.rectangle((5, y0 + 8, 12, y0 + 27), fill=hair); d.line((12, y0 + 10, 12, y0 + 27), fill=hd)
        if st == "spiky":
            for x in (7, 12, 17): d.polygon([(x, y0 + 2), (x - 1, y0 - 6), (x + 5, y0 + 2)], fill=hair)
        if st == "curly":
            for (x, y) in ((3, 3), (7, -3), (13, -4), (19, -3), (4, 9), (6, 14), (22, 2)):
                d.ellipse((x, y0 + y, x + 6, y0 + y + 6), fill=hair)
        ey = y0 + 12
        d.rectangle((20, ey, 21, ey + 2), fill=INK); d.point((20, ey), fill=WHITE)
        d.point((23, ey + 4), fill=BLUSH)
        d.line((22, ey + 6, 24, ey + 6), fill=H("c0503a") if not worried else INK)
        if c.get("glasses"):
            d.rectangle((18, ey - 1, 23, ey + 3), outline=H("8a8fa0")); d.line((13, ey + 1, 18, ey + 1), fill=H("8a8fa0"))
    if c.get("sprout"):
        sx = 15 if view != "right" else 16
        d.line((sx, y0 - 2, sx, y0 - 6), fill=H("38a918"))
        d.ellipse((sx - 5, y0 - 9, sx - 1, y0 - 5), fill=H("6fc60c")); d.ellipse((sx + 1, y0 - 9, sx + 5, y0 - 5), fill=H("6fc60c"))


def person(c, view, ph):
    im = Image.new("RGBA", (W, HH), CLEAR); d = ImageDraw.Draw(im)
    bob = -1 if ph in (1, 3) else 0
    v = "right" if view == "left" else view
    legs(d, v, ph, SUIT, bob)
    body(d, v, ph, SUIT, SUIT_D, c["skin"], bob)
    head(d, v, c, bob)
    im = outline(im)
    return im.transpose(Image.FLIP_LEFT_RIGHT) if view == "left" else im


def eva(who, view, ph):
    col, col_d, top = EVA[who]
    im = Image.new("RGBA", (W, HH), CLEAR); d = ImageDraw.Draw(im)
    bob = -1 if ph in (1, 3) else 0
    v = "right" if view == "left" else view
    # chunky suit: boots, legs, torso, backpack, gloves
    legs(d, v, ph, col, bob)
    y0 = 26 + bob
    swing = {0: 0, 1: 2, 2: 0, 3: -2}[ph]
    if v in ("down", "up"):
        d.rectangle((9, y0, 22, 38 + bob), fill=col)
        d.rectangle((9, 37 + bob, 22, 38 + bob), fill=col_d)
        for i, x in enumerate((6, 23)):
            dy = (swing if i == 0 else -swing) // 2
            d.rectangle((x, y0 + 1, x + 2, y0 + 8 + dy), fill=col)
            d.rectangle((x, y0 + 9 + dy, x + 2, y0 + 10 + dy), fill=col_d)
        if v == "down":
            d.rectangle((13, y0 + 3, 18, y0 + 7), fill=col_d); d.point((14, y0 + 4), fill=VISOR)   # chest pack
        else:
            d.rectangle((11, y0 + 1, 20, y0 + 9), fill=col_d)                                       # backpack
    else:
        d.rectangle((8, y0 + 1, 11, y0 + 10), fill=col_d)                                           # backpack behind
        d.rectangle((11, y0, 21, 38 + bob), fill=col)
        ax = 15 + swing
        d.rectangle((ax, y0 + 2, ax + 2, y0 + 9), fill=col_d)
    # helmet + visor
    hy = 4 + bob
    d.ellipse((4, hy, 27, hy + 23), fill=col)
    if v == "down":
        d.rounded_rectangle((7, hy + 6, 24, hy + 18), radius=5, fill=VISOR)
        d.line((9, hy + 8, 13, hy + 8), fill=VISOR_L)
    elif v == "right":
        d.rounded_rectangle((14, hy + 6, 27, hy + 18), radius=5, fill=VISOR)
        d.line((17, hy + 8, 21, hy + 8), fill=VISOR_L)
        d.rectangle((6, hy + 9, 9, hy + 15), fill=col_d)                                            # ear cup
    else:
        d.line((8, hy + 12, 23, hy + 12), fill=col_d)
    # antenna top, one per crew member (as in the sketches)
    ax = 15 if v != "right" else 13
    d.line((ax, hy, ax, hy - 3), fill=col_d)
    if top == "arrow": d.polygon([(ax - 2, hy - 3), (ax + 2, hy - 3), (ax, hy - 6)], fill=col_d)
    if top == "sprout":
        d.ellipse((ax - 4, hy - 6, ax - 1, hy - 3), fill=H("6fc60c")); d.ellipse((ax + 1, hy - 6, ax + 4, hy - 3), fill=H("6fc60c"))
    if top == "ball": d.ellipse((ax - 2, hy - 6, ax + 2, hy - 2), fill=col_d)
    if top == "prop": d.line((ax - 4, hy - 4, ax + 4, hy - 4), fill=col_d)
    im = outline(im)
    return im.transpose(Image.FLIP_LEFT_RIGHT) if view == "left" else im


def sheet(fn):
    s = Image.new("RGBA", (W * 16, HH), CLEAR)
    i = 0
    for view in ("down", "left", "right", "up"):
        for ph in range(4):
            s.paste(fn(view, ph), (i * W, 0)); i += 1
    return s


# ---------------------------------------------------------------- portraits and heads from the drawings
def cutout(path):
    """Drawing on white -> transparent background (flood fill from the border, so white eyes stay)."""
    im = Image.open(path).convert("RGBA")
    im.thumbnail((384, 384), Image.LANCZOS)
    w, h = im.size
    for seed in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1), (w // 2, 0)):
        if im.getpixel(seed)[:3] > (235, 235, 235):
            ImageDraw.floodfill(im, seed, (0, 0, 0, 0), thresh=60)
    return im.crop(im.getbbox())


def pixelize(im, size):
    """Shrink to size x size, few flat colours, hard edges, INK outline."""
    w, h = im.size
    s = (size - 2) / max(w, h)
    small = im.resize((max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)
    a = small.getchannel("A").point(lambda v: 255 if v > 120 else 0)
    rgb = small.convert("RGB").quantize(colors=14, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGB")
    px = rgb.load()
    for y in range(rgb.height):                                   # the artists' black lines -> the game's INK
        for x in range(rgb.width):
            r, g, b = px[x, y]
            if r + g + b < 110: px[x, y] = INK[:3]
    small = rgb.convert("RGBA"); small.putalpha(a)
    out = Image.new("RGBA", (size, size), CLEAR)
    out.alpha_composite(small, ((size - small.width) // 2, size - 1 - small.height))
    return outline(out)


man_p = ROOT + "/data/assets.json"
man = json.load(open(man_p))
def reg(name, w, h, frames):
    man[name]["w"], man[name]["h"], man[name]["frames"] = w, h, frames

for who, c in CHARS.items():
    name = "char_commander" if who == "commander" else "crew_" + who
    sheet(lambda v, p, c=c: person(c, v, p)).save(OUT + name + ".png"); reg(name, W, HH, 16)
    if who in EVA:
        sheet(lambda v, p, who=who: eva(who, v, p)).save(OUT + "crew_%s_eva.png" % who); reg("crew_%s_eva" % who, W, HH, 16)
    sid = SRC_ID[who]
    role = {"commander": "Commander", "lani": "Engineer", "maya": "Botanist", "mateo": "Doctor", "carlo": "EVA"}[who]
    frames = [pixelize(cutout(SRC + "CH-07/portrait_%s_%s.png" % (sid, mood)), 96) for mood in ("happy", "worried")]
    frames.append(pixelize(cutout(SRC + "CH-08/portrait_mission_control_%s.png" % role), 96))
    p = Image.new("RGBA", (96 * 3, 96), CLEAR)
    for i, f in enumerate(frames): p.paste(f, (i * 96, 0))
    p.save(OUT + "portrait_%s.png" % who); reg("portrait_%s" % who, 96, 96, 3)
    if who != "commander":
        # the head files for CH-04 and CH-05 are swapped in the source pack (04 is the green curly hair)
        hid = {"CH-04": "CH-05", "CH-05": "CH-04"}.get(sid, sid)
        pixelize(cutout(SRC + "CH-09/head_%s.png" % hid), 24).save(OUT + "head_%s.png" % who); reg("head_%s" % who, 24, 24, 1)
# the Commander has no head drawing: use the top of the happy portrait
hc = cutout(SRC + "CH-07/portrait_CH-01_happy.png")
hc = hc.crop((0, 0, hc.width, int(hc.height * 0.62)))
pixelize(hc.crop(hc.getbbox()), 24).save(OUT + "head_commander.png")
man["head_commander"] = {"id": "CH-09", "path": "res://assets/sprites/characters/head_commander.png", "w": 24, "h": 24, "frames": 1, "kind": "image"}
json.dump(man, open(man_p, "w"), indent=1)
print("characters written")
