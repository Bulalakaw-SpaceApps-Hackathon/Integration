class_name CutscenePlayer
extends Control
## Lightweight storybook cutscene UI. It never changes simulation or reward state.

signal continued(next_route: String)
signal skipped(next_route: String)

var beat: CutsceneBeat
var panel_index: int = 0
var elapsed_sec: float = 0.0
var art: TextureRect
var shade: ColorRect
var title_label: Label
var caption_label: Label
var progress_label: Label
var continue_button: Button
var skip_button: Button
var finished: bool = false
var portrait: TextureRect
var transition: Tween
var calm_override: int = -1
var stage: CutsceneStage


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func play(cutscene: CutsceneBeat) -> void:
	beat = cutscene
	finished = false
	panel_index = 0
	elapsed_sec = 0.0
	_show_panel()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Palette.SKY_NIGHT
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	art = TextureRect.new()
	art.position = Vector2(64, 150)
	art.size = Vector2(720, 320)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

	shade = ColorRect.new()
	shade.color = Color(Palette.INK, 0.48)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	portrait = TextureRect.new()
	portrait.position = Vector2(820, 170)
	portrait.size = Vector2(320, 300)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	stage = CutsceneStage.new()
	stage.position = Vector2(272, 146)
	stage.size = Vector2(736, 414)
	add_child(stage)

	var header := VBoxContainer.new()
	header.position = Vector2(48, 42)
	header.custom_minimum_size = Vector2(760, 0)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)
	title_label = Ui.label("", Ui.HUGE, true, Palette.HIGHLIGHT, 760)
	header.add_child(title_label)
	progress_label = Ui.body("", 20, true, Palette.HIGHLIGHT, 760)
	header.add_child(progress_label)

	var caption_box := PanelContainer.new()
	caption_box.position = Vector2(84, 566)
	caption_box.size = Vector2(1112, 76)
	caption_box.add_theme_stylebox_override("panel", Ui.nine("ui_briefing", 14))
	add_child(caption_box)
	caption_label = Ui.body("", 20, false, Palette.INK, 1050)
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_box.add_child(caption_label)

	var buttons := HBoxContainer.new()
	buttons.position = Vector2(84, 648)
	buttons.size = Vector2(1112, 64)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 18)
	add_child(buttons)
	skip_button = Ui.button("SKIP INTRO", _skip, Vector2(220, 64))
	buttons.add_child(skip_button)
	continue_button = Ui.button("CONTINUE", _continue, Vector2(260, 64))
	buttons.add_child(continue_button)
	skip_button.focus_mode = Control.FOCUS_ALL
	continue_button.focus_mode = Control.FOCUS_ALL
	continue_button.grab_focus()


func _process(delta: float) -> void:
	if finished or beat == null or beat.panel_count() == 0:
		return
	elapsed_sec += delta
	var duration := beat.duration_for(panel_index)
	if duration > 0.0 and elapsed_sec >= duration:
		_advance_or_finish()


func _input(event: InputEvent) -> void:
	if finished or beat == null:
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		if key.keycode == KEY_ESCAPE:
			_skip()
			get_viewport().set_input_as_handled()
		elif key.keycode in [KEY_ENTER, KEY_SPACE]:
			_continue()
			get_viewport().set_input_as_handled()


func _show_panel() -> void:
	if beat == null or panel_index >= beat.panel_count():
		return
	elapsed_sec = 0.0
	var asset := beat.panel_assets[panel_index]
	var speaker: String = beat.portrait_assets[panel_index] if panel_index < beat.portrait_assets.size() else ""
	stage.show_panel(asset, speaker, beat.id == "CS-15")
	art.hide()
	portrait.hide()
	art.texture = Assets.frame(asset, 0)
	# Buildings are foreground objects; preserve their silhouette rather than cropping.
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = null
	if panel_index < beat.portrait_assets.size() and beat.portrait_assets[panel_index] != "":
		portrait.texture = Assets.frame(beat.portrait_assets[panel_index], 0)
	if transition:
		transition.kill()
	portrait.position = Vector2(820, 170)
	art.modulate.a = 1.0
	portrait.modulate.a = 1.0
	var calm_enabled: bool = Progression.calm_mode if calm_override < 0 else calm_override == 1
	stage.modulate.a = 1.0
	if not calm_enabled and beat.fade_sec > 0.0:
		art.modulate.a = 0.0
		portrait.modulate.a = 0.0
		portrait.position.x += beat.portrait_slide_px
		transition = create_tween().set_parallel(true)
		stage.modulate.a = 0.0
		transition.tween_property(stage, "modulate:a", 1.0, beat.fade_sec)
		transition.tween_property(art, "modulate:a", 1.0, beat.fade_sec)
		transition.tween_property(portrait, "modulate:a", 1.0, beat.fade_sec)
		transition.tween_property(portrait, "position:x", 820.0, beat.fade_sec).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	title_label.text = beat.title
	caption_label.text = beat.captions[panel_index]
	progress_label.text = "STORY %d / %d" % [panel_index + 1, beat.panel_count()]
	continue_button.text = "CONTINUE"
	skip_button.text = "SKIP STORY"


func _continue() -> void:
	_advance_or_finish()


func _advance_or_finish() -> void:
	if finished or beat == null:
		return
	panel_index += 1
	if panel_index < beat.panel_count():
		_show_panel()
		return
	finished = true
	continued.emit(beat.next_route)
	queue_free()


func _skip() -> void:
	if finished or beat == null:
		return
	finished = true
	skipped.emit(beat.next_route)
	queue_free()
