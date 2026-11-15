"""Crew + Commander portraits remastered from the team's CH- scratch (D64): each 128 px drawing is
reduced to 96 px, flattened to 20 hard-edged colours (no dithering, no soft edges) and given the
game's 1 px ink outline. Frames: 0 happy, 1 worried, 2 neutral (the calm face).
Usage: python3 -I tools/remaster_portraits.py assets/source/scratch-1115/CH- assets/sprites/characters data/assets.json"""
import json, os, sys
from PIL import Image
SRC, OUT, MAN = sys.argv[1], sys.argv[2], sys.argv[3]
INK = (43, 26, 46, 255)

def crisp(im):
    im = im.convert("RGBA").resize((96, 96), Image.LANCZOS)
    a = im.getchannel("A").point(lambda v: 255 if v > 110 else 0)          # hard edge, no halo
    rgb = im.convert("RGB").quantize(colors=20, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    out = rgb.convert("RGBA"); out.putalpha(a)
    px = out.load(); w, h = out.size
    edge = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 255 and ny < h - 1:
                        edge.append((x, y)); break
    for p in edge: px[p] = INK
    return out

raw = open(MAN).read(); man = json.loads(raw)
for who in ("lani", "maya", "mateo", "carlo", "commander"):
    sheet = Image.open(os.path.join(SRC, "portrait_%s.png" % who)).convert("RGBA")
    happy, worried = crisp(sheet.crop((0, 0, 128, 128))), crisp(sheet.crop((128, 0, 256, 128)))
    strip = Image.new("RGBA", (96 * 3, 96), (0, 0, 0, 0))
    for i, f in enumerate((happy, worried, happy)): strip.alpha_composite(f, (i * 96, 0))
    strip.save(os.path.join(OUT, "portrait_%s.png" % who))
    man["portrait_" + who].update({"w": 96, "h": 96, "frames": 3})
open(MAN, "w").write(json.dumps(man, indent="\t", ensure_ascii=False) + ("\n" if raw.endswith("\n") else ""))
print("done")
