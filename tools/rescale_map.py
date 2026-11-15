"""Base map at one pixel size (D49): re-draws every building at 1.5x its old 64 px design
(96x96, Control Room 192x144) so the map can show everything at 2x.

This is not an image upscale: every shape from draw_flat.py / draw_feed_buildings.py is
re-rasterized at the bigger size, so outlines stay 1 px and pixels stay square.
Each building gets 4 frames (D66): its status lights blink in turn.

Usage: python3 -I tools/rescale_map.py assets/sprites/hub data/assets.json
"""
import json, math, os, sys
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
OUT, MANIFEST = sys.argv[1], sys.argv[2]
sys.argv = [sys.argv[0], OUT, OUT]
import draw_flat as F                       # noqa: E402
import draw_feed_buildings as B             # noqa: E402

S = 1.5
FRAMES = 4
FRAME = 0


def _p(v):                                  # a pixel position (centre-preserving)
    return int(math.floor((v + 0.5) * S))


def _lo(v): return int(math.floor(v * S))
def _hi(v): return int(math.ceil((v + 1) * S)) - 1


def _rect(b):
    x0, y0, x1, y1 = b
    return (_lo(x0), _lo(y0), _hi(x1), _hi(y1))


def _pts(xy):
    if isinstance(xy, (list, tuple)) and xy and isinstance(xy[0], (list, tuple)):
        return [(_p(a), _p(b)) for a, b in xy]
    flat = list(xy)
    return [(_p(flat[i]), _p(flat[i + 1])) for i in range(0, len(flat), 2)]


def _w(w): return max(1, int(round(w * S))) if w > 1 else 1


class SD:
    """ImageDraw stand-in that takes the old 64 px coordinates."""
    def __init__(self, im):
        self.raw = ImageDraw.Draw(im)
        self._image = im

    def rectangle(self, b, fill=None, outline=None, width=1):
        self.raw.rectangle(_rect(b), fill=fill, outline=outline, width=width)

    def ellipse(self, b, fill=None, outline=None, width=1):
        self.raw.ellipse(_rect(b), fill=fill, outline=outline, width=width)

    def rounded_rectangle(self, b, radius=0, fill=None, outline=None, width=1):
        self.raw.rounded_rectangle(_rect(b), int(round(radius * S)), fill=fill, outline=outline, width=width)

    def polygon(self, xy, fill=None, outline=None):
        self.raw.polygon(_pts(xy), fill=fill, outline=outline)

    def line(self, xy, fill=None, width=1):
        self.raw.line(_pts(xy), fill=fill, width=_w(width))

    def point(self, xy, fill=None):
        for (x, y) in _pts(xy):
            self.raw.point((x, y), fill=fill)

    def arc(self, b, start, end, fill=None, width=1):
        self.raw.arc(_rect(b), start, end, fill=fill, width=width)

    def pieslice(self, b, start, end, fill=None, outline=None):
        self.raw.pieslice(_rect(b), start, end, fill=fill, outline=outline)


INK, WHITE, DPLUM = F.INK, F.WHITE, F.DPLUM


def canvas(w=64, h=64):
    im = Image.new("RGBA", (int(round(w * S)), int(round(h * S))), F.CLEAR)
    return im, SD(im)


def box(d, b, fill, hi=None, sh=None):
    x0, y0, x1, y1 = _rect(b); r = d.raw
    r.rectangle((x0, y0, x1, y1), fill=INK); r.rectangle((x0 + 1, y0 + 1, x1 - 1, y1 - 1), fill=fill)
    if hi and x1 - x0 > 3: r.line((x0 + 1, y0 + 1, x1 - 2, y0 + 1), fill=hi)
    if sh and y1 - y0 > 3: r.line((x1 - 1, y0 + 2, x1 - 1, y1 - 1), fill=sh); r.line((x0 + 1, y1 - 1, x1 - 1, y1 - 1), fill=sh)


def rbox(d, b, rad, fill, hi=None):
    x0, y0, x1, y1 = _rect(b); r = d.raw; rad = int(round(rad * S))
    r.rounded_rectangle((x0, y0, x1, y1), rad, fill=INK); r.rounded_rectangle((x0 + 1, y0 + 1, x1 - 1, y1 - 1), max(0, rad - 1), fill=fill)
    if hi: r.line((x0 + rad, y0 + 1, x1 - rad, y0 + 1), fill=hi)


def oval(d, b, fill, hi=None):
    x0, y0, x1, y1 = _rect(b); r = d.raw
    r.ellipse((x0, y0, x1, y1), fill=INK); r.ellipse((x0 + 1, y0 + 1, x1 - 1, y1 - 1), fill=fill)
    if hi: r.arc((x0 + 2, y0 + 2, x1 - 2, y1 - 2), 200, 250, fill=hi)


def poly(d, pts, fill): d.raw.polygon(_pts(pts), fill=fill, outline=INK)
def line(d, a, b, w=2): d.raw.line(_pts([a, b]), fill=INK, width=_w(w))


def light(d, x, y, c):
    """A 2 px status light that blinks: each light skips one frame, at its own phase."""
    px, py = _p(x), _p(y)
    on = (FRAME + int(x * 7 + y * 3)) % FRAMES != 0
    d.raw.rectangle((px, py, px + 1, py), fill=INK)
    d.raw.rectangle((px, py - 1, px + 1, py - 1), fill=c if on else DPLUM)


def glass(d, b, tint=F.ICE):
    box(d, b, tint)
    x0, y0, x1, y1 = _rect(b)
    if x1 - x0 > 5 and y1 - y0 > 5: d.raw.line((x0 + 2, y1 - 3, x0 + 4, y0 + 2), fill=WHITE)


for mod in (F, B):
    for name, fn in (("canvas", canvas), ("box", box), ("rbox", rbox), ("oval", oval), ("poly", poly),
                     ("line", line), ("light", light), ("glass", glass)):
        setattr(mod, name, fn)

PLOTS = {"battery": F.battery, "comms_dish": F.comms, "solar": B.solar, "life_support": B.life_support,
         "greenhouse": B.greenhouse, "shelter": B.shelter, "suit_bay": B.suit_bay}


def strip(fn, *args):
    global FRAME
    frames = []
    for FRAME in range(FRAMES):
        F.FRAME = B.FRAME = FRAME
        frames.append(F.floor(fn(*args)))
    w, h = frames[0].size
    out = Image.new("RGBA", (w * FRAMES, h), F.CLEAR)
    for i, f in enumerate(frames):
        out.alpha_composite(f, (i * w, 0))
    return out, w, h


def main():
    raw = open(MANIFEST).read()
    man = json.loads(raw)
    for pid, fn in PLOTS.items():
        for lv in (1, 2, 3):
            im, w, h = strip(fn, lv)
            key = "plot_%s_l%d" % (pid, lv)
            im.save(os.path.join(OUT, key + ".png"))
            man[key].update({"w": w, "h": h, "frames": FRAMES})
    im, w, h = strip(F.habitat)
    im.save(os.path.join(OUT, "bld_habitat.png"))
    man["bld_habitat"].update({"w": w, "h": h, "frames": FRAMES})
    # flat ground pieces have no outlines to keep: a pad is dithered dirt, a highlight is a frame
    for key in ("plot_locked", "plot_empty", "ui_plot_highlight"):
        p = os.path.join(OUT, key + ".png")
        src = Image.open(p).convert("RGBA")
        if src.width == 64:
            src.resize((96, 96), Image.NEAREST).save(p)
            man[key].update({"w": 96, "h": 96})
    open(MANIFEST, "w").write(json.dumps(man, indent="\t" if "\n\t\"" in raw else 1, ensure_ascii=False) + ("\n" if raw.endswith("\n") else ""))
    print("done")


main()
