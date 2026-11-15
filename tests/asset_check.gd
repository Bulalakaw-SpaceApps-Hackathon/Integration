extends SceneTree
## Every image in data/assets.json loads, and holds as many frames as the manifest says
## (a sheet with fewer frames than listed shows blank frames while it animates).

func _initialize() -> void:
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/assets.json"))
	var bad := 0
	for k in m:
		var v: Dictionary = m[k]
		var path: String = v.get("path", "")
		if not path.ends_with(".png"):
			continue
		var tex: Texture2D = load(path)
		if tex == null:
			print("  FAIL  missing ", k)
			bad += 1
			continue
		var need: int = int(v.w) * int(v.get("frames", 1))
		if tex.get_width() < need or tex.get_height() < int(v.h):
			print("  FAIL  %s is %dx%d, manifest needs %dx%d" % [k, tex.get_width(), tex.get_height(), need, int(v.h)])
			bad += 1
	print("ALL PASSED" if bad == 0 else "%d FAILED" % bad)
	quit()
