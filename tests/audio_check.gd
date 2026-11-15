extends SceneTree
## Every sound the game asks for loads as an AudioStream.

func _initialize() -> void:
	var names := ["music_hub", "sfx_camera", "sfx_click", "sfx_door_close", "sfx_door_open", "sfx_dose_tick", "sfx_evacuate",
		"sfx_flare_alarm", "sfx_low_battery", "sfx_materials", "sfx_msg_received", "sfx_msg_sent", "sfx_recall", "sfx_star",
		"sfx_static_loop", "sfx_step_1", "sfx_step_2", "sfx_step_3", "sfx_sunrise", "sfx_thump", "sfx_upgrade", "sfx_wind_loop"]
	var bad := 0
	for n in names:
		var st: AudioStream = load("res://assets/sfx/%s.ogg" % n)
		if st == null or st.get_length() <= 0.0:
			print("  FAIL ", n)
			bad += 1
		else:
			print("  PASS %s %.2fs" % [n, st.get_length()])
	print("ALL PASSED" if bad == 0 else "%d FAILED" % bad)
	quit()
