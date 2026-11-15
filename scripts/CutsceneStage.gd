class_name CutsceneStage
extends Control
## Composes existing pixel assets as scenery and actors, using individual frames.

func show_panel(background: String, speaker: String, finale: bool) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if background.begins_with("cutscene_cs"):
		_image_scene(background, Rect2(Vector2.ZERO, size))
		return
	var exterior: bool = background == "bld_habitat" or background.begins_with("cam_solar")
	if exterior:
		_rect(Rect2(0, 0, 960, 320), Palette.SKY_NIGHT)
		_rect(Rect2(0, 130, 960, 190), Palette.MARS_RUST)
		_image("bld_habitat", Rect2(330, 24, 384, 288))
		_image("plot_solar_l1", Rect2(70, 105, 192, 192))
		_image("deco_rover", Rect2(760, 190, 128, 96))
	else:
		_image(background, Rect2(0, 0, 960, 320))
		if background == "desk_bg":
			_image("desk_monitor", Rect2(100, 115, 176, 136))
			_image("desk_monitor", Rect2(650, 115, 176, 136))
	var crew: Array[String] = ["commander"]
	var id: String = speaker.trim_prefix("portrait_")
	if id != "" and id != "commander":
		crew.append(id)
	if finale:
		crew.assign(["commander", "lani", "maya", "mateo", "carlo"])
	for i in range(crew.size()):
		var asset: String = "char_commander" if crew[i] == "commander" else "crew_" + crew[i]
		_image(asset, Rect2(360 + i * 64, 220, 64, 96))
	if background == "cam_solar_field_dusty":
		_rect(Rect2(0, 0, 960, 320), Color(Palette.MARS_SAND, 0.18))


func _rect(bounds: Rect2, tint: Color) -> void:
	var layer: ColorRect = ColorRect.new()
	layer.position = bounds.position
	layer.size = bounds.size
	layer.color = tint
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)


func _image(asset: String, bounds: Rect2) -> void:
	var layer: TextureRect = TextureRect.new()
	layer.texture = Assets.frame(asset, 0)
	layer.position = bounds.position
	layer.size = bounds.size
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)


func _image_scene(asset: String, bounds: Rect2) -> void:
	_rect(bounds, Palette.INK)
	var layer: TextureRect = TextureRect.new()
	layer.texture = Assets.tex(asset)
	layer.position = bounds.position
	layer.size = bounds.size
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# Keep every supplied frame whole. COVERED crops the top or sides whenever the
	# browser viewport and the logical stage differ by even a few pixels, which made
	# the character and scenery edges disappear in the cutscene viewer.
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
