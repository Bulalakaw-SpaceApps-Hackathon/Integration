"""DK-09 meter icons, 48x48 pixel art on transparent background, palette colours only.
Writes assets/sprites/desk/ui_meter_{oxygen,dose,comms,food}.png"""
import sys
from PIL import Image, ImageDraw
OUT = sys.argv[1]
def c(h, a=255): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (a,)
INK, HI, CREAM, STONE, MAUVE, PLUM = c("2B1A2E"), c("FFF6EC"), c("EEDBC8"), c("CBB7B3"), c("9B828B"), c("684266")
HAZE, INDIGO, WARN, WARN_S = c("86BDC8"), c("5148AB"), c("FEE400"), c("CAA836")
CRIMSON, DANGER_S, LEAF, LEAF_D = c("C3002B"), c("B03228"), c("A2E69F"), c("57BE6B")

def canvas():
    im = Image.new("RGBA", (48, 48), (0, 0, 0, 0)); return im, ImageDraw.Draw(im)

# tiny 3x5 pixel glyphs for the O2 label
GLYPH = {"O": ["111", "101", "101", "101", "111"], "2": ["111", "001", "111", "100", "111"]}
def text(d, x, y, s, col):
    for ch in s:
        for j, row in enumerate(GLYPH[ch]):
            for i, b in enumerate(row):
                if b == "1": d.point((x + i, y + j), fill=col)
        x += 4

def oxygen():
    im, d = canvas()
    d.rectangle((17, 3, 30, 5), fill=MAUVE, outline=INK)                 # valve handle
    d.rectangle((21, 5, 26, 11), fill=STONE, outline=INK)               # neck
    d.rounded_rectangle((13, 10, 34, 45), radius=7, fill=HAZE, outline=INK)   # tank
    d.rectangle((29, 14, 32, 41), fill=c("6FA2AD"))                     # right shade (darker haze)
    d.line((16, 15, 16, 40), fill=HI); d.line((17, 13, 17, 15), fill=HI)  # shine
    d.rectangle((14, 21, 33, 31), fill=CREAM, outline=INK)              # label band
    text(d, 18, 24, "O2", INK)
    for (x, y, r) in [(39, 12, 3), (42, 5, 2)]:                         # bubbles
        d.ellipse((x - r, y - r, x + r, y + r), fill=HI, outline=INK)
    return im

def dose():
    im, d = canvas()
    d.rectangle((18, 2, 29, 9), fill=MAUVE, outline=INK)                # clip
    d.rectangle((21, 4, 26, 6), fill=PLUM)
    d.rounded_rectangle((8, 7, 39, 45), radius=5, fill=CREAM, outline=INK)  # badge
    d.line((10, 9, 10, 42), fill=HI)
    d.ellipse((12, 11, 35, 34), fill=WARN, outline=INK)                 # window
    cx, cy, r = 23.5, 22.5, 9
    for a in (240, 0, 120):                                             # trefoil blades
        d.pieslice((cx - r, cy - r, cx + r, cy + r), a, a + 60, fill=INK)
    d.ellipse((cx - 3.5, cy - 3.5, cx + 3.5, cy + 3.5), fill=WARN)
    d.ellipse((cx - 1.5, cy - 1.5, cx + 1.5, cy + 1.5), fill=INK)
    d.rectangle((14, 37, 33, 41), fill=INDIGO, outline=INK)            # tiny readout
    d.line((16, 39, 22, 39), fill=HAZE)
    return im

def comms():
    im, d = canvas()
    d.rectangle((10, 42, 32, 45), fill=MAUVE, outline=INK)              # base
    d.rectangle((18, 31, 24, 42), fill=STONE, outline=INK)              # stand
    # dish: a bowl drawn flat, then tilted to face up-right
    dish = Image.new("RGBA", (34, 18), (0, 0, 0, 0)); dd = ImageDraw.Draw(dish)
    dd.ellipse((0, 0, 33, 17), fill=CREAM, outline=INK)
    dd.ellipse((4, 3, 29, 13), fill=STONE)                              # bowl inside
    dd.ellipse((14, 6, 19, 10), fill=MAUVE)                             # centre hub
    dish = dish.rotate(38, resample=Image.NEAREST, expand=True)
    im.alpha_composite(dish, (2, 8))
    d.line((21, 26, 31, 15), fill=INK)                                  # feed arm
    d.ellipse((29, 12, 34, 17), fill=WARN, outline=INK)                 # feed horn
    for rr in (4, 7, 10):                                               # signal waves
        d.arc((36 - rr, 11 - rr, 36 + rr, 11 + rr), 285, 345, fill=INDIGO, width=2)
    return im

def food():
    im, d = canvas()
    lobes = [(7, 14, 29, 44), (19, 14, 41, 44)]
    for b in lobes:                                                     # outline as one shape
        d.ellipse(b, fill=INK)
    for (x0, y0, x1, y1) in lobes:                                      # body inset by 1 px
        d.ellipse((x0 + 1, y0 + 1, x1 - 1, y1 - 1), fill=CRIMSON)
    d.pieslice((21, 16, 39, 42), 300, 60, fill=DANGER_S)                # right shade, inside outline
    d.ellipse((11, 19, 16, 25), fill=HI)                                # shine
    d.line((24, 7, 24, 16), fill=PLUM, width=2)                         # stem
    d.polygon([(26, 10), (31, 5), (38, 5), (34, 11), (28, 12)], fill=LEAF, outline=INK)  # leaf
    d.line((28, 10, 35, 6), fill=LEAF_D)
    return im

icons = {"oxygen": oxygen(), "dose": dose(), "comms": comms(), "food": food()}
for k, im in icons.items():
    im.save(f"{OUT}/assets/sprites/desk/ui_meter_{k}.png")
print("ok")
