class_name SpotlightOverlay
extends Control
## Darkens the screen outside a target rectangle while leaving all underlying buttons clickable.

var shades: Array[ColorRect] = []
var frame: Panel
var arrow: TextureRect
var bubble: PanelContainer
var bubble_label: Label
var _arrow_t := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	for i in 4:
		var r := ColorRect.new()
		r.color = Color(0.03, 0.02, 0.06, 0.64)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)
		shades.append(r)

	frame = Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = Palette.HIGHLIGHT
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(8)
	frame.add_theme_stylebox_override("panel", sb)
	add_child(frame)

	bubble = PanelContainer.new()
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_theme_stylebox_override("panel", Ui.nine("ui_popup", 12))
	bubble.custom_minimum_size = Vector2(360, 0)
	add_child(bubble)
	bubble_label = Ui.body("", 18, false, Palette.INK, 340)
	bubble.add_child(bubble_label)

	arrow = Ui.image("ui_hint_arrow", 0)
	arrow.size = Vector2(64, 64)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arrow)

	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_arrow_t += delta
	arrow.texture = Assets.frame("ui_hint_arrow", int(_arrow_t * 3.0) % 2)


func point_at(target: Rect2, message: String) -> void:
	var vw := 1280.0
	var vh := 720.0
	var x1 := clampf(target.position.x, 0.0, vw)
	var y1 := clampf(target.position.y, 0.0, vh)
	var x2 := clampf(target.end.x, x1, vw)
	var y2 := clampf(target.end.y, y1, vh)

	shades[0].position = Vector2.ZERO
	shades[0].size = Vector2(vw, y1)
	shades[1].position = Vector2(0.0, y2)
	shades[1].size = Vector2(vw, vh - y2)
	shades[2].position = Vector2(0.0, y1)
	shades[2].size = Vector2(x1, y2 - y1)
	shades[3].position = Vector2(x2, y1)
	shades[3].size = Vector2(vw - x2, y2 - y1)

	frame.position = Vector2(x1 - 4.0, y1 - 4.0)
	frame.size = Vector2(x2 - x1 + 8.0, y2 - y1 + 8.0)

	var cx := (x1 + x2) * 0.5
	var top_space := y1
	var place_below := top_space < 150.0
	arrow.flip_v = place_below
	if place_below:
		arrow.position = Vector2(clampf(cx - 32.0, 8.0, vw - 72.0), y2 + 4.0)
	else:
		arrow.position = Vector2(clampf(cx - 32.0, 8.0, vw - 72.0), y1 - 66.0)

	bubble_label.text = message
	bubble.reset_size()
	var bw := maxf(bubble.size.x, 360.0)
	var bh := maxf(bubble.size.y, 56.0)
	var bx := clampf(cx - bw * 0.5, 16.0, vw - bw - 16.0)
	var by := (arrow.position.y + 68.0) if place_below else (arrow.position.y - bh - 6.0)
	by = clampf(by, 12.0, vh - bh - 12.0)
	bubble.position = Vector2(bx, by)
	visible = true
	move_to_front()
