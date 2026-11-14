"""Toned Mars ground for the Bulalakaw base map.

tiles_mars.png (128x128, 32 px tiles, same atlas layout HubMap.gd reads):
  row 0: ground A, ground B, ground C, rock scatter      row 2: walkway H, walkway V, walkway cross
  rows 1 and 3 repeat rows 0 and 2 so no tile edge ever samples a transparent or pale pixel
  (the old sheet had a pale bottom row on tile (2,0): that was the white lines).
plot_locked.png / plot_empty.png (64x64): a dusty concrete foundation pad, seen from above.

Ground colours are muted terracotta shades built from the team's MARS_* colours, so the
map reads as one warm, dusty surface instead of flat bright orange.

Usage: python3 -I draw_ground.py <out_dir>
"""
import os, sys, random
from PIL import Image, ImageDraw

OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True)
T = 32
# ground tones (light -> dark)
GL, G1, G2, G3, G4 = (214, 108, 60), (204, 96, 52), (186, 80, 44), (158, 62, 38), (118, 42, 34)
PEB = (230, 150, 104)
INK = (0x2b, 0x1a, 0x2e)
STONE, MAUVE, PLUM, CREAM, OLIVE = (0xcb, 0xb7, 0xb3), (0x9b, 0x82, 0x8b), (0x68, 0x42, 0x66), (0xee, 0xdb, 0xc8), (0xca, 0xa8, 0x36)

def blank(c=G1): return Image.new("RGBA", (T, T), c + (255,))

def speckle(im, rnd, dens=0.05):
    p = im.load()
    for y in range(T):
        for x in range(T):
            r = rnd.random()
            if r < dens * 0.55: p[x, y] = G2 + (255,)
            elif r < dens: p[x, y] = GL + (255,)
    return im

def patch(im, rnd, col, n=34, margin=6):
    """A soft dithered blotch kept away from the tile edge, so tiles never show seams."""
    p = im.load()
    cx, cy = rnd.randint(margin + 6, T - margin - 6), rnd.randint(margin + 6, T - margin - 6)
    rx, ry = rnd.randint(6, 9), rnd.randint(4, 6)
    for y in range(T):
        for x in range(T):
            d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if d < 1 and (d < 0.55 or (x + y) % 2 == 0):
                p[x, y] = col + (255,)

def pebble(d, x, y, big=False):
    if big:
        d.rectangle((x, y + 2, x + 4, y + 3), fill=G4)          # shadow
        d.rectangle((x, y, x + 3, y + 2), fill=G3); d.point((x + 1, y), fill=PEB)
    else:
        d.point((x + 1, y + 1), fill=G4); d.point((x, y), fill=PEB)

def crack(d, x, y, rnd):
    for _ in range(5):
        d.point((x, y), fill=G3); x += rnd.choice((-1, 1, 1)); y += rnd.choice((0, 1))

def ground(variant):
    rnd = random.Random(100 + variant)
    im = speckle(blank(), rnd)
    d = ImageDraw.Draw(im)
    if variant == 1: patch(im, rnd, G2); speckle  # shaded hollow
    if variant == 2: patch(im, rnd, GL); crack(d, 9, 20, rnd)
    if variant in (1, 2):
        pebble(d, rnd.randint(4, 26), rnd.randint(4, 26))
    if variant == 3:
        for (x, y) in ((6, 8), (17, 13), (11, 21), (22, 22), (24, 6)): pebble(d, x, y, True)
        for _ in range(6): pebble(d, rnd.randint(3, 27), rnd.randint(3, 27))
    return im

def walkway_h():
    rnd = random.Random(7)
    im = speckle(blank(), rnd)
    p = im.load(); d = ImageDraw.Draw(im)
    for y in (4, 5):                                     # trodden edge, dithered into the ground
        for x in range(T):
            if (x + y) % 2 == 0: p[x, y] = G2 + (255,)
    d.rectangle((0, 6, 31, 25), fill=G3)                 # compacted bed under the plates
    d.rectangle((0, 7, 31, 24), fill=MAUVE)              # metal plate
    d.line((0, 7, 31, 7), fill=STONE)                    # lit top edge
    d.line((0, 24, 31, 24), fill=PLUM)                   # plate thickness
    d.line((0, 25, 31, 25), fill=G4)                     # shadow on the dust
    d.line((0, 8, 0, 23), fill=PLUM)                     # one seam per 32 px plate
    d.line((1, 8, 1, 23), fill=STONE)
    d.line((2, 15, 31, 15), fill=PLUM); d.line((2, 16, 31, 16), fill=STONE)   # centre rib
    for bx, by in ((4, 10), (27, 10), (4, 21), (27, 21)): d.point((bx, by), fill=PLUM)
    for y in (26, 27):
        for x in range(T):
            if (x + y) % 2 == 1: p[x, y] = G2 + (255,)
    for _ in range(22):                                  # red dust blown onto the plates
        x, y = rnd.randint(0, 31), rnd.choice((8, 9, 10, 21, 22, 23) + tuple(range(8, 24)))
        p[x, y] = (G2 if rnd.random() < 0.6 else G1) + (255,)
    return im

def walkway_v():
    h = walkway_h()
    v = h.transpose(Image.Transpose.TRANSPOSE)
    p = v.load()                                         # keep the light from the top-left
    for y in range(T): p[7, y] = STONE + (255,); p[24, y] = PLUM + (255,)
    return v

def walkway_x():
    h, v = walkway_h(), walkway_v()
    im = h.copy(); m = Image.new("L", (T, T), 0)
    ImageDraw.Draw(m).rectangle((6, 0, 25, 31), fill=255)
    im.paste(v, (0, 0), m)
    d = ImageDraw.Draw(im)
    d.rectangle((7, 7, 24, 24), fill=MAUVE); d.rectangle((7, 7, 24, 24), outline=PLUM)
    d.line((7, 7, 24, 7), fill=STONE); d.line((7, 7, 7, 24), fill=STONE)
    d.rectangle((13, 13, 18, 18), fill=PLUM); d.point((15, 15), fill=STONE)
    return im

sheet = Image.new("RGBA", (128, 128), G1 + (255,))
row0 = [ground(0), ground(1), ground(2), ground(3)]
row2 = [walkway_h(), walkway_v(), walkway_x(), ground(0)]
for i, t in enumerate(row0): sheet.paste(t, (i * T, 0)); sheet.paste(t, (i * T, T))
for i, t in enumerate(row2): sheet.paste(t, (i * T, 2 * T)); sheet.paste(t, (i * T, 3 * T))
sheet.save(os.path.join(OUT, "tiles_mars.png"))

# ---------------------------------------------------------------- foundation pads (64x64)
def pad(locked):
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rounded_rectangle((5, 27, 58, 61), 6, fill=G3 + (150,))          # dug-in dust ring
    d.rounded_rectangle((7, 24, 56, 58), 5, fill=INK)
    d.rounded_rectangle((8, 25, 55, 57), 4, fill=PLUM)                 # slab edge (thickness)
    d.rounded_rectangle((8, 25, 55, 53), 4, fill=MAUVE)                # slab top
    d.line((12, 26, 51, 26), fill=STONE)
    for x in (24, 39): d.line((x, 28, x, 52), fill=PLUM)              # pour seams
    d.line((10, 39, 53, 39), fill=PLUM)
    rnd = random.Random(3 if locked else 4)
    p = im.load()
    for _ in range(70):                                                # dust drifted onto the slab
        x, y = rnd.randint(9, 54), rnd.randint(27, 52)
        if p[x, y][:3] == MAUVE and (x < 18 or x > 45 or y > 47 or rnd.random() < 0.25):
            p[x, y] = (G2 if rnd.random() < 0.5 else G1) + (255,)
    for (x, y, sx, sy) in ((11, 28, 1, 1), (52, 28, -1, 1), (11, 50, 1, -1), (52, 50, -1, -1)):
        d.line((x, y, x + 4 * sx, y), fill=OLIVE); d.line((x, y, x, y + 3 * sy), fill=OLIVE)
    if locked:                                                         # small lock sign at the back
        d.rectangle((31, 16, 32, 30), fill=INK)
        d.rounded_rectangle((24, 4, 39, 19), 2, fill=INK)
        d.rounded_rectangle((25, 5, 38, 18), 2, fill=CREAM)
        d.arc((28, 7, 35, 15), 180, 360, fill=INK, width=2)
        d.rectangle((27, 11, 36, 16), fill=INK); d.point((31, 13), fill=CREAM); d.point((32, 13), fill=CREAM)
    else:                                                              # "build here" dashes
        for x in range(13, 51, 6): d.line((x, 31, x + 2, 31), fill=STONE); d.line((x, 48, x + 2, 48), fill=STONE)
    return im

pad(True).save(os.path.join(OUT, "plot_locked.png"))
pad(False).save(os.path.join(OUT, "plot_empty.png"))
print("done")
