extends SceneTree
## Opens every Task on the desk, solves it by code, and screenshots each one.
var game
var ss
var step := 0
var wait := 10
var kinds := ["loose_cable", "panel_dust", "clogged_filter", "airlock_leak", "greenhouse_leak", "shelter_seal", "dish_drift"]
var ki := 0

func _initialize() -> void:
	change_scene_to_file("res://scenes/Main.tscn")

func _process(_d: float) -> bool:
	if game == null:
		game = root.get_node_or_null("Game")
		ss = root.get_node("SimState")
		root.get_node("Progression").tutorial_done = true
		root.get_node("Progression").seen_guides.assign([1, 2, 3, 4, 5, 6, 7])
	if wait > 0:
		wait -= 1
		return false
	wait = 12
	var desk = game.screen
	match step:
		0: game.goto("hub", 4)
		1: game.goto("desk")
		2:
			if ki >= kinds.size():
				return true
			ss.frozen = true
			ss.sim.add_fault(kinds[ki])
			desk._open_task(kinds[ki])
		3:
			var t0 = desk.task
			match kinds[ki]:
				"loose_cable": t0.plugs_done = 1; t0.plug_angle = 0.2
				"panel_dust":
					for x in range(80, 300, 20): t0._drag(Vector2(x, 120))
				"clogged_filter": t0.temp = 0.7; t0.oxygen = 0.45; t0.holding = true
				"airlock_leak": t0._tap(t0.leaks[0])
				"greenhouse_leak": t0.caught = 3
				"shelter_seal": t0._tap(Vector2(100, 150)); t0._tap(Vector2(164, 150))
				"dish_drift": t0.aim = t0._earth_pos() + Vector2(30, 10)
			wait = 30
			step = 30
			return false
		30:
			step = 3
			root.get_texture().get_image().save_png("user://task_%d_%s.png" % [ki, kinds[ki]])
			var t = desk.task
			t._win()
			wait = 220
		4:
			print(kinds[ki], " fixed: ", not ss.sim.fault_active(kinds[ki]), " task closed: ", desk.task == null)
			ki += 1
			step = 1
	step += 1
	return false
