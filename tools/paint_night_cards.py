"""Night cover cards (D52) in feed style: painted pixel art like the CF-03 Solar Field feed
(dark violet sky, mauve ridges, orange regolith), no text baked in. 240x160, 4 frames each
in one row (D66): sunset shimmer, lamp glow, radiation streaks, Earth twinkle, drifting dust,
aurora ripple, falling meteors. Also night_card_lock (an overlay: dimmed + padlock).

Usage: python3 -I tools/paint_night_cards.py assets/sprites/screens data/assets.json
"""
import json, math, os, random, sys
from PIL import Image, ImageDraw

OUT, MAN = sys.argv[1], sys.argv[2]
W, H, N = 240, 160, 4
def C(h): return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
# CF-03 feed colours + the game palette
SKY0, SKY1, SKY2, SKY3, SKY4 = C("1e1022"), C("2d1330"), C("401642"), C("501f4f"), C("622a5a")
RIDGE_FAR, RIDGE_NEAR = C("7a3a6a"), C("4f1e4e")
GROUND, GROUND_D, GROUND_L, GROUND_DD = C("e1450d"), C("b0341a"), C("f26a2a"), C("7d2418")
INK, PLUM, MAUVE, STONE, CREAM, WHITE = C("2b1a2e"), C("684266"), C("9b828b"), C("cbb7b3"), C("eedbc8"), C("fff6ec")
BLUE, PANEL, ICE = C("5148ab"), (64, 56, 150, 255), C("86bdc8")
GOLD, YEL, ORANGE = C("fca54a"), C("fee400"), C("ff6d00")
MAG, LMAG, DMAG = C("d65cec"), C("f3b6ff"), C("8e2aa8")
MINT, LEAF, GREEN = C("a2e69f"), C("57be6b"), C("6fc60c")
CLEAR = (0, 0, 0, 0)


def dither_band(d, y0, y1, top, bot):
    """Vertical blend from `top` to `bot` using an ordered 2x2 pattern (no new colours)."""
    hgt = max(1, y1 - y0)
    for y in range(y0, y1):
        t = (y - y0) / hgt
        for x in range(W):
            thr = (0.25, 0.75, 1.0, 0.5)[(x % 2) + 2 * (y % 2)]
            d.point((x, y), fill=bot if t * 1.0 >= thr * 0.999 else top)


def sky(d, cols, horizon):
    step = horizon / (len(cols) - 1)
    for i in range(len(cols) - 1):
        dither_band(d, int(i * step), int((i + 1) * step), cols[i], cols[i + 1])


def stars(d, seed, horizon, n=40, frame=0):
    rng = random.Random(seed)
    for i in range(n):
        x, y = rng.randrange(W), rng.randrange(horizon - 6)
        if (i + frame) % 7 == 0:
            continue                                     # twinkle
        d.point((x, y), fill=WHITE if i % 5 == 0 else STONE)


def ridges(d, horizon, seed=3):
    rng = random.Random(seed)
    for (col, amp, base, step) in ((RIDGE_FAR, 14, horizon - 2, 24), (RIDGE_NEAR, 8, horizon + 4, 16)):
        pts, x = [(0, H)], 0
        while x <= W + step:
            pts.append((x, base - rng.randint(0, amp))); x += step
        pts.append((W, H))
        d.polygon(pts, fill=col)


def ground(d, top):
    d.rectangle((0, top, W, H), fill=GROUND)
    dither_band(d, top, top + 6, RIDGE_NEAR, GROUND)
    rng = random.Random(top)
    for _ in range(70):                                  # pebbles and dents
        x, y = rng.randrange(W), rng.randrange(top + 8, H)
        d.point((x, y), fill=GROUND_D if rng.random() < 0.7 else GROUND_L)
    for y in range(H - 18, H, 3):                        # nearer ground is darker
        for x in range((y // 3) % 2, W, 2):
            d.point((x, y), fill=GROUND_D)


def base(d, x, y, lit=GOLD, s=1.0):
    """The station on the horizon: the Control Room dome plus two small blocks, windows lit."""
    r = int(16 * s)
    d.pieslice((x - r, y - r, x + r, y + r), 180, 360, fill=PLUM, outline=INK)
    d.rectangle((x - r, y - 2, x + r, y + int(6 * s)), fill=PLUM, outline=INK)
    for k in (-1, 0, 1):
        d.rectangle((x + k * int(7 * s) - 1, y - int(6 * s), x + k * int(7 * s) + 1, y - int(4 * s)), fill=lit)
    for bx, bw, bh in ((x - r - int(16 * s), int(12 * s), int(10 * s)), (x + r + int(4 * s), int(14 * s), int(8 * s))):
        d.rectangle((bx, y + int(6 * s) - bh, bx + bw, y + int(6 * s)), fill=MAUVE, outline=INK)
        d.point((bx + 3, y + int(6 * s) - bh + 3), fill=lit)
    d.line((x, y - r, x, y - r - int(8 * s)), fill=INK); d.point((x, y - r - int(9 * s)), fill=C("c3002b"))


def panel_row(d, x0, x1, y):
    for px in range(x0, x1, 18):
        d.polygon([(px + 3, y - 10), (px + 17, y - 10), (px + 15, y - 4), (px + 1, y - 4)], fill=BLUE, outline=INK)
        d.line((px + 4, y - 9, px + 15, y - 9), fill=ICE)
        d.line((px + 9, y - 9, px + 8, y - 5), fill=PANEL)
        d.line((px + 3, y - 4, px + 3, y), fill=WHITE); d.line((px + 14, y - 4, px + 14, y), fill=WHITE)


# --------------------------------------------------------------------------- the seven scenes
def n1(f):    # sunset over the base
    im = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(im)
    sky(d, [SKY1, SKY3, PLUM, C("c25a5e"), ORANGE], 100)
    cx, cy = 168, 92
    d.ellipse((cx - 11, cy - 11, cx + 11, cy + 11), fill=GOLD); d.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), fill=YEL)
    for k in range(3):                                   # heat shimmer lines drift across the sun
        y = cy - 6 + k * 5 + (f % 2)
        d.line((cx - 13 + f * 2, y, cx + 4 + f * 2, y), fill=ORANGE)
    ridges(d, 104); ground(d, 110); base(d, 70, 106, lit=YEL)
    return im


def n2(f):    # greenhouse glowing purple
    im = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(im)
    sky(d, [SKY0, SKY1, SKY2, SKY3], 90); stars(d, 2, 90, frame=f)
    ridges(d, 92); ground(d, 98)
    gx0, gx1, gy0, gy1 = 70, 170, 74, 132
    glow = (DMAG, MAG, DMAG, DMAG)[f]
    for g in range(3, 0, -1):                            # glow pool on the ground pulses
        d.ellipse((gx0 - g * 8, gy1 - 6 - g * 2, gx1 + g * 8, gy1 + 10 + g * 2), fill=(glow if g == 1 else DMAG) if g < 3 or f % 2 == 0 else GROUND_D)
    d.rectangle((gx0, gy0, gx1, gy1), fill=INK)
    d.rectangle((gx0 + 2, gy0 + 2, gx1 - 2, gy1 - 2), fill=DMAG)
    d.rectangle((gx0 + 6, gy0 + 4, gx1 - 6, gy0 + 7), fill=LMAG if f % 2 == 0 else MAG)   # grow lamp
    for row in range(2):
        y = gy0 + 22 + row * 18
        for x in range(gx0 + 8, gx1 - 6, 9):
            d.rectangle((x - 2, y, x + 2, y + 3), fill=C("c2502a"))
            for dx, dy in ((-3, -5), (0, -7), (3, -5)): d.line((x, y, x + dx, y + dy), fill=GREEN)
    for x in range(gx0 + 12, gx1, 12): d.line((x, gy0 + 1, x, gy0 + 3), fill=ICE)
    return im


def n3(f):    # radiation: faint streaks over the dome
    im = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(im)
    sky(d, [SKY0, SKY1, SKY2, SKY4], 96); stars(d, 3, 96, frame=f)
    rng = random.Random(9)
    for i in range(14):                                  # particles streak down-right, invisible to the eye
        x0, y0 = rng.randrange(-40, W), rng.randrange(-20, 60)
        x0 += f * 8; y0 += f * 6
        for t in range(6):
            d.point((x0 + t * 4, y0 + t * 3), fill=ICE if t > 3 else MAUVE)
    ridges(d, 100); ground(d, 106); base(d, 120, 104, lit=GOLD, s=1.6)
    return im


def n4(f):    # comms dish with Earth as a bright star
    im = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(im)
    sky(d, [SKY0, SKY1, SKY2, SKY3], 96); stars(d, 4, 96, frame=f)
    ex, ey = 62, 34
    r = (2, 3, 2, 1)[f]
    d.line((ex - r - 2, ey, ex + r + 2, ey), fill=ICE); d.line((ex, ey - r - 2, ex, ey + r + 2), fill=ICE)
    d.rectangle((ex - 1, ey - 1, ex + 1, ey + 1), fill=WHITE); d.point((ex, ey), fill=ICE)
    ridges(d, 100); ground(d, 106)
    dx, dy = 160, 84                                     # dish aimed at Earth
    d.line((dx, dy + 6, dx - 6, dy + 34), fill=INK, width=2); d.line((dx, dy + 6, dx + 6, dy + 34), fill=INK, width=2)
    d.ellipse((dx - 22, dy - 14, dx + 22, dy + 14), fill=CREAM, outline=INK)
    d.ellipse((dx - 18, dy - 10, dx + 16, dy + 10), fill=STONE)
    d.line((dx, dy, dx - 12, dy - 18), fill=INK); d.rectangle((dx - 14, dy - 21, dx - 10, dy - 17), fill=ORANGE)
    for k in range(2):                                   # signal arcs travel towards Earth
        rr = 10 + k * 10 + f * 3
        d.arc((dx - 12 - rr, dy - 18 - rr, dx - 12 + rr, dy - 18 + rr), 200, 250, fill=ICE)
    d.rectangle((dx - 10, dy + 30, dx + 24, dy + 42), fill=STONE, outline=INK); d.point((dx + 20, dy + 34), fill=GREEN)
    return im


def n5(f):    # dust wall swallowing the solar field
    im = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(im)
    sky(d, [SKY1, SKY3, SKY4, C("8a3a3a")], 92)
    ridges(d, 96); ground(d, 102)
    panel_row(d, 120, 236, 128); panel_row(d, 140, 236, 148)
    rng = random.Random(5)                               # the billowing wall, rolling in from the left
    for i in range(40):
        bx = rng.randrange(-20, 130) + f * 3
        by = rng.randrange(10, 150)
        rr = rng.randrange(10, 24)
        col = (C("b85a3c"), C("a04a34"), C("c86a44"))[i % 3]
        d.ellipse((bx - rr, by - rr, bx + rr, by + rr), fill=col)
    for y in range(0, H, 2):                             # the front edge thins into a dither
        for x in range(128 + f * 3 + (y // 2) % 3, 150 + f * 3, 2):
            d.point((x, y), fill=C("b85a3c"))
    for i in range(18):                                  # drifting specks ahead of the wall
        sx = (rng.randrange(140, 260) + f * 6) % W; sy = rng.randrange(20, 150)
        d.point((sx, sy), fill=C("c86a44"))
    return im


def n6(f):    # white-hot Sun and aurora
    im = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(im)
    sky(d, [SKY0, SKY1, SKY2, SKY3], 100); stars(d, 6, 100, n=24, frame=f)
    for band, col in ((0, LEAF), (1, MINT), (2, GREEN)):     # aurora ribbons ripple
        for x in range(0, W, 2):
            y = 58 + band * 7 + int(6 * math.sin(x / 22.0 + f * math.pi / 2 + band))
            d.line((x, y, x, y + 4), fill=col)
    sx, sy = 190, 30
    for k in range(8):                                   # rays flicker
        a = k * math.pi / 4 + (f % 2) * math.pi / 8
        d.line((sx, sy, sx + int(22 * math.cos(a)), sy + int(22 * math.sin(a))), fill=YEL)
    d.ellipse((sx - 12, sy - 12, sx + 12, sy + 12), fill=YEL); d.ellipse((sx - 8, sy - 8, sx + 8, sy + 8), fill=WHITE)
    ridges(d, 104); ground(d, 110); base(d, 70, 108, lit=GOLD)
    return im


def n7(f):    # bulalakaw meteor shower over the base
    im = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(im)
    sky(d, [SKY0, SKY0, SKY1, SKY2, SKY3], 100); stars(d, 7, 100, n=50, frame=f)
    rng = random.Random(77)
    for i in range(7):
        x0, y0 = rng.randrange(40, 280), rng.randrange(-10, 40)
        p = (f + i) % N
        hx, hy = x0 - p * 14, y0 + p * 10
        for t in range(7):
            d.point((hx + t * 3, hy - t * 2), fill=(WHITE, YEL, GOLD, ORANGE, ORANGE, PLUM, PLUM)[t])
        d.rectangle((hx - 1, hy - 1, hx, hy), fill=WHITE)
    ridges(d, 104); ground(d, 110); base(d, 120, 108, lit=YEL, s=1.3)
    return im


def lock():
    im = Image.new("RGBA", (W, H), CLEAR); d = ImageDraw.Draw(im)
    for y in range(H):                                   # dim the card with an ink checker
        for x in range(y % 2, W, 2):
            d.point((x, y), fill=INK)
    cx, cy = W // 2, 66
    d.arc((cx - 14, cy - 30, cx + 14, cy + 2), 180, 360, fill=INK, width=6)
    d.arc((cx - 12, cy - 28, cx + 12, cy), 180, 360, fill=STONE, width=3)
    d.rectangle((cx - 20, cy - 12, cx + 20, cy + 20), fill=INK)
    d.rectangle((cx - 18, cy - 10, cx + 18, cy + 18), fill=GOLD)
    d.line((cx - 16, cy - 9, cx + 16, cy - 9), fill=YEL)
    d.rectangle((cx - 3, cy - 2, cx + 3, cy + 4), fill=INK); d.rectangle((cx - 1, cy + 4, cx + 1, cy + 10), fill=INK)
    return im


def frame_strip(fn):
    out = Image.new("RGBA", (W * N, H))
    for f in range(N):
        im = fn(f)
        dd = ImageDraw.Draw(im); dd.rectangle((0, 0, W - 1, H - 1), outline=INK)   # 1 px ink frame
        out.paste(im, (f * W, 0))
    return out


raw = open(MAN).read(); man = json.loads(raw)
for i, fn in enumerate((n1, n2, n3, n4, n5, n6, n7), 1):
    frame_strip(fn).save(os.path.join(OUT, "night_card_%d.png" % i))
    man["night_card_%d" % i].update({"w": W, "h": H, "frames": N})
lock().save(os.path.join(OUT, "night_card_lock.png"))
open(MAN, "w").write(json.dumps(man, indent="\t", ensure_ascii=False) + ("\n" if raw.endswith("\n") else ""))
print("done")
