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
	"shelter_seal": "Tap the low spots to pile sandbags up to the green flag.",
	"dish_drift": "Drag the crosshair onto Earth and stay on it as it moves."}
const PLUG_C := Vector2(304, 114)     # centre of the socket
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
var _shake_off := Vector2.ZERO
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
# movement: things ease, snap and wobble instead of jumping
var plug_push := 0.0          # 1 -> 0 after a good tap: the plug pushes into the socket
var plug_wobble := 0.0        # 1 -> 0 after a bad tap: the plug shakes
var bag_drop: Array[float] = []   # per column: 1 -> 0 while the newest sandbag falls into place
var patch_pop: Array[float] = []  # per leak: 1 -> 0 while the patch pops on
var cup_target := 260.0
var aim_draw := Vector2(260, 180)


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
	info_l = Ui.body(str(HOW.get(kind, "")), 16, true, Palette.BASE_PLUM, AREA.x)
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
	area.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST      # props are pixel art shown at 2x
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
			plug_angle = rng.randf_range(1.5, 4.5)
			plug_speed = 2.4
			plug_push = 0.0
			plug_wobble = 0.0
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
			patch_pop = [0.0, 0.0, 0.0]
		"greenhouse_leak":
			leak_x = rng.randf_range(120, 400)
			drops.clear()
			caught = 0
			cup_target = cup_x
			drip_t = 0.6
			clamped = false
		"shelter_seal":
			cols.clear()
			bag_drop.clear()
			for i in 6:
				cols.append(rng.randi_range(1, 3))
				bag_drop.append(0.0)
		"dish_drift":
			earth_u = rng.randf_range(0.1, 0.25)
			aim = Vector2(260, 190)
			aim_draw = aim
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
			# slows down near the lined-up spot, so a 7-year-old can hit it
			var off := absf(wrapf(plug_angle, -PI, PI))
			var ease_k := lerpf(0.45, 1.0, clampf(off / 0.9, 0.0, 1.0))
			if plug_push <= 0.0:
				plug_angle = fmod(plug_angle + plug_speed * ease_k * delta, TAU)
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
	plug_push = maxf(0.0, plug_push - delta * 3.5)
	plug_wobble = maxf(0.0, plug_wobble - delta * 3.0)
	for i in bag_drop.size():
		bag_drop[i] = maxf(0.0, bag_drop[i] - delta * 4.0)
	for i in patch_pop.size():
		patch_pop[i] = maxf(0.0, patch_pop[i] - delta * 5.0)
	cup_x = lerpf(cup_x, cup_target, 1.0 - exp(-18.0 * delta))          # the bucket glides after the pointer
	aim_draw = aim_draw.lerp(aim, 1.0 - exp(-14.0 * delta))             # the dish swings to the crosshair
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
			cup_target = clampf(mm.position.x, 30, AREA.x - 30)
		if dragging:
			_drag(mm.position)
	area.queue_redraw()


func _tap(p: Vector2) -> void:
	match kind:
		"loose_cable":
			var diff := absf(wrapf(plug_angle, -PI, PI))
			if plug_push > 0.0:
				return                                   # still clicking in
			if diff < 0.4:
				plugs_done += 1
				Sfx.play("camera")
				_burst(PLUG_C, 16, Palette.STATUS_WARN, 130.0)
				plug_push = 1.0                          # pushes in with a click and a spark
				shake = 1.5
				plug_speed += 0.6                        # each cable turns a bit faster
				if plugs_done >= 3:
					_win()
				else:
					get_tree().create_timer(0.3).timeout.connect(func() -> void:
						if is_instance_valid(self) and state == "play":
							plug_angle = rng.randf_range(1.5, 4.5))
			else:
				plug_wobble = 1.0                        # wrong moment: the plug shakes
				_oops(PLUG_C)
				t_left -= 1.0
		"panel_dust", "dish_drift":
			_drag(p)
		"airlock_leak":
			for i in leaks.size():
				if not leak_fixed[i] and leaks[i].distance_to(p) < 24:
					leak_fixed[i] = true
					patch_pop[i] = 1.0
					Sfx.play("camera")
					_burst(leaks[i], 10, Palette.STATUS_WARN, 80.0)
					if not leak_fixed.has(false):
						_win()
					return
		"greenhouse_leak":
			cup_target = clampf(p.x, 30, AREA.x - 30)
			if caught >= 5 and Vector2(leak_x, 40).distance_to(p) < 30:
				clamped = true
				_win()
		"shelter_seal":
			for i in cols.size():
				if Rect2(70 + i * 64, 20, 60, 200).has_point(p):
					if cols[i] < WALL_TARGET:
						cols[i] += 1
						bag_drop[i] = 1.0
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
	_shake_off = Vector2(rng.randf_range(-shake, shake), rng.randf_range(-shake, shake)).round() if shake > 0.0 else Vector2.ZERO
	area.draw_set_transform(_shake_off)
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
	# framed work area: ink outside, a cream line inside
	area.draw_rect(Rect2(Vector2.ZERO, AREA), Palette.INK, false, 4.0)
	area.draw_rect(Rect2(Vector2(4, 4), AREA - Vector2(8, 8)), Palette.BASE_CREAM, false, 2.0)


func _draw_bg(asset_name: String) -> bool:
	if not Assets.has(asset_name):
		return false
	area.draw_texture_rect(Assets.tex(asset_name), Rect2(Vector2.ZERO, AREA), false)
	return true


func _mars_sky(horizon: float) -> void:
	area.draw_rect(Rect2(0, 0, AREA.x, horizon), SKY_TOP)
	area.draw_rect(Rect2(0, horizon - 30, AREA.x, 30), Color(Palette.SKY_VIOLET, 0.6))
	for s in stars:
		if s.y < horizon - 10:
			area.draw_rect(Rect2(s, Vector2(2, 2)), Color(Palette.HIGHLIGHT, 0.4 + 0.4 * sin(age * 2.0 + s.x)))
	area.draw_rect(Rect2(0, horizon, AREA.x, AREA.y - horizon), Palette.MARS_RUST)
	for i in 8:
		area.draw_circle(Vector2(30 + i * 70, horizon + 14 + (i % 3) * 8), 5 + (i % 2) * 3, Palette.MARS_CRIMSON)


# ---- helpers: pixel-art props at exactly 2x, HUD chips that read on any background
func _spr(asset: String, pos: Vector2, frame := 0) -> void:
	var tex := Assets.frame(asset, frame)
	area.draw_texture_rect(tex, Rect2(pos.round(), tex.get_size() * 2.0), false)


func _spr_c(asset: String, center: Vector2, frame := 0, rot := 0.0, k := 1.0, off := Vector2.ZERO) -> void:
	var tex := Assets.frame(asset, frame)
	var sz := tex.get_size() * 2.0
	area.draw_set_transform(center + off + _shake_off, rot, Vector2(k, k))
	area.draw_texture_rect(tex, Rect2(-sz / 2.0, sz), false)
	area.draw_set_transform(_shake_off)


func _hud(f: Font, pos: Vector2, text: String, col := Palette.HIGHLIGHT, size := 16) -> void:
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	area.draw_rect(Rect2(pos.x - 5, pos.y - size - 4, w + 10, size + 9), Color(Palette.INK, 0.82))
	area.draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _bar(pos: Vector2, w: float, frac: float, col: Color) -> void:
	area.draw_rect(Rect2(pos, Vector2(w, 10)), Palette.INK)
	area.draw_rect(Rect2(pos + Vector2(2, 2), Vector2((w - 4) * clampf(frac, 0.0, 1.0), 6)), col)


func _draw_plug(f: Font) -> void:
	if not _draw_bg("task_loose_cable"):
		_mars_sky(150)
	_spr("task_socket", PLUG_C - Vector2(70, 70))
	# the plug: turns, wobbles on a miss, pushes in on a hit
	var rot := plug_angle + sin(plug_wobble * 40.0) * 0.18 * plug_wobble
	var push := sin(plug_push * PI)                       # in and back out a little
	_spr_c("task_plug", PLUG_C, 0, rot, 1.0 - 0.14 * push)
	var near := absf(wrapf(plug_angle, -PI, PI)) < 0.4
	_hud(f, Vector2(PLUG_C.x - 50, 216), "TAP NOW!" if near else " WAIT... ", Palette.STATUS_WARN if near else Palette.BASE_STONE, 16)
	# one lamp per cable
	for i in 3:
		_spr("task_lamp", Vector2(410, 40 + i * 40), 1 if i < plugs_done else 0)
		_hud(f, Vector2(446, 60 + i * 40), "%d / 3" % (i + 1), Palette.STATUS_OK if i < plugs_done else Palette.BASE_STONE)


func _draw_sweep(f: Font) -> void:
	if not _draw_bg("task_panel_dust"):
		_mars_sky(60)
		area.draw_rect(Rect2(60, 50, 400, 160), Palette.SKY_INDIGO)
		for x in range(60, 461, 50):
			area.draw_line(Vector2(x, 50), Vector2(x, 210), Palette.SKY_HAZE, 1)
		for y in range(50, 211, 40):
			area.draw_line(Vector2(60, y), Vector2(460, y), Palette.SKY_HAZE, 1)
	for i in dust.size():
		_spr_c("task_dust", dust[i], i % 2)
	var power := 1.0 - float(dust.size()) / float(dust_start)
	_hud(f, Vector2(14, 26), "PANEL POWER %d%%" % int(lerpf(30.0, 100.0, power)))
	_bar(Vector2(9, 32), 216, lerpf(0.3, 1.0, power), Palette.STATUS_WARN)
	_hud(f, Vector2(398, 26), "WIND >>>", Palette.MARS_SAND)


func _draw_moxie(f: Font) -> void:
	if not _draw_bg("task_clogged_filter"):
		area.draw_rect(Rect2(0, 0, AREA.x, AREA.y), Palette.BASE_PLUM)
	var hot := overheat_t > 0.0
	# thermometer: green band = just right
	_spr("task_thermo", Vector2(30, 30))
	var tube := Rect2(40, 40, 32, 172)
	area.draw_rect(Rect2(tube.position.x, tube.position.y + tube.size.y * 0.2, tube.size.x, tube.size.y * 0.2), Color(Palette.STATUS_OK, 0.55))
	var col := Palette.STATUS_DANGER if hot or temp > 0.8 else (Palette.STATUS_OK if _in_band() else Palette.STATUS_WARN)
	area.draw_rect(Rect2(tube.position.x + 6, tube.position.y + tube.size.y * (1.0 - temp), tube.size.x - 12, tube.size.y * temp), col)
	_hud(f, Vector2(30, 26), "HEAT")
	_hud(f, Vector2(90, 40 + 172 * 0.3 + 4), "800 C", Palette.STATUS_OK, 8)
	# MOXIE: Mars air in, oxygen out
	_spr("task_moxie", Vector2(150, 56))
	area.draw_rect(Rect2(160, 74, 108, 24), Palette.STATUS_DANGER if hot else (Palette.STATUS_WARN if temp > 0.3 else Color("2c2450")))
	if temp > 0.3 and not hot:
		for k in 4:
			area.draw_rect(Rect2(166 + k * 26, 78 + int(age * 6.0 + k) % 3 * 4, 14, 4), Palette.HIGHLIGHT)   # glowing coils
	area.draw_string(f, Vector2(162, 148), "MOXIE", HORIZONTAL_ALIGNMENT_CENTER, 104, 16, Palette.INK)
	_hud(f, Vector2(150, 44), "MARS AIR IN", Palette.MARS_SAND)
	_spr("task_tank", Vector2(296, 52))
	area.draw_rect(Rect2(302, 66 + 92 * (1.0 - oxygen), 36, 92 * oxygen), Palette.SKY_HAZE)
	_hud(f, Vector2(354, 76), "OXYGEN", Palette.SKY_HAZE)
	_spr("task_heat_button", Vector2(360, 150), 1 if holding else 0)
	area.draw_string(f, Vector2(360, 186 + (4 if holding else 0)), "COOLING" if hot else "HOLD: HEAT", HORIZONTAL_ALIGNMENT_CENTER, 140, 16, Palette.INK)


func _draw_leaks(f: Font) -> void:
	if not _draw_bg("task_airlock_leak"):
		area.draw_rect(Rect2(0, 0, AREA.x, AREA.y), SKY_TOP)
		area.draw_rect(Rect2(0, 200, AREA.x, 30), Palette.MARS_RUST)
		area.draw_rect(Rect2(150, 22, 220, 198), Palette.BASE_MAUVE)
		area.draw_rect(Rect2(166, 34, 188, 174), Palette.BASE_STONE)
		area.draw_rect(Rect2(166, 34, 188, 174), Palette.INK, false, 3)
		area.draw_circle(Vector2(260, 121), 26, Palette.BASE_PLUM)
		area.draw_arc(Vector2(260, 121), 26, 0, TAU, 24, Palette.INK, 3)
		area.draw_line(Vector2(240, 121), Vector2(280, 121), Palette.BASE_CREAM, 4)
	for i in leaks.size():
		if leak_fixed[i]:
			var pop := patch_pop[i] if i < patch_pop.size() else 0.0
			_spr_c("task_patch", leaks[i], 0, 0.0, 1.0 + 0.5 * sin(pop * PI))   # the patch pops on
	_hud(f, Vector2(14, 26), "LEAKS LEFT: %d" % leak_fixed.count(false))
	_hud(f, Vector2(404, 26), "AIR %d%%" % int(100.0 * t_left / time_limit), Palette.SKY_HAZE)


func _draw_water(f: Font) -> void:
	var has_bg := _draw_bg("task_greenhouse_leak")
	if not has_bg:
		area.draw_rect(Rect2(0, 0, AREA.x, AREA.y), Color("#1E3B2A"))
	for x in range(0, int(AREA.x), 32):
		_spr("task_pipe", Vector2(x, 26))
	if clamped:
		_spr_c("task_clamp", Vector2(leak_x, 36))
	else:
		_spr_c("task_drop", Vector2(leak_x, 50 + 2.0 * sin(age * 9.0)))       # the leak bulges before it drips
		if caught >= 5:
			area.draw_arc(Vector2(leak_x, 38), 22 + 4 * sin(age * 8.0), 0, TAU, 24, Palette.STATUS_WARN, 3)
	for d in drops:
		_spr_c("task_drop", d)
	if not has_bg:
		for i in 7:
			var x := 30.0 + i * 75.0
			area.draw_rect(Rect2(x - 10, 214, 20, 16), Palette.MARS_CRIMSON)
			area.draw_circle(Vector2(x, 208), 8, Palette.STATUS_OK)
	# the bucket fills up; it tilts a little while it glides
	area.draw_rect(Rect2(cup_x - 18, 206 - 4 * caught, 36, 4 * caught), EARTH_BLUE)
	_spr_c("task_cup", Vector2(cup_x, 196), 0, clampf((cup_target - cup_x) * 0.004, -0.2, 0.2))
	_hud(f, Vector2(14, 78), "DROPS SAVED: %d / 5" % caught)


func _draw_shield(f: Font) -> void:
	if not _draw_bg("task_shelter_seal"):
		_mars_sky(220)
	var line_y := 214.0 - WALL_TARGET * 30.0
	# space particles raining down
	for k in 14:
		var x := fmod(k * 37.0 + age * 160.0, AREA.x)
		var y := fmod(k * 53.0 + age * 220.0, 220.0)
		area.draw_rect(Rect2(x, y, 2, 6), Color(Palette.STATUS_WARN, 0.7))
	# striped marker pole: its green flag is the safe height
	_spr("task_marker", Vector2(20, line_y - 2))
	for x in range(64, 460, 12):
		area.draw_rect(Rect2(x, line_y - 1, 6, 2), Palette.STATUS_OK)
	for i in cols.size():
		var x := 70.0 + i * 64.0
		for b in cols[i]:
			var y := 214.0 - (b + 1) * 30.0
			if b == cols[i] - 1 and i < bag_drop.size() and bag_drop[i] > 0.0:
				# the newest bag falls in and bounces once
				var u := 1.0 - bag_drop[i]
				y -= (1.0 - u) * 70.0 if u < 0.7 else sin((u - 0.7) / 0.3 * PI) * 6.0
			_spr("task_sandbag", Vector2(x + (4 if b % 2 else -2), y), (i + b) % 2)
		if cols[i] < WALL_TARGET:
			var ty := 214.0 - (cols[i] + 1) * 30.0 + 18.0 + 2.0 * sin(age * 5.0 + i)
			_hud(f, Vector2(x + 18, ty), "TAP", Palette.HIGHLIGHT, 8)
	_hud(f, Vector2(96, 26), "PILE UP TO THE GREEN FLAG")


func _draw_earth(f: Font) -> void:
	if not _draw_bg("task_dish_drift"):
		_mars_sky(190)
	var e := _earth_pos()
	area.draw_circle(e, 16 + 2.0 * sin(age * 3.0), Color(EARTH_BLUE, 0.22))
	_spr_c("task_earth", e)
	area.draw_rect(Rect2(e + Vector2(14, -10), Vector2(4, 4)), Palette.BASE_STONE)   # the Moon
	_hud(f, e + Vector2(20, 30), "EARTH", EARTH_BLUE, 8)
	# the dish swings smoothly to point at the crosshair
	var base := Vector2(70, 200)
	_spr("task_dish_base", base - Vector2(24, 0))
	var dirv := (aim_draw - base).normalized()
	_spr_c("task_dish_head", base + dirv * 18.0, 0, dirv.angle())
	var locked := aim.distance_to(e) < 20.0
	if locked:
		for k in 3:                                               # signal travelling to Earth
			var u := fmod(age * 1.5 + k / 3.0, 1.0)
			area.draw_rect(Rect2(base.lerp(e, u) - Vector2(2, 2), Vector2(4, 4)), Palette.STATUS_OK)
	_spr_c("task_cross", aim, 1 if locked else 0, 0.0, 1.0 + (0.08 * sin(age * 10.0) if locked else 0.0))
	_hud(f, Vector2(14, 26), "SIGNAL")
	_bar(Vector2(104, 13), 160, lock_t / 1.6, Palette.STATUS_OK)
