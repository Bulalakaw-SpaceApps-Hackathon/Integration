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
const HEATER_TXT := ["OFF", "LOW", "MID", "HIGH"]   # index = level + 1 (OFF = -1)
const LS_TXT := ["OFF", "LOW", "NORM", "HIGH"]
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
var radio: PanelContainer
var radio_icon: TextureRect
var radio_label: Label
var radio_until := 0
var signal_strip: SignalStrip       # Earth <-> Mars light-time strip, shown while a message flies
var juice: JuiceLayer               # sparks, pop-up words, flashes (on top of everything)
var shake_amt := 0.0
var board: MalfBoard                 # Malfunction board on the scroll (night)
var diagnose_btn: Button
var stars_strip: StarsStrip
var scan_buttons: Array[Button] = []
var diag_box: PanelContainer
var debrief_more: VBoxContainer
var locked_text: Dictionary = {}     # control -> "LOCKED" text while it is locked tonight
var blink_t := 0.0
var cam_badges: Array[TextureRect] = []   # "something needs you here" marker, top-right of each camera button
var answer_box: PanelContainer
var answer_crew := ""
var ads: Array[Control] = [null, null]  # sponsor message covering monitor 0 / 1
var help_box: PanelContainer
var tut_box: PanelContainer
var tut_label: Label
var tut_next: Button
var tut_step := 0
var guide_mode := 0                    # > 0 while the small "New tonight" strip is up
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
	b.add_theme_color_override("font_disabled_color", Palette.HIGHLIGHT)
	# BT-01 ui_button.png frames: 0 normal, 1 pressed / lit, 2 disabled
	var m := 8 if rect.size.x < 60 else 14
	b.add_theme_stylebox_override("normal", _btn_sb(m, 0))
	b.add_theme_stylebox_override("hover", _btn_sb(m, 1))
	b.add_theme_stylebox_override("pressed", _btn_sb(m, 1))
	b.add_theme_stylebox_override("disabled", _btn_sb(m, 2))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(on_press)
	add_child(b)
	return b


func _set_lit(b: Button, lit: bool) -> void:
	## "On" controls get the yellow style, so their state is visible (plus their text says ON/OFF).
	b.add_theme_stylebox_override("normal", _btn_sb(8 if b.size.x < 60 else 14, 1 if lit else 0))


var _sb_cache: Dictionary = {}

func _btn_sb(margin: int, frame: int) -> StyleBoxTexture:
	var key := margin * 10 + frame
	if not _sb_cache.has(key):
		var sb := Ui.nine("ui_button", margin, frame)
		sb.set_content_margin_all(2)
		_sb_cache[key] = sb
	return _sb_cache[key]


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
		f.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx := i
		f.tapped.connect(func(p: Vector2) -> void: _feed_tap(idx, p))
		add_child(f)
		feeds.append(f)
	for i in 2:
		monitor_sprites.append(_tex("desk_monitor.png", Vector2(229 + i * 470, 258)))
		var mi := i
		var sb := _button("SCAN", Rect2(245 + i * 470 + 254, 290, 62, 20), 8, func() -> void: _press_scan(mi))
		sb.tooltip_text = "Look for a clue here (costs a little battery)"
		scan_buttons.append(sb)
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
	board = MalfBoard.new()
	board.position = Vector2(1088, 47)
	board.size = Vector2(154, 93)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board)
	juice = JuiceLayer.new()
	juice.size = Vector2(1280, 720)
	juice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child.call_deferred(juice)        # added last, so it draws over the desk
	signal_strip = SignalStrip.new()
	signal_strip.position = Vector2(130, 116)
	signal_strip.size = Vector2(236, 30)
	signal_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(signal_strip)
	diagnose_btn = _button("DIAGNOSE", Rect2(1086, 140, 158, 22), 8, _open_diagnose)
	diagnose_btn.tooltip_text = "Pick the cause you think is right"
	stars_strip = StarsStrip.new()
	stars_strip.position = Vector2(130, 92)
	stars_strip.size = Vector2(236, 22)
	stars_strip.mouse_filter = Control.MOUSE_FILTER_STOP
	stars_strip.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_show_help("stars"))
	add_child(stars_strip)

	# meter panel
	_tex("desk_meter_panel.png", Vector2(16, 576))
	meter_panel = MeterPanel.new()
	meter_panel.position = Vector2(16, 576)
	meter_panel.size = Vector2(192, 120)
	meter_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_panel.setup(FONT_R, FONT_B, load(S + "ui_meter_oxygen.png"), load(S + "ui_meter_dose.png"),
		load(S + "ui_meter_comms.png"), load(S + "ui_meter_food.png"))
	add_child(meter_panel)
	_button("<", Rect2(140, 672, 26, 22), 8, func() -> void: meter_panel.flip(-1)).tooltip_text = "Previous stats page"
	_button(">", Rect2(170, 672, 26, 22), 8, func() -> void: meter_panel.flip(1)).tooltip_text = "Next stats page"

	# camera buttons (BT-02 stand-ins)
	for k in 6:
		var cam: String = CAMS[k]
		var b := _button("%d %s" % [k + 1, CAM_SHORT[cam]], Rect2(322 + k * 108, 538, 96, 96), 8,
			func() -> void: _press_camera(cam))
		b.icon = Assets.tex("icon_cam_" + cam)
		var badge := TextureRect.new()
		badge.texture = Assets.frame("ui_attention", 0)
		badge.position = Vector2(96 - 22, -6)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.visible = false
		b.add_child(badge)
		cam_badges.append(badge)
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
	alert_box.position = Vector2(400, 74)    # under the battery, over the windows: never over the monitors
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

	_build_help_buttons()              # before the overlay, so popups always cover them
	alert_box.move_to_front()          # alerts sit above the little "?" icons
	banner.move_to_front()
	radio = PanelContainer.new()
	radio.add_theme_stylebox_override("panel", Ui.nine("ui_popup", 8))
	# the radio line is the first row of the alert column, so they stack and never overlap
	radio.custom_minimum_size = Vector2(456, 0)
	radio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radio.visible = false
	alert_box.add_child(radio)
	alert_box.move_child(radio, 0)
	var rh := HBoxContainer.new()
	rh.add_theme_constant_override("separation", 6)
	radio.add_child(rh)
	radio_icon = TextureRect.new()
	radio_icon.custom_minimum_size = Vector2(16, 16)
	radio_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	radio_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rh.add_child(radio_icon)
	radio_label = Ui.label("", 8, true, Palette.INK, 420)
	rh.add_child(radio_label)

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
	_build_tutorial_box()


# ---------------------------------------------------------------- "?" help on every control
const HELP_SPOTS := {"battery": Vector2(812, 70), "forecast": Vector2(1030, 34), "clock": Vector2(338, 66),
	"cameras": Vector2(962, 540), "monitors": Vector2(548, 262), "shelter": Vector2(152, 218), "recall": Vector2(152, 316),
	"comms": Vector2(152, 414), "heater": Vector2(1218, 218), "life": Vector2(1218, 316), "lamp": Vector2(1218, 414),
	"scroll": Vector2(1232, 170), "meters": Vector2(186, 580)}

func _build_help_buttons() -> void:
	for key in HELP_SPOTS:
		var k: String = key
		var b := TextureButton.new()
		b.texture_normal = Assets.tex("icon_help")
		b.position = HELP_SPOTS[k]
		b.size = Vector2(20, 20)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = "What is this?"
		b.pressed.connect(func() -> void:
			Sfx.play("click")
			_show_help(k))
		add_child(b)
	help_box = PanelContainer.new()
	help_box.add_theme_stylebox_override("panel", Ui.nine("ui_popup", 12))
	help_box.position = Vector2(390, 300)
	help_box.custom_minimum_size = Vector2(500, 0)
	help_box.visible = false
	add_child(help_box)


func _show_help(key: String) -> void:
	for ch in help_box.get_children():
		ch.queue_free()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	help_box.add_child(v)
	v.add_child(Ui.label(Strings.t("help." + key), 16, false, Palette.INK, 470))
	var ok := _button("OK", Rect2(0, 0, 120, 40), 16, func() -> void:
		help_box.visible = false
		if SimState.running and Game.panels.is_empty():
			SimState.paused = false)
	ok.reparent(v)
	ok.custom_minimum_size = Vector2(120, 40)
	help_box.visible = true
	help_box.move_to_front()
	if SimState.running:
		SimState.paused = true


# ---------------------------------------------------------------- guided Night 1
## [text key, target control rect, wait condition]. The clock is frozen until the last step.
func _tut_steps() -> Array:
	return [
		["tut.1", Rect2(378, 22, 456, 48), "next"],
		["tut.2", Rect2(846, 26, 200, 40), "next"],
		["tut.3", cam_buttons[2].get_rect(), "camera"],
		["tut.4", ctl["heater"].get_rect(), "heater"],
		["tut.5", Rect2(846, 26, 200, 40), "next"],
		["tut.6", Rect2(feeds[0].position + Vector2(150, 90), Vector2(100, 70)), "fault"],
		["tut.7", cam_buttons[4].get_rect(), "request"],
		["tut.8", Rect2(feeds[0].position, Vector2(160, 90)), "discovery"],
		["tut.10", Rect2(1058, 2, 212, 196), "next"],
		["tut.11", scan_buttons[0].get_rect(), "scan"],
		["tut.12", diagnose_btn.get_rect(), "diagnose"],
		["tut.9", Rect2(1058, 2, 212, 196), "start"],
	]


func _build_tutorial_box() -> void:
	tut_box = PanelContainer.new()
	tut_box.add_theme_stylebox_override("panel", Ui.nine("ui_popup", 12))
	tut_box.position = Vector2(214, 638)
	tut_box.custom_minimum_size = Vector2(852, 76)
	tut_box.visible = false
	add_child(tut_box)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	tut_box.add_child(h)
	h.add_child(Ui.image("head_lani" if false else "alert_info"))
	tut_label = Ui.label("", 16, false, Palette.INK, 640)
	tut_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(tut_label)
	tut_next = _button("NEXT", Rect2(0, 0, 120, 44), 16, _tut_advance)
	tut_next.reparent(h)
	tut_next.custom_minimum_size = Vector2(120, 44)
	tut_next.size_flags_vertical = Control.SIZE_SHRINK_CENTER


## Keep the strip on screen however many lines the text needs.
func _fit_tut_box() -> void:
	tut_box.reset_size()
	tut_box.position.y = 716.0 - tut_box.size.y


func _start_tutorial() -> void:
	tut_step = 0
	SimState.frozen = true
	tut_box.visible = true
	tut_box.move_to_front()
	_fit_tut_box.call_deferred()
	_tut_show()


func _tut_show() -> void:
	var st: Array = _tut_steps()[tut_step]
	tut_label.text = Strings.t(st[0])
	tut_next.visible = st[2] in ["next", "start"]
	tut_next.text = "START!" if st[2] == "start" else "NEXT"
	_fit_tut_box.call_deferred()
	_point_at(st[1])
	var s := SimState.sim
	match st[2]:
		"fault":
			if not s.cameras_on.has("solar_field"):
				s.toggle_camera("solar_field")
			s.add_fault("loose_cable")
		"request":
			s.add_request("lani", Strings.t("tut.request").trim_prefix("Lani: "), {"battery": -4, "materials": 1}, {}, 9999.0)
		"scan":
			if not s.cameras_on.has("solar_field"):
				s.toggle_camera("solar_field")
		"discovery":
			var d: Dictionary = SimState.night_extras(1).get("discovery", {})
			if not s.cameras_on.has("solar_field"):
				s.toggle_camera("solar_field")
			var p: Array = d.get("pos", [70, 60])
			s.place_discovery("solar_field", Vector2(p[0], p[1]), d.get("title", "DISCOVERY"), d.get("text", ""))


func _tut_advance() -> void:
	Sfx.play("click")
	if guide_mode > 0:
		Progression.seen_guides.append(guide_mode)
		Progression.save_game()
		guide_mode = 0
		tut_box.visible = false
		SimState.frozen = false
		return
	tut_step += 1
	if tut_step >= _tut_steps().size():
		tut_box.visible = false
		hint_arrow.visible = false
		SimState.frozen = false
		Progression.tutorial_done = true
		Progression.save_game()
		return
	_tut_show()


func _tut_check(s: OutpostSim) -> void:
	if not tut_box.visible or guide_mode > 0:
		return
	var st: Array = _tut_steps()[tut_step]
	var done := false
	match st[2]:
		"camera": done = s.cameras_on.has("solar_field")
		"heater": done = s.heater == 0
		"fault": done = not s.fault_active("loose_cable")
		"request": done = s.open_request_for("lani").is_empty()
		"discovery": done = s.discovery_found()
		"scan": done = s.has_malfunction() and s.malf.clues[0].found
		"diagnose": done = s.malfunction_solved()
	if done:
		_tut_advance()


func _point_at(r: Rect2) -> void:
	hint_arrow.visible = true
	hint_arrow.flip_v = r.position.y < 150          # top-of-screen targets: arrow below, pointing up
	if hint_arrow.flip_v:
		hint_arrow.position = Vector2(r.get_center().x - 32, r.end.y + 4)
	else:
		hint_arrow.position = Vector2(r.get_center().x - 32, r.position.y - 66)
	hint_arrow.move_to_front()


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

func _hint_used(control: String) -> void:
	if hint_arrow.visible and not tut_box.visible and SimState.config and HINT_TARGET.get(SimState.config.id, "") == control:
		hint_arrow.visible = false


func _press_shelter() -> void:
	_hint_used("shelter")
	var s := _live()
	if s:
		s.toggle_shelter_door()
		Sfx.play("door_open" if s.shelter_door_open else "door_close")

func _press_recall() -> void:
	_hint_used("recall")
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
		_alert("Question sent! Light takes %d min to reach Earth, and %d min to come back." % [int(s.light_minutes()), int(s.light_minutes())], "comms")
		Sfx.play("msg_sent")

func _press_send() -> void:
	_hint_used("send")
	var s := _live()
	if s and s.send_message("discovery"):
		_alert("Sending the discovery... arrives in %d s" % int(s.message_delay_sec()), "comms")
		Sfx.play("msg_sent")

func _press_heater() -> void:
	_hint_used("heater")
	Sfx.play("click")
	var s := _live()
	if s: s.set_heater(s.heater + 1 if s.heater < 2 else -1)   # OFF > LOW > MID > HIGH > OFF

func _press_life() -> void:
	_hint_used("life")
	Sfx.play("click")
	var s := _live()
	if s: s.set_life_support(s.life_support + 1 if s.life_support < 2 else -1)

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
			if ch != radio:
				ch.queue_free()


func _on_night_started(cfg: NightConfig) -> void:
	SimState.sim.alert.connect(_alert)
	meter_panel.reset_page(cfg)
	clock_night.text = "NIGHT %d · %s" % [cfg.id, _theme_short(cfg)]
	# the scroll fits 5 lines: 2 for the main goal, up to 3 bonus goals (+)
	var s0 := SimState.sim
	scroll_title.text = "MALFUNCTION" if s0.has_malfunction() else "TONIGHT"
	scroll_lines.visible = not s0.has_malfunction()
	scroll_lines.text = "SAFE TO 06:00\nFIND SCIENCE"
	board.visible = s0.has_malfunction()
	diagnose_btn.visible = s0.has_malfunction()
	s0.radio.connect(_radio)
	s0.clue_found.connect(_clue_found)
	var beat := SimState.story_beat(cfg.id)
	if beat.has("open"):
		_radio.call_deferred(str(beat.open))
	if s0.has_malfunction():
		_alert.call_deferred(Strings.t("malf.start") % s0.malf.title, "info")
	ctl["lamp"].disabled = not cfg.food_enabled
	for k in ["dish", "ask", "send"]:
		ctl[k].disabled = cfg.comms_delay_real_min <= 0.0
	ctl["send"].disabled = not cfg.bonus_goals.has("discovery_sent")
	ctl["shelter"].disabled = not cfg.unlocked_plots.has("shelter")
	locked_text.clear()
	for k in ["shelter", "lamp", "dish", "ask", "send"]:
		if ctl[k].disabled:
			locked_text[k] = "LOCK" if k in ["dish", "ask", "send"] else "LOCKED\nNIGHT %d" % _unlock_night(k)
	var s := SimState.sim
	s.crew_said.connect(_crew_said)
	s.request_started.connect(_request_started)
	s.fault_started.connect(func(f: Dictionary) -> void:
		Sfx.play("thump")
		_shake(6.0)
		var p := _fx_pos(str(f.cam), f.pos)
		juice.sparks(p, 18, Palette.STATUS_WARN)
		juice.pop(p, "BROKEN!", Palette.STATUS_DANGER))
	s.malfunction_fixed.connect(func(_c: Dictionary) -> void:
		juice.flash(Palette.STATUS_OK)
		juice.sparks(board.position + board.size / 2.0, 30, Palette.STATUS_WARN)
		juice.pop(board.position + Vector2(board.size.x / 2.0, board.size.y + 10), "SOLVED!", Palette.STATUS_OK))
	s.sponsor_ad.connect(_show_ad)
	_close_answer()
	for i in 2:
		_close_ad(i)
	Sfx.loop("wind_loop", true, -14.0)
	_place_hint_arrow(cfg)
	if SimState.tutorial_tonight:
		_start_tutorial()
	elif Game.flow and not Progression.seen_guides.has(cfg.id) and Strings.has("guide.%d" % cfg.id):
		_show_guide(cfg)


func _on_night_ended(report: Dictionary) -> void:
	_clear_overlay()
	overlay.visible = true
	banner.visible = false
	hint_arrow.visible = false
	tut_box.visible = false
	help_box.visible = false
	if task:
		task.queue_free()
		task = null
	_close_answer()
	for i in 2:
		_close_ad(i)
	Sfx.loop("wind_loop", false)
	Sfx.loop("static_loop", false)
	var cfg := SimState.config
	# D-08 Debrief (one screen): 3 stars with reasons, the Malfunction answer, the Discovery; MORE for clues
	var beat := SimState.story_beat(cfg.id)
	if report.won:
		Sfx.play("sunrise")
		_ov_label("SUNRISE! YOU MADE IT", 24, true, Palette.STATUS_OK_SHADE)
		get_tree().create_timer(0.6).timeout.connect(func() -> void: Sfx.play("star"))
		get_tree().create_timer(1.1).timeout.connect(func() -> void: Sfx.play("materials"))
	else:
		Sfx.play("evacuate")
		_ov_label(Strings.t("evacuate"), 16, true, Palette.STATUS_DANGER_SHADE)
		_ov_label("WHAT HAPPENED: " + Strings.t("lose.%s.what" % report.reason) + " WHY: " + Strings.t("lose.%s.why" % report.reason), 8, true)
		_ov_label("TIP: " + Strings.t("lose.%s.tip" % report.reason), 8, true)
	var stars_row := VBoxContainer.new()
	stars_row.add_theme_constant_override("separation", 2)
	overlay_body.add_child(stars_row)
	var won: bool = report.won
	var lines := [
		[won, "SURVIVE", "Reached 06:00." if won else "Didn't reach 06:00 this time."],
		[won and report.star_science, "SCIENCE", "Malfunction solved and discovery found." if report.star_science else _science_miss(report)],
		[won and report.star_challenge, "CHALLENGE", Strings.t("challenge." + str(report.challenge))],
	]
	for l in lines:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 8)
		stars_row.add_child(r)
		var st := Ui.image("ui_star_full" if l[0] else "ui_star_empty")
		st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.custom_minimum_size = Vector2(24, 24)
		st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.add_child(st)
		r.add_child(Ui.label("%s: %s" % [l[1], l[2]], 8, true, Palette.INK, 560))
	if won:
		var m := HBoxContainer.new()
		m.add_child(Ui.image("icon_materials"))
		m.add_child(Ui.label("+%d MATERIALS" % report.materials, 16, true))
		overlay_body.add_child(m)
	var mf: Dictionary = report.get("malfunction", {})
	if not mf.is_empty():
		var answer := ""
		for c in mf.causes:
			if c.id == mf["true"]:
				answer = c.name
		_ov_label("MALFUNCTION: IT WAS THE %s. %s" % [answer, mf.why], 8, true, Palette.BASE_PLUM)
	if report.get("discovery_found", false):
		_ov_label("DISCOVERY: %s: %s" % [report.discovery.title, report.discovery.text], 8, false, Palette.BASE_PLUM)
	if won and beat.has("close"):
		_ov_label(str(beat.close), 8, true, Palette.SKY_INDIGO)
	debrief_more = VBoxContainer.new()
	debrief_more.visible = false
	overlay_body.add_child(debrief_more)
	if not mf.is_empty():
		var found := PackedStringArray()
		for k in mf.clues:
			if k.found:
				found.append("- %s (%s)" % [k.text, "always right" if int(k.reliability) >= 5 else "right %d in 5" % int(k.reliability)])
		debrief_more.add_child(Ui.label("CLUES YOU FOUND:\n" + ("\n".join(found) if not found.is_empty() else "none. Try SCAN next time!"), 8, false, Palette.INK, 640))
	debrief_more.add_child(Ui.label("DID YOU KNOW? " + cfg.did_you_know + " (SOURCE: " + cfg.did_you_know_source + ")", 8, false, Palette.BASE_PLUM, 640))
	if Game.flow:
		if report.won:
			var label := "MISSION COMPLETE!" if cfg.id >= Progression.NIGHT_COUNT else "CONTINUE"
			_ov_buttons([["MORE", _toggle_more], [label, func() -> void: Game.night_finished(true)]])
		else:
			_ov_buttons([["MORE", _toggle_more], ["RETRY NIGHT", func() -> void: Game.night_finished(false)]])
	elif report.won:
		_ov_buttons([["RETRY", _show_briefing], ["NEXT NIGHT", func() -> void: _change_night(1)]])
	else:
		_ov_buttons([["RETRY NIGHT", _show_briefing]])


func _debrief_extras(report: Dictionary) -> void:
	var lines := PackedStringArray()
	if report.get("discovery_found", false):
		lines.append("SCIENCE: %s! %s" % [report.discovery.title, report.discovery.text])
	elif not report.get("discovery", {}).is_empty():
		lines.append("SCIENCE: the discovery was missed. Watch for shiny things on the cameras!")
	if int(report.get("faults_total", 0)) > 0:
		lines.append("PROBLEMS FIXED: %d OF %d" % [report.faults_fixed, report.faults_total])
	if report.get("sponsor", false):
		lines.append("SPONSOR PAID: +%d MATERIALS%s" % [Balance.config.sponsor_reward, "" if report.won else " (ONLY IF YOU SURVIVE)"])
	if not lines.is_empty():
		_ov_label("\n".join(lines), 8, true, Palette.BASE_PLUM)


func _toggle_more() -> void:
	if debrief_more:
		debrief_more.visible = not debrief_more.visible


func _science_miss(report: Dictionary) -> String:
	var mf: Dictionary = report.get("malfunction", {})
	var miss := PackedStringArray()
	if not mf.is_empty() and not mf.solved:
		miss.append("the malfunction wasn't solved")
	if not report.get("discovery_found", false):
		miss.append("the discovery wasn't found")
	return "Missed: " + " and ".join(miss) + "."


# ---------------------------------------------------------------- guide popups + hints
## First-time guide popup (max two sentences) for what is new tonight. The night waits.
func _show_guide(cfg: NightConfig) -> void:
	SimState.frozen = true                   # clock waits; the desk stays visible
	guide_mode = cfg.id
	tut_label.text = "NEW TONIGHT: " + Strings.t("guide.%d" % cfg.id)
	tut_next.text = "GOT IT!"
	tut_next.visible = true
	tut_box.visible = true
	tut_box.move_to_front()
	_fit_tut_box.call_deferred()


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


func _unlock_night(control: String) -> int:
	for n in range(1, Progression.NIGHT_COUNT + 1):
		var c := SimState.load_night(n)
		if c == null:
			continue
		match control:
			"shelter": if c.unlocked_plots.has("shelter"): return n
			"lamp": if c.food_enabled: return n
			_: if c.comms_delay_real_min > 0.0: return n
	return 0


# ---------------------------------------------------------------- Tasks (hands-on repairs)
var task: TaskGame

func _open_task(kind: String) -> void:
	if task != null:
		return
	var s := SimState.sim
	task = TaskGame.new(kind, s.hazard.dust > 0.0 or s.hazard.flare > 0.0)
	_add_under_popups(task)
	alert_box.move_to_front()
	Sfx.play("click")
	task.finished.connect(func(ok: bool) -> void:
		if ok and SimState.sim:
			SimState.sim.complete_task(kind)
			Game.toast("FIXED! " + Strings.t("task.%s.fact" % kind))
			var fp := _fx_pos(OutpostSim.FAULTS[kind].cam, OutpostSim.FAULTS[kind].pos)
			juice.sparks(fp, 20, Palette.STATUS_OK)
			juice.pop(fp, "FIXED!", Palette.STATUS_OK)
		task.queue_free()
		task = null)


# ---------------------------------------------------------------- Malfunction: radio, clues, scan, diagnose
func _radio(text: String) -> void:
	radio_icon.texture = Assets.tex("portrait_mission_control")
	var stamp := ""
	if SimState.sim:
		stamp = " " + Strings.t("signal.stamp") % int(round(SimState.sim.light_minutes()))
	radio_label.text = (text if text.begins_with("Mission Control") else "MISSION CONTROL: " + text) + stamp
	radio.visible = true
	radio_until = Time.get_ticks_msec() + 7000
	Sfx.play("msg_received", -8.0)


func _clue_found(k: Dictionary) -> void:
	Sfx.play("star", -4.0)
	var rel := int(k.get("reliability", 4))
	var how := "ALWAYS RIGHT" if rel >= 5 else "RIGHT %d IN 5 TIMES" % rel
	_alert(Strings.t("malf.clue") % ["%s (%s)" % [str(k.text), how]], "info")


func _press_scan(i: int) -> void:
	var s := _live()
	if s == null:
		return
	var cam: String = feeds[i].cam
	var r := s.scan(cam)
	if r.is_empty():
		return
	Sfx.play("camera")
	if r.get("empty", false):
		_alert(Strings.t("malf.scan_empty"), "info")


func _open_diagnose() -> void:
	var s := _live()
	if s == null or not s.has_malfunction() or s.malf.solved:
		return
	_close_diagnose()
	diag_box = PanelContainer.new()
	diag_box.add_theme_stylebox_override("panel", Ui.nine("ui_popup", 12))
	diag_box.position = Vector2(760, 150)
	diag_box.custom_minimum_size = Vector2(480, 0)
	add_child(diag_box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	diag_box.add_child(v)
	v.add_child(Ui.label("WHAT IS THE CAUSE? " + str(s.malf.title), 8, true, Palette.INK, 450))
	for c in s.malf.causes:
		var cid: String = c.id
		var txt := "%s · %s" % [c.name, "NOT IT" if c.crossed else MalfBoard.word(c.p)]
		var b := _button(txt, Rect2(0, 0, 450, 36), 8, func() -> void:
			var ss := _live()
			if ss:
				var right := ss.diagnose(cid)
				Sfx.play("upgrade" if right else "evacuate")
				if not right:
					_shake(5.0)
					juice.pop(board.position + Vector2(board.size.x / 2.0, board.size.y + 10), "-%d%% BATTERY" % int(ss.balance.wrong_diagnosis_cost), Palette.STATUS_DANGER)
			_close_diagnose())
		b.reparent(v)
		b.custom_minimum_size = Vector2(450, 36)
		b.disabled = c.crossed
	var cancel := _button("NOT YET", Rect2(0, 0, 160, 32), 8, _close_diagnose)
	cancel.reparent(v)
	cancel.custom_minimum_size = Vector2(160, 32)
	v.add_child(Ui.label("A wrong guess costs %d%% battery, but crosses that cause off." % int(s.balance.wrong_diagnosis_cost), 8, false, Palette.BASE_PLUM, 450))


func _close_diagnose() -> void:
	if diag_box:
		diag_box.queue_free()
		diag_box = null


# ---------------------------------------------------------------- crew talk + requests
## Crew chatter goes on ONE radio line under the battery (replaced, never stacked).
func _crew_said(crew_id: String, text: String) -> void:
	radio_icon.texture = Assets.tex("head_" + crew_id)
	radio_label.text = "%s: %s" % [crew_id.to_upper(), text]
	radio.visible = true
	radio_until = Time.get_ticks_msec() + 4500


func _request_started(r: Dictionary) -> void:
	var s := SimState.sim
	var cam := s.crew_cam(r.crew)
	var where := Strings.t("cam." + cam) if cam != "" else "BASE"
	Sfx.play("recall")
	_alert(Strings.t("crew.calling") % [str(r.crew).to_upper(), where], "crew:" + str(r.crew))


func _cam_needs_you(s: OutpostSim, cam: String) -> bool:
	if not s.faults_on_cam(cam).is_empty():
		return true
	if not s.discovery.is_empty() and not s.discovery.found and s.discovery.cam == cam:
		return true
	for r in s.requests:
		if r.answer == "" and s.crew_cam(r.crew) == cam:
			return true
	return false


## The player tapped a camera picture (local position inside the 320x180 feed).
func _feed_tap(i: int, p: Vector2) -> void:
	var s := _live()
	if s == null or ads[i] != null:
		return
	var cam: String = feeds[i].cam
	if cam == "":
		return
	for f in s.faults_on_cam(cam):
		if p.distance_to(f.pos) < 34.0:
			_open_task(str(f.kind))
			return
	if not s.discovery.is_empty() and not s.discovery.found and s.discovery.cam == cam and p.distance_to(s.discovery.pos) < 34.0:
		if s.collect_discovery():
			Sfx.play("star")
			var dp: Vector2 = feeds[i].position + s.discovery.pos
			juice.sparks(dp, 26, Palette.STATUS_WARN)
			juice.pop(dp, "DISCOVERY!", Palette.STATUS_WARN)
		return
	for c in feeds[i].crew_rects:
		if Rect2(c.rect).grow(6).has_point(p) and not s.open_request_for(c.id).is_empty():
			_open_answer(i, c.id)
			return


func _open_answer(i: int, crew_id: String) -> void:
	_close_answer()
	var r := SimState.sim.open_request_for(crew_id)
	answer_crew = crew_id
	answer_box = PanelContainer.new()
	answer_box.add_theme_stylebox_override("panel", Ui.nine("ui_popup", 12))
	answer_box.position = feeds[i].position + Vector2(4, 4)
	answer_box.custom_minimum_size = Vector2(312, 0)
	_add_under_popups(answer_box)
	var v := VBoxContainer.new()
	answer_box.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	head.add_child(Ui.image("head_" + crew_id))
	head.add_child(Ui.label(crew_id.to_upper() + " ASKS:", 8, true))
	v.add_child(Ui.label(r.text, 8, false, Palette.INK, 290))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	for yes in [true, false]:
		var b := _button("YES" if yes else "NO", Rect2(0, 0, 96, 32), 16, func() -> void:
			var s := _live()
			if s:
				s.answer_request(crew_id, yes)
				Sfx.play("click")
			_close_answer())
		b.reparent(row)
		b.custom_minimum_size = Vector2(96, 32)


## Ads and answer boxes appear during the night but must stay UNDER alerts and big popups.
func _add_under_popups(node: Control) -> void:
	add_child(node)
	move_child(node, alert_box.get_index())   # under alerts, the "?" stays under them too


func _close_answer() -> void:
	if answer_box:
		answer_box.queue_free()
		answer_box = null
	answer_crew = ""


# ---------------------------------------------------------------- sponsor messages
func _show_ad() -> void:
	if ads[0] != null or ads[1] != null or overlay.visible:
		return                                   # one sponsor message at a time
	var i := randi() % 2
	var brands: Array = []
	var f := FileAccess.open("res://data/night_extras.json", FileAccess.READ)
	if f:
		var d: Variant = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			brands = d.get("sponsors", [])
	var brand: String = brands[(SimState.config.id - 1) % brands.size()] if not brands.is_empty() else "SPONSOR"
	var ad := TextureRect.new()
	ad.texture = Assets.tex("ad_%d" % (randi() % 3 + 1))
	ad.position = feeds[i].position
	ad.size = Vector2(320, 180)
	ad.mouse_filter = Control.MOUSE_FILTER_STOP
	_add_under_popups(ad)
	var l := Ui.label(brand, 16, true, Palette.INK, 280)
	l.position = Vector2(20, 96)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ad.add_child(l)
	var l2 := Ui.label("SPONSOR MESSAGE", 8, true, Palette.INK)
	l2.position = Vector2(10, 10)
	ad.add_child(l2)
	var lg := Ui.image("sponsor_logo_%d" % ((SimState.config.id - 1) % maxi(brands.size(), 1) + 1))
	lg.position = Vector2(136, 22)
	ad.add_child(lg)
	var l3 := Ui.label("TAP X TO CLOSE", 8, true, Palette.INK, 280)
	l3.position = Vector2(20, 150)
	l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ad.add_child(l3)
	ads[i] = ad
	Sfx.play("msg_received", -6.0)
	var idx := i
	get_tree().create_timer(SimState.sim.balance.sponsor_close_delay_sec).timeout.connect(func() -> void:
		if ads[idx] == ad and is_instance_valid(ad):
			var x := _button("X", Rect2(282, 6, 32, 32), 16, func() -> void: _close_ad(idx))
			x.reparent(ad, false)                  # keep (282, 6) INSIDE the ad, not desk coordinates
			x.position = Vector2(282, 6)
			x.text = "X"
			x.size = Vector2(32, 32))


func _close_ad(i: int) -> void:
	if ads[i] != null:
		if is_instance_valid(ads[i]):
			ads[i].queue_free()
		ads[i] = null
		if SimState.sim:
			SimState.sim.sponsor_ads_closed += 1


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
	if kind == "thump":
		_shake(9.0)
	elif kind == "flare":
		_shake(4.0)
		if juice: juice.flash(Palette.STATUS_WARN)
	var icon: String = ALERT_ICON.get(kind, "info")
	var icon_asset := "alert_" + icon
	if kind.begins_with("crew:"):
		icon = "crew"
		icon_asset = "head_" + kind.substr(5)
	var l := PanelContainer.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := Ui.nine("ui_popup", 8)
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	l.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	l.add_child(row)
	var ic := Ui.image(icon_asset)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(28, 28)
	row.add_child(ic)
	# crew radio chatter is one small line; real alerts are big
	var lab := Ui.label(text, 8, true, Palette.INK, 400)
	lab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lab)
	alert_box.add_child(l)
	if icon != "crew":
		Sfx.play(ALERT_SOUND.get(icon, "click"), -4.0)
	while alert_box.get_child_count() > 3:          # radio line + never more than 2 alerts
		alert_box.get_child(1).free()
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
		if c == radio:
			continue
		if not c.is_queued_for_deletion() and now >= int(c.get_meta("expires", 0)):
			c.queue_free()


# ============================================================================
# Per-frame updates
# ============================================================================
func _process(delta: float) -> void:
	_prune_alerts()
	if shake_amt > 0.0:
		shake_amt = maxf(0.0, shake_amt - delta * 30.0)
		position = Vector2(randf_range(-shake_amt, shake_amt), randf_range(-shake_amt, shake_amt)) if shake_amt > 0.0 else Vector2.ZERO
	if radio.visible and Time.get_ticks_msec() > radio_until:
		radio.visible = false
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
	ctl["heater"].text = "HEAT\n" + HEATER_TXT[s.heater + 1]
	ctl["life"].text = "AIR\n" + LS_TXT[s.life_support + 1]
	_set_lit(ctl["heater"], s.heater >= 0)
	_set_lit(ctl["life"], s.life_support >= 0)
	ctl["lamp"].text = "LAMP\n" + ("ON" if s.crop_lamp else "OFF")
	_set_lit(ctl["lamp"], s.crop_lamp)
	ctl["dish"].text = "DISH" if not s.dish else "ON"
	_set_lit(ctl["dish"], s.dish)
	ctl["shelter"].text = "DOOR\n" + ("OPEN" if s.shelter_door_open else ("SHUT..." if s.door_closing_left > 0.0 else "CLOSED"))
	_set_lit(ctl["shelter"], s.shelter_door_open)
	for lk in locked_text:
		ctl[lk].text = locked_text[lk]
	# camera buttons blink "!" when something on that camera needs you
	blink_t += delta
	for j in 6:
		var cam: String = CAMS[j]
		var need := _cam_needs_you(s, cam)
		cam_buttons[j].text = "%d %s" % [j + 1, CAM_SHORT[cam]]
		var badge: TextureRect = cam_badges[j]
		badge.visible = need
		if need:
			badge.texture = Assets.frame("ui_attention", int(blink_t * 3.0) % 2)
	# particle countdown banner (the warning window)
	var wait := SimState.director.seconds_until_particles() if SimState.director else -1.0
	banner.visible = SimState.running and s.flare_alarm_at >= 0.0 and wait > 0.0
	if banner.visible:
		banner.text = "PARTICLES IN %d S - GET EVERYONE TO THE SHELTER!" % ceili(wait)
	meter_panel.queue_redraw()
	board.queue_redraw()
	signal_strip.queue_redraw()
	stars_strip.queue_redraw()
	diagnose_btn.disabled = not s.has_malfunction() or s.malf.solved or SimState.paused
	if s.has_malfunction() and s.malf.solved:
		diagnose_btn.text = "SOLVED!"
	for i in 2:
		var cam: String = feeds[i].cam
		var sbn := scan_buttons[i]
		sbn.visible = cam != "" and s.has_malfunction() and not s.malf.solved and ads[i] == null
		if sbn.visible:
			var wait_s := float(s.scan_ready_at.get(cam, 0.0)) - s.clock_sec
			sbn.disabled = wait_s > 0.0
			sbn.text = "SCAN" if wait_s <= 0.0 else "SCAN %d" % ceili(wait_s)
	# a crewmate who walked away can't answer from that camera any more
	if answer_crew != "" and s.open_request_for(answer_crew).is_empty():
		_close_answer()
	_tut_check(s)
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
	signal tapped(pos: Vector2)
	var cam: String = ""
	var t := 0.0
	var crew_rects: Array[Dictionary] = []    # {id, rect} where each crewmate was drawn (for taps)

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			tapped.emit(mb.position)
			accept_event()
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
		# camera problems (sparks) and tonight's discovery (sparkle): tap them
		for f in s.faults_on_cam(cam):
			var fp: Vector2 = f.pos
			draw_texture(Assets.frame("fx_fault", int(t * 6.0) % 2), fp - Vector2(16, 16))
			draw_arc(fp, 20.0 + 3.0 * sin(t * 6.0), 0, TAU, 24, Palette.STATUS_DANGER, 2.0)
			draw_string(font, fp + Vector2(-20, 32), "TAP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.HIGHLIGHT)
		if not s.discovery.is_empty() and not s.discovery.found and s.discovery.cam == cam:
			var dp: Vector2 = s.discovery.pos
			draw_texture(Assets.frame("fx_discovery", int(t * 4.0) % 2), dp - Vector2(16, 16))
		# a clue on this camera right now: magnifier + "looking..." bar while it gets logged
		for k in s.clues_on_cam(cam):
			draw_texture(Assets.frame("fx_clue", int(t * 3.0) % 2), Vector2(144, 40))
			draw_rect(Rect2(120, 78, 80, 6), Palette.INK)
			draw_rect(Rect2(120, 78, 80 * clampf(float(k.watch) / OutpostSim.CLUE_WATCH_SEC, 0.0, 1.0), 6), Palette.STATUS_WARN)
			draw_string(font, Vector2(120, 96), "CLUE!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.STATUS_WARN)
		# crew in view (CH-02..CH-06 sprites; EVA suit outside)
		crew_rects.clear()
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
				crew_rects.append({"id": c.id, "rect": Rect2(x, 100, 48, 60)})
				if not s.open_request_for(c.id).is_empty():
					draw_texture(Assets.frame("fx_request", int(t * 3.0) % 2), Vector2(x + 30, 84))
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
	## DK-09 stats panel with pages. < > buttons flip through every stat.
	var fr: Font
	var fb: Font
	var icons: Dictionary = {}
	var page := 0
	const PAGES := ["AIR", "CREW DOSE", "CREW WHERE", "RADIO", "FOOD"]
	const CREW_COL := {"lani": Palette.CREW_LANI, "maya": Palette.CREW_MAYA, "mateo": Palette.CREW_MATEO, "carlo": Palette.CREW_CARLO}
	const ROOM_SHORT := {"solar_field": "SOLAR FIELD", "outside": "OUTSIDE", "comms_dish": "COMMS DISH", "airlock": "AIRLOCK",
		"shelter": "SHELTER", "life_support": "LIFE SUPPORT", "greenhouse": "GREENHOUSE", "galley": "GALLEY"}

	func setup(r: Font, b: Font, oxy: Texture2D, dose: Texture2D, comms: Texture2D, food: Texture2D) -> void:
		fr = r
		fb = b
		icons = {"oxygen": oxy, "dose": dose, "comms": comms, "food": food}

	## Start each night on the page that matters tonight.
	func reset_page(cfg: NightConfig) -> void:
		page = 0
		if cfg.visible_meters.has("dose"):
			page = 1
		elif cfg.visible_meters.has("comms"):
			page = 3
		elif not cfg.food_enabled and cfg.visible_meters.is_empty():
			page = 2
		queue_redraw()

	func flip(step: int) -> void:
		page = posmod(page + step, PAGES.size())
		queue_redraw()

	func _bar(x: float, y: float, w: float, h: float, frac: float, col: Color) -> void:
		draw_rect(Rect2(x, y, w, h), Color("33203A"))
		draw_rect(Rect2(x, y, w, h), Palette.BASE_MAUVE, false, 1.0)
		if frac > 0.0:
			draw_rect(Rect2(x + 2, y + 2, (w - 4) * clampf(frac, 0.0, 1.0), h - 4), col)

	func _draw() -> void:
		var s: OutpostSim = SimState.sim
		if s == null:
			return
		var blue := Palette.SKY_HAZE
		match PAGES[page]:
			"AIR":
				draw_texture(icons.oxygen, Vector2(12, 10))
				draw_string(fr, Vector2(68, 16), "OXYGEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, blue)
				_bar(68, 20, 112, 14, s.oxygen / 100.0, Palette.SKY_HAZE)
				draw_string(fr, Vector2(68, 54), "%d%%" % int(s.oxygen), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, blue)
				var rate := s.oxygen_per_sec()
				draw_string(fr, Vector2(12, 80), ("RISING" if rate >= 0.0 else "FALLING") + " %.2f%%/S" % absf(rate), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, blue)
			"CREW DOSE":
				draw_texture(icons.dose, Vector2(12, 4))
				draw_string(fr, Vector2(68, 14), "MAX %.1f / %d X-RAYS" % [s.max_dose(), int(s.balance.dose_limit_xrays)], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, blue)
				var i := 0
				for c in s.crew:
					var x := 68 + (i % 2) * 60
					var y := 22 + (i / 2) * 22
					draw_texture_rect(Assets.tex("head_" + c.id), Rect2(x, y, 18, 18), false)
					_bar(x + 20, y + 5, 36, 8, c.dose / s.balance.dose_limit_xrays, Palette.STATUS_WARN)
					i += 1
				draw_string(fr, Vector2(12, 80), "LIMIT %d PER CREWMATE" % int(s.balance.dose_limit_xrays), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, blue)
			"CREW WHERE":
				var j := 0
				for c in s.crew:
					var y := 8 + j * 20
					draw_texture_rect(Assets.tex("head_" + c.id), Rect2(12, y, 16, 16), false)
					var where: String = ROOM_SHORT.get(c.room, str(c.room).to_upper())
					if c.walk_left > 0.0:
						where = "> " + ROOM_SHORT.get(c.target, str(c.target).to_upper())
					draw_string(fr, Vector2(32, y + 12), "%s %s" % [str(c.id).to_upper(), where], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, blue)
					j += 1
			"RADIO":
				draw_texture(icons.comms, Vector2(12, 10))
				draw_string(fr, Vector2(68, 16), "LINK TO EARTH", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, blue)
				if s.config.comms_delay_real_min <= 0.0:
					draw_string(fr, Vector2(68, 44), "NO DISH YET", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, blue)
				else:
					_bar(68, 20, 112, 14, s.comms / 100.0, Palette.SKY_INDIGO)
					draw_string(fr, Vector2(68, 54), "%d%%" % int(s.comms), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, blue)
			"FOOD":
				draw_texture(icons.food, Vector2(12, 10))
				if s.config.food_enabled:
					draw_string(fr, Vector2(68, 32), "FOOD: %d" % s.food, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, blue)
					draw_string(fr, Vector2(68, 50), "LAMP %d/%d S" % [int(s.crop_lamp_on_sec), int(s.balance.crop_min_sec)], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, blue)
				else:
					draw_string(fr, Vector2(68, 32), "FROM NIGHT 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, blue)
		# footer: page name + number (the < > buttons sit on the right)
		draw_string(fb, Vector2(12, 112), "%s %d/%d" % [PAGES[page], page + 1, PAGES.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.HIGHLIGHT)


# ============================================================================
# Malfunction board (on the hanging scroll at night): one bar per cause
# ============================================================================
class MalfBoard extends Control:
	static func word(p: float) -> String:
		if p >= 0.75: return "VERY LIKELY"
		if p >= 0.45: return "LIKELY"
		if p >= 0.2: return "MAYBE"
		return "UNLIKELY"

	func _draw() -> void:
		var s: OutpostSim = SimState.sim
		if s == null or not s.has_malfunction():
			return
		var f: Font = Ui.FONT_R
		var fb: Font = Ui.FONT_B
		var y := 0.0
		for c in s.malf.causes:
			var name: String = c.name
			var p: float = c.p
			var done: bool = s.malf.solved and p >= 1.0
			var word_txt := "NOT IT" if c.crossed else ("SOLVED!" if done else word(p))
			var name_col := Palette.BASE_MAUVE if c.crossed else Palette.INK
			draw_string(fb, Vector2(0, y + 8), name, HORIZONTAL_ALIGNMENT_LEFT, size.x, 8, name_col)
			if c.crossed:
				var w := fb.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
				draw_line(Vector2(0, y + 4), Vector2(minf(w, size.x), y + 4), Palette.STATUS_DANGER, 1.0)
			# bar on its own line, word under the bar's right end
			draw_rect(Rect2(0, y + 11, size.x, 7), Palette.BASE_STONE)
			if not c.crossed:
				var col := Palette.STATUS_OK if done else (Palette.STATUS_WARN if p >= 0.45 else Palette.SKY_HAZE)
				draw_rect(Rect2(0, y + 11, size.x * p, 7), col)
			draw_rect(Rect2(0, y + 11, size.x, 7), Palette.INK, false, 1.0)
			draw_string(f, Vector2(0, y + 27), word_txt, HORIZONTAL_ALIGNMENT_RIGHT, size.x, 8, Palette.STATUS_DANGER_SHADE if c.crossed else Palette.INK)
			y += 31.0


# ============================================================================
# The 3 stars, live, under the clock: SURVIVE · SCIENCE · CHALLENGE
# ============================================================================
class StarsStrip extends Control:
	func _draw() -> void:
		var s: OutpostSim = SimState.sim
		if s == null:
			return
		draw_rect(Rect2(Vector2.ZERO, size), Palette.INK)
		var lit := [s.finished and s.result == "won", s.science_met(), s.challenge_met()]
		var names := ["SURVIVE", "SCIENCE", "CHALLENGE"]
		for i in 3:
			var x := 4.0 + i * 78.0
			draw_texture_rect(Assets.tex("ui_star_full" if lit[i] else "ui_star_empty"), Rect2(x, 3, 16, 16), false)
			draw_string(Ui.FONT_R, Vector2(x + 19, 15), names[i], HORIZONTAL_ALIGNMENT_LEFT, 58, 8, Palette.STATUS_WARN if lit[i] else Palette.BASE_MAUVE)


# ============================================================================
# The radio delay: a dot of light crossing from Mars to Earth (and back for a question)
# ============================================================================
class SignalStrip extends Control:
	func _draw() -> void:
		var s: OutpostSim = SimState.sim
		if s == null or s.messages.is_empty():
			return
		draw_rect(Rect2(Vector2.ZERO, size), Palette.INK)
		var x0 := 14.0
		var x1 := size.x - 14.0
		var y := 10.0
		# Mars on the left, Earth on the right
		draw_circle(Vector2(x0, y), 6.0, Palette.MARS_RUST)
		draw_circle(Vector2(x1, y), 6.0, Palette.SKY_HAZE)
		for k in range(int((x1 - x0 - 16) / 6.0)):
			draw_rect(Rect2(x0 + 9 + k * 6.0, y - 0.5, 3, 1), Palette.BASE_MAUVE)
		var m: Dictionary = s.messages[0]
		var t := s.clock_sec
		var f: float
		if t < m.turn_at:
			f = inverse_lerp(m.sent_at, m.turn_at, t)
		else:
			f = 1.0 - inverse_lerp(m.turn_at, m.arrive_at, t)
		var px := lerpf(x0 + 8, x1 - 8, clampf(f, 0.0, 1.0))
		draw_circle(Vector2(px, y), 3.0, Palette.STATUS_WARN)
		draw_circle(Vector2(px, y), 5.0, Color(Palette.STATUS_WARN, 0.35))
		var txt := Strings.t("signal.label") % int(round(s.light_minutes()))
		draw_string(Ui.FONT_R, Vector2(0, 26), txt, HORIZONTAL_ALIGNMENT_CENTER, size.x, 8, Palette.HIGHLIGHT)


func _shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)


## Where on screen a camera point is: on the monitor if that camera is showing, else its tray button.
func _fx_pos(cam: String, pos: Vector2) -> Vector2:
	for f in feeds:
		if f.cam == cam and f.visible:
			return f.position + pos
	var j := CAMS.find(cam)
	if j >= 0:
		return cam_buttons[j].get_rect().get_center()
	return Vector2(640, 360)


# ============================================================================
# Juice: sparks, pop-up words and screen flashes
# ============================================================================
class JuiceLayer extends Control:
	var parts: Array[Dictionary] = []
	var words: Array[Dictionary] = []
	var flash_col := Color.TRANSPARENT
	var flash_t := 0.0

	func sparks(p: Vector2, n: int, col: Color) -> void:
		for i in n:
			var a := randf_range(0.0, TAU)
			parts.append({"p": p, "v": Vector2.RIGHT.rotated(a) * randf_range(60.0, 220.0), "life": randf_range(0.35, 0.7), "col": col, "r": randf_range(1.5, 3.5)})

	func pop(p: Vector2, text: String, col: Color) -> void:
		words.append({"p": p, "text": text, "life": 1.2, "col": col})

	func flash(col: Color) -> void:
		flash_col = col
		flash_t = 0.5

	func _process(delta: float) -> void:
		flash_t = maxf(0.0, flash_t - delta)
		for i in range(parts.size() - 1, -1, -1):
			var q := parts[i]
			q.life -= delta
			if q.life <= 0.0:
				parts.remove_at(i)
				continue
			q.v = q.v + Vector2(0.0, 300.0 * delta)
			q.p = q.p + q.v * delta
		for i in range(words.size() - 1, -1, -1):
			words[i].life -= delta
			words[i].p = words[i].p + Vector2(0.0, -30.0 * delta)
			if words[i].life <= 0.0:
				words.remove_at(i)
		queue_redraw()

	func _draw() -> void:
		if flash_t > 0.0:
			var a := flash_t * 0.5
			draw_rect(Rect2(Vector2.ZERO, size), Color(flash_col, a * 0.5))
			draw_rect(Rect2(Vector2.ZERO, size), Color(flash_col, a), false, 12.0)
		for q in parts:
			draw_rect(Rect2(q.p - Vector2(q.r, q.r) / 2.0, Vector2(q.r, q.r)), Color(q.col, clampf(q.life * 2.0, 0.0, 1.0)))
		for w in words:
			var a := clampf(w.life * 2.0, 0.0, 1.0)
			var sz := Ui.FONT_B.get_string_size(w.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
			var at: Vector2 = w.p - Vector2(sz.x / 2.0, 0.0)
			for o in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
				draw_string(Ui.FONT_B, at + o, w.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(Palette.INK, a))
			draw_string(Ui.FONT_B, at, w.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(w.col, a))
