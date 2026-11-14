"""DK-09 meter panel: a small desk status display, 192x120, at (16,576). Styled like the clock (dark LCD).
Row 1 (y 8..58): tonight's extra meter -> 48x48 icon at (12,10) + bar at x 68..180, y 18..32 + value text (16 px) at y 38.
Row 2 (y 62..112): food -> icon at (12,62) + 'TOMORROW: 3' text; on dose nights, 4 crew cells in a 2x2 grid
(each 84x24: 24x24 head + 52x8 bar) at x 12/96, y 64/88."""
import sys
from PIL import Image, ImageDraw
OUT = sys.argv[1]
def c(h, a=255): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (a,)
INK, STONE, MAUVE, PLUM, NIGHT = c("2B1A2E"), c("CBB7B3"), c("9B828B"), c("684266"), c("552465")
SHADOW = c("2B1A2E", 110)
W, H = 192, 128
im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
d.ellipse((8, 118, 184, 127), fill=SHADOW)                                         # shadow on desk
for x0 in (18, 156):                                                                # little feet
    d.rectangle((x0, 114, x0 + 18, 121), fill=PLUM, outline=INK, width=2)
d.rounded_rectangle((0, 0, W - 1, 119), radius=8, fill=MAUVE, outline=INK, width=3)  # casing
d.line((6, 4, W - 8, 4), fill=STONE, width=2); d.line((4, 6, 4, 112), fill=STONE, width=2)
d.line((6, 115, W - 6, 115), fill=PLUM, width=2); d.line((W - 5, 6, W - 5, 113), fill=PLUM, width=2)
d.rectangle((7, 7, W - 8, 112), fill=INK)                                           # screen
for y in range(9, 111, 3):                                                          # scanlines like the clock
    d.line((8, y, W - 9, y), fill=c("33203A"))
d.line((12, 60, W - 13, 60), fill=NIGHT)                                            # row divider
im.save(f"{OUT}/assets/sprites/desk/desk_meter_panel.png"); print("ok")
