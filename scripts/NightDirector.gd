class_name NightDirector
extends RefCounted
## Plays any NightConfig: turns its HazardEvents into hazard intensities on the
## sim each tick, fires "why" alerts when events start, and runs the crew
## schedule. One generic script for all 7 nights.

var sim: OutpostSim
var config: NightConfig
var rng := RandomNumberGenerator.new()

# Each entry: {ev: HazardEvent, start, peak, end, started: bool}
var _timeline: Array[Dictionary] = []
var _schedule: Array[CrewSchedule] = []
var _next_move: int = 0


func setup(s: OutpostSim, cfg: NightConfig, bal: BalanceConfig, seed: int, calm_mode: bool) -> void:
	sim = s
	config = cfg
	rng.seed = seed
	_timeline.clear()

	# Real events keep their exact timing; spooky "simplified" ones jitter a little.
	var flare_start := -1.0
	for ev in cfg.hazard_events:
		if calm_mode and ev.optional:
			continue
		var j := 0.0 if ev.is_real() else rng.randf_range(-bal.event_jitter_sec, bal.event_jitter_sec)
		var start := maxf(0.0, ev.start_sec + j) if ev.start_sec > 0.0 else 0.0
		var shift := start - ev.start_sec
		_timeline.append({"ev": ev, "start": start, "peak": ev.peak_sec + shift, "end": ev.end_sec + shift, "started": false})
		if ev.type == "flare" and (flare_start < 0.0 or start < flare_start):
			flare_start = start

	# Warning window: particles always arrive a fixed time after the flare's light.
	if flare_start >= 0.0:
		var window := bal.warning_window_sec * (bal.calm_warning_multiplier if calm_mode else 1.0)
		for e in _timeline:
			var ev: HazardEvent = e.ev
			if ev.type == "particles":
				var new_start := flare_start + window
				var shift: float = new_start - e.start
				e.start = new_start
				e.peak += shift
				e.end = minf(e.end + shift, bal.night_length_sec)

	_schedule = cfg.crew_schedule.duplicate()
	_schedule.sort_custom(func(a: CrewSchedule, b: CrewSchedule) -> bool: return a.at_sec < b.at_sec)
	_next_move = 0


func tick(_dt: float) -> void:
	# Uses the sim's clock so the director and sim never drift apart.
	var t := sim.clock_sec

	for k in sim.hazard.keys():
		sim.hazard[k] = 0.0
	for e in _timeline:
		var ev: HazardEvent = e.ev
		var v := ev.intensity_at(t, e.start, e.peak, e.end)
		if v > 0.0 or (t >= e.start and t < e.end):
			sim.hazard[ev.type] = maxf(sim.hazard[ev.type], v)
		if not e.started and t >= e.start:
			e.started = true
			if ev.type == "flare":
				sim.on_flare_alarm()
			elif ev.why_text != "":
				sim.alert.emit(ev.why_text, ev.type)

	while _next_move < _schedule.size() and _schedule[_next_move].at_sec <= t:
		var m := _schedule[_next_move]
		sim.schedule_move(m.crew_id, m.room, m.walk_sec)
		_next_move += 1


## Seconds until the particles arrive, or -1 if no flare tonight / already arrived.
func seconds_until_particles() -> float:
	for e in _timeline:
		var ev: HazardEvent = e.ev
		if ev.type == "particles" and sim.clock_sec < e.start:
			return e.start - sim.clock_sec
	return -1.0
