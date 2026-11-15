extends Node
## Runs the current night: owns one OutpostSim + one NightDirector and ticks
## them. UI scenes read `SimState.sim` and call its action methods.

signal night_started(cfg: NightConfig)
signal night_ended(report: Dictionary)

const NIGHT_PATH := "res://data/nights/night_%d.tres"

var sim: OutpostSim
var director: NightDirector
var config: NightConfig
var running: bool = false
var paused: bool = false
var speed: float = 1.0     # Judge Mode 2x
var frozen: bool = false   # tutorial: the clock stops but buttons still work
var sponsor_tonight: bool = false
var tutorial_tonight: bool = false
var _extras: Dictionary = {}


var _story: Dictionary = {}

## data/story.json: one story beat per night (Malfunction, Challenge, Problems, radio, lines).
func story_beat(night_id: int) -> Dictionary:
	if _story.is_empty():
		var f := FileAccess.open("res://data/story.json", FileAccess.READ)
		if f:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_story = d
	if night_id == 0:                       # practice night: Night 1's malfunction, its own radio line
		var b: Dictionary = (_story.get("1", {}) as Dictionary).duplicate()
		b["open"] = "Mission Control: This is a practice night. Nothing can go wrong, so try every button!"
		b.erase("close")
		b.erase("radio")
		return b
	return _story.get(str(night_id), {})


## data/night_extras.json: per night discovery + crew request templates.
func night_extras(night_id: int) -> Dictionary:
	if _extras.is_empty():
		var f := FileAccess.open("res://data/night_extras.json", FileAccess.READ)
		if f:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_extras = d
	var out: Dictionary = {"requests": _extras.get("requests", [])}
	out["discovery"] = _extras.get("discoveries", {}).get(str(night_id), {})
	return out


func load_night(night_id: int) -> NightConfig:
	if night_id == 0:
		return _practice_night()
	var path := NIGHT_PATH % night_id
	if not ResourceLoader.exists(path):
		return null
	return load(path) as NightConfig


## Night 0: the last night's base (everything unlocked, radio on) with no hazards at all.
var _practice: NightConfig
func _practice_night() -> NightConfig:
	if _practice == null:
		_practice = (load(NIGHT_PATH % 7) as NightConfig).duplicate() as NightConfig
		_practice.id = 0
		_practice.title = "Practice Night"
		_practice.theme = "Practice"
		_practice.comms_delay_real_min = 4.0
		_practice.briefing_text = "Walk to every building and go inside to see what it does. Then start the practice night and try every control. Nothing can fail here!"
		var none: Array[HazardEvent] = []
		_practice.hazard_events = none
	return _practice


func start_night(night_id: int) -> bool:
	config = load_night(night_id)
	if config == null or not config.ready:
		return false
	sim = OutpostSim.new()
	director = NightDirector.new()
	sim.start(config, Balance.config, Progression.levels, Progression.food_for_night(config))
	director.setup(sim, config, Balance.config, randi(), Progression.calm_mode)
	sim.sponsors = Progression.sponsors_tonight()
	if sponsor_tonight and sim.sponsors.is_empty():
		sim.sponsors = [(night_id - 1) % 7 + 1]
	sim.sponsor = not sim.sponsors.is_empty()
	director.plan_extras(night_extras(night_id), Balance.config, tutorial_tonight, story_beat(night_id))
	frozen = false
	running = true
	paused = false
	night_started.emit(config)
	return true


func stop_night() -> void:
	running = false
	paused = false


func _process(delta: float) -> void:
	if not running or paused or frozen:
		return
	var dt := delta * speed
	director.tick(dt)
	sim.tick(dt)
	if sim.finished:
		running = false
		var report := sim.end_report()
		Progression.apply_night_result(config, report)
		night_ended.emit(report)
