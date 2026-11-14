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
	running = true
	paused = false
	night_started.emit(config)
	return true


func stop_night() -> void:
	running = false
	paused = false


func _process(delta: float) -> void:
	if not running or paused:
		return
	var dt := delta * speed
	director.tick(dt)
	sim.tick(dt)
	if sim.finished:
		running = false
		var report := sim.end_report()
		Progression.apply_night_result(config, report)
		night_ended.emit(report)
