"""Side-view Mars rover for the base map: flat, clean style (white body, grey frame,
orange accents, mast camera, RTG at the back, six-wheel rocker-bogie).
4 frames in one row (64x40 each): wheels turn, body rides the suspension.

Usage: python3 -I draw_rover.py <out_png>
"""
import math, sys
from PIL import Image, ImageDraw

INK, PLUM, MAUVE, STONE, CREAM, WHITE = (43, 26, 46), (104, 66, 102), (155, 130, 139), (203, 183, 179), (238, 219, 200), (255, 246, 236)
ORANGE, GOLD, ICE = (255, 109, 0), (252, 165, 74), (134, 189, 200)
W, H, N = 64, 40, 4

def wheel(d, cx, cy, ang):
    d.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=INK)
    d.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=PLUM)
    d.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=STONE)
    for k in range(3):                                     # spokes / tread marks turn each frame
        a = ang + k * 2 * math.pi / 3
        d.point((round(cx + 4.6 * math.cos(a)), round(cy + 4.6 * math.sin(a))), fill=MAUVE)
    d.point((cx, cy), fill=INK)

def frame(i):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    ang = i * math.pi / 6
    bob = 1 if i % 2 else 0
    wy = 33
    wx = (12, 31, 50)
    # rocker-bogie suspension (drawn behind the body)
    pivot = (27, 24 + bob)
    d.line((pivot, (wx[0], wy - 2)), fill=INK, width=2)
    d.line((pivot, (40, 26 + bob)), fill=INK, width=2)
    d.line(((40, 26 + bob), (wx[1], wy - 2)), fill=INK, width=2)
    d.line(((40, 26 + bob), (wx[2], wy - 2)), fill=INK, width=2)
    for p in (pivot, (40, 26 + bob)): d.ellipse((p[0] - 1, p[1] - 1, p[0] + 1, p[1] + 1), fill=GOLD)
    # RTG power unit at the back
    d.polygon([(5, 13 + bob), (14, 15 + bob), (14, 22 + bob), (6, 21 + bob)], fill=MAUVE, outline=INK)
    for y in (16, 18): d.line((7, y + bob, 12, y + 1 + bob), fill=PLUM)
    d.rectangle((3, 12 + bob, 6, 14 + bob), fill=ORANGE, outline=INK)
    # body
    d.rectangle((13, 13 + bob, 49, 24 + bob), fill=INK)
    d.rectangle((14, 14 + bob, 48, 23 + bob), fill=WHITE)
    d.rectangle((14, 14 + bob, 48, 15 + bob), fill=CREAM)          # deck edge
    d.rectangle((14, 21 + bob, 48, 23 + bob), fill=STONE)          # lower panel
    d.line((14, 20 + bob, 48, 20 + bob), fill=ORANGE)              # accent stripe
    for x in (24, 36): d.line((x, 16 + bob, x, 19 + bob), fill=STONE)
    # high-gain antenna dish on the deck
    d.ellipse((18, 8 + bob, 26, 13 + bob), fill=INK); d.ellipse((19, 9 + bob, 25, 12 + bob), fill=CREAM)
    d.line((22, 12 + bob, 22, 13 + bob), fill=INK)
    # mast + camera head
    d.rectangle((38, 3 + bob, 40, 13 + bob), fill=INK); d.line((39, 4 + bob, 39, 12 + bob), fill=STONE)
    d.rectangle((34, 0 + bob, 46, 6 + bob), fill=INK)
    d.rectangle((35, 1 + bob, 45, 5 + bob), fill=WHITE)
    d.rectangle((35, 1 + bob, 37, 5 + bob), fill=ORANGE)
    d.rectangle((41, 2 + bob, 43, 4 + bob), fill=INK); d.point((42, 3 + bob), fill=ICE)
    # robotic arm folded at the front
    d.line((49, 18 + bob, 55, 15 + bob), fill=INK, width=2)
    d.line((55, 15 + bob, 57, 22 + bob), fill=INK, width=2)
    d.rectangle((55, 21 + bob, 59, 25 + bob), fill=INK); d.rectangle((56, 22 + bob, 58, 24 + bob), fill=GOLD)
    for x in wx: wheel(d, x, wy, ang + x)
    return im

sheet = Image.new("RGBA", (W * N, H), (0, 0, 0, 0))
for i in range(N): sheet.alpha_composite(frame(i), (i * W, 0))
sheet.save(sys.argv[1])
print("done")
