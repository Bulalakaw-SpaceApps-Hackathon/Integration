extends SceneTree
## Lists every Button / clipped Label whose text is wider than the control.
var n := 0
var steps := [["title", 0], ["night_select", 0], ["hub", 3], ["desk", 3], ["desk", 7]]
var si := 0
func _initialize():
	var f := FileAccess.open("user://save.cfg", FileAccess.WRITE)
	if f: f.store_string("")
	change_scene_to_file("res://scenes/Main.tscn")
func walk(node: Node, where: String) -> void:
	for c in node.get_children():
		if c is Control and not (c as Control).is_visible_in_tree():
			continue
		if c is Button and (c as Button).text != "":
			var b := c as Button
			var font := b.get_theme_font("font"); var fs := b.get_theme_font_size("font_size")
			var w := 0.0
			for line in b.text.split("\n"): w = maxf(w, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
			var sb := b.get_theme_stylebox("normal")
			var room := b.size.x - (sb.get_minimum_size().x if sb else 0.0)
			if w > room + 1.0: print("  OVERFLOW %s button '%s' text %d > room %d" % [where, b.text.replace("\n", "|"), w, room])
		elif c is Label and (c as Label).clip_text and (c as Label).text != "":
			var l := c as Label
			var w2 := l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x
			if w2 > l.size.x + 1.0: print("  OVERFLOW %s label '%s' text %d > %d" % [where, l.text, w2, l.size.x])
		walk(c, where)
func _process(_d):
	n += 1
	var g = root.get_node("Game")
	if n % 40 == 20 and si < steps.size():
		root.get_node("Progression").unlock_all = true
		g.goto(steps[si][0], steps[si][1])
	if n % 40 == 39 and si < steps.size():
		walk(g.screen, "%s%d" % steps[si])
		si += 1
		if si >= steps.size():
			print("done")
			return true
	return false
