# Bulalakaw Station status

## Hub and Camera Desk UI repair — 2026-11-15

- **Task IDs** B-01/B-02 and CH-06. The Commander and all four crewmates wear EVA suits on the surface. Clicking a plot opens its building information immediately. Upgrading applies the configured cost and raises the level. The existing building-visit requirement still gates the start of the night.
- **Changes** `scripts/hub/HubMap.gd` and `scripts/hub/Commander.gd` cover surface interaction, dialogs and suits. `scripts/DeskUI.gd` and `autoload/Game.gd` cover the desk help, radio, replies and mute control state. The asset manifest and credits register the Commander EVA sprite. `tests/hub_ui_smoke.gd` and `tests/hub_playtest.gd` cover direct plot selection.
- **Import and assets** Godot 4.7.2.stable reported a clean import with `--headless --editor --import --path .`. `--headless --path . -s res://tests/asset_check.gd` reported ALL PASSED.
- **Simulation** `--headless --path . -s res://tests/test_sim.gd` reported ALL PASSED (0 failed). Godot reported ObjectDB and resource cleanup diagnostics at exit.
- **Rendered playtest** `--path . --resolution 1280x720 -s res://tests/hub_ui_smoke.gd` passed 25 checks on Windows with the Compatibility renderer. Scripted mouse and keyboard input verified the briefing gate, the mute indicator, crew chat, plot opening and upgrade, Escape dismissal, Night 6 desk help pause/resume, and accepting a crew request while alerts were present. Reviewed screenshots of the hub, briefing, lesson, crew chat, desk help and reply.
- **Pending verification** A hands-on playthrough and browser/touch QA. Next test the Night 6 camera-to-reply and shelter sequence in the browser export.
