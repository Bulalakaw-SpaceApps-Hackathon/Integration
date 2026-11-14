extends Node
## Everything that survives between nights and between play sessions.
## Saved with ConfigFile in user:// (works in web builds via IndexedDB).

signal changed

const SAVE_PATH := "user://save.cfg"
const NIGHT_COUNT := 7

var materials: int = 0
var food: int = -1                 # -1 = food not started yet (starts on the first food night)
var levels: Dictionary = {}        # plot id -> 1..3
var stars: Dictionary = {}         # night id (int) -> best stars
var highest_unlocked: int = 1
var fails: Dictionary = {}         # night id -> fails in a row (hint arrow after 2)
var codex: Array[String] = []
var calm_mode: bool = false
var muted: bool = false
var judge_mode: bool = false     # session only: Judge Mode flags are never saved
var unlock_all: bool = false
var api_key: String = ""
var seen_guides: Array[int] = []   # nights whose first-time guide popup was shown
var tutorial_done: bool = false
var story_seen: bool = false
var discoveries: Dictionary = {}   # night id -> discovery title
var sponsor_deals: Array = []      # [[sponsor number, nights left], ...]: accepted sponsors keep sending ads
var sponsor_answered: int = 0      # the day whose sponsor offer was already answered
var resting: Array = []            # crew ids resting today (caught outside in last night's storm)
var ready_badge: bool = false      # finished the Night 0 tutorial


## A plot can be built once any night up to `night_id` has unlocked it.
func plot_unlocked(plot: String, night_id: int) -> bool:
	if unlock_all:
		return true
	for n in range(1, night_id + 1):
		var cfg := SimState.load_night(n)
		if cfg and cfg.unlocked_plots.has(plot):
			return true
	return false


func night_available(night_id: int) -> bool:
	var cfg := SimState.load_night(night_id)
	if cfg == null or not cfg.ready:
		return false
	return judge_mode or night_id <= highest_unlocked


func total_stars() -> int:
	var t := 0
	for k in stars:
		t += int(stars[k])
	return t


func _ready() -> void:
	reset_levels()
	load_game()


func reset_levels() -> void:
	for p in OutpostSim.PLOTS:
		levels[p] = 1


func food_for_night(cfg: NightConfig) -> int:
	if cfg.food_enabled and food < 0:
		food = Balance.config.food_start
	return maxi(food, 0)


func upgrade_cost(plot: String) -> int:
	var lv: int = levels.get(plot, 1)
	if lv >= 3:
		return -1
	return Balance.config.upgrade_cost[lv]   # index lv = cost to reach lv + 1


func can_upgrade(plot: String) -> bool:
	var cost := upgrade_cost(plot)
	return cost >= 0 and materials >= cost


func upgrade(plot: String) -> bool:
	if not can_upgrade(plot):
		return false
	materials -= upgrade_cost(plot)
	levels[plot] = int(levels.get(plot, 1)) + 1
	save_game()
	changed.emit()
	return true


## Win: keep rewards. Lose: nothing earned counts (upgrades are kept anyway).
func apply_night_result(cfg: NightConfig, report: Dictionary) -> void:
	if report.won:
		materials += int(report.materials)
		if cfg.food_enabled:
			food = int(report.food_after)
		stars[cfg.id] = maxi(int(stars.get(cfg.id, 0)), int(report.stars))
		highest_unlocked = maxi(highest_unlocked, mini(cfg.id + 1, NIGHT_COUNT))
		fails[cfg.id] = 0
		if report.get("discovery_found", false):
			discoveries[cfg.id] = report.discovery.title
		for entry in cfg.codex_unlocks:
			if not codex.has(entry):
				codex.append(entry)
		resting = report.get("resting", [])
		for d in sponsor_deals:
			d[1] = int(d[1]) - 1
		sponsor_deals = sponsor_deals.filter(func(d: Array) -> bool: return int(d[1]) > 0)
	else:
		fails[cfg.id] = int(fails.get(cfg.id, 0)) + 1
	save_game()
	changed.emit()


## Accept today's sponsor: its ads (and pay) last Balance.sponsor_nights nights.
func add_sponsor(index: int) -> void:
	for d in sponsor_deals:
		if int(d[0]) == index:
			d[1] = Balance.config.sponsor_nights
			return
	sponsor_deals.append([index, Balance.config.sponsor_nights])


func sponsors_tonight() -> Array:
	var out: Array = []
	for d in sponsor_deals:
		out.append(int(d[0]))
	return out


func show_hint_arrow(night_id: int) -> bool:
	return int(fails.get(night_id, 0)) >= 2


func save_game() -> void:
	if judge_mode or Game.tutorial:
		return          # Judge Mode and the tutorial are sandboxes: never written to the player's save
	var f := ConfigFile.new()
	f.set_value("progress", "materials", materials)
	f.set_value("progress", "food", food)
	f.set_value("progress", "levels", levels)
	f.set_value("progress", "stars", stars)
	f.set_value("progress", "highest_unlocked", highest_unlocked)
	f.set_value("progress", "fails", fails)
	f.set_value("progress", "codex", codex)
	f.set_value("settings", "calm_mode", calm_mode)
	f.set_value("settings", "muted", muted)
	f.set_value("settings", "api_key", api_key)
	f.set_value("progress", "seen_guides", seen_guides)
	f.set_value("progress", "tutorial_done", tutorial_done)
	f.set_value("progress", "story_seen", story_seen)
	f.set_value("progress", "discoveries", discoveries)
	f.set_value("progress", "sponsor_deals", sponsor_deals)
	f.set_value("progress", "sponsor_answered", sponsor_answered)
	f.set_value("progress", "resting", resting)
	f.set_value("progress", "ready_badge", ready_badge)
	var err := f.save(SAVE_PATH)
	if err != OK:
		push_warning("Could not save progress (%s)" % error_string(err))


## Leave Judge Mode and go back to the player's real saved progress.
func leave_judge_mode() -> void:
	judge_mode = false
	unlock_all = false
	materials = 0
	food = -1
	reset_levels()
	stars.clear()
	highest_unlocked = 1
	fails.clear()
	codex.clear()
	discoveries.clear()
	sponsor_deals.clear()
	sponsor_answered = 0
	resting.clear()
	load_game()
	changed.emit()


func load_game() -> void:
	var f := ConfigFile.new()
	if f.load(SAVE_PATH) != OK:
		return
	materials = f.get_value("progress", "materials", 0)
	food = f.get_value("progress", "food", -1)
	levels.merge(f.get_value("progress", "levels", {}), true)
	stars = f.get_value("progress", "stars", {})
	highest_unlocked = f.get_value("progress", "highest_unlocked", 1)
	fails = f.get_value("progress", "fails", {})
	codex.assign(f.get_value("progress", "codex", []))
	calm_mode = f.get_value("settings", "calm_mode", false)
	muted = f.get_value("settings", "muted", false)
	api_key = f.get_value("settings", "api_key", "")
	seen_guides.assign(f.get_value("progress", "seen_guides", []))
	tutorial_done = f.get_value("progress", "tutorial_done", false)
	story_seen = f.get_value("progress", "story_seen", false)
	discoveries = f.get_value("progress", "discoveries", {})
	sponsor_deals = f.get_value("progress", "sponsor_deals", [])
	sponsor_answered = f.get_value("progress", "sponsor_answered", 0)
	resting = f.get_value("progress", "resting", [])
	ready_badge = f.get_value("progress", "ready_badge", false)


func new_game() -> void:
	materials = 0
	food = -1
	reset_levels()
	stars.clear()
	highest_unlocked = 1
	fails.clear()
	codex.clear()
	seen_guides.clear()
	tutorial_done = false
	story_seen = false
	discoveries.clear()
	sponsor_deals.clear()
	sponsor_answered = 0
	resting.clear()
	save_game()
	changed.emit()
