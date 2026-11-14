"""DK-10 desk props at real-world scale (redrawn full-res, not upscaled).
desk_prop_fan.png    320x210 sprite sheet: 2 frames of 160x210 (blades turned 45 deg). At (1104,496): front corner of the desk.
desk_prop_cup.png    56x92 striped drink cup. At (1040,612).
(No wall poster or flag: removed at the team.s request.)"""
import sys, math
from PIL import Image, ImageDraw
OUT = sys.argv[1]
def c(h, a=255): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (a,)
INK, HI, CREAM, STONE, MAUVE, PLUM = c("2B1A2E"), c("FFF6EC"), c("EEDBC8"), c("CBB7B3"), c("9B828B"), c("684266")
HAZE, INDIGO, VIOLET, NIGHT = c("86BDC8"), c("5148AB"), c("5E018B"), c("552465")
SAND, ORANGE, RUST, CRIMSON, DANGER_S, WARN = c("FCA54A"), c("FF6D00"), c("FD5100"), c("C3002B"), c("B03228"), c("FEE400")
SHADOW, CLEAR = c("2B1A2E", 110), (0, 0, 0, 0)

# ---------------- fan (160x210 per frame) ----------------
def fan_frame(angle0):
    W, H = 160, 210
    im = Image.new("RGBA", (W, H), CLEAR); d = ImageDraw.Draw(im)
    d.ellipse((22, 190, 138, 209), fill=SHADOW)                                  # shadow on desk
    d.ellipse((30, 176, 130, 202), fill=PLUM, outline=INK, width=3)             # oval foot (scratch)
    d.arc((36, 180, 124, 196), 190, 350, fill=MAUVE, width=3)
    d.rectangle((70, 128, 90, 186), fill=MAUVE, outline=INK, width=3)           # pole
    d.line((76, 132, 76, 182), fill=STONE, width=3)
    d.rectangle((66, 150, 94, 158), fill=PLUM, outline=INK, width=2)           # height-adjust collar
    cx, cy, R = 80, 70, 66
    d.ellipse((cx - R, cy - R, cx + R, cy + R), fill=STONE, outline=INK, width=3)          # cage back ring
    d.ellipse((cx - R + 8, cy - R + 8, cx + R - 8, cy + R - 8), fill=NIGHT)                # dark inside
    for rr in (40, 22):                                                                    # rear grill rings
        d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), outline=VIOLET, width=2)
    for k in range(4):                                                                     # 4 curved blades
        bl = Image.new("RGBA", (W, H), CLEAR); bd = ImageDraw.Draw(bl)
        bd.ellipse((cx + 4, cy - 16, cx + 54, cy + 12), fill=CREAM, outline=INK, width=2)
        bd.arc((cx + 8, cy - 12, cx + 50, cy + 8), 200, 340, fill=HI, width=2)              # blade shine
        bd.line((cx + 12, cy + 6, cx + 46, cy + 4), fill=STONE, width=2)                    # blade shade
        bl = bl.rotate(-(angle0 + k * 90), center=(cx, cy), resample=Image.NEAREST)
        im.alpha_composite(bl)
    d = ImageDraw.Draw(im)
    d.ellipse((cx - 13, cy - 13, cx + 13, cy + 13), fill=MAUVE, outline=INK, width=3)     # hub
    d.ellipse((cx - 6, cy - 8, cx + 2, cy - 2), fill=STONE)
    for k in range(12):                                                                    # front grill spokes
        a = math.radians(k * 30 + 15)
        d.line((cx + 16 * math.cos(a), cy + 16 * math.sin(a), cx + (R - 6) * math.cos(a), cy + (R - 6) * math.sin(a)), fill=MAUVE, width=2)
    d.ellipse((cx - R, cy - R, cx + R, cy + R), outline=INK, width=3)                      # cage rim
    d.ellipse((cx - R + 3, cy - R + 3, cx + R - 3, cy + R - 3), outline=STONE, width=3)
    d.arc((cx - R + 3, cy - R + 3, cx + R - 3, cy + R - 3), 200, 260, fill=HI, width=3)     # rim shine
    d.rectangle((cx - 10, cy + R - 2, cx + 10, cy + R + 8), fill=PLUM, outline=INK, width=2)  # joint to pole
    d.ellipse((cx - 6, cy + R + 14, cx + 6, cy + R + 26), fill=WARN, outline=INK, width=2)   # speed knob
    return im
sheet = Image.new("RGBA", (320, 210), CLEAR)
sheet.alpha_composite(fan_frame(15), (0, 0)); sheet.alpha_composite(fan_frame(60), (160, 0))
sheet.save(f"{OUT}/assets/sprites/desk/desk_prop_fan.png")

# ---------------- striped cup (56x92) ----------------
cup = Image.new("RGBA", (56, 92), CLEAR); d = ImageDraw.Draw(cup)
d.ellipse((4, 82, 52, 91), fill=SHADOW)
d.polygon([(30, 18), (38, 0), (44, 0), (36, 18)], fill=CRIMSON, outline=INK)          # straw
d.polygon([(6, 20), (50, 20), (44, 86), (12, 86)], fill=CREAM, outline=INK, width=2)   # cup body
for y in (30, 46, 62, 76):                                                            # red stripes
    inset = (y - 20) * 6 // 66
    d.rectangle((7 + inset, y, 49 - inset, y + 6), fill=CRIMSON)
    d.line((7 + inset, y + 6, 49 - inset, y + 6), fill=DANGER_S)
d.polygon([(6, 20), (50, 20), (44, 86), (12, 86)], outline=INK, width=2)
d.line((12, 24, 16, 82), fill=HI, width=2)                                             # shine
d.rounded_rectangle((2, 13, 54, 22), radius=3, fill=STONE, outline=INK, width=2)       # lid
d.line((6, 16, 50, 16), fill=HI)
cup.save(f"{OUT}/assets/sprites/desk/desk_prop_cup.png")

print("ok")
