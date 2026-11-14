class_name TaskGame
extends PanelContainer
## A Task: a 10-20 s hands-on repair opened by tapping a Problem on a camera.
## Skill only: doing it right always works. Hazards only make the timer shorter.
## Every task is a real Mars job (not a generic puzzle). On success it flashes, closes,
## and the desk shows its one-line real fact as a toast.
## Kinds (fault -> task):
##   loose_cable     -> PLUG     the keyed plug spins; tap when the yellow notches line up (x3)
##   panel_dust      -> SWEEP    drag across the panel; Mars wind carries the dust away
##   clogged_filter  -> MOXIE    hold HEAT to keep the oxygen maker in the 800 C band until the tank fills
##   airlock_leak    -> LEAKS    watch for drifting dust puffs and tap where air escapes (x3)
##   greenhouse_leak -> WATER    slide the cup to catch drips, then tap the leak to clamp it
##   shelter_seal    -> SHIELD   tap the low parts of the wall to pile regolith bags up to the line
##   dish_drift      -> EARTH    drag the crosshair onto Earth as it moves across the sky, hold it

signal finished(success: bool)

const AREA := Vector2(520, 230)
const NAMES := {"loose_cable": "PLUG IN THE SOLAR CABLE", "panel_dust": "SWEEP THE SOLAR PANEL",
	"clogged_filter": "RESTART THE OXYGEN MAKER", "airlock_leak": "FIND THE AIRLOCK LEAKS",
	"greenhouse_leak": "SAVE THE WATER", "shelter_seal": "PILE UP THE SHIELDING", "dish_drift": "TRACK EARTH WITH THE DISH"}
const HOW := {"loose_cable": "The plug spins. Tap when the two yellow notches line up!",
	"panel_dust": "Drag across the panel. The Mars wind blows the dust away.",
	"clogged_filter": "Hold HEAT to keep the needle in the green band. Too hot and it shuts off!",
	"airlock_leak": "Watch for dust drifting out of the door. Tap where the air escapes!",
	"greenhouse_leak": "Move the cup to catch 5 drops, then tap the leak to clamp it.",
	"shelter_seal": "Tap the low parts of the wall to pile Mars dirt up to the line.",
	"dish_drift": "Drag the crosshair onto Earth and stay on it as it moves."}
const SKY_TOP := Color("#2A0E3D")
const EARTH_BLUE := Color("#4FA3FF")

var kind := ""
var time_limit := 15.0
var t_left := 15.0
var state := "play"          # play / won / lost
var fact_t := 0.0
var area: Control
var title_l: Label
var info_l: Label
var timer_bar: ProgressBar
var rng := RandomNumberGenerator.new()
var age := 0.0               # seconds since this attempt started
# juice
var parts: Array[Dictionary] = []    # {p, v, life, max, col, r, g}
var shake := 0.0
var flash := 0.0
var stars: Array[Vector2] = []
# PLUG
var plugs_done := 0
var plug_angle := 0.0
var plug_speed := 2.4
# SWEEP
var dust: Array[Vector2] = []
var dust_start := 1
var dragging := false
# MOXIE
var temp := 0.2
var oxygen := 0.0
var holding := false
var overheat_t := 0.0
# LEAKS
var leaks: Array[Vector2] = []
var leak_fixed: Array[bool] = []
var puff_t := 0.0
# WATER
var leak_x := 260.0
var drops: Array[Vector2] = []
var cup_x := 260.0
var caught := 0
var drip_t := 0.0
var clamped := false
# SHIELD
var cols: Array[int] = []
const WALL_TARGET := 5
# EARTH
var earth_u := 0.0
var aim := Vector2(260, 180)
var lock_t := 0.0
# kept for older tests
var wires_done: Array[bool] = [false, false, false]


func _init(fault_kind: String, harder: bool) -> void:
	kind = fault_kind
	time_limit = 15.0 * (0.75 if harder else 1.0)
	if kind == "clogged_filter" or kind == "greenhouse_leak":
		time_limit += 4.0


func _ready() -> void:
	add_theme_stylebox_override("panel", Ui.nine("ui_popup", 12))
	position = Vector2(370, 206)   # below the alert strip
	custom_minimum_size = Vector2(AREA.x + 24, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	title_l = Ui.label("TASK: " + str(NAMES.get(kind, kind)), 16, true)
	v.add_child(title_l)
	info_l = Ui.label(str(HOW.get(kind, "")), 8, true, Palette.BASE_PLUM, AREA.x)
	v.add_child(info_l)
	timer_bar = ProgressBar.new()
	timer_bar.custom_minimum_size = Vector2(AREA.x, 10)
	timer_bar.show_percentage = false
	timer_bar.max_value = 1.0
	v.add_child(timer_bar)
	area = Control.new()
	area.custom_minimum_size = AREA
	area.clip_contents = true
	area.mouse_filter = Control.MOUSE_FILTER_STOP
	area.draw.connect(_draw_area)
	area.gui_input.connect(_area_input)
	v.add_child(area)
	var row := HBoxContainer.new()
	v.add_child(row)
	var close := Ui.button("LATER", func() -> void: finished.emit(false), Vector2(140, 40))
	row.add_child(close)
	rng.randomize()
	for i in 40:
		stars.append(Vector2(rng.randf_range(0, AREA.x), rng.randf_range(0, 140)))
	_setup()


func _setup() -> void:
	state = "play"
	t_left = time_limit
	age = 0.0
	parts.clear()
	match kind:
		"loose_cable":
			plugs_done = 0
			plug_angle = rng.randf_range(0.0, TAU)
			plug_speed = 2.4
		"panel_dust":
			dust.clear()
			for i in 22:
				dust.append(Vector2(rng.randf_range(80, 440), rng.randf_range(60, 196)))
			dust_start = dust.size()
		"clogged_filter":
			temp = 0.2
			oxygen = 0.0
			overheat_t = 0.0
		"airlock_leak":
			leaks.clear()
			leak_fixed.clear()
			var edges := [Vector2(rng.randf_range(176, 344), 34), Vector2(166, rng.randf_range(60, 190)),
				Vector2(354, rng.randf_range(60, 190)), Vector2(rng.randf_range(176, 344), 208)]
			edges.shuffle()
			for i in 3:
				leaks.append(edges[i])
				leak_fixed.append(false)
		"greenhouse_leak":
			leak_x = rng.randf_range(120, 400)
			drops.clear()
			caught = 0
			drip_t = 0.6
			clamped = false
		"shelter_seal":
			cols.clear()
			for i in 6:
				cols.append(rng.randi_range(1, 3))
		"dish_drift":
			earth_u = rng.randf_range(0.1, 0.25)
			aim = Vector2(260, 190)
			lock_t = 0.0


func _process(delta: float) -> void:
	_tick_juice(delta)
	if state == "won":
		fact_t -= delta
		if fact_t <= 0.0:
			finished.emit(true)
		area.queue_redraw()
		return
	if state != "play":
		area.queue_redraw()
		return
	age += delta
	t_left -= delta
	timer_bar.value = t_left / time_limit
	match kind:
		"loose_cable":
			plug_angle = fmod(plug_angle + plug_speed * delta, TAU)
		"clogged_filter":
			if overheat_t > 0.0:
				overheat_t -= delta
				temp = maxf(0.3, temp - delta * 0.4)
			else:
				temp = clampf(temp + (0.45 if holding else -0.3) * delta, 0.0, 1.0)
				if temp > 0.95:
					overheat_t = 1.2
					holding = false
					_oops(Vector2(80, 40))
					info_l.text = "TOO HOT! MOXIE SHUT ITSELF OFF. WAIT, THEN TRY AGAIN."
				elif _in_band():
					oxygen += delta / 5.0
					if rng.randf() < delta * 8.0:
						_puff(Vector2(300, 140), Vector2(rng.randf_range(20, 60), rng.randf_range(-40, -10)), Palette.SKY_HAZE, 4.0, 0.9)
					if oxygen >= 1.0:
						_win()
		"airlock_leak":
			puff_t -= delta
			if puff_t <= 0.0:
				puff_t = 0.45
				for i in leaks.size():
					if not leak_fixed[i]:
						var out := (leaks[i] - Vector2(260, 121)).normalized()
						_puff(leaks[i], out * rng.randf_range(20, 40) + Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)), Palette.MARS_SAND, 3.0, 1.4)
		"greenhouse_leak":
			if not clamped and caught < 5:
				drip_t -= delta
				if drip_t <= 0.0:
					drip_t = rng.randf_range(0.55, 0.9)
					drops.append(Vector2(leak_x, 46))
			for i in range(drops.size() - 1, -1, -1):
				drops[i].y += delta * (90.0 + (drops[i].y - 46.0) * 1.6)
				if drops[i].y >= 196 and absf(drops[i].x - cup_x) < 28:
					drops.remove_at(i)
					caught += 1
					Sfx.play("click")
					_burst(Vector2(cup_x, 194), 5, EARTH_BLUE, 50.0)
					if caught >= 5:
						info_l.text = "GREAT! NOW TAP THE LEAK ON THE PIPE TO CLAMP IT."
				elif drops[i].y >= 220:
					_burst(Vector2(drops[i].x, 220), 6, EARTH_BLUE, 60.0)
					drops.remove_at(i)
		"dish_drift":
			earth_u = minf(earth_u + delta * 0.035, 0.95)
			if aim.distance_to(_earth_pos()) < 20.0:
				lock_t += delta
				if rng.randf() < delta * 10.0:
					_puff(_earth_pos(), Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20)), Palette.STATUS_OK, 2.0, 0.5)
				if lock_t >= 1.6:
					_win()
			else:
				lock_t = maxf(0.0, lock_t - delta * 2.0)
	if state == "play" and t_left <= 0.0:
		state = "lost"
		info_l.text = "OUT OF TIME! TRY AGAIN."
		Sfx.play("low_battery", -6.0)
		shake = 6.0
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if is_instance_valid(self):
				info_l.text = str(HOW.get(kind, ""))
				_setup())
	area.queue_redraw()


func _in_band() -> bool:
	return temp >= 0.6 and temp <= 0.8


func _earth_pos() -> Vector2:
	return Vector2(60.0 + 400.0 * earth_u, 150.0 - 110.0 * sin(earth_u * PI))


func _win() -> void:
	state = "won"
	fact_t = 0.35   # quick flash, then back to the desk (the fact shows as a toast)
	flash = 1.0
	Sfx.play("upgrade")
	_burst(AREA / 2.0, 24, Palette.STATUS_WARN, 160.0)
	info_l.text = "FIXED!"
	info_l.add_theme_color_override("font_color", Palette.STATUS_OK_SHADE)


func _oops(p: Vector2) -> void:
	shake = 5.0
	Sfx.play("thump", -8.0)
	_burst(p, 8, Palette.STATUS_DANGER, 90.0)


# ---------------------------------------------------------------- juice
func _burst(p: Vector2, n: int, col: Color, speed: float) -> void:
	for i in n:
		var a := rng.randf_range(0.0, TAU)
		parts.append({"p": p, "v": Vector2.RIGHT.rotated(a) * rng.randf_range(speed * 0.4, speed),
			"life": 0.5, "max": 0.5, "col": col, "r": rng.randf_range(1.5, 3.0), "g": 160.0})


func _puff(p: Vector2, v: Vector2, col: Color, r: float, life: float) -> void:
	parts.append({"p": p, "v": v, "life": life, "max": life, "col": col, "r": r, "g": 0.0})


func _tick_juice(delta: float) -> void:
	shake = maxf(0.0, shake - delta * 20.0)
	flash = maxf(0.0, flash - delta * 3.0)
	for i in range(parts.size() - 1, -1, -1):
		var q := parts[i]
		q.life -= delta
		if q.life <= 0.0:
			parts.remove_at(i)
			continue
		q.v = q.v + Vector2(0.0, q.g * delta)
		q.p = q.p + q.v * delta


# ---------------------------------------------------------------- input
func _area_input(e: InputEvent) -> void:
	if state != "play":
		return
	var mb := e as InputEventMouseButton
	var mm := e as InputEventMouseMotion
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		dragging = mb.pressed
		if kind == "clogged_filter":
			holding = mb.pressed and overheat_t <= 0.0 and Rect2(360, 150, 140, 60).has_point(mb.position)
		if mb.pressed:
			_tap(mb.position)
	elif mm:
		if kind == "greenhouse_leak":
			cup_x = clampf(mm.position.x, 30, AREA.x - 30)
		if dragging:
			_drag(mm.position)
	area.queue_redraw()


func _tap(p: Vector2) -> void:
	match kind:
		"loose_cable":
			var diff := absf(wrapf(plug_angle, -PI, PI))
			if diff < 0.4:
				plugs_done += 1
				Sfx.play("camera")
				_burst(Vector2(260, 75), 14, Palette.STATUS_WARN, 120.0)
				plug_speed += 0.6
				plug_angle = rng.randf_range(1.5, 4.5)
				if plugs_done >= 3:
					_win()
			else:
				_oops(Vector2(260, 115))
				t_left -= 1.0
		"panel_dust", "dish_drift":
			_drag(p)
		"airlock_leak":
			for i in leaks.size():
				if not leak_fixed[i] and leaks[i].distance_to(p) < 24:
					leak_fixed[i] = true
					Sfx.play("camera")
					_burst(leaks[i], 10, Palette.STATUS_WARN, 80.0)
					if not leak_fixed.has(false):
						_win()
					return
		"greenhouse_leak":
			cup_x = clampf(p.x, 30, AREA.x - 30)
			if caught >= 5 and Vector2(leak_x, 40).distance_to(p) < 30:
				clamped = true
				_win()
		"shelter_seal":
			for i in cols.size():
				if Rect2(70 + i * 64, 20, 60, 200).has_point(p):
					if cols[i] < WALL_TARGET:
						cols[i] += 1
						Sfx.play("thump", -14.0)
						shake = 1.5
						_burst(Vector2(100 + i * 64, 214 - cols[i] * 30), 8, Palette.MARS_SAND, 70.0)
					if cols.all(func(h: int) -> bool: return h >= WALL_TARGET):
						_win()


func _drag(p: Vector2) -> void:
	match kind:
		"panel_dust":
			for d in dust.duplicate():
				if d.distance_to(p) < 30:
					dust.erase(d)
					for k in 3:
						_puff(d, Vector2(rng.randf_range(60, 140), rng.randf_range(-40, 10)), Palette.MARS_SAND, rng.randf_range(3, 6), 0.8)
			if dust.is_empty():
				_win()
		"dish_drift":
			aim = p


# ---------------------------------------------------------------- drawing
func _draw_area() -> void:
	var off := Vector2(rng.randf_range(-shake, shake), rng.randf_range(-shake, shake)) if shake > 0.0 else Vector2.ZERO
	area.draw_set_transform(off)
	var f: Font = Ui.FONT_R
	area.draw_rect(Rect2(-8, -8, AREA.x + 16, AREA.y + 16), Palette.INK)
	match kind:
		"loose_cable": _draw_plug(f)
		"panel_dust": _draw_sweep(f)
		"clogged_filter": _draw_moxie(f)
		"airlock_leak": _draw_leaks(f)
		"greenhouse_leak": _draw_water(f)
		"shelter_seal": _draw_shield(f)
		"dish_drift": _draw_earth(f)
	for q in parts:
		var a: float = clampf(q.life / q.max, 0.0, 1.0)
		area.draw_circle(q.p, q.r, Color(q.col, a))
	if flash > 0.0:
		area.draw_rect(Rect2(Vector2.ZERO, AREA), Color(Palette.HIGHLIGHT, flash * 0.6))
	if state == "won":
		area.draw_rect(Rect2(Vector2.ZERO, AREA), Color(Palette.STATUS_OK, 0.25))
	area.draw_set_transform(Vector2.ZERO)


func _mars_sky(horizon: float) -> void:
	area.draw_rect(Rect2(0, 0, AREA.x, horizon), SKY_TOP)
	area.draw_rect(Rect2(0, horizon - 30, AREA.x, 30), Color(Palette.SKY_VIOLET, 0.6))
	for s in stars:
		if s.y < horizon - 10:
			area.draw_rect(Rect2(s, Vector2(2, 2)), Color(Palette.HIGHLIGHT, 0.4 + 0.4 * sin(age * 2.0 + s.x)))
	area.draw_rect(Rect2(0, horizon, AREA.x, AREA.y - horizon), Palette.MARS_RUST)
	for i in 8:
		area.draw_circle(Vector2(30 + i * 70, horizon + 14 + (i % 3) * 8), 5 + (i % 2) * 3, Palette.MARS_CRIMSON)


func _draw_plug(f: Font) -> void:
	_mars_sky(150)
	var c := Vector2(260, 115)
	# three cable lights: one per plug
	for i in 3:
		var lit := i < plugs_done
		area.draw_circle(Vector2(40, 40 + i * 30), 9, Palette.STATUS_OK if lit else Palette.BASE_PLUM)
		area.draw_string(f, Vector2(56, 44 + i * 30), "CABLE %d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.HIGHLIGHT)
	# the socket on the panel box
	area.draw_rect(Rect2(c - Vector2(70, 70), Vector2(140, 140)), Palette.BASE_STONE)
	area.draw_rect(Rect2(c - Vector2(70, 70), Vector2(140, 140)), Palette.INK, false, 3)
	area.draw_circle(c, 52, Palette.BASE_PLUM)
	area.draw_colored_polygon(PackedVector2Array([c + Vector2(-9, -60), c + Vector2(9, -60), c + Vector2(0, -48)]), Palette.STATUS_WARN)
	# the spinning plug with its key notch
	area.draw_circle(c, 42, Palette.BASE_CREAM)
	area.draw_arc(c, 42, 0, TAU, 32, Palette.INK, 3)
	for k in 4:
		area.draw_circle(c + Vector2.RIGHT.rotated(plug_angle + PI / 4.0 + k * PI / 2.0) * 22, 5, Palette.BASE_MAUVE)
	var n := c + Vector2.UP.rotated(plug_angle) * 36
	area.draw_circle(n, 7, Palette.STATUS_WARN)
	var near := absf(wrapf(plug_angle, -PI, PI)) < 0.4
	area.draw_string(f, Vector2(370, 210), "TAP NOW!" if near else "WAIT...", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.STATUS_WARN if near else Palette.BASE_MAUVE)


func _draw_sweep(f: Font) -> void:
	_mars_sky(60)
	area.draw_rect(Rect2(60, 50, 400, 160), Palette.SKY_INDIGO)
	for x in range(60, 461, 50):
		area.draw_line(Vector2(x, 50), Vector2(x, 210), Palette.SKY_HAZE, 1)
	for y in range(50, 211, 40):
		area.draw_line(Vector2(60, y), Vector2(460, y), Palette.SKY_HAZE, 1)
	for d in dust:
		area.draw_circle(d, 22, Palette.MARS_SAND)
		area.draw_circle(d + Vector2(-6, -5), 9, Color(Palette.MARS_ORANGE, 0.5))
	var power := 1.0 - float(dust.size()) / float(dust_start)
	area.draw_string(f, Vector2(10, 20), "PANEL POWER %d%%" % int(lerpf(30.0, 100.0, power)), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.HIGHLIGHT)
	area.draw_rect(Rect2(10, 26, 200, 8), Palette.BASE_PLUM)
	area.draw_rect(Rect2(10, 26, 200 * lerpf(0.3, 1.0, power), 8), Palette.STATUS_WARN)
	area.draw_string(f, Vector2(340, 20), "WIND >>>", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.MARS_SAND)


func _draw_moxie(f: Font) -> void:
	area.draw_rect(Rect2(0, 0, AREA.x, AREA.y), Palette.BASE_PLUM)
	# thermometer
	area.draw_string(f, Vector2(30, 20), "HEAT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.HIGHLIGHT)
	area.draw_rect(Rect2(36, 30, 40, 180), Palette.INK)
	area.draw_rect(Rect2(36, 30 + 180 * 0.2, 40, 180 * 0.2), Color(Palette.STATUS_OK, 0.5))
	area.draw_string(f, Vector2(82, 30 + 180 * 0.3 + 4), "800 C", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.STATUS_OK)
	var hot := overheat_t > 0.0
	var col := Palette.STATUS_DANGER if hot or temp > 0.8 else (Palette.STATUS_OK if _in_band() else Palette.STATUS_WARN)
	area.draw_rect(Rect2(42, 30 + 180 * (1.0 - temp), 28, 180 * temp), col)
	# MOXIE box: CO2 in, O2 out
	area.draw_rect(Rect2(160, 60, 120, 100), Palette.BASE_STONE)
	area.draw_rect(Rect2(160, 60, 120, 100), Palette.INK, false, 3)
	area.draw_string(f, Vector2(160, 115), "MOXIE", HORIZONTAL_ALIGNMENT_CENTER, 120, 16, Palette.INK)
	area.draw_rect(Rect2(170, 70, 100, 12), Palette.STATUS_DANGER if hot else (Palette.STATUS_WARN if temp > 0.3 else Palette.BASE_MAUVE))
	area.draw_string(f, Vector2(130, 50), "MARS AIR (CO2) >", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.MARS_SAND)
	# oxygen tank
	area.draw_string(f, Vector2(300, 50), "> OXYGEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.SKY_HAZE)
	area.draw_rect(Rect2(300, 60, 40, 100), Palette.INK)
	area.draw_rect(Rect2(304, 64 + 92 * (1.0 - oxygen), 32, 92 * oxygen), Palette.SKY_HAZE)
	area.draw_rect(Rect2(360, 150, 140, 60), Palette.STATUS_WARN if holding else (Palette.BASE_MAUVE if hot else Palette.BASE_CREAM))
	area.draw_rect(Rect2(360, 150, 140, 60), Palette.INK, false, 3)
	area.draw_string(f, Vector2(360, 186), "HOLD: HEAT", HORIZONTAL_ALIGNMENT_CENTER, 140, 8, Palette.INK)


func _draw_leaks(f: Font) -> void:
	area.draw_rect(Rect2(0, 0, AREA.x, AREA.y), SKY_TOP)
	area.draw_rect(Rect2(0, 200, AREA.x, 30), Palette.MARS_RUST)
	# airlock door: a round-cornered hatch
	area.draw_rect(Rect2(150, 22, 220, 198), Palette.BASE_MAUVE)
	area.draw_rect(Rect2(166, 34, 188, 174), Palette.BASE_STONE)
	area.draw_rect(Rect2(166, 34, 188, 174), Palette.INK, false, 3)
	area.draw_circle(Vector2(260, 121), 26, Palette.BASE_PLUM)
	area.draw_arc(Vector2(260, 121), 26, 0, TAU, 24, Palette.INK, 3)
	area.draw_line(Vector2(240, 121), Vector2(280, 121), Palette.BASE_CREAM, 4)
	for i in leaks.size():
		if leak_fixed[i]:
			area.draw_rect(Rect2(leaks[i] - Vector2(12, 12), Vector2(24, 24)), Palette.STATUS_WARN)
			area.draw_rect(Rect2(leaks[i] - Vector2(12, 12), Vector2(24, 24)), Palette.INK, false, 2)
	var left := leak_fixed.count(false)
	area.draw_string(f, Vector2(10, 20), "LEAKS LEFT: %d" % left, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.HIGHLIGHT)
	area.draw_string(f, Vector2(390, 20), "AIR %d%%" % int(100.0 * t_left / time_limit), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.SKY_HAZE)


func _draw_water(f: Font) -> void:
	area.draw_rect(Rect2(0, 0, AREA.x, AREA.y), Color("#1E3B2A"))
	# the pipe and its leak
	area.draw_rect(Rect2(0, 28, AREA.x, 16), Palette.BASE_STONE)
	area.draw_rect(Rect2(0, 28, AREA.x, 16), Palette.INK, false, 2)
	if clamped:
		area.draw_rect(Rect2(leak_x - 14, 24, 28, 24), Palette.STATUS_WARN)
	else:
		area.draw_circle(Vector2(leak_x, 44), 5, EARTH_BLUE)
		if caught >= 5:
			area.draw_arc(Vector2(leak_x, 38), 22 + 4 * sin(age * 8.0), 0, TAU, 24, Palette.STATUS_WARN, 3)
	for d in drops:
		area.draw_circle(d, 5, EARTH_BLUE)
		area.draw_colored_polygon(PackedVector2Array([d + Vector2(-4, -1), d + Vector2(4, -1), d + Vector2(0, -9)]), EARTH_BLUE)
	# plants along the floor
	for i in 7:
		var x := 30.0 + i * 75.0
		area.draw_rect(Rect2(x - 10, 214, 20, 16), Palette.MARS_CRIMSON)
		area.draw_circle(Vector2(x, 208), 8, Palette.STATUS_OK)
	# the cup
	area.draw_rect(Rect2(cup_x - 24, 186, 48, 22), Palette.BASE_CREAM)
	area.draw_rect(Rect2(cup_x - 24, 186, 48, 22), Palette.INK, false, 2)
	area.draw_rect(Rect2(cup_x - 20, 206 - 4 * caught, 40, 4 * caught), EARTH_BLUE)
	area.draw_string(f, Vector2(10, 20), "DROPS SAVED: %d / 5" % caught, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.HIGHLIGHT)


func _draw_shield(f: Font) -> void:
	_mars_sky(220)
	var line_y := 214.0 - WALL_TARGET * 30.0
	# space particles raining down; they stop on the wall where it is high enough
	for k in 14:
		var x := fmod(k * 37.0 + age * 160.0, AREA.x)
		var y := fmod(k * 53.0 + age * 220.0, 220.0)
		area.draw_rect(Rect2(x, y, 2, 6), Color(Palette.STATUS_WARN, 0.7))
	area.draw_line(Vector2(60, line_y), Vector2(460, line_y), Palette.STATUS_OK, 2)
	area.draw_string(f, Vector2(380, line_y - 6), "SAFE HEIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.STATUS_OK)
	for i in cols.size():
		var x := 70.0 + i * 64.0
		for b in cols[i]:
			var r := Rect2(x + (4 if b % 2 else 0), 214 - (b + 1) * 30, 56, 28)
			area.draw_rect(r, Palette.MARS_SAND)
			area.draw_rect(r, Palette.INK, false, 2)
		if cols[i] < WALL_TARGET:
			area.draw_string(f, Vector2(x, 214 - (cols[i] + 1) * 30 + 18), "TAP", HORIZONTAL_ALIGNMENT_CENTER, 60, 8, Palette.HIGHLIGHT)
	area.draw_string(f, Vector2(10, 20), "SHELTER WALL: PILE UP MARS DIRT (REGOLITH)", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.HIGHLIGHT)


func _draw_earth(f: Font) -> void:
	_mars_sky(190)
	var e := _earth_pos()
	area.draw_circle(e, 12, Color(EARTH_BLUE, 0.25))
	area.draw_circle(e, 6, EARTH_BLUE)
	area.draw_circle(e + Vector2(10, -6), 2, Palette.BASE_STONE)   # the Moon
	area.draw_string(f, e + Vector2(14, 14), "EARTH", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, EARTH_BLUE)
	# the dish on the ground, pointing at the crosshair
	var base := Vector2(70, 205)
	var dirv := (aim - base).normalized()
	area.draw_line(base, base + dirv * 40, Palette.BASE_STONE, 4)
	area.draw_arc(base + dirv * 40, 22, dirv.angle() + PI / 2.0, dirv.angle() + PI * 1.5, 12, Palette.BASE_CREAM, 6)
	var locked := aim.distance_to(e) < 20.0
	var col := Palette.STATUS_OK if locked else Palette.STATUS_WARN
	area.draw_arc(aim, 18, 0, TAU, 24, col, 2)
	area.draw_line(aim - Vector2(26, 0), aim - Vector2(10, 0), col, 2)
	area.draw_line(aim + Vector2(10, 0), aim + Vector2(26, 0), col, 2)
	area.draw_line(aim - Vector2(0, 26), aim - Vector2(0, 10), col, 2)
	area.draw_line(aim + Vector2(0, 10), aim + Vector2(0, 26), col, 2)
	area.draw_string(f, Vector2(10, 20), "SIGNAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.HIGHLIGHT)
	area.draw_rect(Rect2(60, 13, 160, 8), Palette.BASE_PLUM)
	area.draw_rect(Rect2(60, 13, 160 * clampf(lock_t / 1.6, 0.0, 1.0), 8), Palette.STATUS_OK)
