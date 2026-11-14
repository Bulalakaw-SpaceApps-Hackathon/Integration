"""DK-05 'sticky note' as a hanging scroll (from the scratch): ceiling strings, rod with end knobs,
paper with a rolled bottom edge, beaded cord. Sprite 212x196, placed at (1058, 2) in the top-right corner.
Title (code) at x 30..182, y 26..42; goal lines at y 48..156 (relative)."""
import sys
from PIL import Image, ImageDraw
OUT = sys.argv[1]
def c(h, a=255): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (a,)
INK, HI, CREAM, STONE, MAUVE, PLUM = c("2B1A2E"), c("FFF6EC"), c("EEDBC8"), c("CBB7B3"), c("9B828B"), c("684266")
WARN, CRIMSON = c("FEE400"), c("C3002B")
SHADOW, CLEAR = c("2B1A2E", 90), (0, 0, 0, 0)
W, H = 212, 196
im = Image.new("RGBA", (W, H), CLEAR); d = ImageDraw.Draw(im)
# strings from the ceiling to the rod ends (angled like the scratch)
d.line((40, 0, 22, 14), fill=INK, width=2); d.line((172, 0, 190, 14), fill=INK, width=2)
# paper drop shadow on the wall
d.rectangle((26, 26, 194, 174), fill=SHADOW)
# paper
d.rectangle((20, 20, 190, 166), fill=CREAM, outline=INK, width=2)
d.line((22, 22, 22, 164), fill=HI)                                          # left edge light
d.rectangle((186, 22, 188, 164), fill=STONE)                                # right edge shade
d.line((30, 44, 182, 44), fill=CRIMSON, width=2)                            # title underline (title written in code)
for y in range(62, 160, 16):                                                # faint ruled lines
    d.line((30, y, 182, y), fill=STONE)
# rolled bottom edge
d.rounded_rectangle((16, 160, 194, 172), radius=6, fill=STONE, outline=INK, width=2)
d.line((22, 163, 188, 163), fill=HI)
# top rod with end knobs
d.rounded_rectangle((10, 12, 202, 24), radius=6, fill=MAUVE, outline=INK, width=2)
d.line((16, 15, 196, 15), fill=STONE, width=2)
for x0 in (2, 196):
    d.rounded_rectangle((x0, 9, x0 + 13, 27), radius=5, fill=PLUM, outline=INK, width=2)
    d.line((x0 + 4, 12, x0 + 4, 24), fill=MAUVE)
# beaded cord + tassel at the bottom centre (from the scratch)
d.line((105, 172, 105, 178), fill=INK, width=2)
for k, y in enumerate((178, 184)):
    d.ellipse((101, y, 109, y + 6), fill=WARN if k == 0 else CRIMSON, outline=INK)
d.polygon([(101, 190), (109, 190), (111, 195), (99, 195)], fill=MAUVE, outline=INK)
im.save(f"{OUT}/assets/sprites/desk/desk_sticky_note.png"); print("ok")
