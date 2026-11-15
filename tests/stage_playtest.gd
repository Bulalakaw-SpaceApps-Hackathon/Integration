extends SceneTree
## Screenshots for the final-gameplay stages (sponsor stacking, try-again screen, pause dim, fan...).
##   xvfb-run godot --path . --rendering-driver opengl3 -s res://tests/stage_playtest.gd

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
	root.get_texture().get_image().save_png("user://stage_%02d_%s.png" % [n, name])
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
	var desk = game.screen
	match step:
		0:
			prog.tutorial_done = true
			prog.sponsor_deals = [[2, 2], [3, 1]]
			prog.seen_guides.assign([1, 2, 3, 4, 5, 6, 7])
			game.goto("hub", 4)
		1:
			game.screen._show_sponsor_poster()
		2: shot("hub_two_sponsors_poster")
		3:
			game.screen._decide_sponsor(true)
		4: shot("hub_three_sponsors")
		5: game.goto("desk")
		6:
			desk.overlay.visible = false
			ss.paused = false
			ss.frozen = false
			ss.sim.show_sponsor_ad()
			ss.sim.show_sponsor_ad()
			ss.sim.show_sponsor_ad()
			desk._tap_fan()
			wait = 110
		7: shot("desk_two_ads_fan")
		8:
			desk._close_ad(0); desk._close_ad(1)
			desk._show_help("battery")
		9: shot("desk_help_dim")
		10:
			desk.help_box.visible = false
			ss.paused = false
			ss.sim.oxygen = 0.0
			wait = 30
		11: shot("desk_rough_alert")
		12:
			ss.sim.battery = 0.0
			ss.sim.battery_zero_sec = 999.0
			wait = 40
		13: shot("try_again")
		14:
			print("deals after loss: ", prog.sponsor_deals, " rough: ", ss.sim.rough)
			prog.sponsor_deals.clear()
			game.goto("title")
		15:
			game.open_panel("judge")
		16:
			shot("judge_best_of")
			game.top_panel()._best_of()
		17:
			desk.overlay.visible = false
			if desk.guide_mode > 0:
				desk._tut_advance()
			ss.frozen = false
			ss.sim.toggle_camera("sky_radar")
			ss.speed = 4.0
			wait = 620
		18:
			print("clock ", ss.sim.clock_sec)
			shot("n7_meteor_shower")
			wait = 420
		19:
			print("n7 faults: ", ss.sim.faults.map(func(f): return f.kind), " discovery: ", ss.sim.discovery.get("title", "-"), " on ", ss.sim.discovery.get("cam", "-"))
			shot("n7_after_meteors")
			ss.speed = 1.0
		20:
			prog.discoveries = {1: "FROST ON THE GROUND", 3: "A RADIATION RECORD", 7: "A BULALAKAW LANDED!"}
			prog.stars = {1: 3, 2: 2, 3: 3, 4: 1, 5: 2, 6: 3, 7: 2}
			game.goto("complete")
			wait = 300
		21: shot("ending")
		22: game.open_panel("real")
		23: shot("what_was_real")
		24: return true
	step += 1
	return false
