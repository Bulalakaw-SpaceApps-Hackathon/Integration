# Fact check (stage E)

Every factual line the player can read, with where it is in the game, the source the game names, a page to check it against, and its status. Built from data/building_lessons.json, data/night_extras.json, data/nights, data/codex, data/story.json (radio lines) and data/strings_en.json. The storyline is not written yet (D42), so it is not here.

Links are NASA pages found while checking; an empty link means: search nasa.gov for the claim. **For the teammate checking this:** open each link, confirm the number, and change the status to `Verified (name)`. Rows marked **To verify** still need a NASA page.

## Fixed in this pass

- Night 3 and its radio line said the September 2017 storm raised radiation "2 to 3 times". NASA/JPL says **more than double** any earlier RAD reading. Changed. ([JPL 2017](https://www.jpl.nasa.gov/news/large-solar-storm-sparks-global-aurora-and-doubles-radiation-levels-on-the-martian-surface/))
- Night 7 radio line said space rocks hit Mars more often *because* of its thin air. The thin air means more of them **reach the ground**; reworded.
- Codex Dust: the "over 99% of direct sunlight" figure was not on a NASA page; reworded to NASA's own description (day turned almost into night). The tau 10.8 record it rests on is confirmed (PIA22930). Night 5's hazard line keeps "over 99%" because tau 10.8 means far less than 1% of direct sunlight gets through.
- Night 1 / Codex Batteries: "-80 C" softened to "colder than -70 C" where it was stated as a fixed number.
- Night 2: kept the 12 g/h figure; the 300 W figure moved out of the player text (it is still in the codex number, MOXIE draws about 300 W).
- Codex Food source: "CSA Food Production Toolkit" could not be found; source now NASA Veggie and NASA Phoenix.
- **NASA photo captions:** the caption under each photo was the *photo we wanted*, not the photo in the game. 30 captions now describe the actual NASA image. Lesson "Power without the Sun" showed a helicopter antenna; it now shows the MMRTG photo (PIA23306).

## Claims

| Where | Claim | Source named in game | NASA page | Status |
|---|---|---|---|---|
| Lesson solar 1 | SUNLIGHT ON MARS IS WEAKER: Mars is about 1.5 times farther from the Sun than Earth. So sunlight there is a bit less than half as strong as on Earth. | NASA Mars Exploration | [link](https://nssdc.gsfc.nasa.gov/planetary/factsheet/marsfact.html) | Checked: Mars gets about 43% of Earth's sunlight (589 vs 1361 W/m2) |
| Lesson solar 2 | NO POWER AT NIGHT: A day on Mars (a sol) lasts about 24 hours and 39 minutes. Solar panels only work while the Sun is up, so at night the base runs on batteries. | NASA Mars Facts | [link](https://science.nasa.gov/mars/facts/) | Checked: sol = 24 h 39 min 35 s |
| Lesson solar 3 | A ROVER THAT KEPT GOING: The solar-powered rover Opportunity was planned to work for 90 sols. It kept working for more than 5,000 sols, from 2004 to 2018! | NASA JPL | [link](https://science.nasa.gov/mission/mer-opportunity/) | Checked: planned 90 sols, last contact sol 5,111 (June 10, 2018) |
| Lesson solar 4 | A SOLAR HELICOPTER: NASA's Ingenuity helicopter charged its batteries with a small solar panel. It was planned for 5 flights and flew 72 times on Mars. | NASA JPL (2024) | [link](https://science.nasa.gov/mission/mars-2020-perseverance/ingenuity-mars-helicopter/) | Checked: 5 planned flights, 72 flown, mission ended Jan 2024 |
| Lesson solar 5 | DUST COVERS THE PANELS: The InSight lander had two round solar panels, each about 2.2 meters wide. Dust slowly covered them, and its mission ended in December 2022 when power ran low. | NASA JPL (2022) | [link](https://science.nasa.gov/mission/insight/) | Checked: panels about 2.2 m (7 ft) across; mission ended Dec 2022 |
| Lesson solar 6 | STORMS BLOCK THE SUN: In 2018 a dust storm covered all of Mars. The sky got so dark that the rover Opportunity could not charge, and NASA lost contact with it. | NASA JPL (2018-2019) | [link](https://svs.gsfc.nasa.gov/30983) | Checked: storm went planet-wide June 2018; Opportunity silent from June 10 |
| Lesson solar 7 | POWER WITHOUT THE SUN: Curiosity and Perseverance don't use solar panels. A nuclear power source turns heat into about 110 watts of electricity, day and night. | NASA Mars 2020 |  | Checked: MMRTG makes about 110 W |
| Lesson battery 1 | SAVING THE DAY FOR THE NIGHT: Batteries store energy from the solar panels during the day. At night the whole base uses that stored energy. | NASA Mars Exploration |  | OK (general) |
| Lesson battery 2 | COLD MARS NIGHTS: Nights on Mars often fall below minus 70 degrees Celsius. Batteries must be kept warm, and heating them uses energy too. | NASA Curiosity REMS (simplified) | [link](https://science.nasa.gov/mission/msl-curiosity/) | Checked: Gale Crater nights reach about -70 to -80 C (REMS) |
| Lesson battery 3 | ROVER BATTERIES: Perseverance carries two rechargeable lithium-ion batteries. They give extra power when the rover needs more than its power source makes. | NASA Mars 2020 |  | Checked: two lithium-ion batteries |
| Lesson battery 4 | EVERY WATT COUNTS: Mission teams plan each sol around the energy they have. In our base, these are the things that use the battery (game numbers). | Game balance (simplified) |  | Game numbers, marked as such |
| Lesson battery 5 | SLEEP MODE: When power gets very low, a rover can switch almost everything off and wait. Opportunity did this during the 2018 dust storm. | NASA JPL (2018) | [link](https://www.jpl.nasa.gov/news/opportunity-hunkers-down-during-dust-storm/) | Checked: Opportunity went into low-power fault mode in the 2018 storm |
| Lesson battery 6 | BATTERIES GET TIRED: Rechargeable batteries hold a little less energy as they get older. Engineers check battery health so they don't run out by surprise. | NASA (simplified) |  | OK (general) |
| Lesson battery 7 | POWER FOR FUTURE BASES: In 2018 NASA tested a small nuclear reactor called Kilopower. Reactors like it could power a base on the Moon or Mars, day and night. | NASA (2018) |  | Checked: KRUSTY/Kilopower test 2017-2018 in Nevada |
| Lesson life_support 1 | WHAT IS MARS AIR?: Mars air is about 95% carbon dioxide and is very thin. People cannot breathe it, so the base must make its own oxygen. | NASA Curiosity | [link](https://science.nasa.gov/mars/facts/) | Checked: about 95% CO2 |
| Lesson life_support 2 | MOXIE MADE OXYGEN: MOXIE, a machine on Perseverance, made oxygen from Mars air. From 2021 to 2023 it made 122 grams, up to 12 grams per hour. | NASA (2023) |  | Checked: 122 g total, up to 12 g/h, 2021-2023 (NASA statement, Sept 2023) |
| Lesson life_support 3 | HOW MUCH AIR DO WE NEED?: One astronaut uses about 0.84 kg of oxygen every day. That is much more than MOXIE made in its whole mission! | NASA (simplified) |  | To verify: 0.84 kg O2 per person per day (NASA life support baseline) |
| Lesson life_support 4 | CLEANING OUT CO2: We breathe out carbon dioxide, and too much makes people sleepy and gives headaches. Life support machines pull CO2 out of the air. | NASA (simplified) |  | OK (general) |
| Lesson life_support 5 | RECYCLING WATER: The space station recycles about 98% of its water, even from sweat and urine. A Mars base would have to recycle almost everything too. | NASA (2023) |  | Checked: ISS reached 98% water recovery in 2023 |
| Lesson life_support 6 | PLANTS HELP BREATHE: Plants take in carbon dioxide and give out oxygen. Future bases may use greenhouses as part of their life support. | NASA (simplified) |  | OK (general) |
| Lesson greenhouse 1 | SALAD IN SPACE: In 2015 astronauts on the space station ate red romaine lettuce they grew themselves. The plant chamber is called Veggie. | NASA (2015) |  | Checked: crew ate Veggie red romaine, Aug 2015 |
| Lesson greenhouse 2 | LIGHTS FOR PLANTS: Space greenhouses use LED lights, mostly red and blue, instead of sunlight. Lights use power, just like our Crop Lamp. | NASA Veggie |  | OK: Veggie uses red/blue (plus green) LEDs |
| Lesson greenhouse 3 | SALTY MARS SOIL: In 2008 the Phoenix lander found perchlorate in Mars soil, about half a percent. It is bad for people and plants, so soil must be cleaned first. | NASA Phoenix (2008) | [link](https://science.nasa.gov/mission/phoenix/) | Checked: Phoenix found about 0.4-0.6% perchlorate |
| Lesson greenhouse 4 | HOT PEPPERS IN ORBIT: In 2021 astronauts grew chile peppers on the space station. Peppers took about four months to grow. | NASA (2021) |  | Checked: planted July 2021, harvested Oct-Nov 2021 (about 4 months) |
| Lesson greenhouse 5 | WATER FROM ICE: Mars has water ice at its poles and under the ground. In 2008 the Phoenix lander dug up ice just under the soil. | NASA Phoenix (2008) | [link](https://science.nasa.gov/mission/phoenix/) | Checked: Phoenix 'Dodo-Goldilocks' trench ice sublimated, 2008 |
| Lesson greenhouse 6 | FOOD FOR A LONG TRIP: A trip to Mars and back could take years. Growing some food on Mars would mean carrying less from Earth. | NASA (simplified) |  | OK (general) |
| Lesson shelter 1 | WHAT IS SHIELDING?: Shielding means putting material between people and radiation. Materials full of hydrogen, like water and plastic, block particles well. | NASA (simplified) |  | OK (general, NASA shielding research) |
| Lesson shelter 2 | RADIATION EVERY DAY: Curiosity measures about 210 microgray of radiation on a normal day on Mars. On 2024-05-20 a solar storm gave 8,100 in one go! | NASA Curiosity RAD | [link](https://ntrs.nasa.gov/citations/20180007641) | Checked: 0.21 mGy/day average (Hassler et al. 2014, Science); 8,100 uGy on 2024-05-20 |
| Lesson shelter 3 | HIDING UNDER MARS SOIL: A thick layer of Mars soil or rock above a base would block most particles. Caves or buried rooms could make good shelters. | NASA (simplified) |  | OK (general) |
| Lesson shelter 4 | A SHELTER MADE OF BAGS: In NASA's Orion spaceship, astronauts can build a storm shelter from their supply bags. More stuff around you means more shielding. | NASA Orion |  | To verify: Orion crew storm shelter built from stowage bags |
| Lesson shelter 5 | NO MAGNETIC SHIELD: Earth's magnetic field and thick air protect us from solar particles. Mars lost its global magnetic field long ago, so its ground gets much more radiation. | NASA MAVEN | [link](https://science.nasa.gov/mission/maven/) | OK: Mars lost its global field billions of years ago (MAVEN) |
| Lesson suit_bay 1 | A SPACESUIT IS A TINY SPACESHIP: A spacesuit gives air to breathe, keeps the right pressure, and keeps the astronaut warm or cool. Outside, it is all that keeps them alive. | NASA |  | OK (general) |
| Lesson suit_bay 2 | TESTING SUITS ON MARS: Perseverance carries five small samples of spacesuit material. Scientists watch how Mars sunlight and dust change them. | NASA Mars 2020 |  | Checked: five spacesuit material samples on SHERLOC target |
| Lesson suit_bay 3 | STICKY, SHARP DUST: Moon dust stuck to Apollo astronauts' suits and wore them down. Mars dust is also fine and sticky, so suits must be cleaned. | NASA Apollo |  | OK: Apollo dust problems are well documented |
| Lesson suit_bay 4 | HOW LONG IS A SPACEWALK?: Spacewalks outside the space station usually last about 6 and a half hours. On Mars, crews must get back fast when danger comes. | NASA |  | OK: ISS spacewalks typically about 6.5 h |
| Lesson comms_dish 1 | MESSAGES TAKE MINUTES: Radio waves travel at the speed of light, but Mars is far away. A message takes between about 3 and 22 minutes to arrive, depending on where the planets are. | NASA | [link](https://science.nasa.gov/mars/facts/) | Checked: one-way light time about 3 to 22 min |
| Lesson comms_dish 2 | GIANT EARS ON EARTH: NASA's Deep Space Network has three big antenna sites: California, Spain and Australia. As Earth spins, one of them can always hear Mars. | NASA DSN |  | Checked: Goldstone, Madrid, Canberra |
| Lesson comms_dish 3 | ORBITERS PASS IT ON: Rovers send most of their data to spacecraft circling Mars, like the Mars Reconnaissance Orbiter. The orbiters send it on to Earth. | NASA JPL |  | OK: most rover data relayed by orbiters |
| Lesson comms_dish 4 | WHEN THE SUN IS IN THE WAY: About every two years the Sun sits between Earth and Mars. Mission teams stop sending commands for about two weeks until it moves. | NASA | [link](https://science.nasa.gov/mars/) | Checked: conjunction every ~2 years, ~2 week command pause |
| Discovery Night 1 | FROST ON THE GROUND: Thin water-ice frost forms on Mars on cold nights. NASA's Viking 2 lander photographed frost on the ground in 1979. | NASA Viking 2 |  | Checked: Viking Lander 2 frost images, 1979 |
| Discovery Night 2 | WATER HIDING IN SOIL: Mars soil holds water locked inside its minerals. Curiosity's first soil sample in 2012 was about 2% water. | NASA Curiosity (2013) |  | Checked: about 2% water by weight (Leshin et al. 2013, Science) |
| Discovery Night 3 | A RADIATION RECORD: Curiosity's RAD instrument has measured radiation on the ground of Mars since 2012. That helps plan how to protect astronauts. | NASA Curiosity RAD | [link](https://ntrs.nasa.gov/citations/20180007641) | Checked: RAD on the surface since Aug 2012 |
| Discovery Night 4 | A ROCK FROM AN OLD LAKE: Curiosity found rocks that formed in an ancient lake in Gale Crater. Long ago, water stayed on Mars for a long time. | NASA Curiosity (2013) | [link](https://science.nasa.gov/mission/msl-curiosity/) | Checked: Gale Crater ancient lake (Yellowknife Bay, 2013) |
| Discovery Night 5 | A DUST DEVIL: Whirlwinds called dust devils cross Mars. Sometimes they blew dust off rover solar panels and gave them more power. | NASA Spirit and Opportunity | [link](https://science.nasa.gov/mission/mer-opportunity/) | Checked: dust devils cleaned Spirit/Opportunity panels |
| Discovery Night 6 | AURORA OVER MARS: During the May 2024 solar storm, NASA's MAVEN orbiter saw auroras glowing across Mars. Mars has auroras even without a global magnetic field. | NASA MAVEN (2024) |  | Checked: MAVEN saw auroras in the May 2024 storm |
| Discovery Night 7 | A BULALAKAW LANDED!: Space rocks reach the ground on Mars more easily than on Earth because the air is so thin. NASA's InSight lander felt meteoroid impacts as marsquakes, and orbiters found the fresh craters. | NASA InSight (2022) | [link](https://science.nasa.gov/mission/insight/) | Checked: InSight felt impacts; craters confirmed by MRO (2022-2023) |
| Night 1 did_you_know | A day on Mars, called a sol, is 24 hours and 39 minutes long—and Curiosity's REMS weather station measures nights colder than -70 C. | see night |  | Checked (see notes) |
| Night 1 hazard line | Outside temperatures are plunging toward -80 C! Mars's thin air can't hold heat, so the heater works harder. |  |  | Checked (see notes) |
| Night 2 did_you_know | NASA's MOXIE on Perseverance used electricity to turn Mars CO2 into fresh oxygen, up to 12 grams per hour. | see night |  | Checked (see notes) |
| Night 2 hazard line | Outside temperatures are plunging toward -80 C! Mars's thin air can't hold heat, so the heater works harder. |  |  | Checked (see notes) |
| Night 2 hazard line | The fan is slowing and CO2 is building up! Turning up Life Support makes oxygen, just like NASA's MOXIE experiment. |  |  | Checked (see notes) |
| Night 3 did_you_know | In September 2017, a solar storm pushed radiation on the ground of Mars to more than double anything Curiosity had measured before. | see night |  | Checked (see notes) |
| Night 3 real_date | 2017-09-10 | see night |  | Checked (see notes) |
| Night 3 real_date | 2017-09-10 | see night |  | Checked (see notes) |
| Night 3 hazard line | Outside temperatures are plunging toward -80 C! Mars's thin air can't hold heat, so the heater works harder. |  |  | Checked (see notes) |
| Night 4 did_you_know | When Perseverance landed in 2021, its signal took 11 minutes and 22 seconds to reach Earth, so it had to land itself. | see night |  | Checked (see notes) |
| Night 4 real_date | 2021-02-18 | see night |  | Checked (see notes) |
| Night 4 hazard line | Outside temperatures are plunging toward -80 C! Mars's thin air can't hold heat, so the heater works harder. |  |  | Checked (see notes) |
| Night 4 hazard line | Static on the radio! Even at the speed of light, signals take 11 minutes 22 seconds to reach Earth. |  |  | Checked (see notes) |
| Night 5 did_you_know | In 2018 a dust storm covered all of Mars for weeks. | see night |  | Checked (see notes) |
| Night 5 real_date | 2018-06-10 | see night |  | Checked (see notes) |
| Night 5 hazard line | Global dust blocked over 99% of direct sunlight—just like the 2018 storm—so the battery starts lower tonight. |  |  | Checked (see notes) |
| Night 5 hazard line | Outside temperatures are plunging toward -80 C! Mars's thin air can't hold heat, so the heater works harder. |  |  | Checked (see notes) |
| Night 6 did_you_know | Someone standing next to Curiosity on May 20, 2024 would have received a dose like 30 chest X-rays. | see night |  | Checked (see notes) |
| Night 6 real_date | 2024-05-20 | see night |  | Checked (see notes) |
| Night 6 real_date | 2024-05-20 | see night |  | Checked (see notes) |
| Night 6 hazard line | Outside temperatures are plunging toward -80 C! Mars's thin air can't hold heat, so the heater works harder. |  |  | Checked (see notes) |
| Night 7 did_you_know | This night combines two real events: the 2018 global dust storm and the May 2024 solar flare. | see night |  | Checked (see notes) |
| Night 7 real_date | 2018-06-10 | see night |  | Checked (see notes) |
| Night 7 real_date | 2024-05-20 | see night |  | Checked (see notes) |
| Night 7 real_date | 2024-05-20 | see night |  | Checked (see notes) |
| Night 7 hazard line | Outside temperatures are plunging toward -80 C! Mars's thin air can't hold heat, so the heater works harder. |  |  | Checked (see notes) |
| Codex battery_solar | BATTERIES AND SOLAR POWER: Solar panels only make power while the Sun is up. At night, when Mars drops below -70 C, the base runs on energy stored in its batteries. [Gale Crater nights: -20 C down to -80 C] | NASA Mars Science Laboratory (Curiosity REMS) |  | Checked (see notes) |
| Codex co2_oxygen | AIR: CO2 AND OXYGEN: Mars air is 95% carbon dioxide, which people cannot breathe. NASA's MOXIE experiment on Perseverance turned that CO2 into fresh oxygen using electric power. [~12 g oxygen/hour using ~300 W] | NASA Mars 2020 (Perseverance MOXIE) |  | Checked (see notes) |
| Codex comms_delay | TALKING TO EARTH: Radio signals take minutes to travel between Mars and Earth. When Perseverance landed on 2021-02-18, its signal took 11 minutes 22 seconds, so it had to land by itself. [11 min 22 s (2021-02-18)] | NASA Mars 2020 |  | Checked (see notes) |
| Codex dust | DUST STORMS: Mars has dust storms that can cover the whole planet for weeks. In June 2018 a planet-wide storm blocked so much sunlight that day turned almost into night for the solar-powered Opportunity rover, and its mission ended. [June 2018 global storm: opacity tau > 10.8] | NASA JPL (Opportunity / Mars Reconnaissance Orbiter) |  | Checked (see notes) |
| Codex food | GROWING FOOD ON MARS: Space greenhouses need grow lights, water, and warmth, and on Mars all three cost battery power. Martian soil also has perchlorate salts, so astronauts grow crops indoors. [Continuous LED photoperiods + thermal control] | NASA Veggie & NASA Phoenix (2008) |  | Checked (see notes) |
| Codex radiation | RADIATION: Mars has thin air and no global magnetic field, so space radiation reaches the ground. NASA's Curiosity RAD and OSDR RadLab track how much dose astronauts and rovers absorb. [2024-05-20: 8,100 µGy (~30 chest X-rays)] | NASA Curiosity RAD & OSDR RadLab |  | Checked (see notes) |
| Codex shelter_shielding | SHELTER AND SHIELDING: Shielding means putting thick material between people and radiation. A shelter with thick walls lets far fewer particles reach the crew. [Game shelter cuts dose to 20% (L1) down to 5% (L3)] | NASA OSDR RadLab & radiation shielding research (simplified) |  | Checked (see notes) |
| Codex sol | A DAY ON MARS: THE SOL: A day on Mars is called a sol, and it is slightly longer than an Earth day. Mission teams on Earth shift their clocks to live on Mars time. [24 hours, 39 minutes, 35 seconds] | NASA Mars Exploration / Curiosity REMS |  | Checked (see notes) |
| Codex solar_flare | SOLAR FLARES: A solar flare is a sudden burst of energy from the Sun tracked by NASA DONKI. Its X-rays arrive first at light speed, while energetic particles arrive minutes later. [2024-05-20: estimated X12 flare] | NASA DONKI & MAVEN (June 2024) |  | Checked (see notes) |
| Radio Night 1 | A day on Mars is called a sol. It lasts 24 hours and 39 minutes. |  |  | Checked (same facts as above) |
| Radio Night 1 | Sunlight on Mars is less than half as strong as on Earth. |  |  | Checked (same facts as above) |
| Radio Night 1 | Rovers plan every sol around how much energy they have. |  |  | Checked (same facts as above) |
| Radio Night 2 | Mars air is about 95% carbon dioxide. |  |  | Checked (same facts as above) |
| Radio Night 2 | NASA's MOXIE made oxygen from Mars air: 122 grams in total. |  |  | Checked (same facts as above) |
| Radio Night 2 | Plants need light, water and warmth. |  |  | Checked (same facts as above) |
| Radio Night 3 | Radiation is invisible, so we measure it with dosimeters. |  |  | Checked (same facts as above) |
| Radio Night 3 | In September 2017, Curiosity measured radiation more than double its old record. |  |  | Checked (same facts as above) |
| Radio Night 3 | Water and plastic are good shielding because they contain lots of hydrogen. |  |  | Checked (same facts as above) |
| Radio Night 4 | Radio signals take 3 to 22 minutes to travel between Mars and Earth. |  |  | Checked (same facts as above) |
| Radio Night 4 | NASA's Deep Space Network listens from California, Spain and Australia. |  |  | Checked (same facts as above) |
| Radio Night 4 | When Perseverance landed in 2021, its signal took 11 minutes 22 seconds. |  |  | Checked (same facts as above) |
| Radio Night 5 | In 2018 a dust storm covered all of Mars. |  |  | Checked (same facts as above) |
| Radio Night 5 | Dust devils sometimes cleaned rover solar panels! |  |  | Checked (same facts as above) |
| Radio Night 5 | The Opportunity rover worked for more than 5,000 sols. |  |  | Checked (same facts as above) |
| Radio Night 6 | This is a real event: an X12 flare hit Mars on May 20, 2024. |  |  | Checked (same facts as above) |
| Radio Night 6 | Curiosity measured 8,100 microgray that day, about 30 chest X-rays. |  |  | Checked (same facts as above) |
| Radio Night 6 | NASA's MAVEN saw auroras glow over Mars during that storm. |  |  | Checked (same facts as above) |
| Radio Night 7 | Tonight combines two real events: the 2018 dust storm and the 2024 flare. |  |  | Checked (same facts as above) |
| Radio Night 7 | More space rocks reach the ground on Mars, because its thin air burns up fewer of them. |  |  | Checked (same facts as above) |
| Radio Night 7 | Send it now: a message takes minutes to reach Earth! |  |  | Checked (same facts as above) |
| Task/desk fact fan.fact | Fun fact: on the space station fans never stop. Without them, the air you breathe out would just hang around your head! |  |  | OK |
| Task/desk fact task.loose_cable.fact | Space plugs have a key, so they only fit one way. No wrong plugs on Mars! |  |  | To verify |
| Task/desk fact task.panel_dust.fact | Dust storms coat everything on Mars. Opportunity's panels got cleaner thanks to wind! |  |  | OK |
| Task/desk fact task.clogged_filter.fact | MOXIE on the Perseverance rover really made oxygen from Mars's CO2 air, at 800 C! |  |  | OK |
| Task/desk fact task.airlock_leak.fact | Air pushes out into Mars's thin air. Astronauts find leaks by watching dust drift. |  |  | To verify |
| Task/desk fact task.greenhouse_leak.fact | Water is precious on Mars. The space station recycles about 98% of its water! |  |  | OK |
| Task/desk fact task.shelter_seal.fact | Piling Mars dirt (regolith) on a shelter blocks space radiation. |  |  | OK |
| Task/desk fact task.dish_drift.fact | From Mars, Earth looks like a bright evening star. Curiosity took a photo of it! |  |  | OK |

## NASA photos (Building Info cards)

Each photo shows a "REAL PHOTO … · CREDIT: NASA" label in a frame (D40). Source of every file:

| File | Lesson | Caption shown | NASA title (ID) | Link |
|---|---|---|---|---|
| nasa_solar_1.png | SUNLIGHT ON MARS IS WEAKER | NASA photo of a sunset on Mars (Curiosity or Spirit) | Sunset in Mars Gale Crater (PIA19400) | [images.nasa.gov](https://images.nasa.gov/details/PIA19400) |
| nasa_solar_2.png | NO POWER AT NIGHT | NASA photo of a solar-powered lander's panels (InSight) | InSight's First Selfie (PIA22876) | [images.nasa.gov](https://images.nasa.gov/details/PIA22876) |
| nasa_solar_3.png | A ROVER THAT KEPT GOING | NASA image of the Opportunity rover | Mars Rover Opportunity at Rock Abrasion Target Potts (PIA20285) | [images.nasa.gov](https://images.nasa.gov/details/PIA20285) |
| nasa_solar_4.png | A SOLAR HELICOPTER | NASA photo of the Ingenuity helicopter on Mars | Ingenuity Mars Helicopter's Record-Breaking Flight (PIA25321) | [images.nasa.gov](https://images.nasa.gov/details/PIA25321) |
| nasa_solar_5.png | DUST COVERS THE PANELS | NASA images of InSight's power falling as dust covered its panels | InSight's Power Generation: After Landing and Spring 2022 (PIA25284) | [images.nasa.gov](https://images.nasa.gov/details/PIA25284) |
| nasa_solar_6.png | STORMS BLOCK THE SUN | NASA Mars Climate Sounder view of the 2018 dust storm | Mars Climate Sounder Studies 2018 Dust Storm (PIA22737) | [images.nasa.gov](https://images.nasa.gov/details/PIA22737) |
| nasa_solar_7.png | POWER WITHOUT THE SUN | NASA photo of Perseverance's nuclear power source (MMRTG) | Mars 2020's MMRTG (PIA23306) | [images.nasa.gov](https://images.nasa.gov/details/PIA23306) |
| nasa_battery_1.png | SAVING THE DAY FOR THE NIGHT | NASA Mars rover concept vehicle | Mars Rover Concept Vehicle (KSC-20170605-PH_KLS01_0135) | [images.nasa.gov](https://images.nasa.gov/details/KSC-20170605-PH_KLS01_0135) |
| nasa_battery_2.png | COLD MARS NIGHTS | NASA image of Curiosity's weather station (REMS) | Taking Mars Temperature (PIA16081) | [images.nasa.gov](https://images.nasa.gov/details/PIA16081) |
| nasa_battery_3.png | ROVER BATTERIES | NASA photo of the Perseverance rover's wheels | Mars 2020 Perseverance Rover Wheels (KSC-20200402-PH-JPL01_0002) | [images.nasa.gov](https://images.nasa.gov/details/KSC-20200402-PH-JPL01_0002) |
| nasa_battery_4.png | EVERY WATT COUNTS | NASA photo of engineers testing a rover drill | Testing New Techniques for Mars Rover Rock-Drilling (PIA22061) | [images.nasa.gov](https://images.nasa.gov/details/PIA22061) |
| nasa_battery_5.png | SLEEP MODE | NASA images of the Sun dimming over Opportunity in the 2018 storm | Shades of Martian Darkness (PIA22521) | [images.nasa.gov](https://images.nasa.gov/details/PIA22521) |
| nasa_battery_6.png | BATTERIES GET TIRED | NASA photo of Perseverance's nuclear power source (MMRTG) | Mars 2020's MMRTG (PIA23306) | [images.nasa.gov](https://images.nasa.gov/details/PIA23306) |
| nasa_battery_7.png | POWER FOR FUTURE BASES | NASA concept of a fission power system for the Moon | Fission Surface Power (GRC-2023-C-10425) | [images.nasa.gov](https://images.nasa.gov/details/GRC-2023-C-10425) |
| nasa_life_support_1.png | WHAT IS MARS AIR? | NASA image of rocks that hold some of Mars's early air | Rocks Here Sequester Some of Mars Early Atmosphere (PIA19817) | [images.nasa.gov](https://images.nasa.gov/details/PIA19817) |
| nasa_life_support_2.png | MOXIE MADE OXYGEN | NASA photo of MOXIE being put into Perseverance | MOXIE All Tucked In (PIA24203) | [images.nasa.gov](https://images.nasa.gov/details/PIA24203) |
| nasa_life_support_3.png | HOW MUCH AIR DO WE NEED? | NASA photo of the International Space Station | International Space Station (ISS) (0100909) | [images.nasa.gov](https://images.nasa.gov/details/0100909) |
| nasa_life_support_4.png | CLEANING OUT CO2 | NASA photo of the space station's CO2 removal system (CDRA) | CDRA Valve RR (iss037e021985) | [images.nasa.gov](https://images.nasa.gov/details/iss037e021985) |
| nasa_life_support_5.png | RECYCLING WATER | NASA photo of the International Space Station | International Space Station (ISS) (0102168) | [images.nasa.gov](https://images.nasa.gov/details/0102168) |
| nasa_life_support_6.png | PLANTS HELP BREATHE | NASA photo of zinnias grown on the space station | Space Zinnias: Growing Seeds from Space (KSC-20181127-PH_JBS01_0005) | [images.nasa.gov](https://images.nasa.gov/details/KSC-20181127-PH_JBS01_0005) |
| nasa_greenhouse_1.png | SALAD IN SPACE | NASA photo of kale and lettuce growing on the space station | Red Russian kale and Dragoon lettuce grow aboard the International Space Station for the ISSGardens investigation (iss075e0227508) | [images.nasa.gov](https://images.nasa.gov/details/iss075e0227508) |
| nasa_greenhouse_2.png | LIGHTS FOR PLANTS | NASA photo of the Veggie plant chamber on the space station | Veggie System on International Space Station (KSC-20170403-PH_AAG01_0001) | [images.nasa.gov](https://images.nasa.gov/details/KSC-20170403-PH_AAG01_0001) |
| nasa_greenhouse_3.png | SALTY MARS SOIL | NASA photo of Phoenix lander's scoop and soil | Phoenix Robotic Arm Scoop with Rasp (PIA10959) | [images.nasa.gov](https://images.nasa.gov/details/PIA10959) |
| nasa_greenhouse_4.png | HOT PEPPERS IN ORBIT | NASA photo of chile peppers growing on the space station | Chile Peppers on ISS (iss065e434041) | [images.nasa.gov](https://images.nasa.gov/details/iss065e434041) |
| nasa_greenhouse_5.png | WATER FROM ICE | NASA Phoenix images of ice vanishing from a trench | Disappearing Ice (PIA10906) | [images.nasa.gov](https://images.nasa.gov/details/PIA10906) |
| nasa_greenhouse_6.png | FOOD FOR A LONG TRIP | NASA concept art of greenhouses for Mars | Aerogel Greenhouses for Mars? (PIA23343) | [images.nasa.gov](https://images.nasa.gov/details/PIA23343) |
| nasa_shelter_1.png | WHAT IS SHIELDING? | NASA photo from the International Space Station | iss053e238891 (iss053e238891) | [images.nasa.gov](https://images.nasa.gov/details/iss053e238891) |
| nasa_shelter_2.png | RADIATION EVERY DAY | NASA graphic of the sources of radiation in space | Sources of Ionizing Radiation in Interplanetary Space (PIA16938) | [images.nasa.gov](https://images.nasa.gov/details/PIA16938) |
| nasa_shelter_3.png | HIDING UNDER MARS SOIL | NASA concept art of possible Mars habitats | Plausible Martian Habitats (PIA14471) | [images.nasa.gov](https://images.nasa.gov/details/PIA14471) |
| nasa_shelter_4.png | A SHELTER MADE OF BAGS | NASA photo from the Orion radiation shielding student challenge | Exploration Design Challenge 2014 (201404250020HQ) | [images.nasa.gov](https://images.nasa.gov/details/201404250020HQ) |
| nasa_shelter_5.png | NO MAGNETIC SHIELD | NASA photo from Kennedy Space Center (2013) | KSC-2013-3598 (KSC-2013-3598) | [images.nasa.gov](https://images.nasa.gov/details/KSC-2013-3598) |
| nasa_suit_bay_1.png | A SPACESUIT IS A TINY SPACESHIP | NASA photo of an astronaut in a spacesuit | NASA astronaut Scott Tingle wears a U.S. spacesuit (iss054e022341) | [images.nasa.gov](https://images.nasa.gov/details/iss054e022341) |
| nasa_suit_bay_2.png | TESTING SUITS ON MARS | NASA image of the SHERLOC calibration target with suit samples | Spacesuit Materials on Perseverance's SHERLOC Calibration Target (PIA24033) | [images.nasa.gov](https://images.nasa.gov/details/PIA24033) |
| nasa_suit_bay_3.png | STICKY, SHARP DUST | NASA photo of Apollo astronauts at the 40th anniversary | Apollo 40th Anniversary Press Conference (200907200100HQ) | [images.nasa.gov](https://images.nasa.gov/details/200907200100HQ) |
| nasa_suit_bay_4.png | HOW LONG IS A SPACEWALK? | NASA astronaut portrait | NASA astronaut Jonny Kim (jsc2024e066574) | [images.nasa.gov](https://images.nasa.gov/details/jsc2024e066574) |
| nasa_comms_dish_1.png | MESSAGES TAKE MINUTES | NASA image comparing the land of Mars and Earth | MGS Mars Orbiter Laser Altimeter MOLA - Mars/Earth Relief Comparison (PIA00960) | [images.nasa.gov](https://images.nasa.gov/details/PIA00960) |
| nasa_comms_dish_2.png | GIANT EARS ON EARTH | NASA photo of the Deep Space Network at Goldstone | NASA's Deep Space Network Goldstone Complex (PIA23214) | [images.nasa.gov](https://images.nasa.gov/details/PIA23214) |
| nasa_comms_dish_3.png | ORBITERS PASS IT ON | NASA artist concept of the Mars Reconnaissance Orbiter | Artist Concept of Mars Reconnaissance Orbiter (PIA04758) | [images.nasa.gov](https://images.nasa.gov/details/PIA04758) |
| nasa_comms_dish_4.png | WHEN THE SUN IS IN THE WAY | NASA photo Ingenuity took as Mars went into solar conjunction | Ingenuity's View of Sand Going Into Conjunction (PIA26050) | [images.nasa.gov](https://images.nasa.gov/details/PIA26050) |

Photos that only loosely fit their lesson (worth swapping if the team finds better NASA images): battery 1, 3, 4; life support 3, 5; shelter 1, 4, 5; suit bay 3, 4; comms 1.
