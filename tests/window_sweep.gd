extends SceneTree
## Fast-forwards one night (18:00 -> 06:00) in the windows and saves a frame every few ticks,
## then the same for a dust storm and a flare. Used to make the preview GIF.
var desk: Control
var f := 0
var n := 0
const FRAMES := 72

func _initialize() -> void:
	desk = load("res://scenes/Desk.tscn").instantiate()
	root.add_child(desk)

func _process(_d: float) -> bool:
	f += 1
	if f < 8:
		return false
	desk.set_process(false)
	desk.overlay.visible = false
	var total := FRAMES + 24
	if n >= total:
		return true
	var h := 18.0 + 12.0 * minf(n, FRAMES - 1) / float(FRAMES - 1)
	var dust := 0.0
	var flare := 0.0
	if n >= FRAMES and n < FRAMES + 12:
		h = 23.0; dust = clampf((n - FRAMES) / 5.0, 0.0, 1.0)
	elif n >= FRAMES + 12:
		h = 22.0; flare = 1.0
	for w in desk.windows:
		w.set_state(h, dust, flare)
	if f % 3 == 0:
		root.get_texture().get_image().save_png("user://sweep_%03d.png" % n)
		n += 1
	return false
