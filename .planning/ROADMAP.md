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
- [ ] **Phase 54: Multi-Modal Popup Inspector & Interactive Graphs** - Production WeatherPopup with 24-hour temperature/feels-like spline curve, rain probability bars, hover scrub, atmospheric grid, AQI card, wind compass, astronomy card, and severe alert banner
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

### Phase 55: System Integration, Retirement & Verification

**Goal**: Retire prototype test files (`TestPill.qml`, `TestPopup.qml`), deploy via GNU Stow leaf symlinks, create automated regression harness, and verify repository cleanliness.  
**Depends on**: Phase 54  
**Requirements**: INTG-01, INTG-02, INTG-03, INTG-04  
**Success Criteria** (what must be TRUE):

  1. Temporary test artifacts (`TestPill.qml`, `TestPopup.qml`) cleanly removed from `BarContent.qml` and git.
  2. All weather QML files deployed under `restow/quickshell/` via leaf symlinks without modifying `vendor/dots-hyprland`.
  3. Automated regression harness `scripts/phase51-weather-assert.sh` passes 100% of assertion checks.
  4. `arch/dots-hyprland.sh verify --strict` passes with 0 findings and zero git churn.  

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 51 → 52 → 53 → 54 → 55

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 51. WWO Fetcher Service & Local Cache Architecture | 3/3 | Complete    | 2026-10-03 |
| 52. Weather Service Singleton & Material Glyph Mapping | 3/3 | Complete    | 2026-10-03 |
| 53. Top Status Bar Weather Pill Component | 2/2 | Complete    | 2026-10-05 |
| 54. Multi-Modal Popup Inspector & Interactive Graphs | 0/TBD | Not started | - |
| 55. System Integration, Retirement & Verification | 0/TBD | Not started | - |

---
*Roadmap defined: 2026-10-02*  
*Last updated: 2026-10-05 for Phase 53 completion*
