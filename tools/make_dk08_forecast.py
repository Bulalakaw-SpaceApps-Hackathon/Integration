"""DK-08 forecast icons (from the scratch): crescent moon and sun with triangle rays, 32x32 each.
Moon = battery runs out before sunrise; sun = battery lasts past sunrise."""
import sys, math
from PIL import Image, ImageDraw, ImageFilter, ImageChops
OUT = sys.argv[1]
def c(h, a=255): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (a,)
INK, HI, CREAM, STONE, MAUVE = c("2B1A2E"), c("FFF6EC"), c("EEDBC8"), c("CBB7B3"), c("9B828B")
WARN, WARN_S, SAND = c("FEE400"), c("CAA836"), c("FCA54A")

def outlined(mask, fill):
    """Fill a mask and give it a 1 px ink outline on every side (pixel-art style)."""
    im = Image.new("RGBA", mask.size, (0, 0, 0, 0)); px = mask.load(); out = im.load()
    W, H = mask.size
    for y in range(H):
        for x in range(W):
            if px[x, y] > 127:
                out[x, y] = fill
            elif any(0 <= x + dx < W and 0 <= y + dy < H and px[x + dx, y + dy] > 127
                     for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                out[x, y] = INK
    return im

# ---- moon: crescent = big disc minus an offset disc ----
a = Image.new("L", (32, 32), 0); ImageDraw.Draw(a).ellipse((3, 3, 27, 27), fill=255)
b = Image.new("L", (32, 32), 0); ImageDraw.Draw(b).ellipse((11, 0, 33, 22), fill=255)
cres = ImageChops.subtract(a, b)
moon = outlined(cres, CREAM)
inner = ImageChops.subtract(cres, ImageChops.subtract(cres, b.filter(ImageFilter.MaxFilter(5))))
shade = ImageChops.subtract(inner, ImageChops.subtract(inner, cres))
moon.paste(STONE, (0, 0), shade)                     # shade along the inner curve (inside the outline)
d = ImageDraw.Draw(moon)
d.point((7, 14), fill=MAUVE); d.point((8, 19), fill=MAUVE); d.point((11, 23), fill=MAUVE)   # small craters
d.line((6, 11, 6, 13), fill=HI)                       # shine on the outer edge
moon.save(f"{OUT}/assets/sprites/desk/ui_forecast_moon.png")

# ---- sun: disc + 8 triangle rays ----
sun = Image.new("RGBA", (32, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(sun)
cx = cy = 15.5
for k in range(8):
    ang = math.radians(k * 45 - 90)
    tip = (cx + 15 * math.cos(ang), cy + 15 * math.sin(ang))
    l = (cx + 10 * math.cos(ang - 0.32), cy + 10 * math.sin(ang - 0.32))
    r = (cx + 10 * math.cos(ang + 0.32), cy + 10 * math.sin(ang + 0.32))
    d.polygon([tip, l, r], fill=SAND, outline=INK)
d.ellipse((7, 7, 24, 24), fill=WARN, outline=INK)
d.pieslice((8, 8, 23, 23), 20, 160, fill=WARN_S)      # lower shade
d.ellipse((9, 9, 23, 21), fill=WARN)                   # keep the top bright
d.ellipse((7, 7, 24, 24), outline=INK)
d.rectangle((11, 11, 12, 12), fill=HI)                 # shine
sun.save(f"{OUT}/assets/sprites/desk/ui_forecast_sun.png")
print("ok")
