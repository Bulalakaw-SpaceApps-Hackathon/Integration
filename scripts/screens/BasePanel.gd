class_name BasePanel
extends Control
## An overlay card on top of any screen (opened with Game.open_panel). Dims what is behind,
## has a title and a CLOSE button. Subclasses fill `body` in _build().

var body: VBoxContainer
var card_width := 820.0
var card_asset := "ui_panel"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Ui.dim(self)
	body = Ui.card(self, card_asset, card_width)
	_build()


func _build() -> void:
	pass


func title(text: String) -> void:
	body.add_child(Ui.label(text, Ui.BIG, true))


func close_row(extra: Array = []) -> HBoxContainer:
	var r := Ui.row(body)
	for b in extra:
		r.add_child(b)
	r.add_child(Ui.button("CLOSE", close, Vector2(180, 56)))
	return r


func close() -> void:
	Game.close_panel(self)


func scroll(height := 380.0) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(card_width - 60, height)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	return v
