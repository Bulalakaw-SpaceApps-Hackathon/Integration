"""Title screen backdrop (SC-01) in feed style: the night-7 meteor shower over the base,
painted at 320x180 and shown at exactly 4x (1280x720), so its pixels match the other screens.
Usage: python3 -I tools/paint_title.py assets/sprites/screens/screen_title.png"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
out = sys.argv[1]
sys.argv = [sys.argv[0], "/tmp", "/tmp/_unused.json"]
open("/tmp/_unused.json", "w").write("{}")
import importlib.util
spec = importlib.util.spec_from_file_location("cards", os.path.join(os.path.dirname(os.path.abspath(__file__)), "paint_night_cards.py"))
src = open(spec.origin).read().split("\nraw = open(MAN)")[0]        # the painting functions only
ns = {"__name__": "cards"}
exec(compile(src, spec.origin, "exec"), ns)
ns["W"], ns["H"] = 320, 180
from PIL import Image
im = ns["n7"](0)
im.resize((1280, 720), Image.NEAREST).save(out)
print("done")
