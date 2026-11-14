extends BasePanel
## R-03 NASA Data panel: every real event the game uses (date, what, source, real number,
## badge) plus the live DONKI status.

const EVENTS := [
	["2017-09-10", "SOLAR PARTICLE STORM REACHED MARS", "Curiosity RAD saw dose rates 2-3x above background", "Zeitlin et al. 2018, Geophysical Research Letters", "real", "NIGHT 3"],
	["2018-06-10", "GLOBAL DUST STORM", "Radio delay Earth-Mars that day: 4.6 minutes (from planet positions)", "NASA JPL; delay computed from planet positions", "real", "NIGHT 5"],
	["2021-02-18", "PERSEVERANCE LANDS ON MARS", "Its signal took 11 min 22 s to reach Earth", "NASA Mars 2020", "real", "NIGHT 4"],
	["2024-05-20", "X12 SOLAR FLARE", "Curiosity RAD measured 8,100 microgray, about 30 chest X-rays", "NASA (June 2024)", "real", "NIGHT 6"],
	["2018 + 2024", "FINALE: TWO REAL EVENTS COMBINED", "The dust storm and the flare happen on one night", "Nights 5 + 6 data, combined for the game", "simplified", "NIGHT 7"],
	["MARS NIGHTS", "VERY COLD NIGHTS", "Mars nights are far below freezing, so heating costs power", "Based on Curiosity weather (REMS) data", "simplified", "NIGHT 1"],
	["2021-2023", "MOXIE MADE OXYGEN FROM MARS AIR", "Making oxygen from Mars air uses electric power", "NASA Perseverance / MOXIE", "simplified", "NIGHT 2"],
]


func _build() -> void:
	card_width = 1100
	body.custom_minimum_size.x = 1060
	title("NASA DATA USED IN THIS GAME")
	var list := scroll(400)
	for e in EVENTS:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", Ui.nine("ui_nasa_panel", 12))
		list.add_child(p)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		p.add_child(h)
		var left := VBoxContainer.new()
		left.custom_minimum_size.x = 150
		left.add_child(Ui.label(e[0], Ui.BODY, true, Palette.STATUS_WARN))
		left.add_child(Ui.label(e[5], 8, false, Palette.SKY_HAZE))
		h.add_child(left)
		var mid := VBoxContainer.new()
		mid.add_child(Ui.label(e[1], Ui.BODY, true, Palette.HIGHLIGHT, 680))
		mid.add_child(Ui.label(e[2], Ui.BODY, false, Palette.BASE_CREAM, 680))
		mid.add_child(Ui.label("SOURCE: " + e[3], 8, false, Palette.SKY_HAZE, 680))
		h.add_child(mid)
		h.add_child(Ui.badge(e[4]))

	var live := HBoxContainer.new()
	live.add_theme_constant_override("separation", 12)
	body.add_child(live)
	live.add_child(Ui.badge("live" if DonkiService.is_live() else "archived"))
	live.add_child(Ui.label("TONIGHT'S REAL SUN: " + DonkiService.summary(), Ui.BODY, false, Palette.INK, 880))
	body.add_child(Ui.label("Radiation is shown in the game as 'chest X-rays' (simplified). Real measurements are in microgray.", 8, false, Palette.BASE_PLUM, 1000))
	close_row()
