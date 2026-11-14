"""Turn the Basemap-assets pack sheets into the game's base-map sprites, face-on
(farming-sim front view), grounded, with the pack's white guide lines removed.

Usage: python3 -I pack_to_game.py <pack_dir> <game_hub_dir> <out_dir>
"""
import colorsys, os, sys
from PIL import Image, ImageDraw

PACK, HUB, OUT = sys.argv[1:4]; os.makedirs(OUT, exist_ok=True)
def sheet(n): return Image.open(os.path.join(PACK, n)).convert("RGBA")
def cell(img, r, c, w=64, h=64): return img.crop((c * w, r * h, c * w + w, r * h + h))
def save(im, name): im.save(os.path.join(OUT, name + ".png"))

def scrub_white(im):
    """The pack sheets have 1 px near-white guide lines baked in (cell borders). Find straight
    runs of very light pixels (6+ long, 1 px thin) and replace each with what is beside it."""
    p = im.load(); W, H = im.size
    def light(q): v = p[q]; return v[3] > 0 and min(v[:3]) >= 235
    kill = set()
    for y in range(H):
        x = 0
        while x < W:
            if light((x, y)):
                x1 = x
                while x1 < W and light((x1, y)): x1 += 1
                if x1 - x >= 6 and not any(0 <= y + d < H and light((xx, y + d)) for xx in range(x, x1) for d in (-1, 1)):
                    kill.update((xx, y) for xx in range(x, x1))
                x = x1
            else: x += 1
    for x in range(W):
        y = 0
        while y < H:
            if light((x, y)):
                y1 = y
                while y1 < H and light((x, y1)): y1 += 1
                if y1 - y >= 6 and not any(0 <= x + d < W and light((x + d, yy)) for yy in range(y, y1) for d in (-1, 1)):
                    kill.update((x, yy) for yy in range(y, y1))
                y = y1
            else: y += 1
    for (x, y) in kill:
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            q = (x + dx, y + dy)
            if 0 <= q[0] < W and 0 <= q[1] < H and q not in kill:
                p[x, y] = p[q]; break
        else: p[x, y] = (0, 0, 0, 0)
    return im

def drop_to_floor(im):
    """Move the art down so its lowest pixel sits on the bottom row (the game stands sprites on it)."""
    bb = im.getbbox()
    if not bb: return im
    out = Image.new("RGBA", im.size, (0, 0, 0, 0)); out.alpha_composite(im, (0, im.height - bb[3]))
    return out

def add_front_edge(im, depth=4):
    """For art drawn from straight above: give it a visible front edge so it reads as a low
    platform standing on the ground (farming-sim view) instead of a decal."""
    a = im.getchannel("A"); p = im.load(); W, H = im.size
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0)); o = out.load()
    for x in range(W):
        col = [y for y in range(H) if p[x, y][3] > 0]
        if not col: continue
        yb = max(col)
        r, g, b, _ = p[x, yb]
        for k in range(1, depth + 1):
            if yb + k < H: o[x, yb + k] = ((r + 0x68) // 2 - 10, (g + 0x42) // 2 - 10, (b + 0x66) // 2 - 10, 255)
        if yb + depth + 1 < H: o[x, yb + depth + 1] = (43, 26, 46, 255)
    out.alpha_composite(im)
    return drop_to_floor(out)

# ------------------------------------------------------------------ plot buildings (64x64)
bank1, green, suit, life, solar, ant = (scrub_white(sheet(n)) for n in (
    "plot_battery_bank1.png", "plot_greenhouse.png", "plot_suit_bay.png", "plot_life_support.png",
    "plot_solar.png", "deco_antenna.png"))
shel = scrub_white(sheet("plot_shelter.png"))
PICK = {
    "battery":      [(bank1, 1, 2), (bank1, 2, 2), (bank1, 3, 2)],
    "greenhouse":   [(green, 0, 1), (green, 0, 2), (green, 0, 3)],
    "suit_bay":     [(suit, 1, 2), (suit, 2, 2), (suit, 3, 2)],
    "solar":        [(solar, 2, 1), (solar, 3, 1), (solar, 3, 0)],
    "comms_dish":   [(ant, 0, 0), (ant, 1, 1), (ant, 2, 1)],
    "life_support": [(life, 1, 1), (life, 2, 2), (life, 3, 1)],
}
for pid, picks in PICK.items():
    for lv, (sh, r, c) in enumerate(picks, 1):
        im = cell(sh, r, c)
        im = add_front_edge(im) if pid == "life_support" else drop_to_floor(im)
        save(im, f"plot_{pid}_l{lv}")

# shelter: the armoured dome from the habitat sheet, at half size, with a radiation shield
# bubble that gets stronger each level ("thicker shielding").
def shelter(level):
    dome = scrub_white(sheet("bld_habitat.png")).crop((0, 0, 128, 96)).resize((64, 48), Image.BOX)
    a = dome.getchannel("A").point(lambda v: 255 if v > 110 else 0); dome.putalpha(a)
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    im.alpha_composite(dome, (0, 64 - 48 - 2))
    d = ImageDraw.Draw(im)
    def bag(x, y, w=9, h=5):
        d.ellipse((x, y, x + w, y + h), fill=(43, 26, 46, 255))
        d.ellipse((x + 1, y + 1, x + w - 1, y + h - 1), fill=(150, 64, 40, 255))
        d.line((x + 2, y + 1, x + w - 3, y + 1), fill=(196, 104, 64, 255))
    if level >= 2:                                   # sandbag berm of packed regolith
        for x in range(1, 58, 8): bag(x, 57)
    if level == 3:
        for x in range(5, 54, 8): bag(x, 52)
        for x in (10, 52):                            # shield emitters
            d.rectangle((x - 1, 40, x + 1, 51), fill=(43, 26, 46, 255)); d.point((x, 41), fill=(134, 189, 200, 255))
            d.rectangle((x - 2, 38, x + 2, 40), fill=(134, 189, 200, 255))
    return drop_to_floor(im)
for lv in (1, 2, 3): save(shelter(lv), f"plot_shelter_l{lv}")

# ------------------------------------------------------------------ control room (128x96)
# The front-facing dome, repainted using ONLY the colours of the control-room interior
# (desk_bg.png). Shading keeps its light-to-dark order on the interior's neutral ramp;
# coloured bits (screens, lights, trim) snap to the interior's accent colours.
def H6(h): return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))
# the interior's colours (desk_bg.png), by role
INK_, PLUM_, MAUVE_, STONE_, CREAM_ = H6("2b1a2e"), H6("684266"), H6("9b828b"), H6("cbb7b3"), H6("eedbc8")
VIOLET_, YELLOW_, GREEN_ = H6("5e018b"), H6("fee400"), H6("38a918")
# hull shading bands, matched to how much of each the interior uses (mostly mauve wall)
BANDS = [(0.10, INK_), (0.32, PLUM_), (0.78, MAUVE_), (0.95, STONE_), (1.01, CREAM_)]
def lum(c): return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]
src = scrub_white(sheet("bld_habitat.png")).crop((0, 96, 128, 192))
# face-on: mirror the left half (door, screen, antenna) about the centre line, then cover the
# mirrored second door with the equipment boxes from the original's right side
CX = 64
hab = Image.new("RGBA", (128, 96), (0, 0, 0, 0))
left = src.crop((0, 0, CX, 96))
hab.paste(left, (0, 0)); hab.paste(left.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (CX, 0))
boxes = src.crop((84, 48, 118, 88))
hab.alpha_composite(boxes, (CX + 12, 48))
term = src.crop((60, 60, 76, 92))                       # entry terminal, whole, on the centre line
hab.alpha_composite(term, (CX - 8, 60))
p = hab.load()
pix = [(x, y) for y in range(96) for x in range(128) if p[x, y][3]]
order = sorted(pix, key=lambda q: lum(p[q][:3]))
rank = {q: i / len(order) for i, q in enumerate(order)}
out = {}
for q in pix:
    r, g, b, a = p[q]
    h, l, sa = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    hd = h * 360
    if sa > 0.5 and 0.3 < l < 0.85 and (40 <= hd <= 70 or hd < 20 or hd > 340):
        out[q] = YELLOW_                       # trim, warning lights
    elif sa > 0.45 and 0.25 < l < 0.8 and 80 <= hd <= 160:
        out[q] = GREEN_                        # status lights, screens
    elif sa > 0.45 and 0.25 < l < 0.8 and 170 <= hd <= 290:
        out[q] = VIOLET_                       # glass and blue screens -> the door glass colour
    else:
        out[q] = next(c for t, c in BANDS if rank[q] < t)
for q, c in out.items(): p[q] = c + (255,)
save(drop_to_floor(hab), "bld_habitat")

# ------------------------------------------------------------------ decorations (64x64)
rov = scrub_white(sheet("deco_rover.png"))
save(drop_to_floor(cell(rov, 2, 0)), "deco_rover")       # the face-on dome robot rover
save(drop_to_floor(cell(ant, 2, 0)), "deco_antenna")
r64 = scrub_white(sheet("deco_rocks64pix.png"))
save(drop_to_floor(cell(r64, 1, 0)), "deco_rocks")
flag = scrub_white(sheet("deco_flag2.png"))
save(drop_to_floor(cell(flag, 2, 2)), "deco_flag")

# crates: the pack draws iso cubes; take each cube's front face and shear it flat-on,
# keep a thin lid band on top -> a face-on crate.
crates = scrub_white(sheet("deco_crates.png"))
def face_on_crate(cube):
    """Iso cube -> face-on crate: take the left face, shear its sloped edges level, add a lid band."""
    A = cube.getchannel("A")
    rows = [(y, [x for x in range(64) if A.getpixel((x, y))]) for y in range(64)]
    rows = [(y, xs) for y, xs in rows if xs]
    full = [y for y, xs in rows if min(xs) <= 7 and max(xs) >= 57]
    y_top, y_bot = min(full), max(full)                      # rows where the side faces are full width
    x0 = min(min(xs) for _, xs in rows); mid = 32
    sk = 0.40
    face = cube.crop((x0, 0, mid, 64))
    fw = face.width
    face = face.transform((fw, y_bot - y_top + 4), Image.Transform.AFFINE, (1, 0, 0, sk, 1, y_top), Image.NEAREST)
    face = face.resize((30, 30), Image.NEAREST)
    out = Image.new("RGBA", (30, 34), (0, 0, 0, 0)); d = ImageDraw.Draw(out)
    lid = face.getpixel((15, 3))
    d.rectangle((0, 0, 29, 4), fill=(0x2b, 0x1a, 0x2e, 255))
    d.rectangle((1, 1, 28, 3), fill=tuple(min(255, int(v * 1.2)) for v in lid[:3]) + (255,))
    out.alpha_composite(face, (0, 4))
    return out
def build_store():
    a = face_on_crate(cell(crates, 0, 0)); b = face_on_crate(cell(crates, 1, 2))
    b = b.resize((22, 25), Image.NEAREST)
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    old = Image.open(os.path.join(HUB, "deco_crates.png")).convert("RGBA")
    sign = old.crop((0, 0, 64, 16)); sb = sign.getbbox()
    if sb: sign = sign.crop(sb); im.alpha_composite(sign, ((64 - sign.width) // 2, 8))
    im.alpha_composite(a, (6, 64 - 34)); im.alpha_composite(b, (37, 64 - 25))
    return im
save(build_store(), "deco_crates")

# ------------------------------------------------------------------ pads (64x64): iso diamond -> flat-on
def flat_pad(iso):
    """Map the pad's iso top face (a diamond) onto a rectangle seen from above, then add a
    front edge so it sits on the ground like the buildings."""
    bb = iso.getbbox(); x0, y0, x1, y1 = bb
    A = iso.getchannel("A")
    widths = [(sum(1 for x in range(64) if A.getpixel((x, y))), y) for y in range(64)]
    cy = max(widths)[1]; cx = (x0 + x1) / 2
    W, H = 52, 30
    # inverse map: output (u,v) in [0,1]^2 -> diamond: P = top + u*(right-top) + v*(left-top)
    top, right, left = (cx, y0), (x1, cy), (x0, cy)
    ax, ay = (right[0] - top[0]) / W, (right[1] - top[1]) / W
    bx, by = (left[0] - top[0]) / H, (left[1] - top[1]) / H
    flat = iso.transform((W, H), Image.Transform.AFFINE, (ax, bx, top[0], ay, by, top[1]), Image.NEAREST)
    flat = flat.rotate(0)
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    ox, oy = 6, 64 - H - 6
    d.rectangle((ox, oy + H - 2, ox + W - 1, oy + H + 3), fill=(0x68, 0x42, 0x66, 255))
    d.line((ox, oy + H + 4, ox + W - 1, oy + H + 4), fill=(0x2b, 0x1a, 0x2e, 255))
    im.alpha_composite(flat, (ox, oy))
    return im
save(flat_pad(cell(scrub_white(sheet("plot_empty.png")), 0, 0)), "plot_empty")
locked = flat_pad(cell(scrub_white(sheet("plot_empty.png")), 0, 0)); d = ImageDraw.Draw(locked)
d.rectangle((31, 14, 32, 30), fill=(43, 26, 46, 255))                  # lock sign on a post
d.rounded_rectangle((24, 2, 39, 17), 2, fill=(43, 26, 46, 255))
d.rounded_rectangle((25, 3, 38, 16), 2, fill=(238, 219, 200, 255))
d.arc((28, 5, 35, 13), 180, 360, fill=(43, 26, 46, 255), width=2)
d.rectangle((27, 9, 36, 14), fill=(43, 26, 46, 255)); d.point((31, 11), fill=(238, 219, 200, 255))
save(locked, "plot_locked")

# ------------------------------------------------------------------ ground: tiles + decals
tm = scrub_white(sheet("tiles_mars.png"))
def c32(r, c): return tm.crop((c * 32, r * 32, c * 32 + 32, r * 32 + 32))
# ground: the toned terracotta tiles (draw_ground.py) as the base, the pack's diamond-plate
# walkway laid on top of it
GROUND = Image.open(os.path.join(os.path.dirname(OUT.rstrip("/")), "buildings_out", "tiles_mars.png")).convert("RGBA")
def g32(i): return GROUND.crop((i * 32, 0, i * 32 + 32, 32))
cross = c32(4, 4)
h_arm = cross.crop((3, 0, 7, 32)); v_arm = cross.crop((0, 3, 32, 7))
H_t, V_t, X_t = g32(0).copy(), g32(0).copy(), g32(0).copy()
for k in range(8): H_t.alpha_composite(h_arm, (k * 4, 0)); V_t.alpha_composite(v_arm, (0, k * 4))
X_t.alpha_composite(cross)
atlas = Image.new("RGBA", (128, 128))
for i in range(4): atlas.paste(g32(i), (i * 32, 0)); atlas.paste(g32(i), (i * 32, 32))
for i, t in enumerate((H_t, V_t, X_t, g32(0))): atlas.paste(t, (i * 32, 64)); atlas.paste(t, (i * 32, 96))
save(atlas, "tiles_mars")

# decals: keep only things that lie flat on the ground (craters, cracks, gravel, ripples).
# The cells HubMap.gd scatters that held standing rocks get flat features instead.
dec = tm.copy()
flat_cells = [(2, 4), (2, 5), (2, 6), (0, 3), (1, 3), (0, 1), (1, 1), (0, 2)]
for i, (r, c) in enumerate([(2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2), (3, 3)]):
    fr, fc = flat_cells[i % len(flat_cells)]
    dec.paste(c32(fr, fc), (c * 32, r * 32))
save(dec, "tiles_mars_decals")
print("done")
