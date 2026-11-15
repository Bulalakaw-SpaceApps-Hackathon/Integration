extends SceneTree
## Base-map rules: tap a far building -> opens its info (lesson + chart + photo);
## the Control Room stays shut until every unlocked building was visited.
##   xvfb-run godot --path . --rendering-driver opengl3 -s res://tests/hub_playtest.gd
var step := 0
var wait := 10
var game
var prog
var n := 0

func _initialize() -> void:
	change_scene_to_file("res://scenes/Main.tscn")

func shot(name: String) -> void:
	n += 1
	root.get_texture().get_image().save_png("user://hub_%02d_%s.png" % [n, name])
	print("shot ", name)

func click(p: Vector2) -> void:
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = p
		e.global_position = p
		root.push_input(e)

func _process(_d: float) -> bool:
	if game == null:
		game = root.get_node_or_null("Game")
		prog = root.get_node("Progression")
	if wait > 0:
		wait -= 1
		return false
	wait = 12
	match step:
		0: shot("title_new")
		1:
			prog.story_seen = true
			prog.highest_unlocked = 2
			game.goto("title")
		2: shot("title_continue")
		3: game.goto("hub", 2)
		4: game.screen._close_card(); game.screen._start_night()
		5:
			shot("start_blocked")
			print("screen after blocked start: ", game.screen_name)
			click(Vector2(944, 216))             # Life Support plot, far away
			wait = 12
		6:
			print("inside open: ", game.screen.card_layer != null)
			shot("inside_life_support")
		7:
			for id in ["solar", "battery", "greenhouse"]:
				game.screen._show_building(id)
			game.screen._close_card()
		8: shot("all_visited")
		9: game.screen._start_night()
		10: print("screen after start: ", game.screen_name)
		11: return true
	step += 1
	return false
