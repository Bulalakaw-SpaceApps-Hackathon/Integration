extends BasePanel
## P-05 Credits: reads CREDITS.md (Godot MIT notice, fonts, every asset).


func _build() -> void:
	card_width = 1000
	body.custom_minimum_size.x = 960
	title("CREDITS")
	var list := scroll(440)
	var text := "CREDITS.md is missing."
	var f := FileAccess.open("res://CREDITS.md", FileAccess.READ)
	if f:
		text = f.get_as_text()
	for line in text.split("\n"):
		var l := line.strip_edges()
		if l == "":
			continue
		if l.begins_with("#"):
			list.add_child(Ui.label(l.lstrip("# ").to_upper(), Ui.BODY, true, Palette.INK, 900))
		else:
			list.add_child(Ui.label(l.lstrip("-* "), 8, false, Palette.BASE_PLUM, 900))
	close_row()
