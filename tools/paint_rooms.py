"""Indoor camera feeds repainted in feed style (D47): painted pixel art that matches the CF-03
Solar Field feed (its violet night colours, one warm ceiling light, ordered dithering, no
sketch lines). 320x180. Writes into assets/sprites/cameras:

  cam_airlock, cam_airlock_open        round vault door; open shows Mars outside
  cam_shelter, cam_shelter_closed      blast-door corridor; closed = striped slab
  cam_shelter_door_anim (4 frames)     the slab coming down
  cam_life_support, cam_life_support_slow   big wall fan (the game draws the spinning blades)
  cam_greenhouse_on (2 frames), cam_greenhouse_off   planters under the magenta grow lamp
  cam_off (2 frames)                   NO SIGNAL with rolling static
  fx_clue / fx_fault / fx_discovery / fx_request    feed markers, 2 frames each

Usage: python3 -I tools/paint_rooms.py assets/sprites/cameras assets/fonts/Silkscreen-Bold.ttf data/assets.json
"""
import json, math, os, random, sys
from PIL import Image, ImageDraw, ImageFont

OUT, FONT, MAN = sys.argv[1], sys.argv[2], sys.argv[3]
W, H = 320, 180
def C(h): return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
V0, V1, V2, V3, V4, V5 = C("1e1022"), C("2d1330"), C("401642"), C("501f4f"), C("622a5a"), C("7a3a6a")
INK, PLUM, MAUVE, STONE, CREAM, WHITE = C("2b1a2e"), C("684266"), C("9b828b"), C("cbb7b3"), C("eedbc8"), C("fff6ec")
STEEL, STEEL_D = C("4a3a62"), C("3a2c50")
ORANGE, GOLD, YEL, RED = C("ff6d00"), C("fca54a"), C("fee400"), C("c3002b")
MAG, LMAG, DMAG = C("d65cec"), C("f3b6ff"), C("8e2aa8")
GREEN, LEAF, DGREEN, POT = C("6fc60c"), C("57be6b"), C("38a918"), C("c2502a")
ICE, BLUE, NAVY = C("86bdc8"), C("5148ab"), C("0b0a3a")
GROUND, GROUND_D = C("e1450d"), C("b0341a")
CLEAR = (0, 0, 0, 0)
BAYER = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))


def mix(d, box, a, b, t_of):
    """Fill box with colour a or b by an ordered 4x4 dither of t_of(x, y) in 0..1 (no new colours)."""
    x0, y0, x1, y1 = box
    for y in range(max(0, y0), min(H, y1 + 1)):
        for x in range(max(0, x0), min(W, x1 + 1)):
            d.point((x, y), fill=b if t_of(x, y) * 16 > BAYER[y % 4][x % 4] else a)


# Room: back wall 70..250 x 22..130, floor below, ceiling above, side walls in perspective.
BX0, BY0, BX1, BY1 = 70, 22, 250, 130


def room(d, light=GOLD):
    # ceiling and floor planes
    d.polygon([(0, 0), (W, 0), (BX1, BY0), (BX0, BY0)], fill=V1)
    d.polygon([(0, H), (W, H), (BX1, BY1), (BX0, BY1)], fill=V2)
    mix(d, (0, BY1, W, H), V2, V3, lambda x, y: max(0.0, 0.7 - abs(x - 160) / 260.0 - (y - BY1) / 140.0))
    for k in range(1, 6):                                  # floor grating lines converge on the wall
        fx = BX0 + (BX1 - BX0) * k / 6
        d.line((fx, BY1, (fx - 160) * 3.2 + 160, H), fill=V1)
    for y in (142, 156, 172):
        t = (y - BY1) / (H - BY1)
        d.line((BX0 - 70 * t, y, BX1 + 70 * t, y), fill=V1)
    # side walls
    d.polygon([(0, 0), (BX0, BY0), (BX0, BY1), (0, H)], fill=V3)
    d.polygon([(W, 0), (BX1, BY0), (BX1, BY1), (W, H)], fill=V3)
    mix(d, (0, 0, BX0, H), V3, V2, lambda x, y: (BX0 - x) / BX0 * 0.9)
    mix(d, (BX1, 0, W, H), V3, V2, lambda x, y: (x - BX1) / (W - BX1) * 0.9)
    for k in range(1, 4):                                  # wall panel seams
        sx = BX0 * k / 4
        d.line((sx, BY0 * sx / BX0, sx, H - (H - BY1) * sx / BX0), fill=V2)
        rx = W - sx
        d.line((rx, BY0 * sx / BX0, rx, H - (H - BY1) * sx / BX0), fill=V2)
    # back wall, lit from the ceiling light
    d.rectangle((BX0, BY0, BX1, BY1), fill=V4)
    mix(d, (BX0, BY0, BX1, BY1), V4, V3, lambda x, y: min(1.0, abs(x - 160) / 110.0 + (y - BY0) / 160.0))
    for y in (52, 96):
        d.line((BX0, y, BX1, y), fill=V3)
    for x in range(BX0 + 8, BX1, 30):
        for y in (BY0 + 4, BY1 - 4):
            d.point((x, y), fill=V5)
    # ceiling light strip and its glow
    d.rectangle((120, 4, 200, 7), fill=INK); d.rectangle((122, 5, 198, 6), fill=light)
    mix(d, (100, 8, 220, 20), V1, V2, lambda x, y: max(0.0, 0.8 - abs(x - 160) / 70.0 - (y - 8) / 16.0))


def pipe_v(d, x, y0, y1, col=STONE, sh=MAUVE):
    d.rectangle((x, y0, x + 5, y1), fill=INK); d.rectangle((x + 1, y0, x + 4, y1), fill=col)
    d.line((x + 4, y0, x + 4, y1), fill=sh)
    for y in range(y0 + 8, y1, 22):
        d.rectangle((x - 1, y, x + 6, y + 2), fill=STEEL_D)


def screen(d, x, y, w=22, h=14, glow=ICE):
    d.rectangle((x, y, x + w, y + h), fill=INK); d.rectangle((x + 2, y + 2, x + w - 2, y + h - 2), fill=NAVY)
    for k in range(3):
        d.line((x + 4, y + 4 + k * 3, x + 4 + (w - 10) * (k + 1) // 3, y + 4 + k * 3), fill=glow)


def hazard(d, box, step=6):
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=INK)
    h = y1 - y0
    for x in range(x0 - h, x1, step):
        pts = [(x, y1), (x + h, y0), (x + h + step // 2, y0), (x + step // 2, y1)]
        d.polygon([(min(max(px, x0), x1), py) for px, py in pts], fill=YEL)


# --------------------------------------------------------------------------- rooms
def airlock(open_):
    im = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(im); room(d)
    cx, cy, r = 160, 78, 46
    d.ellipse((cx - r - 8, cy - r - 8, cx + r + 8, cy + r + 8), fill=STEEL_D)
    d.ellipse((cx - r - 6, cy - r - 6, cx + r + 6, cy + r + 6), fill=STEEL)
    for k in range(12):                                    # frame bolts
        a = k * math.pi / 6
        d.point((cx + int((r + 3) * math.cos(a)), cy + int((r + 3) * math.sin(a))), fill=STONE)
    if open_:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=V0)            # Mars through the hatch
        hole = Image.new("RGBA", (W, H), CLEAR); hd = ImageDraw.Draw(hole)
        hd.rectangle((0, 0, W, cy + 6), fill=V2); hd.rectangle((0, cy + 6, W, H), fill=GROUND)
        mix(hd, (0, cy - 20, W, cy + 6), V2, V4, lambda x, y: (y - (cy - 20)) / 26.0)
        hd.polygon([(cx - r, cy + 8), (cx - 10, cy - 4), (cx + 20, cy + 2), (cx + r, cy - 2), (cx + r, cy + 10)], fill=V5)
        mask = Image.new("L", (W, H), 0); ImageDraw.Draw(mask).ellipse((cx - r + 2, cy - r + 2, cx + r - 2, cy + r - 2), fill=255)
        im.paste(hole, (0, 0), mask)
        for k in range(6): d.point((cx - 30 + k * 11, cy - 30 + (k * 7) % 13), fill=WHITE)
        # the door swung open against the left wall
        d.ellipse((20, cy - r, 52, cy + r), fill=INK); d.ellipse((22, cy - r + 2, 50, cy + r - 2), fill=CREAM)
        d.ellipse((30, cy - 20, 44, cy + 20), outline=ORANGE, width=2)
    else:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=INK)
        d.ellipse((cx - r + 1, cy - r + 1, cx + r - 1, cy + r - 1), fill=STONE)
        d.ellipse((cx - r + 3, cy - r + 3, cx + r - 5, cy + r - 5), fill=CREAM)
        d.arc((cx - r + 6, cy - r + 6, cx + r - 6, cy + r - 6), 200, 260, fill=WHITE, width=2)
        w = 28
        d.ellipse((cx - w, cy - w, cx + w, cy + w), outline=ORANGE, width=3)
        for k in range(8):
            a = k * math.pi / 4
            d.line((cx, cy, cx + int(w * math.cos(a)), cy + int(w * math.sin(a))), fill=ORANGE, width=2)
        d.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=GOLD, outline=INK)
    hazard(d, (110, 128, 210, 134))
    pipe_v(d, 30, 30, 160); screen(d, 262, 70, glow=GREEN)
    d.rectangle((246, 40, 252, 52), fill=INK); d.point((249, 44), fill=GREEN if not open_ else RED)
    return im


def shelter_open():
    im = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(im); room(d)
    x0, y0, x1, y1 = 118, 30, 202, 130
    hazard(d, (x0 - 8, y0 - 8, x1 + 8, y0 - 2)); hazard(d, (x0 - 8, y1 - 2, x1 + 8, y1 + 4))
    d.rectangle((x0 - 8, y0 - 2, x0 - 2, y1 - 2), fill=YEL); d.rectangle((x1 + 2, y0 - 2, x1 + 8, y1 - 2), fill=YEL)
    for k, col in enumerate((STEEL, STEEL_D, V2, V1, V0)):            # corridor going back
        i = k * 8
        d.rectangle((x0 + i, y0 + i * 0.8, x1 - i, y1 - i * 0.6), fill=col)
    d.rectangle((150, 62, 170, 100), fill=ORANGE); d.rectangle((154, 66, 166, 96), fill=GOLD)   # warm light at the end
    screen(d, 228, 60, glow=ICE)
    for x in (30, 280):
        d.rectangle((x - 12, 128, x + 12, 150), fill=PLUM, outline=INK); d.line((x - 10, 130, x + 10, 130), fill=MAUVE)  # crates
    return im


def slab(d, frac):
    """The blast door coming down: frac 0..1 of the doorway covered."""
    x0, y0, x1, y1 = 118, 30, 202, 130
    bottom = y0 + int((y1 - y0) * frac)
    if bottom <= y0:
        return
    d.rectangle((x0, y0, x1, bottom), fill=INK)
    d.rectangle((x0 + 1, y0, x1 - 1, bottom - 1), fill=STONE)
    mix(d, (x0 + 1, y0, x1 - 1, bottom - 1), STONE, MAUVE, lambda x, y: (x - x0) / (x1 - x0) * 0.7)
    hazard(d, (x0 + 1, max(y0, bottom - 8), x1 - 1, bottom - 1))
    zz = [(162, y0 + 8), (152, y0 + 40), (166, y0 + 44), (154, y0 + 86)]   # painted lightning mark
    for a, b in zip(zz, zz[1:]):
        if b[1] < bottom - 8:
            d.line((a, b), fill=YEL, width=3)


def shelter_closed():
    im = shelter_open(); d = ImageDraw.Draw(im); slab(d, 1.0); return im


def door_anim():
    out = Image.new("RGBA", (W * 4, H), CLEAR)
    for k in range(4):
        f = Image.new("RGBA", (W, H), CLEAR); slab(ImageDraw.Draw(f), (k + 1) / 4.0)
        out.alpha_composite(f, (k * W, 0))
    return out


def life_support(slow):
    im = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(im); room(d)
    cx, cy, r = 160, 74, 50
    d.ellipse((cx - r - 8, cy - r - 8, cx + r + 8, cy + r + 8), fill=STEEL_D)
    d.ellipse((cx - r - 5, cy - r - 5, cx + r + 5, cy + r + 5), fill=MAUVE)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=V0)
    for rr in range(r - 4, 6, -8):
        d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), outline=STEEL)
    d.arc((cx - r - 4, cy - r - 4, cx + r + 4, cy + r + 4), 200, 250, fill=STONE, width=2)
    for x in (88, 96, 224, 232):
        pipe_v(d, x, 24, 150, ICE if x in (96, 224) else STONE)
    screen(d, 250, 50, glow=GREEN if not slow else RED)
    d.rectangle((248, 80, 268, 110), fill=INK); d.rectangle((250, 82, 266, 108), fill=STEEL)   # filter housing
    for y in range(86, 106, 4): d.line((252, y, 264, y), fill=STEEL_D if not slow else C("7d2418"))
    d.rectangle((40, 60, 58, 72), fill=INK); d.point((44, 64), fill=RED if slow else GREEN); d.point((50, 64), fill=GOLD)
    if slow:
        for x in range(250, 268, 3): d.point((x, 113), fill=C("7d2418"))           # clogged dust
    return im


def greenhouse(on, frame=0):
    """CF-06: the team's curved grow lamp over two raised beds and a clear aisle."""
    im = Image.new("RGBA", (W, H), STEEL_D)
    d = ImageDraw.Draw(im)
    d.polygon([(0, 0), (320, 0), (275, 31), (45, 31)], fill=INK)
    d.polygon([(0, 180), (320, 180), (269, 112), (51, 112)], fill=STEEL)
    for x in range(52, 271, 36):
        d.line((x, 112, 160 + (x - 160) * 2, 179), fill=STEEL_D)
    for y in (127, 149, 176):
        d.line((0, y, 319, y), fill=STEEL_D)
    d.rounded_rectangle((54, 20, 271, 115), 18, fill=INK)
    d.rounded_rectangle((58, 24, 267, 109), 14, fill=MAUVE)
    d.rounded_rectangle((65, 30, 260, 102), 10, fill=NAVY)
    d.polygon([(65, 88), (99, 75), (125, 83), (160, 72), (209, 85), (260, 78),
               (260, 102), (65, 102)], fill=C("914c52"))
    for x in (105, 161, 216):
        d.rectangle((x, 30, x + 4, 103), fill=INK)
        d.line((x + 1, 32, x + 1, 65), fill=PLUM)
    for x, y in ((73, 42), (121, 52), (152, 36), (194, 58), (241, 38), (251, 62)):
        d.point((x, y), fill=CREAM)

    d.polygon([(82, 14), (104, 5), (218, 5), (242, 14), (232, 25), (92, 25)],
              fill=INK, outline=MAUVE)
    d.rectangle((97, 19, 226, 23), fill=LMAG if on else STEEL)
    if on:
        glow = Image.new("RGBA", (W, H))
        ImageDraw.Draw(glow).polygon([(97, 23), (226, 23), (268, 120), (68, 120)],
                                     fill=(*MAG[:3], 65))
        im.alpha_composite(glow)
        d = ImageDraw.Draw(im)

    for x, y, width, count in ((108, 86, 117, 5), (87, 126, 165, 6)):
        for leg in (x + 6, x + width - 10):
            d.rectangle((leg, y + 7, leg + 5, y + 22), fill=INK)
            d.line((leg + 2, y + 9, leg + 2, y + 21), fill=MAUVE)
        d.polygon([(x + 9, y - 7), (x + width - 9, y - 7),
                   (x + width, y), (x, y)], fill=POT, outline=INK)
        d.rectangle((x, y, x + width, y + 9), fill=INK)
        d.rectangle((x + 2, y + 2, x + width - 2, y + 6), fill=MAUVE if on else PLUM)
        for i in range(count):
            px = x + (i + 1) * width // (count + 1)
            py = y - 3
            sway = (1 if (frame + i) % 2 else -1) if on else 0
            d.line((px, py, px + sway, py - 19), fill=LEAF, width=2)
            for dx, dy in ((-9, -14), (8, -17), (-7, -8), (7, -9)):
                d.polygon([(px, py - 4), (px + dx, py + dy),
                           (px + dx // 2 + sway, py + dy - 2)], fill=GREEN if on else DGREEN)
            if i % 3 == 1:
                d.ellipse((px - 2, py - 14, px + 3, py - 9), fill=GOLD if on else POT)

    d.rounded_rectangle((281, 71, 305, 112), 4, fill=INK)
    d.rectangle((285, 76, 301, 87), fill=STEEL if not on else MAG)
    for y in (94, 102):
        d.line((286, y, 299, y), fill=MAUVE, width=2)
    return im


def no_signal(frame):
    im = Image.new("RGBA", (W, H), NAVY); d = ImageDraw.Draw(im)
    rng = random.Random(frame)
    for _ in range(900):
        d.point((rng.randrange(W), rng.randrange(H)), fill=(V2, V3, STEEL)[rng.randrange(3)])
    y = (frame * 70 + 40) % H                                                      # rolling bar
    d.rectangle((0, y, W, y + 6), fill=STEEL_D)
    d.rectangle((92, 66, 228, 112), fill=INK); d.rectangle((94, 68, 226, 110), fill=NAVY)
    d.rectangle((96, 70, 224, 108), outline=ORANGE)
    f = ImageFont.truetype(FONT, 16); d.fontmode = "1"
    tw = d.textlength("NO SIGNAL", font=f)
    d.text((160 - tw / 2, 80), "NO SIGNAL", font=f, fill=STONE)
    return im


# --------------------------------------------------------------------------- feed markers
def marker(name, w, frames):
    out = Image.new("RGBA", (w * len(frames), w), CLEAR)
    for i, fn in enumerate(frames):
        f = Image.new("RGBA", (w, w), CLEAR); fn(ImageDraw.Draw(f)); out.alpha_composite(f, (i * w, 0))
    out.save(os.path.join(OUT, name + ".png"))


def clue(k):          # magnifier that bobs
    def f(d):
        o = k
        d.ellipse((5, 4 + o, 21, 20 + o), fill=INK); d.ellipse((7, 6 + o, 19, 18 + o), fill=ICE)
        d.arc((8, 7 + o, 18, 17 + o), 200, 260, fill=WHITE)
        d.line((19, 18 + o, 27, 26 + o), fill=INK, width=4); d.line((20, 19 + o, 26, 25 + o), fill=GOLD, width=2)
    return f


def fault(k):         # spark burst
    def f(d):
        pts = [(16, 3), (19, 12), (29, 9), (21, 17), (27, 27), (17, 21), (9, 29), (12, 19), (3, 15), (12, 12)]
        if k: pts = [(x if i % 2 else 16 + (x - 16) * 0.75, y if i % 2 else 16 + (y - 16) * 0.75) for i, (x, y) in enumerate(pts)]
        d.polygon(pts, fill=YEL if k == 0 else ORANGE, outline=INK)
        d.ellipse((13, 13, 19, 19), fill=WHITE)
    return f


def discovery(k):     # four-point sparkle
    def f(d):
        r = 13 if k == 0 else 9
        d.polygon([(16, 16 - r), (18, 14), (16 + r, 16), (18, 18), (16, 16 + r), (14, 18), (16 - r, 16), (14, 14)], fill=YEL, outline=INK)
        d.point((16, 16), fill=WHITE)
        if k == 0:
            for (x, y) in ((5, 6), (27, 25), (26, 6)): d.point((x, y), fill=WHITE)
    return f


def request(k):       # "!" speech bubble that pops
    def f(d):
        o = 0 if k == 0 else 1
        d.rounded_rectangle((1 + o, 1 + o, 22 - o, 17 - o), 4, fill=INK); d.rounded_rectangle((2 + o, 2 + o, 21 - o, 16 - o), 3, fill=WHITE)
        d.polygon([(6, 16), (10, 16), (5, 22)], fill=INK)
        d.rectangle((11, 4 + o, 12, 11), fill=RED); d.rectangle((11, 13, 12, 14 - o), fill=RED)
    return f


def save(im, name): im.save(os.path.join(OUT, name + ".png"))


def strip(frames):
    out = Image.new("RGBA", (W * len(frames), H), CLEAR)
    for i, f in enumerate(frames): out.alpha_composite(f, (i * W, 0))
    return out


save(airlock(False), "cam_airlock"); save(airlock(True), "cam_airlock_open")
save(shelter_open(), "cam_shelter"); save(shelter_closed(), "cam_shelter_closed"); save(door_anim(), "cam_shelter_door_anim")
save(life_support(False), "cam_life_support"); save(life_support(True), "cam_life_support_slow")
save(strip([greenhouse(True, 0), greenhouse(True, 1)]), "cam_greenhouse_on"); save(greenhouse(False), "cam_greenhouse_off")
save(strip([no_signal(0), no_signal(1)]), "cam_off")
marker("fx_clue", 32, [clue(0), clue(1)]); marker("fx_fault", 32, [fault(0), fault(1)])
marker("fx_discovery", 32, [discovery(0), discovery(1)]); marker("fx_request", 24, [request(0), request(1)])
raw = open(MAN).read(); man = json.loads(raw)
man["cam_greenhouse_on"]["frames"] = 2; man["cam_off"]["frames"] = 2
open(MAN, "w").write(json.dumps(man, indent="\t", ensure_ascii=False) + ("\n" if raw.endswith("\n") else ""))
print("done")
