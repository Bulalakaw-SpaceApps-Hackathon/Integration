"""Alert icons in map style (D53), from the team's AL- scratch: 28x28 (the size the alert strip
shows them at, so they are never scaled), flat pixel art, 1 px ink outline, game palette.
Usage: python3 -I tools/draw_alerts.py assets/sprites/ui data/assets.json"""
import json, math, os, sys
from PIL import Image, ImageDraw
OUT, MAN = sys.argv[1], sys.argv[2]
S = 28
def C(h): return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
INK, PLUM, MAUVE, STONE, CREAM, WHITE = C("2b1a2e"), C("684266"), C("9b828b"), C("cbb7b3"), C("eedbc8"), C("fff6ec")
ORANGE, GOLD, YEL, RED = C("ff6d00"), C("fca54a"), C("fee400"), C("c3002b")
ICE, BLUE, GREEN, LIME, R2, R3 = C("86bdc8"), C("5148ab"), C("6fc60c"), C("a2e747"), C("8a3a28"), C("ce764c")

def badge(fill):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, S - 1, S - 1), 6, fill=INK); d.rounded_rectangle((1, 1, S - 2, S - 2), 5, fill=fill)
    d.line((5, 2, S - 6, 2), fill=WHITE)
    return im, d

def battery():
    im, d = badge(STONE)
    d.rectangle((5, 9, 21, 19), fill=INK); d.rectangle((21, 12, 23, 16), fill=INK)
    d.rectangle((6, 10, 20, 18), fill=CREAM); d.rectangle((7, 11, 9, 17), fill=RED)
    return im
def co2():
    im, d = badge(STONE)
    for b in ((4, 10, 14, 20), (10, 6, 22, 18), (16, 11, 24, 20)): d.ellipse(b, fill=INK)
    for b in ((5, 11, 13, 19), (11, 7, 21, 17), (17, 12, 23, 19)): d.ellipse(b, fill=MAUVE)
    d.rectangle((6, 15, 22, 19), fill=MAUVE)
    return im
def cold():
    im, d = badge(ICE)
    for k in range(3):
        a = k * math.pi / 3
        dx, dy = 9 * math.cos(a), 9 * math.sin(a)
        d.line((14 - dx, 14 - dy, 14 + dx, 14 + dy), fill=INK, width=3); d.line((14 - dx, 14 - dy, 14 + dx, 14 + dy), fill=WHITE)
    return im
def comms():
    im, d = badge(STONE)
    d.ellipse((4, 6, 18, 18), fill=INK); d.ellipse((5, 7, 17, 17), fill=WHITE)
    d.line((11, 18, 8, 24), fill=INK, width=2); d.line((11, 18, 14, 24), fill=INK, width=2)
    d.line((17, 6, 24, 13), fill=RED, width=2); d.line((24, 6, 17, 13), fill=RED, width=2)
    return im
def dose():
    im, d = badge(YEL)
    d.ellipse((11, 11, 17, 17), fill=INK)
    for k in range(3):
        a0 = -90 + k * 120
        d.pieslice((4, 4, 24, 24), a0 - 30, a0 + 30, fill=INK)
    d.ellipse((9, 9, 19, 19), outline=YEL, width=2); d.ellipse((12, 12, 16, 16), fill=INK)
    return im
def dust():
    im, d = badge(R3)
    for r, c in ((10, R2), (7, ORANGE), (4, GOLD)): d.arc((14 - r, 14 - r, 14 + r, 14 + r), 30, 300, fill=c, width=2)
    return im
def flare():
    im, d = badge(ORANGE)
    for k in range(8):
        a = k * math.pi / 4
        d.line((14, 14, 14 + 11 * math.cos(a), 14 + 11 * math.sin(a)), fill=YEL, width=2)
    d.ellipse((8, 8, 20, 20), fill=INK); d.ellipse((9, 9, 19, 19), fill=WHITE)
    return im
def hungry():
    im, d = badge(STONE)
    d.ellipse((6, 9, 22, 24), fill=INK); d.ellipse((7, 10, 21, 23), fill=RED); d.point((10, 13), fill=WHITE)
    d.line((14, 9, 15, 4), fill=INK, width=2); d.ellipse((15, 4, 21, 8), fill=GREEN)
    return im
def info():
    im, d = badge(BLUE)
    d.rectangle((12, 5, 15, 8), fill=WHITE); d.rectangle((12, 11, 15, 22), fill=WHITE); d.rectangle((10, 20, 17, 22), fill=WHITE)
    return im
def thump():
    im, d = badge(STONE)
    pts = [(14, 3), (16, 10), (24, 8), (18, 14), (25, 20), (16, 18), (14, 25), (12, 18), (3, 20), (10, 14), (4, 8), (12, 10)]
    d.polygon(pts, fill=YEL, outline=INK)
    return im

raw = open(MAN).read(); man = json.loads(raw)
for name, fn in (("battery", battery), ("co2", co2), ("cold", cold), ("comms", comms), ("dose", dose), ("dust", dust),
                 ("flare", flare), ("hungry", hungry), ("info", info), ("thump", thump)):
    fn().save(os.path.join(OUT, "alert_%s.png" % name))
    man["alert_" + name].update({"w": S, "h": S, "frames": 1})
open(MAN, "w").write(json.dumps(man, indent="\t", ensure_ascii=False) + ("\n" if raw.endswith("\n") else ""))
print("done")
