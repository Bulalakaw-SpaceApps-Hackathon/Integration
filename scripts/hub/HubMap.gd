extends Node2D
## B-01..B-05 The base map (build phase, untimed).
## Walk the Commander (WASD / arrows / touch joystick) next to a plot and press E, or tap a
## plot directly, to open its upgrade card. Tap the habitat (or START NIGHT) to begin the night.
## The Morning Briefing card opens first.

const TILE := 32
const MAP := Vector2i(40, 23)
const PLOT_POS := {        # buildings are drawn at 3x: spaced so none overlap or sit on a walkway
	"solar": Vector2(130, 216), "battery": Vector2(330, 216), "life_support": Vector2(950, 216),
	"greenhouse": Vector2(1150, 216), "shelter": Vector2(240, 526), "suit_bay": Vector2(640, 526),
	"comms_dish": Vector2(1040, 526),
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
const HABITAT_POS := Vector2(640, 194)
const INTERACT_DIST := 130.0
const BSCALE := 2.0                 # one pixel size on the map (D49): buildings are 96 px (habitat 192x144), shown at 2x

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
var briefing_sun: HBoxContainer
var night_story_shown: bool = false
var fx: Sprite2D
var fx_t := -1.0
var plot_labels: Dictionary = {}
var start_button: Button
var mute_button: TextureButton
var spotlight: SpotlightOverlay
var lessons: Dictionary = {}
var anim_t := 0.0                   # building idle loops (lights, smoke, fans, waves...)
var anim_f := -1
var animated: Array[Sprite2D] = []
const ANIM_FPS := 5.0
var rover: Sprite2D                 # drives up and down the main street
var rover_dir := 1.0
var rover_wait := 0.0
var rover_anim := 0.0
const ROVER_Y := 350.0              # wheels on the main walkway (y 320-352)
const ROVER_X := Vector2(110.0, 1170.0)
const ROVER_SPEED := 42.0


func _ready() -> void:
	Commander.ensure_input_actions()
	cfg = SimState.load_night(Game.night)
	var lf := FileAccess.open("res://data/building_lessons.json", FileAccess.READ)
	if lf:
		lessons = JSON.parse_string(lf.get_as_text())
	if not Game.visited.has(Game.night):
		Game.visited[Game.night] = []
	y_sort_enabled = true                 # things lower on screen draw in front: walk behind buildings
	var light := CanvasModulate.new()
	light.color = Color(1.0, 0.95, 0.88)  # one warm, dusty Mars light over the whole map
	add_child(light)
	_build_ground()
	var marks := GroundMarks.new()
	marks.z_index = -10
	marks.habitat = HABITAT_POS
	marks.plots = PLOT_POS
	add_child(marks)
	var drift := DustDrift.new()
	drift.z_index = 20
	add_child(drift)
	_build_bounds()
	_build_habitat()
	for id in PLOT_POS:
		_build_plot(id)
	_build_decor()
	_build_debris()
	_build_rover()
	commander = Commander.new()
	commander.position = HABITAT_POS + Vector2(0, 200)
	add_child(commander)
	var blob := BlobShadow.new()
	blob.show_behind_parent = true
	commander.add_child(blob)
	highlight = Sprite2D.new()
	highlight.texture = Assets.tex("ui_plot_highlight")
	highlight.visible = false
	highlight.scale = Vector2(BSCALE, BSCALE)
	highlight.z_index = 4
	add_child(highlight)
	prompt = Sprite2D.new()
	prompt.texture = Assets.tex("ui_prompt_build")
	prompt.visible = false
	prompt.z_index = 10
	add_child(prompt)
	fx = Sprite2D.new()
	fx.visible = false
	fx.z_index = 11
	fx.scale = Vector2(BSCALE, BSCALE)
	add_child(fx)
	_build_crew()
	_build_hud()
	Progression.changed.connect(_refresh_hud)
	Game.mute_changed.connect(_refresh_mute)
	DonkiService.updated.connect(_refresh_briefing_sun)
	if Game.tutorial:
		_show_tutorial_card()
	elif not Progression.story_seen and not Progression.judge_mode:
		_show_story()
	else:
		_show_briefing()


# ============================================================================ world
func _build_ground() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE / 2, TILE / 2)     # 16 px ground art shown at 2x (D49)
	var src := TileSetAtlasSource.new()
	src.texture = Assets.tex("tiles_mars")
	src.texture_region_size = Vector2i(TILE / 2, TILE / 2)
	for y in 4:
		for x in 4:
			src.create_tile(Vector2i(x, y))
	ts.add_source(src, 0)
	var layer := TileMapLayer.new()
	layer.z_index = -20
	layer.scale = Vector2(2, 2)
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
	for y in range(9, 10):                          # control-room door down to the main street only
		layer.set_cell(Vector2i(20, y), 0, Vector2i(1, 2))
	layer.set_cell(Vector2i(20, 10), 0, Vector2i(2, 2))
	_scatter_decals(rng)


## Craters, rocks, dunes and frost from the artist tileset, kept clear of buildings and paths.
const DECALS := [Vector2i(2, 4), Vector2i(2, 5), Vector2i(2, 6), Vector2i(0, 5), Vector2i(2, 0), Vector2i(2, 1),
	Vector2i(2, 3), Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3), Vector2i(0, 6), Vector2i(0, 7)]
func _scatter_decals(rng: RandomNumberGenerator) -> void:
	var sheet := Assets.tex("tiles_mars_decals")
	var keep_out: Array[Rect2] = [Rect2(HABITAT_POS - Vector2(200, 200), Vector2(400, 320)), Rect2(40, 262, 1200, 124),
		Rect2(616, 280, 48, 80), Rect2(0, 0, 270, 80), Rect2(860, 0, 420, 90), Rect2(990, 610, 290, 110), Rect2(0, 600, 480, 120)]
	for id in PLOT_POS:
		keep_out.append(Rect2(PLOT_POS[id] - Vector2(115, 140), Vector2(230, 230)))
	keep_out.append_array(DECOR_CLEAR)
	var placed := 0
	var used: Array[Vector2] = []
	var tries := 0
	while placed < 36 and tries < 1200:
		tries += 1
		var p := Vector2(rng.randf_range(20, 1260), rng.randf_range(90, 700))
		var bad := false
		for r in keep_out:
			if r.has_point(p):
				bad = true
				break
		for q in used:                                    # spread out: no clumps of craters
			if q.distance_to(p) < 70.0:
				bad = true
				break
		if bad:
			continue
		used.append(p)
		var c: Vector2i = DECALS[rng.randi() % DECALS.size()]
		var a := AtlasTexture.new()
		a.atlas = sheet
		a.region = Rect2(c.y * 16, c.x * 16, 16, 16)
		var d := Sprite2D.new()
		d.texture = a
		d.position = p
		d.scale = Vector2.ONE * 2.0                  # one pixel size on the map (D49)
		d.flip_h = rng.randf() < 0.5
		d.z_index = -15
		add_child(d)
		placed += 1


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


func _solid(pos: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	body.add_child(cs)
	add_child(body)
	body.add_to_group("map_solid")
	return body


func _build_habitat() -> void:
	var s := Sprite2D.new()
	s.texture = Assets.frame("bld_habitat", 0)
	_animate(s, "bld_habitat")
	_stand(s, HABITAT_POS + Vector2(0, 96), BSCALE)
	_foot(s.texture, HABITAT_POS + Vector2(0, 96), BSCALE, 0.92, 54.0)   # footprint only: you can walk behind the roof
	var l := Ui.label("CONTROL ROOM", 8, true, Palette.HIGHLIGHT)
	l.z_index = 5
	l.position = HABITAT_POS + Vector2(-44, 98)
	add_child(l)


func _build_plot(id: String) -> void:
	var s := Sprite2D.new()
	plots[id] = s
	s.texture = Assets.tex("plot_locked")
	_stand(s, PLOT_POS[id] + Vector2(0, 64), BSCALE)
	var post := Sprite2D.new()
	post.texture = Assets.tex("plot_locked_post")
	_stand(post, PLOT_POS[id] + Vector2(0, 12), BSCALE)
	s.set_meta("post", post)
	s.set_meta("body", _solid(PLOT_POS[id] + Vector2(0, 40), Vector2(150, 48)))
	var l := Ui.label(PLOT_NAME[id], 8, true, Palette.HIGHLIGHT)
	l.z_index = 5
	plot_labels[id] = l
	l.position = PLOT_POS[id] + Vector2(-60, 66)
	l.custom_minimum_size.x = 120
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)
	_refresh_plot(id)


func _refresh_plot(id: String) -> void:
	var s: Sprite2D = plots[id]
	var built := Progression.plot_unlocked(id, Game.night)
	var asset := "plot_%s_l%d" % [id, int(Progression.levels.get(id, 1))] if built else "plot_locked"
	s.texture = Assets.frame(asset, 0)
	_animate(s, asset)
	s.z_index = 0 if built else -8
	var post: Sprite2D = s.get_meta("post")
	post.visible = not built
	var sh: ContactShadow = s.get_meta("shadow")
	sh.fit(s.texture)
	sh.visible = built
	if built:
		_fit_body(s.get_meta("body"), s.texture, PLOT_POS[id] + Vector2(0, 64), BSCALE, true, 0.92, 40.0)
	else:
		_fit_body(s.get_meta("body"), post.texture, PLOT_POS[id] + Vector2(0, 12), BSCALE, true, 1.8, 16.0)


func _build_decor() -> void:
	var spots := {"flag": Vector2(840, 420), "antenna": Vector2(850, 600), "crates": Vector2(420, 620),
		"rocks": Vector2(730, 628), "parol": Vector2(452, 120)}
	for name in spots:
		var s := Sprite2D.new()
		s.texture = Assets.frame("deco_" + name, 0)
		if Assets.frame_count("deco_" + name) > 1:
			_animate(s, "deco_" + name)              # flag flaps, antenna blinks, parol sways (D66)
		var k := 2.0                                 # one pixel size on the map (D49)
		var base: Vector2 = spots[name] + Vector2(0, s.texture.get_height() * k / 2.0)
		_stand(s, base, k)
		_foot(s.texture, base, k, 0.96, 22.0 if name != "parol" else 14.0)


## Ground kept clear around each decoration (flag mound, antenna, sari-sari, big rocks),
## sized so a 64 px rock or crater standing just outside still does not overlap it.
const DECOR_CLEAR: Array[Rect2] = [Rect2(720, 330, 250, 240), Rect2(740, 500, 220, 220),
	Rect2(330, 530, 190, 190), Rect2(640, 540, 190, 190)]
## Hand-placed rocks along the top (x, base y, scale).
const TOP_DEBRIS: Array[Vector3] = [Vector3(462, 276, 2.0), Vector3(852, 276, 1.0), Vector3(232, 300, 1.0),
	Vector3(1052, 300, 1.0), Vector3(18, 284, 1.0), Vector3(1262, 284, 1.0), Vector3(478, 150, 1.0)]

## Lots of small rocks and rubble standing on the ground (each with a contact shadow),
## kept off the walkway, the buildings and the HUD corners.
func _build_debris() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var keep_out: Array[Rect2] = [Rect2(HABITAT_POS - Vector2(210, 210), Vector2(420, 330)), Rect2(40, 286, 1200, 140),
		Rect2(0, 0, 280, 90), Rect2(860, 0, 420, 95), Rect2(990, 600, 290, 120), Rect2(0, 690, 520, 30)]
	for id in PLOT_POS:
		keep_out.append(Rect2(PLOT_POS[id] - Vector2(120, 145), Vector2(240, 240)))
	keep_out.append_array(DECOR_CLEAR)
	var n := Assets.frame_count("deco_debris")
	var placed := 0
	var tries := 0
	while placed < 14 and tries < 1500:
		tries += 1
		var p := Vector2(rng.randf_range(24, 1256), rng.randf_range(100, 712))
		var bad := false
		for r in keep_out:
			if r.has_point(p):
				bad = true
				break
		if bad:
			continue
		var s := Sprite2D.new()
		s.texture = Assets.frame("deco_debris", rng.randi() % n)
		s.flip_h = rng.randf() < 0.5
		var dk := 2.0                                # one pixel size on the map (D49)
		_stand(s, p, dk)
		_foot(s.texture, p, dk, 0.96, 20.0)
		placed += 1
	# a few along the top, in the gaps beside the control room and at the map edges
	for spot in TOP_DEBRIS:
		var s := Sprite2D.new()
		s.texture = Assets.frame("deco_debris", rng.randi() % n)
		s.flip_h = rng.randf() < 0.5
		_stand(s, Vector2(spot.x, spot.y), 2.0)
		_foot(s.texture, Vector2(spot.x, spot.y), 2.0, 0.96, 20.0)


## Register a sprite for the idle loop. Each gets its own phase so the base doesn't blink in unison.
func _animate(s: Sprite2D, asset: String) -> void:
	s.set_meta("asset", asset)
	if not s.has_meta("phase"):
		s.set_meta("phase", animated.size() * 3 % 4)
	if not animated.has(s):
		animated.append(s)


func _tick_animation(delta: float) -> void:
	anim_t += delta
	var f := int(anim_t * ANIM_FPS)
	if f == anim_f:
		return
	anim_f = f
	for s in animated:
		var asset: String = s.get_meta("asset")
		var n := Assets.frame_count(asset)
		if n > 1:
			s.texture = Assets.frame(asset, (f + int(s.get_meta("phase"))) % n)


func _build_rover() -> void:
	rover = Sprite2D.new()
	rover.texture = Assets.frame("hub_rover", 0)
	_stand(rover, Vector2(ROVER_X.x + 200.0, ROVER_Y), 2.0)


func _drive_rover(delta: float) -> void:
	if rover == null:
		return
	if rover_wait > 0.0:                            # a short stop at each end of the street
		rover_wait -= delta
		return
	rover.position.x += rover_dir * ROVER_SPEED * delta
	if rover.position.x > ROVER_X.y or rover.position.x < ROVER_X.x:
		rover.position.x = clampf(rover.position.x, ROVER_X.x, ROVER_X.y)
		rover_dir = -rover_dir
		rover_wait = 2.0
	rover.flip_h = rover_dir < 0.0
	rover_anim += delta
	rover.texture = Assets.frame("hub_rover", int(rover_anim * 8.0) % Assets.frame_count("hub_rover"))


# ============================================================================ play
func _physics_process(_delta: float) -> void:
	if commander == null:
		return
	var best := ""
	var best_d := INTERACT_DIST
	var hd := commander.position.distance_to(HABITAT_POS + Vector2(0, 100))
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
		highlight.visible = false                     # no box around the chosen building; the E prompt is enough
		highlight.position = p
		prompt.visible = true
		# above the building, but never up under the top HUD; the control room's sits over its door
		prompt.position = HABITAT_POS + Vector2(0, -24) if best == "habitat" else Vector2(p.x, maxf(p.y - 150.0, 118.0))


func _process(delta: float) -> void:
	_drive_rover(delta)
	_tick_animation(delta)
	if fx_t >= 0.0:
		fx_t += delta
		var f := int(fx_t * 12.0)
		if f >= Assets.frame_count("fx_upgrade"):
			fx_t = -1.0
			fx.visible = false
		else:
			fx.texture = Assets.frame("fx_upgrade", f)


func _input(event: InputEvent) -> void:
	if card_layer != null and Game.top_panel() == null and event.is_action_pressed("ui_cancel"):
		_close_card()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if card_layer != null:
		return
	if event.is_action_pressed("interact") and _crew_near() != "":
		_talk(_crew_near())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and near_target != "":
		_interact(near_target)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = get_canvas_transform().affine_inverse() * (event as InputEventMouseButton).position
		for id in crew_nodes:
			if Rect2(crew_nodes[id].position - Vector2(36, 100), Vector2(72, 108)).has_point(p):
				_talk(id)
				get_viewport().set_input_as_handled()
				return
		if Rect2(HABITAT_POS - Vector2(192, 192), Vector2(384, 288)).has_point(p):
			_interact("habitat")
			get_viewport().set_input_as_handled()
			return
		for id in PLOT_POS:
			var plot: Sprite2D = plots[id]
			var bounds := plot.transform * plot.get_rect()
			var label: Label = plot_labels[id]
			if bounds.has_point(p) or label.get_rect().has_point(p):
				_interact(id)
				get_viewport().set_input_as_handled()
				return


func _interact(target: String) -> void:
	Sfx.play("click")
	if target == "habitat":
		_start_night()
	elif Progression.plot_unlocked(target, Game.night):
		_show_building(target)
	else:
		_show_plot_card(target)


func _required() -> Array[String]:
	var out: Array[String] = []
	for id in PLOT_POS:
		if cfg and cfg.unlocked_plots.has(id):
			out.append(id)
	return out


func _visited_count() -> int:
	var n := 0
	for id in _required():
		if (Game.visited[Game.night] as Array).has(id):
			n += 1
	return n


## The Control Room opens only after the Commander has been inside every building today.
func _start_night() -> void:
	var need := _required().size()
	if _visited_count() < need and not Progression.judge_mode:
		Game.toast("Visit every building first! Walk to each one and press E (%d/%d)." % [_visited_count(), need], "info", 4.0)
		return
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

	# compact panel, top-left: tonight + resources + the big goal (small, so no building is covered)
	var bar := PanelContainer.new()
	var bsb := Ui.nine("ui_panel", 8)
	bsb.set_content_margin_all(6)
	bar.add_theme_stylebox_override("panel", bsb)
	bar.position = Vector2(6, 6)
	hud_root.add_child(bar)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	bar.add_child(col)
	col.add_child(Ui.label(("TUTORIAL · VISIT EVERY BUILDING, THEN START THE PRACTICE NIGHT" if Game.tutorial else "DAY %d OF %d · TONIGHT: %s" % [Game.night, Progression.NIGHT_COUNT, cfg.title.to_upper() if cfg else ""]), 8, true))
	var res := Ui.row(col, 6, BoxContainer.ALIGNMENT_BEGIN)
	for pair in [["icon_materials", "MATERIALS"], ["ui_meter_food", "FOOD"]]:
		var ic := Ui.image(pair[0])
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(20, 20)
		res.add_child(ic)
		var val := Ui.label("", 16, true)
		res.add_child(val)
		if pair[1] == "MATERIALS":
			mat_label = val
		else:
			food_label = val
		res.add_child(Ui.label(pair[1], 8, true, Palette.BASE_PLUM))
	var left := Progression.NIGHT_COUNT - Game.night + 1
	col.add_child(Ui.label("SHIP LANDS IN %d NIGHT%s · DISCOVERIES %d/%d" % [left, "" if left == 1 else "S",
		Progression.discoveries.size(), Progression.NIGHT_COUNT], 8, true, Palette.STATUS_OK_SHADE))

	var tools := Ui.row(hud_root, 6)
	tools.position = Vector2(876, 8)
	tools.add_child(Ui.icon_button("icon_hint", _hint, "Hint"))
	tools.add_child(Ui.button("BRIEFING", _show_briefing, Vector2(140, 64)))
	tools.add_child(Ui.icon_button("icon_settings", func() -> void: Game.open_panel("pause"), "Pause"))
	mute_button = Ui.icon_button("icon_mute_off", Game.toggle_mute, "Mute (M)")
	tools.add_child(mute_button)
	for child in tools.get_children():
		if child is TextureButton:
			child.custom_minimum_size = Vector2(64, 64)
			child.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED

	start_button = Ui.button("START NIGHT", _start_night, Vector2(260, 72))
	start_button.position = Vector2(1004, 632)
	hud_root.add_child(start_button)
	var help := Ui.label("WALK: WASD / ARROWS · BUILD: E OR TAP A PLOT · ESC: PAUSE", 8, true, Palette.HIGHLIGHT)
	help.position = Vector2(16, 700)
	hud_root.add_child(help)

	spotlight = SpotlightOverlay.new()
	hud_root.add_child(spotlight)

	_build_sponsor_panel()
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
	_refresh_mute()
	var food := Progression.food
	if food < 0 and cfg and cfg.food_enabled:
		food = Balance.config.food_start
	food_label.text = str(food) if food >= 0 else "-"
	for id in plots:
		_refresh_plot(id)
	var need := _required().size()
	var done := _visited_count()
	if start_button:
		start_button.text = "START NIGHT" if done >= need or Progression.judge_mode else "VISIT BUILDINGS %d/%d" % [done, need]
	for id in plot_labels:
		var lab: Label = plot_labels[id]
		var seen := (Game.visited[Game.night] as Array).has(id)
		lab.text = PLOT_NAME[id] + (" (VISITED)" if seen else "")
		lab.add_theme_color_override("font_color", Palette.STATUS_OK if seen else Palette.HIGHLIGHT)


func _refresh_mute() -> void:
	mute_button.texture_normal = Assets.tex("icon_mute_on" if Progression.muted else "icon_mute_off")
	mute_button.tooltip_text = "Unmute (M)" if Progression.muted else "Mute (M)"


func _hint() -> void:
	var need := _required()
	for id in need:
		if not (Game.visited[Game.night] as Array).has(id):
			Game.toast("Go inside the %s next: walk to it and press E, or tap it." % PLOT_NAME[id], "info", 5.0)
			return
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
		card_layer.hide()
		card_layer.queue_free()
		card_layer = null
		briefing_sun = null
		commander.set_physics_process(true)
	_refresh_night1_guide()


func _refresh_night1_guide() -> void:
	if spotlight == null:
		return
	if Game.night != 1 or Game.tutorial or Progression.judge_mode or card_layer != null:
		spotlight.visible = false
		return
	var visited: Array = Game.visited.get(1, [])
	if not visited.has("solar"):
		spotlight.point_at(Rect2(PLOT_POS["solar"] - Vector2(96.0, 110.0), Vector2(192.0, 180.0)),
			"Tap SOLAR FIELD to see how sunlight powers your base.")
	elif not visited.has("battery"):
		spotlight.point_at(Rect2(PLOT_POS["battery"] - Vector2(96.0, 110.0), Vector2(192.0, 180.0)),
			"Tap BATTERY BANK! Win nights to earn coins for upgrades.")
	else:
		spotlight.point_at(start_button.get_rect(),
			"Tap START NIGHT to begin your first shift!")


func _new_card(width := 760.0, asset := "ui_panel") -> VBoxContainer:
	_close_card()
	commander.joystick = Vector2.ZERO
	commander.velocity = Vector2.ZERO
	commander.set_physics_process(false)
	card_layer = Control.new()
	card_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.add_child(card_layer)
	_refresh_night1_guide()
	Ui.dim(card_layer, 0.45)
	return Ui.card(card_layer, asset, width)


func _card_scroll(parent: VBoxContainer, height: float) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = height
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	return content


# ---------------------------------------------------------------- Night 0: the tutorial day
func _show_tutorial_card() -> void:
	var v := _new_card(900, "ui_briefing")
	v.add_child(Ui.label("TUTORIAL · PRACTICE DAY", Ui.BIG, true))
	v.add_child(Ui.label(Strings.t("tut0.day1"), Ui.BODY, false, Palette.INK, 820))
	v.add_child(Ui.label(Strings.t("tut0.day2"), Ui.BODY, false, Palette.INK, 820))
	v.add_child(Ui.label(Strings.t("tut0.day3"), Ui.BODY, true, Palette.BASE_PLUM, 820))
	var btns := Ui.row(v)
	btns.add_child(Ui.button("LET'S LOOK AROUND", _close_card, Vector2(320, 60)))


# ---------------------------------------------------------------- the mission (first time only)
func _show_story() -> void:
	commander.joystick = Vector2.ZERO
	commander.velocity = Vector2.ZERO
	commander.set_physics_process(false)
	var story: CutsceneBeat = load("res://data/cutscenes/cs_00_opening.tres") as CutsceneBeat
	var player: CutscenePlayer = preload("res://scenes/CutscenePlayer.tscn").instantiate() as CutscenePlayer
	hud_root.add_child(player)
	player.continued.connect(_show_mission_instructions)
	player.skipped.connect(_show_mission_instructions)
	player.play(story)


func _show_mission_instructions(_next_route: String = "") -> void:
	commander.set_physics_process(true)
	var v := _new_card(900, "ui_briefing")
	var top := Ui.row(v, 16, BoxContainer.ALIGNMENT_BEGIN)
	top.add_child(Ui.image("portrait_mission_control"))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	top.add_child(col)
	col.add_child(Ui.label("YOUR MISSION", Ui.BIG, true))
	col.add_child(Ui.label(Strings.t("goal.story"), Ui.BODY, false, Palette.INK, 700))
	col.add_child(Ui.label(Strings.t("goal.science"), Ui.BODY, false, Palette.INK, 700))
	v.add_child(Ui.label("EVERY NIGHT: BALANCE POWER, AIR, FOOD AND RADIATION SHIELDING.", Ui.BODY, true, Palette.BASE_PLUM, 840))
	v.add_child(Ui.label("BETWEEN NIGHTS: SPEND MATERIALS TO UPGRADE YOUR BASE.", Ui.BODY, true, Palette.BASE_PLUM, 840))
	var btns := Ui.row(v)
	btns.add_child(Ui.button("I'M READY!", func() -> void:
		Progression.story_seen = true
		Progression.save_game()
		_show_briefing(), Vector2(260, 64)))


# ---------------------------------------------------------------- D-07 Morning Briefing
func _on_night_story_done() -> void:
	commander.set_physics_process(true)
	_show_briefing()


func _show_briefing() -> void:
	if cfg == null:
		return
	if not night_story_shown and not Progression.judge_mode and not Game.tutorial:
		night_story_shown = true
		commander.joystick = Vector2.ZERO
		commander.velocity = Vector2.ZERO
		commander.set_physics_process(false)
		Game.play_story(cfg.id * 2 - 1, _on_night_story_done)
		return
	var card := _new_card(980, "ui_briefing")
	var v := _card_scroll(card, 482.0)
	var top := Ui.row(v, 16, BoxContainer.ALIGNMENT_BEGIN)
	top.add_child(Ui.image("portrait_mission_control"))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	top.add_child(col)
	col.add_child(Ui.label("MORNING BRIEFING · NIGHT %d" % cfg.id, 8, true, Palette.BASE_PLUM))
	col.add_child(Ui.label(cfg.title.to_upper(), Ui.BIG, true, Palette.INK, 700))
	col.add_child(Ui.body(cfg.briefing_text, 20, false, Palette.INK, 700))
	for ev in cfg.hazard_events:
		if ev.real_date != "":
			var r := Ui.row(col, 10, BoxContainer.ALIGNMENT_BEGIN)
			r.add_child(Ui.badge(ev.badge if ev.badge in ["real", "simplified"] else "real"))
			r.add_child(Ui.body("Real event · %s · %s" % [ev.real_date, ev.source_name], 20, true, Palette.BASE_PLUM, 560))
			break
	briefing_sun = Ui.row(v, 10, BoxContainer.ALIGNMENT_BEGIN)
	_refresh_briefing_sun()
	# tonight's 3 stars (the same three every night)
	var beat := SimState.story_beat(cfg.id)
	v.add_child(Ui.label("TONIGHT'S 3 STARS", Ui.BODY, true))
	var sl := [["SURVIVE", "Keep everyone safe until 06:00"], ["SCIENCE", Strings.t("science.goal")],
		["CHALLENGE", Strings.t("challenge." + str(beat.get("challenge", "")))]]
	for l in sl:
		var r := Ui.row(v, 8, BoxContainer.ALIGNMENT_BEGIN)
		var st := Ui.image("ui_star_full")
		st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.custom_minimum_size = Vector2(20, 20)
		st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.add_child(st)
		r.add_child(Ui.body("%s · %s" % [l[0], l[1]], 20, true, Palette.INK, 780))
	v.add_child(Ui.body("Tap a building or walk up and press E. Visit each open building before starting.", 20, true, Palette.BASE_PLUM, 820))
	var btns := Ui.row(card)
	btns.add_child(Ui.button("LET'S BUILD", _close_card, Vector2(240, 64)))
	var start := Ui.button("START NIGHT", _start_night, Vector2(240, 64))
	start.disabled = _visited_count() < _required().size() and not Progression.judge_mode
	btns.add_child(start)


func _refresh_briefing_sun() -> void:
	if briefing_sun == null:
		return
	for child in briefing_sun.get_children():
		briefing_sun.remove_child(child)
		child.queue_free()
	if DonkiService.state != "loading":
		briefing_sun.add_child(Ui.badge("live" if DonkiService.is_live() else "archived"))
	briefing_sun.add_child(Ui.body(DonkiService.summary(), 20, false, Palette.INK, 700))


## Sponsor deal (Night 2+): a clickable sponsor icon at the bottom-right, above START NIGHT.
## Tapping it opens the sponsor's poster with ACCEPT / NO THANKS. No choice = no thanks.
var sponsor_icon: TextureButton
var sponsor_mark: Label
var sponsor_brand := ""
var sponsor_index := 1
var sponsor_decided := false

func _build_sponsor_panel() -> void:
	if Game.night < 2:
		return                                   # no sponsors during the guided first night
	var brands: Array = []
	var f := FileAccess.open("res://data/night_extras.json", FileAccess.READ)
	if f:
		var d: Variant = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			brands = d.get("sponsors", [])
	if brands.is_empty():
		return
	sponsor_index = (Game.night - 1) % brands.size() + 1
	sponsor_brand = brands[sponsor_index - 1]
	sponsor_decided = Progression.sponsor_answered == Game.night
	sponsor_icon = TextureButton.new()
	sponsor_icon.texture_normal = Assets.tex("sponsor_logo_%d" % sponsor_index)
	sponsor_icon.position = Vector2(1176, 552)
	sponsor_icon.ignore_texture_size = true
	sponsor_icon.custom_minimum_size = Vector2(64, 64)
	sponsor_icon.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	sponsor_icon.focus_mode = Control.FOCUS_NONE
	sponsor_icon.tooltip_text = "Sponsor offer"
	sponsor_icon.pressed.connect(func() -> void:
		Sfx.play("click")
		_show_sponsor_poster())
	hud_root.add_child(sponsor_icon)
	sponsor_mark = Ui.label("OFFER!", 8, true, Palette.HIGHLIGHT)
	sponsor_mark.position = Vector2(1236, 552)
	hud_root.add_child(sponsor_mark)
	_refresh_sponsor(false)


func _show_sponsor_poster() -> void:
	var v := _new_card(380, "ui_popup")
	var poster := Ui.image("sponsor_poster_%d" % sponsor_index)
	poster.custom_minimum_size = Vector2(300, 380)
	poster.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(poster)
	# Option B: the artist letters the brand + slogan into the poster; code only writes the offer
	var strip := ColorRect.new()
	strip.color = Color(Palette.INK, 0.72)
	strip.position = Vector2(10, 300)
	strip.size = Vector2(280, 72)
	poster.add_child(strip)
	var offer := Ui.label(Strings.t("sponsor.offer") % [sponsor_brand, Balance.config.sponsor_reward], 8, true, Palette.HIGHLIGHT, 264)
	offer.position = Vector2(18, 310)
	offer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	poster.add_child(offer)
	v.add_child(Ui.label(Strings.t("sponsor.warning"), 8, true, Palette.STATUS_DANGER_SHADE, 340))
	var row := Ui.row(v, 10)
	if sponsor_decided:
		row.add_child(Ui.button("CLOSE", _close_card, Vector2(170, 52)))
	else:
		row.add_child(Ui.button("ACCEPT +%d" % Balance.config.sponsor_reward, func() -> void: _decide_sponsor(true), Vector2(170, 52)))
		row.add_child(Ui.button("NO THANKS", func() -> void: _decide_sponsor(false), Vector2(150, 52)))


func _decide_sponsor(accept: bool) -> void:
	if sponsor_decided:
		_close_card()
		return                                   # a deal can't be changed or cancelled
	SimState.sponsor_tonight = accept
	sponsor_decided = true
	Progression.sponsor_answered = Game.night
	if accept:
		Progression.add_sponsor(sponsor_index)
	Progression.save_game()
	_close_card()
	_refresh_sponsor(true)
	var n := Progression.sponsors_tonight().size()
	if accept:
		Game.toast("%s signed for %d nights: +%d materials each night you survive. %d sponsor%s sending pop-ups tonight!" % [sponsor_brand, Balance.config.sponsor_nights, Balance.config.sponsor_reward, n, "" if n == 1 else "s"], "info")
	else:
		Game.toast("No new sponsor." + (" %d older sponsor%s still sending pop-ups tonight." % [n, "" if n == 1 else "s"] if n > 0 else " No pop-ups tonight!"), "info")


func _refresh_sponsor(_decided: bool) -> void:
	if sponsor_mark == null:
		return
	var active := Progression.sponsors_tonight().size()
	if sponsor_decided and active > 0:
		sponsor_mark.text = "ADS x%d" % active
		sponsor_mark.add_theme_color_override("font_color", Palette.STATUS_OK)
	elif SimState.sponsor_tonight:
		sponsor_mark.text = "ON"
		sponsor_mark.add_theme_color_override("font_color", Palette.STATUS_OK)
	elif sponsor_decided:
		sponsor_mark.text = "NO"
		sponsor_mark.add_theme_color_override("font_color", Palette.BASE_STONE)
	else:
		sponsor_mark.text = "OFFER!"


# ---------------------------------------------------------------- inside a building: today's NASA lesson
func _lesson(id: String) -> Dictionary:
	var list: Array = lessons.get(id, [])
	if list.is_empty():
		return {}
	var k := clampi(Game.night - _unlock_night(id), 0, list.size() - 1)
	var d: Dictionary = list[k]
	d["index"] = k
	d["count"] = list.size()
	return d


func _show_building(id: String) -> void:
	var visited: Array = Game.visited[Game.night]
	if not visited.has(id):
		visited.append(id)
		Sfx.play("msg_received")
	var v := _new_card(1200)
	var lv := int(Progression.levels.get(id, 1))
	var les := _lesson(id)
	var head := Ui.row(v, 16, BoxContainer.ALIGNMENT_BEGIN)
	head.add_child(Ui.image("plot_%s_l%d" % [id, lv], 0))
	var hc := VBoxContainer.new()
	head.add_child(hc)
	hc.add_child(Ui.label("INSIDE: " + PLOT_NAME[id], Ui.BIG, true))
	hc.add_child(Ui.label("LEVEL %d OF 3 · DAY %d LESSON (%d OF %d)" % [lv, Game.night, int(les.get("index", 0)) + 1, int(les.get("count", 1))], 8, true, Palette.BASE_PLUM))
	var content := _card_scroll(v, 430.0)
	var body := Ui.row(content, 20, BoxContainer.ALIGNMENT_BEGIN)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	body.add_child(left)
	if not les.is_empty():
		# real photos get a frame (dark outline + cream mat) so they read as "a real picture", not game art
		var frame := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Palette.HIGHLIGHT
		sb.border_color = Palette.INK
		sb.set_border_width_all(3)
		sb.set_content_margin_all(5)
		sb.shadow_color = Color(Palette.INK, 0.35)
		sb.shadow_offset = Vector2(4, 4)
		frame.add_theme_stylebox_override("panel", sb)
		frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var photo := Ui.image("nasa_%s_%d" % [id, int(les.index) + 1])
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		photo.custom_minimum_size = Vector2(320, 200)
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.add_child(photo)
		left.add_child(frame)
		var cap := Ui.row(left, 6, BoxContainer.ALIGNMENT_BEGIN)
		cap.add_child(Ui.badge("real"))
		cap.add_child(Ui.body(str(les.image), 20, true, Palette.BASE_PLUM, 360))
		left.add_child(FigureChart.new(les.get("figure", {})))
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	body.add_child(right)
	if not les.is_empty():
		var tr := Ui.row(right, 10, BoxContainer.ALIGNMENT_BEGIN)
		tr.add_child(Ui.badge(str(les.get("badge", "real"))))
		tr.add_child(Ui.body(str(les.title), 22, true, Palette.INK, 560))
		right.add_child(Ui.body(str(les.text), 20, false, Palette.INK, 660))
		right.add_child(Ui.body(str(les.source), 20, false, Palette.BASE_PLUM, 660))
	right.add_child(Ui.body(PLOT_WHY[id], 20, true, Palette.INK, 660))
	right.add_child(Ui.body("Now · " + _effect(id, lv), 20, true, Palette.INK, 660))
	var btns := Ui.row(v)
	if lv < 3:
		var cost := Progression.upgrade_cost(id)
		right.add_child(Ui.body("Next level · " + _effect(id, lv + 1), 20, true, Palette.STATUS_OK_SHADE, 660))
		var cr := Ui.row(right, 8, BoxContainer.ALIGNMENT_BEGIN)
		cr.add_child(Ui.image("icon_materials"))
		cr.add_child(Ui.label("COSTS %d · YOU HAVE %d" % [cost, Progression.materials], Ui.BODY, true))
		var up := Ui.button("UPGRADE", func() -> void: _upgrade(id), Vector2(220, 64))
		up.disabled = not Progression.can_upgrade(id)
		btns.add_child(up)
	else:
		right.add_child(Ui.label("MAXED OUT!", Ui.BODY, true, Palette.STATUS_OK_SHADE))
	btns.add_child(Ui.button("LEAVE BUILDING", _close_card, Vector2(260, 64)))
	_refresh_hud()


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
	head.add_child(Ui.image("plot_%s_l%d" % [id, lv] if unlocked else "plot_locked", 0))
	var col := VBoxContainer.new()
	head.add_child(col)
	col.add_child(Ui.label(PLOT_NAME[id], Ui.BIG, true))
	col.add_child(Ui.label("LEVEL %d OF 3" % lv if unlocked else "LOCKED", Ui.BODY, true, Palette.BASE_PLUM))
	v.add_child(Ui.label(PLOT_WHY[id], Ui.BODY, false, Palette.INK, 700))
	var btns := Ui.row(v)
	if not unlocked:
		v.add_child(Ui.label("UNLOCKS ON NIGHT %d." % _unlock_night(id), Ui.BODY, true, Palette.STATUS_DANGER_SHADE))
	else:
		v.add_child(Ui.body("Now · " + _effect(id, lv), 20, true, Palette.INK, 700))
		if lv < 3:
			var cost := Progression.upgrade_cost(id)
			v.add_child(Ui.label("NEXT: " + _effect(id, lv + 1), Ui.BODY, true, Palette.STATUS_OK_SHADE, 700))
			var cost_row := Ui.row(v, 8, BoxContainer.ALIGNMENT_BEGIN)
			cost_row.add_child(Ui.image("icon_materials"))
			cost_row.add_child(Ui.label("COSTS %d · YOU HAVE %d" % [cost, Progression.materials], Ui.BODY, true))
			var up := Ui.button("UPGRADE", func() -> void: _upgrade(id), Vector2(220, 64))
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
		_show_building(id)


## A solid footprint at the base of a standing object, sized to its art: the Commander walks
## around it, and can still pass behind its top part (only the ground contact is solid).
func _foot(tex: Texture2D, base: Vector2, k: float, width_frac: float, depth: float) -> void:
	var body := _solid(base, Vector2.ONE)
	_fit_body(body, tex, base, k, true, width_frac, depth)


## Size a collision box to the sprite's real base (D51): as wide as the bottom rows of its
## opaque pixels, `depth` screen px deep, ending at the ground line. Upper parts stay walk-behind.
func _fit_body(body: StaticBody2D, tex: Texture2D, base: Vector2, k: float, on: bool, width_frac := 0.92, depth := 40.0) -> void:
	var cs: CollisionShape2D = body.get_child(0)
	cs.disabled = not on
	var img := tex.get_image()
	var x0 := 0
	var x1 := tex.get_width() - 1
	if img:
		var rows := int(ceil(depth / k))
		x0 = img.get_width()
		x1 = -1
		for y in range(maxi(0, img.get_height() - rows), img.get_height()):
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.5:
					x0 = mini(x0, x)
					x1 = maxi(x1, x)
		if x1 < x0:
			x0 = 0
			x1 = img.get_width() - 1
	var w := (x1 - x0 + 1) * k
	var cx := ((x0 + x1 + 1) / 2.0 - tex.get_width() / 2.0) * k
	body.position = base + Vector2(cx, -depth / 2.0)
	(cs.shape as RectangleShape2D).size = Vector2(maxf(8.0, w * width_frac), depth)


## Stand a sprite ON the ground: its foot is at `base` (so depth sorting works),
## with a soft contact shadow hugging its footprint, so nothing looks like it floats.
func _stand(s: Sprite2D, base: Vector2, k: float) -> void:
	s.position = base
	s.scale = Vector2(k, k)
	s.offset = Vector2(0, -s.texture.get_height() / 2.0)
	var sh := ContactShadow.new()
	sh.fit(s.texture)
	sh.show_behind_parent = true
	s.add_child(sh)
	s.set_meta("shadow", sh)
	add_child(s)


# ============================================================================ ground blending
## Dug-in regolith around every building + dirt tracks to the metal walkway, so buildings sit IN the ground.
class GroundMarks extends Node2D:
	const GROUND_DARK := Color("#963E28")   # shade of the toned ground tiles
	const GROUND_DEEP := Color("#6E2822")
	var habitat := Vector2.ZERO
	var plots: Dictionary = {}

	func _apron(c: Vector2, sz: Vector2) -> void:
		# soft oval of disturbed regolith: 3 fading rings, then scattered scuffs (no hard edge, no box)
		for k in 3:
			var f := 1.0 + k * 0.18
			draw_set_transform(c, 0.0, Vector2(sz.x * f / 2.0, sz.y * f / 2.0))
			draw_circle(Vector2.ZERO, 1.0, Color(GROUND_DARK, 0.20 - k * 0.06))
		draw_set_transform(Vector2.ZERO)
		var rng := RandomNumberGenerator.new()
		rng.seed = int(c.x * 7 + c.y)
		for i in 70:
			var a := rng.randf() * TAU
			var rr := rng.randf_range(0.7, 1.35)
			var p := c + Vector2(cos(a) * sz.x / 2.0 * rr, sin(a) * sz.y / 2.0 * rr)
			draw_rect(Rect2(p, Vector2(2, 2)), Color(GROUND_DEEP, 0.30))

	func _track(x: float, y0: float, y1: float) -> void:
		var a := minf(y0, y1)
		var b := maxf(y0, y1)
		draw_rect(Rect2(x - 12, a, 24, b - a), Color(GROUND_DARK, 0.28))
		var y := a
		while y < b:                                      # rover-wheel treads
			draw_rect(Rect2(x - 9, y, 5, 2), Color(GROUND_DEEP, 0.35))
			draw_rect(Rect2(x + 4, y, 5, 2), Color(GROUND_DEEP, 0.35))
			y += 6.0

	func _draw() -> void:
		_apron(habitat + Vector2(0, 92), Vector2(380, 70))
		for id in plots:
			var p: Vector2 = plots[id]
			_apron(p + Vector2(0, 62), Vector2(210, 56))
			if p.y < 320.0:                               # dirt tracks to the main walkway (y 320-352)
				_track(p.x, p.y + 64.0, 320.0)
			else:
				_track(p.x, 352.0, p.y)


## Soft contact shadow under a standing sprite, sized to the art's footprint
## (sprite-local coordinates: the foot of the sprite is at 0,0).
class ContactShadow extends Node2D:
	var w := 48.0
	var cx := 0.0
	var foot_y := -1.0
	func fit(tex: Texture2D) -> void:
		var img := tex.get_image()
		var r := img.get_used_rect() if img else Rect2i(0, 0, tex.get_width(), tex.get_height())
		w = r.size.x
		cx = r.position.x + r.size.x / 2.0 - tex.get_width() / 2.0
		foot_y = float(r.end.y - tex.get_height()) - 1.0
		queue_redraw()
	func _draw() -> void:
		for layer in [[1.0, 0.24], [0.8, 0.2], [0.6, 0.16]]:
			var k: float = layer[0]
			draw_set_transform(Vector2(cx, foot_y), 0.0, Vector2(w * 0.56 * k, maxf(3.0, w * 0.1) * k))
			draw_circle(Vector2.ZERO, 1.0, Color(0.24, 0.07, 0.05, layer[1]))
		draw_set_transform(Vector2.ZERO)


## A small soft shadow under the Commander's feet.
class BlobShadow extends Node2D:
	func _draw() -> void:
		draw_set_transform(Vector2(1, -2), 0.0, Vector2(1.0, 0.4))   # under the feet (the node position)
		draw_circle(Vector2.ZERO, 11.0, Color(0.3, 0.07, 0.02, 0.4))


## Fine red dust blowing across the whole base.
class DustDrift extends Node2D:
	var specks: Array[Vector3] = []          # x, y, speed
	func _ready() -> void:
		for i in 60:
			specks.append(Vector3(randf() * 1280.0, randf() * 720.0, randf_range(14.0, 40.0)))
	func _process(delta: float) -> void:
		for i in specks.size():
			var v := specks[i]
			v.x = fmod(v.x + v.z * delta, 1290.0)
			v.y += sin(v.x * 0.02) * 0.1
			specks[i] = v
		queue_redraw()
	func _draw() -> void:
		for v in specks:
			draw_rect(Rect2(v.x, v.y, 2, 1), Color(Palette.MARS_SAND, 0.35))


# ============================================================================ the crew by day
## Each crew member stands by their building. Talk to them (tap, or walk up + E): one line a day.
## One of them has noticed something about tonight's Malfunction. Nights 1-3 that hint is right;
## from Night 4 it can be an honest wrong guess, so the night's clues still matter.
## A crew member who was caught outside in last night's storm is resting: not on the map, no hint.
const CREW_SPOT := {"lani": "solar", "maya": "greenhouse", "mateo": "life_support", "carlo": "suit_bay"}
const CREW_ROLE := {"lani": "ENGINEER", "maya": "BOTANIST", "mateo": "DOCTOR", "carlo": "EVA SPECIALIST"}
const ROOM_NAME := {"solar_field": "SOLAR FIELD", "life_support": "LIFE SUPPORT", "airlock": "AIRLOCK", "greenhouse": "GREENHOUSE",
	"shelter": "SHELTER", "sky_radar": "SKY RADAR", "outside": "SKY RADAR", "comms_dish": "SKY RADAR"}
const WRONG_HINT_NIGHTS := [5, 7]
var crew_nodes: Dictionary = {}       # crew id -> Sprite2D
var crew_marks: Dictionary = {}       # crew id -> "!" label until they have spoken today

func _build_crew() -> void:
	if cfg == null:
		return
	var free_spots := [HABITAT_POS + Vector2(-190, 120), HABITAT_POS + Vector2(190, 120), HABITAT_POS + Vector2(-250, 150), HABITAT_POS + Vector2(250, 150)]
	var resting: Array = Progression.resting
	for id in cfg.crew_ids:
		if resting.has(id):
			Game.toast("%s was caught in last night's storm and is resting today." % str(id).to_upper(), "info", 6.0)
			continue
		var spot: String = CREW_SPOT.get(id, "")
		var at: Vector2 = PLOT_POS[spot] + Vector2(124 if id == "lani" else 84, 96) if spot != "" and Progression.plot_unlocked(spot, Game.night) else free_spots.pop_front()
		if id == "maya":
			at += Vector2(-25, 8)
		elif id == "carlo":
			at.y -= 12
		var s := Sprite2D.new()
		s.texture = Assets.frame("crew_%s_eva" % id, 0)
		_stand(s, at, 2.0)
		crew_nodes[id] = s
		var m := Ui.label("!", 16, true, Palette.STATUS_WARN)
		m.position = at + Vector2(-4, -122)
		m.z_index = 6
		m.visible = not _talked().has(id)
		add_child(m)
		crew_marks[id] = m
		var n := Ui.label(str(id).to_upper(), 8, true, Palette.HIGHLIGHT)
		n.position = at + Vector2(-20, 2)
		n.z_index = 5
		add_child(n)


func _talked() -> Array:
	if not Game.talked.has(Game.night):
		Game.talked[Game.night] = []
	return Game.talked[Game.night]


func _crew_near() -> String:
	for id in crew_nodes:
		if commander.position.distance_to(crew_nodes[id].position) < 70.0:
			return id
	return ""


## Who has the hint today, and what they say.
func _hint_line(id: String) -> String:
	var ids: Array = cfg.crew_ids
	var hinter: String = ids[Game.night % ids.size()] if not ids.is_empty() else ""
	var malf: Dictionary = SimState.story_beat(Game.night).get("malfunction", {})
	if id != hinter or malf.is_empty():
		return Strings.t("day.%s.%d" % [id, Game.night % 3])
	var right_room := ""
	var wrong_room := ""
	for c in malf.get("causes", []):
		var rooms: Array = c.get("rooms", [])
		if rooms.is_empty():
			continue
		if c.id == malf.get("true", ""):
			right_room = ROOM_NAME.get(rooms[0], str(rooms[0]).to_upper())
		elif wrong_room == "":
			wrong_room = ROOM_NAME.get(rooms[0], str(rooms[0]).to_upper())
	if Game.night in WRONG_HINT_NIGHTS and wrong_room != "":
		return Strings.t("day.hint_guess") % wrong_room
	if Game.night >= 4:
		return Strings.t("day.hint_guess") % right_room
	return Strings.t("day.hint_sure") % right_room


func _talk(id: String) -> void:
	Sfx.play("msg_received", -6.0)
	if not _talked().has(id):
		_talked().append(id)
	if crew_marks.has(id):
		crew_marks[id].visible = false
	var v := _new_card(760, "ui_briefing")
	var top := Ui.row(v, 16, BoxContainer.ALIGNMENT_BEGIN)
	var p := TextureRect.new()
	p.texture = Assets.frame("portrait_" + id, 0)
	p.custom_minimum_size = Vector2(96, 96)
	top.add_child(p)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	top.add_child(col)
	col.add_child(Ui.body("%s · %s" % [id.capitalize(), CREW_ROLE.get(id, "CREW").capitalize()], 20, true, Palette.BASE_PLUM))
	col.add_child(Ui.body(_hint_line(id), 22, false, Palette.INK, 580))
	var btns := Ui.row(v)
	btns.add_child(Ui.button("OK", _close_card, Vector2(160, 64)))
