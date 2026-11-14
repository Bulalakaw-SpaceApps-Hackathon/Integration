# Antigravity Hackathon Efficiency & Workflow Guide

> **Project:** Bulalakaw Station (NASA Space Apps Challenge 2026)  
> **Target:** Deliver a winning, bug-free, browser-playable game with high-grade NASA data before Sunday 11:59 PM.

---

## 1. Modular Architecture: Decoupled & Resilient Code

To ensure that if one feature or file breaks, it does NOT crash the rest of the game:

### Golden Rules of Modular GDScript:
1. **Never use hard-coded node paths across systems (`get_node("../../SomeNode")` or `find_child()`):**
   * Use **Signals** (`signal door_toggled`, `signal battery_depleted`) for outbound communication.
   * Listeners connect to signals; callers never care who is listening.
2. **UI never executes simulation rules:**
   * UI scripts (`DeskUI.gd`, `HubMap.gd`) only call public intent methods on `SimState` (e.g., `SimState.sim.toggle_camera(id)`) and read public getters.
   * If a UI button has a glitch, the simulation state remains intact.
3. **Data is decoupled from Code:**
   * All numbers, costs, and rates live in `data/balance.tres` (`BalanceConfig`).
   * Nights are isolated data files (`data/nights/night_*.tres`), played by a generic `NightDirector.gd`. Adding, removing, or tweaking a night never touches engine scripts.
4. **Standalone Sim Testing:**
   * The core simulation engine (`OutpostSim.gd`) is pure GDScript with **zero scene tree or autoload dependencies**. It can be verified completely offline with unit tests (`tests/test_sim.gd`).
5. **Fallbacks for External Services:**
   * Network integrations (`autoload/DonkiService.gd`) use an offline cached archive if NASA's API times out, ensuring zero game-breaking crashes during offline judging.

---

## 2. Workspace Organization: Separation of Concerns

Our project workspace is organized so documentation and game code do not clash:

```
spaceapps-bulalakaw-dday/
├── docs/                        <-- Non-game files: briefs, MoMs, guidelines, pitches
│   ├── Bulalakaw-Build-Brief-V2.md
│   ├── NASA Space Apps Challenge Details.md
│   ├── NASA_DATA_ATTRIBUTION.md <-- Complete traceability for Space Apps submission
│   ├── Hackathon Orientation – MoM.pdf
│   └── WORKFLOW_GUIDE.md
│
├── main-game/                   <-- Pure Godot game engine root
│   ├── project.godot
│   ├── assets/                  <-- Sprites, SFX, fonts
│   ├── autoload/                <-- Decoupled singletons (Signals & State)
│   ├── data/                    <-- .tres configs (balance, nights, codex)
│   ├── scenes/                  <-- Minimal root scenes (Main.tscn, Desk.tscn)
│   ├── scripts/                 <-- UI and Director logic
│   └── tests/                   <-- Headless test suites
│
└── .github/workflows/           <-- CI/CD (GitHub Actions Web Export)
```

---

## 3. NASA Data Governance: Traceability First

Whenever we introduce a new number, mechanic, or codex tip:
1. **Never invent arbitrary numbers** when real NASA or partner data exists.
2. **Update `docs/NASA_DATA_ATTRIBUTION.md` immediately**: Keep every dataset, URL, and citation logged so the hackathon submission form is pre-written.
3. **Use Honest In-Game Badging**:
   * `★ Real NASA Data`: Direct telemetry or published measurements.
   * `≈ Simplified`: Scaled or simplified for young learners (e.g., chest X-rays instead of micrograys).
   * `LIVE`: Fetched live from NASA DONKI within 24 hours.
   * `ARCHIVED`: Embedded historical NASA records.

---

## 3. How to Handle "Context Loss" (The Anti-Amnesia Strategy)

### Why you don't need to fear context loss:
1. **The Codebase is the Ground Truth:** The agent reads actual files from your disk (`.gd`, `.tres`, `.json`, `.md`), not just chat memory. As long as our decisions are written down into code or config files, nothing is lost.
2. **Context Compaction (`/compact`):** If a chat gets very long (dozens of steps), you can run the `/compact` slash command. It summarizes the chat history into a clean executive summary while keeping critical project state intact.
3. **Deep Context Handoff:** Whenever a chat gets bloated, ask: *"Create a handoff briefing for a new chat"*. The agent generates a complete, loss-free transfer prompt that you paste into a fresh chat.
4. **Single Source of Truth Document:** `docs/Bulalakaw-Build-Brief-V2.md` and this workflow guide serve as permanent memory. Every new chat can be primed simply by referencing these files.

---

## 4. Multi-Chat Division of Labor

Instead of one messy 200-message chat or 10 fragmented chats, run **3 parallel chat lanes**:

```
┌─────────────────────────────────────────────────────────────┐
│                   Antigravity Project Workspace             │
├──────────────────────────────┬──────────────────────────────┤
│ 1. Coding & Data Engine      │ • Direct code modifications  │
│    (Keep this main chat)     │ • Godot data (*.tres, *.gd)  │
│                              │ • Git branches, commits, PRs │
├──────────────────────────────┼──────────────────────────────┤
│ 2. Design, Copy & Sprites    │ • Narrative, dialog, tips    │
│    (Second Chat)             │ • Sprite dimension & art QA  │
│                              │ • Codex science fact checks  │
├──────────────────────────────┼──────────────────────────────┤
│ 3. Pitch, Deck & Video Lead  │ • 7-slide presentation deck  │
│    (Third Chat)              │ • 30-second video script     │
│                              │ • NASA Portal answers        │
└──────────────────────────────┴──────────────────────────────┘
```

---

## 5. Model Selection Matrix: Which Model for Which Task?

| Task Type | Recommended Model | Reason |
|---|---|---|
| **Writing GDScript, Modifying `.tres`, Git Ops, Bug Fixes** | **Gemini 4 Hydrogen (Medium/High Effort)** | Fastest tool execution, precise code edits, low token overhead, zero lag. |
| **Complex Math, Simulation Physics, Deep Architecture** | **Gemini Pro (or Argon)** | Deep multi-step reasoning, formal verification. |
| **Hackathon Pitch, High-Level Summary, Storytelling, Video Script** | **Gemini Pro** | Eloquent, persuasive, human-centered writing matching NASA judging rubrics. |
| **Quick lookups, status checks, formatting templates** | **Gemini 3.8 Flash** | Ultra-lightweight and instantaneous. |

---

## 6. Daily Hackathon Cadence (Countdown to Sunday 11:59 PM)

1. **Step 1 (Now - Sat Night):** Solidify the **Data & Simulation** (DONKI, real radiation values, balance parameters).
2. **Step 2 (Sun Morning):** Asset Integration (Drop in final artwork/audio into `assets/sprites/` and `assets/sfx/`).
3. **Step 3 (Sun Afternoon):** Judge Mode & Polish (Make sure Night 6 Judge sandbox works flawlessly).
4. **Step 4 (Sun 6:00 PM - 5 Hours Before Deadline):** Lock the Code! Switch 100% of focus to the **7-slide demo deck, 30s video, and submission page write-up**. Never code in the final 2 hours.
