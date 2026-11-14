# NASA & Space Agency Data Source Attribution

> **Project:** Bulalakaw Station — Mars Outpost Trainer  
> **Challenge:** 2026 NASA Space Apps Challenge — *Build a Junior Astronaut Mission Trainer*  
> **Purpose:** Comprehensive, traceable index of all official NASA and partner datasets used in the game mechanics, codex, and telemetry. Directly fulfills the **"Space Agency Data"** and **"References"** fields of the official submission portal.

---

## 1. Quick Data Mapping Matrix

| Agency / Resource | Dataset / Tool | Exact Real Data Point | Where Used in Bulalakaw Station | In-Game Badge |
|---|---|---|---|---|
| **NASA Open APIs** | [api.nasa.gov](https://api.nasa.gov) | Programmatic endpoint authorization & query telemetry | Central API gateway used by `DonkiService.gd` to fetch live solar conditions | `LIVE` / `ARCHIVED` |
| **NASA DONKI** | [Space Weather Database](https://ccmc.gsfc.nasa.gov/tools/DONKI/) (`FLR` / `SEP` endpoints) | Real solar flares (e.g., May 20, 2024 X12 class flare & Sep 10, 2017 event) | • Live solar telemetry banner<br>• Core warning window mechanic in **Night 3** & **Night 6**<br>• Codex: *Solar Flares* (`solar_flare.tres`) | `★ Real NASA Data` |
| **NASA OSDR & RadLab** | [OSDR Radiation Dosimetry Database](https://visualization.osdr.nasa.gov/radlab/gui/data-api/) & Curiosity RAD | Measured surface dose rates: **8,100 µGy** absorbed dose (May 20, 2024 event, ~30 chest X-rays) | • Desk crew dosimeters & alert thresholds<br>• Storm Shelter shielding mitigation curve<br>• Codex: *Radiation* (`radiation.tres`) & *Shelter* (`shelter_shielding.tres`) | `★ Real NASA Data` / `≈ Simplified` |
| **NASA Mars 2020** | Perseverance MOXIE (Mars Oxygen ISRU Experiment) | $12\text{ g } O_2/\text{hour}$ production rate requiring $\approx 300\text{ W}$ electrical power draw | • Life Support battery drain vs. oxygen production trade-off<br>• **Night 2** briefing and mechanics<br>• Codex: *Air: CO₂ & Oxygen* (`co2_oxygen.tres`) | `★ Real NASA Data` |
| **NASA Mars Exploration** | Mars 2020 (Perseverance Landing Comms) | Earth–Mars light-time radio delay: **11 min 22 s** (2021-02-18) | • Comms Dish "Ask Earth" mechanic & countdown timer<br>• **Night 4** & **Night 7** blackout deadline<br>• Codex: *Talking to Earth* (`comms_delay.tres`) | `★ Real NASA Data` |
| **NASA Mars Exploration** | Curiosity REMS / Perseverance MEDA & 2018 Dust Storm | Diurnal temperature drops ($-20^\circ\text{C}$ to $-80^\circ\text{C}$) & 2018 planet-encircling dust storm solar drop | • Base power start-level in **Night 1** & **Night 5**<br>• Heater power draw scaling at night<br>• Codex: *Dust Storms* (`dust.tres`) & *A Day on Mars* (`sol.tres`) | `★ Real NASA Data` |
| **Canadian Space Agency (CSA)** | [CSA Food Production in Space Toolkit](https://www.asc-csa.gc.ca/eng/youth-educators/toolkits/food-production/) | Microgreen growth photoperiod power constraints & nutritional caloric requirements for astronauts | • Greenhouse Plot and Crop Lamp night power budget in **Night 2**<br>• Codex: *Growing Food on Mars* (`food.tres`) | `★ Partner Data` |

---

## 2. Detailed Technical Breakdown & Verifiable Citations

### 1. NASA DONKI (Space Weather Database of Notifications, Knowledge, Information)
* **Official URL:** `https://ccmc.gsfc.nasa.gov/tools/DONKI/`
* **API Endpoints:** `/DONKI/FLR` (Solar Flares), `/DONKI/SEP` (Solar Energetic Particles)
* **Scientific Grounding:**
  In deep space and on Mars (which lacks a global magnetosphere), solar flares and coronal mass ejections (CMEs) emit intense X-rays, EUV radiation, and relativistic protons. The electromagnetic radiation arrives at the speed of light ($\approx 8\text{ to } 15\text{ minutes}$ from the Sun to Mars depending on orbital geometry), while the dangerous heavy charged ions and protons arrive 20 to 60 minutes later.
* **Game Implementation (`main-game/autoload/DonkiService.gd` & `main-game/resources/HazardEvent.gd`):**
  * Implements the **"Warning Window" mechanic**: The sky glows as light arrives first $\rightarrow$ a 20-second warning countdown begins $\rightarrow$ particle dose ticks up.
  * Allows live API queries using the user's NASA API Key or `DEMO_KEY`, with an automatic 24-hour cache and fail-safe fallback to the recorded 2024-05-20 event.

### 2. NASA OSDR / RadLab & Curiosity RAD (Radiation Assessment Detector)
* **Official URL:** `https://osdr.nasa.gov/` and `https://visualization.osdr.nasa.gov/radlab/gui/data-api/`
* **Citation:** Zeitlin et al. (2018), *Analysis of the Radiation Hazard Observed by RAD on the Surface of Mars*, GRL 45(12); NASA Science Mission Directorate release on Curiosity RAD records during the May 2024 storm.
* **Scientific Grounding:**
  Curiosity's RAD instrument detected an absorbed dose of **8,100 micrograys (µGy)** during the massive May 20, 2024 solar eruption—equivalent to approximately 30 simultaneous chest X-rays. 
* **Game Implementation (`main-game/scripts/OutpostSim.gd` & `main-game/data/nights/night_6.tres`):**
  * Target audience adaptation: To keep radiation intuitive for 7–12 year olds without confusing units like millisieverts ($mSv$), the game translates cumulative absorbed dose into **"Chest X-rays" (≈)**.
  * The Storm Shelter reduces dose penetration from $100\%$ outside down to $20\%$ (Level 1) or $5\%$ (Level 3), directly mirroring radiation mass shielding physics.

### 3. NASA MOXIE (Mars Oxygen ISRU Experiment)
* **Official URL:** `https://mars.nasa.gov/mars2020/spacecraft/instruments/moxie/`
* **Scientific Grounding:**
  MOXIE demonstrated that solid oxide electrolysis can extract breathable oxygen ($O_2$) from the atmospheric carbon dioxide ($CO_2$) on Mars, producing $\sim 12\text{ g } O_2/\text{hr}$ at an energy expenditure of $\sim 300\text{ Watts}$.
* **Game Implementation (`main-game/data/nights/night_2.tres` & `main-game/resources/BalanceConfig.gd`):**
  * Life Support settings: Low ($0.08\%/\text{s}$ power), Normal ($0.15\%/\text{s}$ power), High ($0.25\%/\text{s}$ power).
  * Direct trade-off: Running life support high preserves fresh oxygen reserves but rapidly drains the limited battery bank.

### 4. NASA Mars 2020 Perseverance Radio Signal Delay
* **Official URL:** `https://mars.nasa.gov/mars2020/mission/entry-descent-landing/`
* **Citation:** NASA Telemetry, *Seven Minutes of Terror / Perseverance EDL Light-Time Delay* (2021-02-18: 11 minutes 22 seconds).
* **Game Implementation (`main-game/data/nights/night_4.tres` & `main-game/data/nights/night_7.tres`):**
  * Player triggers "Ask Earth" or "Send Discovery". The radio transmission is subject to the scaled speed-of-light delay (5 seconds per real minute), displaying an honest comparison badge showing the true 11m 22s travel time.

### 5. CSA (Canadian Space Agency) — Food Production in Space & Bio-Nutritional STEM Toolkit
* **Official URL:** `https://www.asc-csa.gc.ca/eng/youth-educators/toolkits/food-production/`
* **Scientific Grounding:**
  Controlled Environment Agriculture (CEA) for space relies on specific LED lighting cycles (photoperiods) and temperature control. Heating and illumination of microgreens demand high kilowatt-hour allocations.
* **Game Implementation (`main-game/data/codex/food.tres` & `main-game/data/nights/night_2.tres`):**
  * Turning on the Crop Lamp costs an additional $0.06\%/\text{s}$ battery draw throughout the night to earn the bonus food growth yield for the debrief report.

---

## 3. Transparency & Attribution Standards (Space Apps Compliance)
* All in-game screens clearly distinguish between:
  1. `★ Real NASA Data`: Directly derived from measured NASA mission telemetry or peer-reviewed publications.
  2. `≈ Simplified`: Calibrated for accessibility for students ages 7–12 without compromising physical principles.
  3. `LIVE`: Freshly fetched within the last 24 hours from NASA's live DONKI API.
  4. `ARCHIVED`: Utilizing embedded real historical NASA mission records.
