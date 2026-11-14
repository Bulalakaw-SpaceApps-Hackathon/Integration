# BULALAKAW STATION: Mars Outpost Trainer
### Godot Build Brief V2 (replaces Game Design V1)

> For the AI builder: this document is the single source of truth. Build exactly this. If something here conflicts with your defaults or with Design V1, this document wins. Section 17 is the final checklist.

---

## 0. HOW TO BUILD THIS (rules for the AI builder)

**Engine and language**
- **Godot 4.7.x stable.** The team pins one exact version; write it in `/.godot-version`. Use only Godot 4.7 APIs (no Godot 3 syntax: `TileMapLayer`, not `TileMap`; `CharacterBody2D` with `velocity` + `move_and_slide()`).
- **GDScript only**, with static typing (`var x: int`, `func f() -> void`). No C#, no GDExtension, no plugins.
- **Renderer: Compatibility** from the first commit (required for the web export).
- **Main build: Web export** (itch.io or GitHub Pages). **Backup build: Windows .exe.** Target laptops in a browser first; touch must work but phones are not polished.

**How to structure the code (very important for AI-written code)**
- Build UI and layout **from GDScript** wherever possible. Keep `.tscn` files minimal: a few root scenes plus autoloads. Do not hand-write large `.tscn` files.
- Small, separate scripts with one job each (see Section 16). A bad output should break one file, not the whole game.
- **Every tunable number lives in `res://data/balance.tres`** (a `BalanceConfig` Resource). No magic numbers in scripts.
- **Every night is data**, not code: one `NightConfig.tres` per night, played by one generic `NightDirector`. Adding a night = adding a file.
- Use signals between systems. No `get_node()` / `find_child()` inside `_process`. Use `delta` for all timers and movement.
- No `print` spam; no errors in the debugger at any point.

**Assets**
- 2D top-down. **CC0 assets only** (e.g., Kenney packs) plus the team's own draft sprites. List every asset in a Credits screen.
- Sound: CC0 sound effects (`.ogg`). Soft beeps only, no loud alarms.
- Big, readable fonts by default (minimum 20 px body text at 1280×720).

**Build order (each step must run before the next)**
1. `SimState` + `BalanceConfig` + battery forecast, tested with a debug label
2. Camera Desk (Night 1 playable end to end, including Debrief)
3. `HazardEvent` + `NightDirector` + archive data → **Night 6**, then **Night 7**
4. Hub map (walkable Commander, 7 plots, upgrades, materials)
5. Nights 2, 3, 4, 5 (config files only)
6. `DonkiService` live fetch + NASA Data panel + Codex
7. Judge Mode, settings, save
8. Polish and sound

Any night that is not finished is greyed out in Night Select with "Coming soon". Nothing should look broken.

**Kid-friendly** means ages 7–12: plain words, max two short sentences per popup, big buttons, no gore, no jump scares, nobody ever dies, and failure always teaches something.

---

## 1. THE ONE-LINE PITCH

You are the **Commander of Bulalakaw Station**, a small Mars outpost. Over **7 nights**, you keep your crew safe until sunrise by deciding where the battery's power goes, getting everyone into the shelter when real solar storms hit, and upgrading your base between nights. **Every choice costs something.**

(*"Bulalakaw" is the Filipino word for meteor or shooting star.*)

## 2. WHY THIS GAME EXISTS (NASA Space Apps Challenge, Nov 14–15, 2026)

Challenge theme: a junior astronaut mission trainer where kids 7–12 run a Mars outpost and experience real trade-offs in life support, radiation, power and communication delay, using real NASA data. *(Team: paste the official challenge statement here once confirmed.)*

**Judging criteria and how this game answers them:**
| Criterion | Our answer |
|---|---|
| Impact | A 20-minute campaign any 7-year-old can finish, teaching power budgeting, radiation safety and comms delay |
| Creativity | A cute, kind "security-desk" night game where the tension is "where is my crew, can I get them safe in time?" |
| Validity | Real events, real measured numbers, real planet positions. Every number carries an honest badge |
| Relevance | **NASA data drives the nights**: each hazard night replays a real event measured at Mars |
| Presentation | A 60-second video (Night 1 → build → Night 6 warning window) and a Judge Mode that opens on Night 6 |

---

## 3. THE CORE LOOP

```
Morning Briefing → BUILD (untimed) → NIGHT (3:00) → DEBRIEF → next night
```

- **Briefing:** one card from Mission Control: tonight's theme, the real event (with date and badge), the goal and bonus goals.
- **Build (untimed):** walk the Commander around the base, spend **materials** on upgrades. Kids can take as long as they want.
- **Night (exactly 3:00 real time, 18:00 → 06:00 game clock, 15 s per game hour):** sit at the Camera Desk. Survive until 06:00.
- **Debrief:** what happened, why (one line of science), one tip, one "Did you know?" with a source, stars, materials earned.

There are **no Action Points**. Materials are the only currency.

---

## 4. LOOK, FEEL AND CONTROLS

**Art style:** cute 2D top-down (Stardew Valley / Core Keeper feel). Chunky white-and-orange modules, red-orange ground, round astronauts with big visors. Day sky butterscotch; night deep blue with two small moons and a bright dot for Earth.

### Hub Map (build phase)
- `TileMapLayer` ground, a `CharacterBody2D` Commander (WASD/arrows; Godot 4.7 built-in virtual joystick on touch).
- **7 fixed plots** (Section 6). Stand next to one and press **E** (or tap **Build**) to open its upgrade card. Plots can also be **tapped directly** so judges can skip walking.
- Corner HUD: materials count, Night number, "Start Night" button.

### Camera Desk (night phase): the heart of the game
Layout (1280×720 reference):
- **Top bar:** big **Battery bar** with the **forecast line** ("At this rate your battery lasts until 04:30 🌙"), and the clock counting to 06:00. The forecast updates instantly whenever any switch changes. This is the main teaching tool.
- **Centre:** **2 big monitors** showing the 2 cameras that are on.
- **Bottom:** strip of **6 large camera buttons** with icons (Sky Radar, Airlock, Solar Field, Shelter, Life Support, Greenhouse). Max 2 on at once; each camera on draws battery. Keys `1`–`6`.
- **Left panel:** **Shelter Door** (Space) and **Recall Crew** buttons.
- **Right panel:** **Heater** (Low / Mid / High) and **Life Support** (Low / Normal / High), **Crop Lamp** toggle, and from Night 4 the **Comms Dish** toggle and **Ask Earth** button.
- **Sticky note** on the desk: tonight's goal + bonus goals with ticks.
- **At most one extra meter** per night (see Section 11).
- Camera feeds are flat illustrated scenes with overlays that change: flicker, static, dust haze, a moving crew sprite, a glowing sky.

### Controls
- Desktop: WASD/arrows, `E` interact, `1`–`6` cameras, `Space` shelter door, `R` recall, `Esc` pause, `M` mute.
- Touch: everything tappable, minimum 64 px targets.

### Accessibility (built in, not a mode)
- Every alert uses **icon + shape + colour**, never colour alone.
- Large fonts by default. Mute, Pause, Calm Mode, Retry always available.

---

## 5. RESOURCES

| Resource | Where it shows | Notes |
|---|---|---|
| ⚡ **Battery** (%) | Desk top bar, always | **The one shared budget.** Every system draws from it |
| 💨 **Oxygen** (%) | Desk, Night 2 onward | Crew breathe it; Life Support makes it (and draws battery) |
| ☢️ **Crew dose** (in **chest X-rays**, ≈) | Desk, Night 3 onward | Per crewmate, shown on a dosimeter panel |
| 📡 **Comms** (link quality %) | Desk, Night 4 onward | Lower = longer Ask Earth delay; dust and flares lower it |
| 🧱 **Materials** | Hub HUD and Debrief | Earned at night, spent on upgrades |
| 😊 Morale / 🍎 Supplies | **Debrief only**, as results | Never live meters on the desk |

**Radiation unit:** the game shows dose as **"chest X-rays"** with the ≈ Simplified badge. The real figure appears in the Codex and NASA Data panel (e.g., "8,100 µGy measured by Curiosity RAD on 2024-05-20, about 30 chest X-rays (NASA)"). **Do not use mSv anywhere.**

### No-free-choice table (all must be implemented)
| If the player... | Good thing | The cost |
|---|---|---|
| Life Support HIGH | Oxygen rises | Big battery drain |
| Life Support LOW | Saves battery | Oxygen falls |
| Heater HIGH | Crew warm, morale result up | Big battery drain |
| Heater LOW | Saves battery | Cold: morale result down, crop bonus fails |
| Crop Lamp ON | Greenhouse bonus goal possible | Battery drain |
| Camera ON (max 2) | See where crew and hazards are | Battery drain per camera |
| Close Shelter Door | Dose inside the shelter almost zero | Door motor costs battery; crew inside stop their jobs (morale result down) |
| Recall Crew | Brings outside crew home | Their job stays unfinished; walking time depends on Suit Bay level |
| Comms Dish ON | Ask Earth and Send Discovery work | Battery drain |
| Upgrade plot X | Its night effect improves | Materials not spent on other plots |

If you find a choice with no cost, add one.

---

## 6. THE BASE: 7 FIXED PLOTS

Each plot holds one module, **Level 1 → 2 → 3**. Every level has a visible effect at night.

| Plot | Unlocks | Level 2 / Level 3 effect |
|---|---|---|
| Solar Field | Night 1 | Battery at sunset higher (L1 70% → L2 85% → L3 100%) |
| Battery Bank | Night 1 | All drains × 0.9 → × 0.8 (better storage) |
| Life Support | Night 2 | Makes more oxygen per battery used |
| Storm Shelter | Night 3 | Door closes faster; dose inside lower |
| Suit Bay | Night 4 | Outside crew walk back faster; outside dose lower |
| Comms Dish | Night 4 | Ask Earth delay shorter; resists static |
| Greenhouse | Night 2 | Crop bonus easier; small oxygen bonus |

Upgrade cost: **L2 = 2 materials, L3 = 4 materials** (in `balance.tres`). A good player can max out about half the base by Night 7, so they must choose.

---

## 7. THE CREW: the moving pieces

The Commander stays at the desk at night. Crewmates **move between rooms** doing jobs, and the player tracks them on the cameras. Nobody ever chases the player. Events happen to the **crew** or the **base**, never to the player.

| Crew | Job | Joins | Tip line example |
|---|---|---|---|
| **Lani** | Engineer | Night 1 | "Solar Field B looks dusty. Cleaner panels mean more power!" |
| **Maya** | Botanist | Night 2 | "Plants need light, water and warmth, and all of that costs power." |
| **Mateo** | Doctor | Night 3 | "Watch our dosimeters, Commander. Radiation is invisible!" |
| **Carlo** | EVA specialist | Night 4 | "I'm outside by the airlock tightening the oxygen line." |

Each crewmate: `location` (room id or `outside`), `job`, `dose` (chest X-rays), `walk_speed`.
- A night has a **crew schedule** (in `NightConfig`): who goes where, when.
- **Recall** sends every outside crewmate to the airlock; walk time = `balance.recall_time_base / suit_bay_multiplier`.
- **Crew never die.** On failure: "evacuated to the shelter to rest."

---

## 8. SUIT CARE (lives in the Suit Bay upgrade)

Real reason (shown in the Codex): suit seals keep air in, the backpack holds oxygen and power, cooling water carries heat away, and the CO₂ scrubber cleans each breath. Worn parts make work outside slower and riskier.

In game: **Suit Bay level** sets recall walking speed and outside dose multiplier. The five suit mini-games from Design V1 are **stretch goals only**.

---

## 9. NIGHT EVENTS: "spooky thing → real cause"

3–4 events per night, spaced **25–40 s** apart (Calm Mode: × 1.5). Each event shows a one-line "why" when it happens and is explained again in the Debrief.

| Spooky moment | Real cause | Player response |
|---|---|---|
| Greenhouse light **flickers** | Battery is low | Turn off a camera, lamp, or lower the heater |
| **Fan slows**, air feels heavy | CO₂ filter clogging | Life Support to Normal/High (battery cost) |
| A **shadow** on Sky Radar | A crewmate on EVA | Check Airlock cam; Recall if needed |
| **Thump** on the hull | Wind lifted dust or a loose panel | Check Solar Field cam |
| **Static** on comms | Dust storm or flare weakening radio | Wait, or boost Comms Dish (battery) |
| **Sky Radar glows, alarm lamp** | Flare light arrives first (speed of light) | **Warning window**: get crew into the shelter, close the door |
| **Dosimeters tick up** | Energetic particles arrive later | Everyone should already be inside |
| **Temperature drops** | Mars nights are very cold | Heater (battery cost) |

### The warning window (core mechanic, Nights 3, 6, 7)
Real science: during the 2024-05-20 event, the X-rays and gamma rays from the flare arrived first at light speed, and the charged particles arrived tens of minutes later (NASA). In game: **flare flash → `balance.warning_window_sec` (default 20 s) → particle dose starts.** Shelter level shortens door time; Suit Bay level shortens recall time. Debrief line: "Light is faster than particles!"

---

## 10. COMMUNICATION DELAY

Real science: radio takes minutes to travel between Mars and Earth, depending on where the planets are. On the day Perseverance landed (2021-02-18), its signal took **11 min 22 s** to reach Earth, so the rover had to land itself.

In game (Night 4 onward):
- **Ask Earth** button sends a question; the answer arrives after `real_delay_minutes × balance.delay_seconds_per_real_minute` (default **5 s per real minute**), longer if Comms quality is low.
- The UI shows: "Message sent… arriving in 0:57" and a badge "★ Real delay for this date: 11 min 22 s · ≈ shortened ×12".
- Night 7 goal: **send the discovery before the blackout.** Sending takes the delay time, so the player must start early.

Real one-way delays (Earth–Mars light time, computed from planet positions; Perseverance value matches NASA's published 11 min 22 s):
| Date | One-way delay |
|---|---|
| 2021-02-18 (Perseverance landing) | 11 min 22 s |
| 2018-06-10 (global dust storm) | 4.6 min |
| 2024-05-20 (X12 flare) | 15.8 min |

---

## 11. THE CAMPAIGN: 7 NIGHTS

**Build priority: 1 → 6 → 7 → 2 → 3 → 4 → 5.**

| Night | Name | New this night | Extra desk meter | Real data (badge) | Events |
|---|---|---|---|---|---|
| 1 | *Welcome, Commander* (Power) | Battery + forecast, Solar + Battery Bank plots. Crew: Lani | none | ≈ Mars night temperatures, based on Curiosity weather data | Sunset, temperature drop, flicker |
| 2 | *Air to Breathe* | Oxygen, Life Support + Greenhouse plots. + Maya | Oxygen | ≈ MOXIE idea: making oxygen from Mars air costs power | Fan slows, flicker, temperature drop |
| 3 | *Invisible Energy* (small radiation) | Dosimeters, Shelter plot, first warning window. + Mateo | Crew dose | ★ Sep 10–12, 2017 particle storm: Curiosity RAD saw dose rates 2–3× background | Shadow, glow + alarm, dose ticks |
| 4 | *Hello, Earth!* | Comms, Ask Earth, crewmate on EVA at dusk, Suit Bay + Comms Dish plots. + Carlo | Comms | ★ Perseverance landing delay, 11 min 22 s | Shadow outside, static, recall |
| 5 | *The Big Dust* | Dust storm: lower battery at sunset, dusty panels | Comms | ★ 2018 global dust storm (delay 4.6 min) | Thumps, static, flicker |
| 6 | *Solar Flare Day* | Full-strength warning window | Crew dose | ★ 2024-05-20 X12 flare: Curiosity RAD measured 8,100 µGy ≈ 30 chest X-rays (NASA) | Shadow, glow + alarm, dose spike |
| 7 | *The Bulalakaw Night* (finale) | Dust + flare + blackout; send the discovery | Comms | ≈ **Two real events combined** (Nights 5 + 6), labelled honestly | Everything |

Each night has a **first-time guide popup** (max two sentences) for whatever is new, and unlocks its Codex entries.

After Night 7: **Mission Complete** screen with total stars and a printable "Mission Planner Certificate" (stretch: downloadable image).

---

## 12. WINNING, LOSING AND SCORING

**Win the night:** reach 06:00 with no lose condition.

**Lose conditions** (any one):
- Battery at 0% for `balance.battery_zero_grace_sec` (default 10 s)
- Oxygen reaches 0%
- Any crewmate's dose exceeds `balance.dose_limit_xrays` (default 15 chest X-rays per night)

**On loss:** "Emergency! Everyone is going to the shelter to rest." → **Friendly Debrief** with *what happened*, *why* (one line of science) and *one tip*. The only button is **Retry Night**: upgrades are kept; nothing earned that night counts. **After 2 fails on the same night**, Mission Control shows a hint arrow during that night.

**Materials earned** (only on a win):
- Survive the night: **+3**
- Each bonus goal met: **+1** (shown on the sticky note), e.g.:
  - all crew inside the shelter within 30 s of the alarm
  - battery above 20% at 06:00
  - crop lamp kept on all night (Greenhouse)
  - Night 7: discovery sent before the blackout
- **Stars (1–3) = bonus goals met** (minimum 1 star for surviving).

**Randomness:** event times jitter ±5 s and crew schedules shuffle slightly per run (seeded), but **real-event order and timing never change**.

---

## 13. JUDGE MODE

Main Menu → **Judge Mode**:
- **Night Select (1–7)**, opens with **Night 6** selected by default
- **Unlock all plots**
- **+20 materials**
- **2× speed** toggle

Cut from V1: sliders, trigger buttons, the auto-play guided tour. The **60-second video** (Night 1 → a quick build → Night 6 warning window) replaces the tour.

---

## 14. REAL NASA DATA

### Data layer (must be swappable)
The `NightDirector` **never reads NASA data directly.** It only reads a list of neutral `HazardEvent` records:

```gdscript
class_name HazardEvent extends Resource
@export_enum("flare", "particles", "dust", "comms_loss", "cold", "co2", "eva") var type: String
@export var start_sec: float      # seconds into the 180 s night
@export var peak_sec: float
@export var end_sec: float
@export_range(0.0, 1.0) var intensity: float
@export var real_date: String     # "2024-05-20"
@export var source_name: String   # "Curiosity RAD (NASA)"
@export_enum("real", "simplified", "archived", "live") var badge: String
@export var why_text: String      # one-line science shown to the player
```

Each data source has its own **adapter** that turns its data into `HazardEvent`s:
- `ArchiveAdapter`: the embedded real events in Section 11 (the nights always use these).
- `DonkiAdapter`: live NASA DONKI (`https://api.nasa.gov/DONKI/FLR`, `SEP`, `CME`, `GST` with `startDate` / `endDate`), used for the **"Tonight's real Sun" forecast** in the Morning Briefing.
- When the official challenge data is published, add **one new adapter**. Nothing else changes.

### Live fetch rules
1. Use an `HTTPRequest` node, 8 s timeout, team's own free api.nasa.gov key (fall back to `DEMO_KEY`). Key can be changed in Settings.
2. Cache the result in `user://donki_cache.json` for 24 h, so each player fetches at most once a day.
3. Success → green **LIVE NASA DATA** badge with the fetched event dates.
4. Failure (offline, rate limit, browser CORS block) → amber **ARCHIVED NASA DATA** badge, using the archive. **Never present archived data as live.**
5. The game works fully either way.
6. **First-hour test:** export an empty web build that fetches DONKI and prints the result, to confirm the browser allows it.

### Honesty badges
Only on numbers and facts that come from data: **★ Real**, **≈ Simplified**, **Live**, **Archived**. Tapping a badge shows one plain sentence about what is real and what was simplified.

### NASA Data panel (one screen)
Lists every real event used: date, what happened, source, badge, and the real number (e.g., 8,100 µGy).

### Codex (~8 entries, unlocked across the nights)
sol · battery and solar power · dust · CO₂ and oxygen · radiation · solar flare · storm shelter · comms delay.
Each entry: an icon, **two sentences**, one source line.

### Accuracy guardrails (facts to use, keep them exactly right)
- A sol is about **24 hours 39 minutes**.
- Mars has a very thin atmosphere and no global magnetic field, so energetic particles can reach the ground.
- 2024-05-20: an estimated **X12** flare; Curiosity RAD measured **8,100 micrograys ≈ 30 chest X-rays**, its biggest surge since landing (NASA).
- Sep 2017: a solar particle event raised Curiosity RAD dose rates **2–3× above background** (Zeitlin et al., 2018, GRL).
- Flare light (X-rays, gamma rays) arrives before the particles.
- Perseverance's landing signal took **11 min 22 s** to reach Earth (NASA).
- Martian soil contains **perchlorate**, a salt that is bad for people and plants.
- Grays measure absorbed energy; the game simplifies to "chest X-rays". Do not invent other "NASA facts". If unsure, round and badge it ≈.

---

## 15. KID-FRIENDLY RULES

- Plain language; explain each science word the first time it appears.
- Max **two short sentences** per popup.
- Always show **why** when something bad happens ("Battery is low because the sun went down!").
- **Hint button** (little helmet) always available.
- More than 4 alerts at once → group them.
- No jump scares, no screams, soft beeps only.
- **Pause anywhere:** Resume, Settings, Codex, Retry Night, Quit.
- **Settings:** Mute, Calm Mode, NASA API key. Text is structured so translation (e.g., Filipino) can be added later: all strings in one `res://data/strings_en.json`.
- **Save:** `ConfigFile` at `user://save.cfg` (works in web builds): highest night reached, stars per night, materials, plot levels, unlocked Codex entries, settings.

---

## 16. ARCHITECTURE AND DATA MODEL

### Folder layout
```
res://
  autoload/   SimState.gd  Balance.gd  Progression.gd  DonkiService.gd  Sfx.gd
  data/       balance.tres  nights/night_1.tres … night_7.tres  codex/*.tres  strings_en.json
  resources/  BalanceConfig.gd  NightConfig.gd  HazardEvent.gd  CodexEntry.gd  CrewSchedule.gd
  adapters/   ArchiveAdapter.gd  DonkiAdapter.gd
  scenes/     Main.tscn  HubMap.tscn  Desk.tscn  Debrief.tscn  Menus.tscn
  scripts/    NightDirector.gd  DeskUI.gd  HubMap.gd  Commander.gd  CrewAgent.gd  Plot.gd  JudgeMode.gd
  assets/     sprites/  sfx/  fonts/
```

### Autoloads
- **`SimState`**: live night state: `clock_sec`, `battery`, `oxygen`, `comms`, `crew[]`, `switches` (heater, life_support, cameras_on, crop_lamp, dish, shelter_door), `forecast_end_hour`. Emits `changed`, `alert(why_text)`, `lost(reason)`, `won()`.
- **`Balance`**: loads `balance.tres`.
- **`Progression`**: materials, plot levels, stars, unlocked nights/Codex; save/load.
- **`DonkiService`**: live fetch, cache, badge state.
- **`Sfx`**: plays CC0 sounds; respects mute.

### `NightConfig` (one file per night)
`id, title, theme, briefing_text, debrief_why, debrief_tip, did_you_know, did_you_know_source, hazard_events: Array[HazardEvent], visible_meters: Array[String], crew_ids: Array[String], crew_schedule: Array[CrewSchedule], unlocked_plots: Array[String], bonus_goals: Array[String], comms_delay_real_min: float, codex_unlocks: Array[String]`

### Simulation (tick every frame with `delta`; all numbers from `balance.tres`)
- **Battery drain/s** = `(base_load + life_support[level] + heater[level] + cameras_on × camera_cost + crop_lamp + dish) × battery_bank_multiplier`
- **Battery at sunset** = `solar_start[solar_level]` minus `dust_penalty` on dust nights
- **Forecast:** `hours_left = battery / drain_per_sec / 15` → shown as a clock time; update whenever a switch changes
- **Oxygen/s** = `life_support_output[level] × ls_upgrade_multiplier − crew_inside × breath_rate`
- **Dose/s per crewmate** = `particle_intensity × (outside ? outside_rate × suit_multiplier : inside_rate) × (in_shelter_with_door_closed ? shelter_multiplier : 1)`
- **Comms** = `100 − dust × dust_comms_penalty − flare × flare_comms_penalty` (0 if dish off)

### Starting balance values (tune freely in `balance.tres`)
| Key | Default |
|---|---|
| night_length_sec | 180 (15 s per game hour) |
| solar_start | [70, 85, 100] % |
| base_load | 0.05 %/s |
| life_support (Low/Normal/High) | 0.08 / 0.15 / 0.25 %/s |
| heater (Low/Mid/High) | 0.05 / 0.10 / 0.18 %/s |
| camera_cost (each) | 0.04 %/s |
| crop_lamp | 0.06 %/s |
| dish | 0.05 %/s |
| shelter_door_close | 0.5 % per close |
| battery_bank_multiplier | [1.0, 0.9, 0.8] |
| warning_window_sec | 20 |
| battery_zero_grace_sec | 10 |
| dose_limit_xrays | 15 per crewmate per night |
| recall_time_base | 15 s (÷ suit bay [1.0, 1.3, 1.6]) |
| delay_seconds_per_real_minute | 5 |
| event_gap_sec | 25–40 (Calm Mode × 1.5) |
| upgrade_cost | L2 = 2, L3 = 4 |
| survive_reward / bonus_reward | 3 / 1 |

(Sanity check for Night 1 defaults: Normal life support + Mid heater + 2 cameras + base ≈ 0.38 %/s × 180 s ≈ 68%, against a 70% start: tight but survivable, which is the lesson.)

---

## 17. FINAL CHECKLIST

**Core**
- [ ] Godot 4.7.x, GDScript, Compatibility renderer; web build runs in Chrome/Edge/Firefox; Windows backup build
- [ ] Camera Desk: 6 cameras, max 2 on, clock 18:00 → 06:00 in 3:00, battery forecast line, shelter door, recall, heater, life support, crop lamp, dish
- [ ] Hub map: walkable Commander + tap-to-select, 7 plots with 3 levels, materials
- [ ] Battery as one shared budget; every row of the no-free-choice table implemented
- [ ] Crew move between rooms on a schedule; recall works; Suit Bay changes recall speed and outside dose
- [ ] Warning window (light first, particles later) in Nights 3, 6, 7

**Campaign**
- [ ] 7 nights as `NightConfig.tres` files played by one `NightDirector`; unfinished nights show "Coming soon"
- [ ] Lose conditions, friendly debrief (what / why / tip / did you know + source), Retry only, hint arrow after 2 fails
- [ ] Materials and stars from bonus goals; Mission Complete screen

**Science and honesty**
- [ ] Every real event in the archive with date, source and badge; NASA Data panel
- [ ] Dose in "chest X-rays" (≈) with real µGy in the Codex; no mSv anywhere
- [ ] Real comms delays per date, scaled and labelled; Ask Earth affects gameplay
- [ ] DONKI live fetch with cache and archive fallback; LIVE vs ARCHIVED badge always correct
- [ ] Codex with ~8 entries, two sentences + source each

**Judges**
- [ ] Judge Mode: Night Select (default Night 6), unlock all, +20 materials, 2× speed
- [ ] 60-second video recorded

**Quality**
- [ ] Touch works; mute, pause, Calm Mode, retry; icon + shape on every alert
- [ ] Every spooky moment has a "why" line
- [ ] No errors in the debugger or browser console; 60 FPS on a normal laptop
- [ ] Credits screen lists every CC0 asset

---

## 18. IF TIME RUNS OUT

Cut in this order (first items first):
1. Downloadable certificate, Suit mini-games, extra sound polish
2. Nights 5, 4, 3, 2 (in that order); they show "Coming soon"
3. Live DONKI fetch (archive only, still badged ARCHIVED)
4. Touch polish

**Never cut:** Camera Desk with battery forecast, the warning window, Nights 1, 6 and 7, the real-event archive with honest badges, plot upgrades, friendly debrief with tips, Judge Mode Night Select.

---

## Sources
- NASA, *NASA Watches Mars Light Up During Epic Solar Storm* (June 2024): X12 flare on 2024-05-20; 8,100 µGy ≈ 30 chest X-rays measured by Curiosity RAD.
- Zeitlin et al. (2018), *Analysis of the Radiation Hazard Observed by RAD on the Surface of Mars During the September 2017 Solar Particle Event*, Geophysical Research Letters 45(12).
- NASA JPL (2017), *Large Solar Storm Sparks Global Aurora and Doubles Radiation Levels on the Martian Surface*.
- NASA / Mars 2020 coverage: Perseverance landing signal delay of 11 min 22 s (2021-02-18).
- Earth–Mars light-time values for 2018-06-10 and 2024-05-20 computed from planetary positions (astropy built-in ephemeris); cross-checked against the Perseverance figure.
- NASA DONKI Space Weather Database: https://api.nasa.gov (endpoints FLR, SEP, CME, GST).

*End of brief. Build the game described above.*
