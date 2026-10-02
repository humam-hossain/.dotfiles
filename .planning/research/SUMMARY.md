# Project Research Summary

**Project:** Quickshell Desktop Shell (`.dotfiles`)  
**Domain:** Desktop Shell Weather Telemetry & Visualization (Quickshell / Qt 6 / Linux)  
**Researched:** 2026-10-02  
**Confidence:** HIGH  

## Executive Summary

Milestone **v0.10** replaces the existing basic `wttr.in` weather component with an enterprise-grade, rate-limited weather telemetry service and rich visualization interface powered by the **WorldWeatherOnline (WWO)** API. This implementation builds upon the user's initial sandbox work in `test_wwo_api/` (`WEATHER_PARAMETERS.md`, `test_wwo.py`, `raw_response.json`) and the interactive Canvas plotting prototype in `TestPopup.qml`.

The technical design revolves around three core pillars:
1. **Free-Tier Quota & Architectural Decoupling:** WorldWeatherOnline's free tier permits 500 calls per 24-hour cycle. To protect this budget from rapid QML hot-reloading and desktop shell restarts during development, network fetching is completely decoupled into a standalone Python/Systemd background service running at a fixed 15–20 minute interval (~72–96 calls/day max). Quickshell consumes the local atomic cache in `$XDG_RUNTIME_DIR/weather/weather.json` via a non-blocking `FileView` observer, guaranteeing 0 external API calls on UI reloads.
2. **Design-Matched Iconography & Systematic Parameter Evaluation:** Every parameter group from `WEATHER_PARAMETERS.md` (Thermal/Comfort, Atmospheric, Wind, Air Quality AQI/PM2.5, Astronomy, Severe Alerts) is methodically evaluated to determine its optimal UI representation. All 40+ WWO weather codes and day/night states (`isdaytime`) are cleanly mapped to Material Symbols ligatures matching the rest of the desktop shell.
3. **Interactive Time-Series Canvas Graphs & Scenegraph Efficiency:** Building upon `TestPopup.qml`, the popup features interactive Canvas 2D time-series charts (24-hour smooth temperature & feels-like curves, and hourly precipitation/rain probability bars) with mouse hover scrub inspection. In accordance with Milestone v0.9 performance rules, Canvas rendering is strictly event-driven (repainting only on data change, popup activation, or discrete hover index shifts) to preserve quiescent idle CPU $\le 1.68\%$.

## Key Findings

### Recommended Stack

- **Data Provider:** WorldWeatherOnline Local Weather API (`premium/v1/weather.ashx` with `format=json`, `tp=1`, `num_of_days=3`, `aqi=yes`, `alerts=yes`, `extra=isDayTime,utcDateTime,localObsTime`).
- **Background Fetcher:** Lightweight Python 3 script using `urllib.request` and atomic file rename (`os.replace`) to `$XDG_RUNTIME_DIR/weather/weather.json`.
- **Cadence Scheduler:** Systemd user timer triggering every 15–20 minutes with boot/wake persistence.
- **Desktop Shell Integration:** Quickshell Singleton service (`WeatherService.qml`) watching the cache via `Quickshell.Io.FileView`.
- **UI Engine:** QtQuick QML with custom Canvas 2D time-series graphing, Material Symbols iconography, and Material You / Matugen dynamic palette bindings (`Appearance.colors.*`).

### Expected Features

**Must Have (Table Stakes):**
- Dynamic weather glyph with daytime vs. nighttime switching (`isdaytime`).
- Status bar weather pill in Center Zone displaying temperature (°C) with fluid M3 width resizing.
- Decoupled rate-limited local cache protecting the 500 calls/day free-tier budget.
- Hero weather card in popup with current temperature, feels-like, and condition description.
- Core atmospheric metrics grid (Humidity, Barometric Pressure, UV Index, Wind).

**Should Have (Differentiators):**
- Interactive 24-hour temperature & feels-like smooth Canvas curve with min/max gridlines and hover scrub readout.
- Hourly precipitation volume & rain probability (%) chart.
- Air Quality Index (AQI) card with US-EPA color-coded health badges and PM2.5/PM10 readings.
- Dynamic wind direction compass needle rotating to exact meteorological degrees (`winddirDegree`).
- Astronomy timeline with sunrise/sunset times and lunar phase illumination fraction (`moon_phase`, `moon_illumination`).
- Severe weather warning banner glowing with severity color when official meteorological alerts are active.

**Anti-Features to Avoid:**
- Direct API calls inside QML (`Timer` / `Component.onCompleted`), which burns API quota on shell reloads.
- Embedded animated radar GIFs that waste bandwidth and cause VRAM thrashing.
- Unthrottled 60 FPS animation loops that regress quiescent idle CPU usage.

### Critical Pitfalls

1. **Free-tier API Quota Exhaustion:** Addressed by the decoupled background service and atomic local JSON cache.
2. **Partial File Read Race Conditions in FileView:** Addressed by writing to a temporary file and atomically renaming (`os.replace`).
3. **Canvas Over-Rendering & Idle CPU Churn:** Addressed by gating painting behind popup visibility and discrete hover index changes.
4. **Missing Weather Code Mappings:** Addressed by an exhaustive dictionary in `WeatherGlyphs.qml` covering all WWO condition codes and day/night variants.
5. **Hardcoded Color Codes:** Addressed by binding all UI components strictly to `Appearance.colors.*`.

## Implications for the Roadmap

The milestone can be structured cleanly into 6 sequential phases (continuing from Phase 50):

- **Phase 51: WWO Fetcher Service & Local Cache Architecture:** Build and verify `scripts/weather-fetch.py`, Systemd timer/service, rate-limiting, and atomic `$XDG_RUNTIME_DIR/weather/weather.json` caching.
- **Phase 52: Weather Service Singleton & Material Glyph Mapping:** Build `WeatherService.qml` with `FileView` observer, data parsing models, and `WeatherGlyphs.qml` mapping all 40+ WWO codes + `isdaytime` to Material Symbols.
- **Phase 53: Top Status Bar Weather Pill Component:** Build `WeatherPill.qml` in Center Zone with temperature display, condition glyph, fluid M3 width resizing, and situational alert badges.
- **Phase 54: Interactive Canvas Time-Series Graphs:** Expand `TestPopup.qml` prototype into production `WeatherGraph.qml` with 24-hour temperature/feels-like curve, hourly precipitation bar chart, and hover scrub readout.
- **Phase 55: Multi-Modal Weather Popup Inspector:** Build `WeatherPopup.qml` with 1000ms hover delay, atmospheric grid, AQI card (EPA index + PM2.5), dynamic wind compass, astronomy card, and severe alert banner.
- **Phase 56: System Integration, Test Harness & Verification:** Retire temporary `TestPill.qml` / `TestPopup.qml`, deploy via GNU Stow leaf symlinks, create automated regression harness `scripts/phase51-weather-assert.sh`, and verify zero repository drift.

---
*Research summary for: Desktop Shell Weather Telemetry & Visualization*  
*Researched: 2026-10-02*  
