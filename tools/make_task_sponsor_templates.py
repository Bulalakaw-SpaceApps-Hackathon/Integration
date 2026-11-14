"""Layout templates for the 7 minigames (Tasks) and the 7 sponsors (logo + poster).
Every position here is the one scripts/TaskGame.gd and scripts/hub/HubMap.gd use, so art lines up.

  template_minigames.png          all 7 task play areas (520x230) at 2x, with every code-drawn part marked
  template_minigame_1x.png        520x230 draw-on guide (exact size)
  template_sponsor.png            poster 300x380 at 2x + logo 48x48 at 4x + where both show in the game
  template_sponsor_poster_1x.png  300x380 draw-on guide (exact size)
  template_sponsor_logo_1x.png    48x48 draw-on guide (exact size)

Usage: python3 tools/make_task_sponsor_templates.py <project root>
"""
import sys, os
from PIL import Image, ImageDraw, ImageFont

ROOT = sys.argv[1]
OUT = ROOT + "/assets/templates/"
os.makedirs(OUT, exist_ok=True)
def c(h): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
INK, CREAM, HI, STONE, MAUVE, PLUM = c("2B1A2E"), c("EEDBC8"), c("FFF6EC"), c("CBB7B3"), c("9B828B"), c("684266")
NIGHT, VIOLET, INDIGO, HAZE = c("552465"), c("5E018B"), c("5148AB"), c("86BDC8")
RUST, ORANGE, SAND, WARN, DANGER, OK = c("FD5100"), c("FF6D00"), c("FCA54A"), c("FEE400"), c("EC0500"), c("3DB22B")
SKY, GREEN_WALL, BLUE = c("2A0E3D"), c("1E3B2A"), c("4FA3FF")
F = "/usr/share/fonts/truetype/dejavu/"
fb = ImageFont.truetype(F + "DejaVuSans-Bold.ttf", 15)
fs = ImageFont.truetype(F + "DejaVuSans.ttf", 12)
fxs = ImageFont.truetype(F + "DejaVuSans.ttf", 10)
fbig = ImageFont.truetype(F + "DejaVuSans-Bold.ttf", 22)


def dashed(d, box, col, step=8):
    x0, y0, x1, y1 = box
    for x in range(int(x0), int(x1), step):
        d.line((x, y0, min(x + step // 2, x1), y0), fill=col); d.line((x, y1, min(x + step // 2, x1), y1), fill=col)
    for y in range(int(y0), int(y1), step):
        d.line((x0, y, x0, min(y + step // 2, y1)), fill=col); d.line((x1, y, x1, min(y + step // 2, y1)), fill=col)


def title(d, text, sub, w):
    d.rectangle((0, 0, w, 40), fill=INK)
    d.text((12, 8), text, font=fbig, fill=WARN)
    d.text((12 + d.textlength(text, font=fbig) + 16, 14), sub, font=fs, fill=HI)


# =========================================================================== MINIGAMES
S = 2
PW, PH = 520 * S, 230 * S
NOTE_H = 150
COLS, ROWS = 2, 4
W = COLS * (PW + 30) + 30
H = 60 + ROWS * (PH + NOTE_H + 40)
img = Image.new("RGB", (W, H), CREAM)
d0 = ImageDraw.Draw(img)
title(d0, "MINIGAMES (TASKS) TEMPLATE", "TK-11 to TK-17 · play area 520x230 px, shown here at 2x · dashed = drawn by code on top · numbers are 1x pixels", W)


class P:
    """Draw in 1x task coordinates onto one panel."""
    def __init__(self, ox, oy):
        self.ox, self.oy = ox, oy
        self.d = ImageDraw.Draw(img)

    def r(self, x0, y0, x1, y1):
        return (self.ox + x0 * S, self.oy + y0 * S, self.ox + x1 * S, self.oy + y1 * S)

    def fill(self, box, col, outline=None):
        self.d.rectangle(self.r(*box), fill=col, outline=outline, width=2)

    def code(self, box, label, col=WARN):
        dashed(self.d, self.r(*box), col)
        x0, y0 = self.r(*box)[:2]
        self.d.text((x0 + 4, y0 + 3), label, font=fxs, fill=col)

    def circle(self, cx, cy, rad, label, col=WARN):
        b = self.r(cx - rad, cy - rad, cx + rad, cy + rad)
        self.d.ellipse(b, outline=col, width=2)
        self.d.text((b[0], b[3] + 2), label, font=fxs, fill=col)

    def text(self, x, y, t, col=HI):
        self.d.text((self.ox + x * S, self.oy + y * S), t, font=fxs, fill=col)

    def sky(self, horizon):
        self.fill((0, 0, 520, horizon), SKY)
        self.fill((0, horizon, 520, 230), RUST)
        self.text(440, horizon - 14, "horizon y=%d" % horizon, HAZE)


TASKS = [
    ("TK-11", "PLUG IN THE SOLAR CABLE", "task_loose_cable.png",
     ["Draw: Mars dusk sky + ground, a panel junction box with a round socket.",
      "Separate sprite: the PLUG (84x84, centred, key notch at TOP) - code spins it.",
      "Keep plain: cable lights (left) and 'TAP NOW' text (bottom-right).",
      "The yellow notch on the socket must stay at the top (12 o'clock)."]),
    ("TK-12", "SWEEP THE SOLAR PANEL", "task_panel_dust.png",
     ["Draw: sky + ground, a big blue solar panel with a grid.",
      "Separate sprites: 2-3 dust blobs (~44x44), code places 22 of them.",
      "Keep plain: PANEL POWER bar (top-left) and WIND >>> (top-right).",
      "Dust puffs fly to the RIGHT (Mars wind)."]),
    ("TK-13", "RESTART THE OXYGEN MAKER (MOXIE)", "task_clogged_filter.png",
     ["Draw: machine-room wall, the MOXIE box (NASA's is a gold box),",
      "an empty thermometer, an empty glass oxygen tank, a HEAT button frame.",
      "Code fills: the thermometer (green band = 800 C), the tank, the status light.",
      "HEAT button turns yellow while held: draw it neutral."]),
    ("TK-14", "FIND THE AIRLOCK LEAKS", "task_airlock_leak.png",
     ["Draw: night sky + ground, a round-cornered airlock hatch with a wheel.",
      "Do NOT draw the leaks: code puffs dust at 3 random spots on the hatch EDGE.",
      "Separate sprite: yellow patch sticker 24x24.",
      "Keep plain: LEAKS LEFT (top-left), AIR % (top-right)."]),
    ("TK-15", "SAVE THE WATER", "task_greenhouse_leak.png",
     ["Draw: dark-green greenhouse wall, a pipe across the top, pechay plants in pots.",
      "Separate sprites: cup 48x22 (code slides it), clamp 28x24, water drop 10x14.",
      "The leak can be anywhere x=120-400 on the pipe: keep the pipe plain there.",
      "Keep plain: DROPS SAVED (top-left)."]),
    ("TK-16", "PILE UP THE SHIELDING", "task_shelter_seal.png",
     ["Draw: night sky (space particles rain from the top), ground strip at the bottom.",
      "Separate sprite: regolith sandbag 56x28 (code stacks up to 5 per column).",
      "6 columns, 64 px apart; the SAFE HEIGHT line is code (y=64).",
      "Keep plain: the label (top-left)."]),
    ("TK-17", "TRACK EARTH WITH THE DISH", "task_dish_drift.png",
     ["Draw: starry Mars night sky + horizon. Leave the sky clear for Earth's path.",
      "Separate sprites: Earth + Moon (~16 px), dish (code turns it), crosshair 52x52.",
      "Earth moves along the arc shown, left to right.",
      "Keep plain: SIGNAL bar (top)."]),
]

for i, (aid, name, file, notes) in enumerate(TASKS):
    col_i, row_i = i % COLS, i // COLS
    ox = 30 + col_i * (PW + 30)
    oy = 60 + row_i * (PH + NOTE_H + 40) + 26
    d0.text((ox, oy - 24), "%s  %s   ->  %s" % (aid, name, file), font=fb, fill=INK)
    p = P(ox, oy)
    p.fill((0, 0, 520, 230), INK)
    kind = aid
    if kind == "TK-11":
        p.sky(150)
        for k in range(3):
            p.circle(40, 40 + k * 30, 9, "", OK)
        p.code((30, 28, 120, 130), "cable lights + labels (code)")
        p.fill((190, 45, 330, 185), STONE, INK)
        p.circle(260, 115, 52, "socket r52", INK)
        p.circle(260, 115, 42, "PLUG sprite 84x84 (code spins)", DANGER)
        p.code((251, 52, 269, 68), "notch", WARN)
        p.code((370, 192, 516, 222), "'TAP NOW!' text (code)")
    elif kind == "TK-12":
        p.sky(60)
        p.fill((60, 50, 460, 210), INDIGO, INK)
        p.text(70, 190, "SOLAR PANEL 400x160 at (60,50)")
        p.code((8, 4, 214, 36), "PANEL POWER bar (code)")
        p.code((336, 4, 420, 22), "WIND >>> (code)")
        p.circle(150, 120, 22, "dust blob ~44x44", SAND)
        p.circle(330, 150, 22, "", SAND)
    elif kind == "TK-13":
        p.fill((0, 0, 520, 230), PLUM)
        p.code((36, 30, 76, 210), "thermometer (code fill)")
        p.fill((37, 66, 75, 102), OK)
        p.text(82, 80, "800 C band y=66-102")
        p.fill((160, 60, 280, 160), STONE, INK)
        p.text(190, 105, "MOXIE box", INK)
        p.code((170, 70, 270, 82), "status light (code)", DANGER)
        p.code((300, 60, 340, 160), "O2 tank fill (code)", HAZE)
        p.code((120, 38, 250, 52), "'MARS AIR (CO2) >' (code)")
        p.code((296, 38, 380, 52), "'> OXYGEN' (code)")
        p.fill((360, 150, 500, 210), CREAM, INK)
        p.text(370, 175, "HEAT button 140x60 (tap zone)", INK)
    elif kind == "TK-14":
        p.fill((0, 0, 520, 200), SKY)
        p.fill((0, 200, 520, 230), RUST)
        p.fill((150, 22, 370, 220), MAUVE, INK)
        p.fill((166, 34, 354, 208), STONE, INK)
        p.circle(260, 121, 26, "wheel r26", INK)
        dashed(p.d, p.r(160, 28, 360, 214), DANGER)
        p.text(176, 150, "red dashes = leak zone on the hatch EDGE", DANGER)
        p.code((8, 4, 120, 22), "LEAKS LEFT (code)")
        p.code((386, 4, 470, 22), "AIR % (code)")
        p.code((300, 22, 324, 46), "patch 24x24")
    elif kind == "TK-15":
        p.fill((0, 0, 520, 230), GREEN_WALL)
        p.fill((0, 28, 520, 44), STONE, INK)
        p.text(4, 30, "PIPE y=28-44", INK)
        dashed(p.d, p.r(120, 24, 400, 50), DANGER)
        p.text(200, 52, "leak can be anywhere x=120-400", DANGER)
        p.code((236, 186, 284, 208), "cup 48x22 (code slides x=30-490)", BLUE)
        for k in range(7):
            x = 30 + k * 75
            p.fill((x - 10, 214, x + 10, 230), c("C3002B"))
            p.circle(x, 208, 8, "", OK)
        p.text(330, 196, "pechay pots x=30+75*n", HI)
        p.code((8, 4, 150, 22), "DROPS SAVED (code)")
    elif kind == "TK-16":
        p.sky(220)
        p.d.line(p.r(60, 64, 460, 64), fill=OK, width=2)
        p.text(380, 50, "SAFE HEIGHT y=64 (code)", OK)
        for k in range(6):
            x = 70 + k * 64
            p.code((x, 64, x + 60, 214), "col %d" % (k + 1), SAND)
        p.fill((70, 184, 126, 212), SAND, INK)
        p.text(72, 196, "bag 56x28", INK)
        p.code((8, 4, 330, 22), "label (code)")
    elif kind == "TK-17":
        p.sky(190)
        pts = []
        import math
        for k in range(41):
            u = 0.1 + k * 0.85 / 40
            pts.append(p.r(60 + 400 * u, 150 - 110 * math.sin(u * math.pi), 0, 0)[:2])
        p.d.line(pts, fill=BLUE, width=2)
        p.text(250, 50, "Earth's path (code moves it)", BLUE)
        p.circle(260, 40, 8, "Earth+Moon ~16px", BLUE)
        p.circle(70, 205, 22, "dish (code turns it)", HI)
        p.code((314, 120, 366, 172), "crosshair 52x52")
        p.code((8, 6, 224, 24), "SIGNAL bar (code)")
    for k, n in enumerate(notes):
        d0.text((ox, oy + PH + 8 + k * 16), "- " + n, font=fs, fill=INK)

# legend in the empty 8th slot
ox = 30 + 1 * (PW + 30); oy = 60 + 3 * (PH + NOTE_H + 40) + 26
leg = [("HOW TO USE", None),
       ("1. Draw each background at 520x230 (use template_minigame_1x.png).", None),
       ("2. Draw moving parts (plug, cup, bag, Earth...) as SEPARATE files,", None),
       ("   named task_<problem>_<part>.png, e.g. task_loose_cable_plug.png.", None),
       ("3. Leave the dashed areas plain: the game writes text / bars there.", None),
       ("4. Use the game palette. Keep it bright: these are for kids 7-12.", None),
       ("5. No Among Us look: these are real Mars jobs.", None),
       ("", None),
       ("Dashed yellow = code draws it on top", WARN),
       ("Dashed red = zone where something random appears", DANGER),
       ("Solid shapes = suggested art positions", INK)]
d0.rectangle((ox, oy, ox + PW, oy + PH), fill=HI, outline=INK, width=2)
for k, (t, col) in enumerate(leg):
    d0.text((ox + 16, oy + 14 + k * 22), t, font=fb if k == 0 else fs, fill=col or INK)
img.save(OUT + "template_minigames.png")

one = Image.new("RGBA", (520, 230), (0, 0, 0, 0)); od = ImageDraw.Draw(one)
od.rectangle((0, 0, 519, 229), outline=INK)
for x in range(0, 520, 20): od.line((x, 0, x, 229), fill=STONE + (90,))
for y in range(0, 230, 20): od.line((0, y, 519, y), fill=STONE + (90,))
dashed(od, (0, 0, 230, 36), WARN + (255,))
od.text((4, 4), "top-left: code text / bars", font=fxs, fill=WARN + (255,))
one.save(OUT + "template_minigame_1x.png")


# =========================================================================== SPONSORS
W2, H2 = 1280, 1080
img = Image.new("RGB", (W2, H2), CREAM); d = ImageDraw.Draw(img)
title(d, "SPONSOR TEMPLATE", "SP-11 to SP-17 · 1 poster (300x380) + 1 logo (48x48) · artist letters brand + slogan (like FNAF 6) · made-up brands only", W2)

# poster at 2x
px, py, s2 = 40, 80, 2
d.text((px, py - 26), "POSTER  sponsor_poster_N.png  300x380 (shown 2x)", font=fb, fill=INK)
d.rectangle((px, py, px + 300 * s2, py + 380 * s2), fill=WARN, outline=INK, width=3)
def pr(x0, y0, x1, y1): return (px + x0 * s2, py + y0 * s2, px + x1 * s2, py + y1 * s2)
d.rectangle(pr(18, 18, 282, 62), outline=OK, width=3)
d.text(pr(24, 24, 0, 0)[:2], "BRAND NAME - lettered BY THE ARTIST (big, fun logo-type)", font=fs, fill=INK)
d.rectangle(pr(10, 70, 290, 200), outline=OK, width=3)
d.text(pr(20, 78, 0, 0)[:2], "MASCOT + PRODUCT: big, bold, fun.", font=fb, fill=INK)
d.text(pr(20, 94, 0, 0)[:2], "A silly space/Mars version of the product.", font=fs, fill=INK)
d.text(pr(20, 108, 0, 0)[:2], "Background: sunburst / pattern like FNAF 6.", font=fs, fill=INK)
d.rectangle(pr(10, 206, 290, 292), outline=OK, width=3)
d.text(pr(20, 214, 0, 0)[:2], "SLOGAN - lettered BY THE ARTIST", font=fb, fill=INK)
d.text(pr(20, 230, 0, 0)[:2], "(see the slogan list on the right)", font=fs, fill=INK)
d.rectangle(pr(10, 300, 290, 372), fill=(70, 50, 72))
d.text(pr(16, 306, 0, 0)[:2], "OFFER STRIP - the GAME darkens this area and", font=fs, fill=HI)
d.text(pr(16, 320, 0, 0)[:2], "writes the offer line here (white, 8 px).", font=fs, fill=HI)
d.text(pr(16, 338, 0, 0)[:2], "Art may continue behind it; keep no", font=fs, fill=WARN)
d.text(pr(16, 352, 0, 0)[:2], "important details in y 300-372.", font=fs, fill=WARN)
d.text((px, py + 380 * s2 + 10), "The game puts ACCEPT +3 / NO THANKS buttons UNDER the poster (not on it).", font=fs, fill=INK)
d.text((px, py + 380 * s2 + 28), "Draw everything by hand: no photos, no real people, no real brands.", font=fs, fill=DANGER)

# logo at 4x
lx, ly, s4 = 720, 80, 4
d.text((lx, ly - 26), "LOGO  sponsor_logo_N.png  48x48 (shown 4x)", font=fb, fill=INK)
d.rectangle((lx, ly, lx + 48 * s4, ly + 48 * s4), fill=HI, outline=INK, width=3)
for k in range(0, 49, 8):
    d.line((lx + k * s4, ly, lx + k * s4, ly + 48 * s4), fill=STONE)
    d.line((lx, ly + k * s4, lx + 48 * s4, ly + k * s4), fill=STONE)
d.ellipse((lx + 4 * s4, ly + 4 * s4, lx + 44 * s4, ly + 44 * s4), outline=OK, width=3)
d.text((lx + 4, ly + 48 * s4 + 6), "Keep it inside the green circle: it is a", font=fs, fill=INK)
d.text((lx + 4, ly + 48 * s4 + 22), "round, tappable button. Simple shape +", font=fs, fill=INK)
d.text((lx + 4, ly + 48 * s4 + 38), "1-2 letters max. Thick dark outline.", font=fs, fill=INK)

# where they appear
gx, gy = 720, 420
d.text((gx, gy - 26), "WHERE THE LOGO SHOWS (base map, bottom-right)", font=fb, fill=INK)
mw, mh = 520, 292   # 1280x720 at ~0.406
k = mw / 1280
d.rectangle((gx, gy, gx + mw, gy + mh), fill=ORANGE, outline=INK, width=2)
def mr(x0, y0, x1, y1): return (gx + x0 * k, gy + y0 * k, gx + x1 * k, gy + y1 * k)
d.rectangle(mr(1006, 632, 1274, 704), fill=CREAM, outline=INK, width=2)
d.text(mr(1016, 655, 0, 0)[:2], "START NIGHT", font=fxs, fill=INK)
d.rectangle(mr(1184, 560, 1232, 608), fill=WARN, outline=DANGER, width=2)
d.text(mr(1040, 520, 0, 0)[:2], "logo button 48x48", font=fxs, fill=INK)
d.text(mr(1236, 552, 0, 0)[:2], "OFFER!", font=fxs, fill=INK)
d.text((gx, gy + mh + 8), "Tap the logo -> the poster opens in a popup card (380 wide) with ACCEPT / NO THANKS.", font=fs, fill=INK)
d.text((gx, gy + mh + 24), "Label beside it (code): OFFER! / ON / NO.", font=fs, fill=INK)

import json
slog = json.load(open(ROOT + "/data/night_extras.json"))["slogans"]
rows = [("SP-11", "Cosmo Crunch Cereal", "spare"), ("SP-12", "Rover Racer Sneakers", "Day 2"),
        ("SP-13", "Moon Munch Chips", "Day 3"), ("SP-14", "Orbit Juice Box", "Day 4"),
        ("SP-15", "Stardust Stickers", "Day 5"), ("SP-16", "Zoom Zoom Scooters", "Day 6"),
        ("SP-17", "Planet Puppy Toys", "Day 7")]
ty = gy + mh + 56
d.text((gx, ty), "FILES (N = sponsor number)", font=fb, fill=INK)
for i, (aid, nm, day) in enumerate(rows):
    d.text((gx, ty + 22 + i * 30), "%s  N=%d  %s  (%s)" % (aid, i + 1, nm, day), font=fs, fill=INK)
    d.text((gx + 20, ty + 36 + i * 30), "slogan: \"%s\"" % slog[i], font=fxs, fill=PLUM)
img.save(OUT + "template_sponsor.png")

p1 = Image.new("RGBA", (300, 380), (0, 0, 0, 0)); pd = ImageDraw.Draw(p1)
pd.rectangle((0, 0, 299, 379), outline=INK)
pd.rectangle((18, 18, 282, 62), outline=OK + (255,)); pd.text((22, 22), "BRAND (artist)", font=fxs, fill=OK + (255,))
pd.rectangle((10, 70, 290, 200), outline=OK + (255,)); pd.text((14, 74), "MASCOT + PRODUCT", font=fxs, fill=OK + (255,))
pd.rectangle((10, 206, 290, 292), outline=OK + (255,)); pd.text((14, 210), "SLOGAN (artist)", font=fxs, fill=OK + (255,))
dashed(pd, (10, 300, 290, 372), DANGER + (255,)); pd.text((14, 304), "OFFER STRIP (game darkens + writes)", font=fxs, fill=DANGER + (255,))
p1.save(OUT + "template_sponsor_poster_1x.png")
l1 = Image.new("RGBA", (48, 48), (0, 0, 0, 0)); ld = ImageDraw.Draw(l1)
ld.rectangle((0, 0, 47, 47), outline=INK); ld.ellipse((4, 4, 44, 44), outline=OK + (255,))
l1.save(OUT + "template_sponsor_logo_1x.png")
print("written: template_minigames.png, template_minigame_1x.png, template_sponsor.png, template_sponsor_poster_1x.png, template_sponsor_logo_1x.png")
