extends SceneTree
# Smoke test: load Main with autoloads, start Night 6 at 4x for ~10 s of frames, check no crash.
var frames := 0
func _initialize() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
func _process(_d: float) -> bool:
	frames += 1
	var ss = root.get_node("SimState")
	if frames == 5:
		ss.speed = 4.0
		print("start night 6: ", ss.start_night(6))
		ss.sim.toggle_shelter_door()
		ss.sim.recall_crew()
	if frames == 400:
		var main = root.get_node("Main")
		print("clock ", ss.sim.clock_string(), " battery %.1f" % ss.sim.battery)
		print("--- readout ---\n", main.readout.text)
		return true
	return false
