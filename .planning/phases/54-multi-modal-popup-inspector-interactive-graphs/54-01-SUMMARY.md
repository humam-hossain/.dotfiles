---
phase: 54-multi-modal-popup-inspector-interactive-graphs
plan: 01
subsystem: quickshell-weather
tags: [quickshell, qml, weather, popup, m3, fixtures, assert-harness]
requires:
  - phase: 53-top-status-bar-weather-pill-component
    plan: 02
provides:
  - tests/fixtures/weather/nominal.json
  - tests/fixtures/weather/severe_alerts.json
  - tests/fixtures/weather/heavy_rain.json
  - tests/fixtures/weather/sparse_offline.json
  - scripts/phase54-weather-assert.sh
  - restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBaseCard.qml
  - restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml
affects:
  - quickshell-bar-weather
tech-stack:
  added: []
  patterns:
    - Material 3 container cards (WeatherBaseCard)
    - StyledPopup with Flickable vertical scroll fallback and screen clamping
key-files:
  created:
    - tests/fixtures/weather/nominal.json
    - tests/fixtures/weather/severe_alerts.json
    - tests/fixtures/weather/heavy_rain.json
    - tests/fixtures/weather/sparse_offline.json
    - scripts/phase54-weather-assert.sh
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBaseCard.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml
  modified: []
key-decisions:
  - "D-54-03/04: WeatherBaseCard standardizes on M3 colLayer2 surface with colOutlineVariant border and 18px outline icon"
  - "D-54-08/09: WeatherPopup locks width to 440px with StyledFlickable height clamping to 80% screen height"
requirements-completed:
  - POPUP-01
duration: 4 min
completed: 2026-10-10
coverage:
  - deliverable: "4 mock JSON test fixtures"
    verification:
      kind: command
      ref: "jq empty tests/fixtures/weather/*.json"
      status: pass
    human_judgment: false
  - deliverable: "Test assertion harness scripts/phase54-weather-assert.sh"
    verification:
      kind: command
      ref: "./scripts/phase54-weather-assert.sh -s 1 && ./scripts/phase54-weather-assert.sh -s 5"
      status: pass
    human_judgment: false
  - deliverable: "WeatherBaseCard M3 container component"
    verification:
      kind: command
      ref: "./scripts/phase54-weather-assert.sh -s 1"
      status: pass
    human_judgment: false
  - deliverable: "WeatherPopup root inspector container with leaf symlink"
    verification:
      kind: command
      ref: "./scripts/phase54-weather-assert.sh -s 1"
      status: pass
    human_judgment: false
---

# Phase 54 Plan 01: Test Fixtures, Harness S1/S5, WeatherBaseCard & Root WeatherPopup Summary

Initial foundation established for the Phase 54 multi-modal weather inspector popup including 4 mock JSON fixtures, executable test assertion harness `scripts/phase54-weather-assert.sh`, Material 3 card container `WeatherBaseCard.qml`, and root inspector container `WeatherPopup.qml` deployed as a GNU Stow leaf symlink shadowing upstream stubs.

## Accomplishments

1. **Authored 4 Mock JSON Test Fixtures**:
   - `nominal.json`: Standard sunny condition with complete 24-hour forecast array, air quality indices, and astronomical data.
   - `severe_alerts.json`: Severe thunderstorm and flash flood advisories to validate alert revealer banners and carousels.
   - `heavy_rain.json`: 100% precipitation probabilities and high mm precipitation for bar chart and scrub assertions.
   - `sparse_offline.json`: Cold-boot uninitialized state with `status: "offline"`, `is_stale: true`, and null telemetry to test safe fallbacks.
2. **Built Assertion Harness `scripts/phase54-weather-assert.sh`**:
   - ASVS L1 non-root enforcement, CLI flags (`-s`, `-q`, `-c`, `-h`), and traps.
   - Section 1: Verifies Stow packaging, symlink targets, un-folded directories, QML syntax via `qmlformat`, and M3 styling contracts.
   - Section 5: Strictly asserts zero submodule git churn in `vendor/dots-hyprland` and executes `./arch/dots-hyprland.sh verify --strict`.
3. **Created `WeatherBaseCard.qml`**:
   - Standardized Material 3 card styling with `Appearance.colors.colLayer2`, `Appearance.rounding.small` (12px), `colOutlineVariant` border, 18px header icon, and `default property alias content: cardContent.data`.
4. **Constructed `WeatherPopup.qml` & Deployed Leaf Symlink**:
   - Wrapped via `StyledPopup` with `implicitWidth: 440`, `StyledFlickable` height clamping up to 80% screen height, and `GlobalStates.activeInspectorCount` lifecycle hooks.
   - Deployed as a leaf symlink to `~/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml` with backup `WeatherPopup.qml.bak` safely preserved.

## Verification

- `jq empty tests/fixtures/weather/*.json` exited with code 0.
- `./scripts/phase54-weather-assert.sh --syntax` exited with code 0.
- `./scripts/phase54-weather-assert.sh -s 1` passed with `FAIL=0 FINDINGS=0`.
- `./scripts/phase54-weather-assert.sh -s 5` passed with `FAIL=0 FINDINGS=0`.
- `qmlformat -n` on all authored QML components passed with zero errors.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
