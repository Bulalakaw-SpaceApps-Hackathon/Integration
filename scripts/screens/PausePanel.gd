extends BasePanel
## J-02 Pause: Resume, Settings, Codex, Retry Night, Quit.


func _ready() -> void:
	card_width = 500
	super._ready()
	for child in body.get_children():
		if child is Button:
			child.custom_minimum_size.y = 64
			child.add_theme_font_override("font", Ui.FONT_BODY_B)
			child.add_theme_font_size_override("font_size", 24)


func _build() -> void:
	body.custom_minimum_size.x = 440
	title("PAUSED")
	body.add_child(Ui.button("RESUME", close, Vector2(360, 60)))
	body.add_child(Ui.button("SETTINGS", func() -> void: Game.open_panel("settings"), Vector2(360, 56)))
	body.add_child(Ui.button("CODEX", func() -> void: Game.open_panel("codex"), Vector2(360, 56)))
	if Game.screen_name == "desk":
		body.add_child(Ui.button("RETRY NIGHT", func() -> void: Game.goto("desk"), Vector2(360, 56)))
		body.add_child(Ui.button("BACK TO BASE", func() -> void: Game.goto("hub"), Vector2(360, 56)))
	body.add_child(Ui.button("QUIT TO TITLE", func() -> void: Game.goto("title"), Vector2(360, 56)))
