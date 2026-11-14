extends SceneTree
## Renders the desk at chosen hours / hazards and saves screenshots of the live windows.
## xvfb-run godot --path . --rendering-driver opengl3 -s res://tests/window_preview.gd
var desk: Control
var shots := [
	["w1_1800_sunset", 18.0, 0.0, 0.0], ["w2_1830_sunset", 18.5, 0.0, 0.0], ["w3_2130_phobos", 21.5, 0.0, 0.0],
	["w4_0100_night", 25.0, 0.0, 0.0], ["w5_0545_dawn", 29.75, 0.0, 0.0],
	["w6_storm", 23.0, 1.0, 0.0], ["w7_flare", 22.0, 0.0, 1.0]]
var i := 0
var frames := 0

func _initialize() -> void:
	desk = load("res://scenes/Desk.tscn").instantiate()
	root.add_child(desk)

func _process(_d: float) -> bool:
	frames += 1
	if frames < 8:
		return false
	if i >= shots.size():
		return true
	var s: Array = shots[i]
	desk.set_process(false)                   # hold the hour we set
	desk.overlay.visible = false
	for w in desk.windows:
		w.set_state(s[1], s[2], s[3])
	if frames % 4 == 0:
		var img := root.get_texture().get_image()
		img.save_png("user://%s.png" % s[0])
		print("shot ", s[0])
		i += 1
	return false
