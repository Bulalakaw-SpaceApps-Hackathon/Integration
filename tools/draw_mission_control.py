"""Mission Control's portrait (CH-08): a faceless voice (D3), so no person: a headset
microphone in front of Earth with signal rings, map style, 128x128.
Usage: python3 -I tools/draw_mission_control.py assets/sprites/characters/portrait_mission_control.png"""
import sys
from PIL import Image, ImageDraw
def C(h): return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
INK, PLUM, MAUVE, STONE, CREAM, NAVY = C("2b1a2e"), C("684266"), C("9b828b"), C("cbb7b3"), C("eedbc8"), C("2c2450")
BLUE, ICE, GREEN, DGREEN, ORANGE, WHITE = C("5148ab"), C("86bdc8"), C("6fc60c"), C("38a918"), C("ff6d00"), C("fff6ec")
im = Image.new("RGBA", (128, 128), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
d.rounded_rectangle((2, 2, 125, 125), 14, fill=INK); d.rounded_rectangle((4, 4, 123, 123), 12, fill=NAVY)
for r in (54, 44, 34):                                             # signal rings from Earth
    d.arc((64 - r, 70 - r, 64 + r, 70 + r), 200, 340, fill=PLUM if r == 54 else MAUVE, width=2)
d.ellipse((34, 40, 94, 100), fill=INK); d.ellipse((36, 42, 92, 98), fill=BLUE)
for b in ((44, 52, 62, 66), (66, 60, 84, 78), (50, 76, 66, 90)): d.ellipse(b, fill=GREEN)
d.ellipse((46, 54, 58, 62), fill=DGREEN); d.arc((38, 44, 90, 96), 200, 250, fill=ICE, width=2)
d.arc((26, 30, 102, 106), 200, 340, fill=INK, width=6); d.arc((27, 31, 101, 105), 200, 340, fill=STONE, width=3)   # headset band
for x in (24, 92):
    d.rounded_rectangle((x, 66, x + 12, 88), 4, fill=INK); d.rounded_rectangle((x + 2, 68, x + 10, 86), 3, fill=CREAM)
d.line((34, 84, 52, 100), fill=INK, width=4); d.line((34, 84, 52, 100), fill=STONE, width=2)
d.ellipse((50, 96, 60, 106), fill=INK); d.ellipse((52, 98, 58, 104), fill=ORANGE)
d.point((14, 14), fill=WHITE); d.point((110, 20), fill=WHITE); d.point((18, 108), fill=WHITE)
im.save(sys.argv[1]); print("done")
