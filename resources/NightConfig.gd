class_name NightConfig
extends Resource
## One night = one data file (res://data/nights/night_N.tres).
## Adding a night means adding a file, not code.

@export var id: int = 1
@export var title: String = ""
@export var theme: String = ""
@export_multiline var briefing_text: String = ""
@export_multiline var debrief_why: String = ""
@export_multiline var debrief_tip: String = ""
@export_multiline var did_you_know: String = ""
@export var did_you_know_source: String = ""

@export var hazard_events: Array[HazardEvent] = []
@export var crew_ids: Array[String] = []
@export var crew_schedule: Array[CrewSchedule] = []

## Extra desk meter(s): "oxygen", "dose", "comms". Battery is always shown.
@export var visible_meters: Array[String] = []
@export var food_enabled: bool = false
@export var unlocked_plots: Array[String] = []
## "battery_20", "food_grew", "shelter_fast", "all_inside_end", "discovery_sent"
@export var bonus_goals: Array[String] = []
@export var comms_delay_real_min: float = 0.0   ## 0 = no comms this night
@export var codex_unlocks: Array[String] = []
@export var ready: bool = true                  ## false = "Coming soon" in Night Select
