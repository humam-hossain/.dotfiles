---
phase: 13-native-api-widgets
plan: 01
subsystem: quickshell-services
tags: [quickshell, qml, services, pipewire, mpris, hyprland]

requires:
  - phase: 12-bar-skeleton-and-theme
    provides: Quickshell config root, qs.theme singleton pattern, and Phase 12 bar shell
provides:
  - AudioService singleton wrapping PipeWire default sink state and writes
  - MprisService singleton selecting the active MPRIS player
  - HyprWorkspaces singleton exposing sorted/filtered workspaces and urgent tracking
  - qs.services qmldir registration for Phase 13 widget plans
affects: [13-native-api-widgets, 14-script-backed-widgets, 15-popup-panels]

tech-stack:
  added: [Quickshell.Services.Pipewire, Quickshell.Services.Mpris, Quickshell.Hyprland]
  patterns: [pragma Singleton service wrappers, qmldir singleton registration, PwObjectTracker default-sink binding]

key-files:
  created:
    - .config/quickshell/services/qmldir
    - .config/quickshell/services/AudioService.qml
    - .config/quickshell/services/MprisService.qml
    - .config/quickshell/services/HyprWorkspaces.qml
  modified: []

key-decisions:
  - "Use no-version qmldir singleton registrations to match the existing qs.theme convention."
  - "Keep PipeWire, MPRIS, and Hyprland native APIs behind qs.services wrappers for downstream widgets."

patterns-established:
  - "Service singleton files start with pragma Singleton and a Quickshell Singleton root."
  - "PipeWire audio reads are guarded by PwObjectTracker bound to the current default sink."
  - "Hyprland urgent tracking uses immutable urgentIds reassignment to trigger QML change notifications."

requirements-completed: [WS-01, AUDIO-01, AUDIO-03]

duration: 4 min
completed: 2026-05-04
---

# Phase 13 Plan 01: Service Singletons Summary

**Native Quickshell service wrappers for PipeWire audio, MPRIS player selection, and Hyprland workspace state.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-04T15:53:04Z
- **Completed:** 2026-05-04T15:57:25Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added `qs.services` registration for `AudioService`, `MprisService`, and `HyprWorkspaces`.
- Added `AudioService` with null-guarded default sink state, volume clamping, mute toggling, and direct-child `PwObjectTracker`.
- Added `MprisService` using `MprisPlaybackState.Playing`, with fallback to the first registered player.
- Added `HyprWorkspaces` with sorted/filtered workspace output and best-effort urgent workspace tracking.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create services/qmldir manifest** - `96eb2f4` (feat)
2. **Task 2: Implement AudioService.qml** - `2dad605` (feat)
3. **Task 3: Implement MprisService.qml and HyprWorkspaces.qml** - `63457df` (feat)

## Files Created/Modified

- `.config/quickshell/services/qmldir` - 3-line singleton manifest.
- `.config/quickshell/services/AudioService.qml` - 28-line PipeWire default sink wrapper.
- `.config/quickshell/services/MprisService.qml` - 16-line MPRIS active-player selector.
- `.config/quickshell/services/HyprWorkspaces.qml` - 40-line Hyprland workspace service with urgent map.

## API Surface Delivered

- `AudioService`: `defaultSink`, `volume`, `muted`, `volumePercent`, `sinkName`, `setVolume(percent)`, `bumpVolume(delta)`, `toggleMute()`.
- `MprisService`: `activePlayer`, `hasPlayer`.
- `HyprWorkspaces`: `workspaces`, `urgentIds`, `isUrgent(id)`.

## Verification

- `test -f` checks passed for all four created service files.
- `grep` acceptance checks passed for qmldir registrations, imports, public functions/properties, `Math.max(0, Math.min(1, ...))` volume clamping, `MprisPlaybackState.Playing`, workspace sorting/filtering, and `onRawEvent`.
- `! grep -E ' 1\.0 ' .config/quickshell/services/qmldir` passed.
- `! grep -E "playbackState\s*===\s*['\"]Playing"` passed for `MprisService.qml`.
- `git diff --quiet 3e40fa4..HEAD -- .config/quickshell/BarContent.qml` passed; no widget or bar composition files changed.
- `timeout 5 quickshell --no-color --path .config/quickshell` loaded the config and emitted `Configuration Loaded`; it exited with code 124 only because the timeout stopped the long-running shell. Captured output included no QML warnings/errors mentioning the new services.

## Decisions Made

- Followed the plan's correction to omit `1.0` from `services/qmldir`, matching the existing `theme/qmldir`.
- Used `MprisPlaybackState.Playing` instead of string playback-state comparison.
- Left urgent raw-event parsing as `parseInt(event.data, 10)` per the plan's best-effort Phase 13 scope.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- The first sandboxed Quickshell smoke check could not create `/run/user/1000/quickshell`; rerunning the same command outside the sandbox completed the required smoke check.

## Known Stubs

None.

## Open Questions

- Hyprland `urgent` rawEvent payload parsing was not interactively verified. Follow-up UAT remains: trigger an urgent window on another workspace and confirm `HyprWorkspaces.isUrgent(id)` becomes true, or inspect/log `event.data` if it does not.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 13-02 can import `qs.services` and consume the new `AudioService` and `HyprWorkspaces` APIs. Plan 13-03 can consume `MprisService`.

## Self-Check: PASSED

- Found `.config/quickshell/services/qmldir`.
- Found `.config/quickshell/services/AudioService.qml`.
- Found `.config/quickshell/services/MprisService.qml`.
- Found `.config/quickshell/services/HyprWorkspaces.qml`.
- Found task commits `96eb2f4`, `2dad605`, and `63457df`.

---
*Phase: 13-native-api-widgets*
*Completed: 2026-05-04*
