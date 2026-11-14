extends Control
## P-04 / SC-08 Mission Complete after Night 7: total stars + Mission Planner Certificate
## (downloadable as a PNG in the web build, saved to user:// on desktop).

var cert: PanelContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := Ui.image("screen_complete")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)
	Sfx.play("sunrise")

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	center.add_child(v)

	cert = PanelContainer.new()
	cert.add_theme_stylebox_override("panel", Ui.nine("ui_certificate", 16))
	cert.custom_minimum_size = Vector2(820, 380)
	v.add_child(cert)
	var c := VBoxContainer.new()
	c.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_theme_constant_override("separation", 12)
	cert.add_child(c)
	for l in [Ui.label("THE SUPPLY SHIP HAS LANDED!", Ui.HUGE, true), Ui.label("MISSION PLANNER CERTIFICATE", Ui.BIG, true, Palette.BASE_PLUM),
			Ui.label("This certifies that the Commander of Bulalakaw Station kept the whole crew safe through 7 Mars nights, balancing power, air, food and radiation shielding.", Ui.BODY, false, Palette.INK, 740)]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(l)
	var total := Progression.total_stars()
	var st := Ui.row(c, 8)
	st.add_child(Ui.image("ui_star_full"))
	st.add_child(Ui.label("%d / %d STARS" % [total, Progression.NIGHT_COUNT * 3], Ui.BIG, true))
	var disc := Ui.label("SCIENCE DISCOVERIES: %d / %d" % [Progression.discoveries.size(), Progression.NIGHT_COUNT], Ui.BODY, true, Palette.STATUS_OK_SHADE)
	disc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(disc)
	var date := Ui.label(Time.get_date_string_from_system() + " · NASA SPACE APPS 2026", 8, false, Palette.BASE_PLUM)
	date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(date)

	var btns := Ui.row(v)
	btns.add_child(Ui.button("SAVE CERTIFICATE", _save, Vector2(280, 64)))
	btns.add_child(Ui.button("BACK TO TITLE", func() -> void: Game.goto("title"), Vector2(260, 64)))


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
