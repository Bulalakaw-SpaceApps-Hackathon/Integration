extends Control
## SC-01 Title screen: Play, Judge Mode, Codex, NASA Data, Settings, Credits.


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := Ui.image("screen_title")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)

	var logo := Ui.image("logo")
	logo.position = Vector2(340, 60)
	logo.size = Vector2(600, 200)
	add_child(logo)

	var gallery_btn := Ui.button("CUTSCENE GALLERY", func() -> void: Game.goto("cutscene_gallery"), Vector2(320, 64))
	gallery_btn.position = Vector2(24, 540)
	add_child(gallery_btn)

	var v := VBoxContainer.new()
	v.position = Vector2(490, 300)
	v.custom_minimum_size = Vector2(300, 0)
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	# Campaign: always starts at Night 1. CONTINUE goes to the latest night reached.
	var has_progress := Progression.highest_unlocked > 1 or Progression.story_seen
	if has_progress:
		v.add_child(Ui.button("CONTINUE · NIGHT %d" % Progression.highest_unlocked, _continue, Vector2(300, 64)))
	v.add_child(Ui.button("NEW GAME", _new_game, Vector2(300, 56 if has_progress else 64)))
	v.add_child(Ui.button("JUDGE MODE", func() -> void: Game.open_panel("judge"), Vector2(300, 56)))
	var r := Ui.row(v, 10)
	r.add_child(Ui.button("CODEX", func() -> void: Game.open_panel("codex"), Vector2(145, 52)))
	r.add_child(Ui.button("NASA DATA", func() -> void: Game.open_panel("nasa"), Vector2(145, 52)))
	var r2 := Ui.row(v, 10)
	r2.add_child(Ui.button("SETTINGS", func() -> void: Game.open_panel("settings"), Vector2(145, 52)))
	r2.add_child(Ui.button("CREDITS", func() -> void: Game.open_panel("credits"), Vector2(145, 52)))

	# Night 0: the tutorial, bottom-right. Never forced; new players get a nudge.
	var tut := Ui.button("TUTORIAL", Game.start_tutorial, Vector2(220, 60))
	tut.position = Vector2(1040, 612)
	add_child(tut)
	var note := Ui.label("READY FOR DUTY!" if Progression.ready_badge else "FIRST TIME? START HERE!", 8, true,
		Palette.STATUS_OK if Progression.ready_badge else Palette.STATUS_WARN)
	note.position = Vector2(1040, 594)
	note.custom_minimum_size = Vector2(220, 0)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(note)
	if Progression.ready_badge:
		var badge := Ui.image("ui_star_full")
		badge.position = Vector2(1010, 588)
		badge.custom_minimum_size = Vector2(24, 24)
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.size = Vector2(24, 24)
		add_child(badge)

	# live / archived NASA data status, bottom-left above the credit line
	var status := Ui.row(self, 8)
	status.position = Vector2(20, 654)          # badge (32 px) clear of the credit line below (D55)
	_fill_status(status)
	DonkiService.updated.connect(func() -> void:
		for ch in status.get_children():
			ch.queue_free()
		_fill_status(status))
	DonkiService.fetch()

	var foot := Ui.label("A NASA SPACE APPS 2026 GAME BY TEAM BULALAKAW", 8, false, Palette.HIGHLIGHT)
	foot.position = Vector2(20, 700)
	add_child(foot)


func _fill_status(row: HBoxContainer) -> void:
	row.add_child(Ui.badge("live" if DonkiService.is_live() else "archived"))
	row.add_child(Ui.label(DonkiService.short_status(), 8, false, Palette.HIGHLIGHT))


func _leave_judge() -> void:
	if Progression.judge_mode:
		Progression.leave_judge_mode()
	SimState.speed = 1.0


func _continue() -> void:
	_leave_judge()
	Game.goto("hub", Progression.highest_unlocked)


var _confirm_new := false

func _new_game() -> void:
	_leave_judge()
	var has_progress := Progression.highest_unlocked > 1 or Progression.story_seen
	if has_progress and not _confirm_new:
		_confirm_new = true
		Game.toast("This erases your saved progress. Press NEW GAME again to start over at Night 1.", "info", 5.0)
		return
	Progression.new_game()
	Game.visited.clear()
	Game.goto("hub", 1)
