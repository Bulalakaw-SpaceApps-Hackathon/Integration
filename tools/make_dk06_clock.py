"""DK-06 clock frame (from the scratch: boxy display with a double border). 236x80 at (130,10).
Text is drawn in code with Silkscreen, each line centred horizontally (x = 118) and vertically in its zone:
24-hour time at 32 px bold, centred on y = 29 (zone 12..46); 'NIGHT 1 · POWER' at 16 px, centred on y = 58 (zone 48..68). LCD = ink background, sky-haze text."""
import sys
from PIL import Image, ImageDraw
OUT = sys.argv[1]
def c(h, a=255): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (a,)
INK, HI, STONE, MAUVE, PLUM, NIGHT = c("2B1A2E"), c("FFF6EC"), c("CBB7B3"), c("9B828B"), c("684266"), c("552465")
W, H = 236, 80
im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
d.rounded_rectangle((0, 0, W - 1, H - 1), radius=8, fill=MAUVE, outline=INK, width=3)       # casing
d.line((6, 4, W - 8, 4), fill=STONE, width=2); d.line((4, 6, 4, H - 8), fill=STONE, width=2)  # bevel light
d.line((6, H - 5, W - 6, H - 5), fill=PLUM, width=2); d.line((W - 5, 6, W - 5, H - 6), fill=PLUM, width=2)
d.rectangle((7, 7, W - 8, H - 8), outline=INK, width=2)                                       # double border (scratch)
d.rectangle((11, 11, W - 12, H - 12), fill=INK)                                               # LCD
for y in range(13, H - 12, 3):                                                                # scanlines
    d.line((12, y, W - 13, y), fill=c("33203A"))
d.line((16, 47, W - 17, 47), fill=NIGHT, width=1)                                             # divider
d.line((13, 13, 22, 13), fill=NIGHT); d.line((13, 13, 13, 18), fill=NIGHT)                    # tiny glare
im.save(f"{OUT}/assets/sprites/desk/desk_clock.png"); print("ok")
