"""Redraw the sketched centre art of the Bulalakaw sponsor posters in the game's
clean flat style (same look as posters 4 and 5): 2 px ink outline, flat palette
fills, dot-eye smiley mascots. Frame, banner, slogan box and sunburst are kept.

Usage: python3 -I redo_sponsors.py <drafts_dir> <out_dir>
"""
import math, os, sys
from collections import Counter
from PIL import Image, ImageDraw

SRC, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
INK = (0x2b, 0x1a, 0x2e, 255)
def H(h): return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
CREAM, GOLD, ORANGE, RED, YEL, OLIVE = H("fff6ec"), H("fca54a"), H("ff6d00"), H("c3002b"), H("fee400"), H("caa836")
BEIGE, STONE, PLUM, ICE, BLUE, PINK, RUST, DKRED = H("eedbc8"), H("cbb7b3"), H("684266"), H("86bdc8"), H("5148ab"), H("ef5dc0"), H("b03228"), H("d8305b")
CX, CY, R = 150, 170, 110.5   # glow circle (measured from the drafts)

# ---------------------------------------------------------------- drawing helpers
def ell(d, b, fill, w=2):
    d.ellipse(b, fill=INK)
    d.ellipse((b[0] + w, b[1] + w, b[2] - w, b[3] - w), fill=fill)
def circ(d, x, y, r, fill, w=2): ell(d, (x - r, y - r, x + r, y + r), fill, w)
def box(d, b, fill, rad=0, w=2):
    d.rounded_rectangle(b, rad, fill=INK)
    d.rounded_rectangle((b[0] + w, b[1] + w, b[2] - w, b[3] - w), max(0, rad - w), fill=fill)
def poly(d, pts, fill, w=2): d.polygon(pts, fill=fill, outline=INK, width=w)
def face(d, x, y, s=1.0):
    ex, er = round(11 * s), max(2, round(3 * s))
    for sx in (-1, 1):
        d.ellipse((x + sx * ex - er, y - er - 1, x + sx * ex + er, y + er), fill=INK)
    d.arc((x - 9 * s, y - 2 * s, x + 9 * s, y + 12 * s), 25, 155, fill=INK, width=2)
def blob(cx, cy, r, n=14, wob=0.08, seed=0):
    return [(cx + r * (1 + wob * math.sin(i * 2.7 + seed)) * math.cos(2 * math.pi * i / n),
             cy + r * (1 + wob * math.cos(i * 1.9 + seed)) * math.sin(2 * math.pi * i / n)) for i in range(n)]
def twinkle(d, x, y, c=CREAM):
    d.line((x - 3, y, x + 3, y), fill=c, width=1); d.line((x, y - 3, x, y + 3), fill=c, width=1)
def speed(d, x, y, n=3, ln=20):
    for i in range(n): d.line((x, y + i * 9, x + ln - i * 4, y + i * 9), fill=INK, width=2)

# ---------------------------------------------------------------- clean the draft
def clean(im):
    px = im.load(); W, Hh = im.size
    # slogan box: first row below 200 that is ink across the middle
    top = next(y for y in range(200, 300) if all(px[x, y] == INK for x in (60, 150, 240)))
    reg = [(x, y) for y in range(66, top) for x in range(10, 290)]
    circle = Counter(px[x, y] for x, y in reg).most_common(1)[0][0]
    keep = {c for c, k in Counter(px[x, y] for y in range(top + 40, 370) for x in range(24, 276)).items() if k > 40}
    keep.discard(INK)
    mask = set()
    for x, y in reg:
        if (x - CX) ** 2 + (y - CY) ** 2 <= R * R:
            px[x, y] = circle
        elif px[x, y] not in keep:
            mask.add((x, y))
    while mask:   # grow the sunburst back over stray strokes
        done = {}
        for x, y in mask:
            nb = [px[x + i, y + j] for i in (-1, 0, 1) for j in (-1, 0, 1)
                  if (i or j) and (x + i, y + j) not in mask and 0 <= x + i < W and 0 <= y + j < Hh
                  and px[x + i, y + j] != circle]
            if nb: done[(x, y)] = Counter(nb).most_common(1)[0][0]
        if not done: break
        for p, c in done.items(): px[p] = c
        mask -= done.keys()
    return top, circle

def finish(im, base, top):
    """Paste the untouched banner (above y 66) and slogan box back over any overflow."""
    im.paste(base.crop((0, 0, 300, 66)), (0, 0))
    im.paste(base.crop((0, top, 300, 380)), (0, top))

# ---------------------------------------------------------------- the 5 redraws
def p1(d, bg):   # Cosmo Crunch Cereal: cereal puff mascot + box + milk splash
    box(d, (164, 84, 236, 224), RED, 4)
    d.rectangle((228, 88, 232, 220), fill=RUST)
    box(d, (172, 98, 226, 158), CREAM, 3)
    circ(d, 199, 128, 15, GOLD)
    d.ellipse((178, 123, 220, 133), outline=YEL, width=2)
    d.ellipse((193, 120, 198, 125), fill=OLIVE)
    box(d, (172, 168, 226, 212), YEL, 3)
    for x in (184, 199, 214): circ(d, x, 190, 5, GOLD)
    for x, y in ((72, 92), (146, 86), (58, 214), (247, 150)): circ(d, x, y, 6, GOLD)
    poly(d, [(44, 238), (60, 214), (84, 222), (110, 208), (140, 220), (170, 210), (200, 222), (236, 214), (256, 238)], CREAM)
    for (ax, ay), (hx, hy) in (((76, 150), (54, 124)), ((134, 150), (156, 122))):
        d.line((ax, ay, hx, hy), fill=INK, width=4); circ(d, hx, hy, 6, GOLD)
    for lx in (92, 118):
        d.line((lx, 190, lx, 214), fill=INK, width=4); ell(d, (lx - 8, 208, lx + 6, 218), GOLD)
    circ(d, 105, 160, 38, GOLD)
    d.pieslice((69, 124, 141, 196), 20, 110, fill=ORANGE); d.ellipse((73, 128, 137, 192), fill=GOLD)
    for x, y, r in ((86, 186, 4), (126, 144, 3), (122, 182, 3)): d.ellipse((x - r, y - r, x + r, y + r), fill=OLIVE)
    d.ellipse((82, 134, 94, 142), fill=CREAM)
    face(d, 105, 162)

def p2(d, bg):   # Rover Racer Sneakers: sneaker on rover wheels, Mars volcano behind
    hill = H("7bbaff")
    layer = Image.new("RGBA", (300, 380), (0, 0, 0, 0)); ld = ImageDraw.Draw(layer)
    ld.polygon([(52, 200), (100, 118), (112, 108), (132, 106), (146, 116), (204, 200)], fill=hill)
    ld.polygon([(150, 200), (196, 150), (210, 146), (250, 200)], fill=hill)
    ld.rectangle((0, 196, 300, 300), fill=hill)
    for x, y in ((80, 226), (226, 222), (150, 236)): ld.ellipse((x - 12, y - 4, x + 12, y + 4), fill=H("4fa3ff"))
    m = Image.new("L", (300, 380), 0); ImageDraw.Draw(m).ellipse((CX - R, CY - R, CX + R, CY + R), fill=255)
    m = Image.composite(layer.getchannel("A"), Image.new("L", (300, 380), 0), m)
    d._image.paste(layer, (0, 0), m)
    for x in (92, 148, 204): circ(d, x, 206, 12, INK); circ(d, x, 206, 4, STONE)
    box(d, (60, 180, 236, 198), CREAM, 6)
    poly(d, [(70, 182), (72, 128), (102, 116), (118, 140), (176, 150), (214, 160), (234, 182)], ORANGE)
    poly(d, [(190, 156), (214, 160), (234, 182), (196, 182)], CREAM)
    poly(d, [(72, 128), (102, 116), (104, 126), (76, 136)], CREAM)
    poly(d, [(98, 172), (130, 150), (128, 160), (168, 160), (132, 178), (136, 168)], YEL)
    for i in range(3): d.line((112 + i * 12, 136 + i * 3, 120 + i * 12, 146 + i * 3), fill=INK, width=2)
    face(d, 160, 168, 0.8)
    speed(d, 26, 150)
    for x, y in ((214, 108), (82, 92), (238, 132)): twinkle(d, x, y)

def p3(d, bg):   # Moon Munch Chips: chip bag + crater-chip mascot
    box(d, (154, 88, 236, 220), YEL, 3)
    d.rectangle((228, 92, 232, 216), fill=OLIVE)
    for y0 in (80, 212):
        box(d, (148, y0, 242, y0 + 14), OLIVE, 2)
        for x in range(154, 240, 6): d.line((x, y0 + 3, x, y0 + 10), fill=INK, width=1)
    circ(d, 195, 140, 26, PINK)
    for x, y, r in ((186, 132, 5), (204, 150, 4), (200, 126, 3)): ell(d, (x - r, y - r, x + r, y + r), H("f385cf"), 1)
    box(d, (168, 176, 222, 200), CREAM, 3)
    for x in (178, 195, 212): d.rectangle((x - 3, 186, x + 3, 190), fill=GOLD)
    for (ax, ay), (hx, hy) in (((72, 168), (48, 140)), ((138, 168), (160, 196))):
        d.line((ax, ay, hx, hy), fill=INK, width=4); circ(d, hx, hy, 6, GOLD)
    poly(d, blob(105, 168, 40, 16, 0.07, 1.3), GOLD)
    for x, y, r in ((84, 150, 5), (128, 190, 4), (90, 196, 3), (130, 146, 3)): d.ellipse((x - r, y - r, x + r, y + r), fill=OLIVE)
    face(d, 106, 168)
    for x, y in ((62, 220), (148, 226), (60, 110), (142, 96)): d.rectangle((x, y, x + 4, y + 4), fill=GOLD, outline=INK)

def p6(d, bg):   # Zoom Zoom Scooters: rocket scooter on Mars
    for x, y, w, h in ((54, 212, 30, 14), (226, 210, 26, 12), (160, 230, 18, 9)):
        ell(d, (x - w // 2, y - h // 2, x + w // 2, y + h // 2), RUST)
    poly(d, [(54, 182), (30, 178), (8 + 40, 190), (30, 202), (54, 198)], YEL)
    poly(d, [(54, 186), (40, 190), (54, 194)], ORANGE)
    box(d, (52, 178, 82, 202), STONE, 4)
    d.rectangle((58, 186, 76, 190), fill=RED)
    for x in (94, 202): circ(d, x, 212, 14, INK); circ(d, x, 212, 5, STONE)
    box(d, (78, 192, 214, 206), H("4fa3ff"), 4)
    poly(d, [(190, 196), (200, 196), (216, 104), (206, 104)], CREAM)
    box(d, (194, 94, 236, 104), PLUM, 3)
    box(d, (226, 94, 240, 104), RED, 3)
    circ(d, 203, 122, 10, YEL)
    d.ellipse((198, 116, 203, 121), fill=CREAM)
    face(d, 146, 199, 0.55)
    speed(d, 20, 140)
    for x, y in ((78, 104), (120, 88), (250, 150)): twinkle(d, x, y)

def p7(d, bg):   # Planet Puppy Toys: plush puppy in a bubble helmet + planet ball
    for x in (90, 150): ell(d, (x - 10, 202, x + 10, 222), CREAM)
    ell(d, (58, 160, 76, 176), CREAM)
    ell(d, (68, 156, 188, 216), CREAM)
    d.ellipse((92, 168, 124, 190), fill=BEIGE)
    circ(d, 186, 146, 30, CREAM)
    ell(d, (152, 126, 170, 172), BEIGE)
    face(d, 192, 148, 0.75)
    d.ellipse((150, 104, 230, 188), outline=INK, width=6)
    d.ellipse((152, 106, 228, 186), outline=ICE, width=3)
    d.arc((158, 112, 222, 180), 200, 250, fill=CREAM, width=3)
    box(d, (162, 172, 206, 180), BLUE, 3)
    circ(d, 228, 208, 13, PINK)
    d.arc((208, 200, 248, 216), 160, 380, fill=YEL, width=2)
    for x, y in ((70, 110), (112, 96), (244, 120), (58, 140)): twinkle(d, x, y, BLUE)

ART = {1: p1, 2: p2, 3: p3, 6: p6, 7: p7}
for n in range(1, 8):
    base = Image.open(os.path.join(SRC, f"sponsor_poster_{n}.png")).convert("RGBA")
    im = base.copy()
    if n in ART:
        top, bg = clean(im)
        d = ImageDraw.Draw(im)
        ART[n](d, bg)
        finish(im, base, top)
    im.save(os.path.join(OUT, f"sponsor_poster_{n}.png"))

# ---------------------------------------------------------------- logos (48x48)
def logo(n, draw):
    im = Image.open(os.path.join(SRC, f"sponsor_logo_{n}.png")).convert("RGBA"); px = im.load()
    disk = Counter(px[x, y] for x in range(48) for y in range(48)
                   if 14 <= math.hypot(x - 23.5, y - 23.5) <= 16).most_common(1)[0][0]
    for x in range(48):
        for y in range(48):
            if math.hypot(x - 23.5, y - 23.5) <= 16.5: px[x, y] = disk
    draw(ImageDraw.Draw(im)); return im
def tinyface(d, x, y):
    d.rectangle((x - 5, y - 2, x - 4, y - 1), fill=INK); d.rectangle((x + 3, y - 2, x + 4, y - 1), fill=INK)
    d.line((x - 3, y + 3, x + 2, y + 3), fill=INK)
L = {
    1: lambda d: (ell(d, (12, 12, 35, 35), GOLD), d.rectangle((16, 16, 18, 18), fill=CREAM), tinyface(d, 24, 24)),
    2: lambda d: (poly(d, [(11, 27), (12, 15), (19, 13), (22, 20), (36, 23), (37, 29)], ORANGE, 1),
                  d.rectangle((10, 28, 38, 31), fill=CREAM, outline=INK),
                  [d.ellipse((x - 2, 31, x + 2, 35), fill=INK) for x in (15, 24, 33)]),
    3: lambda d: (poly(d, blob(23.5, 24, 11, 12, 0.08, 1.3), GOLD, 2), tinyface(d, 24, 24)),
    7: lambda d: (ell(d, (15, 15, 33, 33), CREAM), ell(d, (13, 17, 19, 28), BEIGE, 1), tinyface(d, 25, 24),
                  d.ellipse((10, 10, 38, 38), outline=ICE, width=2)),
}
for n in range(1, 8):
    im = logo(n, L[n]) if n in L else Image.open(os.path.join(SRC, f"sponsor_logo_{n}.png")).convert("RGBA")
    im.save(os.path.join(OUT, f"sponsor_logo_{n}.png"))
print("done")
