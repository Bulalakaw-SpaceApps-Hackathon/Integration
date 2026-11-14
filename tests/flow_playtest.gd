extends SceneTree
## Plays through the whole game flow with real rendering and saves screenshots:
## title -> panels -> night select -> hub (briefing, plot card, upgrade) -> Night 1 -> debrief
## -> continue to Night 2 hub -> Judge Mode -> Night 7 -> Mission Complete.
##   xvfb-run godot --path . --rendering-driver opengl3 -s res://tests/flow_playtest.gd

var step := 0
var wait := 10
var game: Node
var ss: Node
var prog: Node
var shot_n := 0


func _initialize() -> void:
	var f := FileAccess.open("user://save.cfg", FileAccess.WRITE)   # fresh save
	if f:
		f.store_string("")
	change_scene_to_file("res://scenes/Main.tscn")


func shot(name: String) -> void:
	shot_n += 1
	var img := root.get_texture().get_image()
	img.save_png("user://flow_%02d_%s.png" % [shot_n, name])
	print("shot ", name)


func play_smart(s: Object) -> void:
	# a careful player: 1 camera, heater LOW, shelter + recall on the flare alarm
	if s.flare_alarm_at >= 0.0:
		if not has_meta("opened"):
			set_meta("opened", true)
			s.toggle_shelter_door()
			s.recall_crew()
		elif s.shelter_door_open:
			var all_in := true
			for c in s.crew:
				if c.room != "shelter" or c.walk_left > 0.0:
					all_in = false
			if all_in:
				s.toggle_shelter_door()


func _process(_d: float) -> bool:
	if game == null:
		game = root.get_node_or_null("Game")
		ss = root.get_node("SimState")
		prog = root.get_node("Progression")
	if wait > 0:
		wait -= 1
		return false
	wait = 12
	match step:
		0: shot("title")
		1: game.open_panel("codex")
		2: shot("codex_locked")
		3: game.close_all_panels(); game.open_panel("nasa")
		4: shot("nasa_panel")
		5: game.close_all_panels(); game.open_panel("settings")
		6: shot("settings")
		7: game.close_all_panels(); game.goto("night_select")
		8: shot("night_select")
		9: game.goto("hub", 1)
		10: shot("hub_briefing")
		11:
			game.screen._close_card()
			game.screen._show_plot_card("solar")
		12: shot("hub_plot_card")
		13:
			game.screen._close_card()
			prog.materials = 5
			game.screen._upgrade("solar")
		14: shot("hub_upgraded")
		15:
			game.screen._close_card()
			Input.action_press("move_right")
			wait = 40
		16:
			Input.action_release("move_right")
			shot("hub_walked")
		17: game.goto("desk")
		18: shot("desk_guide_n1")
		19:
			var desk = game.screen
			desk.overlay.visible = false
			ss.paused = false
			prog.seen_guides.append(1)
			desk._press_camera("solar_field")
			desk._press_heater()      # MID -> HIGH
			desk._press_heater()      # HIGH -> LOW
			ss.speed = 8.0
		20: shot("desk_n1_playing")
		21:
			if ss.running:
				step -= 1
				wait = 30
			else:
				print("N1 result ", ss.sim.result, " reason ", ss.sim.lose_reason, " battery ", ss.sim.battery)
		22: shot("debrief_n1")
		23: game.night_finished(ss.sim.result == "won")
		24: shot("after_n1")
		25:
			game.close_all_panels()
			game.open_panel("judge")
		26: shot("judge_panel")
		27:
			prog.judge_mode = true
			prog.unlock_all = true
			prog.materials += 20
			game.goto("night_select")
		28: shot("night_select_judge")
		29: game.goto("hub", 6)
		30: shot("hub_n6_judge")
		31:
			game.goto("desk")
		32:
			var desk = game.screen
			desk.overlay.visible = false
			ss.paused = false
			ss.speed = 4.0
			desk._press_camera("sky_radar")
			desk._press_camera("shelter")
		33:
			if ss.running:
				play_smart(ss.sim)
				if ss.sim.flare_alarm_at >= 0.0 and not has_meta("n6shot"):
					set_meta("n6shot", true)
					shot("desk_n6_flare")
				step -= 1
				wait = 2
			else:
				print("N6 result ", ss.sim.result, " reason ", ss.sim.lose_reason, " maxdose ", ss.sim.max_dose())
		34: shot("debrief_n6")
		35: game.open_panel("pause")
		36: shot("pause")
		37: game.close_all_panels(); game.night = 7; game.night_finished(true)
		38: shot("mission_complete")
		39:
			game.open_panel("credits")
		40: shot("credits")
		41:
			game.close_all_panels()
			prog.codex.append_array(["sol", "radiation"])
			game.open_panel("codex")
		42: shot("codex_open")
		43: return true
	step += 1
	return false
