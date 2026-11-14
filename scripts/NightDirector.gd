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
# Camera problems, crew requests, the discovery and sponsor messages: [{at, kind, data}]
var _extras: Array[Dictionary] = []


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

	while not _extras.is_empty() and _extras[0].at <= t:
		_fire_extra(_extras.pop_front(), sim.balance)

	while _next_move < _schedule.size() and _schedule[_next_move].at_sec <= t:
		var m := _schedule[_next_move]
		sim.schedule_move(m.crew_id, m.room, m.walk_sec)
		_next_move += 1


## Plan tonight's camera problems, crew requests, discovery and sponsor messages.
## `info` comes from data/night_extras.json. scripted = true (guided Night 1): the tutorial adds them itself.
func plan_extras(info: Dictionary, bal: BalanceConfig, scripted: bool, story: Dictionary = {}) -> void:
	_extras.clear()
	# the story beat decides tonight's Malfunction, Challenge, Problems and radio facts
	sim.setup_malfunction(story.get("malfunction", {}))
	sim.challenge = str(story.get("challenge", ""))
	for r in story.get("radio", []):
		_extras.append({"at": float(r[0]), "kind": "radio", "data": {"text": r[1]}})
	var idx := clampi(config.id - 1, 0, 6)
	var has_flare := false
	for ev in config.hazard_events:
		if ev.type == "flare":
			has_flare = true
	if sim.sponsor:
		var t := bal.sponsor_first_sec
		while t < bal.night_length_sec - 10.0:
			_extras.append({"at": t, "kind": "sponsor", "data": {}})
			t += bal.sponsor_gap_sec + rng.randf_range(-5.0, 5.0)
	if scripted:
		_extras.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.at < b.at)
		return
	if story.has("faults"):
		for f in story.faults:
			_extras.append({"at": float(f[1]) + rng.randf_range(-3.0, 3.0), "kind": "fault", "data": {"fault": f[0]}})
	var kinds: Array[String] = ["loose_cable"]
	if config.id >= 2: kinds.append("clogged_filter")
	if config.food_enabled: kinds.append("greenhouse_leak")
	if config.id >= 4: kinds.append("airlock_leak")
	if has_flare: kinds.append("shelter_seal")
	var n := 0 if story.has("faults") else bal.faults_per_night[idx]
	for i in n:
		var at := lerpf(25.0, 150.0, (i + 0.5) / n) + rng.randf_range(-8.0, 8.0)
		var kind: String = kinds[(i + rng.randi_range(0, kinds.size() - 1)) % kinds.size()]
		if kind == "shelter_seal":
			at = minf(at, 40.0)          # a broken seal only matters before the particles
		_extras.append({"at": at, "kind": "fault", "data": {"fault": kind}})
	var templates: Array = info.get("requests", [])
	var usable: Array = templates.filter(func(r: Dictionary) -> bool: return config.crew_ids.has(r.crew))
	var rn := mini(bal.requests_per_night[idx], usable.size())
	for i in rn:
		var r: Dictionary = usable[(config.id * 3 + i * 5 + rng.randi_range(0, 2)) % usable.size()]
		usable.erase(r)
		var at := lerpf(40.0, 160.0, (i + 0.5) / maxf(rn, 1)) + rng.randf_range(-6.0, 6.0)
		_extras.append({"at": at, "kind": "request", "data": r})
	var disc: Dictionary = info.get("discovery", {})
	if not disc.is_empty():
		_extras.append({"at": float(disc.get("at", 60.0)), "kind": "discovery", "data": disc})
	_extras.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.at < b.at)


func _fire_extra(e: Dictionary, bal: BalanceConfig) -> void:
	var d: Dictionary = e.data
	match e.kind:
		"sponsor": sim.show_sponsor_ad()
		"radio": sim.radio.emit(str(d.text))
		"fault": sim.add_fault(d.fault)
		"request": sim.add_request(d.crew, d.text, d.get("yes", {}), d.get("no", {}), bal.request_timeout_sec)
		"discovery":
			var p: Array = d.get("pos", [160, 90])
			sim.place_discovery(d.cam, Vector2(p[0], p[1]), d.title, d.text)


## Seconds until the particles arrive, or -1 if no flare tonight / already arrived.
func seconds_until_particles() -> float:
	for e in _timeline:
		var ev: HazardEvent = e.ev
		if ev.type == "particles" and sim.clock_sec < e.start:
			return e.start - sim.clock_sec
	return -1.0
