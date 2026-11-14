extends SceneTree
## Screenshots of the tester-feedback features: story card, sponsor offer, guided Night 1,
## camera problems, crew request answer box, discovery, help popup, sponsor messages, OFF switches.
##   xvfb-run godot --path . --rendering-driver opengl3 -s res://tests/feature_playtest.gd

var step := 0
var wait := 10
var game: Node
var ss: Node
var prog: Node
var n := 0


func _initialize() -> void:
	var f := FileAccess.open("user://save.cfg", FileAccess.WRITE)
	if f:
		f.store_string("")
	change_scene_to_file("res://scenes/Main.tscn")


func shot(name: String) -> void:
	n += 1
	root.get_texture().get_image().save_png("user://feat_%02d_%s.png" % [n, name])
	print("shot ", name)


func click(p: Vector2) -> void:
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = p
		e.global_position = p
		root.push_input(e)


func center(c: Control) -> Vector2:
	return c.global_position + c.size / 2


func _process(_d: float) -> bool:
	if game == null:
		game = root.get_node_or_null("Game")
		ss = root.get_node("SimState")
		prog = root.get_node("Progression")
	if wait > 0:
		wait -= 1
		return false
	wait = 12
	var desk = game.screen
	match step:
		0: game.goto("hub", 1)
		1: shot("story_card")
		2: game.screen._show_briefing()
		3: shot("briefing_n1")
		4: game.goto("desk")
		5: shot("tut_1_battery")
		6: click(center(desk.tut_next))
		7: click(center(desk.tut_next))
		8: shot("tut_3_camera")
		9: click(center(desk.cam_buttons[2]))
		10: shot("tut_4_heater")
		11: click(center(desk.ctl["heater"])); click(center(desk.ctl["heater"]))   # MID > HIGH > OFF
		12: shot("heater_off_not_low_yet")
		13: click(center(desk.ctl["heater"]))     # OFF > LOW
		14: click(center(desk.tut_next))
		15: shot("tut_6_fault")
		16:
			var s = ss.sim
			var f = s.faults_on_cam("solar_field")[0]
			var i := 0 if desk.feeds[0].cam == "solar_field" else 1
			click(desk.feeds[i].global_position + f.pos)
		17:
			shot("task_wires_open")
			if desk.task:
				desk.task._win()
			wait = 220
		18: shot("tut_7_request")
		19: click(center(desk.cam_buttons[4]))
		20: shot("air_cam_with_lani_request")
		21:
			var i := 0 if desk.feeds[0].cam == "life_support" else 1
			for c in desk.feeds[i].crew_rects:
				if c.id == "lani":
					click(desk.feeds[i].global_position + c.rect.get_center())
		22: shot("answer_box")
		23:
			for b in desk.answer_box.find_children("*", "Button", true, false):
				if b.text == "YES":
					click(center(b))
		24: shot("tut_8_discovery")
		25:
			var s = ss.sim
			var i := 0 if desk.feeds[0].cam == "solar_field" else 1
			click(desk.feeds[i].global_position + s.discovery.pos)
		26:
			shot("tut_10_board")
			click(center(desk.tut_next))
		27:
			shot("tut_11_scan")
			click(center(desk.scan_buttons[0]))
		28:
			shot("tut_12_diagnose")
			click(center(desk.diagnose_btn))
		29:
			shot("diagnose_box")
			for b in desk.diag_box.find_children("*", "Button", true, false):
				if b.text.begins_with("LOOSE"):
					click(center(b))
		30: shot("tut_9_done")
		31: click(center(desk.tut_next))
		32: desk._show_help("forecast")
		33: shot("help_popup")
		34:
			for b in desk.help_box.find_children("*", "Button", true, false):
				click(center(b))
		35:
			ss.speed = 8.0
		36:
			if ss.running:
				step -= 1
				wait = 30
			else:
				print("N1 tutorial night: ", ss.sim.result, " ", ss.sim.lose_reason)
		37: shot("debrief_n1")
		38:
			ss.speed = 1.0
			game.goto("hub", 5)
		39:
			game.screen._close_card()
			game.screen._show_sponsor_poster()
		40:
			shot("hub_n5_sponsor_poster")
			game.screen._decide_sponsor(true)
		41: shot("hub_n5_sponsor_panel")
		42:
			ss.sponsor_tonight = true
			game.goto("desk")
		43:
			desk.overlay.visible = false
			ss.paused = false
			ss.sim.show_sponsor_ad()
			ss.sim.send_message("ask_earth")
			ss.sim.add_fault("loose_cable")
			wait = 120
			ss.sim.add_fault("airlock_leak")
		44: shot("n5_sponsor_ad_and_locked_buttons")
		45:
			ss.sponsor_tonight = false
			prog.fails[6] = 2
			prog.seen_guides.erase(6)
			game.goto("hub", 6)
		46: game.goto("desk")
		47: shot("n6_guide_strip_and_hint_arrow")
		48: click(center(desk.tut_next))
		49:
			print("arrow before shelter press: ", desk.hint_arrow.visible)
			click(center(desk.ctl["shelter"]))
		50:
			print("arrow after shelter press: ", desk.hint_arrow.visible)
			desk.meter_panel.flip(1)
		51: shot("stats_page_crew_where")
		52: desk.meter_panel.flip(1); desk.meter_panel.flip(1)
		53: shot("stats_page_food")
		54: return true
	step += 1
	return false
