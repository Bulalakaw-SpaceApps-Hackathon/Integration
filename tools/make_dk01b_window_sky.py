"""DK-01b live window layers. For each desk window (L = big west window, R = small east window):
  sky_night_*  plain night sky (the base layer)
  sky_dusk_*   Mars sunset: a BLUE glow around the setting sun (real: Mars sunsets look blue)
  sky_dawn_*   sunrise glow, strongest in the east (right) window
  sky_flare_*  the bright sky when a solar flare's light arrives
  sky_storm_*  dust-storm haze (drawn OVER the hills, mixed in with a dither)
  hills_*      the Mars horizon on a transparent sky
WindowView.gd swaps between these with an ordered dither, so only palette colours ever appear.
Usage: python3 make_dk01b_window_sky.py <project root>"""
import sys
from PIL import Image, ImageDraw
OUT = sys.argv[1] + "/assets/sprites/desk/window/"
import os; os.makedirs(OUT, exist_ok=True)
def c(h): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (255,)
INK, HI, CREAM, STONE, MAUVE, PLUM = c("2B1A2E"), c("FFF6EC"), c("EEDBC8"), c("CBB7B3"), c("9B828B"), c("684266")
HAZE, INDIGO, VIOLET, NIGHT = c("86BDC8"), c("5148AB"), c("5E018B"), c("552465")
SAND, ORANGE, RUST, CRIMSON = c("FCA54A"), c("FF6D00"), c("FD5100"), c("C3002B")
CLEAR = (0, 0, 0, 0)
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

# window glass rectangles, same numbers as make_dk01_desk_bg.py (inclusive)
WINDOWS = {"L": (172, 104, 522, 274), "R": (806, 128, 1004, 270)}


def ramp(w, h, value, stops):
    """Paint a w x h image. value(x, y) -> 0..1; stops = [(limit, colour), ...] ascending.
    Edges between colours are dithered in 2x2 blocks so the art keeps its chunky pixels."""
    img = Image.new("RGBA", (w, h))
    px = img.load()
    for by in range(0, h, 2):
        for bx in range(0, w, 2):
            v = value(bx, by) + (BAYER[(by // 2) % 4][(bx // 2) % 4] / 16.0 - 0.5) * 0.12
            col = stops[-1][1]
            for lim, cc in stops:
                if v < lim:
                    col = cc
                    break
            for yy in range(by, min(by + 2, h)):
                for xx in range(bx, min(bx + 2, w)):
                    px[xx, yy] = col
    return img


def night(w, h):
    # darker at the top, a little violet/indigo near the horizon (same look as the approved art)
    return ramp(w, h, lambda x, y: y / h, [(0.30, NIGHT), (0.62, VIOLET), (0.80, NIGHT), (1.01, VIOLET)])


def glow(w, h, sx, sy, radius, strength):
    """Night sky plus a blue sun-glow centred at (sx, sy)."""
    base = night(w, h)
    def v(x, y):
        dx, dy = (x - sx) / radius, (y - sy) / (radius * 0.75)
        return (dx * dx + dy * dy) ** 0.5 / strength
    g = ramp(w, h, v, [(0.10, HI), (0.36, HAZE), (0.70, INDIGO), (0.92, VIOLET), (9, CLEAR)])
    base.alpha_composite(g)
    return base


def flare(w, h):
    return ramp(w, h, lambda x, y: y / h, [(0.18, HAZE), (0.42, INDIGO), (0.70, VIOLET), (1.01, NIGHT)])


def storm(w, h):
    import math
    return ramp(w, h, lambda x, y: y / h + 0.10 * math.sin(x / 23.0 + y / 11.0), [(0.30, RUST), (0.70, ORANGE), (2.0, SAND)])


def hills(w, h):
    img = Image.new("RGBA", (w, h), CLEAR)
    d = ImageDraw.Draw(img)
    y1 = h - 1
    back = [(0, y1 - 46)] + [(x, y1 - 46 - int(10 * abs((x % 90) - 45) / 45)) for x in range(0, w + 15, 15)] + [(w, y1), (0, y1)]
    d.polygon(back, fill=CRIMSON)
    front = [(0, y1 - 26)] + [(x, y1 - 24 - int(8 * abs(((x + 30) % 70) - 35) / 35)) for x in range(0, w + 10, 10)] + [(w, y1), (0, y1)]
    d.polygon(front, fill=RUST)
    d.line((0, y1 - 10, w, y1 - 10), fill=ORANGE, width=2)
    return img


for key, (x0, y0, x1, y1) in WINDOWS.items():
    w, h = x1 - x0 + 1, y1 - y0 + 1
    night(w, h).save(f"{OUT}sky_night_{key}.png")
    # the sun sets in the west (left window) and rises in the east (right window)
    if key == "L":
        glow(w, h, w * 0.30, h - 40, w * 0.55, 1.0).save(f"{OUT}sky_dusk_{key}.png")
        glow(w, h, w * 1.25, h - 30, w * 0.70, 0.55).save(f"{OUT}sky_dawn_{key}.png")
    else:
        glow(w, h, -w * 0.9, h - 30, w * 1.1, 0.50).save(f"{OUT}sky_dusk_{key}.png")
        glow(w, h, w * 0.65, h - 36, w * 0.75, 1.0).save(f"{OUT}sky_dawn_{key}.png")
    flare(w, h).save(f"{OUT}sky_flare_{key}.png")
    storm(w, h).save(f"{OUT}sky_storm_{key}.png")
    hills(w, h).save(f"{OUT}hills_{key}.png")
print("ok", OUT)
