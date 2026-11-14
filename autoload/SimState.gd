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
	var path := NIGHT_PATH % night_id
	if not ResourceLoader.exists(path):
		return null
	return load(path) as NightConfig


func start_night(night_id: int) -> bool:
	config = load_night(night_id)
	if config == null or not config.ready:
		return false
	sim = OutpostSim.new()
	director = NightDirector.new()
	sim.start(config, Balance.config, Progression.levels, Progression.food_for_night(config))
	director.setup(sim, config, Balance.config, randi(), Progression.calm_mode)
	sim.sponsor = sponsor_tonight
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
