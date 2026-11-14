extends Node
## R-01 Live NASA DONKI fetch for "Tonight's real Sun" (solar flares, last 30 days).
## Rules from the brief: 8 s timeout, team key or DEMO_KEY, 24 h cache in user://,
## LIVE badge only when the data really came from DONKI; otherwise ARCHIVED.
## The nights themselves always use the embedded archive (ArchiveAdapter), never this.

signal updated

const CACHE := "user://donki_cache.json"
const CACHE_HOURS := 24.0
const URL := "https://api.nasa.gov/DONKI/FLR?startDate=%s&endDate=%s&api_key=%s"

var state := "archived"           # "archived" | "loading" | "live"
var flares: Array[Dictionary] = [] # [{date, class}] newest first
var fetched_at := 0.0
var _http: HTTPRequest


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 8.0
	add_child(_http)
	_http.request_completed.connect(_on_done)
	_load_cache()


func is_live() -> bool:
	return state == "live"


func fetch() -> void:
	if state == "loading":
		return
	if state == "live" and Time.get_unix_time_from_system() - fetched_at < CACHE_HOURS * 3600.0:
		return
	var now := Time.get_unix_time_from_system()
	var end := Time.get_date_string_from_unix_time(int(now))
	var start := Time.get_date_string_from_unix_time(int(now - 30 * 86400))
	var key := Progression.api_key if Progression.api_key != "" else "DEMO_KEY"
	state = "loading"
	if _http.request(URL % [start, end, key]) != OK:
		state = "archived"
		updated.emit()


func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		state = "live" if _cache_fresh() else "archived"
		updated.emit()
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not (data is Array):
		state = "archived"
		updated.emit()
		return
	flares.clear()
	for item in data:
		if item is Dictionary:
			flares.append({"date": str(item.get("peakTime", item.get("beginTime", ""))).substr(0, 10),
				"class": str(item.get("classType", "?"))})
	flares.reverse()
	fetched_at = Time.get_unix_time_from_system()
	state = "live"
	var f := FileAccess.open(CACHE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"fetched_at": fetched_at, "flares": flares}))
	updated.emit()


func _load_cache() -> void:
	var f := FileAccess.open(CACHE, FileAccess.READ)
	if f == null:
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		fetched_at = float(d.get("fetched_at", 0.0))
		flares.assign(d.get("flares", []))
		if _cache_fresh():
			state = "live"


func _cache_fresh() -> bool:
	return fetched_at > 0.0 and Time.get_unix_time_from_system() - fetched_at < CACHE_HOURS * 3600.0


## One line for the briefing card / NASA panel.
func summary() -> String:
	if state == "live":
		if flares.is_empty():
			return "NASA DONKI: no solar flares in the last 30 days. A quiet Sun!"
		var biggest: Dictionary = flares[0]
		for fl in flares:
			if _rank(fl["class"]) > _rank(biggest["class"]):
				biggest = fl
		return "NASA DONKI: %d solar flares in the last 30 days. Biggest: %s on %s." % [flares.size(), biggest["class"], biggest["date"]]
	if state == "loading":
		return "Asking NASA DONKI about the Sun..."
	return "Saved NASA data: the X12 flare of 2024-05-20 (no live connection right now)."


func short_status() -> String:
	return {"live": "LIVE NASA DATA", "loading": "CONNECTING TO NASA...", "archived": "ARCHIVED NASA DATA"}[state]


func _rank(cls: String) -> float:
	if cls.length() < 2:
		return 0.0
	var base := {"A": 0.0, "B": 10.0, "C": 20.0, "M": 30.0, "X": 40.0}.get(cls[0], 0.0) as float
	return base + cls.substr(1).to_float()
