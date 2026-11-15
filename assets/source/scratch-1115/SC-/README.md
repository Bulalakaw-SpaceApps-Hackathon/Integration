# Bulalakaw Station screen art

Draft handoff · 2026-11-15

| Task | Files | Integration notes |
| --- | --- | --- |
| SC-07 | `ui_nasa_panel.png` | 96×96, 12 px slices. Dark interior for the existing light NASA Data text. |
| SC-08 | `screen_complete.png`, `ui_certificate.png` | 1280×720 Mars sunrise backdrop and 96×96 certificate source with 16 px slices. The layout stretches the certificate to about 820×380. Godot supplies the copy, star total, and buttons. |
| SC-09 | `ui_joystick_base.png`, `ui_joystick_knob.png` | Optional 128×128 base and 64×64 knob. |
| SC-10 | `font_main.ttf`, `font_main_bold.ttf` | Bulalakaw Readable Regular (400) and Bold (700). Verified every supplied symbol at 20 px in both weights. |
| SC-11 | `font_clock.ttf` | Optional DotGothic16 Regular. Verified the digits and colon at 32 px. |
| SC-12 | `ui_panel.png` | 96×96 source with 14 px slices, stretched to the panel size in Godot. |
| SC-13 | `ui_toggle_on.png`, `ui_toggle_off.png` | 64×32 art. Knob position and check/dash distinguish the states. Use the existing larger touch target. |
| SC-14 | `ui_codex_page.png` | 96×96 Codex source with 14 px slices. |
| SC-15 | `ui_panel.png` | Uses the SC-12 texture. |

The nine images are original pixel art using the project's FD-01 palette. The NASA Data panel has no insignia. The full-screen backdrop is opaque and the other eight PNGs have transparent corners or edges. Verified dimensions, palette membership, binary alpha, and flat centres and stretch-safe edges on all four 9-slice frames.

Bulalakaw Readable is derived from [Atkinson Hyperlegible Next](https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegiblenext) under the SIL Open Font License. The draft uses static 400 and 700 weights, adds a star and right arrow, and maps the micro sign to the existing Greek mu glyph. Its upstream notice is in `OFL-Atkinson.txt`. The clock uses unmodified [DotGothic16](https://github.com/google/fonts/tree/main/ofl/dotgothic16), with its notice in `OFL-DotGothic16.txt`.

The 96×96 sources follow `template_ui_frames.png`. The conversion preserved all fixed corner pixels and the plain texture centres. The completion backdrop follows `template_screen_complete.png`, with the sunrise to the left of the certificate area.

The Integration repo stayed clean. Godot import was attempted during the original draft, but the console launcher could not find the main executable. Next is an in-game layout check at 1280×720 with the draft fonts and frames.
