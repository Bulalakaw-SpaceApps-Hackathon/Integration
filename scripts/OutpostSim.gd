class_name OutpostSim
extends RefCounted
## The whole night simulation, with no UI and no autoload dependencies, so it
## can be tested headless. NightDirector writes `hazard` each tick; the UI only
## calls the public action methods and reads state.

signal alert(text: String, kind: String)
signal lost(reason: String)
signal won()
signal message_arrived(kind: String)
signal crew_said(crew_id: String, text: String)   # speech bubbles, so the crew are predictable
signal fault_started(fault: Dictionary)
signal request_started(request: Dictionary)
signal sponsor_ad(index: int)
signal radio(text: String)                 # Mission Control radio facts
signal clue_found(clue: Dictionary)
signal malfunction_fixed(cause: Dictionary)

enum Heater { OFF = -1, LOW, MID, HIGH }
enum LifeSupport { OFF = -1, LOW, NORMAL, HIGH }

## Problems that only show on one camera. Open that camera and tap the problem to fix it.
const FAULTS := {
	"loose_cable": {"cam": "solar_field", "pos": Vector2(200, 128)},
	"clogged_filter": {"cam": "life_support", "pos": Vector2(250, 70)},
	"airlock_leak": {"cam": "airlock", "pos": Vector2(250, 60)},
	"greenhouse_leak": {"cam": "greenhouse", "pos": Vector2(140, 100)},
	"shelter_seal": {"cam": "shelter", "pos": Vector2(60, 60)},
	"panel_dust": {"cam": "solar_field", "pos": Vector2(110, 130)},
	"dish_drift": {"cam": "sky_radar", "pos": Vector2(250, 50)},
}
const CLUE_SECONDS := 15.0       # a scheduled clue shows on its camera this long
const CLUE_WATCH_SEC := 1.5      # watching it this long logs it
## Which camera shows which room.
const ROOM_CAM := {"solar_field": "solar_field", "outside": "sky_radar", "comms_dish": "sky_radar", "airlock": "airlock",
	"shelter": "shelter", "life_support": "life_support", "greenhouse": "greenhouse", "galley": ""}

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
var faults: Array[Dictionary] = []      # {kind, cam, pos, at, fixed_at}
var requests: Array[Dictionary] = []    # {crew, text, yes, no, at, expires, answer}
var discovery: Dictionary = {}          # {cam, pos, at, title, text, found}
var sponsor := false                    # at least one sponsor deal is active tonight
var sponsors: Array = []                # sponsor numbers (1..7) whose ads run tonight; each one pays
var rough: Array[String] = []           # "oxygen" / "dose": the night went on, but it only earns the Survive star
var _ad_turn := 0
var sponsor_ads_closed := 0
var extra_materials := 0                # from crew requests that pay off (only counts on a win)
var ask_reply_received := false
var challenge := ""                     # tonight's Challenge star goal
# --- Malfunction: {title, why, true, solved, causes:[{id,name,rooms,p,crossed}], clues:[{at,cam,text,reliability,points/away,found,watch}]}
var malf: Dictionary = {}
var scan_ready_at: Dictionary = {}      # cam -> clock time when SCAN works again
var scanned_empty: Array[String] = []   # rooms already counted as "nothing unusual"
var _low_battery_warned: bool = false
var _particles_warned: bool = false
var _battery_empty_warned: bool = false
var _all_clear_said: bool = false


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
	dish = cfg.comms_delay_real_min > 0.0 and cfg.id >= 4   # Nights 2-3: dish starts off, ASK turns it on
	crew.clear()
	for id in cfg.crew_ids:
		crew.append({"id": id, "room": "life_support", "dose": 0.0, "target": "", "walk_left": 0.0, "held": false, "job": "life_support"})
	_tick_comms(0.0)   # so the link quality is correct before the first frame


# ============================================================================
# Player actions (called by the desk UI)
# ============================================================================
func set_heater(level: int) -> void:
	heater = clampi(level, Heater.OFF, Heater.HIGH)


func set_life_support(level: int) -> void:
	life_support = clampi(level, LifeSupport.OFF, LifeSupport.HIGH)


# ---------------------------------------------------------------- faults (camera problems)
func add_fault(kind: String) -> void:
	if not FAULTS.has(kind) or fault_active(kind):
		return
	var f := {"kind": kind, "cam": FAULTS[kind].cam, "pos": FAULTS[kind].pos, "at": clock_sec, "fixed_at": -1.0}
	faults.append(f)
	alert.emit(Strings.t("fault.%s.start" % kind), "info")
	fault_started.emit(f)


func fault_active(kind: String) -> bool:
	for f in faults:
		if f.kind == kind and f.fixed_at < 0.0:
			return true
	return false


func faults_on_cam(cam: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for f in faults:
		if f.cam == cam and f.fixed_at < 0.0:
			out.append(f)
	return out


## Its Task was finished: fixed, wherever the cameras are now.
func complete_task(kind: String) -> bool:
	for f in faults:
		if f.kind == kind and f.fixed_at < 0.0:
			f.fixed_at = clock_sec
			alert.emit(Strings.t("fault.%s.fixed" % kind), "info")
			return true
	return false


## The player tapped the problem on a camera. Works only while that camera is on.
func fix_fault(kind: String) -> bool:
	for f in faults:
		if f.kind == kind and f.fixed_at < 0.0 and cameras_on.has(f.cam):
			f.fixed_at = clock_sec
			alert.emit(Strings.t("fault.%s.fixed" % kind), "info")
			return true
	return false


# ---------------------------------------------------------------- crew requests
## yes / no effects: {"battery": -5, "oxygen": 5, "materials": 1, "morale": 1, "lamp": true, "move": "solar_field"}
func add_request(crew_id: String, text: String, yes: Dictionary, no: Dictionary, timeout_sec: float) -> void:
	if not has_crew(crew_id):
		return
	for c in crew:
		if c.id == crew_id and (c.held or c.room == "shelter"):
			return                             # sheltering crew don't ask for jobs
	var r := {"crew": crew_id, "text": text, "yes": yes, "no": no, "at": clock_sec, "expires": clock_sec + timeout_sec, "answer": ""}
	requests.append(r)
	request_started.emit(r)


func open_request_for(crew_id: String) -> Dictionary:
	for r in requests:
		if r.crew == crew_id and r.answer == "":
			return r
	return {}


func answer_request(crew_id: String, yes: bool) -> bool:
	var r := open_request_for(crew_id)
	if r.is_empty():
		return false
	r.answer = "yes" if yes else "no"
	_apply_effect(crew_id, r.yes if yes else r.no)
	crew_said.emit(crew_id, Strings.t("crew.thanks") if yes else Strings.t("crew.okay"))
	return true


func _apply_effect(crew_id: String, e: Dictionary) -> void:
	battery = maxf(0.0, battery + float(e.get("battery", 0.0)))
	oxygen = clampf(oxygen + float(e.get("oxygen", 0.0)), 0.0, 100.0)
	extra_materials += int(e.get("materials", 0))
	morale += int(e.get("morale", 0))
	if e.has("lamp"):
		set_crop_lamp(bool(e.lamp))
	if e.has("move"):
		for c in crew:
			if c.id == crew_id:
				_walk(c, str(e.move), 6.0)


func has_crew(crew_id: String) -> bool:
	for c in crew:
		if c.id == crew_id:
			return true
	return false


func crew_cam(crew_id: String) -> String:
	for c in crew:
		if c.id == crew_id:
			return ROOM_CAM.get(c.room, "")
	return ""


# ---------------------------------------------------------------- tonight's science discovery
func place_discovery(cam: String, pos: Vector2, title: String, text: String) -> void:
	discovery = {"cam": cam, "pos": pos, "at": clock_sec, "title": title, "text": text, "found": false}
	alert.emit(Strings.t("discovery.appeared") % Strings.t("cam." + cam), "info")


func collect_discovery() -> bool:
	if discovery.is_empty() or discovery.found or not cameras_on.has(discovery.cam):
		return false
	discovery.found = true
	alert.emit(Strings.t("discovery.found") % discovery.title, "info")
	return true


# ---------------------------------------------------------------- the Malfunction (camera detective)
func setup_malfunction(def: Dictionary) -> void:
	malf = {}
	if def.is_empty():
		return
	var causes: Array = []
	for c in def.get("causes", []):
		causes.append({"id": c.id, "name": c.name, "rooms": c.get("rooms", []), "p": 0.0, "crossed": false})
	causes.shuffle()                        # the real cause must not always be the first row
	for c in causes:
		c.p = 1.0 / causes.size()
	var clues: Array = []
	for c in def.get("clues", []):
		var k: Dictionary = c.duplicate()
		k["found"] = false
		k["watch"] = 0.0
		clues.append(k)
	malf = {"title": def.get("title", "MALFUNCTION"), "why": def.get("why", ""), "true": def.get("true", ""),
		"solved": false, "causes": causes, "clues": clues, "wrong": 0}


func has_malfunction() -> bool:
	return not malf.is_empty()


func malfunction_solved() -> bool:
	return has_malfunction() and malf.solved


## Bayes update. A clue from a sensor that is right r times in 5:
## "points" to X: X x r/5, every other cause x (1 - r/5)/(n - 1).
## "away" from X (looks normal): X x (1 - r/5), others x r/5.
func _apply_clue(k: Dictionary) -> void:
	var r: float = clampf(float(k.get("reliability", 4)) / 5.0, 0.0, 1.0)
	var live: Array = malf.causes.filter(func(c: Dictionary) -> bool: return not c.crossed)
	var n := live.size()
	if n <= 1:
		return
	for c in live:
		if k.has("points"):
			c.p *= r if c.id == k.points else maxf((1.0 - r) / (n - 1), 0.02)
		elif k.has("away"):
			c.p *= maxf(1.0 - r, 0.05) if c.id == k.away else r
	_normalize()


func _normalize() -> void:
	var total := 0.0
	for c in malf.causes:
		if not c.crossed:
			total += c.p
	for c in malf.causes:
		c.p = 0.0 if c.crossed else (c.p / total if total > 0.0 else 0.0)


func _find_clue(k: Dictionary) -> void:
	if k.found:
		return
	k.found = true
	_apply_clue(k)
	clue_found.emit(k)


## Clues visible on a camera right now (scheduled window), for the feed to draw.
func clues_on_cam(cam: String) -> Array:
	var out: Array = []
	if has_malfunction() and not malf.solved:
		for k in malf.clues:
			if k.cam == cam and not k.found and clock_sec >= k.at and clock_sec < k.at + CLUE_SECONDS:
				out.append(k)
	return out


func _tick_clues(dt: float) -> void:
	if not has_malfunction() or malf.solved:
		return
	for k in malf.clues:
		if k.found or clock_sec < k.at or clock_sec >= k.at + CLUE_SECONDS:
			continue
		if cameras_on.has(k.cam):
			k.watch += dt
			if k.watch >= CLUE_WATCH_SEC:
				_find_clue(k)


func can_scan(cam: String) -> bool:
	return cameras_on.has(cam) and clock_sec >= float(scan_ready_at.get(cam, 0.0)) and has_malfunction() and not malf.solved


## SCAN a camera: reveals that room's clue (even one not shown yet); if there is none,
## "nothing unusual" is evidence too and lowers the causes tied to that room.
func scan(cam: String) -> Dictionary:
	if not can_scan(cam):
		return {}
	scan_ready_at[cam] = clock_sec + balance.scan_cooldown_sec
	battery = maxf(0.0, battery - balance.scan_cost)
	for k in malf.clues:
		if k.cam == cam and not k.found:
			_find_clue(k)
			return {"clue": k}
	if not scanned_empty.has(cam):
		scanned_empty.append(cam)
		for c in malf.causes:
			if not c.crossed and (c.rooms as Array).has(cam):
				_apply_clue({"away": c.id, "reliability": balance.scan_empty_reliability})
	return {"empty": true}


## Pick a cause. Right: fixed. Wrong: costs battery, that cause is crossed off.
func diagnose(cause_id: String) -> bool:
	if not has_malfunction() or malf.solved:
		return false
	for c in malf.causes:
		if c.id != cause_id or c.crossed:
			continue
		if cause_id == malf["true"]:
			malf.solved = true
			for o in malf.causes:
				o.p = 1.0 if o.id == cause_id else 0.0
			alert.emit(Strings.t("malf.right") % c.name, "info")
			malfunction_fixed.emit(c)
			return true
		c.crossed = true
		malf.wrong += 1
		battery = maxf(0.0, battery - balance.wrong_diagnosis_cost)
		_normalize()
		alert.emit(Strings.t("malf.wrong") % c.name, "info")
		return false
	return false


## Extra drain while unsolved, growing every game hour.
func malfunction_drain() -> float:
	if not has_malfunction() or malf.solved:
		return 0.0
	var hours := clock_sec / (balance.night_length_sec / 12.0)
	return balance.malfunction_drain + balance.malfunction_drain_per_hour * hours


# ---------------------------------------------------------------- the 3 stars
func challenge_met() -> bool:
	match challenge:
		"battery_20": return battery >= balance.battery_bonus_pct
		"food_grew": return food_grew()
		"shelter_fast": return all_sheltered_at >= 0.0 and all_sheltered_at - flare_alarm_at <= balance.shelter_fast_sec
		"carlo_reply":
			for c in crew:
				if c.id == "carlo" and is_outside(c):
					return false
			return ask_reply_received
		"all_fixed":
			for f in faults:
				if f.fixed_at < 0.0:
					return false
			return true
		"discovery_sent": return discovery_sent
	return false


func science_met() -> bool:
	return (malfunction_solved() or not has_malfunction()) and discovery_found()


func show_sponsor_ad() -> void:
	if sponsor:
		var idx: int = sponsors[_ad_turn % sponsors.size()] if not sponsors.is_empty() else (config.id - 1) % 7 + 1
		_ad_turn += 1
		sponsor_ad.emit(idx)


## How many sponsors pay tonight.
func sponsor_count() -> int:
	return maxi(sponsors.size(), 1) if sponsor else 0


## Crew who were still outside when a storm hit: they rest tomorrow.
func caught_outside() -> Array[String]:
	var out: Array[String] = []
	for c in crew:
		if float(c.get("caught_sec", 0.0)) >= balance.caught_outside_sec:
			out.append(c.id)
	return out


func discovery_found() -> bool:
	return not discovery.is_empty() and discovery.found


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
	if not shelter_door_open and not danger_active() and _anyone_held():
		# all clear: opening the door lets the crew go back to their jobs
		shelter_door_open = true
		door_closing_left = 0.0
		release_crew()
		return
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
				crew_said.emit(c.id, Strings.t("crew.to_shelter"))


## True from the flare alarm until the particles have passed.
func danger_active() -> bool:
	if hazard.particles > 0.0 or hazard.flare > 0.0:
		return true
	return flare_alarm_at >= 0.0 and not _particles_warned


func _anyone_held() -> bool:
	for c in crew:
		if c.held:
			return true
	return false


## Send everyone the Commander was holding back to their own job.
func release_crew() -> void:
	for c in crew:
		if c.held:
			c.held = false
			if c.room != c.job:
				_walk(c, c.job, balance.shelter_walk_sec)
				crew_said.emit(c.id, Strings.t("crew.back_to_work"))


## Bring every outside crewmate back to the airlock (then on to the shelter if it is open).
func recall_crew() -> void:
	var t := balance.recall_time_base / _lv(balance.suit_bay_speed, "suit_bay")
	if hungry:
		t *= balance.hungry_recall_multiplier
	for c in crew:
		if is_outside(c) or OUTSIDE_ROOMS.has(c.target):
			_walk(c, "airlock", t)
			c.held = true
			crew_said.emit(c.id, Strings.t("crew.recalled"))


## kind: "ask_earth" or "discovery". Returns false if there is no link.
func send_message(kind: String) -> bool:
	if not dish and config.comms_delay_real_min > 0.0 and battery > 0.0:
		set_dish(true)
		_tick_comms(0.0)
	if comms < balance.min_comms_to_send or config.comms_delay_real_min <= 0.0:
		alert.emit(Strings.t("alert.no_link"), "comms")
		return false
	if kind == "ask_earth" and ask_in_flight():
		alert.emit(Strings.t("alert.ask_waiting"), "comms")
		return false
	# Radio goes at the speed of light: one way for news, there AND back for a question.
	var one_way := message_delay_sec()
	var trips := 2.0 if kind == "ask_earth" else 1.0
	messages.append({"kind": kind, "sent_at": clock_sec, "turn_at": clock_sec + one_way,
		"arrive_at": clock_sec + one_way * trips})
	return true


func ask_in_flight() -> bool:
	for m in messages:
		if m.kind == "ask_earth":
			return true
	return false


## Light minutes from Earth to Mars tonight (real distance). Night 1 has no dish yet, but
## Mission Control's radio lines still took this long to arrive.
const LIGHT_MIN_FALLBACK := {1: 5.0, 2: 7.5, 3: 9.2}
func light_minutes() -> float:
	if config.comms_delay_real_min > 0.0:
		return config.comms_delay_real_min
	return float(LIGHT_MIN_FALLBACK.get(config.id, 6.0))


## What Earth answers. They have a copy of the base, so they can test what we can't.
func _earth_reply() -> String:
	if has_malfunction() and not malf.solved:
		var wrong: Array = malf.causes.filter(func(c: Dictionary) -> bool: return not c.crossed and c.id != malf["true"])
		if not wrong.is_empty():
			wrong.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.p > b.p)
			wrong[0].crossed = true
			_normalize()
			return Strings.t("earth.reply_malf") % wrong[0].name
	for e in config.hazard_events:
		if e.start_sec > clock_sec:
			var mins := int((e.start_sec - clock_sec) / balance.night_length_sec * 12.0 * 60.0)
			return Strings.t("earth.reply_warn") % [Strings.t("earth.hz.%s" % e.type), mins / 60, mins % 60]
	return Strings.t("earth.reply_quiet")


## Called by NightDirector's crew schedule. Ignored once the player has taken charge of a crewmate.
func schedule_move(crew_id: String, room: String, walk_sec: float) -> void:
	for c in crew:
		if c.id == crew_id:
			c.job = room                       # remembered, so they can go back after an emergency
		if c.id == crew_id and not c.held:
			_walk(c, room, walk_sec)
			if Strings.has("crew.go.%s" % room):
				crew_said.emit(crew_id, Strings.t("crew.go.%s" % room))


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
	_tick_clues(dt)
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
				elif c.room == "airlock" and c.held and not danger_active():
					c.held = false                 # recalled with no danger: wait at the airlock for the next job


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
		if fault_active("dish_drift"):
			comms *= balance.fault_dish_comms
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
				ask_reply_received = true
				radio.emit(_earth_reply())
			message_arrived.emit(m.kind)


func _tick_dose(dt: float) -> void:
	var p: float = hazard.particles
	if p <= 0.0:
		if _particles_warned and not _all_clear_said and hazard.flare <= 0.0:
			_all_clear_said = true
			alert.emit(Strings.t("alert.all_clear"), "info")
		return
	if not _particles_warned:
		_particles_warned = true
		alert.emit(Strings.t("alert.particles"), "dose")
	for c in crew:
		c.dose += p * dose_rate_for(c) * dt
		if is_outside(c):
			c["caught_sec"] = float(c.get("caught_sec", 0.0)) + dt


func _tick_bookkeeping(dt: float) -> void:
	if crop_lamp and battery > 0.0 and not fault_active("greenhouse_leak"):
		crop_lamp_on_sec += dt
	if heater <= Heater.LOW:
		heater_low_sec += dt
	for r in requests:
		if r.answer == "" and clock_sec >= r.expires:
			r.answer = "timeout"
			_apply_effect(r.crew, r.no)
			morale -= 1
			crew_said.emit(r.crew, Strings.t("crew.no_answer"))
	if flare_alarm_at >= 0.0 and all_sheltered_at < 0.0 and everyone_protected():
		all_sheltered_at = clock_sec


func _check_end() -> void:
	if battery_zero_sec >= balance.battery_zero_grace_sec:
		_lose("battery")
	else:
		# Only an empty battery ends the night. Bad air or too much radiation make it a ROUGH night:
		# the crew put on masks / hide, the night goes on, but it can only earn the Survive star.
		if oxygen <= 0.0:
			oxygen = 0.0
			_rough("oxygen")
		for c in crew:
			if c.dose > balance.dose_limit_xrays:
				c.dose = balance.dose_limit_xrays
				_rough("dose")
		if clock_sec >= balance.night_length_sec:
			finished = true
			result = "won"
			won.emit()


func _rough(reason: String) -> void:
	if not rough.has(reason):
		rough.append(reason)
		alert.emit(Strings.t("alert.rough_" + reason), "co2" if reason == "oxygen" else "dose")


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
	if life_support >= 0:
		d += balance.life_support_cost[life_support]
	if heater >= 0:
		d += balance.heater_cost[heater] * (1.0 + balance.cold_heater_extra * hazard.cold)
	if fault_active("loose_cable"):
		d += balance.fault_cable_drain
	if fault_active("panel_dust"):
		d += balance.fault_dust_drain
	d += malfunction_drain()
	d += cameras_on.size() * balance.camera_cost
	if crop_lamp:
		d += balance.crop_lamp_cost
	if dish:
		d += balance.dish_cost
	return d * _lv(balance.battery_bank_multiplier, "battery")


func oxygen_per_sec() -> float:
	var made := 0.0
	if battery > 0.0 and life_support >= 0:
		made = balance.life_support_output[life_support] * _lv(balance.life_support_upgrade_multiplier, "life_support")
		made *= 1.0 - balance.co2_output_loss * hazard.co2
		if fault_active("clogged_filter"):
			made *= balance.fault_filter_output
		if hungry:
			made *= balance.hungry_life_support_multiplier
		if crop_lamp:
			made += _lv(balance.greenhouse_oxygen_bonus, "greenhouse")
	var leak := balance.fault_airlock_leak if fault_active("airlock_leak") else 0.0
	return made - balance.breath_rate * crew_inside_count() - leak


func dose_rate_for(c: Dictionary) -> float:
	if is_outside(c):
		return balance.outside_dose_rate * _lv(balance.suit_dose_multiplier, "suit_bay")
	var r := balance.inside_dose_rate * _lv(balance.habitat_shield_multiplier, "shelter")
	if c.room == "shelter" and door_fully_closed():
		var m := _lv(balance.shelter_inside_multiplier, "shelter")
		if fault_active("shelter_seal"):
			m = minf(1.0, m * balance.fault_seal_multiplier)
		r *= m
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
	if heater == Heater.OFF:
		mor -= 1
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
		"stars": (1 + int(science_met() and rough.is_empty()) + int(challenge_met() and rough.is_empty())) if won_night else 0,
		"star_science": science_met() and rough.is_empty(),
		"star_challenge": challenge_met() and rough.is_empty(),
		"rough": rough,
		"resting": caught_outside(),
		"sponsor_count": sponsor_count(),
		"challenge": challenge,
		"malfunction": malf,
		"materials": (balance.survive_reward + balance.bonus_reward * (int(science_met()) + int(challenge_met())) + extra_materials
			+ (balance.discovery_reward if discovery_found() else 0)
			+ balance.sponsor_reward * sponsor_count()) if won_night else 0,
		"discovery_found": discovery_found(),
		"discovery": discovery,
		"faults_total": faults.size(),
		"faults_fixed": faults.filter(func(f: Dictionary) -> bool: return f.fixed_at >= 0.0).size(),
		"sponsor": sponsor,
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
