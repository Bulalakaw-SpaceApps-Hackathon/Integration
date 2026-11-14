class_name OutpostSim
extends RefCounted
## The whole night simulation, with no UI and no autoload dependencies, so it
## can be tested headless. NightDirector writes `hazard` each tick; the UI only
## calls the public action methods and reads state.

signal alert(text: String, kind: String)
signal lost(reason: String)
signal won()
signal message_arrived(kind: String)

enum Heater { LOW, MID, HIGH }
enum LifeSupport { LOW, NORMAL, HIGH }

const CAMERAS: Array[String] = ["sky_radar", "airlock", "solar_field", "shelter", "life_support", "greenhouse"]
const OUTSIDE_ROOMS: Array[String] = ["solar_field", "comms_dish", "outside"]
const PLOTS: Array[String] = ["solar", "battery", "life_support", "shelter", "suit_bay", "comms_dish", "greenhouse"]

var balance: BalanceConfig
var config: NightConfig
var levels: Dictionary = {}   # plot id -> 1..3

# --- live state -------------------------------------------------------------
var clock_sec: float = 0.0
var battery: float = 0.0
var oxygen: float = 0.0
var comms: float = 0.0
var food: int = 0
var hungry: bool = false
var finished: bool = false
var result: String = ""        # "won" / "lost"
var lose_reason: String = ""

# --- switches ---------------------------------------------------------------
var heater: int = Heater.MID
var life_support: int = LifeSupport.NORMAL
var cameras_on: Array[String] = []
var crop_lamp: bool = false
var dish: bool = false
var shelter_door_open: bool = false
var door_closing_left: float = 0.0   # > 0 while the door is still moving shut

# --- hazards, written by NightDirector every tick (0..1) ---------------------
var hazard: Dictionary = {"particles": 0.0, "dust": 0.0, "flare": 0.0, "comms_loss": 0.0, "co2": 0.0, "cold": 0.0, "thump": 0.0}

# --- crew: {id, room, dose, target, walk_left, held} -------------------------
var crew: Array[Dictionary] = []

# --- bookkeeping for alerts, bonus goals and the debrief ---------------------
var messages: Array[Dictionary] = []   # {kind, arrive_at}
var discovery_sent: bool = false
var flare_alarm_at: float = -1.0
var all_sheltered_at: float = -1.0
var crop_lamp_on_sec: float = 0.0
var heater_low_sec: float = 0.0
var battery_zero_sec: float = 0.0
var morale: int = 0
var _low_battery_warned: bool = false
var _particles_warned: bool = false
var _battery_empty_warned: bool = false


# ============================================================================
# Setup
# ============================================================================
func start(cfg: NightConfig, bal: BalanceConfig, plot_levels: Dictionary, food_stock: int) -> void:
	config = cfg
	balance = bal
	levels = plot_levels.duplicate()
	for p in PLOTS:
		if not levels.has(p):
			levels[p] = 1
	clock_sec = 0.0
	var dust_at_sunset := 0.0
	for ev in cfg.hazard_events:
		if ev.type == "dust" and ev.start_sec <= 0.0:
			dust_at_sunset = maxf(dust_at_sunset, ev.intensity)
	battery = _lv(bal.solar_start, "solar") - bal.dust_battery_penalty * dust_at_sunset
	oxygen = bal.oxygen_start
	food = food_stock
	hungry = cfg.food_enabled and food <= 0
	if hungry:
		alert.emit(Strings.t("alert.hungry"), "hungry")
	dish = cfg.comms_delay_real_min > 0.0
	crew.clear()
	for id in cfg.crew_ids:
		crew.append({"id": id, "room": "life_support", "dose": 0.0, "target": "", "walk_left": 0.0, "held": false})
	_tick_comms(0.0)   # so the link quality is correct before the first frame


# ============================================================================
# Player actions (called by the desk UI)
# ============================================================================
func set_heater(level: int) -> void:
	heater = clampi(level, Heater.LOW, Heater.HIGH)


func set_life_support(level: int) -> void:
	life_support = clampi(level, LifeSupport.LOW, LifeSupport.HIGH)


func toggle_camera(cam: String) -> bool:
	if cameras_on.has(cam):
		cameras_on.erase(cam)
		return true
	if cameras_on.size() >= balance.max_cameras_on:
		alert.emit(Strings.t("alert.too_many_cameras"), "info")
		return false
	cameras_on.append(cam)
	return true


func set_crop_lamp(on: bool) -> void:
	crop_lamp = on and config.food_enabled


func set_dish(on: bool) -> void:
	dish = on


## Open: call every inside crewmate to the shelter. Close: protect whoever is inside.
func toggle_shelter_door() -> void:
	if shelter_door_open:
		shelter_door_open = false
		door_closing_left = _lv(balance.door_close_sec, "shelter")
		battery -= balance.shelter_door_close_cost
	else:
		shelter_door_open = true
		door_closing_left = 0.0
		for c in crew:
			if not is_outside(c) and c.room != "shelter":
				_walk(c, "shelter", balance.shelter_walk_sec)
				c.held = true


## Bring every outside crewmate back to the airlock (then on to the shelter if it is open).
func recall_crew() -> void:
	var t := balance.recall_time_base / _lv(balance.suit_bay_speed, "suit_bay")
	if hungry:
		t *= balance.hungry_recall_multiplier
	for c in crew:
		if is_outside(c) or OUTSIDE_ROOMS.has(c.target):
			_walk(c, "airlock", t)
			c.held = true


## kind: "ask_earth" or "discovery". Returns false if there is no link.
func send_message(kind: String) -> bool:
	if comms < balance.min_comms_to_send or config.comms_delay_real_min <= 0.0:
		alert.emit(Strings.t("alert.no_link"), "comms")
		return false
	messages.append({"kind": kind, "arrive_at": clock_sec + message_delay_sec()})
	return true


## Called by NightDirector's crew schedule. Ignored once the player has taken charge of a crewmate.
func schedule_move(crew_id: String, room: String, walk_sec: float) -> void:
	for c in crew:
		if c.id == crew_id and not c.held:
			_walk(c, room, walk_sec)


func on_flare_alarm() -> void:
	if flare_alarm_at < 0.0:
		flare_alarm_at = clock_sec
	alert.emit(Strings.t("alert.flare"), "flare")


# ============================================================================
# Tick
# ============================================================================
func tick(dt: float) -> void:
	if finished:
		return
	clock_sec += dt
	_tick_crew(dt)
	if door_closing_left > 0.0:
		door_closing_left = maxf(0.0, door_closing_left - dt)
		if door_closing_left == 0.0:
			alert.emit(Strings.t("alert.door_closed"), "info")
	_tick_battery(dt)
	_tick_oxygen(dt)
	_tick_comms(dt)
	_tick_dose(dt)
	_tick_bookkeeping(dt)
	_check_end()


func _tick_crew(dt: float) -> void:
	for c in crew:
		if c.walk_left > 0.0:
			c.walk_left -= dt
			if c.walk_left <= 0.0:
				c.room = c.target
				c.target = ""
				c.walk_left = 0.0
				# Recalled crew keep going to the shelter if it is open.
				if c.room == "airlock" and c.held and shelter_door_open:
					_walk(c, "shelter", balance.shelter_walk_sec)


func _tick_battery(dt: float) -> void:
	var has_power := battery > 0.0
	battery -= drain_per_sec() * dt
	if battery <= 0.0:
		battery = 0.0
		battery_zero_sec += dt
		if has_power and not _battery_empty_warned:
			_battery_empty_warned = true
			alert.emit(Strings.t("alert.battery_empty"), "battery")
	else:
		battery_zero_sec = 0.0
	if battery < balance.low_battery_alert_pct and not _low_battery_warned:
		_low_battery_warned = true
		alert.emit(Strings.t("alert.low_battery"), "battery")


func _tick_oxygen(dt: float) -> void:
	oxygen += oxygen_per_sec() * dt
	oxygen = clampf(oxygen, 0.0, 100.0)


func _tick_comms(dt: float) -> void:
	if not dish or battery <= 0.0:
		comms = 0.0
	else:
		var resist := _lv(balance.dish_static_resist, "comms_dish")
		var loss: float = (hazard.dust * balance.dust_comms_penalty + hazard.flare * balance.flare_comms_penalty) * resist
		comms = clampf(100.0 - loss - hazard.comms_loss * 100.0, 0.0, 100.0)
	# Messages in flight are lost if the link drops; delivered ones fire their effect.
	for i in range(messages.size() - 1, -1, -1):
		var m: Dictionary = messages[i]
		if comms < balance.min_comms_to_send:
			messages.remove_at(i)
			alert.emit(Strings.t("alert.message_lost"), "comms")
		elif clock_sec >= m.arrive_at:
			messages.remove_at(i)
			if m.kind == "discovery":
				discovery_sent = true
				alert.emit(Strings.t("alert.discovery_sent"), "comms")
			else:
				alert.emit(Strings.t("alert.ask_earth_reply"), "comms")
			message_arrived.emit(m.kind)


func _tick_dose(dt: float) -> void:
	var p: float = hazard.particles
	if p <= 0.0:
		return
	if not _particles_warned:
		_particles_warned = true
		alert.emit(Strings.t("alert.particles"), "dose")
	for c in crew:
		c.dose += p * dose_rate_for(c) * dt


func _tick_bookkeeping(dt: float) -> void:
	if crop_lamp and battery > 0.0:
		crop_lamp_on_sec += dt
	if heater == Heater.LOW:
		heater_low_sec += dt
	if flare_alarm_at >= 0.0 and all_sheltered_at < 0.0 and everyone_protected():
		all_sheltered_at = clock_sec


func _check_end() -> void:
	if battery_zero_sec >= balance.battery_zero_grace_sec:
		_lose("battery")
	elif oxygen <= 0.0:
		_lose("oxygen")
	else:
		for c in crew:
			if c.dose > balance.dose_limit_xrays:
				_lose("dose")
				return
		if clock_sec >= balance.night_length_sec:
			finished = true
			result = "won"
			won.emit()


func _lose(reason: String) -> void:
	finished = true
	result = "lost"
	lose_reason = reason
	lost.emit(reason)


# ============================================================================
# Derived values (also used by the UI)
# ============================================================================
func drain_per_sec() -> float:
	if battery <= 0.0:
		return 0.0   # everything is off
	var d := balance.base_load
	d += balance.life_support_cost[life_support]
	d += balance.heater_cost[heater] * (1.0 + balance.cold_heater_extra * hazard.cold)
	d += cameras_on.size() * balance.camera_cost
	if crop_lamp:
		d += balance.crop_lamp_cost
	if dish:
		d += balance.dish_cost
	return d * _lv(balance.battery_bank_multiplier, "battery")


func oxygen_per_sec() -> float:
	var made := 0.0
	if battery > 0.0:
		made = balance.life_support_output[life_support] * _lv(balance.life_support_upgrade_multiplier, "life_support")
		made *= 1.0 - balance.co2_output_loss * hazard.co2
		if hungry:
			made *= balance.hungry_life_support_multiplier
		if crop_lamp:
			made += _lv(balance.greenhouse_oxygen_bonus, "greenhouse")
	return made - balance.breath_rate * crew_inside_count()


func dose_rate_for(c: Dictionary) -> float:
	if is_outside(c):
		return balance.outside_dose_rate * _lv(balance.suit_dose_multiplier, "suit_bay")
	var r := balance.inside_dose_rate * _lv(balance.habitat_shield_multiplier, "shelter")
	if c.room == "shelter" and door_fully_closed():
		r *= _lv(balance.shelter_inside_multiplier, "shelter")
	return r


func message_delay_sec() -> float:
	var q := maxf(comms / 100.0, 0.25)
	return config.comms_delay_real_min * balance.delay_seconds_per_real_minute / q * _lv(balance.dish_delay_multiplier, "comms_dish")


## Clock time (seconds into the night) when the battery would hit 0 at the current drain.
func forecast_empty_at() -> float:
	var d := drain_per_sec()
	if d <= 0.0:
		return INF if battery > 0.0 else clock_sec
	return clock_sec + battery / d


func forecast_text() -> String:
	var t := forecast_empty_at()
	if t >= balance.night_length_sec:
		return Strings.t("forecast.past_sunrise")
	return Strings.t("forecast.until") % clock_string(t)


func clock_string(t: float = -1.0) -> String:
	if t < 0.0:
		t = clock_sec
	var sec_per_hour := balance.night_length_sec / 12.0
	var minutes := int(18.0 * 60.0 + t / sec_per_hour * 60.0) % (24 * 60)
	return "%02d:%02d" % [minutes / 60, minutes % 60]


func is_outside(c: Dictionary) -> bool:
	return OUTSIDE_ROOMS.has(c.room)


func crew_inside_count() -> int:
	var n := 0
	for c in crew:
		if not is_outside(c):
			n += 1
	return n


func door_fully_closed() -> bool:
	return not shelter_door_open and door_closing_left <= 0.0


func everyone_protected() -> bool:
	if not door_fully_closed():
		return false
	for c in crew:
		if c.room != "shelter" or c.walk_left > 0.0:
			return false
	return true


func max_dose() -> float:
	var m := 0.0
	for c in crew:
		m = maxf(m, c.dose)
	return m


func food_grew() -> bool:
	return config.food_enabled and crop_lamp_on_sec >= balance.crop_min_sec and heater_low_sec < balance.heater_low_blocks_crops_sec


# ============================================================================
# End of night
# ============================================================================
func end_report() -> Dictionary:
	var won_night := result == "won"
	var bonus := {}
	var met := 0
	for g in config.bonus_goals:
		var ok := false
		match g:
			"battery_20": ok = battery >= balance.battery_bonus_pct
			"food_grew": ok = food_grew()
			"shelter_fast": ok = all_sheltered_at >= 0.0 and all_sheltered_at - flare_alarm_at <= balance.shelter_fast_sec
			"all_inside_end": ok = crew_inside_count() == crew.size()
			"discovery_sent": ok = discovery_sent
		ok = ok and won_night
		bonus[g] = ok
		if ok:
			met += 1
	var food_after := food
	if config.food_enabled and won_night:
		food_after = maxi(0, food - crew.size() * balance.meal_per_crew)
		if food_grew():
			food_after += _lvi(balance.greenhouse_yield, "greenhouse")
	var mor := morale
	if heater == Heater.HIGH:
		mor += 1
	if heater_low_sec > 60.0:
		mor -= 1
	return {
		"night": config.id,
		"won": won_night,
		"reason": lose_reason,
		"battery": battery,
		"oxygen": oxygen,
		"max_dose": max_dose(),
		"bonus": bonus,
		"stars": clampi(met, 1, 3) if won_night else 0,
		"materials": (balance.survive_reward + balance.bonus_reward * met) if won_night else 0,
		"food_after": food_after,
		"morale": mor,
	}


# ============================================================================
# Helpers
# ============================================================================
func _walk(c: Dictionary, room: String, sec: float) -> void:
	if sec <= 0.0:
		c.room = room
		c.target = ""
		c.walk_left = 0.0
	else:
		c.target = room
		c.walk_left = sec


func _lv(arr: Array[float], plot: String) -> float:
	return arr[clampi(int(levels.get(plot, 1)) - 1, 0, arr.size() - 1)]


func _lvi(arr: Array[int], plot: String) -> int:
	return arr[clampi(int(levels.get(plot, 1)) - 1, 0, arr.size() - 1)]
