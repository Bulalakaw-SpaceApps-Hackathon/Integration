class_name WindowView
extends Control
## One live window of the desk room (DK-01b). The desk background has the glass cut out; this sits
## behind it and draws the Mars sky for the current game hour:
##   18:00-19:00  blue Mars sunset in the west (left) window, the sun sinks behind the hills
##   night        stars turn slowly and twinkle, Phobos races across, Deimos creeps, Earth sets
##   05:00-06:00  sunrise glow in the east (right) window
##   hazards      dust storm haze + blowing dust, bright sky pulse when a flare's light arrives
## Every object is placed in SCREEN coordinates, so Phobos can leave one window and enter the other.
## Only palette colours are drawn (layer swaps use the dither_mix shader). Read-only: no game rules.

const DIR := "res://assets/sprites/desk/window/"
const SHADER := preload("res://shaders/dither_mix.gdshader")

var key := "L"
var hour := 18.0       # 18.0 .. 30.0 (30 = 06:00 next morning)
var dust := 0.0        # 0..1 dust-storm strength
var flare := 0.0       # 0..1 flare light
var t := 0.0           # real seconds, for twinkle / blink / wind

var sky: TextureRect
var sky_mat: ShaderMaterial
var storm: TextureRect
var storm_mat: ShaderMaterial
var tex_dusk: Texture2D
var tex_dawn: Texture2D
var tex_flare: Texture2D
var celestial: _Layer
var weather: _Layer

static var _stars: Array = []       # shared by both windows: [Vector2 pos, phase, speed]


func setup(window_key: String, rect: Rect2) -> void:
	key = window_key
	position = rect.position
	size = rect.size
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_dusk = load(DIR + "sky_dusk_%s.png" % key)
	tex_dawn = load(DIR + "sky_dawn_%s.png" % key)
	tex_flare = load(DIR + "sky_flare_%s.png" % key)

	sky = _rect(load(DIR + "sky_night_%s.png" % key))
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = SHADER
	sky.material = sky_mat
	celestial = _Layer.new(self, true)
	add_child(celestial)
	_rect(load(DIR + "hills_%s.png" % key))
	storm = _rect(load(DIR + "sky_storm_%s.png" % key))
	storm_mat = ShaderMaterial.new()
	storm_mat.shader = SHADER
	storm_mat.set_shader_parameter("overlay", true)
	storm.material = storm_mat
	weather = _Layer.new(self, false)
	add_child(weather)

	if _stars.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 70:
			_stars.append([Vector2(rng.randi_range(150, 1030), rng.randi_range(106, 232)),
				rng.randf() * TAU, rng.randf_range(0.6, 2.2)])


func _rect(tex: Texture2D) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func set_state(h: float, dust_amt: float, flare_amt: float) -> void:
	hour = h
	dust = clampf(dust_amt, 0.0, 1.0)
	flare = clampf(flare_amt, 0.0, 1.0)


func _process(delta: float) -> void:
	t += delta
	# which glow layer is mixed over the night sky
	var tex_b: Texture2D = tex_dusk
	var amt := 0.0
	if flare > 0.01:
		tex_b = tex_flare
		amt = flare * (0.75 + 0.25 * sin(t * 5.0))          # the sky throbs while the flare light arrives
	elif hour < 19.0:
		amt = clampf(19.0 - hour, 0.0, 1.0)                  # sunset fades over the first game hour
	elif hour >= 29.0:
		tex_b = tex_dawn
		amt = clampf(hour - 29.0, 0.0, 1.0)                  # sunrise during the last game hour
	sky_mat.set_shader_parameter("tex_b", tex_b)
	sky_mat.set_shader_parameter("mix_t", amt)
	storm_mat.set_shader_parameter("mix_t", dust)           # full storm = solid haze, weaker storm = see-through dither
	celestial.glow = amt
	celestial.queue_redraw()
	weather.queue_redraw()


func glow_now() -> float:
	return celestial.glow


# ---------------------------------------------------------------------------
class _Layer extends Control:
	## sky objects (behind the hills) or weather (in front of the hills)
	var w: WindowView
	var behind_hills: bool
	var glow := 0.0

	func _init(win: WindowView, is_sky: bool) -> void:
		w = win
		behind_hills = is_sky
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if behind_hills:
			_draw_sky()
		else:
			_draw_weather()

	func _px(p: Vector2, s: Vector2, col: Color) -> void:
		# screen coords -> local, snapped to whole pixels
		draw_rect(Rect2((p - w.position).floor(), s), col)

	func _disc(c: Vector2, rx: int, ry: int, fill: Color, outline: Color) -> void:
		for dy in range(-ry - 1, ry + 2):
			for dx in range(-rx - 1, rx + 2):
				var e := pow(dx / (rx + 0.5), 2) + pow(dy / (ry + 0.5), 2)
				var o := pow(dx / (rx + 1.5), 2) + pow(dy / (ry + 1.5), 2)
				if e <= 1.0:
					_px(c + Vector2(dx, dy), Vector2.ONE, fill)
				elif o <= 1.0:
					_px(c + Vector2(dx, dy), Vector2.ONE, outline)

	func _draw_sky() -> void:
		var night_p := clampf((w.hour - 18.0) / 12.0, 0.0, 1.0)
		var hide := maxf(glow, w.dust)
		# stars: the whole sky turns slowly westward (left) through the night, and they twinkle
		for s in WindowView._stars:
			var p: Vector2 = s[0] - Vector2(night_p * 60.0, 0.0)
			if fposmod(s[1], 1.0) < hide:              # glow / dust hides the faint ones first
				continue
			var b := sin(w.t * s[2] + s[1])
			if b > -0.55:
				_px(p, Vector2(2, 2), Palette.HIGHLIGHT if b > 0.2 else Palette.BASE_STONE)
		# a shooting star now and then (Mars gets meteors too), skipped when the sky is bright
		var mt := fposmod(w.t + (0.0 if w.key == "L" else 9.0), 17.0)
		if mt < 0.6 and hide < 0.3:
			var start := Vector2(w.position.x + w.size.x * 0.75, w.position.y + 12.0)
			var head := start + Vector2(-90.0, 36.0) * (mt / 0.6)
			for k in 4:
				_px(head + Vector2(k * 4, -k * 2), Vector2(2, 2), Palette.HIGHLIGHT if k == 0 else Palette.SKY_HAZE)
		# Earth: a blue dot low in the east (right) window that sets before dawn
		var e := Vector2(852, lerpf(176.0, 262.0, clampf((w.hour - 18.0) / 9.0, 0.0, 1.0)))
		if glow < 0.6 and w.dust < 0.6:
			_px(e - Vector2(2, 2), Vector2(5, 5), Palette.SKY_HAZE)
			if sin(w.t * 1.7) > 0.0:
				for d in [Vector2(-4, 0), Vector2(4, 0), Vector2(0, -4), Vector2(0, 4)]:
					_px(e + d, Vector2.ONE, Palette.SKY_HAZE)
		# Deimos: small and slow, creeps across the east window
		_moon(Vector2(lerpf(940.0, 990.0, night_p), 158.0 - 6.0 * night_p), 6, 6)
		# Phobos: big, lumpy and FAST, crosses from the west window to the east one (19:00 -> 01:00)
		var pp := (w.hour - 19.0) / 6.0
		if pp > 0.0 and pp < 1.0:
			_moon(Vector2(lerpf(150.0, 1030.0, pp), 214.0 - 92.0 * sin(PI * pp)), 13, 10)
		# the Sun: small (Mars is farther away). Sets in the west window, rises in the east one.
		if w.hour < 19.0:
			_sun(Vector2(277, lerpf(192.0, 286.0, clampf((w.hour - 18.0) / 0.9, 0.0, 1.0))))
		elif w.hour > 29.2:
			_sun(Vector2(935, lerpf(286.0, 226.0, clampf((w.hour - 29.2) / 0.8, 0.0, 1.0))))

	func _moon(c: Vector2, rx: int, ry: int) -> void:
		if w.dust > 0.7:
			return
		_disc(c, rx, ry, Palette.BASE_STONE, Palette.INK)
		_px(c - Vector2(rx / 3 + 2, ry / 3 + 1), Vector2(maxi(rx / 3, 2), maxi(ry / 3, 2)), Palette.BASE_MAUVE)  # craters
		if rx > 8:
			_px(c + Vector2(3, 2), Vector2(3, 2), Palette.BASE_MAUVE)

	func _sun(c: Vector2) -> void:
		_disc(c, 5, 5, Palette.HIGHLIGHT, Palette.SKY_HAZE)

	func _draw_weather() -> void:
		var wind := 10.0 + 140.0 * w.dust                     # px per second
		var count := 6 + int(70.0 * w.dust)
		var x0 := w.position.x
		var span := w.size.x + 40.0
		for i in count:
			var seed := float(i * 37 % 101) / 101.0
			var y := w.position.y + w.size.y - 8.0 - fposmod(seed * 977.0, 40.0 + 100.0 * w.dust)
			var x := x0 - 20.0 + fposmod(seed * span * 3.0 + w.t * wind * (0.6 + seed), span)
			var col := Palette.MARS_SAND if i % 3 else Palette.MARS_ORANGE
			var length := 2.0 if w.dust < 0.3 else 6.0
			_px(Vector2(x, y), Vector2(length, 2), col)
		# the comms mast on the far hill (east window), red light blinks every 1.5 s
		if w.key == "R":
			var base := Vector2(972, 226)
			_px(base - Vector2(0, 20), Vector2(2, 20), Palette.INK)
			_px(base - Vector2(4, 0), Vector2(10, 2), Palette.INK)
			if fposmod(w.t, 1.5) < 0.5:
				_px(base - Vector2(1, 24), Vector2(4, 4), Palette.STATUS_DANGER)
