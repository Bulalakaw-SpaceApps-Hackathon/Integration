"""Camera Desk layout template (1280x720). Artists draw DK-01..DK-10 over it so pieces line up."""
import sys
from PIL import Image, ImageDraw, ImageFont
OUT = sys.argv[1]
def c(h): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
INK, CREAM, HI = c("2B1A2E"), c("EEDBC8"), c("FFF6EC")
F = "/usr/share/fonts/truetype/dejavu/"
fb = ImageFont.truetype(F + "DejaVuSans-Bold.ttf", 15); fs = ImageFont.truetype(F + "DejaVuSans.ttf", 12)

img = Image.new("RGB", (1280, 720), c("552465")); d = ImageDraw.Draw(img)
# DK-01 regions: wall/window (top) and desk surface (bottom)
d.rectangle((0, 0, 1279, 525), fill=c("552465"))
d.rectangle((0, 526, 1279, 719), fill=c("684266"))
d.line((0, 526, 1279, 526), fill=INK, width=3)
for x, y in [(60, 400), (130, 440), (1150, 380), (980, 450), (300, 420), (760, 455)]:
    d.ellipse((x, y, x + 3, y + 3), fill=HI)                       # stars
d.ellipse((1200, 420, 1212, 432), fill=c("CBB7B3")); d.ellipse((1228, 440, 1234, 446), fill=c("CBB7B3"))  # moons
d.ellipse((1170, 470, 1176, 476), fill=c("86BDC8"))                 # Earth dot

BOX = [  # (id, label, size note, x0, y0, x1, y1, fill)
    ("DK-07", "Battery bar", "456x48", 378, 22, 834, 70, "EEDBC8"),
    ("DK-08", "Forecast icon", "32x32", 846, 30, 878, 62, "FEE400"),
    ("", "Forecast text (code)", "", 886, 30, 1050, 62, None),
    ("DK-06", "Clock", "236x80", 130, 10, 366, 90, "9B828B"),
    ("BT-09", "Pause / mute", "48x48 each", 16, 22, 124, 70, "CBB7B3"),
    ("DK-03", "Left panel", "160x330", 16, 198, 176, 528, "9B828B"),
    ("DK-04", "Right panel", "160x330", 1104, 198, 1264, 528, "9B828B"),
    ("DK-02", "Monitor 1", "352x272 incl. stand", 229, 258, 581, 530, "CBB7B3"),
    ("DK-02", "Monitor 2", "352x272 incl. stand", 699, 258, 1051, 530, "CBB7B3"),
    ("AL-03", "Warning banner / alerts", "400x60", 440, 112, 840, 172, "FEE400"),
    ("BT-02", "6 camera buttons", "96x96 each", 322, 538, 958, 634, "EEDBC8"),
    ("DK-09", "Meter panel", "192x128", 16, 576, 208, 704, "CBB7B3"),
    ("DK-05", "Hanging scroll", "212x196", 1058, 2, 1270, 198, "FEE400"),
    ("DK-10", "Props (cup, fan)", "", 980, 640, 1270, 712, None),
]
for i, (aid, label, size, x0, y0, x1, y1, fill) in enumerate(BOX):
    if fill:
        d.rectangle((x0, y0, x1, y1), fill=c(fill), outline=INK, width=2)
        col = INK
    else:
        for xx in range(x0, x1, 10): d.line((xx, y0, min(xx + 5, x1), y0), fill=HI); d.line((xx, y1, min(xx + 5, x1), y1), fill=HI)
        col = HI
    tx = x0 + 6
    if x1 - x0 < 60:   # tiny box: id only, label goes to the right
        d.text((x0 + 2, y1 + 4), aid, font=fs, fill=HI)
        continue
    if x1 - x0 < 330 or label.startswith("Monitor"):
        d.text((tx, y0 + 4), aid, font=fb, fill=col)
        d.text((tx, y0 + 22), label + ("  " + size if size else ""), font=fs, fill=col)
        if label.startswith("Monitor"): pass
    else:
        d.text((tx, y0 + 4), (aid + "  " if aid else "") + label, font=fb, fill=col)
        if size: d.text((tx, y0 + 22), size, font=fs, fill=col)
# monitor screen holes (camera feeds) and camera buttons
for mx in (229, 699):
    d.rectangle((mx + 16, 258 + 28, mx + 335, 258 + 207), fill=c("5148AB"), outline=INK, width=2)
    d.text((mx + 30, 258 + 90), "Camera feed  320x180", font=fb, fill=HI)
for k in range(6):
    x = 322 + k * 108
    d.rectangle((x, 538, x + 96, 634), outline=INK, width=2)
    d.text((x + 38, 576), str(k + 1), font=fb, fill=INK)
# panel slots (112x88): button area on top, label plate at the bottom
for x0, names in ((16 + 34, ["Shelter door", "Recall crew", "Dish / Ask / Send"]), (1104 + 14, ["Heater", "Life Support", "Crop Lamp"])):
    for k, sy in enumerate((18, 116, 214)):
        y = 198 + sy
        d.rectangle((x0, y + 40, x0 + 111, y + 87), outline=INK, width=2)
        d.text((x0 + 4, y + 70), names[k], font=fs, fill=INK)
d.text((190, 196), "DK-01 = whole background (wall + windows + desk). Grid: 1280x720.", font=fs, fill=HI)
img.save(f"{OUT}/assets/templates/desk_layout_template.png")
print("ok")
