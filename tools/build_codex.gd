extends SceneTree
## Writes res://data/codex/<id>.tres (9 entries). Facts follow the build brief's accuracy guardrails.
##   godot --headless --path . -s res://tools/build_codex.gd

const ENTRIES := [
	["sol", "A DAY ON MARS: THE SOL", "A day on Mars is called a sol. It lasts about 24 hours and 39 minutes.", "", "NASA Mars Facts", "real"],
	["battery_solar", "BATTERIES AND SOLAR POWER", "Solar panels only make power while the Sun is up. At night a Mars base runs on the energy its batteries stored in the day.", "", "NASA Mars Exploration (solar-powered missions)", "simplified"],
	["dust", "DUST STORMS", "Mars has dust storms that can cover the whole planet. In 2018 a global storm blocked so much sunlight that the solar-powered Opportunity rover lost power.", "Global dust storm, June 2018", "NASA JPL", "real"],
	["co2_oxygen", "AIR: CO2 AND OXYGEN", "Mars air is mostly carbon dioxide, which people cannot breathe. NASA's MOXIE experiment on Perseverance made oxygen from that air, using electric power.", "", "NASA Perseverance / MOXIE", "real"],
	["food", "GROWING FOOD ON MARS", "Plants need light, water and warmth, and on a Mars base all three cost power. Martian soil also contains perchlorate, a salt that is bad for people and plants.", "", "NASA (Phoenix lander found perchlorate, 2008)", "real"],
	["radiation", "RADIATION", "Mars has a very thin atmosphere and no global magnetic field, so energetic particles from space can reach the ground. Curiosity's RAD instrument measures them.", "2024-05-20: 8,100 microgray, about 30 chest X-rays", "NASA, Curiosity RAD (2024)", "real"],
	["solar_flare", "SOLAR FLARES", "A solar flare is a sudden burst of light from the Sun. Its X-rays arrive first at the speed of light, and the energetic particles arrive later.", "2024-05-20: an estimated X12 flare", "NASA (June 2024)", "real"],
	["shelter_shielding", "SHELTER AND SHIELDING", "Shielding means putting thick material between people and radiation. A shelter with thick walls lets far fewer particles reach the crew.", "In the game: shelter cuts dose to 20% (L1) down to 5% (L3)", "NASA space radiation research (simplified)", "simplified"],
	["comms_delay", "TALKING TO EARTH", "Radio signals take minutes to travel between Mars and Earth. When Perseverance landed on 2021-02-18, its signal took 11 minutes 22 seconds, so it had to land by itself.", "11 min 22 s (2021-02-18)", "NASA Mars 2020", "real"],
]

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/codex")
	var i := 0
	for e in ENTRIES:
		var c := CodexEntry.new()
		c.id = e[0]; c.title = e[1]; c.text = e[2]; c.real_number = e[3]; c.source = e[4]; c.badge = e[5]
		c.order = i
		i += 1
		var err := ResourceSaver.save(c, "res://data/codex/%s.tres" % c.id)
		print(("saved " if err == OK else "FAILED ") + c.id)
	quit()
