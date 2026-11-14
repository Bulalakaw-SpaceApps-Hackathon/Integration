"""DK-01 desk background (1280x720), remastered from the team scratch.
Room: ceiling lamp, back wall with two windows (night sky, Phobos + Deimos, Earth dot, Mars horizon),
door + switches on the left wall, slats on the right wall, first-person desk top below y=526."""
import sys, random
from PIL import Image, ImageDraw
OUT = sys.argv[1]
def c(h): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
INK, HI, CREAM, STONE, MAUVE, PLUM = c("2B1A2E"), c("FFF6EC"), c("EEDBC8"), c("CBB7B3"), c("9B828B"), c("684266")
HAZE, INDIGO, VIOLET, NIGHT = c("86BDC8"), c("5148AB"), c("5E018B"), c("552465")
SAND, ORANGE, RUST, CRIMSON = c("FCA54A"), c("FF6D00"), c("FD5100"), c("C3002B")
WARN, OK, DANGER = c("FEE400"), c("38A918"), c("EC0500")
W, H = 1280, 720
img = Image.new("RGB", (W, H), MAUVE); d = ImageDraw.Draw(img)

def dither_band(box, a, b, density):
    """Fill box with colour a, sprinkling colour b on a 2x2 checker at the given density (0..1)."""
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=a)
    for y in range(y0, y1 + 1, 2):
        for x in range(x0 + (y // 2) % 2 * 2, x1, 4):
            if ((x * 7 + y * 13) % 100) / 100 < density:
                d.rectangle((x, y, min(x + 1, x1), min(y + 1, y1)), fill=b)

# ---- ceiling --------------------------------------------------------------
CEIL = 88
d.polygon([(0, 0), (W, 0), (W - 130, CEIL), (130, CEIL)], fill=PLUM)
d.line((130, CEIL, W - 130, CEIL), fill=INK, width=3)
for x in range(200, W - 200, 120):                      # ceiling panel seams
    d.line((x, 0, x + (x - 640) // 12, CEIL - 2), fill=NIGHT, width=2)

# ---- side walls (perspective) -----------------------------------------------
d.polygon([(0, 0), (130, CEIL), (130, 526), (0, 620)], fill=PLUM)          # left wall
d.polygon([(W, 0), (W - 130, CEIL), (W - 130, 526), (W, 620)], fill=PLUM)   # right wall
d.line((130, CEIL, 130, 526), fill=INK, width=3); d.line((W - 130, CEIL, W - 130, 526), fill=INK, width=3)
# pipes on the left wall (the door moved to the back wall so it stays visible)
for px in (40, 70):
    d.line((px, 40 + (px - 40), px, 600), fill=MAUVE, width=10)
    d.line((px - 5, 40 + (px - 40), px - 5, 600), fill=INK, width=2); d.line((px + 5, 40 + (px - 40), px + 5, 600), fill=INK, width=2)
    for y in (200, 360):
        d.rectangle((px - 8, y, px + 8, y + 8), fill=STONE, outline=INK, width=2)
# slats on the right wall
for y in range(130, 500, 46):
    yl = y + int((y - 90) * 0.04)
    d.line((W - 124, y, W - 8, yl + 18), fill=NIGHT, width=4)
    d.line((W - 124, y + 4, W - 8, yl + 22), fill=MAUVE, width=2)

# ---- back wall --------------------------------------------------------------
d.rectangle((133, CEIL + 2, W - 133, 523), fill=MAUVE)
for x in range(260, W - 133, 170):                     # wall panel seams
    d.line((x, CEIL + 2, x, 523), fill=PLUM, width=2)
d.rectangle((133, 511, W - 133, 523), fill=PLUM)      # dark wainscot behind the desk
d.line((133, 511, W - 133, 511), fill=INK, width=2)

# ---- windows ----------------------------------------------------------------
random.seed(7)
MAGIC = (1, 2, 3)   # marks glass pixels; turned transparent on save
def window(x0, y0, x1, y1, moons, earth):
    d.rectangle((x0 - 10, y0 - 10, x1 + 10, y1 + 10), fill=STONE, outline=INK, width=3)   # frame
    # The glass is cut out (made transparent) so the live sky (scripts/WindowView.gd) shows through.
    # The sky, stars, moons and hills are drawn by tools/make_dk01b_window_sky.py + WindowView.gd.
    d.rectangle((x0, y0, x1, y1), fill=MAGIC)
    # cross divider (from the scratch)
    mxl = (x0 + x1) // 2
    d.rectangle((mxl - 4, y0, mxl + 4, y1), fill=STONE, outline=INK, width=2)
    d.rectangle((x0, y0 + (y1 - y0) // 3 - 4, x1, y0 + (y1 - y0) // 3 + 4), fill=STONE, outline=INK, width=2)
    d.line((x0 + 2, y0 + 2, x0 + 2, y1 - 2), fill=HI)  # glass shine

# Windows sit high on the wall, deliberately not mirrored: a wide one left, a smaller one right.
window(172, 104, 522, 274, moons=[(252, 142, 13, STONE)], earth=None)          # Phobos (bigger)
window(806, 128, 1004, 270, moons=[(968, 156, 7, STONE)], earth=(852, 176))    # Deimos + Earth

# ---- door on the back wall, slightly right of centre between the monitors ----
DX0, DX1, DY0 = 548, 732, 176                                                 # wide door; both monitors overlap its edges
d.rectangle((DX0 - 6, DY0 - 6, DX1 + 6, 515), fill=STONE, outline=INK, width=3)     # frame
d.rectangle((DX0, DY0, DX1, 515), fill=MAUVE, outline=INK, width=2)                 # door
d.rectangle((DX0 + 40, DY0 + 16, DX1 - 40, DY0 + 96), fill=VIOLET, outline=INK, width=2)   # door window (in the visible middle)
d.line((DX0 + 50, DY0 + 22, DX0 + 66, DY0 + 90), fill=INDIGO, width=3)
d.line((DX0 + 92, DY0 + 16, DX0 + 92, DY0 + 96), fill=STONE, width=3)                    # window divider
d.rectangle((DX0 + 22, DY0 + 128, DX1 - 22, 500), outline=PLUM, width=2)                 # lower door panel
d.line((DX0 + 3, DY0 + 4, DX0 + 3, 510), fill=STONE, width=2)                       # edge light
d.rectangle((DX1 - 66, DY0 + 112, DX1 - 48, DY0 + 118), fill=STONE, outline=INK)            # lever handle (stays visible)
for i, x in enumerate((DX1 + 12, DX1 + 30)):                                        # switch boxes beside the door, above the monitor
    d.rectangle((x, DY0 + 14, x + 13, DY0 + 44), fill=STONE, outline=INK, width=2)
    d.rectangle((x + 4, DY0 + 23, x + 9, DY0 + 29), fill=OK if i == 0 else WARN)

# ---- ceiling lamp (top centre) ----------------------------------------------
d.line((640, 0, 640, 40), fill=INK, width=4)
d.polygon([(596, 74), (684, 74), (664, 40), (616, 40)], fill=STONE, outline=INK, width=3)
d.rectangle((622, 74, 658, 80), fill=WARN, outline=INK, width=2)
d.ellipse((600, 70, 680, 96), fill=CREAM)               # warm glow under the lamp
d.polygon([(596, 74), (684, 74), (664, 40), (616, 40)], fill=STONE, outline=INK, width=3)
d.rectangle((622, 74, 658, 80), fill=WARN, outline=INK, width=2)

# ---- desk (first-person desk top) -------------------------------------------
d.polygon([(0, 526), (W, 526), (W, H), (0, H)], fill=MAUVE)
d.rectangle((0, 516, W, 530), fill=STONE, outline=INK, width=3)    # back lip of the desk
d.line((0, 531, W, 531), fill=PLUM, width=3)
for y, col in ((560, STONE), (640, STONE)):                         # subtle top texture lines
    d.line((0, y, W, y), fill=col)
d.rectangle((0, 704, W, H), fill=PLUM); d.line((0, 704, W, 704), fill=INK, width=3)   # front edge
for x in range(40, W, 160):                                          # screws on the front edge
    d.rectangle((x, 710, x + 3, 713), fill=STONE)

rgba = img.convert("RGBA")
rgba.putdata([(0, 0, 0, 0) if px[:3] == MAGIC else px for px in rgba.getdata()])
rgba.save(f"{OUT}/assets/sprites/desk/desk_bg.png"); print("ok")
