extends SceneTree

var game: Node
var progress: Node
var sim_state: Node
var bad := 0

func _initialize() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	run.call_deferred()

func frames() -> void:
	for i in 4:
		await process_frame

func check(ok: bool, message: String) -> void:
	print("PASS " if ok else "FAIL ", message)
	bad += int(not ok)

func click(pos: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	root.push_input(motion)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = pos
		event.pressed = pressed
		root.push_input(event)

func escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event)

func button_in(node: Node, title: String) -> Button:
	if node is Button and node.text == title:
		return node
	for child in node.get_children():
		var button := button_in(child, title)
		if button:
			return button
	return null

func press(node: Node, title: String) -> void:
	var button := button_in(node, title)
	check(button != null, title + " visible")
	if button:
		var bounds := button.get_global_rect()
		check(root.get_visible_rect().encloses(bounds), title + " inside viewport")
		click(bounds.get_center())

func shot(name: String) -> void:
	root.get_texture().get_image().save_png(OS.get_environment("BUL_SMOKE_OUT").path_join("bul_" + name + ".png"))

func run() -> void:
	await frames()
	game = root.get_node("Game")
	progress = root.get_node("Progression")
	sim_state = root.get_node("SimState")
	progress.story_seen = true
	progress.resting.clear()
	progress.materials = 20
	game.goto("hub", 7)
	await frames()
	var hub: Node = game.screen
	shot("briefing")
	press(hub.card_layer, "LET'S BUILD")
	await frames()
	check(hub.card_layer == null, "briefing click closes")
	shot("hub")
	var assets: Node = root.get_node("Assets")
	check(hub.commander.sprite.texture == assets.frame("char_commander_eva", 0), "Commander EVA")
	for id in hub.crew_nodes:
		check(hub.crew_nodes[id].texture == assets.frame("crew_%s_eva" % id, 0), id + " EVA")
	var crew: Sprite2D = hub.crew_nodes["maya"]
	click(crew.position - Vector2(0, 40))
	await frames()
	check(hub.card_layer != null, "crew opens by click")
	if hub.card_layer:
		shot("crew")
		press(hub.card_layer, "OK")
	await frames()
	click(Vector2(130, 220))
	await frames()
	check(hub.card_layer != null and game.visited[7].has("solar"), "far plot click opens info")
	if hub.card_layer:
		shot("solar")
		var before: int = progress.materials
		var lv: int = progress.levels["solar"]
		progress.judge_mode = true
		press(hub.card_layer, "UPGRADE")
		await frames()
		check(progress.materials < before and progress.levels["solar"] == lv + 1, "upgrade applies cost and level")
		escape()
		await frames()
		check(hub.card_layer == null and hub.commander.is_physics_processing(), "Escape closes lesson and restores movement")
	progress.seen_guides.append(6)
	game.goto("desk", 6)
	await frames()
	var desk: Control = game.screen
	desk._start_night()
	await frames()
	click(Vector2(1022, 500))
	click(Vector2(348, 76))
	await frames()
	check(desk.help_box.visible and sim_state.paused, "desk clock help opens and pauses")
	if desk.help_box.visible:
		shot("help")
		press(desk.help_box, "CLOSE")
	await frames()
	check(not desk.help_box.visible and not sim_state.paused, "desk help closes and resumes")
	desk._crew_said("maya", "I am checking the greenhouse tonight.")
	sim_state.sim.add_request("maya", "May I turn on the crop lamp?", {}, {}, 60.0)
	desk._open_answer(0, "maya")
	await frames()
	shot("desk_reply")
	press(desk.answer_box, "YES")
	await frames()
	check(desk.answer_box == null and sim_state.sim.open_request_for("maya").is_empty(), "crew reply accepted with alerts visible")
	quit(int(bad > 0))
