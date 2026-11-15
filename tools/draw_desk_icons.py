"""Desk control icons in map style (D53): 24x24 flat pixel art, 1 px ink outline, game palette.
Guided by the team's BT- scratch (assets/source/scratch-1115/BT-). Animated ones (D66) are
strips of frames in one row: the fan spins, the lamp glows, the dish sends waves, recall pulses.

Usage: python3 -I tools/draw_desk_icons.py assets/sprites/ui data/assets.json
"""
import json, math, os, sys
from PIL import Image, ImageDraw

OUT, MAN = sys.argv[1], sys.argv[2]
S = 24
def C(h): return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
INK, PLUM, DPLUM, MAUVE, STONE, CREAM, WHITE = C("2b1a2e"), C("684266"), C("552465"), C("9b828b"), C("cbb7b3"), C("eedbc8"), C("fff6ec")
ORANGE, GOLD, YEL, RED = C("ff6d00"), C("fca54a"), C("fee400"), C("c3002b")
ICE, BLUE, MAG, LMAG = C("86bdc8"), C("5148ab"), C("d65cec"), C("f3b6ff")
GREEN, LIME, DGREEN = C("6fc60c"), C("a2e747"), C("38a918")
CLEAR = (0, 0, 0, 0)


def new():
    im = Image.new("RGBA", (S, S), CLEAR); return im, ImageDraw.Draw(im)


def box(d, b, fill, hi=None):
    x0, y0, x1, y1 = b
    d.rectangle(b, fill=INK); d.rectangle((x0 + 1, y0 + 1, x1 - 1, y1 - 1), fill=fill)
    if hi: d.line((x0 + 1, y0 + 1, x1 - 1, y0 + 1), fill=hi)


def heater(level):
    im, d = new()
    box(d, (2, 5, 21, 20), PLUM, MAUVE)
    for k in range(3):                                    # three coils; `level` of them glow
        x = 5 + k * 5
        hot = k < level
        d.rectangle((x, 8, x + 3, 17), fill=INK)
        d.rectangle((x + 1, 9, x + 2, 16), fill=ORANGE if hot else DPLUM)
        if hot: d.point((x + 1, 9), fill=YEL)
    for x in (4, 18): d.rectangle((x, 20, x + 1, 22), fill=INK)
    return im


def fan(level, frame):
    im, d = new()
    cx, cy = 12, 10
    d.ellipse((2, 0, 22, 20), fill=INK); d.ellipse((3, 1, 21, 19), fill=STONE)
    for k in range(3):
        a = frame * math.pi / 6 + k * 2 * math.pi / 3
        x, y = cx + 7 * math.cos(a), cy + 7 * math.sin(a)
        d.line((cx, cy, x, y), fill=ICE, width=3)
    d.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=INK)
    d.rectangle((11, 19, 12, 21), fill=INK); d.rectangle((7, 21, 16, 23), fill=INK)
    for k in range(level):                                # speed ticks
        d.rectangle((18 + 0, 22 - k * 3, 21, 23 - k * 3), fill=LIME)
    return im


def shelter(open_):
    im, d = new()
    d.rectangle((3, 2, 20, 22), fill=INK)
    for x in range(3, 21, 4):                            # hazard frame
        d.rectangle((x, 3, x + 1, 4), fill=YEL)
    d.rectangle((4, 5, 19, 21), fill=YEL)
    if open_:
        d.rectangle((6, 6, 17, 21), fill=INK); d.rectangle((9, 9, 14, 21), fill=ORANGE); d.rectangle((10, 10, 13, 21), fill=GOLD)
    else:
        d.rectangle((6, 6, 17, 21), fill=STONE); d.rectangle((6, 18, 17, 21), fill=MAUVE)
        d.line((12, 7, 10, 12), fill=YEL); d.line((10, 12, 13, 12), fill=YEL); d.line((13, 12, 11, 17), fill=YEL)
    return im


def recall(frame):
    im, d = new()
    r = 10 if frame == 0 else 11
    d.arc((12 - r, 12 - r, 12 + r, 12 + r), 200, 520 - 180, fill=GOLD if frame else ORANGE, width=2)
    d.polygon([(2, 9), (6, 14), (8, 8)], fill=GOLD if frame else ORANGE)   # arrow head: "come back"
    d.ellipse((6, 5, 18, 17), fill=INK); d.ellipse((7, 6, 17, 16), fill=WHITE)
    d.rectangle((9, 9, 15, 13), fill=INK); d.rectangle((10, 10, 14, 12), fill=YEL)
    return im


def lamp(on, frame=0):
    im, d = new()
    d.line((12, 0, 12, 4), fill=INK)
    box(d, (3, 4, 20, 9), MAUVE if not on else LMAG, CREAM if on else STONE)
    if on:
        n = 4 if frame else 3
        for k in range(n):
            x = 5 + k * (12 // (n - 1))
            d.line((x, 11, x - 1 + k % 2, 14 + frame), fill=MAG)
    d.rectangle((6, 18, 17, 23), fill=INK); d.rectangle((7, 19, 16, 22), fill=C("c2502a"))
    for dx in (-3, 0, 3): d.line((12, 18, 12 + dx, 14), fill=GREEN if on else DGREEN)
    return im


def dish(on, frame=0):
    im, d = new()
    d.line((10, 14, 7, 22), fill=INK, width=2); d.line((12, 14, 15, 22), fill=INK, width=2)
    d.ellipse((2, 4, 18, 16), fill=INK); d.ellipse((3, 5, 17, 15), fill=WHITE if on else STONE)
    d.ellipse((5, 7, 15, 14), fill=CREAM if on else MAUVE)
    d.line((10, 10, 15, 4), fill=INK); d.rectangle((14, 2, 16, 4), fill=ORANGE if on else MAUVE)
    if on:
        for k in range(1 + frame):
            r = 3 + k * 3
            d.arc((17 - r, 4 - r, 17 + r, 4 + r), 290, 360, fill=ICE)
    return im


def ask_earth():
    im, d = new()
    d.rounded_rectangle((1, 1, 15, 13), 3, fill=INK); d.rounded_rectangle((2, 2, 14, 12), 2, fill=WHITE)
    d.polygon([(4, 12), (8, 12), (3, 16)], fill=INK)
    d.line((6, 4, 9, 4), fill=BLUE); d.point((10, 5), fill=BLUE); d.line((9, 6, 8, 8), fill=BLUE); d.point((8, 10), fill=BLUE)
    d.ellipse((12, 11, 23, 22), fill=INK); d.ellipse((13, 12, 22, 21), fill=BLUE)
    d.rectangle((15, 14, 17, 16), fill=GREEN); d.rectangle((18, 17, 20, 19), fill=GREEN)
    return im


def send():
    im, d = new()
    pts = [(14, 2), (16, 9), (23, 9), (17, 13), (19, 21), (14, 16), (9, 21), (11, 13), (5, 9), (12, 9)]
    d.polygon(pts, fill=YEL, outline=INK)
    for y in (12, 15, 18): d.line((0, y + 2, 5, y), fill=ORANGE)
    return im


def pause():
    im, d = new()
    for x in (6, 14): box(d, (x, 4, x + 4, 19), CREAM)
    return im


def speaker(muted):
    im, d = new()
    d.polygon([(3, 9), (7, 9), (12, 4), (12, 19), (7, 14), (3, 14)], fill=CREAM, outline=INK)
    if muted:
        d.line((15, 8, 21, 15), fill=RED, width=2); d.line((21, 8, 15, 15), fill=RED, width=2)
    else:
        d.arc((10, 6, 18, 17), 300, 60, fill=INK, width=2); d.arc((10, 2, 22, 21), 300, 60, fill=INK, width=2)
    return im


def gear():
    im, d = new()
    for k in range(8):
        a = k * math.pi / 4
        x, y = 12 + 9 * math.cos(a), 12 + 9 * math.sin(a)
        d.rectangle((x - 2, y - 2, x + 2, y + 2), fill=INK)
    d.ellipse((4, 4, 20, 20), fill=INK); d.ellipse((5, 5, 19, 19), fill=STONE)
    d.ellipse((9, 9, 15, 15), fill=INK); d.ellipse((10, 10, 14, 14), fill=PLUM)
    return im


def hint():
    im, d = new()
    d.ellipse((5, 2, 19, 16), fill=INK); d.ellipse((6, 3, 18, 15), fill=YEL)
    d.point((9, 6), fill=WHITE); d.point((10, 5), fill=WHITE)
    d.rectangle((9, 15, 15, 20), fill=INK); d.rectangle((10, 16, 14, 19), fill=STONE)
    d.line((10, 18, 14, 18), fill=MAUVE)
    return im


def strip(frames):
    out = Image.new("RGBA", (S * len(frames), S), CLEAR)
    for i, f in enumerate(frames): out.alpha_composite(f, (i * S, 0))
    return out


ICONS = {
    "icon_heater_low": [heater(1)], "icon_heater_mid": [heater(2)], "icon_heater_high": [heater(3)],
    "icon_life_support_low": [fan(1, k) for k in range(4)],
    "icon_life_support_normal": [fan(2, k) for k in range(4)],
    "icon_life_support_high": [fan(3, k) for k in range(4)],
    "icon_shelter_open": [shelter(True)], "icon_shelter_closed": [shelter(False)],
    "icon_recall": [recall(0), recall(1)],
    "icon_crop_lamp_on": [lamp(True, 0), lamp(True, 1)], "icon_crop_lamp_off": [lamp(False)],
    "icon_dish_on": [dish(True, 0), dish(True, 1)], "icon_dish_off": [dish(False)],
    "icon_ask_earth": [ask_earth()], "icon_send_discovery": [send()],
    "icon_pause": [pause()], "icon_mute_off": [speaker(False)], "icon_mute_on": [speaker(True)],
    "icon_settings": [gear()], "icon_hint": [hint()],
}
raw = open(MAN).read(); man = json.loads(raw)
for name, frames in ICONS.items():
    strip(frames).save(os.path.join(OUT, name + ".png"))
    man[name].update({"w": S, "h": S, "frames": len(frames)})
open(MAN, "w").write(json.dumps(man, indent="\t", ensure_ascii=False) + ("\n" if raw.endswith("\n") else ""))
print("done", len(ICONS))
