"""DK-03 / DK-04 side consoles, remastered from the scratch (slanted consoles with 3 slots).
Each 160x330, placed at (16,198) [left] and (1104,198) [right]; base sits on the desk lip.
Slots (relative to the sprite): 112x88 at y = 18, 116, 214. Left x = 34..145, right x = 14..125.
Each slot = a 72x60 button area on top + a 100x14 label plate at the bottom (text drawn in code).
Left slot 3 is the comms slot: three 32x32 mini-buttons in a row."""
import sys
from PIL import Image, ImageDraw
OUT = sys.argv[1]
def c(h, a=255): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (a,)
INK, HI, CREAM, STONE, MAUVE, PLUM = c("2B1A2E"), c("FFF6EC"), c("EEDBC8"), c("CBB7B3"), c("9B828B"), c("684266")
NIGHT, OK, WARN = c("552465"), c("38A918"), c("FEE400")
SHADOW, CLEAR = c("2B1A2E", 110), (0, 0, 0, 0)
W, H = 160, 330
SLOT_Y = (18, 116, 214)

def panel(side):
    left = side == "left"
    X = (lambda x: x) if left else (lambda x: W - 1 - x)
    def box(x0, y0, x1, y1): return (min(X(x0), X(x1)), y0, max(X(x0), X(x1)), y1)
    im = Image.new("RGBA", (W, H), CLEAR); d = ImageDraw.Draw(im)
    d.ellipse(box(2, 318, 158, 329), fill=SHADOW)                                   # shadow on desk
    # side face (the slanted depth from the scratch), on the outer side
    d.polygon([(X(2), 30), (X(24), 8), (X(24), 312), (X(2), 320)], fill=PLUM, outline=INK)
    for y in range(60, 300, 40):                                                    # vents on the side
        d.line((X(7), y + 4, X(19), y - 2), fill=NIGHT, width=2)
    # top cap
    d.polygon([(X(24), 8), (X(30), 2), (X(156), 2), (X(156), 8)], fill=STONE, outline=INK)
    # front face
    d.rectangle(box(24, 8, 156, 312), fill=MAUVE, outline=INK, width=3)
    d.line((X(28), 12, X(28), 306), fill=STONE, width=2)                            # bevel light
    d.line((X(28), 12, X(152), 12), fill=STONE, width=2)
    d.line((X(152), 14, X(152), 308), fill=PLUM, width=2)                           # bevel shade
    # plinth on the desk
    d.rectangle(box(0, 310, 159, 322), fill=PLUM, outline=INK, width=3)
    d.line((X(4), 313, X(155), 313), fill=MAUVE)
    # slots
    for k, sy in enumerate(SLOT_Y):
        x0, x1 = (34, 145) if left else (14, 125)        # right slots mirror the left ones
        d.rectangle((x0, sy, x1, sy + 87), fill=PLUM, outline=INK, width=3)         # recess
        d.line((x0 + 3, sy + 3, x1 - 3, sy + 3), fill=NIGHT, width=2)               # inner shadow
        d.rectangle((x0 + 6, sy + 70, x1 - 6, sy + 84), fill=CREAM, outline=INK)    # label plate
        if left and k == 2:                                                         # comms: 3 mini sockets
            for j in range(3):
                bx = x0 + 4 + j * 36
                d.rectangle((bx, sy + 18, bx + 31, sy + 49), fill=NIGHT, outline=INK)
        else:
            d.rectangle((x0 + 20, sy + 7, x1 - 20, sy + 66), fill=NIGHT, outline=INK)  # button socket
    # status lights on the top cap (green = panel powered)
    for j, col in enumerate((OK, WARN)):
        lx = X(140 - j * 12)
        d.rectangle((min(lx, lx + (4 if left else -4)), 3, max(lx, lx + (4 if left else -4)), 6), fill=col)
    for sy in (10, 304):                                                            # screws
        for sxx in (34, 146):
            xx = X(sxx); d.rectangle((min(xx, xx + 3), sy, max(xx, xx + 3), sy + 3), fill=STONE, outline=INK)
    return im

panel("left").save(f"{OUT}/assets/sprites/desk/desk_panel_left.png")
panel("right").save(f"{OUT}/assets/sprites/desk/desk_panel_right.png")
print("ok")
