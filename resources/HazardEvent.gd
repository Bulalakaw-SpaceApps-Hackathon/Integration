class_name HazardEvent
extends Resource
## One thing that happens during a night. Every data source (archive, DONKI,
## the official challenge data) is turned into these by an adapter.
## NightDirector only ever reads HazardEvents, never raw NASA data.

@export_enum("flare", "particles", "dust", "comms_loss", "cold", "co2", "thump") var type: String = "cold"
@export var start_sec: float = 0.0     ## seconds into the night
@export var peak_sec: float = 0.0      ## <= start_sec means "flat" (full intensity until end)
@export var end_sec: float = 180.0
@export_range(0.0, 1.0) var intensity: float = 1.0
@export var real_date: String = ""     ## "2024-05-20"
@export var source_name: String = ""   ## "Curiosity RAD (NASA)"
@export_enum("real", "simplified", "archived", "live") var badge: String = "simplified"
@export_multiline var why_text: String = ""   ## one line of science shown when it starts
@export var optional: bool = false     ## skipped in Calm Mode


func is_real() -> bool:
	return badge == "real" or badge == "archived" or badge == "live"


## Intensity at night time t (0..1 x intensity). Triangle start->peak->end,
## or flat from start to end when peak_sec <= start_sec.
func intensity_at(t: float, start: float, peak: float, end: float) -> float:
	if t < start or t >= end:
		return 0.0
	if peak <= start:
		return intensity
	if t < peak:
		return intensity * (t - start) / (peak - start)
	if end <= peak:
		return intensity
	return intensity * (end - t) / (end - peak)
