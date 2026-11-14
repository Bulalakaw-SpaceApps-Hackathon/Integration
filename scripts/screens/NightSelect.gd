extends Control
## SC-02 Night Select: 7 cards with stars. Locked / unfinished nights are greyed with
## "Coming soon". Judge Mode opens with Night 6 selected.

var selected := 1
var cards: Array[Control] = []
var go_button: Button
var info: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Palette.SKY_NIGHT
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	selected = 6 if Progression.judge_mode else clampi(Progression.highest_unlocked, 1, Progression.NIGHT_COUNT)
	if not Progression.night_available(selected):
		selected = 1

	var title := Ui.label("CHOOSE A NIGHT", Ui.HUGE, true, Palette.HIGHLIGHT)
	title.position = Vector2(40, 30)
	add_child(title)
	if Progression.judge_mode:
		var j := Ui.label("JUDGE MODE", Ui.BODY, true, Palette.STATUS_WARN)
		j.position = Vector2(1050, 42)
		add_child(j)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(64, 100)
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 20)
	add_child(grid)
	for n in range(1, Progression.NIGHT_COUNT + 1):
		var card := _card(n)
		grid.add_child(card)
		cards.append(card)

	info = Ui.label("", Ui.BODY, false, Palette.HIGHLIGHT, 760)
	info.position = Vector2(64, 528)
	add_child(info)
	go_button = Ui.button("GO TO BASE", _go, Vector2(240, 64))
	go_button.position = Vector2(980, 600)
	add_child(go_button)
	var back := Ui.button("BACK", func() -> void: Game.goto("title"), Vector2(160, 56))
	back.position = Vector2(64, 640)
	add_child(back)
	_select(selected)


func _card(n: int) -> Control:
	var cfg := SimState.load_night(n)
	var avail := Progression.night_available(n)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var pic := TextureButton.new()
	pic.texture_normal = Assets.tex("night_card_%d" % n)
	pic.focus_mode = Control.FOCUS_NONE
	pic.pressed.connect(func() -> void:
		Sfx.play("click")
		_select(n))
	box.add_child(pic)
	if not avail:
		var lock := Ui.image("night_card_lock")
		lock.position = Vector2.ZERO
		pic.add_child(lock)
		var why := Ui.label("COMING SOON" if cfg == null or not cfg.ready else "LOCKED", Ui.BODY, true, Palette.HIGHLIGHT)
		why.position = Vector2(0, 124)
		why.custom_minimum_size.x = 240
		why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pic.add_child(why)
	var name := "%d · %s" % [n, cfg.title.to_upper() if cfg else "?"]
	box.add_child(Ui.label(name, 8, true, Palette.HIGHLIGHT))
	box.add_child(Ui.stars(int(Progression.stars.get(n, 0)), 3, 24))
	box.set_meta("night", n)
	return box


func _select(n: int) -> void:
	selected = n
	for c in cards:
		var pic: TextureButton = c.get_child(0)
		pic.modulate = Color.WHITE if int(c.get_meta("night")) == n else Color(1, 1, 1, 0.75)
	var cfg := SimState.load_night(n)
	var avail := Progression.night_available(n)
	if cfg == null or not cfg.ready:
		info.text = "NIGHT %d IS COMING SOON." % n
	elif not avail:
		info.text = "NIGHT %d: WIN THE NIGHT BEFORE IT TO UNLOCK." % n
	else:
		info.text = "NIGHT %d · %s\n%s" % [n, cfg.title.to_upper(), cfg.briefing_text]
	go_button.disabled = not avail


func _go() -> void:
	Game.goto("hub", selected)


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k and k.pressed and (k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER) and not go_button.disabled:
		_go()
