class_name Strings
extends RefCounted
## All player-facing text lives in res://data/strings_en.json so it can be
## translated later (e.g. Filipino). Usage: Strings.t("alert.flare")

const PATH := "res://data/strings_en.json"
static var _data: Dictionary = {}


static func has(key: String) -> bool:
	t(key)
	return _data.has(key)


static func t(key: String) -> String:
	if _data.is_empty():
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_data = parsed
	return str(_data.get(key, key))
