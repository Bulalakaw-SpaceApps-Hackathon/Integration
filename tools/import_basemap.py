"""Slice the teammate's base-map sheets (Basemap-assets repo) into the game's sprite files.

Each sheet is 256x256 = a 4x4 grid of 64x64 options (rows usually go small -> big).
bld_habitat.png is 256x192 = a 2x2 grid of 128x96 options.
PICKS says which cell goes into which game file: change a (row, col) and re-run to swap a choice.

Usage: python3 tools/import_basemap.py <project root> <folder with the sheets>
The original sheets are copied to assets/source/basemap/ so nothing is lost.
"""
import sys, os, shutil, json
from PIL import Image

ROOT, SRC = sys.argv[1], sys.argv[2]
OUT = ROOT + "/assets/sprites/hub/"
KEEP = ROOT + "/assets/source/basemap/"
os.makedirs(KEEP, exist_ok=True)

# game file          : (sheet, row, col)       rows/cols counted from 0
PICKS = {
    # Mars-fitting picks: grey/red metal bases, no grass, glass domes instead of wooden sheds
    "plot_solar_l1":        ("plot_solar.png", 1, 2),
    "plot_solar_l2":        ("plot_solar.png", 2, 2),
    "plot_solar_l3":        ("plot_solar.png", 3, 2),
    "plot_battery_l1":      ("plot_battery_bank2.png", 1, 3),
    "plot_battery_l2":      ("plot_battery_bank2.png", 2, 3),
    "plot_battery_l3":      ("plot_battery_bank2.png", 3, 3),
    "plot_life_support_l1": ("plot_life_support.png", 1, 1),
    "plot_life_support_l2": ("plot_life_support.png", 2, 1),
    "plot_life_support_l3": ("plot_life_support.png", 3, 1),
    "plot_shelter_l1":      ("plot_shelter.png", 1, 1),
    "plot_shelter_l2":      ("plot_shelter.png", 2, 1),
    "plot_shelter_l3":      ("plot_shelter.png", 3, 1),
    "plot_suit_bay_l1":     ("plot_suit_bay.png", 1, 1),
    "plot_suit_bay_l2":     ("plot_suit_bay.png", 2, 1),
    "plot_suit_bay_l3":     ("plot_suit_bay.png", 3, 1),
    "plot_greenhouse_l1":   ("plot_greenhouse.png", 2, 1),   # glass domes, growing left -> right
    "plot_greenhouse_l2":   ("plot_greenhouse.png", 2, 2),
    "plot_greenhouse_l3":   ("plot_greenhouse.png", 2, 3),
    "plot_comms_dish_l1":   ("deco_antenna.png", 0, 0),       # no comms sheet yet: dishes from the antenna sheet
    "plot_comms_dish_l2":   ("deco_antenna.png", 1, 1),
    "plot_comms_dish_l3":   ("deco_antenna.png", 2, 1),
    "plot_locked":          ("plot_locked.png", 0, 3),
    "plot_empty":           ("plot_empty.png", 0, 0),
    "deco_flag":            ("deco_flag2.png", 0, 0),          # flag planted in a Mars mound
    "deco_rover":           ("deco_rover.png", 0, 0),
    "deco_antenna":         ("deco_antenna.png", 0, 1),
    "deco_rocks":           ("deco_rocks64pix.png", 0, 1),
}
HABITAT = ("bld_habitat.png", 1, 1)              # 2x2 grid of 128x96
FX_UPGRADE = ("fx_upgrade.png", 0)               # one row = 4 animation frames


def cell(sheet, r, c, w=64, h=64):
    return Image.open(os.path.join(SRC, sheet)).convert("RGBA").crop((c * w, r * h, c * w + w, r * h + h))


# ---------------------------------------------------------------- the "fit pass"
# Makes the artist sprites belong on OUR Mars map instead of looking pasted on:
#  1. warm Mars light (dusty orange sun): multiply by a warm tint, tone down cold blues a little
#  2. red dust built up on the lower part of every object (strongest at the ground line)
#  3. a dark INK outline like the rest of the game's art
WARM = (1.0, 0.93, 0.84)
DUST = (214, 110, 60)
INK_C = (43, 26, 46, 255)
def fit(img):
    img = img.copy()
    px = img.load()
    w, h = img.size
    ys = [y for y in range(h) for x in range(w) if px[x, y][3] > 0]
    if not ys:
        return img
    top, bot = min(ys), max(ys)
    span = max(1, bot - top)
    for y in range(h):
        k = (y - top) / span                              # 0 at the top of the object, 1 at its foot
        dust = max(0.0, (k - 0.6) / 0.4) * 0.38
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if b > r and b > g:                           # cold blue -> a touch greyer
                m = (r + g + b) / 3
                r, g, b = r * 0.85 + m * 0.15, g * 0.85 + m * 0.15, b * 0.8 + m * 0.2
            r, g, b = r * WARM[0], g * WARM[1], b * WARM[2]
            r, g, b = r + (DUST[0] - r) * dust, g + (DUST[1] - g) * dust, b + (DUST[2] - b) * dust
            px[x, y] = (int(r), int(g), int(b), a)
    out = img.copy(); op = out.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0 and any(0 <= x + dx < w and 0 <= y + dy < h and px[x + dx, y + dy][3] > 128
                                        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                op[x, y] = INK_C
    return out


# Top-down construction pads (the artist's pads are isometric diamonds, which fight the grid).
from PIL import ImageDraw
def pad(locked):
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rounded_rectangle((4, 14, 59, 58), radius=6, fill=(176, 70, 30, 255), outline=INK_C, width=2)   # dug regolith
    d.rounded_rectangle((9, 18, 54, 50), radius=3, fill=(120, 108, 112, 255), outline=INK_C)           # concrete slab
    d.line((9, 50, 54, 50), fill=(84, 70, 80, 255), width=3)                                           # front edge (3/4 view)
    for x0 in (6, 52):                                                                                  # corner stakes
        d.rectangle((x0, 10, x0 + 5, 20), fill=(254, 228, 0, 255), outline=INK_C)
        d.rectangle((x0, 44, x0 + 5, 54), fill=(254, 228, 0, 255), outline=INK_C)
    for k in range(4):                                                                                  # hazard tape
        d.line((12 + k * 11, 34, 18 + k * 11, 34), fill=(254, 228, 0, 255), width=2)
    if locked:
        d.rectangle((30, 4, 33, 30), fill=INK_C)                                                        # sign post
        d.rounded_rectangle((22, 0, 41, 16), radius=3, fill=(238, 219, 200, 255), outline=INK_C)
        d.rectangle((28, 7, 35, 13), fill=INK_C); d.arc((28, 2, 35, 10), 180, 360, fill=INK_C, width=2)  # padlock
    else:
        d.rectangle((14, 22, 49, 30), fill=(238, 219, 200, 255), outline=INK_C)
    return im


for f in os.listdir(SRC):
    if f.endswith(".png"):
        shutil.copy(os.path.join(SRC, f), KEEP + f)

man_p = ROOT + "/data/assets.json"
man = json.load(open(man_p))
for name, (sheet, r, c) in PICKS.items():
    if name in ("plot_locked", "plot_empty"):
        pad(name == "plot_locked").save(OUT + name + ".png")
    else:
        fit(cell(sheet, r, c)).save(OUT + name + ".png")
    if name in man:
        man[name]["w"], man[name]["h"] = 64, 64
fit(cell(HABITAT[0], HABITAT[1], HABITAT[2], 128, 96)).save(OUT + "bld_habitat.png")
row = Image.open(os.path.join(SRC, FX_UPGRADE[0])).convert("RGBA").crop((0, FX_UPGRADE[1] * 64, 256, FX_UPGRADE[1] * 64 + 64))
row.save(OUT + "fx_upgrade.png")
man["fx_upgrade"]["frames"] = 4

# ---- ground: tiles_mars.png in the game's layout (4x4 of 32x32)
#   row 0: 4 ground variants (palette orange + their speckle / crack overlays), col 3 = small rocks
#   row 2: walkway plates: 0 = plate, 1 = plate, 2 = crossing
#   tiles_mars_decals.png = their whole tileset, for scattered craters / rocks / dunes / ice
T = Image.open(os.path.join(SRC, "tiles_mars.png")).convert("RGBA")
def t32(r, c): return T.crop((c * 32, r * 32, c * 32 + 32, r * 32 + 32))
import random
random.seed(7)
def ground(base):
    g = Image.new("RGBA", (32, 32), base)
    px = g.load()
    for _ in range(14):                                   # soft dither, palette tones only
        x, y = random.randrange(32), random.randrange(32)
        px[x, y] = random.choice([(253, 81, 0, 255), (252, 165, 74, 255), (240, 98, 10, 255)])
    return g
atlas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
ORANGE = (255, 109, 0, 255)
for i, ov in enumerate([None, None, (1, 5), (2, 1)]):
    g = ground(ORANGE)
    if ov:
        o = t32(*ov)
        if i == 2:                                        # faint cracks only
            o.putalpha(o.getchannel("A").point(lambda a: a // 2))
        g.alpha_composite(o)
    atlas.paste(g, (i * 32, 0))
for i, src in enumerate([(5, 0), (5, 0), (4, 4)]):
    g = ground(ORANGE); g.alpha_composite(t32(*src)); atlas.paste(g, (i * 32, 64))
atlas.save(OUT + "tiles_mars.png")
T.save(OUT + "tiles_mars_decals.png")
man["tiles_mars_decals"] = {"id": "HM-01", "path": "res://assets/sprites/hub/tiles_mars_decals.png", "w": 256, "h": 256, "frames": 1, "kind": "image"}

# ---- sari-sari crate in their style: their crate + a little cloth sign
from PIL import ImageDraw, ImageFont
cr = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
cr.alpha_composite(cell("deco_crates.png", 0, 0).resize((48, 48), Image.NEAREST), (0, 14))
cr.alpha_composite(cell("deco_crates.png", 1, 1).resize((36, 36), Image.NEAREST), (28, 26))
d = ImageDraw.Draw(cr)
d.rectangle((4, 2, 60, 14), fill=(238, 219, 200, 255), outline=(43, 26, 46, 255))
try:
    f = ImageFont.truetype(ROOT + "/assets/fonts/Silkscreen-Regular.ttf", 8)
except Exception:
    f = ImageFont.load_default()
d.text((32 - d.textlength("SARI-SARI", font=f) / 2, 3), "SARI-SARI", font=f, fill=(43, 26, 46, 255))
fit(cr).save(OUT + "deco_crates.png")
man["deco_crates"]["w"], man["deco_crates"]["h"] = 64, 64
json.dump(man, open(man_p, "w"), indent=1)
print("imported %d sprites + habitat + fx_upgrade (4 frames)" % len(PICKS))
