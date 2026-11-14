extends Node
## One place that knows where every art and sound file lives (data/assets.json, written by
## tools/make_placeholders.py). Code asks by FILE NAME without extension:
##   Assets.tex("crew_lani")        whole texture
##   Assets.frame("crew_lani", 2)   one frame of a sprite sheet (frames are in one row)
##   Assets.sound("sfx_click")      AudioStream
## Swapping art = replacing the PNG/OGG with the same name and size. No code changes.

const MANIFEST := "res://data/assets.json"

var manifest: Dictionary = {}
var _tex: Dictionary = {}
var _frames: Dictionary = {}
var _missing: Dictionary = {}
var _fallback: Texture2D


func _ready() -> void:
	var f := FileAccess.open(MANIFEST, FileAccess.READ)
	if f:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			manifest = parsed
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.MAGENTA)
	_fallback = ImageTexture.create_from_image(img)


func has(asset: String) -> bool:
	return manifest.has(asset)


func info(asset: String) -> Dictionary:
	return manifest.get(asset, {})


func frame_count(asset: String) -> int:
	return int(info(asset).get("frames", 1))


func tex(asset: String) -> Texture2D:
	if _tex.has(asset):
		return _tex[asset]
	var t: Texture2D = null
	var path: String = info(asset).get("path", "")
	if path != "" and ResourceLoader.exists(path):
		t = load(path) as Texture2D
	if t == null:
		if not _missing.has(asset):
			_missing[asset] = true
			push_warning("Missing art: %s (showing a magenta box)" % asset)
		t = _fallback
	_tex[asset] = t
	return t


func frame(asset: String, index: int) -> Texture2D:
	var n := frame_count(asset)
	if n <= 1:
		return tex(asset)
	var key := "%s#%d" % [asset, index % n]
	if _frames.has(key):
		return _frames[key]
	var whole := tex(asset)
	var fw := whole.get_width() / n
	var a := AtlasTexture.new()
	a.atlas = whole
	a.region = Rect2((index % n) * fw, 0, fw, whole.get_height())
	_frames[key] = a
	return a


func sound(asset: String) -> AudioStream:
	var path: String = info(asset).get("path", "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	var s := load(path) as AudioStream
	if s is AudioStreamOggVorbis and info(asset).get("kind", "") == "loop":
		(s as AudioStreamOggVorbis).loop = true
	return s
