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
	check("N6 doing nothing = too much radiation", not r.won and r.reason == "dose")

	r = play(6, good_shelter_player())
	check("N6 good sheltering survives", r.won)
	check("N6 good sheltering earns shelter_fast", r.bonus.get("shelter_fast", false))
	print("    N6 good play: max dose %.1f chest X-rays, battery %.1f%%" % [r.max_dose, r.battery])

	r = play(6, func(s: OutpostSim, d: NightDirector) -> void:
		if s.flare_alarm_at >= 0.0 and s.clock_sec - s.flare_alarm_at < DT:
			s.toggle_shelter_door()   # opens and calls inside crew, but forgets the outside crew
		if s.shelter_door_open and s.clock_sec - s.flare_alarm_at > 8.0:
			s.toggle_shelter_door())
	check("N6 forgetting the outside crew still fails", not r.won and r.reason == "dose")

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


func check(name: String, ok: bool) -> void:
	print(("  PASS  " if ok else "  FAIL  ") + name)
	if not ok:
		failures += 1
