extends SceneTree
## Base-map collision bot (D51). With every building built, the Commander walks straight at
## every building, rock and decoration from four sides. While he walks it checks:
##   - his feet never end up inside a solid box (collision holds),
##   - his feet never stand on a sprite's base: the bottom 12 px of its opaque pixels
##     (that is what "clipping into a building" looks like),
##   - his sprite's bottom edge is his node position, so y-sorting compares feet with bases.
##   xvfb-run -a godot --path . --rendering-driver opengl3 -s res://tests/map_collision_test.gd

const BAND := 12.0          # screen px above a sprite's ground line that count as its base
const WALK_FRAMES := 50

var game
var prog
var map
var cmd
var step := 0
var wait := 20
var targets: Array = []     # Sprite2D
var ti := 0
var side := 0
var frames := 0
var fails := 0
var checks := 0
var seen: Dictionary = {}


func _initialize() -> void:
	var f := FileAccess.open("user://save.cfg", FileAccess.WRITE)
	if f:
		f.store_string("")
	change_scene_to_file("res://scenes/Main.tscn")


func fail(msg: String) -> void:
	if seen.has(msg):
		return
	seen[msg] = true
	fails += 1
	print("  FAIL  ", msg)


func sprite_name(s: Sprite2D) -> String:
	for id in map.plots:
		if map.plots[id] == s:
			return "plot " + id
	return "%s at %v" % [s.texture.resource_path.get_file() if s.texture.resource_path != "" else "sprite", s.position.round()]


## Feet on the opaque base rows of a standing sprite?
func on_base(s: Sprite2D, feet: Vector2) -> bool:
	var tex := s.texture
	var img := tex.get_image()
	if img == null:
		return false
	var k := s.scale.x
	var px := int(floor((feet.x - s.position.x) / k + tex.get_width() / 2.0))
	var py := int(floor((feet.y - s.position.y) / k + tex.get_height()))
	if s.flip_h:
		px = tex.get_width() - 1 - px
	if px < 0 or px >= img.get_width() or py < 0 or py >= img.get_height():
		return false
	if feet.y < s.position.y - BAND or feet.y > s.position.y:
		return false
	return img.get_pixel(px, py).a > 0.5


func check() -> void:
	checks += 1
	var feet: Vector2 = cmd.position
	# feet inside a solid box?
	for b in map.get_tree().get_nodes_in_group("map_solid"):
		var cs: CollisionShape2D = b.get_child(0)
		if cs.disabled:
			continue
		var r := Rect2(b.position - cs.shape.size / 2.0, cs.shape.size).grow(-2.0)
		if r.has_point(feet):
			fail("feet inside the solid box at %v" % b.position.round())
	# feet standing on a sprite's base?
	for s in targets:
		if on_base(s, feet):
			fail("Commander stands on the base of " + sprite_name(s))
	# sprite bottom = node position (y-sort by feet)
	var spr: Sprite2D = cmd.sprite
	var bottom: float = cmd.position.y + (spr.offset.y + spr.texture.get_height() / 2.0) * spr.scale.y
	if absf(bottom - cmd.position.y) > 2.0:
		fail("Commander's feet are %.0f px from his node position (y-sort would be off)" % (bottom - cmd.position.y))


func _physics_process(_d: float) -> bool:
	if map == null or step != 3:
		return false
	if ti >= targets.size():
		step = 4
		return false
	var s: Sprite2D = targets[ti]
	var w: float = s.texture.get_width() * s.scale.x
	var h: float = s.texture.get_height() * s.scale.y
	if frames == 0:
		# start just outside the sprite on one side, then walk straight at its base
		var start: Vector2 = [s.position + Vector2(0, 46), s.position + Vector2(-w / 2.0 - 30.0, -8),
			s.position + Vector2(w / 2.0 + 30.0, -8), s.position + Vector2(0, -h * 0.45)][side]
		start = start.clamp(Vector2(24, 110), Vector2(1256, 708))   # stay on the map
		cmd.position = start
		cmd.velocity = Vector2.ZERO
		for b in map.get_tree().get_nodes_in_group("map_solid"):
			var bs: CollisionShape2D = b.get_child(0)
			if not bs.disabled and Rect2(b.position - bs.shape.size / 2.0, bs.shape.size).grow(12.0).has_point(start):
				frames = WALK_FRAMES          # no room to start on this side (map edge): skip it
	var aim: Vector2 = s.position + Vector2(0, -4) - cmd.position
	cmd.joystick = aim.normalized() if aim.length() > 4.0 else Vector2.ZERO
	if frames > 2 and frames < WALK_FRAMES:
		check()
	frames += 1
	if frames >= WALK_FRAMES:
		frames = 0
		side += 1
		if side >= 4:
			side = 0
			ti += 1
	return false


func _process(_d: float) -> bool:
	if game == null:
		game = root.get_node_or_null("Game")
		prog = root.get_node("Progression")
	if wait > 0:
		wait -= 1
		return false
	match step:
		0:
			prog.unlock_all = true
			for id in ["solar", "battery", "life_support", "shelter", "suit_bay", "comms_dish", "greenhouse"]:
				prog.levels[id] = 3
			game.goto("hub", 7)
			step = 1
			wait = 30
		1:
			map = game.screen
			cmd = map.commander
			for c in map.get_children():
				if c is Sprite2D and c != map.rover and not map.crew_nodes.values().has(c) and c.has_meta("shadow") and c.visible and c.z_index >= 0:
					targets.append(c)
			print("targets: ", targets.size())
			step = 3
		4:
			cmd.joystick = Vector2.ZERO
			root.get_texture().get_image().save_png("user://map_collision_last.png")
			print("checks: ", checks)
			print("ALL PASSED" if fails == 0 else "%d FAILED" % fails)
			return true
	return false
