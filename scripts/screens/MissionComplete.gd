extends Control
## P-04 / SC-08 Mission Complete after Night 7, all on one screen: the supply ship landing,
## total stars, discoveries, a line from each crew member, PLAY AGAIN, WHAT WAS REAL?
## and the Mission Planner Certificate (PNG download on web, user:// on desktop).

const CREW := ["lani", "maya", "mateo", "carlo"]

var cert: PanelContainer
var ship: Ship


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := Ui.image("screen_complete")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)
	Sfx.play("sunrise")

	ship = Ship.new()
	ship.position = Vector2(1090, 0)
	add_child(ship)

	cert = PanelContainer.new()
	cert.add_theme_stylebox_override("panel", Ui.nine("ui_certificate", 16))
	cert.position = Vector2(40, 30)
	cert.custom_minimum_size = Vector2(900, 0)
	add_child(cert)
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", 10)
	cert.add_child(c)
	var head := Ui.label(Strings.t("end.title"), Ui.BIG, true)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(head)
	var sub := Ui.label("MISSION PLANNER CERTIFICATE · 7 MARS NIGHTS · POWER, AIR, FOOD AND RADIATION SHIELDING", 8, true, Palette.BASE_PLUM, 840)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(sub)

	var stats := Ui.row(c, 28)
	var st := Ui.row(stats, 8)
	st.add_child(Ui.image("ui_star_full"))
	st.add_child(Ui.label("%d / %d STARS" % [Progression.total_stars(), Progression.NIGHT_COUNT * 3], Ui.BIG, true))
	stats.add_child(Ui.label("DISCOVERIES: %d / %d" % [Progression.discoveries.size(), Progression.NIGHT_COUNT], Ui.BIG, true, Palette.STATUS_OK_SHADE))

	# every discovery found, by night
	var names := PackedStringArray()
	for n in range(1, Progression.NIGHT_COUNT + 1):
		if Progression.discoveries.has(n):
			names.append(str(Progression.discoveries[n]))
	if not names.is_empty():
		c.add_child(Ui.label("YOU FOUND: " + " · ".join(names), 8, true, Palette.SKY_INDIGO, 840))

	# a line from each crew member
	for id in CREW:
		var r := Ui.row(c, 10, BoxContainer.ALIGNMENT_BEGIN)
		var h := Ui.image("head_" + id)
		h.custom_minimum_size = Vector2(24, 24)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.add_child(h)
		r.add_child(Ui.label(Strings.t("end." + id), Ui.BODY, false, Palette.INK, 780))
	var date := Ui.label(Time.get_date_string_from_system() + " · NASA SPACE APPS 2026 · TEAM BULALAKAW", 8, false, Palette.BASE_PLUM)
	date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(date)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 12)
	btns.position = Vector2(40, 640)
	add_child(btns)
	btns.add_child(Ui.button("PLAY AGAIN", _play_again, Vector2(220, 60)))
	btns.add_child(Ui.button("WHAT WAS REAL?", func() -> void: Game.open_panel("real"), Vector2(280, 60)))
	btns.add_child(Ui.button("SAVE CERTIFICATE", _save, Vector2(280, 60)))
	btns.add_child(Ui.button("TITLE", func() -> void: Game.goto("title"), Vector2(140, 60)))


func _play_again() -> void:
	if Progression.judge_mode:
		Progression.leave_judge_mode()
	Progression.new_game()
	Game.visited.clear()
	Game.goto("hub", 1)


func _save() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var r := Rect2i(cert.global_position, cert.size)
	img = img.get_region(r.intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	var png := img.save_png_to_buffer()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(png, "bulalakaw_certificate.png", "image/png")
		Game.toast("Certificate downloaded!", "info")
	else:
		var path := "user://bulalakaw_certificate.png"
		img.save_png(path)
		Game.toast("Saved: " + ProjectSettings.globalize_path(path), "info", 6.0)


## The supply ship coming down on its engine flame, then resting on the ground.
class Ship extends Node2D:
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var k := clampf(t / 4.0, 0.0, 1.0)
		var ease_k := 1.0 - pow(1.0 - k, 3.0)
		var y := lerpf(-140.0, 470.0, ease_k)
		var ink := Palette.INK
		# landing pad + dust kicked up while the engine burns
		draw_rect(Rect2(-70, 606, 140, 10), Palette.BASE_STONE)
		draw_rect(Rect2(-70, 606, 140, 10), ink, false, 2.0)
		if k < 1.0:
			var flame := 30.0 + 14.0 * sin(t * 30.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-16, y + 120), Vector2(16, y + 120), Vector2(0, y + 120 + flame)]), Palette.STATUS_WARN)
			draw_colored_polygon(PackedVector2Array([Vector2(-8, y + 120), Vector2(8, y + 120), Vector2(0, y + 120 + flame * 0.6)]), Palette.HIGHLIGHT)
			if k > 0.6:
				for i in 10:
					var a := float(i) * 0.7 + t * 3.0
					draw_circle(Vector2(cos(a) * (40.0 + 30.0 * k), 604.0 - absf(sin(a * 1.7)) * 16.0), 5.0, Color(Palette.MARS_SAND, 0.6))
		# legs
		for sx in [-1.0, 1.0]:
			draw_line(Vector2(sx * 18.0, y + 104), Vector2(sx * 40.0, y + 136), ink, 4.0)
			draw_rect(Rect2(sx * 40.0 - 8.0, y + 134, 16, 4), ink)
		# body
		draw_colored_polygon(PackedVector2Array([Vector2(-26, y + 120), Vector2(-26, y + 30), Vector2(0, y - 16), Vector2(26, y + 30), Vector2(26, y + 120)]), Palette.HIGHLIGHT)
		draw_polyline(PackedVector2Array([Vector2(-26, y + 120), Vector2(-26, y + 30), Vector2(0, y - 16), Vector2(26, y + 30), Vector2(26, y + 120), Vector2(-26, y + 120)]), ink, 3.0)
		draw_rect(Rect2(-26, y + 76, 52, 12), Palette.MARS_ORANGE)
		draw_circle(Vector2(0, y + 48), 11.0, ink)
		draw_circle(Vector2(0, y + 48), 8.0, Palette.SKY_HAZE)
		draw_string(Ui.FONT_B, Vector2(-26, y + 108), "SUPPLY", HORIZONTAL_ALIGNMENT_CENTER, 52, 8, ink)
