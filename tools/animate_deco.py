"""4-frame loops for the base-map decorations (D66): flag flaps, antenna light blinks, parol sways.
Usage: python3 -I tools/animate_deco.py assets/sprites/hub data/assets.json"""
import json, os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
OUT, MAN = sys.argv[1], sys.argv[2]
sys.argv = [sys.argv[0], OUT, OUT]
import draw_flat as F          # noqa: E402

def strip(frames):
    w, h = frames[0].size
    out = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames): out.alpha_composite(f, (i * w, 0))
    return out, w, h

raw = open(MAN).read(); man = json.loads(raw)
for name, fn in (("deco_flag", F.deco_flag), ("deco_antenna", F.deco_antenna)):
    frames = []
    for k in range(4):
        F.FRAME = k
        frames.append(F.floor(fn()))
    im, w, h = strip(frames); im.save(os.path.join(OUT, name + ".png")); man[name].update({"w": w, "h": h, "frames": 4})
p = os.path.join(OUT, "deco_parol.png")
src = Image.open(p).convert("RGBA")
w0 = man["deco_parol"]["w"]; one = src.crop((0, 0, w0, src.height))
frames = []
for dx in (0, 1, 0, -1):                 # the lantern sways on its string
    f = Image.new("RGBA", one.size, (0, 0, 0, 0)); top = one.crop((0, 0, w0, 6)); body = one.crop((0, 6, w0, one.height))
    f.alpha_composite(top, (0, 0)); f.alpha_composite(body, (dx, 6)); frames.append(f)
im, w, h = strip(frames); im.save(p); man["deco_parol"].update({"w": w, "h": h, "frames": 4})
open(MAN, "w").write(json.dumps(man, indent="\t", ensure_ascii=False) + ("\n" if raw.endswith("\n") else ""))
print("done")
