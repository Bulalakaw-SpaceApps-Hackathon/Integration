extends BasePanel
## J-02 Pause: Resume, Settings, Codex, Retry Night, Quit.


func _build() -> void:
	card_width = 420
	body.custom_minimum_size.x = 360
	title("PAUSED")
	body.add_child(Ui.button("RESUME", close, Vector2(360, 60)))
	body.add_child(Ui.button("SETTINGS", func() -> void: Game.open_panel("settings"), Vector2(360, 56)))
	body.add_child(Ui.button("CODEX", func() -> void: Game.open_panel("codex"), Vector2(360, 56)))
	if Game.screen_name == "desk":
		body.add_child(Ui.button("RETRY NIGHT", func() -> void: Game.goto("desk"), Vector2(360, 56)))
		body.add_child(Ui.button("BACK TO BASE", func() -> void: Game.goto("hub"), Vector2(360, 56)))
	body.add_child(Ui.button("QUIT TO TITLE", func() -> void: Game.goto("title"), Vector2(360, 56)))
