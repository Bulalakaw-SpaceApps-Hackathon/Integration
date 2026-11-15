extends BasePanel
## "What was real?": every real NASA fact the game is built on, night by night, with its source.


func _build() -> void:
	card_width = 980
	title("WHAT WAS REAL?")
	body.add_child(Ui.label("The base and the crew are made up. Everything below is real, and you can look it up.", Ui.BODY, false, Palette.INK, 900))
	var v := scroll(420)
	for n in range(1, Progression.NIGHT_COUNT + 1):
		var cfg := SimState.load_night(n)
		if cfg == null:
			continue
		v.add_child(Ui.label("NIGHT %d · %s" % [n, cfg.title.to_upper()], Ui.BODY, true, Palette.SKY_INDIGO))
		for ev in cfg.hazard_events:
			if ev.real_date != "":
				var r := Ui.row(v, 10, BoxContainer.ALIGNMENT_BEGIN)
				r.add_child(Ui.badge("real"))
				r.add_child(Ui.label("REAL EVENT: %s (%s)" % [ev.real_date, ev.source_name], 8, true, Palette.INK, 780))
		if cfg.did_you_know != "":
			v.add_child(Ui.label("%s (SOURCE: %s)" % [cfg.did_you_know, cfg.did_you_know_source], 8, false, Palette.INK, 880))
		var d: Dictionary = SimState.night_extras(n).get("discovery", {})
		if not d.is_empty():
			v.add_child(Ui.label("DISCOVERY · %s: %s (SOURCE: %s)" % [d.get("title", ""), d.get("text", ""), d.get("source", "NASA")], 8, false, Palette.BASE_PLUM, 880))
	v.add_child(Ui.label("THE REPAIR TASKS", Ui.BODY, true, Palette.SKY_INDIGO))
	for k in OutpostSim.FAULTS:
		v.add_child(Ui.label(Strings.t("task.%s.fact" % k), 8, false, Palette.INK, 880))
	close_row()
