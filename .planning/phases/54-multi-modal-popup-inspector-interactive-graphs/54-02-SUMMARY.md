---
phase: 54-multi-modal-popup-inspector-interactive-graphs
plan: 02
subsystem: quickshell-weather
tags: [quickshell, qml, weather, hero-card, alert-banner, carousel, drawer]
requires:
  - phase: 54-multi-modal-popup-inspector-interactive-graphs
    plan: 01
provides:
  - restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherHeroCard.qml
  - restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherAlertBanner.qml
affects:
  - quickshell-bar-weather
tech-stack:
  added: []
  patterns:
    - WeatherHeroCard with large temperature readout, outline glyph, observation time, and debounced reload
    - WeatherAlertBanner with dynamic M3 severity tint, multi-alert stepping carousel, and expandable advisory drawer
key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherHeroCard.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherAlertBanner.qml
  modified:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml
    - scripts/phase54-weather-assert.sh
key-decisions:
  - "D-54-32/34: WeatherHeroCard displays huge bold Celsius readout, 36px outline glyph, and soft amber status pill when stale/offline"
  - "D-54-37/38: Passive cache reload triggers Weather.getData() with 360° spin over 600ms and 2s debounce lockout"
  - "D-54-30/31: WeatherAlertBanner collapses to 0 height via Revealer, glows with M3 severity color, and provides multi-alert stepping controls"
requirements-completed:
  - POPUP-02
  - POPUP-07
duration: 4 min
completed: 2026-10-10
coverage:
  - deliverable: "WeatherHeroCard desktop overview component"
    verification:
      kind: command
      ref: "./scripts/phase54-weather-assert.sh -s 2"
      status: pass
    human_judgment: false
  - deliverable: "WeatherAlertBanner severe advisory carousel and drawer"
    verification:
      kind: command
      ref: "./scripts/phase54-weather-assert.sh -s 2"
      status: pass
    human_judgment: false
  - deliverable: "WeatherPopup layout integration"
    verification:
      kind: command
      ref: "./scripts/phase54-weather-assert.sh -s 2"
      status: pass
    human_judgment: false
---

# Phase 54 Plan 02: WeatherHeroCard Overview & WeatherAlertBanner Carousel Summary

Primary desktop weather overview and severe weather advisory banner delivered via `WeatherHeroCard.qml` and `WeatherAlertBanner.qml`, integrated directly into `WeatherPopup.qml` with automated verification in `scripts/phase54-weather-assert.sh` Section 2.

## Accomplishments

1. **Authored `WeatherHeroCard.qml`**:
   - Large bold integer Celsius temperature readout (~32–36px bold via `Appearance.font.pixelSize.huge`) with safe neutral fallback (`"--°C"`).
   - 36px outline condition glyph (`fill: 0`), city/region metadata, and descriptive text.
   - Soft amber status pill (`Appearance.m3colors.m3errorContainer`) for stale/offline states displaying last-known cached metrics without dimming.
   - Passive cache reload button triggering `Weather.getData()` with 360° spin animation over 600ms and 2000ms debounce lockout.
2. **Authored `WeatherAlertBanner.qml`**:
   - Collapsible `Revealer` container collapsing to 0 height when no alerts exist.
   - Dynamic Material 3 severity border glow using `WeatherGlyphs.getAlertColor(activeAlert?.severity)`.
   - Multi-alert stepping carousel (`<` and `>` with `<N> of <M>` count pill) when multiple alerts are active.
   - Expandable text drawer with 180° animated chevron displaying full advisory and affected areas.
   - Pure desktop telemetry with zero external browser popups or clipboard mutations.
3. **Integrated into `WeatherPopup.qml`**:
   - Positioned `WeatherAlertBanner` at position 1 and `WeatherHeroCard` at position 2 in `contentColumn`.
4. **Enriched Assert Harness Section 2**:
   - Verified AST properties, state bindings, debounced timers, and headless mock data injection with Node.js across `nominal.json`, `severe_alerts.json`, and `sparse_offline.json`.

## Verification

- `./scripts/phase54-weather-assert.sh -s 2` passed with `FAIL=0 FINDINGS=0`.
- `./scripts/phase54-weather-assert.sh --quick` passed with `FAIL=0 FINDINGS=0`.
- `qmlformat -n` on all authored QML components passed with zero errors.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
