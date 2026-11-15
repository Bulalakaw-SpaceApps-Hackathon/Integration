extends SceneTree
## Night 0 tutorial end to end: title button -> practice day -> practice night -> badge.

var step := 0
var wait := 10
var game: Node
var ss: Node
var prog: Node
var n := 0
var sub := 0


func _initialize() -> void:
	var f := FileAccess.open("user://save.cfg", FileAccess.WRITE)
	if f:
		f.store_string("")
	change_scene_to_file("res://scenes/Main.tscn")


func shot(name: String) -> void:
	n += 1
	root.get_texture().get_image().save_png("user://tut_%02d_%s.png" % [n, name])
	print("shot ", name)


func _process(_d: float) -> bool:
	if game == null:
		game = root.get_node_or_null("Game")
		ss = root.get_node("SimState")
		prog = root.get_node("Progression")
	if wait > 0:
		wait -= 1
		return false
	wait = 12
	var scr = game.screen
	match step:
		0: shot("title_new_player")
		1: game.start_tutorial()
		2: shot("day_card")
		3:
			scr._close_card()
			for id in ["solar", "battery", "life_support", "shelter", "suit_bay", "comms_dish", "greenhouse"]:
				scr._show_building(id)
				scr._close_card()
		4: shot("day_all_visited")
		5: scr._start_night()
		6:
			print("desk? ", game.screen_name, " frozen ", ss.frozen, " steps ", scr._tut_steps().size())
			shot("night_step_1")
		7:
			# walk every step: press NEXT where there is one, otherwise do the action for the player
			var st: Array = scr._tut_steps()[scr.tut_step]
			var s = ss.sim
			match st[2]:
				"next", "start": scr._tut_advance()
				"camera": s.toggle_camera("solar_field")
				"heater": s.set_heater(0)
				"fault": s.complete_task("loose_cable")
				"request": s.answer_request("lani", true)
				"discovery": s.collect_discovery()
				"scan": s.scan("solar_field")
				"diagnose": s.diagnose(s.malf["true"])
				"shelter": scr._press_shelter()
				"recall": scr._press_recall()
				"ask":
					scr._press_ask()
					print("ask: dish ", s.dish, " comms ", s.comms, " cfgdelay ", s.config.comms_delay_real_min, " msgs ", s.messages, " disabled ", scr.ctl["ask"].disabled, " hazard ", s.hazard)
				"ad":
					if sub == 0:
						sub = 1
						wait = 110
						return false
					shot("night_ad_step")
					scr._close_ad(0)
					scr._close_ad(1)
				"finish":
					shot("night_last_step")
					scr._tut_advance()
					step = 8
					return false
			print("step ", scr.tut_step, " ", st[0], " ", st[2])
			return false
		8:
			print("screen ", game.screen_name, " badge ", prog.ready_badge, " tutorial ", game.tutorial, " unlock_all ", prog.unlock_all, " highest ", prog.highest_unlocked)
			shot("title_badge")
		9: return true
	step += 1
	return false
