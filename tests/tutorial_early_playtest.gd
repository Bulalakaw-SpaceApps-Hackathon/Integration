extends SceneTree
## Night 0 tutorial, played by a kid who presses everything early (D: tutorial steps skip themselves).
## Before the steps ask: Solar camera on, heater OFF, malfunction diagnosed, shelter open, recall, ask Earth.
## Passes if every early step shows "already done", SCAN + DIAGNOSE collapse into one "already solved"
## line, and the tutorial still ends with the Ready for duty badge.

var step := 0
var wait := 10
var game: Node
var ss: Node
var prog: Node
var skipped: Array[String] = []
var fails := 0


func _initialize() -> void:
	var f := FileAccess.open("user://save.cfg", FileAccess.WRITE)
	if f:
		f.store_string("")
	change_scene_to_file("res://scenes/Main.tscn")


func check(ok: bool, what: String) -> void:
	print(("  PASS  " if ok else "  FAIL  ") + what)
	if not ok:
		fails += 1


func _process(_d: float) -> bool:
	if game == null:
		game = root.get_node_or_null("Game")
		ss = root.get_node("SimState")
		prog = root.get_node("Progression")
	if wait > 0:
		wait -= 1
		return false
	wait = 8
	var scr = game.screen
	match step:
		0: game.start_tutorial()
		1:
			scr._close_card()
			for id in ["solar", "battery", "life_support", "shelter", "suit_bay", "comms_dish", "greenhouse"]:
				scr._show_building(id)
				scr._close_card()
		2: scr._start_night()
		3:
			# the eager kid: do everything before being asked
			var s = ss.sim
			s.toggle_camera("solar_field")
			s.set_heater(-1)
			s.diagnose(s.malf["true"])
			scr._press_shelter()
			scr._press_recall()
			scr._press_ask()
			check(s.malfunction_solved(), "malfunction solved early")
		4:
			var st: Array = scr._tut_steps()[scr.tut_step]
			var s = ss.sim
			if scr.tut_skip:
				if st[2] == "scan":
					root.get_texture().get_image().save_png("user://tut_early_already_solved.png")
				skipped.append(st[2])
				scr._tut_advance()
				return false
			match st[2]:
				"next", "start": scr._tut_advance()
				"fault": s.complete_task("loose_cable")
				"request": s.answer_request("lani", true)
				"discovery": s.collect_discovery()
				"ad":
					scr._close_ad(0)
					scr._close_ad(1)
				"finish":
					scr._tut_advance()
					step = 5
					return false
				_:
					check(false, "stuck on step %s (%s)" % [st[0], st[2]])
					step = 5
					return false
			return false
		5:
			print("skipped: ", skipped)
			for k in ["camera", "heater", "scan", "shelter", "recall", "ask"]:
				check(skipped.has(k), "step '%s' skipped because it was already done" % k)
			check(not skipped.has("diagnose"), "SCAN and DIAGNOSE share one 'already solved' line")
			check(prog.ready_badge, "Ready for duty badge given")
			check(game.screen_name == "title", "back on the title screen")
			print("ALL PASSED" if fails == 0 else "%d FAILED" % fails)
			return true
	step += 1
	return false
