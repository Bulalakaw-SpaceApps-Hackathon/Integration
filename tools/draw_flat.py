"""Base-map art in the rover's flat style: clean shapes, 1 px ink outline, one fill +
one highlight + one shade per material. Designs follow the Basemap-assets pack picks.

Writes into <out_dir>: bld_habitat (128x96), plot_<id>_l1..3 (64x64), deco_debris
(12 frames of 32x32), deco_rocks, deco_flag, deco_antenna, deco_crates (64x64).

Usage: python3 -I draw_flat.py <out_dir> <old_hub_dir>
"""
import math, os, sys
from PIL import Image, ImageDraw

OUT, OLD = sys.argv[1], sys.argv[2]
def H(h): return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
INK, WHITE, CREAM, STONE, MAUVE, PLUM, DPLUM = H("2b1a2e"), H("fff6ec"), H("eedbc8"), H("cbb7b3"), H("9b828b"), H("684266"), H("552465")
ICE, BLUE, VIOLET, PANEL = H("86bdc8"), H("5148ab"), H("5e018b"), (64, 56, 150, 255)
LIME, GREEN, DGREEN, MINT, LEAF, FOREST = H("a2e747"), H("6fc60c"), H("38a918"), H("a2e69f"), H("57be6b"), H("44721c")
ORANGE, GOLD, YEL, OLIVE, RED = H("ff6d00"), H("fca54a"), H("fee400"), H("caa836"), H("c3002b")
WOOD, WOOD_D, WOOD_L = (168, 110, 66, 255), (112, 68, 42, 255), (204, 150, 96, 255)
R1, R2, R3, R4 = (176, 82, 52, 255), (138, 58, 40, 255), (206, 118, 76, 255), (96, 40, 34, 255)
CLEAR = (0, 0, 0, 0)

def canvas(w=64, h=64):
    im = Image.new("RGBA", (w, h), CLEAR); return im, ImageDraw.Draw(im)
def box(d, b, fill, hi=None, sh=None):
    x0, y0, x1, y1 = b
    d.rectangle(b, fill=INK); d.rectangle((x0 + 1, y0 + 1, x1 - 1, y1 - 1), fill=fill)
    if hi and x1 - x0 > 3: d.line((x0 + 1, y0 + 1, x1 - 2, y0 + 1), fill=hi)
    if sh and y1 - y0 > 3: d.line((x1 - 1, y0 + 2, x1 - 1, y1 - 1), fill=sh); d.line((x0 + 1, y1 - 1, x1 - 1, y1 - 1), fill=sh)
def rbox(d, b, r, fill, hi=None):
    x0, y0, x1, y1 = b
    d.rounded_rectangle(b, r, fill=INK); d.rounded_rectangle((x0 + 1, y0 + 1, x1 - 1, y1 - 1), max(0, r - 1), fill=fill)
    if hi: d.line((x0 + r, y0 + 1, x1 - r, y0 + 1), fill=hi)
def oval(d, b, fill, hi=None):
    x0, y0, x1, y1 = b
    d.ellipse(b, fill=INK); d.ellipse((x0 + 1, y0 + 1, x1 - 1, y1 - 1), fill=fill)
    if hi: d.arc((x0 + 2, y0 + 2, x1 - 2, y1 - 2), 200, 250, fill=hi)
def poly(d, pts, fill): d.polygon(pts, fill=fill, outline=INK)
def line(d, a, b, w=2): d.line((a, b), fill=INK, width=w)
def light(d, x, y, c): d.point((x, y), fill=INK); d.point((x, y - 1), fill=c)
def glass(d, b, tint=ICE):
    box(d, b, tint)
    x0, y0, x1, y1 = b
    if x1 - x0 > 5 and y1 - y0 > 5: d.line((x0 + 2, y1 - 3, x0 + 4, y0 + 2), fill=WHITE)
def floor(im):
    bb = im.getbbox()
    if not bb: return im
    out = Image.new("RGBA", im.size, CLEAR); out.alpha_composite(im, (0, im.height - bb[3])); return out
def save(im, name): floor(im).save(os.path.join(OUT, name + ".png"))

# ================================================================== battery bank (green energy cells)
def battery(lv):
    im, d = canvas()
    if lv == 1:
        box(d, (20, 14, 40, 63), PLUM, MAUVE, DPLUM)
        for y0 in (17, 38):
            glass(d, (23, y0, 37, y0 + 18), GREEN)
            d.rectangle((25, y0 + 9, 35, y0 + 16), fill=LIME)
        box(d, (40, 22, 47, 44), STONE, WHITE, MAUVE)
        for y in (26, 32, 38): light(d, 43, y + 1, LIME if y < 38 else GOLD)
    else:
        n = 3 if lv == 2 else 4
        x0, x1 = (10, 54) if lv == 2 else (4, 60)
        line(d, (x0 + 2, 14), (x1 - 2, 14), 3); d.line((x0 + 3, 14, x1 - 3, 14), fill=DGREEN)
        tw = (x1 - x0 - 4) // n
        for i in range(n):
            tx = x0 + 3 + i * tw
            line(d, (tx + tw // 2, 14), (tx + tw // 2, 19))
            col = (GREEN, GREEN, ICE, GREEN)[i]
            glass(d, (tx, 18, tx + tw - 3, 48), col)
            d.rectangle((tx + 2, 30, tx + tw - 5, 46), fill=LIME if col == GREEN else MINT)
        box(d, (x0, 46, x1, 63), PLUM, MAUVE, DPLUM)
        box(d, (x0 + 6, 50, x0 + 20, 58), INK)
        for k in range(3): d.line((x0 + 8, 52 + k * 2, x0 + 8 + 3 + k * 3, 52 + k * 2), fill=LIME)
        for x in range(x1 - 18, x1 - 4, 4): light(d, x, 55, LIME if lv == 3 else GOLD)
        if lv == 3:
            for (sx, sy) in ((8, 12), (55, 10), (30, 8)):   # crackle of charge
                d.line((sx, sy, sx + 2, sy + 3), fill=LIME); d.line((sx + 2, sy + 3, sx, sy + 5), fill=LIME)
    return im

# ================================================================== greenhouse (wood-frame glasshouse)
def greenhouse(lv):
    im, d = canvas()
    w = (20, 26, 28)[lv - 1]
    cx, base, roof_y = 32, 63, (24, 16, 14)[lv - 1]
    eave = roof_y + w // 1 if False else roof_y + (w * 2) // 3
    x0, x1 = cx - w, cx + w
    poly(d, [(x0, eave), (cx, roof_y), (x1, eave)], ICE)                  # glass gable
    d.line((x0 + 3, eave - 1, cx, roof_y + 3), fill=WHITE)
    box(d, (x0, eave, x1, base), ICE)                                     # glass walls
    for x in range(x0 + 7, x1 - 2, 7): d.line((x, eave + 1, x, base - 1), fill=WOOD)   # mullions
    d.line((x0, eave, x1, eave), fill=WOOD_D); d.line((x0, eave + 1, x1, eave + 1), fill=WOOD)
    d.line((x0, eave, cx, roof_y), fill=WOOD_D); d.line((cx, roof_y, x1, eave), fill=WOOD_D)
    for x in range(x0 + 3, x1 - 2, 5):                                    # plants inside
        h = 6 + (x * 7) % 5 + (lv - 1) * 3
        d.ellipse((x - 3, base - 4 - h, x + 3, base - 4), fill=LEAF); d.point((x - 1, base - 3 - h), fill=MINT)
    box(d, (x0, base - 4, x1, base), WOOD, WOOD_L, WOOD_D)                # planter base
    box(d, (cx - 4, base - 16, cx + 4, base), WOOD, WOOD_L)               # door
    glass(d, (cx - 2, base - 14, cx + 2, base - 7))
    if lv == 3:                                                           # overgrown: vines + bushes
        for (vx, vy, r) in ((x0 + 2, eave + 2, 5), (x1 - 3, eave, 6), (cx + 10, roof_y + 8, 4), (x0 + 12, roof_y + 10, 4)):
            oval(d, (vx - r, vy - r, vx + r, vy + r), LEAF); d.point((vx - 1, vy - 2), fill=MINT)
        for bx in (x0 - 2, x1 - 6):
            oval(d, (bx, base - 9, bx + 9, base), DGREEN); d.point((bx + 3, base - 7), fill=LEAF)
    return im

# ================================================================== suit bay (gantry with a suit)
def suit(d, cx, top, s=1.0, tone=STONE):
    oval(d, (cx - 5, top, cx + 5, top + 10), WHITE)
    box(d, (cx - 3, top + 3, cx + 3, top + 7), YEL)
    box(d, (cx - 7, top + 10, cx + 7, top + 25), WHITE, None, tone)
    box(d, (cx - 4, top + 13, cx + 4, top + 18), ORANGE)
    for ax in (cx - 10, cx + 7): box(d, (ax, top + 11, ax + 3, top + 22), WHITE)
    for lx in (cx - 6, cx + 1): box(d, (lx, top + 25, lx + 5, top + 34), WHITE, None, tone)

def mini_suit(d, cx, top, visor=YEL):
    """A 22 px spacesuit hanging in a window."""
    oval(d, (cx - 4, top, cx + 4, top + 8), WHITE)
    box(d, (cx - 3, top + 2, cx + 3, top + 6), visor)
    box(d, (cx - 5, top + 8, cx + 5, top + 17), WHITE, None, STONE)
    d.rectangle((cx - 3, top + 10, cx + 3, top + 13), fill=ORANGE)
    for ax in (cx - 7, cx + 5): box(d, (ax, top + 9, ax + 2, top + 16), WHITE)
    for lx in (cx - 4, cx + 1): box(d, (lx, top + 17, lx + 3, top + 22), WHITE)

def hazard(d, x0, y0, x1, y1):
    d.rectangle((x0, y0, x1, y1), fill=INK)
    for x in range(x0 - (y1 - y0), x1, 6):
        d.polygon([(x, y1), (x + (y1 - y0), y0), (x + (y1 - y0) + 3, y0), (x + 3, y1)], fill=YEL)
    d.rectangle((x0 - 8, y0, x0 - 1, y1), fill=CLEAR); d.rectangle((x1 + 1, y0, x1 + 8, y1), fill=CLEAR)

def suit_bay(lv):
    """Suit hangar: suits hang behind glass, an airlock door, roof lights."""
    im, d = canvas()
    if lv == 1:
        x0, x1 = 8, 54
    else:
        x0, x1 = 2, 61
    top = 22 if lv == 1 else 18
    box(d, (x0 + 2, top + 5, x1 - 2, 62), STONE, WHITE, MAUVE)              # walls
    box(d, (x0, top, x1, top + 6), ORANGE, GOLD, (196, 70, 0, 255))         # roof slab
    if lv >= 2: hazard(d, x0 + 1, top + 7, x1 - 1, top + 9)
    box(d, (x0 + 1, 59, x1 - 1, 63), MAUVE, STONE, PLUM)                    # footing
    n = 1 if lv == 1 else 2
    wy0 = top + (10 if lv == 1 else 12)
    for i in range(n):                                                      # suit windows
        wx = x0 + 5 + i * 19
        tint = ICE if lv < 3 else (120, 210, 230, 255)
        box(d, (wx, wy0, wx + 16, wy0 + 27), tint)
        if lv == 3: d.rectangle((wx + 1, wy0 + 1, wx + 15, wy0 + 2), fill=WHITE)
        mini_suit(d, wx + 8, wy0 + 3, YEL if lv < 3 else LIME)
        d.line((wx + 2, wy0 + 25, wx + 5, wy0 + 20), fill=WHITE)
    # airlock door
    dx0 = x1 - 17 if lv == 1 else x1 - 20
    box(d, (dx0, top + 14, dx0 + 13, 59), MAUVE, STONE, PLUM)
    if lv == 1:
        oval(d, (dx0 + 3, top + 17, dx0 + 10, top + 24), ICE); d.point((dx0 + 5, top + 19), fill=WHITE)
    else:
        for y in range(top + 17, 58, 3): d.line((dx0 + 2, y, dx0 + 11, y), fill=PLUM)   # roll-up door
    box(d, (dx0 - 4, top + 26, dx0 - 1, top + 31), INK); d.point((dx0 - 3, top + 28), fill=LIME)
    # roof gear
    box(d, (x0 + 5, top - 4, x0 + 11, top), MAUVE); box(d, (x0 + 4, top - 7, x0 + 12, top - 3), YEL, WHITE)  # floodlight
    light(d, x1 - 4, top - 1, RED if lv < 3 else LIME)
    if lv == 3:
        line(d, (x1 - 12, top), (x1 - 12, top - 14), 1); oval(d, (x1 - 16, top - 18, x1 - 8, top - 12), ICE)
        box(d, (x0 + 18, top - 5, x0 + 34, top), INK)                       # glowing sign
        d.line((x0 + 20, top - 3, x0 + 32, top - 3), fill=ICE); d.line((x0 + 20, top - 2, x0 + 27, top - 2), fill=ICE)
        line(d, (x0 + 2, 50), (x0 - 1, 58), 1); d.point((x0 - 1, 58), fill=LIME)
    return im

# ================================================================== solar field (panel arrays)
def panel(d, x0, y0, cols, rows, cw=9, ch=7):
    for r in range(rows):
        for c in range(cols):
            x, y = x0 + c * (cw + 1), y0 + r * (ch + 1)
            box(d, (x, y, x + cw, y + ch), BLUE)
            d.line((x + 1, y + ch // 2, x + cw - 1, y + ch // 2), fill=PANEL)
            d.line((x + cw // 2, y + 1, x + cw // 2, y + ch - 1), fill=PANEL)
            d.point((x + 2, y + 2), fill=ICE)

def solar(lv):
    im, d = canvas()
    if lv == 1:
        panel(d, 14, 14, 3, 2)
        for x in (20, 40): box(d, (x, 30, x + 2, 48), MAUVE)
        box(d, (18, 40, 46, 56), STONE, WHITE, MAUVE)
        for x in range(21, 44, 3): d.line((x, 43, x, 53), fill=MAUVE)
        box(d, (28, 45, 36, 51), DGREEN); d.point((30, 47), fill=LIME)
        for sx in (6, 52):                                                # warning signs
            line(d, (sx + 3, 52), (sx + 3, 62), 1)
            d.polygon([(sx, 52), (sx + 3, 46), (sx + 6, 52)], fill=YEL, outline=INK); d.point((sx + 3, 50), fill=INK)
    else:
        cols = 4
        panel(d, 9, 6 if lv == 2 else 4, cols, 3)
        for x in (14, 31, 48): box(d, (x, 28, x + 2, 46), MAUVE)
        for i in range(4):                                                # battery boxes
            bx = 8 + i * 12
            box(d, (bx, 44, bx + 10, 54), PLUM, MAUVE); d.line((bx + 3, 49, bx + 7, 49), fill=LIME)
        d.line((10, 57, 54, 57), fill=INK, width=2)
        if lv == 3:
            box(d, (24, 46, 40, 60), STONE, WHITE, MAUVE)                 # transformer
            for x in (27, 31, 35): d.line((x, 48, x, 58), fill=MAUVE)
            for fx in range(2, 62, 4): d.line((fx, 56, fx, 63), fill=MAUVE)  # fence
            d.line((2, 57, 61, 57), fill=STONE); d.line((2, 61, 61, 61), fill=STONE)
            for x in (12, 52): light(d, x, 3, GOLD)
    return im

# ================================================================== comms dish
def dish(d, cx, cy, r, face=1):
    """Parabolic dish seen face-on and tilted up: bowl, inner shading, rim light, feed struts."""
    ry = max(3, int(r * 0.8))
    oval(d, (cx - r, cy - ry, cx + r, cy + ry), WHITE)
    d.ellipse((cx - r + 3, cy - ry + 3, cx + r - 2, cy + ry - 1), fill=STONE)
    d.ellipse((cx - r + 3, cy - ry + 2, cx + r - 5, cy + ry - 4), fill=CREAM)
    d.arc((cx - r + 1, cy - ry + 1, cx + r - 1, cy + ry - 1), 195, 265, fill=WHITE)
    fx, fy = cx + face * 2, cy - 3
    for px, py in ((cx - r + 3, cy + 1), (cx + r - 3, cy + 1), (cx, cy + ry - 2)):
        d.line((px, py, fx, fy), fill=MAUVE)
    box(d, (fx - 2, fy - 2, fx + 2, fy + 2), ORANGE)

<<<<<<< HEAD
FRAME = 0                                    # animation frame, set by tools/rescale_map.py (D66)

def waves(d, x, y, n=2, r0=4):
    for k in range(n):
        r = r0 + k * 4 + FRAME % 2 * 2         # signal rings pulse outwards
=======
def waves(d, x, y, n=2, r0=4):
    for k in range(n):
        r = r0 + k * 4
>>>>>>> 3757b8b42369dbed611261392235ce92fae39988
        d.arc((x - r, y - r, x + r, y + r), 290, 340, fill=ICE, width=1)

def lattice(d, x, y0, y1, w=6):
    d.line((x - w // 2, y1, x - 1, y0), fill=INK, width=1); d.line((x + w // 2, y1, x + 1, y0), fill=INK, width=1)
    for y in range(y1, y0, -6):
        k = (y1 - y) / (y1 - y0); hw = w / 2 * (1 - k) + 1
        d.line((x - hw, y, x + hw, y - 6), fill=STONE); d.line((x + hw, y, x - hw, y - 6), fill=STONE)

def comms(lv):
    """Ground station: equipment shed, dish on a turning mount, signal waves, beacon mast."""
    im, d = canvas()
    sx0, sx1 = (12, 44) if lv == 1 else (6, 50)
    box(d, (sx0 + 1, 46, sx1 - 1, 63), STONE, WHITE, MAUVE)                   # shed
    box(d, (sx0, 42, sx1, 47), ORANGE, GOLD, (196, 70, 0, 255))
    box(d, (sx0 + 4, 50, sx0 + 11, 63), MAUVE, STONE)                          # door
    if lv >= 2:
        box(d, (sx0 + 15, 50, sx0 + 30, 58), INK)                              # waveform screen
        for x in range(sx0 + 17, sx0 + 29, 2): d.point((x, 54 + round(2 * math.sin(x))), fill=LIME)
    light(d, sx1 - 4, 52, LIME); light(d, sx1 - 4, 56, GOLD)
    if lv == 1:
        box(d, (26, 30, 30, 42), MAUVE)
        dish(d, 28, 22, 12); waves(d, 31, 16, 2, 5)
    else:
        cx = 26
        box(d, (cx - 6, 36, cx + 6, 42), MAUVE, STONE)                         # turntable
        line(d, (cx - 5, 36), (cx - 7, 24), 2); line(d, (cx + 5, 36), (cx + 7, 24), 2)   # yoke
        box(d, (cx + 8, 26, cx + 13, 32), PLUM)                                # counterweight
        dish(d, cx, 20, 15 if lv == 2 else 18); waves(d, cx + 4, 14, 3, 6)
        if lv == 2:
            poly(d, [(sx1 - 2, 34), (62, 28), (63, 35), (sx1 - 1, 40)], BLUE); d.line((sx1 + 1, 36, 61, 31), fill=PANEL)
    if lv == 3:
        lattice(d, 56, 6, 42, 8)
        light(d, 56, 5, RED)
        dish(d, 56, 22, 5)
        waves(d, 58, 17, 2, 4)
    return im

# ================================================================== life support (front view)
def fan(d, cx, cy, r=7):
    oval(d, (cx - r, cy - r, cx + r, cy + r), STONE)
    for k in range(4):
        a = k * math.pi / 2 + 0.4
        d.line((cx, cy, cx + round((r - 2) * math.cos(a)), cy + round((r - 2) * math.sin(a))), fill=MAUVE, width=2)
    d.ellipse((cx - 1, cy - 1, cx + 1, cy + 1), fill=INK)

def tank(d, x, y0, y1, fill=ICE, liquid=None):
    rbox(d, (x, y0, x + 9, y1), 4, fill)
    if liquid: d.rectangle((x + 2, (y0 + y1) // 2, x + 7, y1 - 3), fill=liquid)
    d.line((x + 2, y0 + 4, x + 2, y1 - 5), fill=WHITE)

def gauge(d, cx, cy, r=3):
    oval(d, (cx - r, cy - r, cx + r, cy + r), WHITE); d.line((cx, cy, cx + r - 1, cy - 1), fill=RED)

def o2_tank(d, x, y0, y1, w=10):
    rbox(d, (x, y0, x + w, y1), w // 2, ICE)
    d.rectangle((x + 2, (y0 + y1) // 2, x + w - 2, y1 - 3), fill=(100, 170, 210, 255))
    d.line((x + 2, y0 + 4, x + 2, y1 - 5), fill=WHITE)
    d.line((x + 1, y0 + 8, x + w - 1, y0 + 8), fill=STONE)
    gauge(d, x + w // 2, y0 + 13)

def puff(d, x, y):
<<<<<<< HEAD
    y -= FRAME % 2                            # steam rises and falls back
=======
>>>>>>> 3757b8b42369dbed611261392235ce92fae39988
    for (ox, oy, r) in ((0, 0, 3), (4, -4, 2), (7, -8, 2)):
        d.ellipse((x + ox - r, y + oy - r, x + ox + r, y + oy + r), fill=WHITE)
        d.point((x + ox + r - 1, y + oy), fill=STONE)

def pipe(d, pts):
    d.line(pts, fill=INK, width=4); d.line(pts, fill=ORANGE, width=2)

def grille(d, b):
    box(d, b, PLUM)
    for y in range(b[1] + 2, b[3] - 1, 2): d.line((b[0] + 2, y, b[2] - 2, y), fill=MAUVE)

def life_support(lv):
    """Oxygen plant: air-intake grille, glowing O2 tanks with gauges, orange pipes, venting chimney."""
    im, d = canvas()
    if lv == 1:
        box(d, (8, 32, 40, 60), STONE, WHITE, MAUVE)
        box(d, (6, 28, 42, 33), ORANGE, GOLD, (196, 70, 0, 255))
        grille(d, (12, 36, 36, 46))
        box(d, (12, 49, 22, 56), INK); d.line((14, 52, 20, 52), fill=LIME)
        light(d, 27, 53, LIME); light(d, 32, 53, GOLD)
        box(d, (16, 18, 22, 28), MAUVE, STONE); puff(d, 19, 14)
        pipe(d, [(40, 40), (45, 40)])
        o2_tank(d, 45, 24, 60)
        box(d, (4, 59, 60, 63), MAUVE, STONE, PLUM)
    elif lv == 2:
        box(d, (2, 34, 36, 60), STONE, WHITE, MAUVE)
        box(d, (0, 30, 38, 35), ORANGE, GOLD, (196, 70, 0, 255))
        oval(d, (6, 10, 32, 36), ICE, WHITE)                                   # oxygen garden dome
        d.rectangle((6, 31, 32, 35), fill=CLEAR); box(d, (0, 30, 38, 35), ORANGE, GOLD, (196, 70, 0, 255))
        for (px, py, r) in ((12, 26, 5), (20, 22, 6), (27, 27, 4)): oval(d, (px - r, py - r, px + r, py + r), LEAF)
        grille(d, (6, 38, 24, 48))
        box(d, (26, 38, 33, 48), INK); d.line((28, 41, 31, 41), fill=LIME); d.line((28, 44, 30, 44), fill=LIME)
        light(d, 9, 54, LIME); light(d, 14, 54, GOLD)
        pipe(d, [(36, 42), (41, 42)]); pipe(d, [(36, 50), (52, 50)])
        o2_tank(d, 41, 20, 60); o2_tank(d, 52, 28, 60, 9)
        box(d, (0, 59, 63, 63), MAUVE, STONE, PLUM)
    else:
        box(d, (2, 30, 44, 60), STONE, WHITE, MAUVE)
        box(d, (0, 26, 46, 31), ORANGE, GOLD, (196, 70, 0, 255))
        d.line((2, 21, 44, 21), fill=INK); d.line((2, 22, 44, 22), fill=STONE)     # roof catwalk rail
        for x in (3, 16, 30, 43): d.line((x, 21, x, 26), fill=INK)
        fan(d, 13, 42, 7); fan(d, 31, 42, 7)
        box(d, (7, 52, 37, 58), INK)
        for x in range(9, 36, 3): d.point((x, 55 - (x % 2)), fill=LIME)
        for x in (10, 34): box(d, (x - 3, 12, x + 3, 21), MAUVE, STONE)
        puff(d, 10, 8); puff(d, 34, 7)
        pipe(d, [(44, 36), (48, 36)]); pipe(d, [(44, 48), (56, 48)])
        pipe(d, [(52, 18), (52, 12), (60, 12), (60, 18)])
        o2_tank(d, 47, 18, 60, 8); o2_tank(d, 55, 18, 60, 8)
        light(d, 23, 25, LIME)
        box(d, (0, 59, 63, 63), MAUVE, STONE, PLUM)
    return im

# ================================================================== shelter (armoured dome)
def shelter(lv):
    im, d = canvas()
    oval(d, (6, 14, 58, 80), FOREST)                                      # armoured dome
    d.rectangle((0, 58, 63, 63), fill=CLEAR)
    d.arc((9, 17, 55, 77), 200, 250, fill=LEAF)
    for x0, x1 in ((16, 48), (26, 38)): d.arc((x0, 14, x1, 80), 180, 360, fill=DGREEN)
    box(d, (4, 50, 60, 60), PLUM, MAUVE, DPLUM)                           # base ring
    rbox(d, (24, 34, 40, 60), 3, MAUVE)                                   # hatch
    d.rectangle((25, 35, 26, 59), fill=YEL); d.rectangle((38, 35, 39, 59), fill=YEL)
    box(d, (28, 40, 36, 46), INK); d.point((30, 42), fill=LIME)
    for x in (16, 48): light(d, x, 44, LIME)
    line(d, (22, 16), (20, 8), 1); light(d, 20, 8, RED); line(d, (42, 16), (44, 9), 1); light(d, 44, 9, RED)
    def bag(x, y):
        oval(d, (x, y, x + 9, y + 5), R2); d.line((x + 2, y + 1, x + 6, y + 1), fill=R3)
    if lv >= 2:
        for x in range(0, 58, 8): bag(x, 58)
    if lv == 3:
        for x in range(4, 54, 8): bag(x, 53)
        for x in (8, 55):
            box(d, (x - 1, 38, x + 1, 52), MAUVE); oval(d, (x - 3, 34, x + 3, 39), ICE)
    return im

# ================================================================== control room (128x96), desk colours only
def habitat():
    im, d = canvas(128, 96)
    cx = 64
    # octagonal dome: three tiers seen face-on
    poly(d, [(26, 50), (34, 24), (50, 12), (78, 12), (94, 24), (102, 50)], MAUVE)
    poly(d, [(34, 24), (50, 12), (78, 12), (94, 24)], STONE)             # roof facet, lit
    d.line((36, 24, 92, 24), fill=YEL); d.line((35, 25, 93, 25), fill=YEL)   # trim ring
    d.line((50, 13, 78, 13), fill=CREAM)
    for x in (48, 80): d.line((x, 26, x - 4 if x < 64 else x + 4, 50), fill=PLUM)
    # windows (violet glass like the interior door)
    for (x0, x1) in ((36, 50), (78, 92)):
        box(d, (x0, 30, x1, 40), VIOLET); d.line((x0 + 2, 32, x0 + 4, 32), fill=STONE)
    box(d, (56, 28, 72, 40), VIOLET); d.line((64, 29, 64, 39), fill=DPLUM); d.line((58, 30, 59, 37), fill=BLUE)
    # lower wall
    box(d, (18, 48, 110, 92), MAUVE, STONE, PLUM)
    for x in (34, 50, 78, 94): d.line((x, 50, x, 89), fill=PLUM)
    d.line((19, 86, 109, 86), fill=PLUM)
    # main door (centre) with terminal
    box(d, (55, 56, 73, 92), STONE, CREAM, MAUVE)
    box(d, (57, 58, 71, 92), MAUVE)
    box(d, (59, 60, 69, 68), VIOLET); d.line((64, 61, 64, 67), fill=STONE)
    d.rectangle((60, 74, 68, 86), outline=PLUM)
    for y, c in ((63, DGREEN), (67, YEL)): box(d, (75, y - 2, 78, y + 1), STONE); d.point((76, y - 1), fill=c)
    # side airlock (left) with yellow frame
    rbox(d, (22, 58, 36, 92), 5, YEL); rbox(d, (24, 60, 34, 92), 4, PLUM)
    d.line((29, 61, 29, 91), fill=DPLUM)
    # equipment boxes (right)
    box(d, (92, 66, 108, 92), STONE, CREAM, MAUVE); box(d, (96, 72, 104, 80), PLUM); d.point((98, 74), fill=DGREEN)
    box(d, (108, 74, 120, 92), MAUVE, STONE, PLUM)
    # antennas + dishes on the roof
    for x, f in ((52, -1), (76, 1)):
        line(d, (x, 12), (x, 4), 1)
        oval(d, (x - 5 + f * 2, 0, x + 5 + f * 2, 7), CREAM)
    d.rectangle((60, 6, 68, 12), fill=INK); d.rectangle((61, 7, 67, 11), fill=STONE); d.line((62, 9, 66, 9), fill=YEL)
    # doorstep
    box(d, (52, 90, 76, 95), PLUM)
    return im

# ================================================================== rocks + debris (flat style)
def rock(d, x0, y0, x1, y1, seed=0, base=R1):
    """Rounded boulder sitting flat on the ground: dome top, flat bottom, lit top-left, shaded right."""
    w, h = x1 - x0, y1 - y0
    lay = Image.new("RGBA", d._image.size, CLEAR); ld = ImageDraw.Draw(lay)
    tilt = (seed % 3 - 1) * 0.15
    ld.ellipse((x0, y0, x1, y1 + h * 0.6), fill=INK)
    ld.ellipse((x0 + 1, y0 + 1, x1 - 1, y1 + h * 0.6 - 1), fill=base)
    ld.pieslice((x0 + 1, y0 + 1, x1 - 1, y1 + h * 0.6 - 1), 300 + tilt * 40, 30, fill=R2 if base != R2 else R4)
    ld.arc((x0 + 2, y0 + 2, x1 - 2, y1 + h * 0.6 - 2), 195, 250, fill=R3, width=2)
    if w > 10: ld.line((x0 + w * 0.55, y0 + h * 0.35, x0 + w * 0.65, y0 + h * 0.6), fill=R2 if base != R2 else R4)
    ld.rectangle((0, y1 + 1, lay.width, lay.height), fill=CLEAR)
    ld.line((x0 + 1, y1, x1 - 1, y1), fill=INK)
    d._image.alpha_composite(lay)

def debris_sheet():
    shapes = [
        [(6, 14, 26, 31)], [(3, 18, 17, 31), (14, 12, 29, 31)], [(9, 20, 23, 31)], [(4, 22, 13, 31), (12, 16, 27, 31)],
        [(7, 10, 25, 31)], [(2, 24, 10, 31), (9, 20, 18, 31), (17, 23, 26, 31)], [(10, 17, 30, 31)], [(5, 15, 22, 31)],
        [(8, 22, 18, 31), (16, 25, 24, 31)], [(3, 12, 28, 31)], [(6, 19, 15, 31), (14, 21, 22, 31), (21, 24, 28, 31)], [(9, 14, 24, 31)],
    ]
    sheet = Image.new("RGBA", (32 * len(shapes), 32), CLEAR)
    for i, parts in enumerate(shapes):
        im, d = canvas(32, 32)
        for j, b in enumerate(parts): rock(d, *b, seed=i * 3 + j, base=(R1, R2, R1)[(i + j) % 3])
        for k in range(3):                                                # loose pebbles
            px, py = 2 + (i * 7 + k * 11) % 26, 30 - (k % 2)
            d.point((px, py), fill=R4); d.point((px, py - 1), fill=R3)
        sheet.alpha_composite(im, (i * 32, 0))
    sheet.save(os.path.join(OUT, "deco_debris.png"))

def deco_rocks():
    im, d = canvas()
    rock(d, 4, 34, 30, 63, 1); rock(d, 22, 22, 52, 63, 2); rock(d, 44, 44, 62, 63, 3, R2)
    return im

def deco_flag():
    im, d = canvas()
    oval(d, (6, 52, 58, 66), R2); d.rectangle((0, 60, 63, 63), fill=CLEAR); d.line((12, 55, 24, 54), fill=R3)
    line(d, (18, 58), (18, 6), 3); d.line((18, 7, 18, 57), fill=STONE); oval(d, (16, 3, 20, 7), GOLD)
<<<<<<< HEAD
    fx0, fy0, fx1, fy1 = 19, 8, 54 - (1 if FRAME % 2 else 0), 30 + (1 if FRAME in (1, 2) else 0)   # the flag flaps (D66)
=======
    fx0, fy0, fx1, fy1 = 19, 8, 54, 30
>>>>>>> 3757b8b42369dbed611261392235ce92fae39988
    d.rectangle((fx0, fy0, fx1, fy1), fill=INK)
    d.rectangle((fx0 + 1, fy0 + 1, fx1 - 1, (fy0 + fy1) // 2), fill=(0, 56, 168, 255))      # blue
    d.rectangle((fx0 + 1, (fy0 + fy1) // 2 + 1, fx1 - 1, fy1 - 1), fill=(206, 17, 38, 255))  # red
    d.polygon([(fx0 + 1, fy0 + 1), (fx0 + 13, (fy0 + fy1) // 2), (fx0 + 1, fy1 - 1)], fill=WHITE)
    d.ellipse((fx0 + 3, (fy0 + fy1) // 2 - 2, fx0 + 7, (fy0 + fy1) // 2 + 2), fill=YEL)
    return im

def deco_antenna():
    im, d = canvas()
    for a, b in (((32, 40), (22, 62)), ((32, 40), (42, 62))): line(d, a, b)
    box(d, (28, 30, 36, 44), DGREEN, LEAF); d.point((31, 34), fill=LIME)
    line(d, (32, 30), (32, 16), 2)
    line(d, (10, 16), (56, 8), 2)                                          # yagi boom
    for k in range(6):
        x = 14 + k * 8; y = 15 - k * 1.4
        d.line((x, y - 5, x, y + 5), fill=INK, width=1)
<<<<<<< HEAD
    light(d, 56, 7, RED if FRAME % 2 == 0 else DPLUM)                  # tip light blinks (D66)
=======
    light(d, 56, 7, RED)
>>>>>>> 3757b8b42369dbed611261392235ce92fae39988
    return im

def deco_crates():
    im, d = canvas()
    old = Image.open(os.path.join(OLD, "deco_crates.png")).convert("RGBA")
    sign = old.crop((0, 0, 64, 16)); sb = sign.getbbox()
    if sb: sign = sign.crop(sb); im.alpha_composite(sign, ((64 - sign.width) // 2, 6))
    box(d, (6, 34, 34, 63), WOOD, WOOD_L, WOOD_D)                          # wooden crate
    d.rectangle((9, 37, 31, 60), outline=WOOD_D)
    d.line((10, 38, 30, 59), fill=WOOD_D, width=2); d.line((30, 38, 10, 59), fill=WOOD_D, width=2)
    box(d, (36, 42, 58, 63), (214, 170, 120, 255), (236, 200, 156, 255), (176, 130, 86, 255))   # cardboard box
    d.line((47, 43, 47, 50), fill=(176, 130, 86, 255))
    d.rectangle((40, 52, 45, 57), fill=INK); d.point((42, 54), fill=YEL)
    return im

if __name__ == "__main__":
    save(habitat(), "bld_habitat")
    for name, fn in (("battery", battery), ("greenhouse", greenhouse), ("suit_bay", suit_bay), ("solar", solar),
                     ("comms_dish", comms), ("life_support", life_support), ("shelter", shelter)):
        for lv in (1, 2, 3): save(fn(lv), f"plot_{name}_l{lv}")
    debris_sheet()
    for name, fn in (("deco_rocks", deco_rocks), ("deco_flag", deco_flag), ("deco_antenna", deco_antenna), ("deco_crates", deco_crates)):
        save(fn(), name)
    print("done")
