---
phase: 54-multi-modal-popup-inspector-interactive-graphs
plan: 03
subsystem: quickshell-weather
tags: [quickshell, qml, weather, canvas, splines, monotone-cubic, graph, scrub-overlay]
requires:
  - phase: 54-multi-modal-popup-inspector-interactive-graphs
    plan: 02
provides:
  - restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml
affects:
  - quickshell-bar-weather
tech-stack:
  added: []
  patterns:
    - Fritsch-Carlson Monotone Cubic Spline interpolation on Canvas 2D
    - Dual-tier forecast graph (upper 70% splines, lower 30% precipitation bars)
    - Zero-repaint interactive hover scrub overlay (pure QML items tracking mouseX)
    - Event-driven Canvas rendering gated strictly behind popupActive
key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml
  modified:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml
    - scripts/phase54-weather-assert.sh
key-decisions:
  - "D-54-14/15: WeatherGraph renders dual temperature splines using Fritsch-Carlson monotone cubic spline interpolation with zero overshoot"
  - "D-54-18/19: Dual-tier layout with upper 70% temperature curves and lower 30% hourly rain columns colored deep blue when precipMM > 2.5mm"
  - "D-54-20/21: Zero-repaint hover scrub overlay with floating tooltip pill snaps to nearest slot without calling requestPaint()"
  - "D-54-22: Canvas rendering strictly gated behind popupActive and data updates for quiescent idle CPU <= 1.68%"
requirements-completed:
  - GRAPH-01
  - GRAPH-02
  - GRAPH-03
  - GRAPH-04
duration: 4 min
completed: 2026-10-10
coverage:
  - deliverable: "WeatherGraph Canvas 2D dual splines and rain bars"
    verification:
      kind: command
      ref: "./scripts/phase54-weather-assert.sh -s 3"
      status: pass
    human_judgment: false
  - deliverable: "Zero-repaint interactive hover scrub overlay"
    verification:
      kind: command
      ref: "./scripts/phase54-weather-assert.sh -s 3"
      status: pass
    human_judgment: false
  - deliverable: "WeatherPopup layout integration"
    verification:
      kind: command
      ref: "./scripts/phase54-weather-assert.sh -s 3"
      status: pass
    human_judgment: false
---

# Phase 54 Plan 03: WeatherGraph Dual Splines, Precipitation Bars & Scrub Tooltip Summary

Interactive 24-hour forecast graph delivered via `WeatherGraph.qml` with dual Canvas 2D temperature splines using Fritsch-Carlson monotone cubic spline interpolation, dynamic high/low guidelines, hourly precipitation probability bars, zero-repaint QML hover scrub overlay, and event-driven rendering strictly gated behind `popupActive`.

## Accomplishments

1. **Authored `WeatherGraph.qml` Spline & Bar Engine**:
   - Implemented Fritsch-Carlson Monotone Cubic Spline interpolation algorithm computing tangent slopes and clamping weights ($\alpha^2 + \beta^2 \le 9$) to eliminate overshoot and oscillation.
   - Normalized incoming WWO hourly data by explicitly filtering out the day roll-up slot (`slot.time !== "24"`), yielding strictly 24 hourly data columns.
   - Rendered solid actual temperature spline with subtle vertical linear gradient fill (`Appearance.colors.colPrimary` to transparent) and dashed feels-like temperature spline (`Appearance.colors.colSecondary`).
   - Drew dynamic 24-hour high/low guidelines with 1°C padding headroom and horizontal dotted rules with text degree labels.
   - Rendered lower ~30% tier hourly rain columns mapping height to rain chance % (0–100%) and deepening color saturation from primary cyan to saturated deep blue (`#1976D2`) when precipitation volume exceeds 2.5mm.
   - Formatted X-axis 3-hour timestamp labels (`Now`, `03:00`, `06:00`, ...).
2. **Zero-Repaint Interactive Hover Scrub Overlay**:
   - Implemented pure QtQuick visual overlay (`Rectangle` hairline, `Rectangle` snap dot, and floating tooltip pill) tracking `MouseArea.mouseX` without calling `Canvas.requestPaint()`.
   - Tooltip pill snaps to nearest hourly slot showing `[Time] • [Temp°C] (Feels [XX°C]) • [Rain % / mm]`.
   - Gated Canvas `requestPaint()` strictly behind `popupActive === true` and `Weather.onHourlyChanged` to preserve quiescent idle CPU $\le 1.68\%$.
3. **Integrated into `WeatherPopup.qml`**:
   - Positioned `WeatherGraph` at position 3 directly beneath `WeatherHeroCard`.
4. **Enriched Assert Harness Section 3**:
   - Validated Fritsch-Carlson spline AST, roll-up slot filtering, zero-repaint invariant, and headless Node.js mathematical evaluation over 24-hour test fixtures.

## Verification

- `./scripts/phase54-weather-assert.sh -s 3` passed with `FAIL=0 FINDINGS=0`.
- `./scripts/phase54-weather-assert.sh --quick` passed with `FAIL=0 FINDINGS=0`.
- `qmlformat -n` on all authored QML components passed with zero errors.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
