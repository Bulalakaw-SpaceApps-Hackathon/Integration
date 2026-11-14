class_name BalanceConfig
extends Resource
## Every tunable number in the game. Saved as res://data/balance.tres.
## Arrays indexed by setting or by plot level (index 0 = Level 1).

@export_group("Night")
@export var night_length_sec: float = 180.0      # 18:00 -> 06:00 = 12 game hours
@export var battery_zero_grace_sec: float = 10.0
@export var low_battery_alert_pct: float = 15.0

@export_group("Battery (percent per second)")
@export var solar_start: Array[float] = [70.0, 85.0, 100.0]        # by Solar Field level
@export var dust_battery_penalty: float = 20.0                    # x dust intensity at sunset
@export var base_load: float = 0.05
@export var life_support_cost: Array[float] = [0.08, 0.15, 0.25]  # LOW / NORMAL / HIGH
@export var heater_cost: Array[float] = [0.05, 0.10, 0.18]        # LOW / MID / HIGH
@export var cold_heater_extra: float = 0.5                        # heater works harder when it is cold
@export var camera_cost: float = 0.04
@export var max_cameras_on: int = 2
@export var crop_lamp_cost: float = 0.06
@export var dish_cost: float = 0.05
@export var shelter_door_close_cost: float = 0.5                   # one-off, per close
@export var battery_bank_multiplier: Array[float] = [1.0, 0.9, 0.8]

@export_group("Oxygen (percent per second)")
@export var oxygen_start: float = 40.0
@export var life_support_output: Array[float] = [0.10, 0.20, 0.30]  # LOW / NORMAL / HIGH
@export var life_support_upgrade_multiplier: Array[float] = [1.0, 1.15, 1.3]
@export var breath_rate: float = 0.07                              # per crewmate inside
@export var co2_output_loss: float = 0.5                           # x co2 intensity
@export var greenhouse_oxygen_bonus: Array[float] = [0.01, 0.02, 0.03]  # while crop lamp on

@export_group("Radiation (chest X-rays per second at intensity 1)")
@export var outside_dose_rate: float = 0.5
@export var inside_dose_rate: float = 0.4
@export var dose_limit_xrays: float = 15.0
@export var warning_window_sec: float = 20.0
@export var shelter_inside_multiplier: Array[float] = [0.2, 0.1, 0.05]
@export var habitat_shield_multiplier: Array[float] = [1.0, 0.85, 0.7]
@export var suit_dose_multiplier: Array[float] = [1.0, 0.85, 0.7]
@export var door_close_sec: Array[float] = [4.0, 2.5, 1.5]

@export_group("Crew movement (seconds)")
@export var recall_time_base: float = 15.0
@export var suit_bay_speed: Array[float] = [1.0, 1.3, 1.6]
@export var shelter_walk_sec: float = 4.0
@export var hungry_recall_multiplier: float = 1.3
@export var hungry_life_support_multiplier: float = 0.8

@export_group("Comms")
@export var delay_seconds_per_real_minute: float = 5.0
@export var dust_comms_penalty: float = 40.0
@export var flare_comms_penalty: float = 30.0
@export var dish_static_resist: Array[float] = [1.0, 0.8, 0.6]
@export var dish_delay_multiplier: Array[float] = [1.0, 0.85, 0.7]
@export var min_comms_to_send: float = 5.0

@export_group("Food (meals)")
@export var food_start: int = 4
@export var meal_per_crew: int = 1
@export var crop_min_sec: float = 120.0
@export var greenhouse_yield: Array[int] = [2, 3, 4]
@export var heater_low_blocks_crops_sec: float = 60.0

@export_group("Rewards and upgrades")
@export var survive_reward: int = 3
@export var bonus_reward: int = 1
@export var upgrade_cost: Array[int] = [0, 2, 4]   # cost to reach L1 / L2 / L3
@export var shelter_fast_sec: float = 30.0
@export var battery_bonus_pct: float = 20.0

@export_group("Camera problems, crew requests, discovery, sponsors")
@export var fault_cable_drain: float = 0.10          # %/s extra while a cable is loose
@export var fault_filter_output: float = 0.4         # life support makes 40% while clogged
@export var fault_airlock_leak: float = 0.12         # oxygen %/s lost while the airlock leaks
@export var fault_seal_multiplier: float = 3.0       # shelter lets in 3x more while its seal is broken
@export var faults_per_night: Array[int] = [1, 2, 2, 3, 3, 3, 4]
@export var requests_per_night: Array[int] = [1, 1, 2, 2, 2, 2, 3]
@export var request_timeout_sec: float = 30.0
@export var discovery_reward: int = 1
@export var sponsor_reward: int = 3
@export var sponsor_first_sec: float = 20.0
@export var sponsor_gap_sec: float = 28.0
@export var sponsor_close_delay_sec: float = 1.5
@export var fault_dust_drain: float = 0.05
@export var fault_dish_comms: float = 0.4            # link quality x0.4 while the dish has drifted
@export_group("Malfunction, clues and scan")
@export var malfunction_drain: float = 0.01          # %/s while unsolved...
@export var malfunction_drain_per_hour: float = 0.004  # ...plus this much more every game hour
@export var wrong_diagnosis_cost: float = 3.0        # % battery per wrong guess
@export var scan_cost: float = 2.0                   # % battery per SCAN
@export var scan_cooldown_sec: float = 20.0
@export var scan_empty_reliability: float = 3.0      # "nothing unusual" is right 3 in 5 times
@export_group("Calm Mode and randomness")
@export var calm_warning_multiplier: float = 1.5
@export var event_jitter_sec: float = 5.0
