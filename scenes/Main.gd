extends Control
## The game's main scene. Game (autoload) shows every screen inside this node.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Game.attach(self)
