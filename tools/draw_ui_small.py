"""Stars and forecast sun/moon in map style (D53): flat pixel art, 1 px ink outline, game palette.
Usage: python3 -I tools/draw_ui_small.py assets/sprites/ui"""
import math, os, sys
from PIL import Image, ImageDraw
OUT = sys.argv[1]
def C(h): return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
INK, MAUVE, PLUM, STONE, WHITE, YEL, GOLD, ORANGE, ICE, CREAM = C("2b1a2e"), C("9b828b"), C("684266"), C("cbb7b3"), C("fff6ec"), C("fee400"), C("fca54a"), C("ff6d00"), C("86bdc8"), C("eedbc8")

def star(full):
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    pts = [(32 + 28 * math.cos(-math.pi / 2 + k * math.pi / 5) * (1 if k % 2 == 0 else 0.45),
            34 + 28 * math.sin(-math.pi / 2 + k * math.pi / 5) * (1 if k % 2 == 0 else 0.45)) for k in range(10)]
    pts = [(round(x), round(y)) for x, y in pts]
    d.polygon(pts, fill=INK)
    inner = [(round(32 + (x - 32) * 0.86), round(34 + (y - 34) * 0.86)) for x, y in pts]
    d.polygon(inner, fill=YEL if full else MAUVE)
    shade = [(round(32 + (x - 32) * 0.86), round(34 + (y - 34) * 0.86)) for x, y in pts[4:8]] + [(32, 34)]
    d.polygon(shade, fill=GOLD if full else PLUM)                      # lower-right facets in shade
    if full:
        d.line((24, 22, 28, 18), fill=WHITE, width=2)
    return im

def sun():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    for k in range(8):
        a = k * math.pi / 4
        d.line((16 + 10 * math.cos(a), 16 + 10 * math.sin(a), 16 + 14 * math.cos(a), 16 + 14 * math.sin(a)), fill=GOLD, width=2)
    d.ellipse((7, 7, 25, 25), fill=INK); d.ellipse((8, 8, 24, 24), fill=YEL); d.arc((10, 10, 22, 22), 200, 250, fill=WHITE)
    return im

def moon():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.ellipse((5, 4, 27, 26), fill=INK); d.ellipse((6, 5, 26, 25), fill=CREAM)
    d.ellipse((15, 0, 35, 20), fill=(0, 0, 0, 0))
    d.arc((15, 0, 35, 20), 95, 215, fill=INK)
    d.point((10, 18), fill=STONE); d.point((13, 21), fill=STONE)
    return im

star(True).save(os.path.join(OUT, "ui_star_full.png")); star(False).save(os.path.join(OUT, "ui_star_empty.png"))
sun().save(os.path.join(OUT, "ui_forecast_sun.png")); moon().save(os.path.join(OUT, "ui_forecast_moon.png"))
print("done")
