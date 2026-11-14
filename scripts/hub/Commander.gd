class_name Commander
extends CharacterBody2D
## CH-01 The Commander on the base map. WASD / arrows, or the touch joystick.
## char_commander.png: 16 frames in one row = down 0-3, left 4-7, right 8-11, up 12-15.

const SPEED := 170.0
const DIRS := {"down": 0, "left": 4, "right": 8, "up": 12}

var sprite: Sprite2D
var joystick := Vector2.ZERO      # set by the touch joystick
var facing := "down"
var anim_t := 0.0
var step_t := 0.0


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	shape.position = Vector2(0, 8)
	add_child(shape)
	sprite = Sprite2D.new()
	sprite.texture = Assets.frame("char_commander", 0)
	add_child(sprite)


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO:
		dir = joystick
	velocity = dir.limit_length(1.0) * SPEED
	move_and_slide()
	if dir.length() > 0.1:
		if absf(dir.x) > absf(dir.y):
			facing = "right" if dir.x > 0.0 else "left"
		else:
			facing = "down" if dir.y > 0.0 else "up"
		anim_t += delta
		step_t += delta
		if step_t > 0.32:
			step_t = 0.0
			Sfx.play("step_%d" % (randi() % 3 + 1), -8.0)
	else:
		anim_t = 0.0
	var f := int(anim_t * 8.0) % 4
	sprite.texture = Assets.frame("char_commander", int(DIRS[facing]) + f)


static func ensure_input_actions() -> void:
	var keys := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "interact": [KEY_E, KEY_ENTER]}
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
