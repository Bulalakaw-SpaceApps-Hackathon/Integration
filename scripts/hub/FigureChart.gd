class_name FigureChart
extends Control
## A simple bar chart for the building lessons, drawn from real numbers in
## data/building_lessons.json: {"title", "unit", "bars": [[label, value], ...]}.
## Negative values (like -70 C) draw to the left of a zero line.

var fig: Dictionary = {}
const COLS := [Palette.SKY_HAZE, Palette.MARS_ORANGE, Palette.STATUS_OK, Palette.CREW_LANI, Palette.STATUS_WARN]


func _init(figure: Dictionary) -> void:
	fig = figure
	custom_minimum_size = Vector2(420, 40 + 30 * maxi(1, (fig.get("bars", []) as Array).size()))
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var f: Font = Ui.FONT_R
	var fb: Font = Ui.FONT_B
	draw_rect(Rect2(Vector2.ZERO, size), Palette.INK)
	draw_string(fb, Vector2(10, 18), str(fig.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 8, Palette.STATUS_WARN)
	var bars: Array = fig.get("bars", [])
	if bars.is_empty():
		return
	var lo := 0.0
	var hi := 0.0
	for b in bars:
		lo = minf(lo, float(b[1]))
		hi = maxf(hi, float(b[1]))
	var span := maxf(hi - lo, 0.0001)
	var label_w := 130.0
	var x0 := label_w + 10.0
	var w := size.x - x0 - 70.0
	var zero_x := x0 + w * (-lo / span)
	var unit := str(fig.get("unit", ""))
	for i in bars.size():
		var b: Array = bars[i]
		var v := float(b[1])
		var y := 30.0 + i * 30.0
		draw_string(f, Vector2(10, y + 14), str(b[0]), HORIZONTAL_ALIGNMENT_LEFT, label_w, 8, Palette.HIGHLIGHT)
		var bx := zero_x if v >= 0.0 else zero_x - w * (-v / span)
		var bw := maxf(2.0, w * absf(v) / span)
		draw_rect(Rect2(bx, y + 2, bw, 16), COLS[i % COLS.size()])
		draw_rect(Rect2(bx, y + 2, bw, 16), Palette.HIGHLIGHT, false, 1.0)
		var txt := (str(int(v)) if is_equal_approx(v, round(v)) else str(v)) + (" " + unit if unit != "" else "")
		draw_string(f, Vector2(x0 + w + 6, y + 14), txt, HORIZONTAL_ALIGNMENT_LEFT, 64, 8, Palette.HIGHLIGHT)
	if lo < 0.0:
		draw_line(Vector2(zero_x, 26), Vector2(zero_x, size.y - 6), Palette.BASE_MAUVE, 1.0)
