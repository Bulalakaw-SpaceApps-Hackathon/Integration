# Bulalakaw Station (Godot 4.7.2, GDScript)

The **whole game is playable end to end**: Title → Night Select → Base map (Morning Briefing, build) →
Camera Desk night → Debrief → next night … → Mission Complete. **Every asset is a placeholder** with the
final file name, folder and size, so finals drop in without code changes (see "Swapping in final art").

## Open and run
1. Open the folder in **Godot 4.7.2** (Compatibility renderer). Press **F5**.
2. `scenes/Desk.tscn` can still be run on its own (**F6**) with its own night picker, for testing one night fast.
3. `scenes/Debug.tscn` is the old text harness for balancing.

| Where | Keys / touch |
|---|---|
| Base map | WASD / arrows walk · **E** build (or tap a plot) · tap the Control Room or START NIGHT |
| Desk | 1–6 cameras · Space shelter door · R recall · H heater · L life support · C crop lamp · D dish · Q ask Earth · T send discovery · F2 2x speed |
| Everywhere | Esc pause (Resume, Settings, Codex, Retry, Base, Quit) · M mute |

## What is in the game
| Area | Files |
|---|---|
| Flow + overlays (pause, panels, toasts) | `autoload/Game.gd`, `scenes/Main.tscn` |
| Title, Night Select (Coming soon / Locked), Mission Complete + certificate download | `scripts/screens/` |
| Panels: Pause, Settings (mute, Calm Mode, NASA key, reset), Codex (9), NASA Data, Credits, Judge Mode | `scripts/screens/*Panel.gd` |
| Base map: tiles, Commander, 7 plots × 3 levels, upgrade cards, materials/food HUD, briefing, touch stick | `scripts/hub/` |
| Camera Desk: feeds with crew sprites, guide popups (first time per night), hint button, hint arrow after 2 fails, debrief with stars + materials | `scripts/DeskUI.gd`, `scripts/WindowView.gd` |
| Live NASA DONKI flares (8 s timeout, 24 h cache, LIVE / ARCHIVED badge) | `autoload/DonkiService.gd` |
| Sounds (Master / Music / SFX buses, mute) | `autoload/Sfx.gd` |
| Asset lookup by file name | `autoload/Assets.gd` + `data/assets.json` |
| Theme (FD-02) built from ui_panel / ui_button / ui_popup | `scripts/Ui.gd` |
| Codex data | `data/codex/*.tres` (made by `tools/build_codex.gd`) |
| Credits + Godot MIT notice | `CREDITS.md` (shown in game) |

## How a night plays (after tester feedback)
- **Big goal** (story card on the first base visit, always on the base HUD): keep the crew safe for 7 nights until the **supply ship** lands, and find **one science discovery** each night.
- **Cameras matter:** problems (loose cable, clogged filter, airlock leak, pipe leak, shelter seal) only show on their camera. Tap the sparks to fix. Crew **call for help**: open the camera where they are, tap them, answer YES / NO (each has a cost). The **discovery** sparkles on one camera: tap it. Camera buttons blink `!` when that camera needs you.
- **Crew talk:** crew say where they are going ("Off to the greenhouse!"), so they are predictable.
- **Every switch can go OFF:** heater and life support cycle OFF > LOW > MID/NORM > HIGH. Locked controls say LOCKED NIGHT n.
- **Sponsor deals** (Night 2+, on the briefing card): accept for +3 materials (only if you survive); made-up sponsor messages then pop over a monitor and must be tapped closed.
- **Help:** a `?` on every control; Night 1 is a guided walkthrough (clock frozen until you finish it).
- Data: `data/night_extras.json` (discoveries, crew requests, sponsor names). Numbers: the "Camera problems" group in `balance.tres`.

## Day / build time (mandatory, hands-on)
- Between nights it is **day**. The Commander must **walk into every unlocked building** before the Control Room opens (START NIGHT shows `VISIT BUILDINGS 2/4`). Tapping a far building makes the Commander walk there.
- **Inside each building:** today's NASA lesson (2 sentences, honesty badge, source), a **chart drawn from the real numbers**, a **NASA photo slot**, and the building's upgrade. The lesson changes every day (39 lessons in `data/building_lessons.json`).
- **NASA photos:** `assets/sprites/info/nasa_<building>_<n>.png` (320x200). Each placeholder names the NASA image to use; NASA images are generally free to use with credit "NASA". Add each one to CREDITS.md.
- **Campaign:** the title has CONTINUE (latest night reached) and NEW GAME (Night 1). Picking any night is Judge Mode only (Judge Mode also skips the visit rule).

## Nights v2: never idle, always learning
- **3 stars every night:** SURVIVE (06:00) · SCIENCE (solve the Malfunction AND find the Discovery) · CHALLENGE (one per night, in `data/story.json`). Live strip under the clock.
- **Malfunction (camera detective):** the hanging scroll becomes the Malfunction board, with one Likelihood bar per cause. Clues show on cameras for 15 s (watch that camera to log them); some sensors are only "right N in 5 times". **SCAN** (2% battery, 20 s cooldown) reveals a room's clue, or "nothing unusual", which also lowers that room's causes. **DIAGNOSE** any time: right = solved; wrong = 3% battery and that cause is crossed off. While unsolved it drains a little extra power that grows every hour.
- **Tasks:** tapping a Problem opens a 10–20 s hands-on repair (`scripts/TaskGame.gd`): wires, dust, filter, airlock seal, pipes, door cracks, dish. Skill only; hazards just shorten the timer. Each ends with a real fact.
- **Radio facts** from Mission Control on the radio line, timed per night.
- **Story:** `data/story.json` (placeholder story beats). The writer fills `docs/STORY_TEMPLATE.md`; the integrator copies it into the JSON.
- Glossary of these terms: `CONTEXT.md`.

Judge Mode is a sandbox: nothing it does is written to the player's save.

## Swapping in final art and sound
- Every file on the Assets sheet already exists as a placeholder (191 files: art in `assets/sprites/<characters|desk|cameras|ui|hub|screens>/`, sounds in `assets/sfx/`, `icon.png`, `boot_splash.png`, `icon.ico`).
- To use a final: **overwrite the placeholder with the same file name and the same size** (sprite sheets: same frame size and count, frames in one row). Godot re-imports it; nothing else changes.
- `python3 tools/make_placeholders.py .` remakes missing placeholders and `data/assets.json`. It never overwrites an existing file unless you add `--force`.
- **Layout templates for artists** are in `assets/templates/` (made by `tools/make_layout_templates.py`): camera feed, base map, buildings/plots, title, night select, mission complete, UI frames and icons. Each shows exact sizes and the zones where code draws text or sprites. `*_1x.png` files are exact-size guides to draw on.
- 9-slice frames (ui_panel, ui_button, ui_popup, ui_briefing, ui_debrief, ui_codex_page, ui_nasa_panel, ui_certificate) keep a ~12 px border; the code stretches the middle.

## Build for the web / Windows
`export_presets.cfg` has **Web** (no threads, works on itch.io and GitHub Pages) and **Windows**. Install the 4.7.2 export templates, then Project → Export, or:
```
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . --export-release "Windows" build/windows/BulalakawStation.exe
```

## Tests
```
godot --headless --path . -s res://tests/test_sim.gd          # 21 balance checks, ALL PASSED
godot --headless --path . -s res://tests/smoke_debug.gd       # debug harness smoke test
godot --path . -s res://tests/desk_playtest.gd                # auto-plays Night 1 + 6 on the desk (needs a window)
godot --path . -s res://tests/flow_playtest.gd                # whole game flow + screenshots in user://
```

## Rules for the AI writing the next parts
- UI scripts **only** call `SimState.sim` action methods (`toggle_camera`, `set_heater`, `toggle_shelter_door`, `recall_crew`, `send_message`, …) and read its state (`battery`, `forecast_text()`, `crew`, …). Never put game rules in UI code.
- Listen to `SimState.sim.alert(text, kind)` for popups, `SimState.night_ended(report)` for the Debrief.
- New numbers go in `BalanceConfig.gd`; new text goes in `strings_en.json`; a new night is a new `NightConfig`.
- `OutpostSim` must stay free of autoloads and nodes so `tests/test_sim.gd` keeps working. Run the tests after every change to the simulation.

## Current balance (all plots at Level 1, from the tests)
- Night 1 default settings: survives with ~14% battery; 2 cameras + heater HIGH runs out.
- Night 5 (dust): default settings fail; heater LOW + dish off survives.
- Night 6: doing nothing fails on radiation; recall + shelter at the alarm survives with max dose ~3.7 chest X-rays.
- Nights 6–7 finish with only 2–5% battery at Level 1. That is intended: real players will have upgraded Solar or Battery by then.
