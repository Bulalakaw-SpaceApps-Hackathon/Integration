extends SceneTree
## U-01 narrow data contract test. Runtime routing is covered by a playable smoke test.

var failed: int = 0


func _init() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/assets.json"))
	for i in range(16):
		var path: String = "res://data/cutscenes/cs_00_opening.tres" if i == 0 else "res://data/cutscenes/cs_%02d.tres" % i
		var item: CutsceneBeat = load(path) as CutsceneBeat
		_check(item != null, "scene %d loads" % i)
		if item == null:
			continue
		_check(item.panel_count() > 0 and item.panel_assets.size() == item.captions.size() and item.captions.size() == item.panel_durations_sec.size(), "scene %d panel arrays match" % i)
		for asset in item.panel_assets + item.portrait_assets:
			_check(asset == "" or (manifest.has(asset) and FileAccess.file_exists(str(manifest[asset].path))), "scene %d asset %s exists" % [i, asset])
	var beat := load("res://data/cutscenes/cs_00_opening.tres") as CutsceneBeat
	_check(beat != null, "CS-00 resource loads")
	if beat != null:
		_check(beat.id == "CS-00", "CS-00 has the expected id")
		_check(beat.panel_count() == 4, "CS-00 has four complete panels")
		_check(beat.next_route == "night_1_briefing", "CS-00 routes to the Night 1 briefing")
		_check(beat.duration_for(0) >= 0.0, "CS-00 panel timing is data-driven")
	quit(failed)


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: " + label)
	else:
		failed += 1
		push_error("FAIL: " + label)
