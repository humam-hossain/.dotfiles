# Requirements: Weather Station & WWO Telemetry

**Defined:** 2026-10-02  
**Core Value:** The desktop must keep (and eventually exceed) current Waybar-era capability — workspaces, system metrics, network, ping, weather, clock, music, volume, tray, notifications, power — while consolidating toward one themeable shell. Delivery is via **upstream dots-hyprland + personal overlays**, not a from-scratch QML rewrite.

## v0.10 Requirements

Requirements for Milestone v0.10. Each maps to roadmap phases.

### WorldWeatherOnline API & Local Cache Service (WWO)

- [x] **WWO-01**: Standalone background Python fetcher queries WorldWeatherOnline Local Weather API (`premium/v1/weather.ashx` with `format=json`, `tp=1`, `num_of_days=3`, `aqi=yes`, `alerts=yes`) using API key from secure `.env` configuration.
- [x] **WWO-02**: Scheduled cadence execution via Systemd user timer (every 15–20 minutes) strictly enforcing a rate-limited cap ($\le 96$ calls/day) safely within the 500 free-tier daily quota.
- [x] **WWO-03**: Atomic JSON cache file replacement writing to `$XDG_RUNTIME_DIR/weather/weather.json` via unique temporary file rename (`os.replace`) to eliminate partial read race conditions in Quickshell.
- [x] **WWO-04**: Offline resilience preserving cached forecast data during network outages, recording error metadata and setting an `is_stale: true` flag without crashing or deleting the cache.

### Weather Service Singleton & Iconography (GLYPH)

- [x] **GLYPH-01**: `WeatherService.qml` singleton observes the local cache file via reactive `Quickshell.Io.FileView` with non-blocking updates and zero external API calls on desktop shell reload.
- [x] **GLYPH-02**: Comprehensive `WeatherGlyphs.qml` dictionary mapper converts all 40+ WWO condition codes (`weatherCode` 113–395) to Material Symbols ligature strings with verified fallbacks.
- [x] **GLYPH-03**: Daytime vs. nighttime glyph switching dynamically driven by WWO `isdaytime` field across all weather conditions.
- [x] **GLYPH-04**: Health and severity color mapping assigning Material You palette tokens (`Appearance.colors.*`) to air quality levels (US-EPA) and severe weather alerts.

### Top Status Bar Weather Pill (BAR)

- [x] **BAR-01**: `WeatherPill.qml` component integrated into `BarContent.qml` Center Zone to the right of Workspaces, inheriting `BarGroup` with fluid M3 width resizing animation.
- [x] **BAR-02**: Status bar pill displays current ambient temperature in integer Celsius (`XX°C`) alongside the active dynamic condition glyph.
- [x] **BAR-03**: Context-sensitive warning indicators on the pill for imminent rain (probability > 50%) or active severe weather warnings.
- [x] **BAR-04**: Interactive mouse click toggles `WeatherPopup` with smooth scale behavior and hover intent delay anchoring (`StyledPopup`).

### Interactive Time-Series Canvas Graphs (GRAPH)

- [ ] **GRAPH-01**: 24-hour hourly temperature & feels-like curve rendered via QtQuick Canvas 2D with smooth Bezier spline interpolation and min/max gridlines.
- [ ] **GRAPH-02**: Hourly rain probability (%) and precipitation volume (mm) column/bar visualization for the 24-hour forecast window.
- [ ] **GRAPH-03**: Interactive mouse hover scrub inspection with dynamic readout of time, temperature, and rain chance at the nearest hourly slot.
- [ ] **GRAPH-04**: Event-driven Canvas rendering with repaint requests gated strictly behind popup visibility (`root.active`) and discrete hover changes to prevent idle CPU churn.

### Multi-Modal Popup Inspector (POPUP)

- [x] **POPUP-01**: `WeatherPopup.qml` anchored via `StyledPopup` with 1000ms hover intent delay and horizontal screen boundary clamping.
- [x] **POPUP-02**: Hero header card presenting location name (`nearest_area`), local observation time, large temperature readout, and human condition description (`weatherDesc`).
- [ ] **POPUP-03**: Atmospheric metrics grid displaying Humidity (%), Barometric Pressure (hPa), UV Index, and Visibility (km).
- [ ] **POPUP-04**: Air Quality Index (AQI) card displaying US-EPA index (1–6) color-coded health badge and fine particulate PM2.5 / PM10 concentrations.
- [ ] **POPUP-05**: Dynamic wind compass card displaying rotating needle angle (`winddirDegree`), 16-point direction (`winddir16Point`), wind speed (km/h), and peak gusts.
- [ ] **POPUP-06**: Astronomy card displaying local sunrise, sunset times, and lunar phase illumination fraction (`moon_phase` + `moon_illumination`).
- [x] **POPUP-07**: Severe weather alert banner dynamically rendered only when active meteorological alerts exist in `alerts.alert`, glowing with severity color.

### System Integration, Retirement & Verification (INTG)

- [ ] **INTG-01**: Clean retirement and deletion of temporary prototype files (`TestPill.qml`, `TestPopup.qml`) from `BarContent.qml` and the filesystem.
- [ ] **INTG-02**: All custom QML files deployed via GNU Stow leaf symlinks in `restow/quickshell/` without modifying `vendor/dots-hyprland`.
- [ ] **INTG-03**: Automated multi-section regression test harness (`scripts/phase51-weather-assert.sh`) verifying atomic caching, schema conformance, `FileView` reactivity, and zero git churn.
- [ ] **INTG-04**: Repository cleanliness affirmed via `arch/dots-hyprland.sh verify --strict` with 0 findings.

## Future Requirements (Deferred)

- **CUST-01**: Port remaining custom scripts (earthquake alert, etc.) into native Quickshell components.
- **RADAR-01**: Web-based or static radar satellite tile viewer in an expanded drawer.
- **MULTICITY-01**: Multi-location switcher allowing user to toggle between home, work, and travel cities.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Direct QML live API polling on startup | Burns 500 calls/day free-tier quota during UI development and shell reloads. |
| Embedded animated radar GIFs/videos | High bandwidth consumption and severe GPU/VRAM thrashing in Quickshell. |
| Hardcoded city/coordinates without config support | Fragile and inflexible across different operator environments. |
| Continuous 60 FPS graph animation loops | Regresses Milestone v0.9 performance optimizations (quiescent idle CPU $\le 1.68\%$). |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| WWO-01 | Phase 51 | Complete |
| WWO-02 | Phase 51 | Complete |
| WWO-03 | Phase 51 | Complete |
| WWO-04 | Phase 51 | Complete |
| GLYPH-01 | Phase 52 | Complete |
| GLYPH-02 | Phase 52 | Complete |
| GLYPH-03 | Phase 52 | Complete |
| GLYPH-04 | Phase 52 | Complete |
| BAR-01 | Phase 53 | Complete |
| BAR-02 | Phase 53 | Complete |
| BAR-03 | Phase 53 | Complete |
| BAR-04 | Phase 53 | Complete |
| GRAPH-01 | Phase 54 | Pending |
| GRAPH-02 | Phase 54 | Pending |
| GRAPH-03 | Phase 54 | Pending |
| GRAPH-04 | Phase 54 | Pending |
| POPUP-01 | Phase 54 | Complete |
| POPUP-02 | Phase 54 | Complete |
| POPUP-03 | Phase 54 | Pending |
| POPUP-04 | Phase 54 | Pending |
| POPUP-05 | Phase 54 | Pending |
| POPUP-06 | Phase 54 | Pending |
| POPUP-07 | Phase 54 | Complete |
| INTG-01 | Phase 55 | Pending |
| INTG-02 | Phase 55 | Pending |
| INTG-03 | Phase 55 | Pending |
| INTG-04 | Phase 55 | Pending |

**Coverage:**

- v0.10 requirements: 27 total
- Mapped to phases: 27
- Unmapped: 0 ✓

---
*Requirements defined: 2026-10-02*  
*Last updated: 2026-10-05 after merging Phase 54 and Phase 55*  
