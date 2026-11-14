"""Layout templates for artists (like desk_layout_template.png), one per art group.
Every position and size here is the one the game code uses, so art drawn on a template lines up.

  template_camera_feed.png        320x180 x4: what code draws on top of each camera feed
  template_camera_feed_1x.png     320x180 draw-on guide (exact size)
  template_hub_map.png            1280x720 1:1: plots, habitat, walkways, decorations, HUD zones
  template_buildings.png          plot sprites (64x64, L1-L3) + habitat + locked/empty + effects
  template_plot_1x.png            64x64 draw-on guide (exact size)
  template_screen_title.png       1280x720 1:1
  template_screen_night_select.png 1280x720 1:1 (+ night card 240x160 detail)
  template_screen_complete.png    1280x720 1:1
  template_ui_frames.png          every 9-slice frame with its border lines, toggles, badges, stars
  template_icons.png              every icon slot: size, file name, required SHAPE

Usage: python3 tools/make_layout_templates.py <project root>
"""
import sys, os, math
from PIL import Image, ImageDraw, ImageFont

ROOT = sys.argv[1]
OUT = ROOT + "/assets/templates/"
os.makedirs(OUT, exist_ok=True)
def c(h): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
INK, CREAM, HI, STONE, MAUVE, PLUM = c("2B1A2E"), c("EEDBC8"), c("FFF6EC"), c("CBB7B3"), c("9B828B"), c("684266")
NIGHT, VIOLET, INDIGO, HAZE = c("552465"), c("5E018B"), c("5148AB"), c("86BDC8")
RUST, ORANGE, SAND, WARN, DANGER, OK = c("FD5100"), c("FF6D00"), c("FCA54A"), c("FEE400"), c("EC0500"), c("3DB22B")
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


def tag(d, box, aid, label, size="", fill=None, col=INK, dash=False):
    x0, y0, x1, y1 = box
    if dash:
        dashed(d, box, col)
    elif fill is not None:
        d.rectangle(box, fill=fill, outline=INK, width=2)
    tx, ty = x0 + 5, y0 + 3
    if aid:
        d.text((tx, ty), aid, font=fb, fill=col); ty += 18
    if label:
        d.text((tx, ty), label, font=fs, fill=col); ty += 15
    if size:
        d.text((tx, ty), size, font=fs, fill=col)


def title(d, text, sub, w=1280):
    d.rectangle((0, 0, w, 40), fill=INK)
    d.text((12, 8), text, font=fbig, fill=WARN)
    d.text((12 + d.textlength(text, font=fbig) + 16, 14), sub, font=fs, fill=HI)


def grid(d, x0, y0, w, h, step, col):
    for x in range(x0, x0 + w + 1, step): d.line((x, y0, x, y0 + h), fill=col)
    for y in range(y0, y0 + h + 1, step): d.line((x0, y, x0 + w, y), fill=col)


# =========================================================================== CAMERA FEED
S = 4
img = Image.new("RGB", (320 * S, 180 * S + 260), INK); d = ImageDraw.Draw(img)
d.rectangle((0, 0, 320 * S - 1, 180 * S - 1), fill=NIGHT)
grid(d, 0, 0, 320 * S - 1, 180 * S - 1, 16 * S, VIOLET)
d.rectangle((0, 110 * S, 320 * S - 1, 180 * S - 1), fill=PLUM)
d.text((10, 110 * S + 6), "FLOOR / GROUND (suggested from y = 110): crew stand here", font=fs, fill=HI)
for k in range(4):   # crew sprite slots (code)
    x = (24 + 60 * k) * S
    tag(d, (x, 112 * S, x + 48 * S, 160 * S), "", "CREW %d (code)" % (k + 1), "48x48 at x=%d, y=112" % (24 + 60 * k), dash=True, col=WARN)
    d.text((x + 4, 102 * S), "name tag y=100-108", font=fxs, fill=WARN)
tag(d, (250 * S, 162 * S, 318 * S, 174 * S), "", "clock text (code)", "", dash=True, col=HI)
tag(d, (196 * S, 10 * S, 300 * S, 22 * S), "", "SHELTER cam only: 'DOOR: OPEN' text", "", dash=True, col=HI)
d.ellipse(((160 - 50) * S, (90 - 50) * S, (160 + 50) * S, (90 + 50) * S), outline=HAZE, width=3)
d.text(((160 - 48) * S, 92 * S), "SKY RADAR only: radar blip circles here (centre 160,90, radius 50)", font=fxs, fill=HAZE)
tag(d, (150 * S, 0, 310 * S, 180 * S - 1), "", "", "", dash=True, col=SAND)
d.text((152 * S + 4, 26 * S), "SHELTER cam only: door anim CF-11 (160x200 at x=150,y=-10)", font=fxs, fill=SAND)
tag(d, (6 * S, 156 * S, 140 * S, 172 * S), "", "SKY RADAR only: 'BLIP = CARLO OUTSIDE' text", "", dash=True, col=HI)
y = 180 * S + 12
notes = [
    "CF-01..CF-07 camera feeds: 320x180 PNG each, NO transparency needed. Drawn 1:1 inside the monitor's screen hole. Template here is 4x.",
    "Keep the dashed zones simple (no important detail): code draws crew sprites, text and effects there.",
    "States (one file each): sky_radar + _glow (flare) · airlock + _open · solar_field + _dusty · shelter (door open) + _closed",
    "life_support + _slow (CO2 night) · greenhouse_on (lamp on) + _off · cam_off (no signal).",
    "Overlays drawn on top by code: fx_static (4 frames 320x180), fx_dust_haze (320x180 semi-transparent), fx_radar_blip (16x16 x2).",
    "Outside cams (solar_field, airlock) show crew in EVA suits; inside cams show normal suits. Leave the floor band readable.",
]
for n in notes:
    d.text((12, y), n, font=fs, fill=HI); y += 20
img.save(OUT + "template_camera_feed.png")
one = Image.new("RGBA", (320, 180), NIGHT + (255,)); d1 = ImageDraw.Draw(one)
d1.rectangle((0, 110, 319, 179), fill=PLUM + (255,))
for k in range(4):
    x = 24 + 60 * k; dashed(d1, (x, 112, x + 48, 160), WARN, 4)
dashed(d1, (250, 162, 318, 174), HI, 4)
one.save(OUT + "template_camera_feed_1x.png")

# =========================================================================== HUB MAP (1:1)
img = Image.new("RGB", (1280, 720), ORANGE); d = ImageDraw.Draw(img)
grid(d, 0, 0, 1280, 720, 32, c("F26600"))
d.rectangle((96, 320, 1184, 351), fill=STONE); d.rectangle((640, 160, 671, 575), fill=STONE)   # walkways (tiles 3..36 row 10, col 20 rows 5..17)
d.text((100, 324), "WALKWAY (tile row 10)", font=fxs, fill=INK); d.text((676, 540), "WALKWAY (tile col 20)", font=fxs, fill=INK)
PLOTS = {"solar": (176, 216), "battery": (336, 216), "life_support": (944, 216), "greenhouse": (1104, 216),
         "shelter": (240, 456), "suit_bay": (640, 488), "comms_dish": (1040, 456)}
IDS = {"solar": "HM-03", "battery": "HM-04", "life_support": "HM-05", "shelter": "HM-06", "suit_bay": "HM-07", "comms_dish": "HM-08", "greenhouse": "HM-09"}
for pid, (x, y) in PLOTS.items():
    tag(d, (x - 32, y - 32, x + 32, y + 32), IDS[pid], pid, fill=CREAM)
    dashed(d, (x - 28, y - 26, x + 28, y + 26), DANGER, 4)
    d.text((x - 60, y + 36), "name label (code)", font=fxs, fill=INK)
    d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=DANGER)
tag(d, (576, 80, 704, 176), "HM-02", "Habitat 128x96", "centre (640,128)", fill=CREAM)
d.text((596, 180), "'CONTROL ROOM' (code)", font=fxs, fill=INK)
DECO = {"rover": (472, 330, 64, 48), "flag": (760, 96, 32, 48), "antenna": (1180, 560, 32, 64), "crates": (400, 600, 48, 40), "rocks": (860, 620, 48, 32)}
for n, (x, y, w, h) in DECO.items():
    tag(d, (x - w // 2, y - h // 2, x + w // 2, y + h // 2), "", "deco_" + n, "", fill=SAND)
d.ellipse((636, 234, 644, 242), fill=INK); d.text((648, 228), "Commander start", font=fxs, fill=INK)
# HUD zones (code UI on top of the map)
tag(d, (8, 8, 700, 80), "", "HUD: night name, materials, food (code)", "", dash=True, col=HI)
tag(d, (860, 8, 1272, 72), "", "HUD: hint, BRIEFING, pause, mute (code)", "", dash=True, col=HI)
tag(d, (1004, 632, 1264, 704), "", "START NIGHT button (code)", "", dash=True, col=HI)
tag(d, (24, 560, 152, 688), "", "Touch joystick", "(touch screens only)", dash=True, col=HI)
d.text((16, 704), "help line (code)", font=fxs, fill=HI)
d.text((330, 640), "HM-01 Mars ground tileset: 32x32 tiles, 4x4 grid in tiles_mars.png. Tiles 0-2 ground variants, 3 rocks,", font=fs, fill=INK)
d.text((330, 656), "4-7 crater edges (N E S W), 8 walkway horizontal, 9 vertical, 10 cross, 11 end, 12-15 spare. Red dot = sprite centre.", font=fs, fill=INK)
d.text((330, 672), "Red dashed box = collision (Commander can't walk through). Map = 40x23 tiles, 1:1 at 1280x720.", font=fs, fill=INK)
img.save(OUT + "template_hub_map.png")

# =========================================================================== BUILDINGS (plots, 2x)
S = 2
img = Image.new("RGB", (1560, 1240), PLUM); d = ImageDraw.Draw(img)
title(d, "BUILDINGS: PLOTS L1 / L2 / L3 (shown 2x)", "64x64 each, transparent PNG, sprite is centred on the plot point")
NAMES = {"solar": "Solar Field: more panels each level", "battery": "Battery Bank: more / bigger cells",
         "life_support": "Life Support: bigger machine + vents", "shelter": "Shelter & Shielding: THICKER walls each level",
         "suit_bay": "Suit Bay: more suit racks", "comms_dish": "Comms Dish: bigger dish", "greenhouse": "Greenhouse: more plants"}
y = 56
for pid in ["solar", "battery", "life_support", "greenhouse", "shelter", "suit_bay", "comms_dish"]:
    d.text((16, y + 40), IDS[pid], font=fb, fill=WARN)
    d.text((16, y + 60), NAMES[pid], font=fs, fill=HI)
    for lv in (1, 2, 3):
        x = 340 + (lv - 1) * 160
        d.rectangle((x, y, x + 128, y + 128), fill=ORANGE, outline=INK, width=2)
        grid(d, x, y, 128, 128, 16, c("F26600"))
        dashed(d, (x + 8, y + 12, x + 120, y + 116), DANGER, 4)
        d.text((x + 4, y + 4), "L%d" % lv, font=fb, fill=INK)
        d.text((x, y + 132), "plot_%s_l%d.png" % (pid, lv), font=fxs, fill=HI)
    y += 160
x0 = 860
tag(d, (x0, 56, x0 + 256, 248), "HM-02", "Habitat / Control Room", "128x96 (shown 2x)", fill=CREAM)
d.text((x0, 252), "bld_habitat.png · door = where you 'Start Night'", font=fxs, fill=HI)
tag(d, (x0, 290, x0 + 128, 418), "HM-10", "locked", "64x64", fill=MAUVE)
tag(d, (x0 + 150, 290, x0 + 278, 418), "HM-10", "empty", "64x64", fill=RUST)
tag(d, (x0, 450, x0 + 128, 578), "HM-11", "highlight", "64x64 ring", dash=True, col=WARN)
tag(d, (x0 + 150, 450, x0 + 246, 546), "HM-11", "'E' prompt", "48x48", fill=WARN)
d.text((x0, 584), "highlight sits on the plot; prompt floats 58 px above it", font=fxs, fill=HI)
for k in range(6):
    tag(d, (x0 + k * 64, 620, x0 + k * 64 + 60, 680), "", "f%d" % k, "", fill=SAND)
d.text((x0, 684), "HM-13 fx_upgrade.png: 6 frames of 64x64 in one row (384x64), 12 fps", font=fxs, fill=HI)
notes = ["Red dashed box = collision (56x52). Anything outside it can overlap the ground.",
         "Each level must LOOK bigger or better than the one before: kids should see their upgrade.",
         "The plot's name label is written by code 36 px below the centre, so keep the bottom edge clean.",
         "Light comes from the top-left; ground shadow to the bottom-right. Palette colours only."]
yy = 740
for n in notes:
    d.text((x0, yy), n, font=fxs, fill=HI); yy += 16
img.save(OUT + "template_buildings.png")
one = Image.new("RGBA", (64, 64), (0, 0, 0, 0)); d1 = ImageDraw.Draw(one)
dashed(d1, (4, 6, 60, 58), DANGER + (255,), 4)
d1.ellipse((30, 30, 33, 33), fill=INK + (255,))
one.save(OUT + "template_plot_1x.png")

# =========================================================================== SCREENS (1:1)
# Title
img = Image.new("RGB", (1280, 720), NIGHT); d = ImageDraw.Draw(img)
d.rectangle((0, 470, 1279, 719), fill=RUST)
tag(d, (340, 60, 940, 260), "SC-01", "logo.png 600x200 (transparent)", "at (340,60)", fill=CREAM)
for i, (t, h) in enumerate([("PLAY / CONTINUE", 64), ("JUDGE MODE", 56), ("CODEX | NASA DATA", 52), ("SETTINGS | CREDITS", 52)]):
    yy = 300 + sum([64, 56, 52, 52][:i]) + i * 10
    tag(d, (490, yy, 790, yy + h), "", t + " (code buttons)", "", dash=True, col=HI)
tag(d, (860, 666, 1270, 704), "", "LIVE / ARCHIVED badge (code)", "", dash=True, col=HI)
tag(d, (16, 690, 500, 712), "", "footer text (code)", "", dash=True, col=HI)
d.text((20, 60), "SC-01 screen_title.png 1280x720", font=fb, fill=WARN)
d.text((20, 80), "Background art. Keep the centre column", font=fs, fill=HI)
d.text((20, 96), "(x 490-790, y 300-540) calm so buttons", font=fs, fill=HI)
d.text((20, 112), "read well. Also used as boot_splash.png.", font=fs, fill=HI)
img.save(OUT + "template_screen_title.png")
# Night select
img = Image.new("RGB", (1280, 720), c("4A4A4A")); d = ImageDraw.Draw(img)
d.text((40, 30), "CHOOSE A NIGHT (code)", font=fbig, fill=HI)
for n in range(7):
    x = 64 + (n % 4) * 264; y = 100 + (n // 4) * 212
    tag(d, (x, y, x + 240, y + 160), "SC-02", "night_card_%d.png" % (n + 1), "240x160", fill=CREAM)
    d.text((x, y + 164), "name (code) y+164", font=fxs, fill=HI)
    d.text((x, y + 180), "stars 24px (code)", font=fxs, fill=HI)
x, y = 64 + 3 * 264, 312
tag(d, (x, y, x + 240, y + 160), "SC-02", "night_card_lock.png", "240x160 OVERLAY (transparent)", fill=MAUVE)
dashed(d, (x, y + 124, x + 240, y + 144), WARN, 4); d.text((x + 6, y + 128), "'LOCKED'/'COMING SOON' text (code)", font=fxs, fill=WARN)
tag(d, (64, 528, 900, 620), "", "night info text (code)", "", dash=True, col=HI)
tag(d, (980, 600, 1220, 664), "", "GO TO BASE (code)", "", dash=True, col=HI)
tag(d, (64, 640, 224, 696), "", "BACK (code)", "", dash=True, col=HI)
d.text((300, 640), "Card pictures: 1 sunset · 2 air+food · 3 invisible energy · 4 hello Earth · 5 dust · 6 flare · 7 finale", font=fs, fill=WARN)
img.save(OUT + "template_screen_night_select.png")
# Mission complete
img = Image.new("RGB", (1280, 720), INDIGO); d = ImageDraw.Draw(img)
d.rectangle((0, 560, 1279, 719), fill=ORANGE)
tag(d, (230, 128, 1050, 508), "SC-08", "ui_certificate.png = 9-slice frame (16 px border)", "stretched to about 820x380; all text is code", fill=HI)
tag(d, (370, 522, 650, 586), "", "SAVE CERTIFICATE (code)", "", dash=True, col=HI)
tag(d, (664, 522, 924, 586), "", "BACK TO TITLE (code)", "", dash=True, col=HI)
d.text((20, 20), "SC-08 screen_complete.png 1280x720 background (sunrise!)", font=fb, fill=WARN)
d.text((20, 40), "The certificate is captured as a PNG when kids press SAVE, so the frame should look nice on its own.", font=fs, fill=HI)
img.save(OUT + "template_screen_complete.png")

# =========================================================================== UI FRAMES (9-slice, 3x)
S = 3
img = Image.new("RGB", (1280, 1560), PLUM); d = ImageDraw.Draw(img)
title(d, "UI FRAMES (9-SLICE), shown 3x", "Corners stay, edges stretch, middle stretches. Lines = border size the code uses.")
FR = [("SC-12", "ui_panel.png", 96, 96, 14, "every panel / card"), ("BT-01", "ui_button.png", 96, 96, 14, "3 frames: normal, pressed/lit, disabled (288x96); small desk buttons use border 8"),
      ("AL-02", "ui_popup.png", 64, 64, 12, "alerts + toasts"), ("SC-03", "ui_briefing.png", 96, 96, 14, "Morning Briefing card"),
      ("SC-04", "ui_debrief.png", 96, 96, 14, "Debrief + guide popups"), ("SC-14", "ui_codex_page.png", 96, 96, 14, "Codex page"),
      ("SC-07", "ui_nasa_panel.png", 96, 96, 12, "NASA Data rows (dark)"), ("SC-08", "ui_certificate.png", 96, 96, 16, "certificate")]
x, y = 20, 60
for aid, name, w, h, m, use in FR:
    if x + w * S > 1260:
        x = 20; y += 96 * S + 70
    d.rectangle((x, y, x + w * S, y + h * S), fill=CREAM, outline=INK, width=2)
    for v in (m, w - m):
        d.line((x + v * S, y, x + v * S, y + h * S), fill=DANGER, width=1)
    for v in (m, h - m):
        d.line((x, y + v * S, x + w * S, y + v * S), fill=DANGER, width=1)
    d.text((x, y + h * S + 4), "%s %s" % (aid, name), font=fb, fill=WARN)
    d.text((x, y + h * S + 22), "%dx%d · border %d px · %s" % (w, h, m, use), font=fxs, fill=HI)
    x += w * S + 40
y += 96 * S + 70
tag(d, (20, y, 20 + 400, y + 60), "AL-03", "ui_warning_banner.png 400x60, border 8 (no text: code writes it)", "", fill=WARN)
tag(d, (440, y, 440 + 64 * S, y + 32 * S), "SC-13", "toggle on / off", "64x32 each", fill=OK)
tag(d, (660, y, 660 + 96 * S, y + 32 * S), "SC-05", "badges 96x32: real, simplified,", "live, archived (text inside the art)", fill=WARN)
y2 = y + 120
tag(d, (20, y2, 20 + 64 * 2, y2 + 64 * 2), "SC-04", "stars", "64x64 empty+full", fill=WARN)
tag(d, (170, y2, 170 + 128, y2 + 128), "SC-09", "joystick base", "128x128", fill=MAUVE)
tag(d, (320, y2, 320 + 64, y2 + 64), "", "knob 64", "", fill=CREAM)
tag(d, (410, y2, 410 + 64 * 2, y2 + 64 * 2), "AL-04", "hint arrow", "64x64 x2 frames", fill=WARN)
tag(d, (560, y2, 560 + 64, y2 + 64), "FD-07", "cursor", "32x32 x2", fill=HI)
d.text((660, y2 + 10), "Text on frames is always written by code in Silkscreen.", font=fs, fill=HI)
d.text((660, y2 + 28), "So: NO words in frames, banners or buttons.", font=fs, fill=HI)
d.text((660, y2 + 46), "Exception: the 4 badges carry their own word", font=fs, fill=HI)
d.text((660, y2 + 64), "(★ / ≈ are not in the font).", font=fs, fill=HI)
img.save(OUT + "template_ui_frames.png")

# =========================================================================== ICONS
img = Image.new("RGB", (1280, 1080), PLUM); d = ImageDraw.Draw(img)
title(d, "ICONS (shown 2x)", "Transparent PNG. Keep a 3 px empty margin. Every alert has its OWN SHAPE (colour-blind rule).")
def shape(d, box, kind, fill):
    x0, y0, x1, y1 = box; cx, cy = (x0 + x1) / 2, (y0 + y1) / 2; r = (x1 - x0) / 2
    pts = None
    if kind == "circle": d.ellipse(box, fill=fill, outline=INK, width=2); return
    if kind == "square": d.rectangle(box, fill=fill, outline=INK, width=2); return
    if kind == "rounded": d.rounded_rectangle(box, radius=r / 2.5, fill=fill, outline=INK, width=2); return
    n = {"triangle": 3, "diamond": 4, "pentagon": 5, "hexagon": 6, "octagon": 8}.get(kind)
    if n:
        off = {3: -math.pi / 2, 4: 0, 5: -math.pi / 2, 6: 0, 8: math.pi / 8}[n]
        pts = [(cx + r * math.cos(2 * math.pi * k / n + off), cy + r * math.sin(2 * math.pi * k / n + off)) for k in range(n)]
    elif kind == "star":
        pts = [(cx + (r if k % 2 == 0 else r * 0.45) * math.cos(math.pi / 5 * k - math.pi / 2), cy + (r if k % 2 == 0 else r * 0.45) * math.sin(math.pi / 5 * k - math.pi / 2)) for k in range(10)]
    elif kind == "drop":
        d.ellipse((x0 + r * 0.3, cy - r * 0.3, x1 - r * 0.3, y1), fill=fill, outline=INK, width=2)
        d.polygon([(cx, y0), (x1 - r * 0.35, cy), (x0 + r * 0.35, cy)], fill=fill); return
    d.polygon(pts, fill=fill, outline=INK)
def slot(x, y, px, aid, file, kind=None, fill=CREAM, note=""):
    s = px * 2
    d.rectangle((x, y, x + s, y + s), fill=c("7A5A78"), outline=INK)
    dashed(d, (x + 6, y + 6, x + s - 6, y + s - 6), MAUVE, 4)
    if kind: shape(d, (x + 8, y + 8, x + s - 8, y + s - 8), kind, fill)
    d.text((x, y + s + 2), file, font=fxs, fill=HI)
    if note: d.text((x, y + s + 14), note, font=fxs, fill=WARN)
y = 56
d.text((16, y), "AL-01 ALERTS 48x48 · alert_<kind>.png · shape is REQUIRED", font=fb, fill=WARN); y += 22
ALERTS = [("battery", "circle", OK), ("co2", "hexagon", HAZE), ("flare", "triangle", WARN), ("dose", "diamond", c("A2E747")), ("dust", "octagon", SAND),
          ("comms", "rounded", INDIGO), ("cold", "star", HAZE), ("thump", "square", MAUVE), ("hungry", "pentagon", ORANGE), ("info", "drop", CREAM)]
for i, (k, sh, col) in enumerate(ALERTS):
    slot(16 + i * 124, y, 48, "AL-01", "alert_%s" % k, sh, col, sh)
y += 96 + 40
d.text((16, y), "BT-02 CAMERA BUTTON ICONS 48x48 · icon_cam_<id>.png · sits top-centre of a 96x96 button, '1 SKY' text under it", font=fb, fill=WARN); y += 22
for i, cid in enumerate(["sky_radar", "airlock", "solar_field", "shelter", "life_support", "greenhouse"]):
    slot(16 + i * 124, y, 48, "BT-02", "icon_cam_" + cid)
y += 96 + 40
d.text((16, y), "DESK CONTROLS 48x48 · the state word is ALSO written by code, so icons can stay simple", font=fb, fill=WARN); y += 22
DESK = ["icon_heater_low", "icon_heater_mid", "icon_heater_high", "icon_life_support_low", "icon_life_support_normal", "icon_life_support_high",
        "icon_shelter_open", "icon_shelter_closed", "icon_recall", "icon_crop_lamp_on"]
for i, f in enumerate(DESK):
    slot(16 + i * 124, y, 48, "", f, note=["heater 1 flame", "2 flames", "3 flames", "", "", "", "BT-05", "", "BT-06", "BT-07 (+_off)"][i])
y += 96 + 40
d.text((16, y), "BT-08 COMMS 32x32 (mini buttons) · BT-09 SYSTEM 48x48 (hint = little Commander helmet)", font=fb, fill=WARN); y += 22
xs = 16
for f in ["icon_dish_on", "icon_dish_off", "icon_ask_earth", "icon_send_discovery"]:
    slot(xs, y, 32, "BT-08", f); xs += 110
for f in ["icon_pause", "icon_mute_on", "icon_mute_off", "icon_settings", "icon_hint"]:
    slot(xs, y, 48, "BT-09", f); xs += 124
y += 96 + 40
d.text((16, y), "SC-06 CODEX 64x64 · codex_<id>.png    SC-04 icon_materials 64x64", font=fb, fill=WARN); y += 22
for i, cid in enumerate(["sol", "battery_solar", "dust", "co2_oxygen", "food", "radiation", "solar_flare", "shelter_shielding", "comms_delay", "materials"]):
    slot(16 + i * 124, y, 48 if False else 48, "", ("codex_" + cid) if cid != "materials" else "icon_materials", note="(64x64 file)")
img.save(OUT + "template_icons.png")
print("templates written to", OUT)
