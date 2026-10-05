---
phase: 53-top-status-bar-weather-pill-component
plan: "01"
subsystem: quickshell-bar
tags:
  - quickshell
  - weather
  - status-bar
  - qml
  - stow
  - leaf-symlink
requirements:
  - BAR-01
  - BAR-02
  - BAR-03
  - BAR-04
status: completed
completed_at: "2026-10-05T17:11:30+06:00"
commits:
  - fb37f9c7  # feat(53-01): author status bar weather pill component and deploy overlay leaf symlink
key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml
  modified: []
key-decisions:
  - "D-53-01: Leave BarContent.qml 100% UNTOUCHED to preserve upstream compatibility"
  - "D-53-02: Deploy WeatherBar.qml personal overlay via GNU Stow leaf symlink with .bak preservation of upstream stub"
  - "D-53-03: Use MouseArea as root container to eliminate double-nested BarGroup padding"
  - "D-53-04: Directly bind to modern Weather.current.* telemetry properties"
  - "D-53-05: Absorb all click events and eliminate upstream right-click manual refresh"
  - "D-53-06: Dim text/glyph to m3onSurfaceVariant when stale/offline with cloud_off cold-boot fallback"
  - "D-53-08: Support vertical status bar layout stacking glyph above temperature"
  - "D-53-11: Imminent rain chance badge revealed when probability > 50% in upcoming 3 hours"
  - "D-53-14: Severe alert warning icon displayed dynamically colored by severity"
  - "D-53-15: 3-loop breathing pulse animation (1.0 ↔ 0.4 over 600ms each) for active alerts"
  - "D-53-17: Severe alert takes precedence over imminent rain badge"
  - "D-53-18: Integer Celsius formatted as XX°C in Tiers 0/1 and XX° in Tier 2"
  - "D-53-19: Safe numeric parsing with Math.round and '--' fallback"
  - "D-53-29: Anchor WeatherPopup with 1000ms hover intent delay and expose popupActive"
---

# Plan 53-01 Summary: Top Status Bar Weather Pill Component

## Objective Accomplished
Authored the production-quality top status bar weather pill component `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` as a tracer slice proving the vertical path end-to-end, and deployed it as a GNU Stow personal overlay leaf symlink to `~/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` with safe backup preservation (`WeatherBar.qml.bak`). Kept `BarContent.qml` 100% UNTOUCHED and upstream `vendor/dots-hyprland` completely clean per BAR-01, BAR-02, BAR-03, BAR-04, and decisions D-53-01 through D-53-33.

## Key Changes
1. **WeatherBar Component Architecture (`restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml`)**:
   - Declared with `pragma ComponentBehavior: Bound`.
   - Root element is `MouseArea` (`id: root`), eliminating double-nested `BarGroup` padding while inheriting outer `BarGroup` pill geometry from `BarContent.qml` (L190–200).
   - Set `acceptedButtons: Qt.AllButtons`, `cursorShape: Qt.ArrowCursor`, `hoverEnabled: true`, and absorbed all mouse clicks (`event.accepted = true`), removing deprecated right-click manual refresh.
   - Screen width adaptive resolution for `useShortenedForm` (Tier 0: standard, Tier 1: shortened, Tier 2: hella-shortened).
   - Vertical bar mode support stacking glyph above temperature with `columns: root.vertical ? 1 : -1`.

2. **Telemetry Bindings & Responsive Formatting**:
   - Bound directly to modern `Weather.current.*` properties (`tempC`, `glyph`, `desc`), `Weather.alerts`, and `Weather.hourly`.
   - Formatted temperature via `Math.round(Number(Weather.current.tempC))` with safe `"--"` fallback, appending `°` in Tier 2 and `°C` in Tiers 0/1.
   - Condition glyph rendered as outline Material Symbol (`fill: 0`) at `Appearance.font.pixelSize.large`, with `cloud_off` cold-boot fallback when uninitialized.
   - Stale/offline dimming via `Appearance.m3colors.m3onSurfaceVariant` while preserving neutral `Appearance.colors.colOnLayer1` across all ambient temperatures.
   - 200ms `expressiveEffects` ColorAnimation on color transitions.

3. **Hazard Indicators & Breathing Pulse Animation**:
   - Evaluates maximum `chanceofrain` across the first 3 hours in `Weather.hourly`; reveals `water_drop` + percentage badge when chance > 50% in Tiers 0/1.
   - Active severe alert renders `warning` icon colored via `WeatherGlyphs.getAlertColor` and takes precedence over the rain badge.
   - 3-loop breathing pulse animation (opacity 1.0 ↔ 0.4 over 600ms each with `Easing.InOutSine`) resetting to 1.0 on completion.
   - Both indicators wrapped in fluid `Revealer` components with explicit dimensions.

4. **Popup Wiring & Stow Deployment**:
   - Instantiated `WeatherPopup` with `hoverTarget: root`, inheriting `StyledPopup` 1000ms hover delay and screen boundary clamping.
   - Exposed `readonly property bool popupActive` bound to `weatherPopup.active`.
   - Safely preserved upstream stub as `~/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml.bak`.
   - Symlinked `WeatherBar.qml` to restow source.

## Verification
- `test -s restow/.../WeatherBar.qml && qmlformat -n restow/.../WeatherBar.qml`: PASS
- `test -L ~/.config/.../WeatherBar.qml && test -f ~/.config/.../WeatherBar.qml.bak`: PASS
- `git status --porcelain vendor/dots-hyprland`: PASS (0 lines, pristine vendor hygiene)
- `./arch/dots-hyprland.sh verify --strict`: PASS (FAIL=0 FINDINGS=0)

## Deviations from Plan
None — executed strictly according to plan specifications.

## Self-Check: PASSED
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` exists on disk: YES
- `~/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` symlink exists: YES
- `~/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml.bak` backup exists: YES
- Commits recorded for plan: fb37f9c7
