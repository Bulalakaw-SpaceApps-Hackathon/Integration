"""Team camera icons (BT-02) -> 48x48 game icons: white background removed, cropped, scaled.
Usage: python3 -I tools/import_cam_icons.py <assets/source dir> <assets/sprites/ui dir>"""
import sys, glob, os
from PIL import Image, ImageDraw
SRC, OUT = sys.argv[1], sys.argv[2]
NAMES = {"icon_cam_sky_radar": "icon_cam_sky_radar", "icon_can_airlock": "icon_cam_airlock",
         "icon_cam_solar_field": "icon_cam_solar_field", "icon_cam_shelter": "icon_cam_shelter",
         "icon_cam_life_support": "icon_cam_life_support", "icon_cam_greenhouse": "icon_cam_greenhouse"}
for src_name, game_name in NAMES.items():
    p = glob.glob(os.path.join(SRC, "**", src_name + ".png"), recursive=True)[0]
    im = Image.open(p).convert("RGBA")
    # flood the white backdrop from every edge pixel that is near-white
    key = (255, 0, 255, 0)
    rgb = im.copy()
    w, h = rgb.size
    for x, y in [(x, 0) for x in range(0, w, 8)] + [(x, h - 1) for x in range(0, w, 8)] + [(0, y) for y in range(0, h, 8)] + [(w - 1, y) for y in range(0, h, 8)]:
        r, g, b, a = rgb.getpixel((x, y))
        if a > 0 and min(r, g, b) > 225:
            ImageDraw.floodfill(rgb, (x, y), key, thresh=40)
    px = rgb.load()
    for yy in range(h):
        for xx in range(w):
            if px[xx, yy] == key: px[xx, yy] = (0, 0, 0, 0)
    bb = rgb.getbbox(); rgb = rgb.crop(bb)
    rgb.thumbnail((46, 46), Image.LANCZOS)
    out = Image.new("RGBA", (48, 48), (0, 0, 0, 0)); out.alpha_composite(rgb, ((48 - rgb.width) // 2, (48 - rgb.height) // 2))
    out.save(os.path.join(OUT, game_name + ".png"))
print("done")
