class_name CutsceneBeat
extends Resource
## Presentation-only story beat. Gameplay callers choose when to play it.

@export var id: String = ""
@export var title: String = ""
@export var panel_assets: Array[String] = []
@export var portrait_assets: Array[String] = []
@export var fade_sec: float = 0.8
@export var portrait_slide_px: float = 18.0
@export var captions: Array[String] = []
@export var panel_durations_sec: Array[float] = []
@export var next_route: String = ""
@export var accessibility_note: String = ""


func panel_count() -> int:
	return mini(panel_assets.size(), mini(captions.size(), panel_durations_sec.size()))


func duration_for(index: int) -> float:
	if index < 0 or index >= panel_durations_sec.size():
		return 0.0
	return maxf(0.0, panel_durations_sec[index])
