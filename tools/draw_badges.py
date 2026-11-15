"""LIVE / ARCHIVED / REAL / SIMPLIFIED badges in map style (D53): 96x32 pixel pills with a
1 px ink outline, a small icon and Silkscreen text drawn without anti-aliasing.
Usage: python3 -I tools/draw_badges.py assets/sprites/ui assets/fonts/Silkscreen-Bold.ttf"""
import sys, os
from PIL import Image, ImageDraw, ImageFont
OUT, FONT = sys.argv[1], sys.argv[2]
def C(h): return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
INK, WHITE, CREAM, STONE, MAUVE, PLUM = C("2b1a2e"), C("fff6ec"), C("eedbc8"), C("cbb7b3"), C("9b828b"), C("684266")
GREEN, DGREEN, LIME, GOLD, YEL, ICE, BLUE, RED = C("6fc60c"), C("38a918"), C("a2e747"), C("fca54a"), C("fee400"), C("86bdc8"), C("5148ab"), C("c3002b")
font = ImageFont.truetype(FONT, 8)

def pill(name, fill, light, shade, text, icon, txt=INK):
    im = Image.new("RGBA", (96, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(im); d.fontmode = "1"
    d.rounded_rectangle((1, 4, 94, 27), 6, fill=INK)
    d.rounded_rectangle((2, 5, 93, 26), 5, fill=fill)
    d.line((7, 6, 88, 6), fill=light); d.line((7, 25, 88, 25), fill=shade)
    icon(d)
    tw = d.textlength(text, font=font)
    d.text((22 + (70 - tw) / 2, 11), text, font=font, fill=txt)
    im.save(os.path.join(OUT, "badge_%s.png" % name))

def live_icon(d):      # a broadcasting dot
    d.ellipse((7, 12, 15, 20), fill=INK); d.ellipse((8, 13, 14, 19), fill=RED); d.point((10, 14), fill=WHITE)
def archive_icon(d):   # a little data box
    d.rectangle((7, 11, 16, 21), fill=INK); d.rectangle((8, 14, 15, 20), fill=CREAM); d.rectangle((8, 12, 15, 13), fill=MAUVE)
    d.line((10, 16, 13, 16), fill=INK)
def real_icon(d):      # a star
    pts = [(11, 10), (13, 15), (18, 15), (14, 18), (16, 23), (11, 20), (6, 23), (8, 18), (4, 15), (9, 15)]
    d.polygon(pts, fill=YEL, outline=INK)
def simple_icon(d):    # a rounded "≈"
    for y in (13, 18):
        d.line((7, y + 1, 9, y - 1), fill=INK); d.line((9, y - 1, 12, y + 1), fill=INK); d.line((12, y + 1, 15, y - 1), fill=INK)

pill("live", GREEN, LIME, DGREEN, "LIVE", live_icon)
pill("archived", GOLD, YEL, C("c47a2a"), "ARCHIVED", archive_icon)
pill("real", BLUE, ICE, PLUM, "REAL", real_icon, txt=WHITE)
pill("simplified", ICE, WHITE, MAUVE, "SIMPLIFIED", simple_icon)
print("done")
