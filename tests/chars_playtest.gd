extends SceneTree
## Pixel characters in the game: day map crew + hint card, cameras, request box, debrief faces.

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
	root.get_texture().get_image().save_png("user://chars_%02d_%s.png" % [n, name])
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
		0:
			prog.story_seen = true
			prog.seen_guides.assign([1, 2, 3, 4, 5, 6, 7])
			prog.resting = ["maya"]
			game.goto("hub", 5)
		1:
			scr._close_card()
			scr.commander.position = Vector2(560, 380)
		2: shot("hub_crew")
		3:
			for id in scr.crew_nodes:
				print(id, ": ", scr._hint_line(id))
			scr._talk("lani")
		4: shot("hub_talk")
		5:
			scr._close_card()
			game.goto("desk")
		6:
			scr.overlay.visible = false
			ss.frozen = false
			var s = ss.sim
			for cam in ["life_support", "solar_field"]:
				if not s.cameras_on.has(cam):
					s.toggle_camera(cam)
			s.add_request("mateo", "Can I run the air test early? It costs a little power.", {"battery": -3}, {}, 999.0)
			s.schedule_move("carlo", "solar_field", 30.0)
			wait = 40
		7: shot("desk_crew_on_cams")
		8:
			for i in 2:
				if scr.feeds[i].cam == "life_support":
					scr._open_answer(i, "mateo")
		9: shot("desk_request_portrait")
		10:
			scr._close_answer()
			ss.sim.clock_sec = ss.sim.balance.night_length_sec - 0.5
			wait = 60
		11: shot("debrief_faces")
		12: return true
	step += 1
	return false
