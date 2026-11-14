extends Node2D
## B-01..B-05 The base map (build phase, untimed).
## Walk the Commander (WASD / arrows / touch joystick) next to a plot and press E, or tap a
## plot directly, to open its upgrade card. Tap the habitat (or START NIGHT) to begin the night.
## The Morning Briefing card opens first.

const TILE := 32
const MAP := Vector2i(40, 23)
const PLOT_POS := {
	"solar": Vector2(176, 216), "battery": Vector2(336, 216), "life_support": Vector2(944, 216),
	"greenhouse": Vector2(1104, 216), "shelter": Vector2(240, 456), "suit_bay": Vector2(640, 488),
	"comms_dish": Vector2(1040, 456),
}
const PLOT_NAME := {
	"solar": "SOLAR FIELD", "battery": "BATTERY BANK", "life_support": "LIFE SUPPORT", "greenhouse": "GREENHOUSE",
	"shelter": "SHELTER & SHIELDING", "suit_bay": "SUIT BAY", "comms_dish": "COMMS DISH",
}
const PLOT_WHY := {
	"solar": "Solar panels charge the battery in the day. More panels = more power at sunset.",
	"battery": "Better batteries waste less, so every switch drains less.",
	"life_support": "Makes oxygen for the crew from Mars air. Better machines make more air for the same power.",
	"greenhouse": "Grows food while the Crop Lamp is on at night. Bigger greenhouse = more meals.",
	"shelter": "Thick walls are shielding: they block radiation. Thicker walls block more, and the door shuts faster.",
	"suit_bay": "Good suits let the crew walk back faster and block a little radiation outside.",
	"comms_dish": "A bigger dish gets messages to Earth faster and fights static.",
}
const HABITAT_POS := Vector2(640, 128)
const INTERACT_DIST := 80.0

var cfg: NightConfig
var commander: Commander
var plots: Dictionary = {}          # id -> Sprite2D
var highlight: Sprite2D
var prompt: Sprite2D
var near_target := ""               # plot id, "habitat" or ""
var hud: CanvasLayer
var hud_root: Control
var mat_label: Label
var food_label: Label
var card_layer: Control
var fx: Sprite2D
var fx_t := -1.0


func _ready() -> void:
	Commander.ensure_input_actions()
	cfg = SimState.load_night(Game.night)
	_build_ground()
	_build_bounds()
	_build_habitat()
	for id in PLOT_POS:
		_build_plot(id)
	_build_decor()
	commander = Commander.new()
	commander.position = HABITAT_POS + Vector2(0, 110)
	add_child(commander)
	highlight = Sprite2D.new()
	highlight.texture = Assets.tex("ui_plot_highlight")
	highlight.visible = false
	add_child(highlight)
	prompt = Sprite2D.new()
	prompt.texture = Assets.tex("ui_prompt_build")
	prompt.visible = false
	prompt.z_index = 10
	add_child(prompt)
	fx = Sprite2D.new()
	fx.visible = false
	fx.z_index = 11
	add_child(fx)
	_build_hud()
	Progression.changed.connect(_refresh_hud)
	_show_briefing()


# ============================================================================ world
func _build_ground() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	src.texture = Assets.tex("tiles_mars")
	src.texture_region_size = Vector2i(TILE, TILE)
	for y in 4:
		for x in 4:
			src.create_tile(Vector2i(x, y))
	ts.add_source(src, 0)
	var layer := TileMapLayer.new()
	layer.tile_set = ts
	add_child(layer)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for y in MAP.y:
		for x in MAP.x:
			var v := rng.randi_range(0, 2)
			if rng.randf() < 0.03:
				v = 3                                     # rocks
			layer.set_cell(Vector2i(x, y), 0, Vector2i(v, 0))
	# walkways: a main street under the habitat and paths to each plot row
	for x in range(3, 37):
		layer.set_cell(Vector2i(x, 10), 0, Vector2i(0, 2))
	for y in range(5, 18):
		layer.set_cell(Vector2i(20, y), 0, Vector2i(1, 2))
	layer.set_cell(Vector2i(20, 10), 0, Vector2i(2, 2))


func _build_bounds() -> void:
	var walls := StaticBody2D.new()
	add_child(walls)
	var w := MAP.x * TILE
	var h := 720
	for seg in [[Vector2(0, 0), Vector2.DOWN], [Vector2(0, h), Vector2.UP], [Vector2(0, 0), Vector2.RIGHT], [Vector2(w, 0), Vector2.LEFT]]:
		var cs := CollisionShape2D.new()
		var b := WorldBoundaryShape2D.new()
		b.normal = seg[1]
		cs.shape = b
		cs.position = seg[0]
		walls.add_child(cs)


func _solid(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	body.add_child(cs)
	add_child(body)


func _build_habitat() -> void:
	var s := Sprite2D.new()
	s.texture = Assets.tex("bld_habitat")
	s.position = HABITAT_POS
	add_child(s)
	_solid(HABITAT_POS + Vector2(0, 10), Vector2(120, 70))
	var l := Ui.label("CONTROL ROOM", 8, true, Palette.HIGHLIGHT)
	l.position = HABITAT_POS + Vector2(-44, 52)
	add_child(l)


func _build_plot(id: String) -> void:
	var s := Sprite2D.new()
	s.position = PLOT_POS[id]
	add_child(s)
	plots[id] = s
	_solid(PLOT_POS[id], Vector2(56, 52))
	var l := Ui.label(PLOT_NAME[id], 8, true, Palette.HIGHLIGHT)
	l.position = PLOT_POS[id] + Vector2(-60, 36)
	l.custom_minimum_size.x = 120
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)
	_refresh_plot(id)


func _refresh_plot(id: String) -> void:
	var s: Sprite2D = plots[id]
	if Progression.plot_unlocked(id, Game.night):
		s.texture = Assets.tex("plot_%s_l%d" % [id, int(Progression.levels.get(id, 1))])
	else:
		s.texture = Assets.tex("plot_locked")


func _build_decor() -> void:
	var spots := {"rover": Vector2(472, 330), "flag": Vector2(760, 96), "antenna": Vector2(1180, 560), "crates": Vector2(400, 600), "rocks": Vector2(860, 620)}
	for name in spots:
		var s := Sprite2D.new()
		s.texture = Assets.tex("deco_" + name)
		s.position = spots[name]
		add_child(s)


# ============================================================================ play
func _physics_process(_delta: float) -> void:
	if commander == null:
		return
	var best := ""
	var best_d := INTERACT_DIST
	var hd := commander.position.distance_to(HABITAT_POS + Vector2(0, 50))
	if hd < best_d:
		best = "habitat"
		best_d = hd
	for id in PLOT_POS:
		var d := commander.position.distance_to(PLOT_POS[id])
		if d < best_d:
			best = id
			best_d = d
	near_target = best
	if best == "" or card_layer != null:
		highlight.visible = false
		prompt.visible = false
	else:
		var p: Vector2 = HABITAT_POS if best == "habitat" else PLOT_POS[best]
		highlight.visible = best != "habitat"
		highlight.position = p
		prompt.visible = true
		prompt.position = p + Vector2(0, -58)


func _process(delta: float) -> void:
	if fx_t >= 0.0:
		fx_t += delta
		var f := int(fx_t * 12.0)
		if f >= Assets.frame_count("fx_upgrade"):
			fx_t = -1.0
			fx.visible = false
		else:
			fx.texture = Assets.frame("fx_upgrade", f)


func _unhandled_input(event: InputEvent) -> void:
	if card_layer != null:
		return
	if event.is_action_pressed("interact") and near_target != "":
		_interact(near_target)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		if Rect2(HABITAT_POS - Vector2(64, 48), Vector2(128, 96)).has_point(p):
			_interact("habitat")
			return
		for id in PLOT_POS:
			if Rect2(PLOT_POS[id] - Vector2(32, 32), Vector2(64, 64)).has_point(p):
				_interact(id)
				return


func _interact(target: String) -> void:
	Sfx.play("click")
	if target == "habitat":
		_start_night()
	else:
		_show_plot_card(target)


func _start_night() -> void:
	Game.goto("desk")


# ============================================================================ HUD
func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.theme = Game.theme
	hud.add_child(hud_root)

	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", Ui.nine("ui_panel", 12))
	bar.position = Vector2(8, 8)
	hud_root.add_child(bar)
	var row := Ui.row(bar, 18, BoxContainer.ALIGNMENT_BEGIN)
	row.add_child(Ui.label("NIGHT %d · %s" % [Game.night, cfg.title.to_upper() if cfg else ""], Ui.BODY, true))
	row.add_child(Ui.image("icon_materials"))
	mat_label = Ui.label("", Ui.BIG, true)
	row.add_child(mat_label)
	row.add_child(Ui.image("ui_meter_food"))
	food_label = Ui.label("", Ui.BIG, true)
	row.add_child(food_label)

	var tools := Ui.row(hud_root, 6)
	tools.position = Vector2(860, 8)
	tools.add_child(Ui.icon_button("icon_hint", _hint, "Hint"))
	tools.add_child(Ui.button("BRIEFING", _show_briefing, Vector2(140, 56)))
	tools.add_child(Ui.icon_button("icon_settings", func() -> void: Game.open_panel("pause"), "Pause"))
	tools.add_child(Ui.icon_button("icon_mute_on" if Progression.muted else "icon_mute_off", Game.toggle_mute, "Mute (M)"))

	var start := Ui.button("START NIGHT", _start_night, Vector2(260, 72))
	start.position = Vector2(1004, 632)
	hud_root.add_child(start)
	var help := Ui.label("WALK: WASD / ARROWS · BUILD: E OR TAP A PLOT · ESC: PAUSE", 8, true, Palette.HIGHLIGHT)
	help.position = Vector2(16, 700)
	hud_root.add_child(help)

	if DisplayServer.is_touchscreen_available():
		var joy := TouchStick.new()
		joy.position = Vector2(24, 560)
		joy.moved.connect(func(d: Vector2) -> void: commander.joystick = d)
		hud_root.add_child(joy)
	_refresh_hud()


func _refresh_hud() -> void:
	if mat_label == null:
		return
	mat_label.text = str(Progression.materials)
	var food := Progression.food
	if food < 0 and cfg and cfg.food_enabled:
		food = Balance.config.food_start
	food_label.text = str(food) if food >= 0 else "-"
	for id in plots:
		_refresh_plot(id)


func _hint() -> void:
	var cheapest := ""
	for id in PLOT_POS:
		if Progression.plot_unlocked(id, Game.night) and Progression.can_upgrade(id):
			cheapest = id
			break
	if cheapest != "":
		Game.toast("You can afford an upgrade: %s. Walk to it and press E, or tap it." % PLOT_NAME[cheapest], "info", 5.0)
	else:
		Game.toast("Win nights to earn materials. Bonus goals give extra! Tap the Control Room to start.", "info", 5.0)


func _close_card() -> void:
	if card_layer:
		card_layer.queue_free()
		card_layer = null


func _new_card(width := 760.0, asset := "ui_panel") -> VBoxContainer:
	_close_card()
	card_layer = Control.new()
	card_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.add_child(card_layer)
	Ui.dim(card_layer, 0.45)
	return Ui.card(card_layer, asset, width)


# ---------------------------------------------------------------- D-07 Morning Briefing
func _show_briefing() -> void:
	if cfg == null:
		return
	var v := _new_card(900, "ui_briefing")
	var top := Ui.row(v, 16, BoxContainer.ALIGNMENT_BEGIN)
	top.add_child(Ui.image("portrait_mission_control"))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	top.add_child(col)
	col.add_child(Ui.label("MORNING BRIEFING · NIGHT %d" % cfg.id, 8, true, Palette.BASE_PLUM))
	col.add_child(Ui.label(cfg.title.to_upper(), Ui.BIG, true, Palette.INK, 700))
	col.add_child(Ui.label(cfg.briefing_text, Ui.BODY, false, Palette.INK, 700))
	for ev in cfg.hazard_events:
		if ev.real_date != "":
			var r := Ui.row(col, 10, BoxContainer.ALIGNMENT_BEGIN)
			r.add_child(Ui.badge(ev.badge if ev.badge in ["real", "simplified"] else "real"))
			r.add_child(Ui.label("REAL EVENT: %s · %s" % [ev.real_date, ev.source_name], 8, true, Palette.BASE_PLUM, 560))
			break
	var sun := Ui.row(v, 10, BoxContainer.ALIGNMENT_BEGIN)
	sun.add_child(Ui.badge("live" if DonkiService.is_live() else "archived"))
	sun.add_child(Ui.label("TONIGHT'S REAL SUN: " + DonkiService.summary(), 8, false, Palette.INK, 700))
	v.add_child(Ui.label("GOAL: KEEP EVERYONE SAFE UNTIL 06:00", Ui.BODY, true))
	for g in cfg.bonus_goals:
		v.add_child(Ui.label("BONUS: " + Strings.t("bonus." + g), Ui.BODY, false, Palette.BASE_PLUM, 820))
	var btns := Ui.row(v)
	btns.add_child(Ui.button("LET'S BUILD", _close_card, Vector2(240, 60)))
	btns.add_child(Ui.button("START NIGHT", _start_night, Vector2(240, 60)))


# ---------------------------------------------------------------- B-02 upgrade card
func _effect(id: String, lv: int) -> String:
	var b := Balance.config
	var i := clampi(lv - 1, 0, 2)
	match id:
		"solar": return "Battery at sunset: %d%%" % int(b.solar_start[i])
		"battery": return "Every switch uses %d%% of the power" % int(round(b.battery_bank_multiplier[i] * 100.0))
		"life_support": return "Makes %d%% oxygen for the same power" % int(round(b.life_support_upgrade_multiplier[i] * 100.0))
		"greenhouse": return "Crop Lamp grows %d meals a night" % b.greenhouse_yield[i]
		"shelter":
			var t := "Shelter lets in %d%% of radiation, door shuts in %.1f s" % [int(round(b.shelter_inside_multiplier[i] * 100.0)), b.door_close_sec[i]]
			if lv >= 2:
				t += ". Whole base: %d%%" % int(round(b.habitat_shield_multiplier[i] * 100.0))
			return t
		"suit_bay": return "Crew walk back %.1fx faster, %d%% dose outside" % [b.suit_bay_speed[i], int(round(b.suit_dose_multiplier[i] * 100.0))]
		"comms_dish": return "Messages take %d%% of the time, static %d%%" % [int(round(b.dish_delay_multiplier[i] * 100.0)), int(round(b.dish_static_resist[i] * 100.0))]
	return ""


func _unlock_night(id: String) -> int:
	for n in range(1, Progression.NIGHT_COUNT + 1):
		var c := SimState.load_night(n)
		if c and c.unlocked_plots.has(id):
			return n
	return 0


func _show_plot_card(id: String) -> void:
	var v := _new_card(760)
	var lv := int(Progression.levels.get(id, 1))
	var unlocked := Progression.plot_unlocked(id, Game.night)
	var head := Ui.row(v, 16, BoxContainer.ALIGNMENT_BEGIN)
	head.add_child(Ui.image("plot_%s_l%d" % [id, lv] if unlocked else "plot_locked"))
	var col := VBoxContainer.new()
	head.add_child(col)
	col.add_child(Ui.label(PLOT_NAME[id], Ui.BIG, true))
	col.add_child(Ui.label("LEVEL %d OF 3" % lv if unlocked else "LOCKED", Ui.BODY, true, Palette.BASE_PLUM))
	v.add_child(Ui.label(PLOT_WHY[id], Ui.BODY, false, Palette.INK, 700))
	var btns := Ui.row(v)
	if not unlocked:
		v.add_child(Ui.label("UNLOCKS ON NIGHT %d." % _unlock_night(id), Ui.BODY, true, Palette.STATUS_DANGER_SHADE))
	else:
		v.add_child(Ui.label("NOW: " + _effect(id, lv), Ui.BODY, true, Palette.INK, 700))
		if lv < 3:
			var cost := Progression.upgrade_cost(id)
			v.add_child(Ui.label("NEXT: " + _effect(id, lv + 1), Ui.BODY, true, Palette.STATUS_OK_SHADE, 700))
			var cost_row := Ui.row(v, 8, BoxContainer.ALIGNMENT_BEGIN)
			cost_row.add_child(Ui.image("icon_materials"))
			cost_row.add_child(Ui.label("COSTS %d · YOU HAVE %d" % [cost, Progression.materials], Ui.BODY, true))
			var up := Ui.button("UPGRADE", func() -> void: _upgrade(id), Vector2(220, 60))
			up.disabled = not Progression.can_upgrade(id)
			btns.add_child(up)
			if up.disabled:
				v.add_child(Ui.label("Not enough materials yet. Win nights and bonus goals to earn more!", 8, false, Palette.BASE_PLUM, 700))
		else:
			v.add_child(Ui.label("MAXED OUT!", Ui.BODY, true, Palette.STATUS_OK_SHADE))
	v.move_child(btns, v.get_child_count() - 1)
	btns.add_child(Ui.button("CLOSE", _close_card, Vector2(180, 60)))


func _upgrade(id: String) -> void:
	if Progression.upgrade(id):
		Sfx.play("upgrade")
		fx.position = PLOT_POS[id]
		fx.visible = true
		fx_t = 0.0
		_refresh_plot(id)
		Game.toast("%s is now level %d!" % [PLOT_NAME[id], int(Progression.levels[id])], "info")
		_show_plot_card(id)
