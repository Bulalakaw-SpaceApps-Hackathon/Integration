extends SceneTree
## All six camera feeds in every state, on the real desk.

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
	root.get_texture().get_image().save_png("user://feeds_%02d_%s.png" % [n, name])
	print("shot ", name)


func cams(a: String, b: String) -> void:
	var s = ss.sim
	while not s.cameras_on.is_empty():
		s.toggle_camera(s.cameras_on[0])
	s.toggle_camera(a)
	s.toggle_camera(b)


func _process(_d: float) -> bool:
	if game == null:
		game = root.get_node_or_null("Game")
		ss = root.get_node("SimState")
		prog = root.get_node("Progression")
	if wait > 0:
		wait -= 1
		return false
	wait = 14
	var desk = game.screen
	match step:
		0:
			prog.seen_guides.assign([1, 2, 3, 4, 5, 6, 7])
			prog.unlock_all = true
			game.goto("desk", 7)
		1:
			desk.overlay.visible = false
			ss.frozen = false
			ss.paused = false
			cams("airlock", "shelter")
		2: shot("airlock_shelter_open")
		3:
			ss.sim.toggle_shelter_door()
			wait = 6
		4: shot("shelter_door_closing")
		5:
			cams("life_support", "greenhouse")
			ss.sim.set_crop_lamp(true)
		6: shot("lifesupport_greenhouse_lamp")
		7:
			ss.sim.set_crop_lamp(false)
			ss.sim.hazard.co2 = 1.0
		8: shot("lifesupport_slow_greenhouse_off")
		9:
			cams("sky_radar", "solar_field")
			ss.sim.hazard.co2 = 0.0
			ss.sim.hazard.dust = 1.0
			ss.sim.hazard.flare = 1.0
		10: shot("radar_glow_solar_dusty")
		11: return true
	step += 1
	return false
