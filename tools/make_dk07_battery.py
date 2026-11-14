"""DK-07 battery bar (from the scratch: battery outline + terminal nub, segmented fill, low version with '!').
ui_battery_frame.png  456x48, placed at (378,22): casing, nub, 10 empty segment slots.
ui_battery_fill.png   428x36 strip, drawn at frame offset (9,6): 10 green segments.
ui_battery_low.png    428x36 strip, same place: 10 red segments, '!' on the first one (shape cue, not colour only).
Code shows k = ceil(battery% / 10) segments by cropping the strip to k * 43 px wide; uses the low strip below 20%."""
import sys
from PIL import Image, ImageDraw
OUT = sys.argv[1]
def c(h, a=255): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (a,)
INK, HI, CREAM, STONE, MAUVE, PLUM = c("2B1A2E"), c("FFF6EC"), c("EEDBC8"), c("CBB7B3"), c("9B828B"), c("684266")
OK, OK_S, OK_L = c("38A918"), c("44721C"), c("A2E69F")
DANGER, DANGER_S, DANGER_L = c("EC0500"), c("B03228"), c("FF8696")
SLOT = c("33203A")
SEG_W, PITCH, SEG_Y0, SEG_Y1 = 39, 43, 3, 32       # inside the strip

# ---- frame ----
fr = Image.new("RGBA", (456, 48), (0, 0, 0, 0)); d = ImageDraw.Draw(fr)
d.rounded_rectangle((443, 14, 455, 33), radius=3, fill=MAUVE, outline=INK, width=3)      # terminal nub
d.line((446, 18, 446, 29), fill=STONE)
d.rounded_rectangle((0, 0, 445, 47), radius=8, fill=STONE, outline=INK, width=3)         # casing
d.line((6, 4, 438, 4), fill=CREAM, width=2); d.line((4, 6, 4, 41), fill=CREAM, width=2)  # bevel light
d.line((6, 43, 440, 43), fill=MAUVE, width=2)                                            # bevel shade
d.rectangle((6, 6, 439, 41), fill=INK)                                                    # cavity
for k in range(10):                                                                       # empty slots
    x = 9 + k * PITCH
    d.rounded_rectangle((x, 6 + SEG_Y0, x + SEG_W - 1, 6 + SEG_Y1), radius=3, fill=SLOT)
fr.save(f"{OUT}/assets/sprites/desk/ui_battery_frame.png")

# ---- fill strips ----
def strip(main, shade, light, warn_mark):
    im = Image.new("RGBA", (428, 36), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    for k in range(10):
        x = k * PITCH
        d.rounded_rectangle((x, SEG_Y0, x + SEG_W - 1, SEG_Y1), radius=3, fill=main)
        d.line((x + 3, SEG_Y0 + 2, x + SEG_W - 4, SEG_Y0 + 2), fill=light, width=2)      # top shine
        d.line((x + 2, SEG_Y1 - 2, x + SEG_W - 3, SEG_Y1 - 2), fill=shade, width=3)     # bottom shade
    if warn_mark:                                                                         # '!' on segment 1
        d.rectangle((17, SEG_Y0 + 5, 21, SEG_Y0 + 18), fill=INK)
        d.rectangle((17, SEG_Y0 + 21, 21, SEG_Y0 + 25), fill=INK)
    return im
strip(OK, OK_S, OK_L, False).save(f"{OUT}/assets/sprites/desk/ui_battery_fill.png")
strip(DANGER, DANGER_S, DANGER_L, True).save(f"{OUT}/assets/sprites/desk/ui_battery_low.png")
print("ok")
