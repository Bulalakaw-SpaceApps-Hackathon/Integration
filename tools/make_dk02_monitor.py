"""DK-02 monitor (remastered from scratch): bezel 440x281 + neck + base that rests on the desk.
Sprite is 352x272, placed at screen (229,258) and (699,258); the base sits on the desk lip.
Screen hole (transparent) = 320x180 at (16,28). Writes desk_monitor.png (LED on) and desk_monitor_off.png."""
import sys
from PIL import Image, ImageDraw
OUT = sys.argv[1]
def c(h, a=255): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (a,)
INK, HI, CREAM, STONE, MAUVE, PLUM = c("2B1A2E"), c("FFF6EC"), c("EEDBC8"), c("CBB7B3"), c("9B828B"), c("684266")
OK, CLEAR = c("38A918"), (0, 0, 0, 0)
SHADOW = c("2B1A2E", 110)

def monitor(on):
    # bezel 352x224, screen hole 320x180 at (16,28); short stand; base bottom at y=266
    im = Image.new("RGBA", (352, 272), CLEAR); d = ImageDraw.Draw(im)
    d.ellipse((110, 260, 242, 271), fill=SHADOW)                        # shadow on the desk
    d.polygon([(120, 264), (232, 264), (214, 250), (138, 250)], fill=MAUVE, outline=INK, width=3)   # base
    d.line((142, 254, 210, 254), fill=STONE, width=2)
    d.rectangle((162, 218, 190, 252), fill=MAUVE, outline=INK, width=3)  # short neck
    d.line((167, 224, 167, 248), fill=STONE, width=3)
    d.rectangle((160, 232, 192, 237), fill=PLUM, outline=INK, width=2)   # hinge clip
    for x0 in (30, 298):                                                 # little feet (from the scratch)
        d.rectangle((x0, 220, x0 + 24, 230), fill=PLUM, outline=INK, width=2)
    d.rounded_rectangle((0, 0, 351, 223), radius=14, fill=STONE, outline=INK, width=3)          # bezel
    d.rounded_rectangle((5, 5, 346, 218), radius=10, outline=CREAM, width=2)
    d.line((12, 217, 340, 217), fill=MAUVE, width=3); d.line((345, 14, 345, 212), fill=MAUVE, width=3)
    d.rounded_rectangle((116, 6, 236, 23), radius=4, fill=MAUVE, outline=INK, width=2)          # nameplate
    for (sx, sy) in ((10, 10), (338, 10), (10, 208), (338, 208)):
        d.rectangle((sx, sy, sx + 3, sy + 3), fill=MAUVE, outline=INK)
    d.rectangle((13, 25, 338, 211), outline=INK, width=3)                # screen rim
    d.rectangle((16, 28, 335, 207), fill=CLEAR)                          # screen hole 320x180
    d.ellipse((164, 210, 188, 220), fill=MAUVE, outline=INK, width=2)    # power button
    d.rectangle((196, 212, 201, 217), fill=OK if on else PLUM, outline=INK)   # LED
    return im

monitor(True).save(f"{OUT}/assets/sprites/desk/desk_monitor.png")
monitor(False).save(f"{OUT}/assets/sprites/desk/desk_monitor_off.png")
print("ok")
