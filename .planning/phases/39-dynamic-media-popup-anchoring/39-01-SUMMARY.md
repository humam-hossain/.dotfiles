---
phase: 39-dynamic-media-popup-anchoring
plan: 01
subsystem: ui
tags: [qml, quickshell, media-controls, wayland, layer-shell, stow]

requires:
  - phase: 38-power-profiles-daemon
    provides: power-profiles-daemon integration and test harness pattern
provides:
  - Dynamic MediaControls.qml popup anchoring beneath Media pill
  - Horizontal and vertical boundary clamping with hyprlandGapsOut margins
  - Multi-monitor screen binding via GlobalStates bridge
  - 5-section automated assertion test harness
affects: [41-regression-harness]

actuals:
  tokens: 18000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "mapToItem(null, ...) scene coordinate conversion for cross-component positioning"
    - "HoverHandler multi-monitor disambiguation for global state updates"
    - "Math.max/Math.min clamping with narrow-screen guard and subpixel rounding"

key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/GlobalStates.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml
    - scripts/phase39-media-popup-assert.sh
  modified:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml

key-decisions:
  - "Used HoverHandler instead of MouseArea for multi-monitor pill hover detection to avoid intercepting inner click handlers"
  - "Sentinel value -1 for mediaPillCenterX/Y enables clean upstream fallback when opened via keyboard shortcut or IPC"
  - "Clamping formula includes (maxX < minX) ? minX guard to handle screens narrower than popup width"

patterns-established:
  - "GlobalStates bridge pattern: adding layout-only coordinate properties to desktop singleton for cross-component positioning"
  - "Reactive Connections tracking: dynamically connecting to item geometry changes only while popup is open on the same screen"

requirements-completed: [MEDIA-01, MEDIA-02, INTG-01, INTG-02, INTG-03]

coverage:
  - id: D1
    description: "MediaControls.qml dynamically anchors horizontally beneath the Media pill center with clamped margins"
    requirement: "MEDIA-01"
    verification:
      - kind: unit
        ref: "./scripts/phase39-media-popup-assert.sh --section 3 (headless coordinate clamping math)"
        status: pass
  - id: D2
    description: "Boundary clamping enforces hyprlandGapsOut (5px) margins across standard, ultrawide, and narrow displays"
    requirement: "MEDIA-02"
    verification:
      - kind: unit
        ref: "./scripts/phase39-media-popup-assert.sh --section 3 (T1-T10 assertions)"
        status: pass
  - id: D3
    description: "Multi-monitor screen binding opens popup on the monitor where the pill was clicked"
    requirement: "MEDIA-01"
    verification:
      - kind: integration
        ref: "./scripts/phase39-media-popup-assert.sh --section 4 (state lifecycle)"
        status: pass
  - id: D4
    description: "All QML modifications deployed via restow/quickshell/ leaf symlinks without modifying vendor/dots-hyprland"
    requirement: "INTG-01"
    verification:
      - kind: integration
        ref: "./scripts/phase39-media-popup-assert.sh --section 1 (symlink integrity)"
        status: pass
  - id: D5
    description: "Full 5-section test harness passes with FAIL=0 FINDINGS=0 and dots-hyprland verify --strict clean"
    requirement: "INTG-03"
    verification:
      - kind: e2e
        ref: "./scripts/phase39-media-popup-assert.sh && ./arch/dots-hyprland.sh verify --strict"
        status: pass
---

# Phase 39: Dynamic Media Popup Anchoring Summary

**Dynamically position MediaControls.qml beneath the status bar Media pill with boundary clamping via GlobalStates coordinate bridge and restow overlays**

## Performance

- **Tasks:** 3
- **Commits:** 3
- **Files created:** 3
- **Files modified:** 2

## Accomplishments
- GlobalStates.qml restow overlay with mediaPillCenterX, mediaPillCenterY, and mediaPillScreen bridge properties
- BarContent.qml coordinate capture using mapToItem(null, ...) with HoverHandler multi-monitor disambiguation
- VerticalBarContent.qml vertical coordinate capture with hover gating and reactive layout tracking
- MediaControls.qml overlay with dynamic clamped margins and screen: GlobalStates.mediaPillScreen ?? null binding
- Upstream center fallback when mediaPillCenterX <= 0 (keyboard shortcut / IPC activation)
- 5-section test harness (scripts/phase39-media-popup-assert.sh) validating symlink integrity, QML AST properties, headless clamping math across 6 resolution scenarios, multi-monitor state lifecycle, and strict dots verification

## Files Created/Modified
- `restow/quickshell/.config/quickshell/ii/GlobalStates.qml` - Desktop singleton overlay with coordinate bridge properties
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` - Horizontal bar coordinate capture and hover gating
- `restow/quickshell/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml` - Vertical bar coordinate capture and hover gating
- `restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml` - Popup overlay with clamped margins and screen binding
- `scripts/phase39-media-popup-assert.sh` - 5-section automated assertion test harness

## Decisions Made
- Used HoverHandler for multi-monitor pill hover detection rather than MouseArea to avoid intercepting inner click handlers in Media.qml
- Sentinel value -1 for coordinate properties enables clean fallback to upstream center positioning
- Clamping formula guards against narrow screens with (maxX < minX) ? minX to prevent boundary inversion
- Math.round applied to final clamped values to prevent subpixel blur on Wayland
- Reactive Connections dynamically connect to item geometry only while popup is open on the same screen

## Deviations from Plan
None - followed plan as specified.

---
*Phase: 39-dynamic-media-popup-anchoring*
*Plan: 01*
