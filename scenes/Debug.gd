extends Node
## DEBUG HARNESS (build-order step 1): plays any night with keyboard controls
## and a text readout, before the real Camera Desk UI exists. Replace with the
## real Desk / Hub / Debrief scenes later; keep this around for balancing.
##
## Keys:  PageUp/PageDown pick night · Enter start · P pause · F2 2x speed
##        1-6 cameras · H heater · L life support · C crop lamp · D dish
##        Space shelter door · R recall · E ask Earth · T send discovery

const CAMS := OutpostSim.CAMERAS
const HEATER_NAMES := ["LOW", "MID", "HIGH"]
const LS_NAMES := ["LOW", "NORMAL", "HIGH"]

var night_id: int = 1
var readout: Label
var log_label: Label
var log_lines: Array[String] = []
var last_report: Dictionary = {}


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.16)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	readout = _make_label(Vector2(24, 16), 22)
	log_label = _make_label(Vector2(24, 470), 18)
	log_label.modulate = Color(1.0, 0.85, 0.6)
	SimState.night_ended.connect(_on_night_ended)
	SimState.night_started.connect(_on_night_started)


func _make_label(pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(1232, 440)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	add_child(l)
	return l


func _on_night_started(_cfg: NightConfig) -> void:
	log_lines.clear()
	last_report = {}
	SimState.sim.alert.connect(func(text: String, kind: String) -> void: _log("[%s] %s" % [kind, text]))


func _on_night_ended(report: Dictionary) -> void:
	last_report = report
	if not report.won:
		_log(Strings.t("evacuate"))
		_log(Strings.t("lose.%s.why" % report.reason))
		_log("Tip: " + Strings.t("lose.%s.tip" % report.reason))


func _log(line: String) -> void:
	var stamp := SimState.sim.clock_string() if SimState.sim else "--:--"
	log_lines.append("%s  %s" % [stamp, line])
	if log_lines.size() > 8:
		log_lines.pop_front()


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	var k: Key = key_event.keycode
	var s := SimState.sim
	var live := SimState.running and s != null
	match k:
		KEY_PAGEUP: night_id = mini(night_id + 1, Progression.NIGHT_COUNT)
		KEY_PAGEDOWN: night_id = maxi(night_id - 1, 1)
		KEY_ENTER, KEY_KP_ENTER:
			if not SimState.running:
				SimState.start_night(night_id)
		KEY_P: SimState.paused = not SimState.paused
		KEY_F2: SimState.speed = 2.0 if SimState.speed == 1.0 else 1.0
	if not live:
		return
	match k:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6: s.toggle_camera(CAMS[k - KEY_1])
		KEY_H: s.set_heater((s.heater + 1) % 3)
		KEY_L: s.set_life_support((s.life_support + 1) % 3)
		KEY_C: s.set_crop_lamp(not s.crop_lamp)
		KEY_D: s.set_dish(not s.dish)
		KEY_SPACE: s.toggle_shelter_door()
		KEY_R: s.recall_crew()
		KEY_E:
			if s.send_message("ask_earth"):
				_log("Message sent... arriving in %.0f s" % s.message_delay_sec())
		KEY_T:
			if s.send_message("discovery"):
				_log("Discovery sending... arrives in %.0f s" % s.message_delay_sec())


func _process(_delta: float) -> void:
	var s := SimState.sim
	var t := PackedStringArray()
	var cfg := SimState.load_night(night_id) if not SimState.running else SimState.config
	t.append("NIGHT %d: %s   [PgUp/PgDn change, Enter start]   materials %d   food %d   speed %.0fx%s" % [
		cfg.id if cfg else night_id, cfg.title if cfg else "?", Progression.materials, maxi(Progression.food, 0), SimState.speed,
		"   PAUSED" if SimState.paused else ""])
	if s == null:
		readout.text = "\n".join(t)
		return
	var c := s.config
	t.append("%s   %s" % [s.clock_string(), s.forecast_text()])
	t.append("Battery %5.1f%%   drain %.2f %%/s   |   Heater %s   Life Support %s   Crop Lamp %s   Dish %s" % [
		s.battery, s.drain_per_sec(), HEATER_NAMES[s.heater], LS_NAMES[s.life_support],
		"ON" if s.crop_lamp else "off", "ON" if s.dish else "off"])
	var extra := PackedStringArray()
	if c.visible_meters.has("oxygen") or c.food_enabled:
		extra.append("Oxygen %.1f%%" % s.oxygen)
	if c.visible_meters.has("comms") or c.comms_delay_real_min > 0.0:
		extra.append("Comms %.0f%% (delay %.0f s)" % [s.comms, s.message_delay_sec() if s.comms > 0.0 else 0.0])
	if c.food_enabled:
		extra.append("Food %d%s  lamp %.0f/%.0f s" % [s.food, " HUNGRY" if s.hungry else "", s.crop_lamp_on_sec, s.balance.crop_min_sec])
	if not extra.is_empty():
		t.append("   ".join(extra))
	t.append("Cameras on: %s   Shelter door: %s" % [", ".join(s.cameras_on) if not s.cameras_on.is_empty() else "none",
		"OPEN" if s.shelter_door_open else ("closing" if s.door_closing_left > 0.0 else "closed")])
	var wait := SimState.director.seconds_until_particles() if SimState.director else -1.0
	if s.flare_alarm_at >= 0.0 and wait > 0.0:
		t.append(">>> PARTICLES ARRIVE IN %.0f s <<<" % wait)
	var hz := PackedStringArray()
	for key in s.hazard.keys():
		if s.hazard[key] > 0.0:
			hz.append("%s %.2f" % [key, s.hazard[key]])
	t.append("Hazards: " + (", ".join(hz) if not hz.is_empty() else "none"))
	t.append("")
	for cm in s.crew:
		var where: String = cm.room if cm.walk_left <= 0.0 else "%s -> %s (%.0f s)" % [cm.room, cm.target, cm.walk_left]
		t.append("  %-6s %-34s dose %4.1f / %.0f chest X-rays%s" % [cm.id, where, cm.dose, s.balance.dose_limit_xrays,
			"  OUTSIDE" if s.is_outside(cm) else ""])
	if not last_report.is_empty():
		t.append("")
		t.append("=== %s ===  stars %d  materials +%d  bonus %s" % [
			"SUNRISE! YOU MADE IT" if last_report.won else "NIGHT LOST", last_report.stars, last_report.materials, str(last_report.bonus)])
	readout.text = "\n".join(t)
	log_label.text = "\n".join(log_lines)
