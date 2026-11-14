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

Judge Mode is a sandbox: nothing it does is written to the player's save.

## Swapping in final art and sound
- Every file on the Assets sheet already exists as a placeholder (191 files: art in `assets/sprites/<characters|desk|cameras|ui|hub|screens>/`, sounds in `assets/sfx/`, `icon.png`, `boot_splash.png`, `icon.ico`).
- To use a final: **overwrite the placeholder with the same file name and the same size** (sprite sheets: same frame size and count, frames in one row). Godot re-imports it; nothing else changes.
- `python3 tools/make_placeholders.py .` remakes missing placeholders and `data/assets.json`. It never overwrites an existing file unless you add `--force`.
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
