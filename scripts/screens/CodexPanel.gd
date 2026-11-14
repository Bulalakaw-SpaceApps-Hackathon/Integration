extends BasePanel
## R-04 Codex: 9 entries, unlocked by winning nights (all open in Judge Mode).

var page: VBoxContainer
var entries: Array[CodexEntry] = []


func _build() -> void:
	card_width = 980
	body.custom_minimum_size.x = 940
	title("CODEX")
	for f in DirAccess.get_files_at("res://data/codex"):
		var path := "res://data/codex/" + f.trim_suffix(".remap")
		if path.ends_with(".tres"):
			var e := load(path) as CodexEntry
			if e:
				entries.append(e)
	entries.sort_custom(func(a: CodexEntry, b: CodexEntry) -> bool: return a.order < b.order)

	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 20)
	body.add_child(split)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	split.add_child(grid)
	for e in entries:
		var open := _unlocked(e.id)
		var b := TextureButton.new()
		b.texture_normal = Assets.tex("codex_" + e.id)
		b.custom_minimum_size = Vector2(72, 72)
		b.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
		b.ignore_texture_size = true
		b.focus_mode = Control.FOCUS_NONE
		b.modulate = Color.WHITE if open else Color(0.2, 0.15, 0.2, 1)
		b.tooltip_text = e.title if open else "LOCKED"
		b.pressed.connect(func() -> void:
			Sfx.play("click")
			_show(e))
		grid.add_child(b)

	var pp := PanelContainer.new()
	pp.add_theme_stylebox_override("panel", Ui.nine("ui_codex_page", 14))
	pp.custom_minimum_size = Vector2(640, 330)
	split.add_child(pp)
	page = VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	pp.add_child(page)
	var first: CodexEntry = null
	for e in entries:
		if _unlocked(e.id):
			first = e
			break
	if first:
		_show(first)
	else:
		page.add_child(Ui.label("WIN A NIGHT TO UNLOCK YOUR FIRST CODEX PAGE.", Ui.BODY, true, Palette.INK, 580))
	close_row()


func _unlocked(id: String) -> bool:
	return Progression.judge_mode or Progression.codex.has(id)


func _show(e: CodexEntry) -> void:
	for ch in page.get_children():
		ch.queue_free()
	if not _unlocked(e.id):
		page.add_child(Ui.label("LOCKED. WIN MORE NIGHTS TO OPEN THIS PAGE.", Ui.BODY, true, Palette.INK, 580))
		return
	var head := Ui.row(page, 12, BoxContainer.ALIGNMENT_BEGIN)
	head.add_child(Ui.image("codex_" + e.id))
	head.add_child(Ui.label(e.title, Ui.BODY, true, Palette.INK, 400))
	head.add_child(Ui.badge(e.badge))
	page.add_child(Ui.label(e.text, Ui.BODY, false, Palette.INK, 590))
	if e.real_number != "":
		page.add_child(Ui.label("REAL NUMBER: " + e.real_number, Ui.BODY, true, Palette.BASE_PLUM, 590))
	page.add_child(Ui.label("SOURCE: " + e.source, 8, false, Palette.BASE_PLUM, 590))
