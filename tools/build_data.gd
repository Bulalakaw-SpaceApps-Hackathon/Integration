extends SceneTree
## Writes res://data/balance.tres and res://data/nights/night_1..7.tres.
## Run once (or after editing this file):
##   godot --headless --path . -s res://tools/build_data.gd
## After that, the team can also tweak the .tres files in the Inspector.


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/nights")
	_save(BalanceConfig.new(), "res://data/balance.tres")
	_save(night_1(), "res://data/nights/night_1.tres")
	_save(night_2(), "res://data/nights/night_2.tres")
	_save(night_3(), "res://data/nights/night_3.tres")
	_save(night_4(), "res://data/nights/night_4.tres")
	_save(night_5(), "res://data/nights/night_5.tres")
	_save(night_6(), "res://data/nights/night_6.tres")
	_save(night_7(), "res://data/nights/night_7.tres")
	quit()


func _save(res: Resource, path: String) -> void:
	var err := ResourceSaver.save(res, path)
	print(("saved " if err == OK else "FAILED ") + path)


# --- helpers -----------------------------------------------------------------
func ev(type: String, start: float, peak: float, end: float, intensity: float, badge: String,
		why: String, date := "", source := "", optional := false) -> HazardEvent:
	var e := HazardEvent.new()
	e.type = type
	e.start_sec = start
	e.peak_sec = peak
	e.end_sec = end
	e.intensity = intensity
	e.badge = badge
	e.why_text = why
	e.real_date = date
	e.source_name = source
	e.optional = optional
	return e


func mv(at: float, who: String, room: String, walk := 0.0) -> CrewSchedule:
	var s := CrewSchedule.new()
	s.at_sec = at
	s.crew_id = who
	s.room = room
	s.walk_sec = walk
	return s


func base(id: int, title: String, theme: String) -> NightConfig:
	var n := NightConfig.new()
	n.id = id
	n.title = title
	n.theme = theme
	return n


func cold(intensity := 0.5) -> HazardEvent:
	return ev("cold", 15.0, 60.0, 180.0, intensity, "simplified",
		"It's getting very cold outside. Mars nights are colder than any freezer on Earth, so the heater works harder.",
		"", "Based on Curiosity rover weather data (simplified)")


# --- the 7 nights ------------------------------------------------------------
func night_1() -> NightConfig:
	var n := base(1, "Welcome, Commander", "Power")
	n.briefing_text = "The sun is setting, so the solar panels stop making power. Make the battery last until 06:00!"
	n.crew_ids.assign(["lani"])
	n.crew_schedule.assign([mv(0, "lani", "life_support"), mv(90, "lani", "airlock", 3)])
	n.hazard_events.assign([cold(0.5)])
	n.unlocked_plots.assign(["solar", "battery"])
	n.bonus_goals.assign(["battery_20"])
	n.debrief_why = "At night there is no sunlight, so every light, heater and camera uses up stored battery."
	n.debrief_tip = "Watch the forecast line. Switch off what you don't need before it's too late."
	n.did_you_know = "A day on Mars, called a sol, is about 24 hours and 39 minutes long."
	n.did_you_know_source = "NASA"
	n.codex_unlocks.assign(["sol", "battery_solar"])
	return n


func night_2() -> NightConfig:
	var n := base(2, "Air and Food", "Life support and food")
	n.briefing_text = "Maya has joined! Keep the air fresh, and decide if the Crop Lamp is worth the power."
	n.crew_ids.assign(["lani", "maya"])
	n.crew_schedule.assign([mv(0, "lani", "life_support"), mv(0, "maya", "greenhouse")])
	n.hazard_events.assign([
		cold(0.5),
		ev("co2", 70.0, 90.0, 130.0, 0.8, "simplified",
			"The fan is slowing and the air feels heavy. The CO2 filter is clogging, so Life Support makes less fresh air.")
	])
	n.visible_meters.assign(["oxygen"])
	n.food_enabled = true
	n.unlocked_plots.assign(["solar", "battery", "life_support", "greenhouse"])
	n.bonus_goals.assign(["battery_20", "food_grew"])
	n.debrief_why = "Making oxygen and growing food both need electricity, and the battery is shared."
	n.debrief_tip = "Turn Life Support up when the air feels heavy, and turn something else down to pay for it."
	n.did_you_know = "NASA's MOXIE experiment on the Perseverance rover made oxygen from the Martian air, and it needed power to do it."
	n.did_you_know_source = "NASA Mars 2020 (MOXIE)"
	n.codex_unlocks.assign(["co2_oxygen", "food"])
	return n


func night_3() -> NightConfig:
	var n := base(3, "Invisible Energy", "Radiation and shielding")
	n.briefing_text = "Doctor Mateo is here. A real solar storm from September 2017 is coming. Our shelter has thick shielding!"
	n.crew_ids.assign(["lani", "maya", "mateo"])
	n.crew_schedule.assign([mv(0, "lani", "solar_field"), mv(0, "maya", "greenhouse"), mv(0, "mateo", "life_support"), mv(150, "lani", "airlock", 10)])
	n.hazard_events.assign([
		cold(0.4),
		ev("flare", 60.0, 60.0, 75.0, 1.0, "real",
			"", "2017-09-10", "NASA solar observations"),
		ev("particles", 80.0, 110.0, 170.0, 0.35, "real",
			"", "2017-09-10", "Curiosity RAD (NASA): dose rates rose 2-3x above normal"),
	])
	n.visible_meters.assign(["dose"])
	n.food_enabled = true
	n.unlocked_plots.assign(["solar", "battery", "life_support", "greenhouse", "shelter"])
	n.bonus_goals.assign(["shelter_fast", "battery_20", "food_grew"])
	n.debrief_why = "Light from a solar flare travels fastest, so it arrives before the particles. That gap is your warning time."
	n.debrief_tip = "When the sky glows: recall anyone outside, open the shelter, then close the door once everyone is in."
	n.did_you_know = "In September 2017, Curiosity's radiation detector measured dose rates on Mars 2 to 3 times higher than normal."
	n.did_you_know_source = "Zeitlin et al. 2018, Geophysical Research Letters (Curiosity RAD)"
	n.codex_unlocks.assign(["radiation", "solar_flare", "shelter_shielding"])
	return n


func night_4() -> NightConfig:
	var n := base(4, "Hello, Earth!", "Communication delay")
	n.briefing_text = "Carlo is outside fixing the Comms Dish. Messages to Earth take minutes, so you must decide things yourself!"
	n.crew_ids.assign(["lani", "maya", "mateo", "carlo"])
	n.crew_schedule.assign([mv(0, "lani", "life_support"), mv(0, "maya", "greenhouse"), mv(0, "mateo", "galley"), mv(0, "carlo", "comms_dish")])
	n.hazard_events.assign([
		cold(0.5),
		ev("comms_loss", 80.0, 95.0, 120.0, 0.5, "simplified",
			"Static on the radio! Something is weakening the link to Earth."),
	])
	n.visible_meters.assign(["comms"])
	n.food_enabled = true
	n.comms_delay_real_min = 11.37
	n.unlocked_plots.assign(["solar", "battery", "life_support", "greenhouse", "shelter", "suit_bay", "comms_dish"])
	n.bonus_goals.assign(["all_inside_end", "battery_20", "food_grew"])
	n.debrief_why = "Radio signals take minutes to travel between Mars and Earth, so help from Earth always arrives late."
	n.debrief_tip = "Don't wait for Earth's answer. Bring Carlo inside before sunrise."
	n.did_you_know = "When Perseverance landed in 2021, its signal took 11 minutes and 22 seconds to reach Earth, so it had to land itself."
	n.did_you_know_source = "NASA Mars 2020"
	n.codex_unlocks.assign(["comms_delay"])
	return n


func night_5() -> NightConfig:
	var n := base(5, "The Big Dust", "Dust storm")
	n.briefing_text = "A planet-wide dust storm like the real one in 2018 has covered the sky. The panels made less power today."
	n.crew_ids.assign(["lani", "maya", "mateo", "carlo"])
	n.crew_schedule.assign([mv(0, "lani", "life_support"), mv(0, "maya", "greenhouse"), mv(0, "mateo", "galley"), mv(0, "carlo", "airlock"), mv(100, "carlo", "solar_field", 5)])
	n.hazard_events.assign([
		ev("dust", 0.0, 0.0, 180.0, 0.8, "real",
			"Dust in the sky blocked the sunlight, so the battery starts lower tonight.",
			"2018-06-10", "NASA Mars missions (2018 global dust storm)"),
		cold(0.5),
		ev("thump", 50.0, 50.0, 53.0, 0.5, "simplified",
			"Thump! A gust of wind threw dust against the hull.", "", "", true),
		ev("thump", 130.0, 130.0, 133.0, 0.5, "simplified",
			"Thump! Wind is rattling a loose solar panel.", "", "", true),
	])
	n.visible_meters.assign(["comms"])
	n.food_enabled = true
	n.comms_delay_real_min = 4.6
	n.unlocked_plots.assign(["solar", "battery", "life_support", "greenhouse", "shelter", "suit_bay", "comms_dish"])
	n.bonus_goals.assign(["battery_20", "food_grew", "all_inside_end"])
	n.debrief_why = "Martian dust is very fine and sticky. It blocks sunlight and covers solar panels."
	n.debrief_tip = "On dust nights, start with less: fewer cameras and a lower heater."
	n.did_you_know = "In 2018 a dust storm covered all of Mars for weeks."
	n.did_you_know_source = "NASA"
	n.codex_unlocks.assign(["dust"])
	return n


func night_6() -> NightConfig:
	var n := base(6, "Solar Flare Day", "Big solar flare")
	n.briefing_text = "Tonight replays the real X12 solar flare that hit Mars on May 20, 2024. Be ready to shelter!"
	n.crew_ids.assign(["lani", "maya", "mateo", "carlo"])
	n.crew_schedule.assign([mv(0, "lani", "life_support"), mv(0, "maya", "greenhouse"), mv(0, "mateo", "galley"), mv(0, "carlo", "comms_dish"), mv(30, "lani", "solar_field", 5)])
	n.hazard_events.assign([
		cold(0.5),
		ev("flare", 50.0, 50.0, 70.0, 1.0, "real",
			"", "2024-05-20", "NASA: estimated X12 flare"),
		ev("particles", 70.0, 100.0, 160.0, 1.0, "real",
			"", "2024-05-20", "Curiosity RAD (NASA): 8,100 micrograys, about 30 chest X-rays"),
	])
	n.visible_meters.assign(["dose"])
	n.food_enabled = true
	n.comms_delay_real_min = 15.8
	n.unlocked_plots.assign(["solar", "battery", "life_support", "greenhouse", "shelter", "suit_bay", "comms_dish"])
	n.bonus_goals.assign(["shelter_fast", "battery_20", "food_grew"])
	n.debrief_why = "The flare's light reached Mars first. The particles came later, and Mars's thin air can't stop them."
	n.debrief_tip = "Recall the crew the moment the sky glows. Every second of warning counts."
	n.did_you_know = "Someone standing next to Curiosity on May 20, 2024 would have received a dose like 30 chest X-rays."
	n.did_you_know_source = "NASA (Curiosity RAD)"
	n.codex_unlocks.assign([])
	return n


func night_7() -> NightConfig:
	var n := base(7, "The Bulalakaw Night", "Finale")
	n.briefing_text = "Dust, a solar flare and a radio blackout, all at once! Keep everyone safe and send our discovery to Earth."
	n.crew_ids.assign(["lani", "maya", "mateo", "carlo"])
	n.crew_schedule.assign([mv(0, "lani", "life_support"), mv(0, "maya", "greenhouse"), mv(0, "mateo", "galley"), mv(0, "carlo", "comms_dish")])
	n.hazard_events.assign([
		ev("dust", 0.0, 0.0, 180.0, 0.6, "simplified",
			"Dust again! Less sunlight means a weaker battery tonight.",
			"2018-06-10", "Two real events combined: 2018 dust storm + 2024 flare"),
		cold(0.6),
		ev("flare", 90.0, 90.0, 110.0, 1.0, "simplified",
			"", "2024-05-20", "Two real events combined: 2018 dust storm + 2024 flare"),
		ev("particles", 110.0, 135.0, 175.0, 0.8, "simplified",
			"", "2024-05-20", "Two real events combined"),
		ev("comms_loss", 150.0, 150.0, 180.0, 1.0, "simplified",
			"Radio blackout! The storm has cut the link to Earth."),
	])
	n.visible_meters.assign(["comms"])
	n.food_enabled = true
	n.comms_delay_real_min = 4.6
	n.unlocked_plots.assign(["solar", "battery", "life_support", "greenhouse", "shelter", "suit_bay", "comms_dish"])
	n.bonus_goals.assign(["discovery_sent", "shelter_fast", "battery_20"])
	n.debrief_why = "Real missions have to juggle power, air, food and radiation all at the same time."
	n.debrief_tip = "Send important messages early. The radio delay means late messages may never arrive."
	n.did_you_know = "This night combines two real events: the 2018 global dust storm and the May 2024 solar flare."
	n.did_you_know_source = "NASA"
	n.codex_unlocks.assign([])
	return n
