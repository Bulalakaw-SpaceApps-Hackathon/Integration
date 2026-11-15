# Bulalakaw Station status

## Hub and Camera Desk UI repair — 2026-11-15

- **Task IDs** B-01/B-02 and CH-06. The Commander and all four crewmates wear EVA suits on the surface. Clicking a plot opens its building information immediately. Upgrading applies the configured cost and raises the level. The existing building-visit requirement still gates the start of the night.
- **Changes** `scripts/hub/HubMap.gd` and `scripts/hub/Commander.gd` cover surface interaction, dialogs and suits. `scripts/DeskUI.gd` and `autoload/Game.gd` cover the desk help, radio, replies and mute control state. The asset manifest and credits register the Commander EVA sprite. `tests/hub_ui_smoke.gd` and `tests/hub_playtest.gd` cover direct plot selection.
- **Import and assets** Godot 4.7.2.stable reported a clean import with `--headless --editor --import --path .`. `--headless --path . -s res://tests/asset_check.gd` reported ALL PASSED.
- **Simulation** `--headless --path . -s res://tests/test_sim.gd` reported ALL PASSED (0 failed). Godot reported ObjectDB and resource cleanup diagnostics at exit.
- **Rendered playtest** `--path . --resolution 1280x720 -s res://tests/hub_ui_smoke.gd` passed 25 checks on Windows with the Compatibility renderer. Scripted mouse and keyboard input verified the briefing gate, the mute indicator, crew chat, plot opening and upgrade, Escape dismissal, Night 6 desk help pause/resume, and accepting a crew request while alerts were present. Reviewed screenshots of the hub, briefing, lesson, crew chat, desk help and reply.
- **Pending verification** A hands-on playthrough and browser/touch QA. Next test the Night 6 camera-to-reply and shelter sequence in the browser export.

## Camera Desk visual repair — 2026-11-15

- **Task IDs** DK-09 and CF-06. Acceptance was a readable crew dose panel at 1280 x 720, an unobstructed pair of camera feeds and visually distinct greenhouse lamp states.
- **Changes** `scripts/DeskUI.gd` widens and reorganizes the five stats pages, resizes the control captions and places Scan on each monitor frame. `autoload/Game.gd` moves desk notices below the camera buttons. `scripts/WindowView.gd` and `shaders/window_blend.gdshader` replace checkerboard sky transitions with a crossfade. The greenhouse PNGs, `tools/paint_rooms.py` and `CREDITS.md` contain the new greenhouse art and its source credit.
- **Verification** Godot 4.7.2.stable `--headless --editor --import --path .` completed without reported errors. `--headless --path . -s res://tests/asset_check.gd` and `--headless --path . -s res://tests/test_sim.gd` passed. The simulation reported its existing resource cleanup diagnostics on exit.
- **Rendered smoke** `--path . --resolution 1280x720 -s res://tests/hub_ui_smoke.gd` passed 42 checks. Visually reviewed the two active feeds, both greenhouse lamp states, crew stats and the flare windows. The new feed uses Team ALT-F4 sketches as the basis for a pixel-art redraw and retains the original runtime frame dimensions and lamp behavior.
- **Pending verification** Browser and touch layout. Next, run the two-camera and meter paging checks in the browser export.

## Shared asset handoff — 2026-11-15

- **Task ID** P-01. Compared the final game asset tree and manifest to the shared Assets repository.
- **Changed** Appended 241 missing or updated files to the shared repository, including 32 SC additions. `IN_GAME_HANDOFF.md` in the shared repository lists every copied file and its game source path.
- **Verified** SHA-256 matched every copy against its game original. All 266 manifest entries have matching content in their shared asset category. All 326 existing destination files retained their original contents. Godot `--headless --path . -s res://tests/asset_check.gd` reported ALL PASSED.
- **Scope and next task** Asset handoff only. The next browser and touch check remains listed above.

## SC screen asset compatibility — 2026-11-15

- **Task IDs** SC-01 and SC-08. Integrated the SC-01 logo at 600 x 200 after making its edge-connected white background transparent. Restored the missing SC-08 completion backdrop from SC- at 1280 x 720.
- **Changed files** `assets/sprites/screens/logo.png` and `assets/sprites/screens/screen_complete.png`.
- **Compatibility decisions** Kept the existing title backdrop because the candidate has baked control placeholders. Kept the animated night-card strips and the reusable lock overlay. The candidates have a different frame layout or embed a fixed Coming Soon label. Other SC assets resolve through their UI and font paths.
- **Verification** Godot 4.7.2.stable `--headless --editor --import --path .` exited 0. `--headless --path . -s res://tests/asset_check.gd` reported ALL PASSED. A rendered 1280 x 720 smoke opened the title, night select and completion screens and checked asset dimensions. Reviewed title and completion captures. Simulation behavior was outside this asset-only pass. Browser verification remains pending.

## Full SC art integration — 2026-11-15

- **Task IDs** SC-01 through SC-15. The SC artwork now comes from the root of the shared `SC-` folder, using the existing runtime paths for screens, UI and fonts. Preview and handoff files remain in the shared repo.
- **Changed** Screen and UI PNGs, font notices where different, `data/assets.json`, and the corresponding Title, Night Select, briefing and debrief layout scripts.
- **Adaptations** Added a menu surface over the title art's mock buttons. The supplied night covers are static, normalized to 240 x 160. Swapped the source mapping for Nights 4 and 5 so Hello Earth and Dust match the campaign order. Locked playable nights keep their own cover with a Locked label. Unfinished nights use the supplied Coming Soon cover. Used the supplied briefing as a nine-slice and the supplied debrief art as a heading icon. Added visible provenance text to the new badge art.
- **Verification** Godot 4.7.2.stable editor import and asset checks passed. The 1280 x 720 hub/desk smoke passed 42 checks. A separate rendered smoke opened Title, Night Select, Mission Complete, Hub Briefing and a synthetic failed-night debrief. Reviewed their screenshots. Browser and touch verification are pending.
