extends SceneTree
## Headless balance + logic tests. Plays nights with scripted "players".
##   godot --headless --path . -s res://tests/test_sim.gd
## Exit code 0 = all passed.

const DT := 0.05
var failures := 0
var bal: BalanceConfig


func _init() -> void:
	bal = load("res://data/balance.tres")
	if bal == null:
		bal = BalanceConfig.new()

	# --- Night 1: power ------------------------------------------------------
	var r := play(1, func(_s: OutpostSim, _d: NightDirector) -> void: pass)
	check("N1 default settings survive", r.won)
	print("    N1 battery left: %.1f%%" % r.battery)

	r = play(1, func(s: OutpostSim, _d: NightDirector) -> void:
		if s.clock_sec < DT:
			s.toggle_camera("solar_field"); s.toggle_camera("life_support"); s.set_heater(OutpostSim.Heater.HIGH))
	check("N1 two cameras + heater HIGH all night runs out of battery", not r.won and r.reason == "battery")

	r = play(1, func(s: OutpostSim, _d: NightDirector) -> void:
		if s.clock_sec < DT:
			s.set_heater(OutpostSim.Heater.LOW))
	check("N1 heater LOW earns the battery bonus", r.won and r.bonus.get("battery_20", false))

	# --- Night 2: air and food ----------------------------------------------
	r = play(2, func(s: OutpostSim, _d: NightDirector) -> void:
		if s.clock_sec < DT:
			s.set_crop_lamp(true))
	check("N2 crop lamp all night (default settings) survives", r.won)
	check("N2 crop lamp grows food (4 - 2 eaten + 2 grown = 4)", r.food_after == 4)
	print("    N2 lamp on: battery %.1f%%, oxygen %.1f%%" % [r.battery, r.oxygen])

	var normal := play(2, func(_s: OutpostSim, _d: NightDirector) -> void: pass)
	r = play(2, func(s: OutpostSim, _d: NightDirector) -> void:
		if s.clock_sec < DT:
			s.set_life_support(OutpostSim.LifeSupport.LOW))
	print("    N2 oxygen at sunrise: Normal %.1f%%, Low %.1f%%" % [normal.oxygen, r.oxygen])
	check("N2 life support LOW saves battery but costs >15 points of oxygen", normal.oxygen - r.oxygen > 15.0 and r.battery > normal.battery)

	# --- Radio delay: ASK EARTH comes back after 2x light time and rules out a wrong cause
	var asked := {"sent": -1.0, "reply": -1.0, "text": "", "crossed": 0}
	var story2: Dictionary = JSON.parse_string(FileAccess.open("res://data/story.json", FileAccess.READ).get_as_text())
	r = play_extras(2, _extras(), func(s: OutpostSim, _d: NightDirector) -> void:
		if asked.sent < 0.0 and s.has_malfunction() and s.clock_sec > 5.0:
			if s.send_message("ask_earth"):
				asked.sent = s.clock_sec
				s.radio.connect(func(t: String) -> void:
					if asked.reply < 0.0 and not s.ask_in_flight():
						asked.reply = s.clock_sec
						asked.text = t
						asked.crossed = s.malf.causes.filter(func(c: Dictionary) -> bool: return c.crossed).size()))
	var want := 2.0 * 7.5 * bal.delay_seconds_per_real_minute
	print("    N2 ask earth: sent %.1f, reply %.1f (want ~%.0f s later): %s" % [asked.sent, asked.reply, want, asked.text])
	check("N2 ASK EARTH reply arrives after the round trip", asked.reply > 0.0 and asked.reply - asked.sent >= want - 1.0)
	check("N2 Earth's reply crosses off a wrong cause", asked.crossed >= 1)

	# --- Balance target: a player who does NOTHING all night
	for nn in range(1, 8):
		var rr := play(nn, func(_s: OutpostSim, _d: NightDirector) -> void: pass)
		print("    passive N%d: won %s, battery %.0f%%, oxygen %.0f%%, rough %s, stars %d" % [nn, rr.won, rr.battery, rr.oxygen, rr.rough, rr.stars])

	# --- The real cause must not always be the first row
	var first_true := 0
	for i in 20:
		var ss := OutpostSim.new()
		ss.balance = bal
		ss.setup_malfunction(story2["3"].malfunction)
		if ss.malf.causes[0].id == ss.malf["true"]:
			first_true += 1
	check("Malfunction rows are shuffled (true cause first in %d of 20)" % first_true, first_true < 16)

	# --- Night 3: small real particle storm ---------------------------------
	r = play(3, func(_s: OutpostSim, _d: NightDirector) -> void: pass)
	check("N3 small storm is survivable without sheltering (gentle intro)", r.won)
	check("N3 no shelter = no shelter bonus", not r.bonus.get("shelter_fast", true))

	r = play(3, good_shelter_player())
	check("N3 good sheltering earns shelter_fast", r.won and r.bonus.get("shelter_fast", false))

	# --- Night 4: comms delay -----------------------------------------------
	var replies := [0]
	r = play(4, func(s: OutpostSim, _d: NightDirector) -> void:
		if s.clock_sec < DT:
			s.message_arrived.connect(func(_k: String) -> void: replies[0] += 1)
			s.send_message("ask_earth")
		if absf(s.clock_sec - 120.0) < DT / 2.0:
			s.recall_crew())
	check("N4 Ask Earth reply arrives after a delay", replies[0] == 1)
	check("N4 recalling Carlo earns all_inside_end", r.won and r.bonus.get("all_inside_end", false))

	# --- Night 5: dust ------------------------------------------------------
	r = play(5, func(_s: OutpostSim, _d: NightDirector) -> void: pass)
	check("N5 default settings fail on a dust night", not r.won)
	r = play(5, func(s: OutpostSim, _d: NightDirector) -> void:
		if s.clock_sec < DT:
			s.set_heater(OutpostSim.Heater.LOW); s.set_dish(false))
	check("N5 saving power (heater LOW, dish off) survives", r.won)
	print("    N5 frugal: battery %.1f%%, oxygen %.1f%%" % [r.battery, r.oxygen])

	# --- Night 6: the real X12 flare -----------------------------------------
	r = play(6, func(_s: OutpostSim, _d: NightDirector) -> void: pass)
	check("N6 doing nothing = rough night (radiation): Survive star only, crew rest", r.rough.has("dose") and r.stars <= 1 and not r.resting.is_empty())

	r = play(6, good_shelter_player())
	check("N6 good sheltering survives", r.won)
	check("N6 good sheltering earns shelter_fast", r.bonus.get("shelter_fast", false))
	print("    N6 good play: max dose %.1f chest X-rays, battery %.1f%%" % [r.max_dose, r.battery])

	r = play(6, func(s: OutpostSim, d: NightDirector) -> void:
		if s.flare_alarm_at >= 0.0 and s.clock_sec - s.flare_alarm_at < DT:
			s.toggle_shelter_door()   # opens and calls inside crew, but forgets the outside crew
		if s.shelter_door_open and s.clock_sec - s.flare_alarm_at > 8.0:
			s.toggle_shelter_door())
	check("N6 forgetting the outside crew = rough night, they rest tomorrow", r.rough.has("dose") and r.stars <= 1 and not r.resting.is_empty())

	# --- Night 7: finale ----------------------------------------------------
	var shelter := good_shelter_player()
	r = play(7, func(s: OutpostSim, d: NightDirector) -> void:
		if s.clock_sec < DT:
			s.set_heater(OutpostSim.Heater.LOW)
		if absf(s.clock_sec - 20.0) < DT / 2.0:
			s.send_message("discovery")
		shelter.call(s, d))
	check("N7 early discovery + sheltering wins with discovery_sent", r.won and r.bonus.get("discovery_sent", false))
	print("    N7 good play: battery %.1f%%, max dose %.1f" % [r.battery, r.max_dose])

	r = play(7, func(s: OutpostSim, d: NightDirector) -> void:
		if s.clock_sec < DT:
			s.set_heater(OutpostSim.Heater.LOW)
		if absf(s.clock_sec - 140.0) < DT / 2.0:
			s.send_message("discovery")
		shelter.call(s, d))
	check("N7 sending too late is lost in the blackout", not r.get("bonus", {}).get("discovery_sent", true))

	# --- OFF switches, camera problems, crew requests, discovery ------------
	var t := OutpostSim.new()
	t.start(load("res://data/nights/night_2.tres"), bal, {}, 4)
	t.set_heater(OutpostSim.Heater.LOW)
	var low_drain := t.drain_per_sec()
	t.set_heater(OutpostSim.Heater.OFF)
	check("Heater OFF uses less power than LOW", t.drain_per_sec() < low_drain)
	t.set_life_support(OutpostSim.LifeSupport.OFF)
	check("Life Support OFF makes no oxygen (air falls)", t.oxygen_per_sec() < 0.0)
	t.set_life_support(OutpostSim.LifeSupport.NORMAL)
	var d0 := t.drain_per_sec()
	t.add_fault("loose_cable")
	check("A loose cable drains extra power", t.drain_per_sec() > d0)
	check("Can't fix a problem without its camera on", not t.fix_fault("loose_cable"))
	t.toggle_camera("solar_field")
	check("Fixing it with the camera on works", t.fix_fault("loose_cable") and is_equal_approx(t.drain_per_sec(), d0 + bal.camera_cost * bal.battery_bank_multiplier[0]))
	var b0 := t.battery
	t.add_request("lani", "test", {"battery": -4, "materials": 1}, {}, 30.0)
	check("Answering YES to a request applies its cost and reward", t.answer_request("lani", true) and is_equal_approx(t.battery, b0 - 4.0) and t.extra_materials == 1)
	t.place_discovery("greenhouse", Vector2(10, 10), "X", "Y")
	check("Discovery needs its camera", not t.collect_discovery())
	t.toggle_camera("greenhouse")
	check("Discovery collected with the camera on", t.collect_discovery() and t.discovery_found())

	# Whole nights with problems, requests and the discovery switched on:
	# an attentive player (fixes problems, answers yes, collects science, shelters) wins every night.
	var extras := _extras()
	for n in range(1, 8):
		var shelter_p := good_shelter_player()
		r = play_extras(n, extras, func(s: OutpostSim, d: NightDirector) -> void:
			if s.clock_sec < DT:
				s.set_heater(OutpostSim.Heater.LOW)
				if s.config.food_enabled:
					s.set_crop_lamp(true)
			_attentive(s)
			shelter_p.call(s, d))
		check("N%d attentive player wins with 3 stars possible (stars %d, science %s, challenge %s)" % [n, r.stars, r.star_science, r.star_challenge], r.won and r.star_science)
		if not r.star_science: print("    N%d detail: rough %s, discovery %s, malf solved %s, battery %.0f, faults %d/%d" % [n, r.rough, r.discovery_found, r.malfunction.get("solved", false), r.battery, r.faults_fixed, r.faults_total])
		if not r.won:
			print("      lost: ", r.reason, " battery ", r.battery, " oxygen ", r.oxygen)
	var lazy := play_extras(2, extras, func(_s: OutpostSim, _d: NightDirector) -> void: pass)
	var busy := play_extras(2, extras, func(s: OutpostSim, _d: NightDirector) -> void: _attentive(s))
	print("    N2 ignoring problems: battery %.1f oxygen %.1f · fixing them: battery %.1f oxygen %.1f" % [lazy.battery, lazy.oxygen, busy.battery, busy.oxygen])
	check("N2 ignoring camera problems is worse than fixing them", lazy.oxygen + lazy.battery < busy.oxygen + busy.battery)

	# Crew go back to work after the danger (they used to stay in the shelter forever)
	var u := OutpostSim.new()
	var ud := NightDirector.new()
	var c6: NightConfig = load("res://data/nights/night_6.tres")
	u.start(c6, bal, {}, 4)
	ud.setup(u, c6, bal, 1, false)
	var gp := good_shelter_player()
	var reopened := [false]
	while not u.finished:
		gp.call(u, ud)
		if u._all_clear_said and not reopened[0] and u.door_fully_closed():
			reopened[0] = true
			u.toggle_shelter_door()
		ud.tick(DT)
		u.tick(DT)
	var still_held := 0
	for cm in u.crew:
		if cm.held:
			still_held += 1
	check("N6 after the all clear, opening the door sends the crew back to work", reopened[0] and still_held == 0)

	# Malfunction maths
	var m := OutpostSim.new()
	m.start(load("res://data/nights/night_2.tres"), bal, {}, 4)
	m.setup_malfunction({"true": "a", "causes": [{"id": "a", "name": "A", "rooms": ["airlock"]}, {"id": "b", "name": "B", "rooms": ["greenhouse"]}, {"id": "c", "name": "C", "rooms": ["shelter"]}], "clues": []})
	check("Malfunction starts even (1/3 each)", is_equal_approx(m.malf.causes[0].p, 1.0 / 3.0))
	m._apply_clue({"points": "a", "reliability": 4})
	check("A 4-in-5 clue makes its cause most likely but not certain", _cause(m, "a").p > 0.7 and _cause(m, "a").p < 0.95)
	var b0m := m.battery
	check("Wrong diagnosis is refused, costs battery, crosses the cause off", not m.diagnose("b") and _cause(m, "b").crossed and m.battery < b0m)
	check("Right diagnosis solves it", m.diagnose("a") and m.malfunction_solved())
	var m2 := OutpostSim.new()
	m2.start(load("res://data/nights/night_2.tres"), bal, {}, 4)
	m2.setup_malfunction({"true": "a", "causes": [{"id": "a", "name": "A", "rooms": ["airlock"]}, {"id": "b", "name": "B", "rooms": ["greenhouse"]}], "clues": []})
	m2.toggle_camera("greenhouse")
	var res := m2.scan("greenhouse")
	check("Empty SCAN lowers the causes tied to that room", res.get("empty", false) and _cause(m2, "b").p < 0.5)
	check("SCAN has a cooldown", not m2.can_scan("greenhouse"))
	for n in range(1, 8):
		var sb: Dictionary = JSON.parse_string(FileAccess.open("res://data/story.json", FileAccess.READ).get_as_text()).get(str(n), {})
		var ok_true := false
		var true_has_clue := false
		for c in sb.malfunction.causes:
			if c.id == sb.malfunction["true"]:
				ok_true = true
				for k in sb.malfunction.clues:
					if (c.rooms as Array).has(k.cam):
						true_has_clue = true
		check("Story N%d: true cause exists and its room has a clue (so SCAN never lies about it)" % n, ok_true and true_has_clue)

	# --- Forecast -----------------------------------------------------------
	var s := OutpostSim.new()
	s.start(load("res://data/nights/night_1.tres"), bal, {}, 0)
	var before := s.forecast_empty_at()
	s.set_heater(OutpostSim.Heater.HIGH)
	check("Forecast moves earlier when the heater goes up", s.forecast_empty_at() < before)
	print("    N1 forecast at sunset: '%s'" % s.forecast_text())

	print("\n%s (%d failed)" % ["ALL PASSED" if failures == 0 else "SOME FAILED", failures])
	quit(1 if failures > 0 else 0)


## Recall + open the shelter on the alarm; close the door once everyone is inside.
func good_shelter_player() -> Callable:
	return func(s: OutpostSim, _d: NightDirector) -> void:
		if s.flare_alarm_at < 0.0:
			return
		if s.clock_sec - s.flare_alarm_at < DT:
			s.recall_crew()
			if not s.shelter_door_open:
				s.toggle_shelter_door()
		if s.shelter_door_open:
			var all_in := true
			for c in s.crew:
				if c.room != "shelter" or c.walk_left > 0.0:
					all_in = false
			if all_in:
				s.toggle_shelter_door()


func play(night_id: int, player: Callable) -> Dictionary:
	var cfg: NightConfig = load("res://data/nights/night_%d.tres" % night_id)
	var sim := OutpostSim.new()
	var dir := NightDirector.new()
	var food := bal.food_start if cfg.food_enabled else 0
	sim.start(cfg, bal, {}, food)
	dir.setup(sim, cfg, bal, 12345, false)
	while not sim.finished:
		player.call(sim, dir)
		dir.tick(DT)
		sim.tick(DT)
	return sim.end_report()


## Looks at whichever camera needs attention (one at a time), then fixes / answers / collects.
func _attentive(s: OutpostSim) -> void:
	var want := ""
	for f in s.faults:
		if f.fixed_at < 0.0:
			want = f.cam
	if want == "" and not s.discovery.is_empty() and not s.discovery.found:
		want = s.discovery.cam
	if want == "":
		for r in s.requests:
			if r.answer == "":
				want = s.crew_cam(r.crew)
	# detective: a clue is showing somewhere right now -> go and watch it
	if want == "" and s.has_malfunction() and not s.malf.solved:
		for k in s.malf.clues:
			if not k.found and s.clock_sec >= float(k.at) and s.clock_sec <= float(k.at) + OutpostSim.CLUE_SECONDS:
				want = k.cam
	# careful with power: switch extras off when the forecast says the battery won't last
	if s.forecast_empty_at() < s.balance.night_length_sec:
		if s.crop_lamp:
			s.set_crop_lamp(false)
		elif s.heater > OutpostSim.Heater.OFF:
			s.set_heater(s.heater - 1)
		elif s.life_support > OutpostSim.LifeSupport.LOW and s.oxygen > 30.0:
			s.set_life_support(s.life_support - 1)
	if want == "":
		while not s.cameras_on.is_empty():
			s.toggle_camera(s.cameras_on[0])
		return
	if not s.cameras_on.has(want):
		while s.cameras_on.size() >= 1:
			s.toggle_camera(s.cameras_on[0])
		s.toggle_camera(want)
	for f in s.faults:
		if f.fixed_at < 0.0:
			s.fix_fault(f.kind)
	s.collect_discovery()
	# detective: scan the camera we're on, diagnose once one cause is "very likely"
	if s.has_malfunction() and not s.malf.solved:
		for cam in s.cameras_on:
			if s.can_scan(cam) and not s.has_meta("scanned_" + cam):
				s.set_meta("scanned_" + cam, true)
				s.scan(cam)
		for c in s.malf.causes:
			if c.p >= 0.75:
				s.diagnose(c.id)
	for r in s.requests:
		if r.answer == "" and s.crew_cam(r.crew) == want:
			s.answer_request(r.crew, r.yes.get("battery", 0) > -5)


func _extras() -> Dictionary:
	var f := FileAccess.open("res://data/night_extras.json", FileAccess.READ)
	return JSON.parse_string(f.get_as_text())


func play_extras(night_id: int, extras: Dictionary, player: Callable) -> Dictionary:
	var cfg: NightConfig = load("res://data/nights/night_%d.tres" % night_id)
	var sim := OutpostSim.new()
	var dir := NightDirector.new()
	sim.start(cfg, bal, {}, bal.food_start if cfg.food_enabled else 0)
	dir.setup(sim, cfg, bal, 777, false)
	var story: Dictionary = JSON.parse_string(FileAccess.open("res://data/story.json", FileAccess.READ).get_as_text())
	dir.plan_extras({"requests": extras.requests, "discovery": extras.discoveries.get(str(night_id), {})}, bal, false, story.get(str(night_id), {}))
	while not sim.finished:
		player.call(sim, dir)
		dir.tick(DT)
		sim.tick(DT)
	return sim.end_report()


func check(name: String, ok: bool) -> void:
	print(("  PASS  " if ok else "  FAIL  ") + name)
	if not ok:
		failures += 1


func _cause(sim: OutpostSim, id: String) -> Dictionary:
	for c in sim.malf.causes:
		if c.id == id:
			return c
	return {}
