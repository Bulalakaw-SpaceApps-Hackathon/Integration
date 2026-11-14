# Set 1 license review

Reviewed 2026-11-14 from the bundled source archives and the source spreadsheet.

## Confirmed from bundled `License.txt`

The following selected files come from Kenney packs whose embedded `License.txt` states Creative Commons Zero (CC0), usable in personal, educational, and commercial projects:

- `sfx_click.ogg`, `sfx_camera.ogg`, `sfx_sunrise.ogg`, `sfx_evacuate.ogg`, `sfx_flare_alarm.ogg`, `sfx_msg_sent.ogg`, `sfx_upgrade.ogg`, `sfx_star.ogg`, `sfx_dose_tick.ogg` — `kenney_interface-sounds.zip` or `kenney_digital-audio.zip`
- `sfx_thump.ogg` — `kenney_impact-sounds.zip`
- `music_hub.ogg` — `kenney_sci-fi-sounds.zip`

Kenney's license says credit is appreciated but not mandatory. The project rules still require listing assets on the Credits screen, so credit Kenney / www.kenney.nl.

## Source archive checks

- `sfx_wind_loop.m4a`: the bundled `wind.zip` contains Ogg and M4A wind files but no license/readme file. The source workbook records the OpenGameArt wind page as CC0; retain that provenance link and verify the exact page before shipping.
- `sfx_door_open_close_source.mp3`: source workbook identifies Freesound 607265 by ryankingart as CC0. The local directory has no license file for this MP3; retain the source URL and verify the page before shipping.
- `sfx_recall.wav`: source page for Freesound 732209 (SoundBiterSFX) was checked and displays CC0. Convert to Ogg before shipping.
- `sfx_static_loop.wav`: source workbook identifies OpenGameArt radio noise loop as CC0. No license file is bundled locally; retain the source URL and verify the exact page before shipping.

## Conclusion

Set 1 has confirmed CC0 evidence for the Kenney selections and a documented but externally sourced CC0 claim for the non-Kenney selections. Do not mark the whole set license-complete until the OpenGameArt and Freesound source pages are recorded in the project credits and the non-Ogg files are converted.
