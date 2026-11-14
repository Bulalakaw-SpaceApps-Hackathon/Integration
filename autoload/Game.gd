extends Node
## Game flow: which screen is showing, plus the overlay layer (pause menu, panels, toasts)
## that sits above every screen.
##
##   Title -> Night Select -> Hub (Briefing card, Build) -> Desk (Night) -> Debrief
##     won  -> Hub of the next night (or Mission Complete after Night 7)
##     lost -> Retry the same night (upgrades kept, nothing earned counts)

signal screen_changed(name: String)

const SCREENS := {
	"title": "res://scripts/screens/TitleScreen.gd",
	"night_select": "res://scripts/screens/NightSelect.gd",
	"hub": "res://scripts/hub/HubMap.gd",
	"complete": "res://scripts/screens/MissionComplete.gd",
}
const PANELS := {
	"pause": "res://scripts/screens/PausePanel.gd",
	"settings": "res://scripts/screens/SettingsPanel.gd",
	"codex": "res://scripts/screens/CodexPanel.gd",
	"nasa": "res://scripts/screens/NasaPanel.gd",
	"credits": "res://scripts/screens/CreditsPanel.gd",
	"judge": "res://scripts/screens/JudgePanel.gd",
	"real": "res://scripts/screens/RealPanel.gd",
}

var flow := false              # true when the game runs from Main.tscn (false: Desk.tscn on its own)
var night := 1
var tutorial := false          # Night 0: the practice run. Nothing is saved, nothing can fail.
var screen_name := ""
var screen: Node
var holder: Control
var overlay: CanvasLayer
var overlay_root: Control
var panels: Array[Control] = []
var toast_box: VBoxContainer
var visited: Dictionary = {}     # night -> Array of plot ids the Commander went inside today
var theme: Theme                 # FD-02, also set on Controls under CanvasLayers (they don't inherit)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = Ui.make_theme()
	get_tree().root.theme = theme
	overlay = CanvasLayer.new()
	overlay.layer = 20
	add_child(overlay)
	overlay_root = Control.new()
	overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_root.theme = theme
	overlay.add_child(overlay_root)
	toast_box = VBoxContainer.new()
	# bottom-left, growing upward
	toast_box.anchor_top = 1.0
	toast_box.anchor_bottom = 1.0
	toast_box.offset_left = 10
	toast_box.offset_bottom = -26
	toast_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	toast_box.custom_minimum_size = Vector2(440, 0)
	toast_box.alignment = BoxContainer.ALIGNMENT_END
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.add_theme_constant_override("separation", 6)
	toast_box.theme = theme
	overlay.add_child(toast_box)


## Called by Main.tscn. Everything after this is driven by Game.
func attach(main: Control) -> void:
	flow = true
	holder = main
	goto("title")


func goto(name: String, night_id := -1) -> void:
	if night_id > 0 and night_id != night:
		SimState.sponsor_tonight = false         # sponsor deals are per night
	if night_id > 0:
		night = night_id
	if tutorial and name not in ["hub", "desk"]:
		_end_tutorial(false)
	close_all_panels()
	SimState.stop_night()
	Sfx.stop_all_loops()
	if screen:
		screen.queue_free()
		screen = null
	screen_name = name
	if name == "desk":
		SimState.tutorial_tonight = tutorial
		screen = load("res://scenes/Desk.tscn").instantiate()
	else:
		var script: GDScript = load(SCREENS[name])
		screen = script.new()
	holder.add_child(screen)
	Sfx.music(name in ["title", "night_select", "hub", "complete"])
	screen_changed.emit(name)


## Night 0 (TUTORIAL on the title screen): every building unlocked, then a guided practice night.
func start_tutorial() -> void:
	if Progression.judge_mode:
		Progression.leave_judge_mode()
	tutorial = true
	Progression.unlock_all = true
	Progression.resting.clear()
	visited.erase(0)
	night = 0
	goto("hub")


## Put the real save back. `done` = the practice night was finished: "Ready for duty!" badge.
func _end_tutorial(done: bool) -> void:
	tutorial = false
	Progression.leave_judge_mode()        # throws away everything the practice run changed
	visited.erase(0)
	if done:
		Progression.ready_badge = true
		Progression.save_game()


func finish_tutorial() -> void:
	_end_tutorial(true)
	goto("title")
	toast("Ready for duty, Commander! Press NEW GAME to start Night 1.", "info", 6.0)


## Desk asks for this when the player presses the debrief button.
func night_finished(won: bool) -> void:
	if not won:
		goto("desk")                        # Retry Night
	elif night >= Progression.NIGHT_COUNT:
		goto("complete")
	else:
		goto("hub", night + 1)


# ---------------------------------------------------------------- panels (overlays)
func open_panel(name: String) -> Control:
	var script: GDScript = load(PANELS[name])
	var p: Control = script.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_root.add_child(p)
	panels.append(p)
	_update_pause()
	return p


func close_panel(p: Control) -> void:
	panels.erase(p)
	p.queue_free()
	_update_pause()


func close_all_panels() -> void:
	for p in panels:
		p.queue_free()
	panels.clear()
	_update_pause()


func top_panel() -> Control:
	return panels.back() if not panels.is_empty() else null


func _update_pause() -> void:
	# a night is frozen while any panel is open on top of it
	SimState.paused = SimState.running and not panels.is_empty()


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_M:
		toggle_mute()
		get_viewport().set_input_as_handled()
	elif k.keycode == KEY_ESCAPE and flow:
		get_viewport().set_input_as_handled()
		if top_panel():
			close_panel(top_panel())
		elif screen_name in ["desk", "hub"]:
			open_panel("pause")


func toggle_mute() -> void:
	Progression.muted = not Progression.muted
	Progression.save_game()
	Sfx.apply_mute()
	toast("Sound off" if Progression.muted else "Sound on", "info")


# ---------------------------------------------------------------- toasts
## Small message at the top (icon + shape + text). More than 4 at once are grouped.
func toast(text: String, kind := "info", seconds := 4.0) -> void:
	if toast_box.get_child_count() >= 4:
		toast_box.get_child(0).queue_free()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Ui.nine("ui_popup", 12))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	h.add_child(Ui.image("alert_" + kind))
	var l := Ui.label(text, 8, true, Palette.INK, 360)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	toast_box.add_child(p)
	var t := get_tree().create_timer(seconds, true, false, true)
	t.timeout.connect(p.queue_free)
