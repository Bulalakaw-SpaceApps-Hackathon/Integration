"""Base-map buildings redrawn to match their camera feeds (D38).

Solar Field: tilted blue panels on white A-frames (CF-03).
Life Support: big round wall fan with pipes.
Greenhouse: purple grow lamps over rows of potted plants.
Shelter: blast door in a yellow-black hazard frame with an orange glow window.
Suit Bay: round cream vault door with an orange wheel (the Airlock feed).

Same flat style as draw_flat.py (1 px ink outline, fill + highlight + shade), 64x64 plots,
three levels that each add more of the building's feature. Battery, Comms Dish and the
Control Room are left to draw_flat.py.

Usage: python3 -I tools/draw_feed_buildings.py assets/sprites/hub
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
_out = sys.argv[1]
sys.argv = [sys.argv[0], _out, _out]
from draw_flat import *          # noqa: E402,F401  (helpers + palette)

MAG, DMAG, LMAG = H("d65cec"), H("8e2aa8"), H("f3b6ff")
NAVY, STEEL = H("2c2450"), H("3e3a6a")
POT = H("c2502a")

def wall(d, x0, y0, x1, y1, roof_h=5, fill=STONE, roof=CREAM):
    """Building block in 3/4 view: a roof strip on top, the front wall below it."""
    box(d, (x0, y0, x1, y0 + roof_h), roof, WHITE, STONE)
    box(d, (x0, y0 + roof_h, x1, y1), fill, WHITE, MAUVE)

# ================================================================== solar field
def solar_unit(d, x, y, w=22):
    """One tilted panel on a white A-frame. (x, y) = top-left of the panel's high edge."""
    h, lean = 9, 5
    foot = y + h + 8
    # A-frame legs (behind the panel)
    for lx in (x + 3, x + w - 6):
        poly(d, [(lx, y + h), (lx + 2, y + h), (lx + 5, foot), (lx - 2, foot)], WHITE)
        d.line((lx, foot - 2, lx + 3, foot - 2), fill=STONE)
    box(d, (x + 1, foot - 1, x + w - 2, foot + 1), STONE)                  # base rail
    # the panel itself: a parallelogram, high edge at the back
    poly(d, [(x + lean, y), (x + w, y), (x + w - lean, y + h), (x, y + h)], BLUE)
    for k in range(1, 4):                                                   # cell grid
        fx = k / 4
        d.line((x + lean + (w - lean) * fx - lean * 0 + 0, y + 1, x + (w - lean) * fx, y + h - 1), fill=PANEL)
    d.line((x + lean // 2 + 1, y + h // 2, x + w - lean // 2 - 1, y + h // 2), fill=PANEL)
    d.line((x + lean + 1, y + 1, x + w - 2, y + 1), fill=ICE)              # glint
    d.line((x + 1, y + h + 1, x + w - lean - 1, y + h + 1), fill=INK)      # panel thickness
    d.line((x + 1, y + h, x + w - lean - 1, y + h), fill=WHITE)

def solar(lv):
    im, d = canvas()
    if lv == 1:
        spots = [(8, 26), (32, 32)]
    elif lv == 2:
        spots = [(6, 14), (32, 18), (8, 36), (34, 40)]
    else:
        spots = [(2, 8), (22, 4), (42, 8), (2, 28), (22, 24), (42, 28)]
    for (x, y) in spots: solar_unit(d, x, y, 20 if lv == 3 else 22)
    # cable run to a junction box
    jy = 58 if lv < 3 else 56
    d.line((6, jy, 50, jy), fill=INK, width=2); d.line((6, jy - 1, 50, jy - 1), fill=STONE)
    box(d, (48, jy - 6, 58, jy + 3), PLUM, MAUVE); light(d, 53, jy - 2, LIME)
    if lv == 3:
        box(d, (24, 47, 40, 60), STONE, WHITE, MAUVE)                        # inverter
        for x in (27, 31, 35): d.line((x, 50, x, 58), fill=MAUVE)
        light(d, 37, 49, GOLD)
    return im

# ================================================================== life support
def big_fan(d, cx, cy, r):
    """The round wall fan from the Life Support feed: rings on a dark disc."""
    oval(d, (cx - r - 2, cy - r - 2, cx + r + 2, cy + r + 2), MAUVE)       # housing
    oval(d, (cx - r, cy - r, cx + r, cy + r), DPLUM)
    for rr in range(r - 2, 2, -3): d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), outline=STONE)
    d.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=WHITE, outline=INK)
    d.arc((cx - r - 1, cy - r - 1, cx + r + 1, cy + r + 1), 200, 250, fill=WHITE)

def vpipe(d, x, y0, y1, fill=ICE):
    box(d, (x, y0, x + 3, y1), fill); d.line((x + 1, y0 + 1, x + 1, y1 - 1), fill=WHITE)
    for y in range(y0 + 5, y1 - 2, 9): d.line((x, y, x + 3, y), fill=INK)  # clamps

def life_support(lv):
    im, d = canvas()
    if lv == 1:
        wall(d, 10, 20, 54, 61, fill=PLUM, roof=MAUVE)
        big_fan(d, 32, 42, 11)
        vpipe(d, 13, 27, 60); vpipe(d, 48, 27, 60)
        box(d, (4, 60, 60, 63), MAUVE, STONE, PLUM)
    elif lv == 2:
        wall(d, 4, 16, 60, 61, fill=PLUM, roof=MAUVE)
        big_fan(d, 26, 40, 13)
        vpipe(d, 7, 23, 60); vpipe(d, 44, 23, 60); vpipe(d, 49, 23, 60, STONE)
        pipe(d, [(52, 30), (56, 30), (56, 52)])
        box(d, (53, 52, 59, 58), INK); d.line((54, 55, 57, 55), fill=LIME)
        box(d, (0, 60, 63, 63), MAUVE, STONE, PLUM)
    else:
        wall(d, 1, 14, 62, 61, fill=PLUM, roof=MAUVE)
        big_fan(d, 17, 40, 11); big_fan(d, 46, 40, 11)
        vpipe(d, 30, 21, 60); vpipe(d, 3, 21, 60, STONE); vpipe(d, 57, 21, 60, STONE)
        for x in (12, 50): box(d, (x - 3, 4, x + 3, 15), MAUVE, STONE)       # vents on the roof
        puff(d, 12, 2); puff(d, 50, 1)
        light(d, 32, 18, LIME)
        box(d, (0, 60, 63, 63), MAUVE, STONE, PLUM)
    return im

# ================================================================== greenhouse
def sprout(d, x, y):
    box(d, (x - 2, y, x + 2, y + 3), POT)
    for (dx, dy) in ((-3, -4), (0, -6), (3, -4), (-1, -3), (2, -3)):
        d.line((x, y, x + dx, y + dy), fill=GREEN)
    d.point((x, y - 6), fill=LIME)

def greenhouse(lv):
    im, d = canvas()
    x0, x1 = {1: (8, 56), 2: (4, 60), 3: (1, 62)}[lv]
    rows = lv
    top = {1: 22, 2: 14, 3: 8}[lv]
    # dark frame + floor seen through the glass roof
    box(d, (x0, top, x1, 61), NAVY)
    d.rectangle((x0 + 2, top + 2, x1 - 2, 59), fill=STEEL)
    # magenta glow pools under the lamps
    span = (59 - top - 6) // rows
    for r in range(rows):
        ly = top + 4 + r * span
        d.ellipse((x0 + 3, ly + 1, x1 - 3, ly + span + 2), fill=DMAG)
        d.ellipse((x0 + 8, ly + 3, x1 - 8, ly + span - 1), fill=(176, 64, 200, 255))
        # grow-lamp bar
        box(d, (x0 + 6, ly, x1 - 6, ly + 3), LMAG); d.line((x0 + 7, ly + 2, x1 - 7, ly + 2), fill=MAG)
        # plant row
        for px in range(x0 + 8, x1 - 5, 7): sprout(d, px, ly + span - 4)
    # glass roof ribs
    for x in range(x0 + 8, x1 - 2, 8): d.line((x, top + 1, x, top + 3), fill=ICE)
    d.line((x0 + 1, top + 1, x1 - 1, top + 1), fill=ICE)
    # front: low wall with door
    box(d, (x0, 56, x1, 63), MAUVE, STONE, PLUM)
    cx = (x0 + x1) // 2
    box(d, (cx - 4, 55, cx + 4, 63), PLUM); d.point((cx + 2, 59), fill=LIME)
    if lv == 3:
        for lx in (x0 + 3, x1 - 3): light(d, lx, top - 1, MAG)
    return im

# ================================================================== shelter
def blast_door(d, cx, top, w, h):
    """Hazard-striped frame around a nested-square door with an orange glow window."""
    x0, x1, y1 = cx - w // 2, cx + w // 2, top + h
    d.rectangle((x0, top, x1, y1), fill=INK)
    band = 3
    inner = (x0 + band, top + band, x1 - band, y1)
    # yellow-black diagonal stripes on the frame
    for x in range(x0 - h, x1 + 1, 5):
        pts = [(x, y1), (x + h, top), (x + h + 2, top), (x + 2, y1)]
        d.polygon([(min(max(px, x0), x1), py) for (px, py) in pts], fill=YEL)
    d.line((x0, top, x0, y1), fill=INK); d.line((x1, top, x1, y1), fill=INK)
    d.rectangle(inner, fill=INK)
    ix0, iy0, ix1, iy1 = inner
    box(d, (ix0 + 1, iy0 + 1, ix1 - 1, iy1), STONE, WHITE, MAUVE)
    box(d, (ix0 + 3, iy0 + 3, ix1 - 3, iy1 - 2), MAUVE, STONE, PLUM)
    wx = (ix0 + ix1) // 2
    box(d, (wx - 2, iy0 + 5, wx + 2, iy1 - 5), ORANGE); d.line((wx - 1, iy0 + 6, wx - 1, iy1 - 7), fill=GOLD)

def shelter(lv):
    im, d = canvas()
    if lv == 1:
        wall(d, 8, 22, 56, 61, fill=MAUVE, roof=STONE)
        blast_door(d, 32, 31, 22, 30)
        light(d, 50, 34, LIME)
        box(d, (4, 60, 60, 63), PLUM, MAUVE, DPLUM)
    else:
        wall(d, 3, 16 if lv == 2 else 12, 60, 61, fill=MAUVE, roof=STONE)
        blast_door(d, 32, 27 if lv == 2 else 22, 26, 34 if lv == 2 else 39)
        for x in (10, 54): light(d, x, 32, LIME)
        box(d, (49, 38, 57, 46), INK); d.point((51, 40), fill=ICE); d.point((53, 42), fill=ICE)   # panel light
        def bag(x, y):
            oval(d, (x, y, x + 9, y + 5), R2); d.line((x + 2, y + 1, x + 6, y + 1), fill=R3)
        for x in (0, 8, 47, 55): bag(x, 58)
        if lv == 3:
            for x in (4, 51): bag(x, 53)
            line(d, (48, 12), (48, 3), 1); light(d, 48, 3, RED)
            box(d, (10, 6, 22, 12), PLUM, MAUVE); d.line((12, 9, 20, 9), fill=YEL)   # roof hatch
    return im

# ================================================================== suit bay (airlock)
def vault_door(d, cx, cy, r):
    oval(d, (cx - r - 3, cy - r - 3, cx + r + 3, cy + r + 3), STEEL)       # frame
    oval(d, (cx - r, cy - r, cx + r, cy + r), CREAM)
    d.arc((cx - r + 1, cy - r + 1, cx + r - 1, cy + r - 1), 200, 260, fill=WHITE)
    w = max(3, r * 2 // 3)
    d.ellipse((cx - w, cy - w, cx + w, cy + w), outline=ORANGE, width=2)    # wheel rim
    for k in range(8):
        a = k * math.pi / 4
        d.line((cx, cy, cx + round(w * math.cos(a)), cy + round(w * math.sin(a))), fill=ORANGE)
    d.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=ORANGE, outline=INK)

def suit_bay(lv):
    im, d = canvas()
    if lv == 1:
        wall(d, 10, 20, 54, 61, fill=PLUM, roof=MAUVE)
        vault_door(d, 32, 43, 12)
        light(d, 48, 30, RED)
        box(d, (4, 60, 60, 63), MAUVE, STONE, PLUM)
    elif lv == 2:
        wall(d, 2, 16, 61, 61, fill=PLUM, roof=MAUVE)
        vault_door(d, 22, 41, 13)
        box(d, (40, 26, 57, 56), ICE); mini_suit(d, 48, 30)                  # suit window
        d.line((42, 53, 45, 47), fill=WHITE)
        light(d, 6, 26, LIME)
        box(d, (0, 60, 63, 63), MAUVE, STONE, PLUM)
    else:
        wall(d, 1, 12, 62, 61, fill=PLUM, roof=MAUVE)
        vault_door(d, 17, 40, 12); vault_door(d, 46, 40, 12)
        hazard(d, 3, 56, 60, 58)
        box(d, (25, 5, 31, 12), MAUVE); box(d, (24, 2, 32, 6), YEL, WHITE)      # floodlight
        line(d, (40, 12), (40, 3), 1); oval(d, (37, 0, 43, 5), ICE)          # antenna
        light(d, 4, 18, LIME); light(d, 59, 18, LIME)
        box(d, (0, 60, 63, 63), MAUVE, STONE, PLUM)
    return im

if __name__ == "__main__":
    for name, fn in (("solar", solar), ("life_support", life_support), ("greenhouse", greenhouse),
                     ("shelter", shelter), ("suit_bay", suit_bay)):
        for lv in (1, 2, 3): save(fn(lv), f"plot_{name}_l{lv}")
    print("done")
