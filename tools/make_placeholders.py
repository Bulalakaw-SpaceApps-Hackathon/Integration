"""Placeholder art + sound for EVERY asset on the Assets sheet.

Each placeholder has the exact file name, folder, size and frame layout of the final asset,
so an artist's final file replaces it 1:1 (same name, same size) with no code change.
Placeholders are drawn in palette colours with the asset ID written on them.

Also writes data/assets.json (the manifest the game's Assets autoload reads).

Usage:  python3 tools/make_placeholders.py <project root> [--force]
  Existing files are NEVER overwritten unless --force is given (so finals are safe).
"""
import json, math, os, subprocess, sys, wave, struct, random
from PIL import Image, ImageDraw, ImageFont

ROOT = sys.argv[1]
FORCE = "--force" in sys.argv
random.seed(3)

def c(h): return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (255,)
INK, HI, CREAM, STONE, MAUVE, PLUM = c("2B1A2E"), c("FFF6EC"), c("EEDBC8"), c("CBB7B3"), c("9B828B"), c("684266")
HAZE, INDIGO, VIOLET, NIGHT = c("86BDC8"), c("5148AB"), c("5E018B"), c("552465")
SAND, ORANGE, RUST, CRIMSON = c("FCA54A"), c("FF6D00"), c("FD5100"), c("C3002B")
WARN, DANGER, OK = c("FFE600"), c("EC0500"), c("3DB22B")
CREW = {"lani": (c("EF5DC0"), c("B01081")), "maya": (c("A2E69F"), c("57BE6B")),
        "mateo": (c("FF8696"), c("D8305B")), "carlo": (c("A2E747"), c("6FC60C")),
        "commander": (c("FCA54A"), c("FD5100")), "mission_control": (HAZE, INDIGO)}
CLEAR = (0, 0, 0, 0)
FONT = ROOT + "/assets/fonts/Silkscreen-Regular.ttf"
def font(px): return ImageFont.truetype(FONT, px)

MANIFEST = {}   # name (no extension) -> {id, path, w, h, frames, kind}

def path_for(folder, name):
    if folder == "":
        return f"{ROOT}/{name}"
    return f"{ROOT}/assets/{folder}/{name}"

def register(aid, folder, name, w, h, frames=1, kind="image"):
    stem = os.path.splitext(name)[0]
    rel = (f"res://{name}" if folder == "" else f"res://assets/{folder}/{name}")
    MANIFEST[stem] = {"id": aid, "path": rel, "w": w, "h": h, "frames": frames, "kind": kind}

def save(img, aid, folder, name, frames=1):
    register(aid, folder, name, img.width // frames, img.height, frames)
    p = path_for(folder, name)
    if os.path.exists(p) and not FORCE:
        return False
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p)
    return True

# ---------------------------------------------------------------- drawing helpers
def text_fit(d, box, txt, col, max_px=16):
    x0, y0, x1, y1 = box
    for px in (max_px, 8):
        f = font(px)
        lines = txt.split("\n")
        widths = [d.textlength(l, font=f) for l in lines]
        if max(widths) <= (x1 - x0 - 4) and len(lines) * (px + 2) <= (y1 - y0):
            y = (y0 + y1) / 2 - len(lines) * (px + 2) / 2
            for l, wl in zip(lines, widths):
                d.text(((x0 + x1) / 2 - wl / 2, y), l, font=f, fill=col)
                y += px + 2
            return
    # too small for text: just a dot
    d.rectangle(((x0 + x1) // 2 - 1, (y0 + y1) // 2 - 1, (x0 + x1) // 2 + 1, (y0 + y1) // 2 + 1), fill=col)

def box(w, h, fill=STONE, border=INK, label="", lcol=INK, stripes=True):
    img = Image.new("RGBA", (w, h), fill)
    d = ImageDraw.Draw(img)
    if stripes and w > 40 and h > 40:
        for k in range(-h, w, 16):
            d.line((k, h, k + h, 0), fill=tuple(max(0, v - 14) for v in fill[:3]) + (255,), width=4)
    d.rectangle((0, 0, w - 1, h - 1), outline=border, width=2 if min(w, h) > 24 else 1)
    if label:
        text_fit(d, (2, 2, w - 2, h - 2), label, lcol)
    return img

def strip(frames):
    w = sum(f.width for f in frames); h = max(f.height for f in frames)
    out = Image.new("RGBA", (w, h), CLEAR); x = 0
    for f in frames:
        out.alpha_composite(f, (x, 0)); x += f.width
    return out

def astronaut(size, main, shade, sticker="circle", bob=0, step=0, eva=False, facing="down"):
    """A round placeholder astronaut (32x32): helmet, visor, body, sticker shape."""
    img = Image.new("RGBA", (size, size), CLEAR)
    d = ImageDraw.Draw(img)
    s = size / 32
    def R(x0, y0, x1, y1): return (x0 * s, (y0 + bob) * s, x1 * s, (y1 + bob) * s)
    # legs (alternate with step)
    d.rectangle(R(11, 24 + (1 if step % 2 else 0), 14, 30), fill=shade, outline=INK)
    d.rectangle(R(18, 24 + (0 if step % 2 else 1), 21, 30), fill=shade, outline=INK)
    # body
    d.rounded_rectangle(R(8, 15, 24, 26), radius=3 * s, fill=main, outline=INK)
    if eva:
        d.rectangle(R(5, 16, 9, 24), fill=STONE, outline=INK)   # backpack
    # helmet
    d.ellipse(R(7, 2, 25, 18), fill=CREAM if not eva else HI, outline=INK)
    if facing != "up":
        vx = {"down": 0, "left": -3, "right": 3}[facing]
        d.rounded_rectangle(R(11 + vx, 6, 21 + vx, 14), radius=3 * s, fill=INDIGO, outline=INK)
        d.rectangle(R(13 + vx, 7, 15 + vx, 9), fill=HAZE)
    # sticker (shape cue, not colour only) on the helmet side
    sx, sy = 20, 3
    if sticker == "circle":
        d.ellipse(R(sx, sy, sx + 4, sy + 4), fill=main, outline=INK)
    elif sticker == "triangle":
        d.polygon([(p[0] * s, (p[1] + bob) * s) for p in [(sx + 2, sy), (sx + 5, sy + 5), (sx - 1, sy + 5)]], fill=main, outline=INK)
    elif sticker == "plus":
        d.rectangle(R(sx + 1, sy - 1, sx + 3, sy + 5), fill=main); d.rectangle(R(sx - 1, sy + 1, sx + 5, sy + 3), fill=main)
    elif sticker == "square":
        d.rectangle(R(sx, sy, sx + 4, sy + 4), fill=main, outline=INK)
    elif sticker == "star":
        d.polygon([(p[0] * s, (p[1] + bob) * s) for p in [(sx + 2, sy - 1), (sx + 3, sy + 2), (sx + 5, sy + 2), (sx + 3, sy + 4), (sx + 4, sy + 6), (sx + 2, sy + 4), (sx, sy + 6), (sx + 1, sy + 4), (sx - 1, sy + 2), (sx + 1, sy + 2)]], fill=main, outline=INK)
    return img

STICKER = {"lani": "circle", "maya": "triangle", "mateo": "plus", "carlo": "square", "commander": "star", "mission_control": "circle"}

def shape_icon(size, shape, fill, label="", inner=INK):
    img = Image.new("RGBA", (size, size), CLEAR)
    d = ImageDraw.Draw(img)
    m = 3; w = size - 1 - m
    if shape == "circle": d.ellipse((m, m, w, w), fill=fill, outline=INK, width=2)
    elif shape == "triangle": d.polygon([(size / 2, m), (w, w), (m, w)], fill=fill, outline=INK)
    elif shape == "diamond": d.polygon([(size / 2, m), (w, size / 2), (size / 2, w), (m, size / 2)], fill=fill, outline=INK)
    elif shape == "square": d.rectangle((m, m, w, w), fill=fill, outline=INK, width=2)
    elif shape == "hexagon":
        r = size / 2 - m; cx = cy = size / 2
        d.polygon([(cx + r * math.cos(math.pi / 3 * k), cy + r * math.sin(math.pi / 3 * k)) for k in range(6)], fill=fill, outline=INK)
    elif shape == "octagon":
        r = size / 2 - m; cx = cy = size / 2
        d.polygon([(cx + r * math.cos(math.pi / 4 * k + math.pi / 8), cy + r * math.sin(math.pi / 4 * k + math.pi / 8)) for k in range(8)], fill=fill, outline=INK)
    elif shape == "pentagon":
        r = size / 2 - m; cx = cy = size / 2 + 2
        d.polygon([(cx + r * math.cos(2 * math.pi / 5 * k - math.pi / 2), cy + r * math.sin(2 * math.pi / 5 * k - math.pi / 2)) for k in range(5)], fill=fill, outline=INK)
    elif shape == "drop":
        d.ellipse((m + 6, size / 3, w - 6, w), fill=fill, outline=INK); d.polygon([(size / 2, m), (w - 7, size / 2), (m + 7, size / 2)], fill=fill)
    elif shape == "star":
        cx = cy = size / 2; R1 = size / 2 - m; R2 = R1 * 0.45
        d.polygon([(cx + (R1 if k % 2 == 0 else R2) * math.cos(math.pi / 5 * k - math.pi / 2), cy + (R1 if k % 2 == 0 else R2) * math.sin(math.pi / 5 * k - math.pi / 2)) for k in range(10)], fill=fill, outline=INK)
    elif shape == "rounded": d.rounded_rectangle((m, m, w, w), radius=size // 5, fill=fill, outline=INK, width=2)
    if label:
        text_fit(d, (m + 4, m + 4, w - 4, w - 4), label, inner)
    return img

def nine(w, h, fill, border, inner=None):
    img = Image.new("RGBA", (w, h), CLEAR)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=10, fill=border)
    d.rounded_rectangle((3, 3, w - 4, h - 4), radius=8, fill=fill)
    if inner:
        d.rounded_rectangle((6, 6, w - 7, h - 7), radius=6, outline=inner, width=1)
    return img

made = []
def S(img, aid, folder, name, frames=1):
    if save(img, aid, folder, name, frames):
        made.append(name)

# ======================================================================== CHARACTERS
CH = "sprites/characters"
for who in ["lani", "maya", "mateo", "carlo"]:
    m, sh = CREW[who]
    aid = {"lani": "CH-02", "maya": "CH-03", "mateo": "CH-04", "carlo": "CH-05"}[who]
    fr = [astronaut(32, m, sh, STICKER[who], bob=b) for b in (0, 1)] + [astronaut(32, m, sh, STICKER[who], step=k, facing="right") for k in range(4)]
    S(strip(fr), aid, CH, f"crew_{who}.png", 6)
    fr = [astronaut(32, m, sh, STICKER[who], eva=True)] + [astronaut(32, m, sh, STICKER[who], step=k, eva=True, facing="right") for k in range(4)]
    S(strip(fr), "CH-06", CH, f"crew_{who}_eva.png", 5)
m, sh = CREW["commander"]
fr = []
for facing in ["down", "left", "right", "up"]:
    fr += [astronaut(32, m, sh, "star", step=k, facing=facing) for k in range(4)]
S(strip(fr), "CH-01", CH, "char_commander.png", 16)

def portrait(who, worried):
    m, sh = CREW[who]
    img = box(128, 128, NIGHT if not worried else PLUM, INK, stripes=False)
    a = astronaut(32, m, sh, STICKER[who]).resize((96, 96), Image.NEAREST)
    img.alpha_composite(a, (16, 18))
    d = ImageDraw.Draw(img)
    if worried:
        d.text((96, 6), "!", font=font(16), fill=WARN)
    d.text((6, 112), who.upper().replace("_", " ")[:14], font=font(8), fill=HI)
    return img
for who in ["commander", "lani", "maya", "mateo", "carlo"]:
    S(strip([portrait(who, False), portrait(who, True)]), "CH-07", CH, f"portrait_{who}.png", 2)
S(portrait("mission_control", False), "CH-08", CH, "portrait_mission_control.png")
for who in ["lani", "maya", "mateo", "carlo"]:
    m, sh = CREW[who]
    S(astronaut(32, m, sh, STICKER[who]).crop((4, 0, 28, 24)), "CH-09", CH, f"head_{who}.png")

# ======================================================================== CAMERA FEEDS
CF = "sprites/cameras"
def cam(label, sky=NIGHT, ground=RUST, extra=None):
    img = Image.new("RGBA", (320, 180), sky)
    d = ImageDraw.Draw(img)
    if ground:
        d.rectangle((0, 110, 319, 179), fill=ground)
    if extra: extra(d)
    d.rectangle((0, 0, 319, 179), outline=INK, width=2)
    d.rectangle((6, 156, 6 + d.textlength(label, font=font(8)) + 6, 172), fill=INK)
    d.text((9, 159), label, font=font(8), fill=HI)
    return img
def radar(d, glow=False):
    for r in (30, 60, 90): d.ellipse((160 - r, 90 - r, 160 + r, 90 + r), outline=HAZE if glow else INDIGO)
    if glow: d.rectangle((0, 0, 319, 30), fill=WARN)
S(cam("CF-01 SKY RADAR", INK, None, radar), "CF-01", CF, "cam_sky_radar.png")
S(cam("CF-01 SKY RADAR GLOW", PLUM, None, lambda d: radar(d, True)), "CF-01", CF, "cam_sky_radar_glow.png")
def airlock(d, open_):
    d.rectangle((0, 0, 319, 179), fill=STONE); d.rectangle((210, 24, 290, 150), fill=NIGHT if open_ else MAUVE, outline=INK, width=2)
S(cam("CF-02 AIRLOCK", extra=lambda d: airlock(d, False)), "CF-02", CF, "cam_airlock.png")
S(cam("CF-02 AIRLOCK OPEN", extra=lambda d: airlock(d, True)), "CF-02", CF, "cam_airlock_open.png")
def panels(d, dusty):
    for i in range(4):
        d.polygon([(26 + i * 74, 150), (82 + i * 74, 150), (92 + i * 74, 118), (36 + i * 74, 118)], fill=SAND if dusty else INDIGO, outline=INK)
S(cam("CF-03 SOLAR FIELD", extra=lambda d: panels(d, False)), "CF-03", CF, "cam_solar_field.png")
S(cam("CF-03 SOLAR DUSTY", extra=lambda d: panels(d, True)), "CF-03", CF, "cam_solar_field_dusty.png")
def shelter(d, closed):
    d.rectangle((0, 0, 319, 179), fill=PLUM); d.rectangle((16, 16, 303, 150), fill=MAUVE, outline=INK, width=6)
    d.rectangle((230, 40, 290, 150), fill=STONE if closed else NIGHT, outline=INK, width=2)
S(cam("CF-04 SHELTER", extra=lambda d: shelter(d, False)), "CF-04", CF, "cam_shelter.png")
S(cam("CF-04 SHELTER CLOSED", extra=lambda d: shelter(d, True)), "CF-04", CF, "cam_shelter_closed.png")
def fan_room(d, slow):
    d.rectangle((0, 0, 319, 179), fill=STONE); d.ellipse((210, 30, 290, 110), fill=MAUVE, outline=INK, width=2)
    d.line((250, 34, 250, 106), fill=INK, width=4);
    if not slow: d.line((214, 70, 286, 70), fill=INK, width=4)
S(cam("CF-05 LIFE SUPPORT", extra=lambda d: fan_room(d, False)), "CF-05", CF, "cam_life_support.png")
S(cam("CF-05 FAN SLOW", extra=lambda d: fan_room(d, True)), "CF-05", CF, "cam_life_support_slow.png")
def green(d, on):
    d.rectangle((0, 0, 319, 179), fill=c("57BE6B") if on else PLUM)
    if on: d.rectangle((40, 10, 280, 22), fill=WARN)
    for i in range(6): d.rectangle((24 + i * 48, 120, 52 + i * 48, 150), fill=OK, outline=INK)
S(cam("CF-06 GREENHOUSE ON", extra=lambda d: green(d, True)), "CF-06", CF, "cam_greenhouse_on.png")
S(cam("CF-06 GREENHOUSE OFF", extra=lambda d: green(d, False)), "CF-06", CF, "cam_greenhouse_off.png")
S(cam("CF-07 NO SIGNAL", NIGHT, None, lambda d: d.text((112, 82), "NO SIGNAL", font=font(16), fill=MAUVE)), "CF-07", CF, "cam_off.png")
frames = []
for k in range(4):
    f = Image.new("RGBA", (320, 180), CLEAR); fd = ImageDraw.Draw(f)
    for _ in range(500):
        x, y = random.randrange(0, 320, 2), random.randrange(0, 180, 2)
        fd.rectangle((x, y, x + 1, y + 1), fill=random.choice([HI, STONE, MAUVE]))
    frames.append(f)
S(strip(frames), "CF-08", CF, "fx_static.png", 4)
haze = Image.new("RGBA", (320, 180), SAND[:3] + (90,))
S(haze, "CF-09", CF, "fx_dust_haze.png")
S(strip([shape_icon(16, "diamond", WARN), shape_icon(16, "diamond", HI)]), "CF-10", CF, "fx_radar_blip.png", 2)
S(strip([box(160, 200, STONE, INK, f"DOOR\n{k * 33}%") for k in range(4)]), "CF-11", CF, "cam_shelter_door_anim.png", 4)

# camera interaction effects (CF-12..CF-14) + sponsor message art (SP-01)
def spark(k):
    f = Image.new("RGBA", (32, 32), CLEAR); fd = ImageDraw.Draw(f)
    pts = [(16, 2), (20, 12), (30, 10), (22, 18), (28, 30), (16, 22), (4, 30), (10, 18), (2, 10), (12, 12)]
    fd.polygon(pts if k == 0 else [(p[0], 32 - p[1]) for p in pts], fill=WARN if k == 0 else ORANGE, outline=INK)
    return f
S(strip([spark(0), spark(1)]), "CF-12", CF, "fx_fault.png", 2)
S(strip([shape_icon(32, "star", HI), shape_icon(32, "star", HAZE)]), "CF-13", CF, "fx_discovery.png", 2)
def bubble(k):
    f = Image.new("RGBA", (24, 24), CLEAR); fd = ImageDraw.Draw(f)
    fd.rounded_rectangle((1, 1 + k, 22, 18 + k), radius=6, fill=HI, outline=INK); fd.polygon([(6, 18 + k), (10, 18 + k), (4, 23)], fill=HI)
    fd.text((9, 3 + k), "!", font=font(16), fill=DANGER)
    return f
S(strip([bubble(0), bubble(1)]), "CF-14", CF, "fx_request.png", 2)
def mag(k):
    f = Image.new("RGBA", (32, 32), CLEAR); fd = ImageDraw.Draw(f)
    fd.ellipse((3 + k, 3, 21 + k, 21), fill=HAZE, outline=INK, width=3); fd.line((18 + k, 18, 29, 29), fill=INK, width=5)
    return f
S(strip([mag(0), mag(1)]), "CF-15", CF, "fx_clue.png", 2)
for k, col in enumerate([SAND, HAZE, c("EF5DC0")]):
    # clean card: solid colour, thick frame, empty middle (code writes the brand, the tag and the X)
    ad = Image.new("RGBA", (320, 180), col); dd = ImageDraw.Draw(ad)
    dd.rectangle((0, 0, 319, 179), outline=INK, width=4)
    dd.rectangle((8, 8, 311, 171), outline=HI, width=2)
    dd.text((236, 166), "SP-01 #%d" % (k + 1), font=font(8), fill=INK)
    S(ad, "SP-01", CF, "ad_%d.png" % (k + 1))
# SP-02 made-up sponsor logos (one per brand in data/night_extras.json), BT-11 attention badge
brands = json.load(open(f"{ROOT}/data/night_extras.json"))["sponsors"]
for k, brand in enumerate(brands, 1):
    lg = Image.new("RGBA", (48, 48), CLEAR); ld = ImageDraw.Draw(lg)
    col = [SAND, HAZE, c("EF5DC0"), OK, WARN, ORANGE, c("A2E747")][(k - 1) % 7]
    ld.rounded_rectangle((1, 1, 46, 46), radius=12, fill=col, outline=INK, width=3)
    initials = "".join(w[0] for w in brand.split()[:2])
    ld.text((24 - ld.textlength(initials, font=font(16)) / 2, 14), initials, font=font(16), fill=INK)
    S(lg, "SP-02", "sprites/ui", "sponsor_logo_%d.png" % k)
# SP-03 sponsor posters (300x380): no words in the art, code writes brand (top) and offer (bottom)
for k, brand in enumerate(brands, 1):
    col = [SAND, HAZE, c("EF5DC0"), OK, WARN, ORANGE, c("A2E747")][(k - 1) % 7]
    po = Image.new("RGBA", (300, 380), col); pd = ImageDraw.Draw(po)
    pd.rectangle((0, 0, 299, 379), outline=INK, width=6); pd.rectangle((10, 10, 289, 369), outline=HI, width=2)
    pd.rectangle((10, 280, 289, 340), fill=HI)                               # offer text zone
    pd.ellipse((90, 90, 210, 210), fill=HI, outline=INK, width=4)           # mascot / product spot
    pd.text((112, 140), "SP-03", font=font(16), fill=INK)
    S(po, "SP-03", "sprites/ui", "sponsor_poster_%d.png" % k)
def att(k):
    f = Image.new("RGBA", (22, 22), CLEAR); fd = ImageDraw.Draw(f)
    fd.ellipse((1, 1, 20, 20), fill=DANGER if k == 0 else WARN, outline=INK, width=2)
    fd.text((8, 2), "!", font=font(16), fill=HI if k == 0 else INK)
    return f
S(strip([att(0), att(1)]), "BT-11", "sprites/ui", "ui_attention.png", 2)
hp = Image.new("RGBA", (20, 20), CLEAR); hd = ImageDraw.Draw(hp)
hd.ellipse((0, 0, 19, 19), fill=HAZE, outline=INK, width=2)
qb = hd.textbbox((0, 0), "?", font=font(16))
hd.text(((20 - (qb[2] - qb[0])) / 2 - qb[0], (20 - (qb[3] - qb[1])) / 2 - qb[1]), "?", font=font(16), fill=INK)
S(hp, "BT-10", "sprites/ui", "icon_help.png")

# ======================================================================== DESK BUTTONS + UI
UI = "sprites/ui"
S(strip([nine(96, 96, CREAM, INK, STONE), nine(96, 96, WARN, INK, c("C9B500")), nine(96, 96, MAUVE, PLUM)]), "BT-01", UI, "ui_button.png", 3)
CAM_GLYPH = {"sky_radar": ("circle", "SKY"), "airlock": ("square", "AIR\nLOCK"), "solar_field": ("hexagon", "SUN"),
             "shelter": ("pentagon", "SHEL"), "life_support": ("drop", "O2"), "greenhouse": ("triangle", "FOOD")}
for cid, (shape, lab) in CAM_GLYPH.items():
    S(shape_icon(48, shape, HAZE, lab), "BT-02", UI, f"icon_cam_{cid}.png")
for k, lv in enumerate(["low", "mid", "high"]):
    S(shape_icon(48, "drop", [SAND, ORANGE, RUST][k], "I" * (k + 1)), "BT-03", UI, f"icon_heater_{lv}.png")
for k, lv in enumerate(["low", "normal", "high"]):
    S(shape_icon(48, "circle", [STONE, HAZE, INDIGO][k], ["LO", "NO", "HI"][k]), "BT-04", UI, f"icon_life_support_{lv}.png")
S(shape_icon(48, "pentagon", OK, "OPEN"), "BT-05", UI, "icon_shelter_open.png")
S(shape_icon(48, "square", DANGER, "SHUT", HI), "BT-05", UI, "icon_shelter_closed.png")
S(shape_icon(48, "rounded", WARN, "CALL"), "BT-06", UI, "icon_recall.png")
S(shape_icon(48, "triangle", WARN, "ON"), "BT-07", UI, "icon_crop_lamp_on.png")
S(shape_icon(48, "triangle", MAUVE, "OFF"), "BT-07", UI, "icon_crop_lamp_off.png")
for n, (sh, f, l) in {"dish_on": ("circle", OK, "ON"), "dish_off": ("circle", MAUVE, "OFF"), "ask_earth": ("rounded", HAZE, "?"), "send_discovery": ("star", WARN, "!")}.items():
    S(shape_icon(32, sh, f, l), "BT-08", UI, f"icon_{n}.png")
for n, (sh, f, l) in {"pause": ("rounded", CREAM, "II"), "mute_on": ("rounded", MAUVE, "X"), "mute_off": ("rounded", CREAM, "))"),
                      "settings": ("octagon", CREAM, "SET"), "hint": ("circle", SAND, "?")}.items():
    S(shape_icon(48, sh, f, l), "BT-09", UI, f"icon_{n}.png")
ALERT = {"battery": ("circle", OK), "co2": ("hexagon", HAZE), "flare": ("triangle", WARN), "dose": ("diamond", c("A2E747")),
         "dust": ("octagon", SAND), "comms": ("rounded", INDIGO), "cold": ("star", HAZE), "thump": ("square", MAUVE),
         "hungry": ("pentagon", ORANGE), "info": ("drop", CREAM)}
for kind, (shape, fill) in ALERT.items():
    S(shape_icon(48, shape, fill, kind[:3].upper()), "AL-01", UI, f"alert_{kind}.png")
S(nine(64, 64, HI, INK, STONE), "AL-02", UI, "ui_popup.png")
banner = box(400, 60, WARN, INK); ImageDraw.Draw(banner).text((6, 4), "AL-03", font=font(8), fill=INK)
S(banner, "AL-03", UI, "ui_warning_banner.png")
def arrow(dy):
    img = Image.new("RGBA", (64, 64), CLEAR); d = ImageDraw.Draw(img)
    d.polygon([(32, 56 - dy), (8, 28 - dy), (22, 28 - dy), (22, 6 - dy), (42, 6 - dy), (42, 28 - dy), (56, 28 - dy)], fill=WARN, outline=INK)
    return img
S(strip([arrow(0), arrow(4)]), "AL-04", UI, "ui_hint_arrow.png", 2)

# ======================================================================== BASE MAP
HM = "sprites/hub"
tiles = Image.new("RGBA", (128, 128), CLEAR)
td = ImageDraw.Draw(tiles)
for i in range(16):
    x, y = (i % 4) * 32, (i // 4) * 32
    base = [ORANGE, c("F26600"), c("FF7A14"), ORANGE][i % 4] if i < 4 else ORANGE
    td.rectangle((x, y, x + 31, y + 31), fill=base)
    if i < 3:   # ground variants: a few pebbles
        for _ in range(4):
            px, py = x + random.randrange(2, 28), y + random.randrange(2, 28)
            td.rectangle((px, py, px + 1, py + 1), fill=RUST)
    elif i == 3:   # rocks
        td.ellipse((x + 6, y + 10, x + 26, y + 26), fill=CRIMSON, outline=INK)
    elif 4 <= i < 8:  # crater edges N E S W
        side = i - 4
        rect = [(x, y, x + 31, y + 8), (x + 23, y, x + 31, y + 31), (x, y + 23, x + 31, y + 31), (x, y, x + 8, y + 31)][side]
        td.rectangle(rect, fill=RUST)
    elif 8 <= i < 12:  # walkway: horizontal, vertical, cross, end
        k = i - 8
        if k in (0, 2): td.rectangle((x, y + 10, x + 31, y + 21), fill=STONE, outline=MAUVE)
        if k in (1, 2): td.rectangle((x + 10, y, x + 21, y + 31), fill=STONE, outline=MAUVE)
        if k == 3: td.rectangle((x + 8, y + 8, x + 23, y + 23), fill=STONE, outline=MAUVE)
    else:
        td.rectangle((x + 4, y + 4, x + 27, y + 27), fill=SAND)
    if i >= 4:
        td.text((x + 2, y + 22), str(i), font=font(8), fill=INK)
S(tiles, "HM-01", HM, "tiles_mars.png")
def building(w, h, label, fill=CREAM):
    img = Image.new("RGBA", (w, h), CLEAR); d = ImageDraw.Draw(img)
    d.rounded_rectangle((2, h // 4, w - 3, h - 3), radius=10, fill=fill, outline=INK, width=2)
    d.ellipse((w // 4, 2, 3 * w // 4, h // 2 + 6), fill=fill, outline=INK, width=2)
    d.rectangle((w // 2 - 10, h - 30, w // 2 + 10, h - 4), fill=INDIGO, outline=INK)
    d.rectangle((6, h // 4 + 6, w - 7, h // 4 + 12), fill=ORANGE)
    text_fit(d, (6, h // 2 - 6, w - 6, h // 2 + 14), label, INK)
    return img
S(building(128, 96, "HM-02 HAB"), "HM-02", HM, "bld_habitat.png")
PLOT = {"solar": ("HM-03", INDIGO, "SOLAR"), "battery": ("HM-04", OK, "BATT"), "life_support": ("HM-05", HAZE, "AIR"),
        "shelter": ("HM-06", MAUVE, "SHEL"), "suit_bay": ("HM-07", SAND, "SUIT"), "comms_dish": ("HM-08", STONE, "DISH"),
        "greenhouse": ("HM-09", c("57BE6B"), "FOOD")}
for pid, (aid, col, lab) in PLOT.items():
    for lv in (1, 2, 3):
        img = Image.new("RGBA", (64, 64), CLEAR); d = ImageDraw.Draw(img)
        d.rounded_rectangle((2, 2, 61, 61), radius=8, fill=RUST, outline=INK)
        inset = 16 - lv * 4
        d.rounded_rectangle((inset, inset, 63 - inset, 63 - inset), radius=6, fill=col, outline=INK, width=1 + lv)
        text_fit(d, (inset + 2, inset + 2, 61 - inset, 40), lab, INK, 8)
        for k in range(lv):
            d.polygon([(14 + k * 14, 46), (18 + k * 14, 54), (10 + k * 14, 54)], fill=WARN, outline=INK)
        S(img, aid, HM, f"plot_{pid}_l{lv}.png")
S(box(64, 64, PLUM, INK, "LOCK"), "HM-10", HM, "plot_locked.png")
S(box(64, 64, RUST, INK, "EMPTY", stripes=False), "HM-10", HM, "plot_empty.png")
hl = Image.new("RGBA", (64, 64), CLEAR); ImageDraw.Draw(hl).rounded_rectangle((0, 0, 63, 63), radius=8, outline=WARN, width=3)
S(hl, "HM-11", HM, "ui_plot_highlight.png")
S(shape_icon(48, "rounded", WARN, "E"), "HM-11", HM, "ui_prompt_build.png")
for name, (w, h, col) in {"rover": (64, 48, STONE), "antenna": (32, 64, MAUVE), "rocks": (48, 32, CRIMSON)}.items():
    S(box(w, h, col, INK, name.upper()), "HM-12", HM, f"deco_{name}.png")
# Filipino touches: the Philippine flag, a sari-sari supply crate, a parol (Christmas star lantern)
import math
fl = Image.new("RGBA", (32, 48), CLEAR); fd = ImageDraw.Draw(fl)
fd.rectangle((2, 2, 3, 47), fill=INK)
fd.rectangle((4, 4, 31, 11), fill=(0, 56, 168, 255)); fd.rectangle((4, 12, 31, 19), fill=(206, 17, 38, 255))
fd.polygon([(4, 4), (4, 19), (16, 11)], fill=(255, 255, 255, 255)); fd.ellipse((6, 9, 9, 12), fill=(252, 209, 22, 255))
fd.rectangle((4, 4, 31, 19), outline=INK)
S(fl, "HM-12", HM, "deco_flag.png")
cr = box(72, 40, SAND, INK, "SARI-SARI")
S(cr, "HM-12", HM, "deco_crates.png")
pa = Image.new("RGBA", (32, 48), CLEAR); pd = ImageDraw.Draw(pa)
pts = []
for k in range(10):
    r = 14 if k % 2 == 0 else 6
    a = -math.pi / 2 + k * math.pi / 5
    pts.append((16 + r * math.cos(a), 16 + r * math.sin(a)))
pd.polygon(pts, fill=WARN, outline=INK)
pd.ellipse((12, 12, 20, 20), fill=(236, 5, 0, 255), outline=INK)
for x in (11, 16, 21):
    pd.line((x, 28, x + (x - 16) // 2, 46), fill=(236, 5, 0, 255), width=2)
S(pa, "HM-12", HM, "deco_parol.png")
fx = []
for k in range(6):
    f = Image.new("RGBA", (64, 64), CLEAR); fd = ImageDraw.Draw(f)
    r = 6 + k * 5
    for a in range(8):
        ang = a * math.pi / 4
        x, y = 32 + r * math.cos(ang), 32 + r * math.sin(ang)
        fd.rectangle((x - 2, y - 2, x + 2, y + 2), fill=WARN if k < 4 else HI)
    fx.append(f)
S(strip(fx), "HM-13", HM, "fx_upgrade.png", 6)

# ======================================================================== SCREENS
SC = "sprites/screens"
title = Image.new("RGBA", (1280, 720), NIGHT); d = ImageDraw.Draw(title)
d.rectangle((0, 470, 1279, 719), fill=RUST); d.rectangle((0, 520, 1279, 719), fill=ORANGE)
for _ in range(90):
    x, y = random.randrange(0, 1280), random.randrange(0, 440)
    d.rectangle((x, y, x + 1, y + 1), fill=HI)
d.line((980, 90, 760, 260), fill=HI, width=3); d.ellipse((970, 80, 990, 100), fill=WARN)   # the bulalakaw
d.text((20, 690), "SC-01 PLACEHOLDER", font=font(8), fill=INK)
S(title, "SC-01", SC, "screen_title.png")
logo = Image.new("RGBA", (600, 200), CLEAR); d = ImageDraw.Draw(logo)
d.rounded_rectangle((0, 0, 599, 199), radius=24, fill=INK)
d.text((40, 50), "BULALAKAW", font=font(64) if True else font(32), fill=WARN)
d.text((44, 130), "STATION", font=font(32), fill=HAZE)
S(logo, "SC-01", SC, "logo.png")
NIGHT_PIC = {1: (ORANGE, "SUNSET"), 2: (c("57BE6B"), "AIR+FOOD"), 3: (c("A2E747"), "INVISIBLE"), 4: (HAZE, "HELLO EARTH"),
             5: (SAND, "DUST"), 6: (WARN, "FLARE"), 7: (c("EF5DC0"), "FINALE")}
for n, (col, lab) in NIGHT_PIC.items():
    S(box(240, 160, col, INK, f"NIGHT {n}\n{lab}"), "SC-02", SC, f"night_card_{n}.png")
lock = Image.new("RGBA", (240, 160), INK[:3] + (170,)); d = ImageDraw.Draw(lock)
d.rounded_rectangle((100, 60, 140, 100), radius=4, fill=STONE, outline=INK); d.arc((106, 40, 134, 76), 180, 360, fill=STONE, width=5)
S(lock, "SC-02", SC, "night_card_lock.png")
S(nine(96, 96, CREAM, INK, STONE), "SC-03", UI, "ui_briefing.png")
S(nine(96, 96, HI, INK, SAND), "SC-04", UI, "ui_debrief.png")
S(shape_icon(64, "star", MAUVE), "SC-04", UI, "ui_star_empty.png")
S(shape_icon(64, "star", WARN), "SC-04", UI, "ui_star_full.png")
S(shape_icon(64, "hexagon", SAND, "MAT"), "SC-04", UI, "icon_materials.png")
for n, (fill, lab, col) in {"real": (WARN, "* REAL", INK), "simplified": (HAZE, "~ SIMPLE", INK), "live": (OK, "LIVE", HI), "archived": (c("FFB000"), "ARCHIVED", INK)}.items():
    img = Image.new("RGBA", (96, 32), CLEAR); d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, 95, 31), radius=10, fill=fill, outline=INK, width=2)
    text_fit(d, (4, 4, 92, 28), lab, col)
    S(img, "SC-05", UI, f"badge_{n}.png")
CODEX = {"sol": ("circle", ORANGE), "battery_solar": ("hexagon", INDIGO), "dust": ("octagon", SAND), "co2_oxygen": ("drop", HAZE),
         "food": ("triangle", c("57BE6B")), "radiation": ("diamond", c("A2E747")), "solar_flare": ("star", WARN),
         "shelter_shielding": ("pentagon", MAUVE), "comms_delay": ("rounded", STONE)}
for cid, (sh, col) in CODEX.items():
    S(shape_icon(64, sh, col, cid.split("_")[0][:4].upper()), "SC-06", UI, f"codex_{cid}.png")
S(nine(96, 96, INK, HAZE, INDIGO), "SC-07", UI, "ui_nasa_panel.png")
comp = Image.new("RGBA", (1280, 720), INDIGO); d = ImageDraw.Draw(comp)
d.rectangle((0, 560, 1279, 719), fill=ORANGE); d.ellipse((560, 400, 720, 560), fill=WARN)   # sunrise
d.text((20, 690), "SC-08 PLACEHOLDER", font=font(8), fill=INK)
S(comp, "SC-08", SC, "screen_complete.png")
S(nine(96, 96, HI, ORANGE, WARN), "SC-08", UI, "ui_certificate.png")
base = Image.new("RGBA", (128, 128), CLEAR); ImageDraw.Draw(base).ellipse((2, 2, 125, 125), fill=INK[:3] + (120,), outline=HI, width=3)
S(base, "SC-09", UI, "ui_joystick_base.png")
knob = Image.new("RGBA", (64, 64), CLEAR); ImageDraw.Draw(knob).ellipse((2, 2, 61, 61), fill=CREAM, outline=INK, width=3)
S(knob, "SC-09", UI, "ui_joystick_knob.png")
S(nine(96, 96, CREAM, INK, STONE), "SC-12", UI, "ui_panel.png")
for on in (True, False):
    img = Image.new("RGBA", (64, 32), CLEAR); d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, 63, 31), radius=15, fill=OK if on else MAUVE, outline=INK, width=2)
    d.ellipse((34, 3, 60, 28) if on else (3, 3, 29, 28), fill=HI, outline=INK, width=2)
    S(img, "SC-13", UI, "ui_toggle_on.png" if on else "ui_toggle_off.png")
S(nine(96, 96, HI, PLUM, STONE), "SC-14", UI, "ui_codex_page.png")
for n, hand in (("ui_cursor.png", False), ("ui_cursor_hand.png", True)):
    img = Image.new("RGBA", (32, 32), CLEAR); d = ImageDraw.Draw(img)
    if hand: d.rounded_rectangle((8, 2, 22, 28), radius=5, fill=HI, outline=INK, width=2)
    else: d.polygon([(2, 2), (2, 26), (9, 20), (14, 30), (18, 28), (13, 18), (22, 18)], fill=HI, outline=INK)
    S(img, "FD-07", UI, n)

# ======================================================================== BUILDING LESSON PHOTOS (NI-xx)
# One photo slot per lesson: the team puts the suggested NASA image here (public domain, credit NASA).
LES = json.load(open(f"{ROOT}/data/building_lessons.json"))
for pid, lessons in LES.items():
    for k, les in enumerate(lessons, 1):
        img = Image.new("RGBA", (320, 200), NIGHT); d = ImageDraw.Draw(img)
        d.rectangle((0, 0, 319, 199), outline=INK, width=3)
        d.rectangle((10, 10, 309, 150), outline=MAUVE, width=1)
        d.text((16, 16), "NASA PHOTO SLOT", font=font(8), fill=WARN)
        words, line, y = les["image"].upper().split(), "", 34
        for w_ in words:
            if d.textlength(line + w_ + " ", font=font(8)) > 280:
                d.text((16, y), line, font=font(8), fill=HI); y += 12; line = ""
            line += w_ + " "
        d.text((16, y), line, font=font(8), fill=HI)
        d.text((16, 160), "NI: nasa_%s_%d.png 320x200" % (pid, k), font=font(8), fill=STONE)
        S(img, "NI-%s" % pid, "sprites/info", "nasa_%s_%d.png" % (pid, k))

# ======================================================================== ROOT ICONS
icon = Image.new("RGBA", (256, 256), CLEAR); d = ImageDraw.Draw(icon)
d.rounded_rectangle((0, 0, 255, 255), radius=48, fill=NIGHT)
d.line((210, 46, 70, 190), fill=HI, width=12); d.ellipse((190, 26, 230, 66), fill=WARN, outline=INK, width=4)
S(icon, "SB-01", "", "icon.png")
splash = title.copy(); ImageDraw.Draw(splash).text((540, 340), "LOADING...", font=font(32), fill=HI)
S(splash, "SB-02", "", "boot_splash.png")
ico_path = f"{ROOT}/icon.ico"
if FORCE or not os.path.exists(ico_path):
    icon.save(ico_path, sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])
    made.append("icon.ico")
register("FD-05", "", "icon.ico", 256, 256)

# ======================================================================== AUDIO (soft placeholder tones)
SFX = f"{ROOT}/assets/sfx"
os.makedirs(SFX, exist_ok=True)
RATE = 22050
def tone_seq(parts, vol=0.25):
    """parts: list of (freq or 'noise' or 'brown', seconds, fade_out bool)."""
    out = []
    brown = 0.0
    for freq, dur, fade in parts:
        n = int(RATE * dur)
        for i in range(n):
            t = i / RATE
            env = min(1.0, i / (RATE * 0.005)) * ((1 - i / n) if fade else 1.0)
            if freq == "noise":
                v = random.uniform(-1, 1)
            elif freq == "brown":
                brown = max(-1, min(1, brown + random.uniform(-0.05, 0.05))); v = brown
            elif freq == 0:
                v = 0
            else:
                v = math.sin(2 * math.pi * freq * t) * 0.8 + math.sin(4 * math.pi * freq * t) * 0.2
            out.append(v * env * vol)
    return out
def write_ogg(name, samples, aid, loop=False):
    stem = os.path.splitext(name)[0]
    MANIFEST[stem] = {"id": aid, "path": f"res://assets/sfx/{name}", "w": 0, "h": 0, "frames": 1, "kind": "loop" if loop else "sound"}
    p = f"{SFX}/{name}"
    if os.path.exists(p) and not FORCE:
        return
    wav = p[:-4] + ".wav"
    with wave.open(wav, "w") as wf:
        wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(RATE)
        wf.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32000)) for s in samples))
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "3", p], check=True)
    os.remove(wav)
    made.append(name)
write_ogg("sfx_click.ogg", tone_seq([(1100, 0.04, True)], 0.2), "AU-01")
write_ogg("sfx_camera.ogg", tone_seq([(700, 0.05, False), (1000, 0.06, True)], 0.18), "AU-02")
write_ogg("sfx_low_battery.ogg", tone_seq([(520, 0.12, True), (0, 0.06, False), (440, 0.16, True)], 0.2), "AU-03")
write_ogg("sfx_wind_loop.ogg", tone_seq([("brown", 4.0, False)], 0.35), "AU-04", True)
write_ogg("sfx_sunrise.ogg", tone_seq([(523, 0.18, True), (659, 0.18, True), (784, 0.18, True), (1047, 0.45, True)], 0.22), "AU-05")
write_ogg("sfx_evacuate.ogg", tone_seq([(440, 0.3, True), (392, 0.3, True), (349, 0.5, True)], 0.18), "AU-06")
write_ogg("sfx_flare_alarm.ogg", tone_seq([(880, 0.15, True), (0, 0.1, False), (880, 0.15, True)], 0.16), "AU-07")
write_ogg("sfx_door_open.ogg", tone_seq([("noise", 0.5, True)], 0.08), "AU-08")
write_ogg("sfx_door_close.ogg", tone_seq([("noise", 0.6, True), (90, 0.12, True)], 0.09), "AU-08")
write_ogg("sfx_recall.ogg", tone_seq([(1300, 0.06, False), (0, 0.04, False), (1300, 0.06, False), (0, 0.04, False), (1600, 0.1, True)], 0.15), "AU-09")
write_ogg("sfx_msg_sent.ogg", tone_seq([(600, 0.08, False), (900, 0.12, True)], 0.18), "AU-10")
write_ogg("sfx_msg_received.ogg", tone_seq([(900, 0.08, False), (600, 0.08, False), (1200, 0.16, True)], 0.18), "AU-10")
write_ogg("sfx_static_loop.ogg", tone_seq([("noise", 2.0, False)], 0.05), "AU-11", True)
write_ogg("sfx_thump.ogg", tone_seq([(70, 0.25, True)], 0.5), "AU-12")
write_ogg("music_hub.ogg", tone_seq([(262, 1.0, True), (330, 1.0, True), (392, 1.0, True), (330, 1.0, True)] * 2, 0.08), "AU-13", True)
for k in (1, 2, 3):
    write_ogg(f"sfx_step_{k}.ogg", tone_seq([("noise", 0.05, True)], 0.06 + 0.01 * k), "AU-14")
write_ogg("sfx_upgrade.ogg", tone_seq([(400, 0.08, False), (600, 0.08, False), (800, 0.08, False), (1200, 0.25, True)], 0.2), "AU-15")
write_ogg("sfx_star.ogg", tone_seq([(988, 0.1, False), (1319, 0.3, True)], 0.2), "AU-16")
write_ogg("sfx_materials.ogg", tone_seq([(659, 0.08, False), (784, 0.08, False), (988, 0.2, True)], 0.18), "AU-16")
write_ogg("sfx_dose_tick.ogg", tone_seq([("noise", 0.012, True)], 0.25), "AU-17")

# ======================================================================== ALREADY-MADE DESK ART (register only)
DESK = {"desk_bg": "DK-01", "desk_monitor": "DK-02", "desk_monitor_off": "DK-02", "desk_panel_left": "DK-03", "desk_panel_right": "DK-04",
        "desk_sticky_note": "DK-05", "desk_clock": "DK-06", "ui_battery_frame": "DK-07", "ui_battery_fill": "DK-07", "ui_battery_low": "DK-07",
        "ui_forecast_moon": "DK-08", "ui_forecast_sun": "DK-08", "ui_meter_oxygen": "DK-09", "ui_meter_dose": "DK-09", "ui_meter_comms": "DK-09",
        "ui_meter_food": "DK-09", "desk_meter_panel": "DK-09", "desk_prop_fan": "DK-10", "desk_prop_cup": "DK-10"}
for stem, aid in DESK.items():
    p = f"{ROOT}/assets/sprites/desk/{stem}.png"
    im = Image.open(p)
    frames = 2 if stem == "desk_prop_fan" else 1
    register(aid, "sprites/desk", stem + ".png", im.width // frames, im.height, frames)

with open(f"{ROOT}/data/assets.json", "w") as f:
    json.dump(dict(sorted(MANIFEST.items())), f, indent=1)
print(f"manifest: {len(MANIFEST)} files · newly written: {len(made)}")
