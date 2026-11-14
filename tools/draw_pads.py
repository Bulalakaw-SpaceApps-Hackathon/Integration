"""Locked / empty building plots for the base map (64x64, shown at 3x).

No hard rectangle: the plot is an uneven patch of dug regolith that dithers into the
ground, marked by four stakes. Locked plots get caution tape between the stakes and a
small metal sign with a padlock; empty plots get a loose survey string instead.

Usage: python3 -I draw_pads.py <out_dir>
"""
import math, os, random, sys
from PIL import Image, ImageDraw

OUT = sys.argv[1]
G1, G2, G3, G4, GL = (204, 96, 52), (186, 80, 44), (158, 62, 38), (118, 42, 34), (214, 108, 60)
INK, PLUM, MAUVE, STONE, CREAM = (43, 26, 46), (104, 66, 102), (155, 130, 139), (203, 183, 179), (238, 219, 200)
YEL, OLIVE, WOOD, WOOD_D = (254, 228, 0), (202, 168, 54), (150, 98, 60), (104, 62, 40)
A = 255

def patch(im, rnd, cx=32, cy=48, rx=26, ry=11):
    """Dug-up regolith: darker, lumpy edge, dithered so it melts into the ground."""
    p = im.load()
    bumps = [rnd.uniform(-0.12, 0.12) for _ in range(12)]
    for y in range(64):
        for x in range(64):
            ang = math.atan2((y - cy) / ry, (x - cx) / rx)
            k = int((ang + math.pi) / (2 * math.pi) * 12) % 12
            r = 1 + bumps[k]
            d = math.hypot((x - cx) / rx, (y - cy) / ry) / r
            if d < 0.62: c = G3 if (x * 7 + y * 3) % 11 else G4
            elif d < 0.85: c = G2 if (x + y) % 3 else G3
            elif d < 1.0: c = G2 if (x + y) % 2 == 0 else None
            else: c = None
            if c: p[x, y] = c + (A,)
    for _ in range(26):                                   # clods and pebbles turned up by digging
        x, y = rnd.randint(cx - rx + 4, cx + rx - 4), rnd.randint(cy - ry + 2, cy + ry - 2)
        if p[x, y][3]:
            p[x, y] = GL + (A,)
            if y + 1 < 64: p[x, y + 1] = G4 + (A,)

def stake(d, x, y, h=9):
    """A survey stake standing on the ground at (x, y)."""
    d.rectangle((x - 1, y - h, x + 1, y), fill=INK)
    d.line((x, y - h + 1, x, y - 1), fill=WOOD)
    d.point((x, y - h + 1), fill=CREAM)
    d.line((x - 1, y + 1, x + 1, y + 1), fill=G4)        # tiny contact shadow

def tape(d, a, b, sag=1):
    """Yellow-black caution tape from stake a to stake b, sagging a little."""
    (x0, y0), (x1, y1) = a, b
    n = max(abs(x1 - x0), abs(y1 - y0))
    for i in range(n + 1):
        t = i / n
        x = round(x0 + (x1 - x0) * t); y = round(y0 + (y1 - y0) * t + sag * math.sin(math.pi * t))
        d.point((x, y), fill=YEL if (i // 3) % 2 == 0 else INK)
        d.point((x, y + 1), fill=OLIVE if (i // 3) % 2 == 0 else INK)

def string(d, a, b):
    (x0, y0), (x1, y1) = a, b
    n = max(abs(x1 - x0), abs(y1 - y0))
    for i in range(0, n + 1, 2):
        t = i / n
        d.point((round(x0 + (x1 - x0) * t), round(y0 + (y1 - y0) * t + math.sin(math.pi * t))), fill=CREAM)

def lock_sign(d, cx, base):
    """Small metal sign on a post with a padlock: plum plate, stone rim, gold padlock."""
    d.rectangle((cx - 1, base - 14, cx + 1, base), fill=INK); d.line((cx, base - 13, cx, base - 1), fill=MAUVE)
    d.line((cx - 2, base + 1, cx + 2, base + 1), fill=G4)
    x0, y0, x1, y1 = cx - 9, base - 30, cx + 9, base - 13
    d.rounded_rectangle((x0, y0, x1, y1), 3, fill=INK)
    d.rounded_rectangle((x0 + 1, y0 + 1, x1 - 1, y1 - 1), 2, fill=STONE)
    d.rounded_rectangle((x0 + 2, y0 + 2, x1 - 2, y1 - 2), 2, fill=PLUM)
    d.line((x0 + 3, y0 + 2, x1 - 3, y0 + 2), fill=MAUVE)                   # top light
    for bx in (x0 + 2, x1 - 2): d.point((bx, y0 + 2), fill=STONE); d.point((bx, y1 - 2), fill=STONE)  # rivets
    # padlock: shackle + body
    d.arc((cx - 4, y0 + 3, cx + 3, y0 + 11), 180, 360, fill=INK, width=2)
    d.line((cx - 3, y0 + 5, cx - 3, y0 + 8), fill=STONE)
    d.rectangle((cx - 5, y0 + 8, cx + 4, y0 + 14), fill=INK)
    d.rectangle((cx - 4, y0 + 9, cx + 3, y0 + 13), fill=YEL)
    d.line((cx - 4, y0 + 13, cx + 3, y0 + 13), fill=OLIVE)
    d.point((cx - 3, y0 + 9), fill=CREAM)
    d.point((cx - 1, y0 + 10), fill=INK); d.point((cx - 1, y0 + 11), fill=INK)

def plot(locked):
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    rnd = random.Random(11 if locked else 12)
    patch(im, rnd)
    back = [(10, 41), (54, 41)]; front = [(7, 57), (57, 57)]
    if locked:
        tape(d, back[0], back[1]); tape(d, back[0], front[0], 0); tape(d, back[1], front[1], 0)
    else:
        string(d, back[0], back[1]); string(d, back[0], front[0]); string(d, back[1], front[1])
    for s in back: stake(d, s[0], s[1] + 1)
    if locked: lock_sign(d, 32, 46)
    if locked: tape(d, front[0], front[1], 2)
    else: string(d, front[0], front[1])
    for s in front: stake(d, s[0], s[1] + 1, 10)
    return im

plot(True).save(os.path.join(OUT, "plot_locked.png"))
plot(False).save(os.path.join(OUT, "plot_empty.png"))
print("done")
