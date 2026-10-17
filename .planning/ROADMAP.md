# Roadmap: Quickshell Desktop Shell

## Milestones

- ✅ **v0.8 Notification Experience & Shell Interaction Polish** — Phases 38–41 (shipped 2026-09-25) — [Archive](milestones/v0.8-ROADMAP.md)
- ✅ **v0.9 Top Status Bar Resource Components & Hardware Telemetry** — Phases 42–50 (shipped 2026-10-01) — [Archive](milestones/v0.9-ROADMAP.md)
- 🟡 **v0.10 Weather Station & WWO Telemetry** — Phases 51–56 (in progress)

## Phases

<details>
<summary>✅ v0.8 Notification Experience & Shell Interaction Polish (Phases 38–41) — SHIPPED 2026-09-25</summary>

- [x] **Phase 38: Power Profiles Daemon System Integration** (1/1 plans) — completed 2026-09-23
- [x] **Phase 39: Dynamic Media Popup Anchoring** (1/1 plans) — completed 2026-09-23
- [x] **Phase 40: Notification Center Quick-Dismiss & Smart Interaction** (3/3 plans) — completed 2026-09-24
- [x] **Phase 40.1: Clock Pill Padding and Unified Volume Ceiling Ergonomics (INSERTED)** (2/2 plans) — completed 2026-09-24
- [x] **Phase 41: End-to-End Verification & Repository Integrity** (2/2 plans) — completed 2026-09-25

See full archived phase details in [milestones/v0.8-ROADMAP.md](milestones/v0.8-ROADMAP.md).

</details>

<details>
<summary>✅ v0.9 Top Status Bar Resource Components & Hardware Telemetry (Phases 42–50) — SHIPPED 2026-10-01</summary>

- [x] **Phase 42: Telemetry Services & Sensor Infrastructure** (4 plans) — completed 2026-09-25
- [x] **Phase 43: CPU & GPU Component (Pill & Popup)** (7 plans) — completed 2026-09-26
- [x] **Phase 43.1: Quickshell Performance Profiling and Resource Optimization (INSERTED)** (3 plans) — completed 2026-09-27
- [x] **Phase 43.2: Quickshell Profiling Harness Calibration & Empirical Baseline Capture (INSERTED)** (2 plans) — completed 2026-09-27
- [x] **Phase 43.3: Quickshell Benchmark Bottleneck Analysis & Optimization Strategy (INSERTED)** (1 plan) — completed 2026-09-27
- [x] **Phase 43.4: Quickshell Targeted Optimization & Empirical Verification (INSERTED)** (3 plans) — completed 2026-09-27
- [x] **Phase 43.5: CPU/GPU Dynamic Telemetry, Top Process Attribution Tree & Hover Delay Ergonomics (INSERTED)** (3 plans) — completed 2026-09-28
- [x] **Phase 43.6: Remove Top Processes & Streamline CpuGpuPopup Layout (INSERTED)** (2 plans) — completed 2026-09-28
- [x] **Phase 44: Memory & Storage Component (Pill & Popup)** (3 plans) — completed 2026-09-28
- [x] **Phase 45: Network & Multi-Target Ping Component (Pill & Popup)** (3 plans) — completed 2026-09-29
- [x] **Phase 46: Left-Zone Integration, Verification & Repository Integrity** (2 plans) — completed 2026-09-29
- [x] **Phase 47: Center-Zone Layout Reorganization** (3 plans) — completed 2026-09-29
- [x] **Phase 48: Right-Zone Media Expansion & System Tray Empty State Gating** (3 plans) — completed 2026-09-30
- [x] **Phase 49: Quickshell Resource Profiling & Component Performance Audit** (4 plans) — completed 2026-09-30
- [x] **Phase 50: Quickshell Deep Performance Optimization & Overhead Reduction** (4 plans) — completed 2026-09-30

See full archived phase details in [milestones/v0.9-ROADMAP.md](milestones/v0.9-ROADMAP.md).

</details>

### Milestone v0.10 Phases

- [x] **Phase 51: WWO Fetcher Service & Local Cache Architecture** - Standalone Python fetcher and systemd user timer with rate-limiting and atomic JSON caching (completed 2026-10-03)
- [x] **Phase 52: Weather Service Singleton & Material Glyph Mapping** - Reactive FileView observer service, complete WWO code dictionary, and day/night glyph mapper (completed 2026-10-03)
- [x] **Phase 53: Top Status Bar Weather Pill Component** - Status bar WeatherPill in Center Zone with temperature display, condition glyph, and fluid M3 width resizing (completed 2026-10-05)
- [x] **Phase 54: Multi-Modal Popup Inspector & Interactive Graphs** - Initial prototype; UAT rejected monolithic design in favor of modular breakdown (completed 2026-10-10)
- [x] **Phase 54.1: Top Status Bar Weather Component Polish (INSERTED)** - Visual alignment, M3 styling, interactive hover/active cues, and pill responsiveness (completed 2026-10-10)
- [x] **Phase 54.2: Hourly Parameter Modeling and Rolling Cache Service (INSERTED)** - [-12h .. NOW .. +12h] rolling window, 0-cost midnight cache rollover, and structured QML datasets (completed 2026-10-11)
- [x] **Phase 54.3: Interactive Multi-Metric Hourly Graph Component (INSERTED)** - Multi-metric graph (Thermal, Moisture, Wind, AQI, Atmosphere, Rain volume, UV) with scrub inspection (completed 2026-10-13)
- [ ] **Phase 54.4: Modular Popup Inspector and Clean Card Layout (INSERTED)** - Three side-by-side hourly graph cards, synced hover tooltips, percent-sized non-scrolling popup
- [ ] **Phase 54.5: Popup Hero, Daily Stats, Astronomy and Forecast Cards (INSERTED)** - Hero header, stat pills, astronomy card, forecast strip, hidden-card fate
- [ ] **Phase 55: System Integration, Retirement & Verification** - Prototype retirement, leaf symlink deployment, automated regression harness, and zero git churn

## Phase Details

### Phase 51: WWO Fetcher Service & Local Cache Architecture

**Goal**: Build a decoupled background Python fetcher and systemd timer that securely queries WorldWeatherOnline and atomically writes `$XDG_RUNTIME_DIR/weather/weather.json` under the 500 calls/day budget.  
**Depends on**: Nothing (first phase of v0.10)  
**Requirements**: WWO-01, WWO-02, WWO-03, WWO-04  
**Success Criteria** (what must be TRUE):

  1. Standalone Python fetcher queries WWO API using `.env` credentials and generates a complete JSON cache file in `$XDG_RUNTIME_DIR/weather/weather.json`.
  2. Systemd user timer executes every 15–20 minutes, enforcing a daily call rate $\le 96$ calls/day, safely under the 500 free-tier limit.
  3. File write operations use atomic tempfile replacement (`os.replace`) to prevent Quickshell reading partial or truncated JSON data.
  4. Network drops or API timeouts preserve existing cached data with `is_stale: true` and error metadata without deleting or corrupting the cache.  

**Plans**: 3/3 plans complete

### Phase 52: Weather Service Singleton & Material Glyph Mapping

**Goal**: Create `WeatherService.qml` singleton consuming the cache via reactive `FileView` and `WeatherGlyphs.qml` mapping all 40+ WWO codes to Material Symbols with day/night awareness.  
**Depends on**: Phase 51  
**Requirements**: GLYPH-01, GLYPH-02, GLYPH-03, GLYPH-04  
**Success Criteria** (what must be TRUE):

  1. `WeatherService.qml` parses local cache into structured reactive properties (`current`, `hourly`, `aqi`, `astronomy`, `alerts`) via `Quickshell.Io.FileView` with 0 network calls on shell reload.
  2. All 40+ WWO weather codes (113–395) map deterministically to valid Material Symbols ligature glyphs.
  3. Dynamic day vs. night glyph switching works reliably based on the `isdaytime` field across all weather conditions.
  4. Air quality (US-EPA 1–6) and severe weather alert levels map cleanly to Material You theme colors (`Appearance.colors.*`).  

**Plans**: 3/3 plans complete

### Phase 53: Top Status Bar Weather Pill Component

**Goal**: Build `WeatherPill.qml` in the Center Zone of the status bar with temperature, condition glyph, fluid M3 width resizing, and alert indicators.  
**Depends on**: Phase 52  
**Requirements**: BAR-01, BAR-02, BAR-03, BAR-04  
**Success Criteria** (what must be TRUE):

  1. `WeatherPill.qml` renders in `BarContent.qml` Center Zone to the right of Workspaces with uniform 4px margins and zero visual overlap.
  2. Displays current temperature in Celsius (`XX°C`) alongside active dynamic condition glyph.
  3. Displays subtle warning indicator for imminent rain (probability > 50%) or active severe weather warnings.
  4. Clicking or hovering pill toggles `WeatherPopup` with smooth scale transitions and hover intent delay anchoring (`StyledPopup`).  

**Plans**: 2/2 plans complete

- [x] 53-01-PLAN.md
- [x] 53-02-PLAN.md

### Phase 54: Multi-Modal Popup Inspector & Interactive Graphs

**Goal**: Build production `WeatherPopup.qml` and `WeatherGraph.qml`, delivering the complete interactive visual popup inspector with 24-hour temperature/precipitation spline graphs, hover scrub, hero overview, atmospheric grid, AQI card, wind compass, astronomy timeline, and severe alert banner.  
**Depends on**: Phase 53  
**Requirements**: GRAPH-01, GRAPH-02, GRAPH-03, GRAPH-04, POPUP-01, POPUP-02, POPUP-03, POPUP-04, POPUP-05, POPUP-06, POPUP-07  
**Success Criteria** (what must be TRUE):

  1. Popup anchors under `WeatherBar` with 1000ms hover delay and screen boundary clamping via `StyledPopup`.
  2. Canvas 2D renders 24-hour temperature and feels-like curve with smooth Bezier spline interpolation, min/max gridlines, and gradient fills.
  3. Hourly precipitation volume (mm) and rain probability (%) render as clear bars/columns across the 24-hour forecast strip with interactive mouse scrub readout.
  4. Canvas repainting is strictly event-driven (gated by popup visibility `root.active` and discrete hover index shifts) to maintain quiescent idle CPU $\le 1.68\%$.
  5. Hero card displays location name, observation time, large temperature readout, and human condition description.
  6. Atmospheric grid displays Humidity, Pressure, UV Index, and Visibility.
  7. Air Quality card renders US-EPA colored health badge and PM2.5 / PM10 metrics.
  8. Wind card displays rotating directional compass needle (`winddirDegree`), 16-point direction, and wind/gust speed.
  9. Astronomy card displays sunrise, sunset, and lunar illumination phase.
  10. Severe weather banner renders prominently when official alerts are active.

**Plans**: TBD

- [x] 54-01-PLAN.md
- [x] 54-02-PLAN.md
- [x] 54-03-PLAN.md
- [x] 54-04-PLAN.md

### Phase 54.1: Top Status Bar Weather Component Polish (INSERTED)

**Goal:** Refine WeatherBar pill in Center Zone to achieve pixel-perfect visual alignment, consistent M3 surface styling, interactive hover/active states, and fluid responsive sizing matching neighboring status bar modules.
**Requirements**: BAR-01, BAR-02, BAR-03, BAR-04
**Depends on:** Phase 53
**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 54.1-01-PLAN.md

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 54.1-02-PLAN.md

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 54.1-03-PLAN.md

### Phase 54.2: Hourly Parameter Modeling and Rolling Cache Service (INSERTED)

**Goal:** Model the continuous [-12h .. NOW .. +12h] rolling timeline across past and future forecast slots, implement 0-cost midnight cache rollover in wwo-fetcher.py for full 24/7 historical coverage, and expose structured typed datasets in WeatherService.qml for all selected metric groups (Thermal, Moisture, Wind, AQI, Atmosphere, Solar).
**Requirements**: DATA-01, DATA-02, DATA-03
**Depends on:** Phase 54.1
**Plans:** 4/4 plans complete

Plans:
**Wave 1**

- [x] 54.2-01-PLAN.md — Backend Fetcher Historical Cache Rollover & Downtime Invalidation

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 54.2-02-PLAN.md — WeatherService 25-Point Rolling Timeline, Metric Groups & Series Getter

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 54.2-03-PLAN.md — Verification Test Harness (phase54.2-weather-assert.sh) & Zero-Churn Integrity Gate

### Phase 54.3: Interactive Multi-Metric Hourly Graph Component (INSERTED)

**Goal:** Build dedicated interactive WeatherGraph component supporting metric selection across agreed groups (Thermal dual splines, Moisture/Cloud cover, Precipitation odds/volume, Wind dynamics with compass dial, Air quality with EPA tiers, Atmosphere/Pressure, Solar/UV) with a centered "NOW" hairline and zero-repaint hover scrubbing.
**Requirements**: GRAPH-01, GRAPH-02, GRAPH-03, GRAPH-04
**Depends on:** Phase 54.2
**Plans:** 10/10 plans complete

Plans:
**Wave 1**

- [x] 54.3-01-PLAN.md — Test Harness Creation & Wave 0 Infrastructure

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 54.3-02-PLAN.md — Metric Selector Tab Bar & Multi-Metric Dual-Tier Canvas Engine

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 54.3-03-PLAN.md — Zero-Repaint Hover Scrub Overlay, Day/Night Shading & Submodule Verification

**Gap closure (UAT 2026-10-13, 4 gaps):**

- [x] 54.3-04-PLAN.md — Tab-less composite essentials canvas + stale-session deploy discipline (G-54.3-1)
- [x] 54.3-05-PLAN.md — Legend row, distinct series palette, canvas text geometry, QML icon axis strip, tooltip type (G-54.3-2, G-54.3-3, G-54.3-5 canvas half)
- [x] 54.3-06-PLAN.md — Card scaffold layout-driven sizing, clipping fail-safe, full strict verification (G-54.3-5)
- [x] 54.3-07-PLAN.md — Y-axis gutter unclip plus tooltip stacked 3-line opacity plus single-graph scope decision (G-54.3-1, G-54.3-3, G-54.3-4)
- [x] 54.3-08-PLAN.md — Stacked locked Wind/AQI/Baro/UV graph instances plus per-metric paint branches plus Test 4 truth rewrite (G-54.3-4)

**Gap closure (UAT 2026-10-15, 3 gaps):**

- [x] 54.3-09-PLAN.md — Popup-chrome centering plus anchoring harness gate (G-54.3-1)
- [x] 54.3-10-PLAN.md — Per-metric legend, axis labels, baro shortening, tooltip rewire plus wiring gates (G-54.3-2, G-54.3-3)

### Phase 54.4: Modular Popup Inspector and Clean Card Layout (INSERTED)

**Goal:** Replace the five stacked hourly graphs in WeatherPopup with three equal side-by-side graph cards (Temperature; Rain, Wind & Visibility; Air, UV & Pressure) with synced hover and floating tooltips, inside a non-scrolling popup sized as a percentage of its screen, keeping the alert banner and hero card on top (absorbs backlog 999.1; top-section redesign moved to Phase 54.5).
**Requirements**: POPUP-01, POPUP-02, POPUP-03, POPUP-04
**Depends on:** Phase 54.3
**Plans:** 8/8 plans executed

**Success Criteria** (what must be TRUE):

  1. The popup outer size is popupWidthPercent x popupHeightPercent of its screen (default 50 x 50), at least 900px wide, clamped to the screen, with no scrolling. StyledPopup anchoring and the horizontal clamp still hold (POPUP-01).
  2. The alert banner and the unchanged hero card sit on top. The Atmospheric, Wind, AQI and Astronomy cards are hidden, not deleted (POPUP-02).
  3. Three equal cards sit side by side, each with a legend row, the same left gutter, and an identical 7-tick 12-hour x-axis reading Now at the centre.
  4. Hovering any graph syncs the scrub line, markers and all three tooltips across the graphs, and the tooltips float above neighbouring cards.
  5. Humidity, pressure (atm), UV and visibility read out in the graph tooltips (POPUP-03, interim). An EPA tier ribbon and an AQI, PM2.5 and PM10 tooltip line appear in Graph 3 (POPUP-04, interim).
  6. `./scripts/phase54.4-weather-assert.sh` passes with FAIL=0, and `./arch/dots-hyprland.sh verify --strict` is clean.

Plans:
**Wave 1**

- [x] 54.4-01-PLAN.md — Tracer: percent-sized non-scrolling three-card popup, temperature curve via WeatherGraphMath.js, StyledPopup re-clamp, Wave 0 harness
- [x] 54.4-02-PLAN.md — Scope reconciliation: re-scope 54.4 goal, insert Phase 54.5, annotate POPUP-03/04

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 54.4-03-PLAN.md — Synced hover: popup-owned hoverSlot, scrub line and markers, three overlay tooltips, temperature tooltip
- [x] 54.4-04-PLAN.md — Supersede 54.3/54 harness contracts by decision, SIGPIPE fix, phase34 single-file hex allow-list

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 54.4-05-PLAN.md — Temperature graph complete: legend row, 1°C grid with thinning labels, shared backdrop, collision-free peak labels

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 54.4-06-PLAN.md — Graph 2: rain % tiers, wind/gust/visibility, mm bars with labels, 4-line tooltip

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 54.4-07-PLAN.md — Graph 3: UV tiers, EPA ribbon, solar bars, pressure in atm with trend, 5-line tooltip

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 54.4-08-PLAN.md — Phase gate: full suite, live log smoke after restart, VALIDATION map, verify-work human checks

### Phase 54.5: Popup Hero, Daily Stats, Astronomy and Forecast Cards (INSERTED)

**Goal:** Redesign the WeatherPopup top section deferred from Phase 54.4: hero location/observation header, daily text stat pills (Min/Avg/Max, sun hours, UV max), astronomy sun/moon card (sunrise, sunset, moonrise, moonset, phase, illumination), 3-day forecast trend strip, and the fate of the hidden Atmospheric, Wind and AQI cards.
**Requirements**: POPUP-02, POPUP-03, POPUP-04, POPUP-05, POPUP-06 (confirm at /gsd-discuss-phase 54.5)
**Depends on:** Phase 54.4
**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 54.5 to break down)

### Phase 55: System Integration, Retirement & Verification

**Goal**: Retire prototype test files (`TestPill.qml`, `TestPopup.qml`), deploy via GNU Stow leaf symlinks, create automated regression harness, and verify repository cleanliness.  
**Depends on**: Phase 54.5  
**Requirements**: INTG-01, INTG-02, INTG-03, INTG-04  
**Success Criteria** (what must be TRUE):

  1. Temporary test artifacts (`TestPill.qml`, `TestPopup.qml`) cleanly removed from `BarContent.qml` and git.
  2. All weather QML files deployed under `restow/quickshell/` via leaf symlinks without modifying `vendor/dots-hyprland`.
  3. Automated regression harness `scripts/phase51-weather-assert.sh` passes 100% of assertion checks.
  4. `arch/dots-hyprland.sh verify --strict` passes with 0 findings and zero git churn.  

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 51 → 52 → 53 → 54 → 54.1 → 54.2 → 54.3 → 54.4 → 54.5 → 55

| Phase | Plans Complete | Status | Completed |
|---|---|---|---|
| 51. WWO Fetcher Service & Local Cache Architecture | 3/3 | Complete | 2026-10-03 |
| 52. Weather Service Singleton & Material Glyph Mapping | 3/3 | Complete | 2026-10-03 |
| 53. Top Status Bar Weather Pill Component | 2/2 | Complete | 2026-10-05 |
| 54. Multi-Modal Popup Inspector & Interactive Graphs | 4/4 | Redesigned | 2026-10-10 |
| 54.1. Top Status Bar Weather Component Polish | 3/3 | Complete    | 2026-10-10 |
| 54.2. Hourly Parameter Modeling and Rolling Cache Service | 4/4 | Complete    | 2026-10-11 |
| 54.3. Interactive Multi-Metric Hourly Graph Component | 10/10 | Complete    | 2026-10-15 |
| 54.4. Modular Popup Inspector and Clean Card Layout | 8/8 | In Progress | - |
| 54.5. Popup Hero, Daily Stats, Astronomy and Forecast Cards | 0/TBD | Not started | - |
| 55. System Integration, Retirement & Verification | 0/TBD | Not started | - |

---
*Roadmap defined: 2026-10-02*  
*Last updated: 2026-10-10 for Phase 54.1–54.4 roadmap expansion*

## Backlog

### Phase 999.1: Follow-up — Phase 54.3 deferred UAT follow-up: Test 4 (BACKLOG)

**Goal:** Resolve the UAT checkpoint deferred during Phase 54.3 verification
**Source phase:** 54.3
**Deferred at:** 2026-10-15 during /gsd-verify-work 54.3 session completion
**Follow-ups:**
- [ ] Test 4: user confirms five stacked graphs work, but wants a future phase to redesign into 2-3 compact graphs (possibly horizontal, smaller) with no scrolling (deferred 2026-10-15) **[absorbed by Phase 54.4]** — three compact side-by-side graphs, no scrolling
