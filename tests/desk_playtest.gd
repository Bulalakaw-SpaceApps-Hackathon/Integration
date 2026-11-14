extends SceneTree
## Scripted play-test of the Camera Desk (needs a display; run under xvfb-run for CI):
##   xvfb-run -a godot --path . --rendering-driver opengl3 -s res://tests/desk_playtest.gd
## Plays Night 1 (two cameras on, so the battery runs out) and Night 6 (recall + shelter at
## the flare alarm), pressing the same functions the buttons call, and saves screenshots.

const OUT := "user://playtest_"
var frame := 0
var step := 0
var wait_frames := 0
var desk: Control
var ss: Node


func _initialize() -> void:
	change_scene_to_file("res://scenes/Desk.tscn")


func shot(name: String) -> void:
	var img := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path(OUT + name + ".png")
	img.save_png(path)
	print("screenshot: ", path)


func _process(_delta: float) -> bool:
	frame += 1
	if frame < 5:
		return false
	desk = current_scene
	ss = root.get_node("SimState")
	if wait_frames > 0:
		wait_frames -= 1
		return false
	match step:
		0:
			shot("01_briefing_night1")
			desk._start_night()
			step = 1
		1:
			desk._press_camera("solar_field")
			desk._press_camera("life_support")
			desk._press_camera("greenhouse")          # a 3rd camera must be refused
			ss.speed = 6.0
			step = 2
		2:
			if ss.sim.clock_sec > 45.0:
				print("N1 cameras on: ", ss.sim.cameras_on, "  (expect 2)")
				shot("02_night1_two_cameras")
				step = 3
		3:
			if not ss.running:
				wait_frames = 10
				step = 4
		4:
			print("N1 result: ", ss.sim.result, " reason: ", ss.sim.lose_reason)
			shot("03_debrief_night1")
			desk.night_id = 6
			desk._show_briefing()
			wait_frames = 5
			step = 5
		5:
			shot("04_briefing_night6")
			desk._start_night()
			desk._press_camera("sky_radar")
			desk._press_camera("shelter")
			ss.speed = 3.0
			step = 6
		6:
			if ss.sim.flare_alarm_at >= 0.0:
				wait_frames = 20
				step = 7
		7:
			shot("05_night6_flare_countdown")
			desk._press_recall()
			desk._press_shelter()
			step = 8
		8:
			var all_in := true
			for c in ss.sim.crew:
				if c.room != "shelter" or c.walk_left > 0.0:
					all_in = false
			if all_in:
				desk._press_shelter()                 # close the door
				desk._press_camera("sky_radar")       # a careful player saves power:
				desk._press_camera("shelter")         # both cameras off while sheltered
				wait_frames = 30
				step = 9
		9:
			shot("06_night6_sheltered")
			step = 10
		10:
			if not ss.running:
				wait_frames = 10
				step = 11
		11:
			print("N6 result: ", ss.sim.result, "  reason: ", ss.sim.lose_reason, "  battery: ", snappedf(ss.sim.battery, 0.1), "  max dose: ", snappedf(ss.sim.max_dose(), 0.1))
			shot("07_debrief_night6")
			return true
	return false
