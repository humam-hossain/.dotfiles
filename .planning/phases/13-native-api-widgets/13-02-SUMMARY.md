---
phase: 13-native-api-widgets
plan: 02
subsystem: quickshell-widgets
tags: [quickshell, qml, widgets, hyprland, pipewire]

requires:
  - phase: 13-native-api-widgets
    provides: AudioService and HyprWorkspaces service singletons from Plan 13-01
provides:
  - qs.widgets qmldir manifest pre-registering WorkspacesWidget, VolumeWidget, MusicWidget, and TrayWidget
  - WorkspacesWidget bound to HyprWorkspaces with click activation and static wheel dispatch
  - VolumeWidget bound to AudioService with pavucontrol launch, mute toggle, wheel volume steps, and sink tooltip
affects: [13-native-api-widgets, 14-script-backed-widgets, 15-popup-panels]

tech-stack:
  added: [Quickshell.Hyprland widget consumer, Quickshell.Io Process consumer]
  patterns: [Local.ModulePill widget roots, no-version non-singleton qmldir registration, static dispatch and Process command sinks]

key-files:
  created:
    - .config/quickshell/widgets/qmldir
    - .config/quickshell/widgets/WorkspacesWidget.qml
    - .config/quickshell/widgets/VolumeWidget.qml
  modified: []

key-decisions:
  - "Pre-register all four Phase 13 widgets in widgets/qmldir so Plan 13-03 can add MusicWidget and TrayWidget without touching the manifest."
  - "Keep empty-vs-occupied workspace differentiation deferred per A4; all listed non-active workspaces render with Colours.textColor."
  - "Keep Hyprland dispatch and pavucontrol launch command surfaces static to satisfy T-13-HYP-02 and T-13-VOL-01."

patterns-established:
  - "Widget components live under .config/quickshell/widgets and import the root ModulePill via import \"../\" as Local."
  - "Workspaces use per-glyph click MouseAreas plus a pill-wide wheel-only MouseArea with static Hyprland.dispatch calls."
  - "Volume uses a literal Process command array and routes wheel input through AudioService.bumpVolume(step)."

requirements-completed: [WS-01, WS-02, WS-03, AUDIO-01]

duration: 6 min
completed: 2026-05-04
---

# Phase 13 Plan 02: Workspaces and Volume Widgets Summary

**Quickshell widget namespace with live Hyprland workspace controls and PipeWire volume controls.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-04T16:00:27Z
- **Completed:** 2026-05-04T16:05:58Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added `qs.widgets` registration for all four Phase 13 widgets, including Plan 13-03's `MusicWidget` and `TrayWidget`.
- Added `WorkspacesWidget` with id-sorted `HyprWorkspaces.workspaces`, active/urgent color states, click activation, and static wheel dispatch.
- Added `VolumeWidget` with default-sink visibility, threshold glyphs, mute opacity, pavucontrol launch, right-click mute, wheel volume steps, and a diagnostic sink tooltip.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create widgets/qmldir registering all four widgets** - `b81323a` (feat)
2. **Task 2: Implement WorkspacesWidget.qml** - `37b9794` (feat)
3. **Task 3: Implement VolumeWidget.qml** - `b1a7eff` (feat)

## Files Created/Modified

- `.config/quickshell/widgets/qmldir` - 4 lines; non-singleton registrations for Workspaces, Volume, Music, and Tray widgets.
- `.config/quickshell/widgets/WorkspacesWidget.qml` - 53 lines; Hyprland workspace glyph row with click and wheel interactions.
- `.config/quickshell/widgets/VolumeWidget.qml` - 62 lines; PipeWire default-sink volume pill with pavucontrol and mute/scroll controls.

## Verification

- Task 1 grep checks passed: all four manifest lines present, no `singleton`, no `1.0`, 4 total lines.
- Task 2 grep checks passed: required imports, `HyprWorkspaces.workspaces`, `modelData.activate()`, both static `Hyprland.dispatch("workspace e+1")` / `e-1` calls, workspace glyphs, `Colours.accent`, `Colours.critical`, pointer cursor, and no dispatch interpolation/concatenation.
- Task 3 grep checks passed: required imports, `visible: AudioService.defaultSink !== null`, literal `command: ["pavucontrol"]`, `startDetached()`, `toggleMute()`, `bumpVolume(step)`, `5 * Math.sign(...)`, volume glyphs, mute opacity binding, tooltip, sink name, and no command interpolation/concatenation.
- Plan-level checks passed: all three files exist, `BarContent.qml` is unchanged since Plan 13-01 metadata commit, and both threat-model negative greps pass.
- `timeout 5 quickshell --no-color --path .config/quickshell` passed outside the sandbox: Quickshell emitted `Configuration Loaded`; exit code 124 was the expected timeout stopping the long-running shell. No QML warnings/errors mentioned `WorkspacesWidget` or `VolumeWidget`.

## Manual UAT Outcomes

The executor did not perform pointer/display UAT that would mutate the active Hyprland session. These remain for the Phase 13 verifier once Plan 13-03 wires the widgets into `BarContent.qml`.

| Criterion | Outcome |
|-----------|---------|
| Reactive workspace add/remove | Not run - widget is registered but not yet instantiated by `BarContent.qml`. |
| Active workspace highlight color = `#cba6f7` | Not run - requires live visual inspection after Plan 13-03 composition. |
| Workspace click activates target workspace | Not run - requires pointer interaction after Plan 13-03 composition. |
| Workspace scroll cycles forward/back | Not run - requires pointer wheel interaction after Plan 13-03 composition. |
| Volume reactive update within 500 ms | Not run - requires live PipeWire interaction after Plan 13-03 composition. |
| Click opens pavucontrol | Not run - requires pointer interaction after Plan 13-03 composition. |
| Mute icon swap and 60% opacity | Not run - requires live audio mute interaction after Plan 13-03 composition. |
| Urgent workspace override fires | Not run - depends on Plan 01 urgent rawEvent payload behavior and live urgent-window test. |

## Decisions Made

- Followed the plan's shared-file conflict strategy: Plan 13-02 owns `widgets/qmldir` and Plan 13-03 should only add `MusicWidget.qml` and `TrayWidget.qml`.
- Applied A4 as planned: empty-vs-occupied differentiation is not implemented because the current Hyprland workspace surface does not expose reliable occupancy. `Colours.subtextColor` should be revisited in Phase 16 only if UAT shows the two-state workspace display is insufficient.
- Kept `BarContent.qml` unchanged so Plan 13-03 can compose all four widgets at once.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- The first sandboxed Quickshell smoke check failed because the sandbox could not access `/run/user/1000` and the Wayland/X display. Rerunning the same smoke check outside the sandbox loaded the config successfully.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 13-03 can add `MusicWidget.qml` and `TrayWidget.qml` without modifying `widgets/qmldir`, then update `BarContent.qml` to import `qs.widgets` and instantiate all four Phase 13 widgets.

## Self-Check: PASSED

- Found `.config/quickshell/widgets/qmldir`.
- Found `.config/quickshell/widgets/WorkspacesWidget.qml`.
- Found `.config/quickshell/widgets/VolumeWidget.qml`.
- Found `.planning/phases/13-native-api-widgets/13-02-SUMMARY.md`.
- Found task commits `b81323a`, `37b9794`, and `b1a7eff`.

---
*Phase: 13-native-api-widgets*
*Completed: 2026-05-04*
