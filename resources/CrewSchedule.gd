class_name CrewSchedule
extends Resource
## "At this time, this crewmate walks to this room."
## Rooms: life_support, greenhouse, shelter, airlock, galley (inside)
##        solar_field, comms_dish (outside)

@export var at_sec: float = 0.0
@export var crew_id: String = "lani"
@export var room: String = "life_support"
@export var walk_sec: float = 0.0
