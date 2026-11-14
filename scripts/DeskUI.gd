extends Control
## The Camera Desk (build-order step 2). Places all desk art, wires every control to
## SimState.sim, and shows briefing + debrief. No game rules live here: this script only
## calls OutpostSim action methods and reads its state.
##
## Stand-ins until the art exists: camera feeds (CF-xx) are drawn in code, desk buttons
## (BT-xx) are plain styled buttons, crew are coloured squares (CH-xx).
##
## Keys: 1-6 cameras · H heater · L life support · C crop lamp · D dish · Q ask Earth
##       T send discovery · Space shelter door · R recall · Esc pause · F2 2x speed

const S := "res://assets/sprites/desk/"
const FONT_R := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const FONT_B := preload("res://assets/fonts/Silkscreen-Bold.ttf")
const CAMS := OutpostSim.CAMERAS
const CAM_SHORT := {"sky_radar": "SKY", "airlock": "AIRLOCK", "solar_field": "SOLAR", "shelter": "SHELTER", "life_support": "AIR", "greenhouse": "PLANTS"}
const CAM_NAME := {"sky_radar": "SKY RADAR", "airlock": "AIRLOCK", "solar_field": "SOLAR FIELD", "shelter": "SHELTER", "life_support": "LIFE SUPPORT", "greenhouse": "GREENHOUSE"}
const HEATER_TXT := ["LOW", "MID", "HIGH"]
const LS_TXT := ["LOW", "NORM", "HIGH"]
const ALERT_SECONDS := 5.0

var night_id: int = 1

# --- nodes we update every frame ---
var feeds: Array[FeedView] = []
var nameplates: Array[Label] = []
var monitor_sprites: Array[TextureRect] = []
var clock_time: Label
var clock_night: Label
var batt_fill: TextureRect
var batt_atlas: AtlasTexture
var batt_tex_ok: Texture2D
var batt_tex_low: Texture2D
var forecast_icon: TextureRect
var forecast_l1: Label
var forecast_l2: Label
var windows: Array[WindowView] = []
var briefing_open := false        # the window shows 18:00 while the briefing is up
var scroll_title: Label
var scroll_lines: Label
var meter_panel: MeterPanel
var fan: TextureRect
var fan_atlas: AtlasTexture
var fan_frame: int = 0
var fan_timer: float = 0.0
var cam_buttons: Array[Button] = []
var ctl: Dictionary = {}            # control name -> Button
var alert_box: VBoxContainer
var banner: Label
var pause_label: Label
var hint_arrow: TextureRect
var hint_t := 0.0
var tick_t := 0.0
var overlay: PanelContainer
var overlay_body: VBoxContainer
var tex_moon: Texture2D
var tex_sun: Texture2D
var mon_on: Texture2D
var mon_off: Texture2D


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_desk()
	SimState.night_started.connect(_on_night_started)
	SimState.night_ended.connect(_on_night_ended)
	if Game.flow:
		night_id = Game.night            # the Morning Briefing was shown on the base map
		overlay.visible = false
		_start_night.call_deferred()
	else:
		_show_briefing()                 # Desk.tscn run on its own (F6): built-in night picker


# ============================================================================
# Building the desk
# ============================================================================
func _window(k: String, r: Rect2) -> WindowView:
	var w := WindowView.new()
	add_child(w)
	w.setup(k, r)
	return w


func _tex(name: String, pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(S + name)
	t.position = pos
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	return t


func _label(text: String, pos: Vector2, sz: Vector2, font_size: int, color: Color, bold := false,
		h := HORIZONTAL_ALIGNMENT_LEFT, v := VERTICAL_ALIGNMENT_TOP, parent: Node = null) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = sz
	l.horizontal_alignment = h
	l.vertical_alignment = v
	l.add_theme_font_override("font", FONT_B if bold else FONT_R)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else self).add_child(l)
	return l


func _style(fill: Color, border: Color, width := 2, radius := 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	return sb


func _button(text: String, rect: Rect2, font_size: int, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", FONT_R)
	b.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, Palette.INK)
	b.add_theme_color_override("font_disabled_color", Palette.BASE_MAUVE)
	b.add_theme_stylebox_override("normal", _style(Palette.BASE_CREAM, Palette.INK))
	b.add_theme_stylebox_override("hover", _style(Palette.HIGHLIGHT, Palette.INK))
	b.add_theme_stylebox_override("pressed", _style(Palette.STATUS_WARN, Palette.INK))
	b.add_theme_stylebox_override("disabled", _style(Palette.BASE_STONE, Palette.BASE_MAUVE))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(on_press)
	add_child(b)
	return b


func _set_lit(b: Button, lit: bool) -> void:
	## "On" controls get the yellow style, so their state is visible (plus their text says ON/OFF).
	b.add_theme_stylebox_override("normal", _style(Palette.STATUS_WARN if lit else Palette.BASE_CREAM, Palette.INK))


func _build_desk() -> void:
	tex_moon = load(S + "ui_forecast_moon.png")
	tex_sun = load(S + "ui_forecast_sun.png")
	mon_on = load(S + "desk_monitor.png")
	mon_off = load(S + "desk_monitor_off.png")
	batt_tex_ok = load(S + "ui_battery_fill.png")
	batt_tex_low = load(S + "ui_battery_low.png")

	# live Mars sky BEHIND the desk background (its window glass is see-through)
	windows.append(_window("L", Rect2(172, 104, 351, 171)))
	windows.append(_window("R", Rect2(806, 128, 199, 143)))
	_tex("desk_bg.png", Vector2.ZERO)

	# camera feeds sit BEHIND the monitor bezels (the screen hole is transparent)
	for i in 2:
		var f := FeedView.new()
		f.position = Vector2(245 + i * 470, 286)
		f.size = Vector2(320, 180)
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(f)
		feeds.append(f)
	for i in 2:
		monitor_sprites.append(_tex("desk_monitor.png", Vector2(229 + i * 470, 258)))
		nameplates.append(_label("", Vector2(345 + i * 470, 264), Vector2(120, 17), 8, Palette.HIGHLIGHT, false,
			HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER))

	_tex("desk_panel_left.png", Vector2(16, 198))
	_tex("desk_panel_right.png", Vector2(1104, 198))
	_build_panel_controls()

	# top bar
	_button("II", Rect2(16, 22, 48, 48), 16, _toggle_pause)
	_button("2X", Rect2(72, 22, 48, 48), 16, _toggle_speed)
	var hint := _button("?", Rect2(16, 78, 48, 48), 16, _show_hint)
	hint.icon = Assets.tex("icon_hint")
	hint.text = ""
	hint.expand_icon = true
	hint.tooltip_text = "Hint from Mission Control"
	_button("M", Rect2(72, 78, 48, 48), 16, Game.toggle_mute).tooltip_text = "Mute (M)"
	_tex("desk_clock.png", Vector2(130, 10))
	clock_time = _label("18:00", Vector2(141, 13), Vector2(214, 34), 32, Palette.SKY_HAZE, true,
		HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	clock_night = _label("", Vector2(141, 59), Vector2(214, 18), 16, Palette.SKY_HAZE, false,
		HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	_tex("ui_battery_frame.png", Vector2(378, 22))
	batt_atlas = AtlasTexture.new()
	batt_atlas.atlas = batt_tex_ok
	batt_atlas.region = Rect2(0, 0, 430, 36)
	batt_fill = TextureRect.new()
	batt_fill.texture = batt_atlas
	batt_fill.position = Vector2(387, 28)
	batt_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(batt_fill)
	forecast_icon = _tex("ui_forecast_moon.png", Vector2(846, 30))
	forecast_l1 = _label("", Vector2(886, 28), Vector2(170, 18), 16, Palette.HIGHLIGHT)
	forecast_l2 = _label("", Vector2(886, 46), Vector2(170, 18), 16, Palette.HIGHLIGHT, true)

	# scroll (sticky note)
	_tex("desk_sticky_note.png", Vector2(1058, 2))
	scroll_title = _label("TONIGHT", Vector2(1088, 27), Vector2(152, 16), 16, Palette.INK, true)
	scroll_lines = _label("", Vector2(1088, 50), Vector2(152, 112), 16, Palette.INK)
	scroll_lines.add_theme_constant_override("line_spacing", 0)

	# meter panel
	_tex("desk_meter_panel.png", Vector2(16, 576))
	meter_panel = MeterPanel.new()
	meter_panel.position = Vector2(16, 576)
	meter_panel.size = Vector2(192, 120)
	meter_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_panel.setup(FONT_R, FONT_B, load(S + "ui_meter_oxygen.png"), load(S + "ui_meter_dose.png"),
		load(S + "ui_meter_comms.png"), load(S + "ui_meter_food.png"))
	add_child(meter_panel)

	# camera buttons (BT-02 stand-ins)
	for k in 6:
		var cam: String = CAMS[k]
		var b := _button("%d %s" % [k + 1, CAM_SHORT[cam]], Rect2(322 + k * 108, 538, 96, 96), 8,
			func() -> void: _press_camera(cam))
		b.icon = Assets.tex("icon_cam_" + cam)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		cam_buttons.append(b)

	# props (fan drawn last, it is closest to the player)
	_tex("desk_prop_cup.png", Vector2(1040, 612))
	fan_atlas = AtlasTexture.new()
	fan_atlas.atlas = load(S + "desk_prop_fan.png")
	fan_atlas.region = Rect2(0, 0, 160, 210)
	fan = TextureRect.new()
	fan.texture = fan_atlas
	fan.position = Vector2(1104, 496)
	fan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fan)

	# alerts, particle banner, pause label
	alert_box = VBoxContainer.new()
	alert_box.position = Vector2(400, 118)
	alert_box.size = Vector2(480, 0)
	alert_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_box.add_theme_constant_override("separation", 4)
	add_child(alert_box)
	banner = _label("", Vector2(380, 470), Vector2(520, 40), 16, Palette.INK, true,
		HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	banner.add_theme_stylebox_override("normal", Ui.nine("ui_warning_banner", 8))
	banner.visible = false
	pause_label = _label("PAUSED", Vector2(440, 300), Vector2(400, 60), 32, Palette.HIGHLIGHT, true,
		HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	pause_label.add_theme_stylebox_override("normal", _style(Palette.INK, Palette.HIGHLIGHT, 3))
	pause_label.visible = false

	hint_arrow = Ui.image("ui_hint_arrow", 0)
	hint_arrow.size = Vector2(64, 64)
	hint_arrow.visible = false
	add_child(hint_arrow)

	# briefing / debrief overlay
	overlay = PanelContainer.new()
	overlay.position = Vector2(280, 110)
	overlay.size = Vector2(720, 470)
	overlay.add_theme_stylebox_override("panel", Ui.nine("ui_debrief", 14))
	add_child(overlay)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	overlay.add_child(margin)
	overlay_body = VBoxContainer.new()
	overlay_body.add_theme_constant_override("separation", 12)
	margin.add_child(overlay_body)


func _build_panel_controls() -> void:
	# slot k sits at y = 198 + 18 + 98k; button area 72x60 at slot +20,+7; label plate at slot +6,+70
	var lx := 16 + 34
	var rx := 1104 + 14
	var slot_y := func(k: int) -> int: return 198 + 18 + 98 * k
	ctl["shelter"] = _button("DOOR\nCLOSED", Rect2(lx + 20, slot_y.call(0) + 7, 72, 60), 8, _press_shelter)
	ctl["recall"] = _button("RECALL", Rect2(lx + 20, slot_y.call(1) + 7, 72, 60), 8, _press_recall)
	ctl["dish"] = _button("DISH", Rect2(lx + 4, slot_y.call(2) + 18, 32, 32), 8, _press_dish)
	ctl["ask"] = _button("ASK", Rect2(lx + 40, slot_y.call(2) + 18, 32, 32), 8, _press_ask)
	ctl["send"] = _button("SEND", Rect2(lx + 76, slot_y.call(2) + 18, 32, 32), 8, _press_send)
	ctl["heater"] = _button("HEAT\nMID", Rect2(rx + 20, slot_y.call(0) + 7, 72, 60), 8, _press_heater)
	ctl["life"] = _button("AIR\nNORM", Rect2(rx + 20, slot_y.call(1) + 7, 72, 60), 8, _press_life)
	ctl["lamp"] = _button("LAMP\nOFF", Rect2(rx + 20, slot_y.call(2) + 7, 72, 60), 8, _press_lamp)
	var plates := [[lx, 0, "SHELTER DOOR"], [lx, 1, "RECALL CREW"], [lx, 2, "COMMS"],
		[rx, 0, "HEATER"], [rx, 1, "LIFE SUPPORT"], [rx, 2, "CROP LAMP"]]
	for p in plates:
		_label(p[2], Vector2(p[0] + 6, slot_y.call(p[1]) + 70), Vector2(100, 14), 8, Palette.INK, false,
			HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)


# ============================================================================
# Player actions (only call the sim)
# ============================================================================
func _live() -> OutpostSim:
	return SimState.sim if SimState.running and not SimState.paused else null

func _press_camera(cam: String) -> void:
	var s := _live()
	if s:
		s.toggle_camera(cam)
		Sfx.play("camera")

func _press_shelter() -> void:
	var s := _live()
	if s:
		s.toggle_shelter_door()
		Sfx.play("door_open" if s.shelter_door_open else "door_close")

func _press_recall() -> void:
	var s := _live()
	if s:
		s.recall_crew()
		Sfx.play("recall")

func _press_dish() -> void:
	Sfx.play("click")
	var s := _live()
	if s: s.set_dish(not s.dish)

func _press_ask() -> void:
	var s := _live()
	if s and s.send_message("ask_earth"):
		_alert("Message sent to Earth... arriving in %d s" % int(s.message_delay_sec()), "comms")
		Sfx.play("msg_sent")

func _press_send() -> void:
	var s := _live()
	if s and s.send_message("discovery"):
		_alert("Sending the discovery... arrives in %d s" % int(s.message_delay_sec()), "comms")
		Sfx.play("msg_sent")

func _press_heater() -> void:
	Sfx.play("click")
	var s := _live()
	if s: s.set_heater((s.heater + 1) % 3)

func _press_life() -> void:
	Sfx.play("click")
	var s := _live()
	if s: s.set_life_support((s.life_support + 1) % 3)

func _press_lamp() -> void:
	Sfx.play("click")
	var s := _live()
	if s: s.set_crop_lamp(not s.crop_lamp)

func _toggle_pause() -> void:
	if Game.flow:
		Game.open_panel("pause")
	elif SimState.running:
		SimState.paused = not SimState.paused

func _toggle_speed() -> void:
	SimState.speed = 2.0 if SimState.speed == 1.0 else 1.0


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6: _press_camera(CAMS[k.keycode - KEY_1])
		KEY_H: _press_heater()
		KEY_L: _press_life()
		KEY_C: _press_lamp()
		KEY_D: _press_dish()
		KEY_Q: _press_ask()
		KEY_T: _press_send()
		KEY_SPACE: _press_shelter()
		KEY_R: _press_recall()
		KEY_ESCAPE:
			if not Game.flow: _toggle_pause()
		KEY_F2: _toggle_speed()
		KEY_ENTER, KEY_KP_ENTER:
			if not SimState.running and not Game.flow: _start_night()


# ============================================================================
# Night flow: briefing -> night -> debrief
# ============================================================================
func _clear_overlay() -> void:
	for ch in overlay_body.get_children():
		ch.queue_free()


func _ov_label(text: String, size: int, bold := false, color := Palette.INK) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(660, 0)
	l.add_theme_font_override("font", FONT_B if bold else FONT_R)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	overlay_body.add_child(l)
	return l


func _ov_buttons(items: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	overlay_body.add_child(row)
	for it in items:
		var b := Button.new()
		b.text = it[0]
		b.custom_minimum_size = Vector2(150, 48)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_override("font", FONT_B)
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", Palette.INK)
		b.add_theme_color_override("font_hover_color", Palette.INK)
		b.add_theme_stylebox_override("normal", _style(Palette.STATUS_WARN, Palette.INK, 3))
		b.add_theme_stylebox_override("hover", _style(Palette.HIGHLIGHT, Palette.INK, 3))
		b.add_theme_stylebox_override("pressed", _style(Palette.STATUS_WARN_SHADE, Palette.INK, 3))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.pressed.connect(it[1])
		row.add_child(b)


func _show_briefing() -> void:
	var cfg := SimState.load_night(night_id)
	briefing_open = true
	_clear_overlay()
	overlay.visible = true
	_ov_label("NIGHT %d · %s" % [night_id, cfg.title.to_upper() if cfg else "?"], 24, true)
	if cfg:
		_ov_label(cfg.briefing_text, 16)
		for ev in cfg.hazard_events:
			if ev.is_real() and ev.real_date != "":
				_ov_label("REAL EVENT: %s · %s" % [ev.real_date, ev.source_name], 8, false, Palette.BASE_PLUM)
				break
		_ov_label("GOAL: KEEP EVERYONE SAFE UNTIL 06:00", 16, true)
	_ov_buttons([["< PREV", func() -> void: _change_night(-1)], ["START", _start_night], ["NEXT >", func() -> void: _change_night(1)]])
	_ov_label("ENTER = START · 1-6 CAMERAS · SPACE DOOR · R RECALL · H HEAT · L AIR · C LAMP", 8, false, Palette.BASE_PLUM)


func _change_night(step: int) -> void:
	night_id = clampi(night_id + step, 1, Progression.NIGHT_COUNT)
	_show_briefing()


func _start_night() -> void:
	overlay.visible = false              # hide first: night_started may open the guide popup
	briefing_open = false
	if SimState.start_night(night_id):
		for ch in alert_box.get_children():
			ch.queue_free()


func _on_night_started(cfg: NightConfig) -> void:
	SimState.sim.alert.connect(_alert)
	clock_night.text = "NIGHT %d · %s" % [cfg.id, _theme_short(cfg)]
	# the scroll fits 5 lines: 2 for the main goal, up to 3 bonus goals (+)
	var goal_lines := PackedStringArray(["KEEP EVERYONE", "SAFE TO 06:00"])
	for g in cfg.bonus_goals:
		goal_lines.append("+" + _bonus_short(g))
	scroll_lines.text = "\n".join(goal_lines)
	ctl["lamp"].disabled = not cfg.food_enabled
	for k in ["dish", "ask", "send"]:
		ctl[k].disabled = cfg.comms_delay_real_min <= 0.0
	ctl["send"].disabled = not cfg.bonus_goals.has("discovery_sent")
	ctl["shelter"].disabled = not cfg.unlocked_plots.has("shelter")
	Sfx.loop("wind_loop", true, -14.0)
	_place_hint_arrow(cfg)
	if Game.flow and not Progression.seen_guides.has(cfg.id) and Strings.has("guide.%d" % cfg.id):
		_show_guide(cfg)


func _on_night_ended(report: Dictionary) -> void:
	_clear_overlay()
	overlay.visible = true
	banner.visible = false
	hint_arrow.visible = false
	Sfx.loop("wind_loop", false)
	Sfx.loop("static_loop", false)
	var cfg := SimState.config
	# D-08 Debrief: what happened, why, tip, did you know + source, stars, materials
	if report.won:
		Sfx.play("sunrise")
		_ov_label("SUNRISE! YOU MADE IT", 24, true, Palette.STATUS_OK_SHADE)
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 16)
		overlay_body.add_child(r)
		r.add_child(Ui.stars(int(report.stars)))
		r.add_child(Ui.image("icon_materials"))
		r.add_child(Ui.label("+%d" % report.materials, 24, true))
		var met := PackedStringArray()
		for g in report.bonus.keys():
			met.append(("[X] " if report.bonus[g] else "[ ] ") + Strings.t("bonus." + g))
		_ov_label("\n".join(met), 16)
		_ov_label("WHY IT WORKED: " + cfg.debrief_why, 16)
		_ov_label("TIP: " + cfg.debrief_tip, 16)
		get_tree().create_timer(0.6).timeout.connect(func() -> void: Sfx.play("star"))
		get_tree().create_timer(1.1).timeout.connect(func() -> void: Sfx.play("materials"))
	else:
		Sfx.play("evacuate")
		_ov_label(Strings.t("evacuate"), 16, true, Palette.STATUS_DANGER_SHADE)
		_ov_label("WHAT HAPPENED: " + Strings.t("lose.%s.what" % report.reason), 24, true)
		_ov_label("WHY: " + Strings.t("lose.%s.why" % report.reason), 16)
		_ov_label("TIP: " + Strings.t("lose.%s.tip" % report.reason), 16)
		_ov_label("Your upgrades are kept. Nothing earned tonight counts.", 8, false, Palette.BASE_PLUM)
	_ov_label("DID YOU KNOW? " + cfg.did_you_know + "  (SOURCE: " + cfg.did_you_know_source + ")", 8, false, Palette.BASE_PLUM)
	if Game.flow:
		if report.won:
			var label := "MISSION COMPLETE!" if cfg.id >= Progression.NIGHT_COUNT else "CONTINUE"
			_ov_buttons([[label, func() -> void: Game.night_finished(true)]])
		else:
			_ov_buttons([["RETRY NIGHT", func() -> void: Game.night_finished(false)]])
	elif report.won:
		_ov_buttons([["RETRY", _show_briefing], ["NEXT NIGHT", func() -> void: _change_night(1)]])
	else:
		_ov_buttons([["RETRY NIGHT", _show_briefing]])


# ---------------------------------------------------------------- guide popups + hints
## First-time guide popup (max two sentences) for what is new tonight. The night waits.
func _show_guide(cfg: NightConfig) -> void:
	SimState.paused = true
	_clear_overlay()
	overlay.visible = true
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	overlay_body.add_child(head)
	head.add_child(Ui.image("portrait_mission_control"))
	head.add_child(Ui.label("NEW TONIGHT", 24, true))
	_ov_label(Strings.t("guide.%d" % cfg.id), 16)
	_ov_buttons([["GOT IT!", func() -> void:
		Progression.seen_guides.append(cfg.id)
		Progression.save_game()
		overlay.visible = false
		SimState.paused = false]])


## P-03 After 2 fails on the same night, an arrow points at the control that matters most.
const HINT_TARGET := {1: "heater", 2: "life", 3: "shelter", 4: "recall", 5: "heater", 6: "shelter", 7: "send"}

func _place_hint_arrow(cfg: NightConfig) -> void:
	hint_arrow.visible = false
	if not Progression.show_hint_arrow(cfg.id):
		return
	var target: Button = ctl.get(HINT_TARGET.get(cfg.id, "heater"))
	if target == null:
		return
	hint_arrow.visible = true
	hint_arrow.position = target.position + Vector2(target.size.x / 2 - 32, -70)
	_alert("Mission Control: " + cfg.debrief_tip, "info")


func _show_hint() -> void:
	var cfg := SimState.config if SimState.config else SimState.load_night(night_id)
	if cfg:
		_alert("Hint: " + cfg.debrief_tip, "info")


func _theme_short(cfg: NightConfig) -> String:
	const SHORT := {1: "POWER", 2: "AIR + FOOD", 3: "RADIATION", 4: "COMMS", 5: "DUST STORM", 6: "FLARE", 7: "FINALE"}
	return SHORT.get(cfg.id, cfg.theme.to_upper())


func _bonus_short(g: String) -> String:
	const SHORT := {"battery_20": "BATTERY 20%", "food_grew": "GROW FOOD", "shelter_fast": "SHELTER FAST",
		"all_inside_end": "ALL INSIDE", "discovery_sent": "SEND FINDING"}
	return SHORT.get(g, g)


# ============================================================================
# Alerts
# ============================================================================
const ALERT_ICON := {"particles": "dose", "comms_loss": "comms", "eva": "info", "co2": "co2", "cold": "cold",
	"dust": "dust", "thump": "thump", "flare": "flare", "dose": "dose", "battery": "battery", "comms": "comms",
	"hungry": "hungry", "info": "info"}
const ALERT_SOUND := {"battery": "low_battery", "flare": "flare_alarm", "thump": "thump", "comms": "msg_received"}

func _alert(text: String, kind: String) -> void:
	var icon: String = ALERT_ICON.get(kind, "info")
	var l := PanelContainer.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_stylebox_override("panel", Ui.nine("ui_popup", 12))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	l.add_child(row)
	row.add_child(Ui.image("alert_" + icon))
	var lab := Ui.label(text, 16, false, Palette.INK, 400)
	lab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lab)
	alert_box.add_child(l)
	Sfx.play(ALERT_SOUND.get(icon, "click"), -4.0)
	while alert_box.get_child_count() > 3:          # never more than 3 on screen
		alert_box.get_child(0).free()
	l.set_meta("expires", Time.get_ticks_msec() + int(ALERT_SECONDS * 1000.0))


func _update_windows(s: OutpostSim) -> void:
	var h := 18.0
	var dust := 0.0
	var flare := 0.0
	if s != null and not briefing_open:
		h = 18.0 + 12.0 * s.clock_sec / s.balance.night_length_sec
		dust = s.hazard.dust
		flare = s.hazard.flare
	for w in windows:
		w.set_state(h, dust, flare)


func _prune_alerts() -> void:
	var now := Time.get_ticks_msec()
	for c in alert_box.get_children():
		if not c.is_queued_for_deletion() and now >= int(c.get_meta("expires", 0)):
			c.queue_free()


# ============================================================================
# Per-frame updates
# ============================================================================
func _process(delta: float) -> void:
	_prune_alerts()
	var s := SimState.sim
	_update_windows(s)
	pause_label.visible = SimState.paused and not Game.flow
	if s == null:
		return
	# clock + battery + forecast
	clock_time.text = s.clock_string()
	var k := clampi(ceili(s.battery / 10.0), 0, 10)
	batt_atlas.atlas = batt_tex_low if s.battery < s.balance.battery_bonus_pct else batt_tex_ok
	batt_atlas.region = Rect2(0, 0, maxi(k * 43, 1), 36)
	batt_fill.visible = k > 0
	var lasts := s.forecast_empty_at() >= s.balance.night_length_sec
	forecast_icon.texture = tex_sun if lasts else tex_moon
	forecast_l1.text = "LASTS PAST" if lasts else "LASTS UNTIL"
	forecast_l2.text = "SUNRISE" if lasts else s.clock_string(s.forecast_empty_at())
	# monitors: first camera on -> monitor 1, second -> monitor 2
	for i in 2:
		var cam: String = s.cameras_on[i] if i < s.cameras_on.size() else ""
		feeds[i].cam = cam
		feeds[i].queue_redraw()
		monitor_sprites[i].texture = mon_on if cam != "" else mon_off
		nameplates[i].text = CAM_NAME.get(cam, "OFF")
	for j in 6:
		_set_lit(cam_buttons[j], s.cameras_on.has(CAMS[j]))
	# control labels show their state in words too (not colour only)
	ctl["heater"].text = "HEAT\n" + HEATER_TXT[s.heater]
	ctl["life"].text = "AIR\n" + LS_TXT[s.life_support]
	ctl["lamp"].text = "LAMP\n" + ("ON" if s.crop_lamp else "OFF")
	_set_lit(ctl["lamp"], s.crop_lamp)
	ctl["dish"].text = "DISH" if not s.dish else "ON"
	_set_lit(ctl["dish"], s.dish)
	ctl["shelter"].text = "DOOR\n" + ("OPEN" if s.shelter_door_open else ("SHUT..." if s.door_closing_left > 0.0 else "CLOSED"))
	_set_lit(ctl["shelter"], s.shelter_door_open)
	# particle countdown banner (the warning window)
	var wait := SimState.director.seconds_until_particles() if SimState.director else -1.0
	banner.visible = SimState.running and s.flare_alarm_at >= 0.0 and wait > 0.0
	if banner.visible:
		banner.text = "PARTICLES IN %d S - GET EVERYONE TO THE SHELTER!" % ceili(wait)
	meter_panel.queue_redraw()
	# hint arrow bobs (AL-04, 2 frames)
	if hint_arrow.visible:
		hint_t += delta
		hint_arrow.texture = Assets.frame("ui_hint_arrow", int(hint_t * 3.0) % 2)
	# make the invisible danger audible: soft dose ticks while particles arrive
	if SimState.running and not SimState.paused and s.hazard.particles > 0.0:
		tick_t += delta * (1.0 + 4.0 * s.hazard.particles)
		if tick_t > 0.5:
			tick_t = 0.0
			Sfx.play("dose_tick", -6.0)
	Sfx.loop("static_loop", SimState.running and s.hazard.comms_loss > 0.0, -12.0)
	# fan spins; slower when the CO2 filter clogs
	fan_timer += delta * SimState.speed
	var period := 0.3 if s.hazard.co2 > 0.0 else 0.08
	if fan_timer >= period:
		fan_timer = 0.0
		fan_frame = 1 - fan_frame
		fan_atlas.region = Rect2(fan_frame * 160, 0, 160, 210)


# ============================================================================
# Camera feeds (CF-01..CF-11): the feed art + crew sprites + overlays, all from Assets
# ============================================================================
class FeedView extends Control:
	var cam: String = ""
	var t := 0.0
	const ROOMS := {"sky_radar": ["outside"], "airlock": ["airlock"], "solar_field": ["solar_field", "outside"],
		"shelter": ["shelter"], "life_support": ["life_support"], "greenhouse": ["greenhouse"]}
	const OUTSIDE := ["solar_field", "outside", "comms_dish"]

	func _process(delta: float) -> void:
		t += delta

	func _bg(s: OutpostSim) -> String:
		match cam:
			"sky_radar":
				var glowing: bool = s.hazard.flare > 0.0 or (s.flare_alarm_at >= 0.0 and SimState.director.seconds_until_particles() > 0.0)
				return "cam_sky_radar_glow" if glowing else "cam_sky_radar"
			"airlock":
				for c in s.crew:
					if c.walk_left > 0.0 and (c.room == "airlock" or OUTSIDE.has(c.room)):
						return "cam_airlock_open"
				return "cam_airlock"
			"solar_field": return "cam_solar_field_dusty" if s.hazard.dust > 0.0 else "cam_solar_field"
			"shelter": return "cam_shelter" if s.shelter_door_open else "cam_shelter_closed"
			"life_support": return "cam_life_support_slow" if s.hazard.co2 > 0.0 else "cam_life_support"
			"greenhouse": return "cam_greenhouse_on" if s.crop_lamp else "cam_greenhouse_off"
		return "cam_off"

	func _draw() -> void:
		var font: Font = preload("res://assets/fonts/Silkscreen-Regular.ttf")
		var s: OutpostSim = SimState.sim
		if cam == "" or s == null:
			draw_texture(Assets.tex("cam_off"), Vector2.ZERO)
			return
		draw_texture(Assets.tex(_bg(s)), Vector2.ZERO)
		# shelter door sliding shut (CF-11)
		if cam == "shelter" and s.door_closing_left > 0.0:
			var total: float = s.balance.door_close_sec[clampi(int(s.levels.get("shelter", 1)) - 1, 0, 2)]
			var k := clampi(int((1.0 - s.door_closing_left / total) * 4.0), 0, 3)
			draw_texture(Assets.frame("cam_shelter_door_anim", k), Vector2(150, -10))
		# radar blip for a crewmate on EVA (CF-10): "it's just Carlo!"
		if cam == "sky_radar":
			var i := 0
			for c in s.crew:
				if OUTSIDE.has(c.room):
					var ang := t * 0.8 + i * 2.1
					draw_texture(Assets.frame("fx_radar_blip", int(t * 3.0) % 2), Vector2(160, 90) + Vector2(cos(ang), sin(ang)) * 50.0 - Vector2(8, 8))
					draw_string(font, Vector2(8, 168), "BLIP = " + str(c.id).to_upper() + " OUTSIDE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.HIGHLIGHT)
					i += 1
		# crew in view (CH-02..CH-06 sprites; EVA suit outside)
		var x := 24.0
		for c in s.crew:
			var room: String = c.room
			if ROOMS[cam].has(room):
				var sheet := "crew_%s_eva" % c.id if OUTSIDE.has(room) or room == "airlock" else "crew_%s" % c.id
				var walking: bool = c.walk_left > 0.0
				var f := (2 + int(t * 8.0) % 4) if walking and Assets.frame_count(sheet) >= 6 else (1 + int(t * 8.0) % 4 if walking else int(t * 2.0) % 2)
				var tex := Assets.frame(sheet, f)
				draw_texture_rect(tex, Rect2(x, 112, 48, 48), false)
				draw_string(font, Vector2(x, 108), str(c.id).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.HIGHLIGHT)
				x += 60
		# dust haze on outside cameras (CF-09)
		if cam in ["solar_field", "sky_radar", "airlock"] and s.hazard.dust > 0.0:
			draw_texture(Assets.tex("fx_dust_haze"), Vector2.ZERO, Color(1, 1, 1, clampf(s.hazard.dust, 0.0, 1.0)))
		# static when the link is weak (CF-08)
		if s.hazard.comms_loss > 0.0:
			draw_texture(Assets.frame("fx_static", int(t * 12.0) % 4), Vector2.ZERO, Color(1, 1, 1, clampf(s.hazard.comms_loss, 0.2, 1.0)))
		if cam == "shelter":
			var door := "OPEN" if s.shelter_door_open else ("CLOSING" if s.door_closing_left > 0.0 else "CLOSED")
			draw_string(font, Vector2(200, 20), "DOOR: " + door, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.HIGHLIGHT)
		draw_string(font, Vector2(260, 172), s.clock_string(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.HIGHLIGHT)


# ============================================================================
# Meter panel contents (DK-09)
# ============================================================================
class MeterPanel extends Control:
	var fr: Font
	var fb: Font
	var icons: Dictionary = {}
	const CREW_COL := {"lani": Palette.CREW_LANI, "maya": Palette.CREW_MAYA, "mateo": Palette.CREW_MATEO, "carlo": Palette.CREW_CARLO}

	func setup(r: Font, b: Font, oxy: Texture2D, dose: Texture2D, comms: Texture2D, food: Texture2D) -> void:
		fr = r
		fb = b
		icons = {"oxygen": oxy, "dose": dose, "comms": comms, "food": food}

	func _bar(x: float, y: float, w: float, h: float, frac: float, col: Color) -> void:
		draw_rect(Rect2(x, y, w, h), Color("33203A"))
		draw_rect(Rect2(x, y, w, h), Palette.BASE_MAUVE, false, 1.0)
		if frac > 0.0:
			draw_rect(Rect2(x + 2, y + 2, (w - 4) * clampf(frac, 0.0, 1.0), h - 4), col)

	func _draw() -> void:
		var s: OutpostSim = SimState.sim
		if s == null:
			return
		var cfg := s.config
		var meter := "battery"
		if cfg.visible_meters.size() > 0:
			meter = cfg.visible_meters[0]
		elif cfg.food_enabled:
			meter = "oxygen"
		var blue := Palette.SKY_HAZE
		# row 1: tonight's meter
		match meter:
			"oxygen":
				draw_texture(icons.oxygen, Vector2(12, 10))
				draw_string(fr, Vector2(68, 16), "OXYGEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, blue)
				_bar(68, 20, 112, 14, s.oxygen / 100.0, Palette.SKY_HAZE)
				draw_string(fr, Vector2(68, 54), "%d%%" % int(s.oxygen), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, blue)
			"dose":
				draw_texture(icons.dose, Vector2(12, 10))
				draw_string(fr, Vector2(68, 16), "MAX DOSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, blue)
				_bar(68, 20, 112, 14, s.max_dose() / s.balance.dose_limit_xrays, Palette.STATUS_WARN)
				draw_string(fr, Vector2(68, 54), "%.1f X-RAYS" % s.max_dose(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, blue)
			"comms":
				draw_texture(icons.comms, Vector2(12, 10))
				draw_string(fr, Vector2(68, 16), "LINK TO EARTH", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, blue)
				_bar(68, 20, 112, 14, s.comms / 100.0, Palette.SKY_INDIGO)
				draw_string(fr, Vector2(68, 54), "%d%%" % int(s.comms), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, blue)
			_:
				draw_string(fb, Vector2(12, 40), "ALL SYSTEMS OK", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, blue)
		# row 2: crew doses on dose nights, otherwise food
		if meter == "dose":
			var i := 0
			for c in s.crew:
				var x := 12 + (i % 2) * 84
				var y := 64 + (i / 2) * 24
				draw_rect(Rect2(x, y, 22, 22), CREW_COL.get(c.id, Palette.HIGHLIGHT))
				draw_rect(Rect2(x, y, 22, 22), Palette.INK, false, 1.0)
				_bar(x + 28, y + 7, 52, 8, c.dose / s.balance.dose_limit_xrays, Palette.STATUS_WARN)
				i += 1
		elif cfg.food_enabled:
			draw_texture(icons.food, Vector2(12, 64))
			draw_string(fr, Vector2(68, 88), "FOOD: %d" % s.food, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, blue)
			draw_string(fr, Vector2(68, 104), "LAMP %d/%d S" % [int(s.crop_lamp_on_sec), int(s.balance.crop_min_sec)], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, blue)
		else:
			draw_string(fr, Vector2(12, 92), "CREW: %d INSIDE" % s.crew_inside_count(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, blue)
