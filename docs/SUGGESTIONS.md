# Suggestions queue (not built yet)

Collected from playtests. Nothing here is implemented until the batch is reviewed and agreed.

| # | Date | Suggestion | Notes / open questions |
|---|------|------------|------------------------|
| 1 | 2026-11-14 | **Sponsor ads stack up.** Every sponsor you accept keeps sending ads on later nights, so the more deals you take, the more pop-ups you get (like FNAF 6). | Open: do accepted sponsors stay for the rest of the run, or a few nights? Do rewards stack too (+3 each per night)? Max pop-ups on screen at once (currently 1)? Can you cancel a deal later? |

# Decisions (grill, 2026-11-14 night)

Agreed, not all built yet.

| # | Decision |
|---|----------|
| D1 | All 7 nights get polished, not only Nights 1-3. |
| D2 | Characters are converted to pixel art (from the hand-drawn sheets) everywhere: map sprites, portraits, head icons. |
| D3 | CH-01 Commander, CH-02 Lani (Engineer), CH-03 Maya (Botanist), CH-04 Mateo (Doctor), CH-05 Carlo (EVA). The five "mission control" portraits are neutral crew portraits. Mission Control is a faceless radio voice. |
| D4 | Characters appear: portraits on radio lines and crew requests; crew on camera feeds at night; crew by their buildings on the day map; worried/happy portraits on trouble and debrief. |
| D5 | Full 4-direction walk cycles, finalized in-house from the pose sheets. |
| D6 | The other five camera feeds are drawn in-house in the Sky Radar painted style. |
| D7 | Battery at zero ends the night early: 0 stars, kind try-again screen with one tip. Everything else only costs stars. |
| D8 | Audio: Set 1 is the base, gaps filled from Sets 2-3, licence lines in CREDITS. |
| D9 | Sponsor ads stack: an accepted sponsor stays 2 nights, rewards stack, max 2 ads on screen, no cancelling. |
| D10 | Story is written after the gameplay is final. NASA photo/fact pass also after gameplay. |
| D11 | English with Tagalog touches; no full translation. |
| D12 | Submission is Nov 15, 10 PM (Manila). A build is sent after every stage so there is always a submittable version. |
| D13 | Pixel character sizes: map/camera sprites 32x48 (4 directions x 4 frames), portraits 96x96, head icons 24x24. Chibi proportions. |
| D14 | Crew are shown on the camera feeds at night, walking between rooms; recall brings them through the Airlock to the Shelter; EVA suits outside; worried portrait when caught outside in a storm. |
| D15 | On the day map each crew member gives one spoken line per day that hints at tonight's malfunction. |
| D16 | One new thing per night as built; Night 7 adds a unique meteor-shower moment on the Sky Radar camera. |
| D17 | Retry after battery zero restarts the same night keeping upgrades and the sponsor deal; a second button goes back to base. |
| D18 | Stacked sponsor ads cover monitors only, never the control buttons. |
| D19 | New feeds: Airlock and Solar Field outside views; Shelter, Life Support, Greenhouse inside views with crew. Each has a simple hazard version (not too detailed). |
| D20 | Work order: fail screen + retry + sponsor stacking; night polish and balance; pixel characters; camera feeds; audio; story; NASA fact list. |
| D21 | One commit per stage; first commit saves the other chat's uncommitted work as is. |
| D22 | Difficulty: surviving is reachable for a 7-year-old on every night; 3 stars on Nights 5-7 takes a 12-year-old a couple of tries. |
| D23 | Day-map crew hints are always true on Nights 1-3; from Night 4 they can be an honest wrong guess. |
| D24 | BUG to fix: the true malfunction cause is always the first row of the board. The row order must be shuffled every night. |
| D25 | A crew member caught outside in a storm rests the next day (no hint from them). Nobody is hurt on screen. |
| D26 | Night 7 meteor shower at a fixed time: two meteors cause thump problems to fix; one landing spot on Sky Radar is the final discovery sent to Earth. |
| D27 | Each night's new thing gets one short guided prompt, skippable, shown once. |
| D28 | Ending on one screen: total stars, discoveries, a line from each crew member, the supply ship landing, Play again, and a "What was real?" list of NASA facts. |
| D29 | Judge Mode keeps the night picker and adds "Best of": Night 7 with a fully upgraded base. |
| D30 | Laptop first; touch works but no phone layouts. |
| D31 | "Night 0" tutorial, opened from a TUTORIAL button at the bottom right of the title menu: covers all buildings and everything needed to play. |
| D32 | Night 0 is a playable practice night with no score: a walk around the day map (every building unlocked and explained), then a practice night where nothing can fail and each control is tried once. |
| D33 | Night 1 becomes a normal easy night with light prompts only. Night 0 is offered to new players, never forced. |
| D34 | Finishing Night 0 gives no stars or materials, only a "Ready for duty!" badge on the title screen. |
| D35 | The desk fan is interactable. |
| D36 | Whenever the game is paused, the screen behind the popup is darkened. |
| D37 | The four sketch feeds (Airlock, Greenhouse, Life Support, Shelter) are repainted in the Solar Field (CF-03) painted pixel style, keeping each sketch's layout. Night palette for all. Sources: assets/source/feeds. |
| D38 | Map buildings redrawn to match their feeds: Solar Field (tilted blue panels on white frames), Life Support (big round wall fan, pipes), Greenhouse (purple grow lamps, plant rows), Shelter (yellow-black striped blast door), Suit Bay (round vault door with wheel, from the Airlock feed). Battery, Comms Dish, Control Room unchanged. Top-down 3/4 view, 3 levels each adding more of the same feature. |
| D39 | Dynamic feeds: Sky Radar glows in flares/particle storms, blips for crew outside, meteors on Night 7; Solar Field dusty in dust storms, darkens as charge drops; Airlock door opens while crew pass; Shelter door animates with the SHELTER button; Life Support fan speed follows Low/Mid/High and stops on empty battery; Greenhouse lamp on/off with CROP LAMP. All: dust haze overlay in dust storms, No Signal when off, crew walking through. |
| D40 | Use the team's 39 NASA photos (building lessons), 7 minigame backgrounds, alert and button icons (assets/source/assets-main). Every real photo gets a border and a "Credit: NASA" line; each photo's source goes in the fact-check list. |
| D41 | Automated hourly stages from 3:30 AM. If a run is cut short by the usage limit, the next run finishes it first and the schedule shifts. |
| D42 | "Final draft" = the complete gameplay without the storyline. The story is written later, after the final draft. |
| D43 | Push the project as it is (never add build/ or .godot/; leave the .exe and Audio-Design folder untouched). |
| D44 | Push once, at the final draft, to GitHub Bulalakaw-SpaceApps-Hackathon/Integration branch final-gameplay. |
| D45 | Merge the team's newer final-gameplay commits first; then open a PR final-gameplay -> main for the team to review (never merge it). Stop and ask on any conflict that touches someone else's work. |
| D46 | Asset zips sent during the runs go to assets/source/; the team's art always wins over mine, and each run's summary says what it replaced. |
| D47 | One art style per layer: camera feeds and night cover art are painted pixel art matching CF-03 (shaded, no outlines, no sketch lines); everything walked on or tapped (base map, crew, UI) is flat pixel art with a 1 px ink outline. Every sketchy or smooth piece (Airlock, Shelter, Life Support, Greenhouse, NO SIGNAL feeds) is remastered. |
| D48 | Everything in the team's zips is scratch art (a guide) and is redrawn to fit the game. Used as-is only: NASA photos, the sounds, the CF-01 Sky Radar and CF-03 Solar Field feeds, and any file named FINAL_ or called final. Replaces D46's "team art always wins" for art. |
| D49 | One pixel size on the base map: everything drawn at 2x. Buildings redrawn at about 96x96; debris, plots and the Control Room scaled to match. |
| D50 | Solar Field: a ground-anchored array filling its plot like the other buildings: panels on short white A-frame legs, ground shadow, gravel bed, cable trench. L1 one row, L2 two, L3 three plus an inverter shed. |
| D51 | Collision follows each sprite's real base; the Commander walks behind roofs and tall rocks (y-sort). Big rocks and debris are solid; small pebbles are flat ground decoration. A test bot walks the Commander around everything and fails on overlaps. |
| D52 | Night cover art: one painted scene per night (N1 sunset over the base, N2 glowing greenhouse, N3 radiation streaks over the dome, N4 dish with Earth as a bright star, N5 dust wall over the solar field, N6 white-hot Sun and aurora, N7 meteor shower) plus a matching locked card. Titles stay game text. |
| D53 | Replace all tool-made placeholders, in order: night cards and badges; desk icons, meters and stars; codex pictures and sponsor logos; everything else. |
| D54 | One locked game palette (the team colours already in the code, about 32). Every remastered piece uses only those colours. |
| D55 | Visual bug sweep includes the ARCHIVED badge in the menu; the user may send more. |
| D56 | Order: collision and pixel size on the base map; Solar Field and building remaster; night cover art; repaint sketchy feeds; placeholders by priority. Test, build and screenshot after each step; drop the later steps if time runs short. Work starts when the user sends the asset files. |
