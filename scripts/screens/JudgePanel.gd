extends BasePanel
## J-01 Judge Mode: Night Select (opens on Night 6), Unlock all plots, +20 materials, 2x speed.

var mat_label: Label


func _build() -> void:
	card_width = 640
	body.custom_minimum_size.x = 600
	title("JUDGE MODE")
	body.add_child(Ui.label("Jump to any night. Night 6 (the real 2024 solar flare) is the best one to see first.", Ui.BODY, false, Palette.INK, 580))
	Progression.judge_mode = true
	body.add_child(_check("UNLOCK ALL PLOTS", Progression.unlock_all, func(on: bool) -> void: Progression.unlock_all = on))
	body.add_child(_check("2X SPEED", SimState.speed > 1.0, func(on: bool) -> void: SimState.speed = 2.0 if on else 1.0))
	var r := Ui.row(body, 16, BoxContainer.ALIGNMENT_BEGIN)
	r.add_child(Ui.button("+20 MATERIALS", func() -> void:
		Progression.materials += 20
		Progression.save_game()
		mat_label.text = "MATERIALS: %d" % Progression.materials, Vector2(260, 56)))
	mat_label = Ui.label("MATERIALS: %d" % Progression.materials, Ui.BODY, true)
	r.add_child(mat_label)
	close_row([Ui.button("CHOOSE NIGHT", func() -> void: Game.goto("night_select"), Vector2(260, 56))])


func _check(text: String, on: bool, changed: Callable) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 16)
	var b := TextureButton.new()
	b.toggle_mode = true
	b.button_pressed = on
	b.texture_normal = Assets.tex("ui_toggle_off")
	b.texture_pressed = Assets.tex("ui_toggle_on")
	b.focus_mode = Control.FOCUS_NONE
	b.toggled.connect(func(v: bool) -> void:
		Sfx.play("click")
		changed.call(v))
	r.add_child(b)
	r.add_child(Ui.label(text, Ui.BODY, true))
	return r


func close() -> void:
	# closing without choosing a night leaves Judge Mode
	if Game.screen_name == "title":
		Progression.leave_judge_mode()
		SimState.speed = 1.0
	super.close()
