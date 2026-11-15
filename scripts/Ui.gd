class_name Ui
extends RefCounted
## FD-02 UI theme + small builders every screen uses. All looks come from the asset files
## (ui_panel, ui_button, ui_popup ...), so swapping those PNGs restyles every screen.

const FONT_R := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const FONT_B := preload("res://assets/fonts/Silkscreen-Bold.ttf")
## Body text (lessons, radio lines, alerts, the tutorial) uses the team's Bulalakaw Readable,
## easier for 7-year-olds than the all-caps pixel font; titles and buttons stay Silkscreen (D63).
const FONT_BODY := preload("res://assets/fonts/BulalakawReadable-Regular.ttf")
const FONT_BODY_B := preload("res://assets/fonts/BulalakawReadable-Bold.ttf")
const FONT_CLOCK := preload("res://assets/fonts/DotGothic16-Regular.ttf")
const BODY := 16
const BIG := 24
const HUGE := 32


static func nine(asset: String, margin := 12, frame := -1) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = Assets.tex(asset) if frame < 0 else Assets.frame(asset, frame)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	sb.content_margin_left = margin + 8
	sb.content_margin_right = margin + 8
	sb.content_margin_top = margin + 4
	sb.content_margin_bottom = margin + 4
	return sb


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = FONT_R
	t.default_font_size = BODY
	t.set_color("font_color", "Label", Palette.INK)
	# buttons: ui_button.png frames = normal, pressed, disabled
	var normal := nine("ui_button", 14, 0)
	var pressed := nine("ui_button", 14, 1)
	var disabled := nine("ui_button", 14, 2)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", pressed)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(k, "Button", Palette.INK)
	t.set_color("font_disabled_color", "Button", Palette.BASE_STONE)
	t.set_font("font", "Button", FONT_B)
	t.set_font_size("font_size", "Button", BODY)
	t.set_stylebox("panel", "PanelContainer", nine("ui_panel", 14))
	t.set_stylebox("panel", "Panel", nine("ui_panel", 14))
	var le := StyleBoxFlat.new()
	le.bg_color = Palette.HIGHLIGHT
	le.border_color = Palette.INK
	le.set_border_width_all(2)
	le.set_content_margin_all(8)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le)
	t.set_color("font_color", "LineEdit", Palette.INK)
	t.set_color("caret_color", "LineEdit", Palette.INK)
	return t


static func label(text: String, size := BODY, bold := false, color := Palette.INK, wrap_width := 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT_B if bold else FONT_R)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap_width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = wrap_width
	return l


## A label in the readable body font. Pixel fonts shrink at 8 px, so body text is at least 14 px.
static func body(text: String, size := BODY, bold := false, color := Palette.INK, wrap_width := 0.0) -> Label:
	var l := label(text, maxi(size, 14), bold, color, wrap_width)
	l.add_theme_font_override("font", FONT_BODY_B if bold else FONT_BODY)
	return l


static func button(text: String, on_press: Callable, min_size := Vector2(200, 64), icon := "") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	if icon != "":
		b.icon = Assets.tex(icon)
	b.pressed.connect(func() -> void: Sfx.play("click"))
	b.pressed.connect(on_press)
	return b


static func icon_button(asset: String, on_press: Callable, tip := "") -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = Assets.tex(asset)
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(64, 64)
	b.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	b.ignore_texture_size = true
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void: Sfx.play("click"))
	b.pressed.connect(on_press)
	return b


static func image(asset: String, frame := -1) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Assets.tex(asset) if frame < 0 else Assets.frame(asset, frame)
	r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## A centred card (PanelContainer with a VBox). Returns the VBox to fill.
static func card(parent: Control, asset := "ui_panel", width := 760.0) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", nine(asset, 14))
	p.custom_minimum_size.x = width
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	return v


static func row(parent: Control, sep := 16, align := BoxContainer.ALIGNMENT_CENTER) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.alignment = align
	parent.add_child(h)
	return h


## Full-screen dim layer that blocks clicks to whatever is behind it.
static func dim(parent: Control, alpha := 0.6) -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(Palette.INK, alpha)
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(d)
	return d


## Honesty badge (SC-05). Tapping it explains what is real and what was simplified.
static func badge(kind: String) -> TextureButton:
	const WHY := {
		"real": "REAL: this date and number come from a real NASA measurement.",
		"simplified": "SIMPLIFIED: based on real science, but the numbers are rounded or shortened for the game.",
		"live": "LIVE: fetched from NASA's DONKI space-weather database today.",
		"archived": "ARCHIVED: real NASA data saved inside the game (no internet needed).",
	}
	var b := TextureButton.new()
	b.texture_normal = Assets.tex("badge_" + kind)
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = WHY.get(kind, "")
	b.pressed.connect(func() -> void: Game.toast(WHY.get(kind, ""), "info"))
	return b


static func stars(n: int, of := 3, px := 0) -> HBoxContainer:
	var h := HBoxContainer.new()
	for i in of:
		var s := image("ui_star_full" if i < n else "ui_star_empty")
		if px > 0:
			s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			s.custom_minimum_size = Vector2(px, px)
		h.add_child(s)
	return h
