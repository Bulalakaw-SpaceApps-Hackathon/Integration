# Bulalakaw Station
A NASA Space Apps Challenge 2026 game by Team Bulalakaw (Polytechnic University of the Philippines).

# Game
- Design, code and art direction: Team Bulalakaw

# Art and sound
- SC screen and interface artwork: Team Bulalakaw, from the root of the team Assets repository's SC- group. Resized and adapted where needed for the game layout.
- CF-06 greenhouse camera: pixel-art redraw in tools/paint_rooms.py, based on Team Bulalakaw's greenhouse camera sketches in the team Assets repository.
- The Commander's outdoor EVA sprite adapts Team Bulalakaw's Carlo EVA walk cycle with cream and blue suit panels.
- BT-01 through BT-11 (29 button, control and attention PNGs): original Team Bulalakaw art from the team Assets repository, in the matching folders under `BT-/`. The game copies are in `assets/sprites/ui/`.
- Art by Team Bulalakaw: characters, camera feeds, base map, UI, alerts, sponsor ads and effects (sources in assets/source/).
- The team's scratch art (assets/source/) was remastered into the game's style with the tools in tools/: base-map buildings, decorations and ground (draw_flat, draw_feed_buildings, rescale_map, animate_deco), indoor camera feeds and markers (paint_rooms), night covers and the title backdrop (paint_night_cards, paint_title), desk and alert icons, badges, stars (draw_desk_icons, draw_alerts, draw_badges, draw_ui_small), crew portraits (remaster_portraits) and Mission Control (draw_mission_control).
- Used as made by the team: the CF-01 Sky Radar and CF-03 Solar Field feeds, the screen set (panel, codex page, NASA panel, certificate, toggles, joystick, ending backdrop), the task backgrounds, the sounds and the NASA photos.
- A few small UI pieces (codex pictures, sponsor logos, meters, battery bar) are still made by tools/make_placeholders.py and tools/make_dk*.py in the team palette.
- Sounds were chosen by the team's audio designer (Audio-Design pack, Set 1) and built with tools/import_audio.sh.
  - Kenney (www.kenney.nl), CC0: Interface Sounds / Digital Audio packs (sfx_click, sfx_camera, sfx_sunrise, sfx_evacuate, sfx_flare_alarm, sfx_msg_sent, sfx_msg_received, sfx_upgrade, sfx_star, sfx_materials, sfx_low_battery (reversed), sfx_dose_tick), Impact Sounds (sfx_thump), Sci-Fi Sounds (music_hub), footsteps (sfx_step_1..3).
  - "Sci-fi doors airlock sound effect" by ryankingart, Freesound 607265, CC0 (https://freesound.org/s/607265/): sfx_door_open and sfx_door_close, cut from one recording.
  - "Walkie-talkie beep" by SoundBiterSFX, Freesound 732209, CC0 (https://freesound.org/s/732209/): sfx_recall.
  - Wind loop (sfx_wind_loop) and radio noise loop (sfx_static_loop): OpenGameArt, CC0, per the team's source workbook. The exact page links still need to be added here before shipping.
- When a final asset or a CC0 download replaces a placeholder, add it here: asset ID, file name, author, source link, licence.

- Asset pack imported from Team Bulalakaw's Repo/Assets. It includes BT desk icons, CF camera art and effects, CH characters and portraits, HM map art, SP sponsor posters, and UI-20 radio planets. The NI lesson image credits are listed below.

# Fonts
- Silkscreen by Jason Kottke. SIL Open Font License 1.1 (assets/fonts/OFL.txt).
- Bulalakaw Readable (body text): derived by the team from Atkinson Hyperlegible Next (Braille Institute). SIL Open Font License 1.1 (assets/fonts/OFL-Atkinson.txt).
- DotGothic16 (clock) by Fontworks Inc. SIL Open Font License 1.1 (assets/fonts/OFL-DotGothic16.txt).

# NASA data
- NASA, "NASA Watches Mars Light Up During Epic Solar Storm" (June 2024): X12 flare on 2024-05-20, Curiosity RAD measured 8,100 microgray (about 30 chest X-rays).
- Zeitlin et al. (2018), Geophysical Research Letters 45(12): September 2017 solar particle event seen by Curiosity RAD.
- NASA JPL (2017): Large solar storm sparks global aurora and doubles radiation levels on the Martian surface.
- NASA Mars 2020: Perseverance landing signal delay of 11 min 22 s (2021-02-18).
- NASA DONKI Space Weather Database (api.nasa.gov), live solar flare list.
- Earth-Mars light times for 2018-06-10 and 2024-05-20 computed from planet positions.
- This game is not made or endorsed by NASA. It does not use the NASA logo.

# Godot Engine
- This game uses Godot Engine, available under the following license:
- Copyright (c) 2014-present Godot Engine contributors. Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.
- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
- Godot also includes third-party code: portions of this software are copyright (c) The FreeType Project (www.freetype.org), all rights reserved. ENet (MIT) and Mbed TLS (Apache 2.0) are also included. Full list: Godot's COPYRIGHT.txt.

# NASA lesson photos (NI-01..NI-07)
- `nasa_battery_1.png`: NASA — "P6 Truss, Photovoltaic (PV) Solar Array Wing (SAW)" (sts097-376-019), https://images.nasa.gov/details/sts097-376-019
- `nasa_battery_2.png`: NASA — "Taking Mars Temperature" (PIA16081), https://images.nasa.gov/details/PIA16081
- `nasa_battery_3.png`: NASA — "Mars Helicopter's Solar Array as Seen by Perseverance's Mastcam-Z" (PIA24545), https://images.nasa.gov/details/PIA24545
- `nasa_battery_4.png`: NASA — "Mars InSight Pre-Landing" (NHQ201811260004), https://images.nasa.gov/details/NHQ201811260004
- `nasa_battery_5.png`: NASA — "Shades of Martian Darkness" (PIA22521), https://images.nasa.gov/details/PIA22521
- `nasa_battery_6.png`: NASA — "Mars 2020's MMRTG" (PIA23306), https://images.nasa.gov/details/PIA23306
- `nasa_battery_7.png`: NASA — "Fission Surface Power" (GRC-2023-C-10425), https://images.nasa.gov/details/GRC-2023-C-10425
- `nasa_comms_dish_1.png`: NASA — "The Earth and Moon As Seen by 2001 Mars Odyssey Thermal Emission Imaging System" (PIA00559), https://images.nasa.gov/details/PIA00559
- `nasa_comms_dish_2.png`: NASA — "NASA's Deep Space Network Goldstone Complex" (PIA23214), https://images.nasa.gov/details/PIA23214
- `nasa_comms_dish_3.png`: NASA — "Artist Concept of Mars Reconnaissance Orbiter" (PIA04758), https://images.nasa.gov/details/PIA04758
- `nasa_comms_dish_4.png`: NASA — " Ingenuity's View of Sand Going Into Conjunction" (PIA26050), https://images.nasa.gov/details/PIA26050
- `nasa_greenhouse_1.png`: NASA — "Red Russian kale and Dragoon lettuce grow aboard the International Space Station for the ISSGardens investigation" (iss075e0227508), https://images.nasa.gov/details/iss075e0227508
- `nasa_greenhouse_2.png`: NASA — "Veggie System on International Space Station" (KSC-20170403-PH_AAG01_0001), https://images.nasa.gov/details/KSC-20170403-PH_AAG01_0001
- `nasa_greenhouse_3.png`: NASA — "Phoenix Robotic Arm Scoop with Rasp" (PIA10959), https://images.nasa.gov/details/PIA10959
- `nasa_greenhouse_4.png`: NASA — "Chile Peppers on ISS" (iss065e434041), https://images.nasa.gov/details/iss065e434041
- `nasa_greenhouse_5.png`: NASA — "Disappearing Ice" (PIA10906), https://images.nasa.gov/details/PIA10906
- `nasa_greenhouse_6.png`: NASA — "Aerogel Greenhouses for Mars?" (PIA23343), https://images.nasa.gov/details/PIA23343
- `nasa_life_support_1.png`: NASA — "Rocks Here Sequester Some of Mars Early Atmosphere" (PIA19817), https://images.nasa.gov/details/PIA19817
- `nasa_life_support_2.png`: NASA — "MOXIE All Tucked In" (PIA24203), https://images.nasa.gov/details/PIA24203
- `nasa_life_support_3.png`: NASA — "OGS Water ORU R&R" (iss020e033496), https://images.nasa.gov/details/iss020e033496
- `nasa_life_support_4.png`: NASA — "CDRA Valve RR" (iss037e021985), https://images.nasa.gov/details/iss037e021985
- `nasa_life_support_5.png`: NASA — "JEM Water Recovery System (JWRS) Gas Trap and Bypass Line Installation" (iss065e333421), https://images.nasa.gov/details/iss065e333421
- `nasa_life_support_6.png`: NASA — "Space Zinnias: Growing Seeds from Space" (KSC-20181127-PH_JBS01_0005), https://images.nasa.gov/details/KSC-20181127-PH_JBS01_0005
- `nasa_shelter_1.png`: NASA — "Spacecraft Single Event Environments at High Shielding Mass (HiMassSEE)" (iss032e016954), https://images.nasa.gov/details/iss032e016954
- `nasa_shelter_2.png`: NASA — "Sources of Ionizing Radiation in Interplanetary Space" (PIA16938), https://images.nasa.gov/details/PIA16938
- `nasa_shelter_3.png`: NASA — "Plausible Martian Habitats" (PIA14471), https://images.nasa.gov/details/PIA14471
- `nasa_shelter_4.png`: NASA — "Artemis II Orion Hardware" (KSC-20240223-PH-RNS01_0002), https://images.nasa.gov/details/KSC-20240223-PH-RNS01_0002
- `nasa_shelter_5.png`: NASA — "MAVEN Artist Concept" (PIA18811), https://images.nasa.gov/details/PIA18811
- `nasa_solar_1.png`: NASA — "Sunset in Mars Gale Crater" (PIA19400), https://images.nasa.gov/details/PIA19400
- `nasa_solar_2.png`: NASA — "InSight's First Selfie" (PIA22876), https://images.nasa.gov/details/PIA22876
- `nasa_solar_3.png`: NASA — "Mars Rover Opportunity at Rock Abrasion Target Potts" (PIA20285), https://images.nasa.gov/details/PIA20285
- `nasa_solar_4.png`: NASA — "Ingenuity Mars Helicopter's Record-Breaking Flight" (PIA25321), https://images.nasa.gov/details/PIA25321
- `nasa_solar_5.png`: NASA — "InSight's Power Generation: After Landing and Spring 2022" (PIA25284), https://images.nasa.gov/details/PIA25284
- `nasa_solar_6.png`: NASA — "Mars Climate Sounder Studies 2018 Dust Storm" (PIA22737), https://images.nasa.gov/details/PIA22737
- `nasa_suit_bay_1.png`: NASA — "NASA astronaut Scott Tingle wears a U.S. spacesuit" (iss054e022341), https://images.nasa.gov/details/iss054e022341
- `nasa_suit_bay_2.png`: NASA — "Spacesuit Materials on Perseverance's SHERLOC Calibration Target" (PIA24033), https://images.nasa.gov/details/PIA24033
- `nasa_suit_bay_3.png`: NASA — "Apollo 17 Lunar Surface Experiment: Lunar Ejecta and Meteorites Experiment" (S72-37257), https://images.nasa.gov/details/S72-37257
- `nasa_suit_bay_4.png`: NASA — "Astronaut Suni Williams during a spacewalk outside the International Space Station" (iss072e487421), https://images.nasa.gov/details/iss072e487421
