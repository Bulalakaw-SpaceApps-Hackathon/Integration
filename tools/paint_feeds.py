"""Paint the four sketch camera feeds (Airlock, Greenhouse, Life Support, Shelter) in the style of the
team's finished Solar Field cam (CF-03): night palette, deep violet shadows, warm orange light,
crisp pixel edges, soft dithered gradients.

Layout comes from the team's sketches in assets/source/feeds (their line art is laid over the paint),
colours come from CF-03's palette plus a few accents (hazard yellow, grow-lamp magenta, plant green).

Writes 320x180 PNGs into assets/sprites/cameras/:
  cam_airlock, cam_airlock_open, cam_greenhouse_off, cam_greenhouse_on,
  cam_life_support, cam_life_support_slow, cam_shelter, cam_shelter_closed,
  cam_shelter_door_anim (4 frames, 320x180 each: door open -> closed)
Also copies the team's finished No Signal screen, dust haze and radar blip over the placeholders.

Usage: python3 tools/paint_feeds.py <project root>
"""
import sys, os, math, random, json
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = sys.argv[1]
SRC = ROOT + "/assets/source/feeds/"
OUT = ROOT + "/assets/sprites/cameras/"
W, H = 320, 180
def C(h): return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))

# CF-03 palette (measured from the team's Solar Field cam) + accents
PAL = ["#1e1022", "#2a296b", "#401743", "#4a1b41", "#64294d", "#2c1538", "#5a1c35", "#281228", "#3d1836",
       "#3b1438", "#442a62", "#1a1543", "#200d22", "#251220", "#78839c", "#9c291a", "#ac412a", "#d0471a",
       "#e1440c", "#ff6d00", "#fca54a", "#ffd27a", "#fff6ec", "#c8c0d0", "#a89cb8", "#6a5a86", "#8a7aa6",
       "#fee400", "#2b1a2e", "#d23cf0", "#8a1fb0", "#f08cff", "#3fbf4a", "#1e7a3a", "#8be06a", "#5fe8ff", "#1f8fa0"]
PAL = [C(h) for h in PAL]
LINE = C("#160a1a")


def paletted(img):
    p = Image.new("P", (1, 1))
    flat = [v for c in PAL for v in c]
    p.putpalette(flat + [0] * (768 - len(flat)))
    return img.convert("RGB").quantize(palette=p, dither=Image.Dither.NONE).convert("RGB")


def grad(d, box, top, bot, steps=8):
    x0, y0, x1, y1 = box
    h = max(1, y1 - y0)
    for i in range(steps):
        k = i / max(1, steps - 1)
        col = tuple(int(top[j] + (bot[j] - top[j]) * k) for j in range(3))
        d.rectangle((x0, y0 + h * i // steps, x1, y0 + h * (i + 1) // steps), fill=col)


def dither_noise(img, amount=10, seed=3):
    rnd = random.Random(seed)
    px = img.load()
    for y in range(H):
        for x in range(W):
            if (x + y) % 2 == 0 and rnd.random() < 0.35:
                r, g, b = px[x, y]
                k = rnd.choice((-amount, amount))
                px[x, y] = (max(0, min(255, r + k)), max(0, min(255, g + k)), max(0, min(255, b + k)))
    return img


def glow(img, center, radius, col, strength=0.55):
    """Soft additive light pool (lamps, Mars light through the hatch)."""
    layer = Image.new("RGB", (W, H), (0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = center
    for i in range(10, 0, -1):
        r = radius * i / 10
        k = strength * (1 - i / 11)
        d.ellipse((cx - r, cy - r * 0.8, cx + r, cy + r * 0.8), fill=tuple(int(c * k) for c in col))
    layer = layer.filter(ImageFilter.GaussianBlur(4))
    return ImageChops.add(img, layer)


def sketch_lines(name, thresh=105, keep=None):
    """The sketch's ink lines, as a mask at feed size."""
    sk = Image.open(SRC + name).convert("L").resize((W, H), Image.LANCZOS)
    m = sk.point(lambda v: 255 if v < thresh else 0)
    if keep:
        k = Image.new("L", (W, H), 0)
        ImageDraw.Draw(k).rectangle(keep, fill=255)
        m = ImageChops.multiply(m, k)
    return m


def ink(img, mask, col=LINE):
    img.paste(Image.new("RGB", (W, H), col), (0, 0), mask)
    return img


def finish(img, name, mask=None):
    img = dither_noise(img)
    if mask is not None:
        img = ink(img, mask)
    img = paletted(img)
    img.save(OUT + name + ".png")
    return img


# ------------------------------------------------------------------------------ AIRLOCK
def mars_view(d, box):
    """Mars at night through an opening: violet sky, stars, orange ground (as CF-03)."""
    x0, y0, x1, y1 = box
    grad(d, (x0, y0, x1, y0 + (y1 - y0) * 0.62), C("#1a1543"), C("#64294d"))
    grad(d, (x0, y0 + (y1 - y0) * 0.62, x1, y1), C("#d0471a"), C("#9c291a"))
    rnd = random.Random(5)
    for _ in range(18):
        d.point((rnd.randint(x0, x1), rnd.randint(y0, int(y0 + (y1 - y0) * 0.5))), fill=C("#fff6ec"))
    d.polygon([(x0, y0 + (y1 - y0) * 0.62), (x0 + (x1 - x0) * 0.3, y0 + (y1 - y0) * 0.5), (x0 + (x1 - x0) * 0.55, y0 + (y1 - y0) * 0.6),
               (x0 + (x1 - x0) * 0.8, y0 + (y1 - y0) * 0.52), (x1, y0 + (y1 - y0) * 0.62)], fill=C("#401743"))


def airlock(open_):
    img = Image.new("RGB", (W, H)); d = ImageDraw.Draw(img)
    grad(d, (0, 0, W, 162), C("#3b1438"), C("#64294d"))           # back wall
    grad(d, (0, 0, 52, 180), C("#5a1c35"), C("#3d1836"))          # left wall (lit warm)
    grad(d, (258, 0, W, 180), C("#5a1c35"), C("#3d1836"))         # right wall
    d.rectangle((0, 162, W, H), fill=C("#251220"))                # floor
    d.polygon([(52, 162), (258, 162), (W, H), (0, H)], fill=C("#2c1538"))
    d.rectangle((92, 18, 240, 164), fill=C("#6a5a86"))            # door frame
    d.rectangle((98, 24, 234, 158), fill=C("#442a62"))
    for y in range(24, 158, 6):                                    # warning chevrons on the sill
        pass
    if not open_:
        d.ellipse((102, 24, 220, 142), fill=C("#c8c0d0"))         # vault door (white like the team's task art)
        d.ellipse((110, 32, 212, 134), fill=C("#fff6ec"))
        d.ellipse((124, 46, 198, 120), outline=C("#ff6d00"), width=6)
        for k in range(12):                                        # wheel spokes
            a = k * math.pi / 6
            d.line((161 + 14 * math.cos(a), 83 + 14 * math.sin(a), 161 + 34 * math.cos(a), 83 + 34 * math.sin(a)), fill=C("#e1440c"), width=2)
        d.ellipse((150, 72, 172, 94), fill=C("#ff6d00")); d.ellipse((156, 78, 166, 88), fill=C("#fca54a"))
        for y in (40, 120):                                        # hinges
            d.rectangle((92, y, 102, y + 10), fill=C("#a89cb8"))
        img = glow(img, (160, 84), 70, C("#ff6d00"), 0.25)
    else:
        d.ellipse((106, 26, 218, 140), fill=C("#1e1022"))
        dd = ImageDraw.Draw(img)
        mars_view(dd, (112, 32, 212, 134))
        m = Image.new("L", (W, H), 0); ImageDraw.Draw(m).ellipse((112, 32, 212, 134), fill=255)
        hole = img.copy()
        img = Image.new("RGB", (W, H)); d = ImageDraw.Draw(img)
        grad(d, (0, 0, W, 162), C("#3b1438"), C("#64294d"))
        grad(d, (0, 0, 52, 180), C("#5a1c35"), C("#3d1836"))
        grad(d, (258, 0, W, 180), C("#5a1c35"), C("#3d1836"))
        d.rectangle((0, 162, W, H), fill=C("#251220"))
        d.polygon([(52, 162), (258, 162), (W, H), (0, H)], fill=C("#2c1538"))
        d.rectangle((92, 18, 240, 164), fill=C("#6a5a86")); d.rectangle((98, 24, 234, 158), fill=C("#442a62"))
        d.ellipse((106, 26, 218, 140), fill=C("#1e1022"))
        img.paste(hole, (0, 0), m)
        d.ellipse((42, 20, 98, 152), fill=C("#c8c0d0"))           # the door swung open, seen edge-on
        d.ellipse((50, 28, 92, 144), fill=C("#fff6ec"))
        d.ellipse((60, 60, 82, 112), outline=C("#ff6d00"), width=3)
        img = glow(img, (162, 110), 80, C("#ff6d00"), 0.45)
    mask = sketch_lines("CF-02/" + ("cam_airlock_open.png" if open_ else "cam_airlock.png"), 90, keep=(0, 0, 100, 180) if open_ else None)
    # keep the sketch's wall/frame lines, not its loose door scribbles over our painted vault
    k = Image.new("L", (W, H), 255); ImageDraw.Draw(k).ellipse((104, 24, 220, 142), fill=0)
    if open_:
        ImageDraw.Draw(k).ellipse((40, 18, 100, 154), fill=0)
    mask = ImageChops.multiply(sketch_lines("CF-02/" + ("cam_airlock_open.png" if open_ else "cam_airlock.png"), 90), k)
    return finish(img, "cam_airlock_open" if open_ else "cam_airlock", mask)


# ------------------------------------------------------------------------------ GREENHOUSE
PLANTS = [(112, 108, 1.0), (140, 103, 1.0), (168, 100, 1.0), (196, 96, 1.0), (224, 92, 1.0), (252, 88, 1.0), (282, 84, 1.0),
          (150, 130, 1.6), (196, 124, 1.8), (246, 114, 1.6), (296, 104, 1.5), (300, 152, 1.4), (14, 118, 1.0), (14, 158, 1.0)]


def plant(d, x, y, s, col, col_d):
    for k in range(7):
        a = -math.pi / 2 + (k - 3) * 0.42
        L = (12 + 4 * (k % 2)) * s
        tip = (x + math.cos(a) * L, y + math.sin(a) * L)
        d.polygon([(x - 2, y), tip, (x + 2, y)], fill=col if k % 2 else col_d)
    d.rectangle((x - 5 * s, y, x + 5 * s, y + 6 * s), fill=C("#9c291a"))


def greenhouse(lamp):
    img = Image.new("RGB", (W, H)); d = ImageDraw.Draw(img)
    grad(d, (0, 0, W, 120), C("#2c1538"), C("#3d1836"))
    grad(d, (0, 120, W, H), C("#281228"), C("#1e1022"))
    d.polygon([(70, 92), (320, 62), (320, 108), (128, 146)], fill=C("#6a5a86"))     # plant table
    d.polygon([(70, 92), (128, 146), (128, 152), (66, 98)], fill=C("#442a62"))
    d.polygon([(0, 70), (34, 80), (34, 180), (0, 180)], fill=C("#3d1836"))         # left shelf
    for (hx0, hx1) in ((-20, 26), (88, 300)):                                       # lamp hoods
        d.chord((hx0, -6, hx1, 40), 0, 180, fill=C("#78839c"))
        d.line((hx0 + 4, 18, hx1 - 4, 18), fill=C("#a89cb8"))
    green, green_d = (C("#3fbf4a"), C("#1e7a3a")) if lamp else (C("#1e7a3a"), C("#2c1538"))
    for x, y, s in PLANTS:
        plant(d, x, y, s, green, green_d)
    if lamp:
        img = glow(img, (200, 40), 150, C("#d23cf0"), 0.6)
        img = glow(img, (0, 30), 60, C("#d23cf0"), 0.5)
        img = glow(img, (200, 110), 90, C("#8a1fb0"), 0.35)
    else:
        img = glow(img, (200, 60), 120, C("#442a62"), 0.25)
    # keep the sketch's lamp hoods and roof lines; the plants are painted, not traced
    mask = sketch_lines("cam_greenhouse_on.png" if lamp else "cam_greenhouse_off.png", 70, keep=(0, 0, W, 46))
    d = ImageDraw.Draw(img)
    d.line([(70, 92), (320, 62)], fill=LINE, width=2); d.line([(70, 92), (128, 146), (320, 108)], fill=LINE, width=2)
    return finish(img, "cam_greenhouse_on" if lamp else "cam_greenhouse_off", mask)


# ------------------------------------------------------------------------------ LIFE SUPPORT
def life_support(fast):
    img = Image.new("RGB", (W, H)); d = ImageDraw.Draw(img)
    grad(d, (0, 0, W, 150), C("#3b1438"), C("#5a1c35"))
    d.polygon([(0, 150), (W, 150), (W, H), (0, H)], fill=C("#2c1538"))
    d.polygon([(0, 0), (40, 18), (40, 150), (0, 172)], fill=C("#4a1b41"))          # left wall in perspective
    d.polygon([(W, 0), (282, 18), (282, 150), (W, 172)], fill=C("#4a1b41"))
    for x in (86, 92, 224, 230):                                                     # pipes
        d.rectangle((x, 10, x + 3, 150), fill=C("#78839c"))
    d.rectangle((6, 78, 34, 136), fill=C("#442a62")); d.rectangle((246, 56, 268, 112), fill=C("#442a62"))
    for y in range(84, 132, 6):
        d.line((10, y, 30, y), fill=C("#5fe8ff") if y % 12 == 0 else C("#1f8fa0"))
    d.rectangle((288, 96, 314, 122), fill=C("#442a62"))
    cx, cy = 160, 72
    d.ellipse((cx - 56, cy - 56, cx + 56, cy + 56), fill=C("#6a5a86"))             # fan housing
    d.ellipse((cx - 46, cy - 46, cx + 46, cy + 46), fill=C("#1e1022"))
    if fast:
        for r in (40, 30, 20):                                                       # spinning blur
            d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=C("#78839c"), width=2)
        d.ellipse((cx - 38, cy - 38, cx + 38, cy + 38), outline=C("#a89cb8"))
    else:
        for k in range(4):                                                           # still blades
            a = k * math.pi / 2 + 0.3
            d.polygon([(cx, cy), (cx + 40 * math.cos(a - 0.35), cy + 40 * math.sin(a - 0.35)),
                       (cx + 42 * math.cos(a + 0.2), cy + 42 * math.sin(a + 0.2))], fill=C("#a89cb8"))
    d.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), fill=C("#c8c0d0"))
    img = glow(img, (20, 108), 30, C("#5fe8ff"), 0.35)
    img = glow(img, (cx, cy), 70, C("#ff6d00"), 0.12)
    keep = Image.new("L", (W, H), 255); ImageDraw.Draw(keep).ellipse((cx - 48, cy - 48, cx + 48, cy + 48), fill=0)
    mask = ImageChops.multiply(sketch_lines("cam_life_support_slow.png" if not fast else "cam_life_support.png", 80), keep)
    return finish(img, "cam_life_support" if fast else "cam_life_support_slow", mask)


# ------------------------------------------------------------------------------ SHELTER
DOOR = (112, 36, 186, 126)


def shelter_room(d):
    grad(d, (0, 0, W, 130), C("#3b1438"), C("#5a1c35"))
    d.polygon([(0, 0), (60, 30), (60, 135), (0, 180)], fill=C("#4a1b41"))           # side walls in perspective
    d.polygon([(W, 0), (252, 30), (252, 135), (W, 180)], fill=C("#4a1b41"))
    d.polygon([(0, 180), (60, 135), (252, 135), (W, 180)], fill=C("#2c1538"))       # floor
    d.polygon([(0, 0), (60, 30), (252, 30), (W, 0)], fill=C("#281228"))            # ceiling
    d.rectangle((100, 26, 198, 132), fill=C("#6a5a86"))                              # door frame
    d.rectangle((208, 64, 226, 82), fill=C("#442a62")); d.rectangle((211, 67, 223, 79), fill=C("#5fe8ff"))   # panel
    for (x, y) in ((64, 116), (78, 122), (214, 120), (230, 114)):                    # crates / bottles
        d.rectangle((x, y, x + 10, y + 12), fill=C("#64294d"))


def blast_door(d, k=1.0):
    """k = how far the door has come down: 0 open, 1 closed."""
    x0, y0, x1, y1 = DOOR
    bottom = y0 + (y1 - y0) * k
    if k > 0:
        d.rectangle((x0, y0, x1, bottom), fill=C("#78839c"))
        d.line((x0 + 4, y0 + 10, x1 - 4, y0 + 10), fill=C("#a89cb8"))
        # yellow lightning stripe + hazard bands, as in the sketch
        pts = [(150, y0 + 6), (142, y0 + 34), (154, y0 + 46), (140, y0 + 84)]
        pts = [p for p in pts if p[1] <= bottom]
        if len(pts) > 1: d.line(pts, fill=C("#fee400"), width=4)
        for i in range(x0, x1, 10):
            d.polygon([(i, y0), (i + 5, y0), (i + 9, y0 + 6), (i + 4, y0 + 6)], fill=C("#fee400"))
            if bottom >= y1 - 6:
                d.polygon([(i, y1 - 6), (i + 5, y1 - 6), (i + 9, y1), (i + 4, y1)], fill=C("#fee400"))
        d.line((x0, bottom, x1, bottom), fill=C("#2b1a2e"), width=2)


def shelter_open_inside(d):
    x0, y0, x1, y1 = DOOR
    d.rectangle(DOOR, fill=C("#1e1022"))
    for i in range(4):                                                               # the shelter tunnel behind
        m = 7 * (i + 1)
        d.rectangle((x0 + m, y0 + m, x1 - m, y1 - m), outline=C("#442a62"))
    d.rectangle((x0 + 30, y0 + 30, x1 - 30, y1 - 30), fill=C("#fca54a"))             # warm light inside


def shelter(closed_k):
    img = Image.new("RGB", (W, H)); d = ImageDraw.Draw(img)
    shelter_room(d)
    shelter_open_inside(d)
    blast_door(d, closed_k)
    img = glow(img, (149, 80), 40, C("#fca54a"), 0.3 * (1 - closed_k))
    img = glow(img, (217, 73), 20, C("#5fe8ff"), 0.3)
    keep = Image.new("L", (W, H), 255); ImageDraw.Draw(keep).rectangle(DOOR, fill=0)
    mask = ImageChops.multiply(sketch_lines("cam_shelter_closed.png", 70), keep)
    img = dither_noise(img)
    img = ink(img, mask)
    return paletted(img)


os.makedirs(OUT, exist_ok=True)
for o in (False, True): airlock(o)
for l in (False, True): greenhouse(l)
for f in (False, True): life_support(f)
shelter(0.0).save(OUT + "cam_shelter.png")
shelter(1.0).save(OUT + "cam_shelter_closed.png")
strip = Image.new("RGB", (W * 4, H))
for i, k in enumerate((0.25, 0.5, 0.75, 1.0)):
    strip.paste(shelter(k), (i * W, 0))
strip.save(OUT + "cam_shelter_door_anim.png")

# the team's finished pieces win over placeholders
Image.open(SRC + "cam_off.png").convert("RGB").resize((W, H), Image.LANCZOS).save(OUT + "cam_off.png")
haze = Image.open(SRC + "fx_dust_haze.png").convert("RGBA").resize((W, H), Image.LANCZOS)
haze.putalpha(haze.getchannel("A").point(lambda v: int(v * 0.55)))
haze.save(ROOT + "/assets/sprites/fx/fx_dust_haze.png" if os.path.isdir(ROOT + "/assets/sprites/fx") else OUT + "fx_dust_haze.png")

man_p = ROOT + "/data/assets.json"
man = json.load(open(man_p))
man["cam_shelter_door_anim"].update({"w": W, "h": H, "frames": 4})
json.dump(man, open(man_p, "w"), indent=1)
print("feeds painted")
