extends Control
## Review-only screen: does not call campaign completion or save functions.

var selection: OptionButton
var player: CutscenePlayer
var calm: CheckButton
var status: Label
var index: int = 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bar: HBoxContainer = HBoxContainer.new()
	bar.position = Vector2(24, 8)
	bar.add_theme_constant_override("separation", 8)
	selection = OptionButton.new()
	selection.custom_minimum_size = Vector2(370, 64)
	for i in range(16):
		var beat: CutsceneBeat = load(_path(i)) as CutsceneBeat
		selection.add_item("%s: %s" % [beat.id, beat.title])
	selection.item_selected.connect(_select)
	bar.add_child(selection)
	bar.add_child(Ui.button("PREV", func() -> void: _select(posmod(index - 1, 16)), Vector2(110, 64)))
	bar.add_child(Ui.button("NEXT", func() -> void: _select((index + 1) % 16), Vector2(110, 64)))
	bar.add_child(Ui.button("REPLAY", _replay, Vector2(130, 64)))
	calm = CheckButton.new()
	calm.text = "CALM"
	calm.custom_minimum_size = Vector2(130, 64)
	calm.button_pressed = Progression.calm_mode
	calm.toggled.connect(func(_on: bool) -> void: _replay())
	bar.add_child(calm)
	bar.add_child(Ui.button("EXIT", func() -> void: Game.goto("title"), Vector2(110, 64)))
	status = Ui.body("", 20, false, Palette.HIGHLIGHT)
	status.position = Vector2(48, 420)
	add_child(status)
	add_child(bar)
	_replay()
	move_child(bar, -1)


func _path(i: int) -> String:
	return "res://data/cutscenes/cs_00_opening.tres" if i == 0 else "res://data/cutscenes/cs_%02d.tres" % i


func _select(i: int) -> void:
	index = i
	selection.select(i)
	_replay()


func _replay() -> void:
	if is_instance_valid(player):
		player.hide()
		player.set_process_input(false)
		player.queue_free()
	status.text = ""
	player = preload("res://scenes/CutscenePlayer.tscn").instantiate() as CutscenePlayer
	player.calm_override = 1 if calm.button_pressed else 0
	add_child(player)
	move_child(player, 0)
	# Leave room for the gallery toolbar without shrinking captions or controls.
	(player.title_label.get_parent() as Control).position.y = 82
	player.continued.connect(_finished)
	player.skipped.connect(_finished)
	player.play(load(_path(index)) as CutsceneBeat)


func _finished(_route: String) -> void:
	status.text = "Preview finished. Choose NEXT or REPLAY. Campaign progress is unchanged."
