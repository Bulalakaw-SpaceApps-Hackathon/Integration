"""Minigame props + the materials icon in map style: flat pixel art, 1 px ink outline, game
palette, light from the top-left. Drawn small and shown at exactly 2x by TaskGame.gd.

Usage: python3 -I tools/draw_task_props.py assets/sprites/tasks assets/sprites/ui data/assets.json
"""
import json, math, os, sys
from PIL import Image, ImageDraw

OUT, UI, MAN = sys.argv[1], sys.argv[2], sys.argv[3]
def C(h): return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
INK, PLUM, DPLUM, MAUVE, STONE, CREAM, WHITE = C("2b1a2e"), C("684266"), C("552465"), C("9b828b"), C("cbb7b3"), C("eedbc8"), C("fff6ec")
ORANGE, DORANGE, GOLD, YEL, RED = C("ff6d00"), C("c44e00"), C("fca54a"), C("fee400"), C("c3002b")
ICE, BLUE, NAVY, WATER, DWATER = C("86bdc8"), C("5148ab"), C("2c2450"), C("4fa3ff"), C("2f6fd0")
GREEN, LIME, DGREEN = C("6fc60c"), C("a2e747"), C("38a918")
SAND, SAND_L, SAND_D, RUST = C("d8a070"), C("eec39a"), C("a8683e"), C("8a3a28")
STEEL, STEEL_L, STEEL_D = C("8f9bb0"), C("c4cfdd"), C("5d6880")
CLEAR = (0, 0, 0, 0)
made = {}


def new(w, h):
    im = Image.new("RGBA", (w, h), CLEAR); return im, ImageDraw.Draw(im)


def put(name, frames, folder=None, ident="TK-P"):
    w, h = frames[0].size
    out = Image.new("RGBA", (w * len(frames), h), CLEAR)
    for i, f in enumerate(frames): out.alpha_composite(f, (i * w, 0))
    folder = folder or OUT
    out.save(os.path.join(folder, name + ".png"))
    rel = "res://" + os.path.join(folder, name + ".png").replace("\\", "/")
    made[name] = {"id": ident, "path": rel, "w": w, "h": h, "frames": len(frames), "kind": "image"}


def box(d, b, fill, hi=None, sh=None):
    x0, y0, x1, y1 = b
    d.rectangle(b, fill=INK); d.rectangle((x0 + 1, y0 + 1, x1 - 1, y1 - 1), fill=fill)
    if hi: d.line((x0 + 1, y0 + 1, x1 - 2, y0 + 1), fill=hi); d.line((x0 + 1, y0 + 1, x0 + 1, y1 - 2), fill=hi)
    if sh: d.line((x1 - 1, y0 + 2, x1 - 1, y1 - 1), fill=sh); d.line((x0 + 2, y1 - 1, x1 - 1, y1 - 1), fill=sh)


# ------------------------------------------------------------------ materials: stack of metal plates
def materials():
    im, d = new(32, 32)
    for k, (y, col, hi, sh) in enumerate(((20, STEEL_D, STEEL, INK), (14, STEEL, STEEL_L, STEEL_D), (8, STEEL_L, WHITE, STEEL))):
        x = 2 + k                                          # each plate sits a little to the right
        d.polygon([(x + 5, y), (x + 26, y), (x + 21, y + 8), (x, y + 8)], fill=col, outline=INK)
        d.line((x + 6, y + 1, x + 24, y + 1), fill=hi)
        d.polygon([(x, y + 8), (x + 21, y + 8), (x + 21, y + 11), (x, y + 11)], fill=sh if sh != INK else STEEL_D, outline=INK)
        for rx, ry in ((x + 7, y + 2), (x + 22, y + 2), (x + 3, y + 6), (x + 18, y + 6)):
            d.point((rx, ry), fill=INK)                    # rivets
    d.line((12, 10, 16, 10), fill=WHITE); d.line((20, 9, 23, 9), fill=WHITE)   # shine on the top plate
    put("icon_materials", [im.resize((64, 64), Image.NEAREST)], UI, "SC-04")


# ------------------------------------------------------------------ plug + socket (loose cable)
def plug():
    im, d = new(44, 44)
    c = 22
    d.ellipse((1, 1, 42, 42), fill=INK); d.ellipse((2, 2, 41, 41), fill=ORANGE)
    d.arc((4, 4, 39, 39), 190, 280, fill=GOLD, width=2)                # light from the top-left
    d.arc((3, 3, 40, 40), 10, 100, fill=DORANGE, width=2)
    d.ellipse((8, 8, 35, 35), fill=INK); d.ellipse((9, 9, 34, 34), fill=CREAM)
    for k in range(4):                                                 # four metal pins
        a = math.pi / 4 + k * math.pi / 2
        x, y = c + 8 * math.cos(a), c + 8 * math.sin(a)
        d.ellipse((x - 3, y - 3, x + 2, y + 2), fill=INK); d.ellipse((x - 2, y - 2, x + 1, y + 1), fill=STEEL_L)
    d.ellipse((c - 2, c - 2, c + 1, c + 1), fill=MAUVE)
    d.polygon([(c - 4, 1), (c + 3, 1), (c + 3, 8), (c - 4, 8)], fill=INK)   # the yellow key notch (points up at angle 0)
    d.rectangle((c - 3, 2, c + 2, 7), fill=YEL); d.line((c - 3, 2, c + 2, 2), fill=WHITE)
    put("task_plug", [im])


def socket():
    im, d = new(70, 70)
    box(d, (0, 4, 69, 69), STONE, WHITE, MAUVE)
    box(d, (3, 7, 66, 66), CREAM, WHITE, STONE)
    for x, y in ((6, 10), (62, 10), (6, 62), (62, 62)):               # corner bolts
        d.rectangle((x - 1, y - 1, x + 1, y + 1), fill=INK); d.point((x, y), fill=STEEL_L)
    d.ellipse((8, 12, 61, 65), fill=INK); d.ellipse((10, 14, 59, 63), fill=PLUM)
    d.arc((11, 15, 58, 62), 20, 110, fill=MAUVE, width=2)             # the socket is a hole: light on its far rim
    d.ellipse((13, 17, 56, 60), fill=DPLUM)
    d.polygon([(29, 0), (40, 0), (35, 8), (34, 8)], fill=YEL, outline=INK)   # marker: line the notch up here
    put("task_socket", [im])


def lamp():
    frames = []
    for on in (False, True):
        im, d = new(12, 12)
        d.ellipse((0, 0, 11, 11), fill=INK); d.ellipse((1, 1, 10, 10), fill=GREEN if on else PLUM)
        d.point((3, 3), fill=LIME if on else MAUVE); d.point((4, 3), fill=LIME if on else MAUVE)
        frames.append(im)
    put("task_lamp", frames)


# ------------------------------------------------------------------ sandbag wall (shelter)
def sandbag():
    frames = []
    for v in range(2):
        im, d = new(30, 15)
        d.rounded_rectangle((0, 1, 29, 14), 5, fill=INK); d.rounded_rectangle((1, 2, 28, 13), 4, fill=SAND)
        d.line((5, 3, 23, 3), fill=SAND_L); d.line((3, 5, 3, 9), fill=SAND_L)
        d.line((5, 12, 25, 12), fill=SAND_D); d.line((27, 6, 27, 10), fill=SAND_D)
        d.line((8 + v * 6, 6, 12 + v * 6, 9), fill=SAND_D)             # a crease, different on each bag
        d.rectangle((25, 0, 29, 3), fill=INK); d.rectangle((26, 1, 28, 2), fill=CREAM)   # the tied corner
        frames.append(im)
    put("task_sandbag", frames)


def marker():
    im, d = new(22, 84)
    d.rectangle((0, 12, 5, 83), fill=INK)
    for y in range(13, 83, 6):
        d.rectangle((1, y, 4, min(82, y + 5)), fill=YEL if (y // 6) % 2 else INK)
    d.rectangle((0, 0, 21, 11), fill=INK); d.rectangle((1, 1, 20, 10), fill=GREEN); d.line((2, 2, 19, 2), fill=LIME)
    d.line((4, 6, 8, 9), fill=WHITE); d.line((8, 9, 16, 3), fill=WHITE)   # a tick: "safe up to here"
    put("task_marker", [im])


# ------------------------------------------------------------------ dust (panel sweep)
def dust():
    frames = []
    for v in range(2):
        im, d = new(24, 24)
        blobs = ((3, 8, 14, 20), (8, 4, 21, 17), (10, 10, 22, 22)) if v == 0 else ((2, 6, 16, 18), (9, 9, 22, 21), (6, 2, 18, 13))
        for b in blobs: d.ellipse(b, fill=SAND_D)
        for b in blobs: d.ellipse((b[0] + 1, b[1], b[2] - 1, b[3] - 2), fill=SAND)
        d.ellipse((blobs[1][0] + 2, blobs[1][1] + 1, blobs[1][0] + 7, blobs[1][1] + 5), fill=SAND_L)
        for x, y in ((6, 14), (15, 9), (17, 17), (11, 19)): d.point((x, y), fill=RUST)
        frames.append(im)
    put("task_dust", frames)


# ------------------------------------------------------------------ oxygen maker (MOXIE)
def moxie():
    im, d = new(64, 54)
    box(d, (0, 4, 63, 53), GOLD, YEL, DORANGE)
    box(d, (4, 8, 59, 22), NAVY)                                       # heater window (the game draws the glow)
    for x in range(8, 58, 6): d.line((x, 26, x, 30), fill=DORANGE)     # vents
    box(d, (6, 34, 57, 49), CREAM, WHITE, STONE)                       # name plate (text drawn by the game)
    d.rectangle((10, 0, 17, 4), fill=INK); d.rectangle((11, 1, 16, 4), fill=STONE)   # inlet
    d.rectangle((46, 0, 53, 4), fill=INK); d.rectangle((47, 1, 52, 4), fill=ICE)     # outlet
    put("task_moxie", [im])
    im, d = new(24, 56)                                                # oxygen tank shell (fill drawn by the game)
    d.rounded_rectangle((0, 4, 23, 55), 6, fill=INK); d.rounded_rectangle((1, 5, 22, 54), 5, fill=NAVY)
    d.rectangle((8, 0, 15, 5), fill=INK); d.rectangle((9, 1, 14, 4), fill=STEEL_L)
    d.line((3, 10, 3, 48), fill=PLUM)
    put("task_tank", [im])
    im, d = new(26, 96)                                                # thermometer shell
    d.rounded_rectangle((0, 0, 25, 95), 6, fill=INK); d.rounded_rectangle((1, 1, 24, 94), 5, fill=STONE)
    d.rectangle((4, 4, 21, 91), fill=INK); d.rectangle((5, 5, 20, 90), fill=NAVY)
    put("task_thermo", [im])
    frames = []
    for down in (False, True):
        im, d = new(70, 30)
        o = 2 if down else 0
        d.rounded_rectangle((0, 4, 69, 29), 5, fill=INK)                # base
        d.rounded_rectangle((0, o, 69, 25 + o), 5, fill=INK)
        d.rounded_rectangle((1, 1 + o, 68, 24 + o), 4, fill=ORANGE if down else CREAM)
        d.line((5, 2 + o, 64, 2 + o), fill=GOLD if down else WHITE)
        d.line((5, 23 + o, 64, 23 + o), fill=DORANGE if down else STONE)
        frames.append(im)
    put("task_heat_button", frames)


# ------------------------------------------------------------------ airlock leak patch
def patch():
    im, d = new(14, 14)
    box(d, (0, 0, 13, 13), STEEL, STEEL_L, STEEL_D)
    for x, y in ((2, 2), (11, 2), (2, 11), (11, 11)): d.point((x, y), fill=INK)
    d.line((4, 9, 9, 4), fill=STEEL_L)
    put("task_patch", [im])


# ------------------------------------------------------------------ water leak (greenhouse)
def water():
    im, d = new(16, 10)                                                # tileable pipe
    d.rectangle((0, 0, 15, 9), fill=INK); d.rectangle((0, 1, 15, 8), fill=STEEL)
    d.line((0, 2, 15, 2), fill=STEEL_L); d.line((0, 7, 15, 7), fill=STEEL_D)
    d.rectangle((6, 0, 9, 9), fill=INK); d.rectangle((7, 1, 8, 8), fill=STEEL_D)   # joint
    put("task_pipe", [im])
    im, d = new(18, 16)                                                # clamp
    box(d, (0, 0, 17, 15), YEL, WHITE, GOLD)
    d.rectangle((7, 3, 10, 12), fill=INK); d.rectangle((8, 4, 9, 11), fill=STEEL_L)
    put("task_clamp", [im])
    im, d = new(7, 10)                                                 # drop
    d.polygon([(3, 0), (6, 6), (5, 9), (1, 9), (0, 6)], fill=WATER, outline=INK)
    d.point((2, 5), fill=WHITE)
    put("task_drop", [im])
    im, d = new(28, 16)                                                # bucket (water level drawn by the game)
    d.polygon([(0, 0), (27, 0), (24, 15), (3, 15)], fill=INK)
    d.polygon([(2, 1), (25, 1), (23, 14), (4, 14)], fill=CREAM)
    d.line((3, 2, 24, 2), fill=WHITE); d.line((22, 4, 21, 13), fill=STONE)
    put("task_cup", [im])


# ------------------------------------------------------------------ dish + Earth + crosshair
def dish():
    im, d = new(32, 32)                                                # dish head, pointing right at angle 0
    d.pieslice((4, 1, 40, 30), 90, 270, fill=INK); d.pieslice((6, 3, 38, 28), 90, 270, fill=CREAM)
    d.pieslice((10, 7, 34, 24), 90, 270, fill=STONE)
    d.line((14, 15, 29, 15), fill=INK, width=2); d.rectangle((27, 13, 30, 17), fill=ORANGE)
    d.arc((6, 3, 38, 28), 100, 180, fill=WHITE)
    put("task_dish_head", [im])
    im, d = new(24, 18)                                                # tripod base
    d.polygon([(11, 0), (13, 0), (22, 17), (18, 17), (12, 6), (6, 17), (2, 17)], fill=INK)
    d.line((12, 2, 5, 16), fill=STONE); d.line((12, 2, 19, 16), fill=STONE)
    d.rectangle((0, 15, 23, 17), fill=INK); d.line((1, 16, 22, 16), fill=MAUVE)
    put("task_dish_base", [im])
    im, d = new(12, 12)                                                # Earth
    d.ellipse((0, 0, 11, 11), fill=INK); d.ellipse((1, 1, 10, 10), fill=WATER)
    d.rectangle((3, 3, 5, 5), fill=GREEN); d.rectangle((6, 6, 8, 8), fill=GREEN); d.point((3, 2), fill=WHITE)
    put("task_earth", [im])
    frames = []
    for col in (GOLD, GREEN):                                          # crosshair: searching / locked
        im, d = new(28, 28)
        d.ellipse((4, 4, 23, 23), outline=INK, width=3); d.ellipse((5, 5, 22, 22), outline=col, width=1)
        for (a, b) in (((13, 0), (14, 6)), ((13, 21), (14, 27)), ((0, 13), (6, 14)), ((21, 13), (27, 14))):
            d.rectangle((a[0] - 1, a[1] - 1, b[0] + 1, b[1] + 1), fill=INK); d.rectangle((a, b), fill=col)
        frames.append(im)
    put("task_cross", frames)


for fn in (materials, plug, socket, lamp, sandbag, marker, dust, moxie, patch, water, dish):
    fn()
raw = open(MAN).read(); man = json.loads(raw)
for k, v in made.items():
    if k in man: v["id"] = man[k].get("id", v["id"])
    man[k] = v
open(MAN, "w").write(json.dumps(man, indent="\t", ensure_ascii=False) + ("\n" if raw.endswith("\n") else ""))
print("done", len(made))
