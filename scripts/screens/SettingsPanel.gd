extends BasePanel
## J-03 Settings: Mute, Calm Mode, NASA API key (+ reset progress).

var key_edit: LineEdit


func _build() -> void:
	title("SETTINGS")
	body.add_child(_toggle("SOUND OFF (M)", Progression.muted, func(on: bool) -> void:
		Progression.muted = on
		Sfx.apply_mute()))
	body.add_child(_toggle("CALM MODE (MORE TIME)", Progression.calm_mode, func(on: bool) -> void:
		Progression.calm_mode = on))
	body.add_child(Ui.label("Calm Mode gives 1.5x more time before particles arrive, and spaces events further apart.", 8, false, Palette.BASE_PLUM, 740))
	body.add_child(Ui.label("NASA API KEY (FREE AT API.NASA.GOV)", Ui.BODY, true))
	key_edit = LineEdit.new()
	key_edit.text = Progression.api_key
	key_edit.placeholder_text = "DEMO_KEY"
	key_edit.custom_minimum_size = Vector2(740, 48)
	key_edit.text_changed.connect(func(t: String) -> void: Progression.api_key = t.strip_edges())
	body.add_child(key_edit)
	close_row([Ui.button("RESET PROGRESS", _reset, Vector2(240, 56))])


func _toggle(text: String, on: bool, changed: Callable) -> HBoxContainer:
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
		changed.call(v)
		Progression.save_game())
	r.add_child(b)
	r.add_child(Ui.label(text, Ui.BODY, true))
	return r


func close() -> void:
	Progression.save_game()
	super.close()


func _reset() -> void:
	Progression.new_game()
	Game.toast("Progress reset. Good luck, Commander!", "info")
	Game.goto("title")
