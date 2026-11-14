extends Node
## Plays the game's soft sounds (CC0 .ogg in assets/sfx). Respects Mute.
##   Sfx.play("click")            one-shot  (file sfx_click.ogg)
##   Sfx.loop("wind_loop", true)  start / stop a loop
##   Sfx.music(true)              base-map music
## Buses: Master > Music, SFX (created here if the project has no bus layout).

const POOL := 8

var _players: Array[AudioStreamPlayer] = []
var _loops: Dictionary = {}          # name -> AudioStreamPlayer
var _next := 0
var _last_played: Dictionary = {}    # name -> msec, to stop sound spam


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	apply_mute()


func apply_mute() -> void:
	AudioServer.set_bus_mute(0, Progression.muted)


func play(name: String, volume_db := 0.0) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(name, -1000)) < 60:
		return
	_last_played[name] = now
	var stream := Assets.sound("sfx_" + name)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = stream
	p.volume_db = volume_db
	p.play()


func loop(name: String, on: bool, volume_db := -6.0) -> void:
	var asset := name if name.begins_with("music_") else "sfx_" + name
	if on:
		if _loops.has(name):
			return
		var stream := Assets.sound(asset)
		if stream == null:
			return
		var p := AudioStreamPlayer.new()
		p.bus = "Music" if name.begins_with("music_") else "SFX"
		p.stream = stream
		p.volume_db = volume_db
		add_child(p)
		p.play()
		_loops[name] = p
	elif _loops.has(name):
		(_loops[name] as AudioStreamPlayer).queue_free()
		_loops.erase(name)


func stop_all_loops() -> void:
	for n in _loops.keys():
		loop(n, false)


func music(on: bool) -> void:
	loop("music_hub", on, -10.0)
