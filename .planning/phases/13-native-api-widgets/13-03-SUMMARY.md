---
phase: 13-native-api-widgets
plan: 03
subsystem: quickshell-widgets
tags: [quickshell, qml, widgets, mpris, systemtray, hyprland]

requires:
  - phase: 13-native-api-widgets
    provides: AudioService, MprisService, HyprWorkspaces, widgets/qmldir, WorkspacesWidget, and VolumeWidget from Plans 13-01 and 13-02
provides:
  - MusicWidget bound to MprisService with metadata display, tooltip, and togglePlaying click
  - TrayWidget bound to SystemTray.items with IconImage rendering, item activation, native QsMenuAnchor menus, and HyprlandFocusGrab dismissal
  - BarContent composition replacing placeholders with WorkspacesWidget, MusicWidget, VolumeWidget, and TrayWidget
affects: [13-native-api-widgets, 14-script-backed-widgets, 15-popup-panels, 16-polish-and-parity]

tech-stack:
  added: [Quickshell.Services.SystemTray consumer, Quickshell.Widgets IconImage consumer, Quickshell QsMenuAnchor consumer]
  patterns: [item-relative tray menu anchoring, ModulePill data slot for support objects, MouseArea hover state for tooltips]

key-files:
  created:
    - .config/quickshell/widgets/MusicWidget.qml
    - .config/quickshell/widgets/TrayWidget.qml
  modified:
    - .config/quickshell/BarContent.qml
    - .config/quickshell/ModulePill.qml
    - .config/quickshell/widgets/VolumeWidget.qml

key-decisions:
  - "Right BarGroup order is MusicWidget, VolumeWidget, TrayWidget so the variable-width music pill sits left of the stable volume/tray controls."
  - "Tray menus use item-relative QsMenuAnchor anchoring instead of anchor.window because anchor.window produced proxied-window warnings at runtime."
  - "ModulePill now exposes inner.data, not inner.children, so planned non-visual support objects such as Process, QsMenuAnchor, and HyprlandFocusGrab can live inside widget roots."

patterns-established:
  - "Use MouseArea.hoverEnabled plus containsMouse for ModulePill tooltips; do not place HoverHandler directly in ModulePill content."
  - "Place tray menu anchors against the clicked Item and dismiss through HyprlandFocusGrab without grabFocus."

requirements-completed: [AUDIO-03, TRAY-01]

duration: 24 min
completed: 2026-05-04
---

# Phase 13 Plan 03: Music, Tray, and Bar Composition Summary

**Native MPRIS music and SystemTray widgets wired into the Quickshell bar with placeholder pills removed.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-05-04T15:54:00Z
- **Completed:** 2026-05-04T16:18:07Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added `MusicWidget.qml` (48 lines) with `MprisService.activePlayer`, `trackArtist` / `trackTitle` / `trackAlbum`, 30-character truncation, `No track` fallback, `togglePlaying()`, disabled opacity, and metadata tooltip.
- Added `TrayWidget.qml` (79 lines) with `SystemTray.items`, 21px `IconImage` delegates, left-click activation, right-click `QsMenuAnchor`, `HyprlandFocusGrab`, NeedsAttention tint, and `\uf128` fallback glyph.
- Modified `BarContent.qml` to import `qs.widgets`, remove all Phase 12 placeholder labels, keep the center group empty for Phase 14, and render the right group as `MusicWidget`, `VolumeWidget`, `TrayWidget`.
- Preserved `BarContent.qml`'s PanelWindow, `WlrKeyboardFocus.None`, background, DropShadow, and RowLayout anchor structure.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement MusicWidget.qml** - `771743e` (feat)
2. **Task 2: Implement TrayWidget.qml** - `96d5cda` (feat)
3. **Deviation fix: make wired widgets load cleanly** - `14bc5f8` (fix)
4. **Task 3: Wire BarContent.qml** - `6095818` (feat)

## Files Created/Modified

- `.config/quickshell/widgets/MusicWidget.qml` - MPRIS music pill with safe text-only metadata bindings and click-to-toggle playback.
- `.config/quickshell/widgets/TrayWidget.qml` - Native SNI tray pill with icon rendering, menu anchoring, and focus-grab dismissal.
- `.config/quickshell/BarContent.qml` - Adds `import qs.widgets` and composes left/workspaces, empty center, and right/music-volume-tray.
- `.config/quickshell/ModulePill.qml` - Deviation fix: default content alias widened to `inner.data` so support QObjects do not break widget roots.
- `.config/quickshell/widgets/VolumeWidget.qml` - Deviation fix: imports `QtQuick.Controls` and uses `MouseArea.containsMouse` for tooltip hover.

## Verification

- MusicWidget acceptance greps passed: service import, Local import, `visible: MprisService.hasPlayer`, `togglePlaying()`, singular track fields, `Text.ElideRight`, `canControl`, `No track`, no `playPause`, no plural `artists`, no bare `.title`, no `Process`, no `Hyprland.dispatch`.
- TrayWidget acceptance greps passed: `Quickshell.Widgets`, `Quickshell.Services.SystemTray`, `Quickshell.Hyprland`, `IconImage`, `SystemTray.items`, `modelData.activate`, `QsMenuAnchor`, `modelData.menu`, `HyprlandFocusGrab`, `Status.NeedsAttention`, `Colours.critical`, 21px icon size, no `grabFocus`, no `Process`.
- BarContent acceptance greps passed: `import qs.widgets`, all four widget instantiations, `WlrKeyboardFocus.None`, `RowLayout`, and no `Left` / `Center` / `Right` placeholder text or `// D-01 placeholder`.
- `timeout 5 quickshell --no-color --path .config/quickshell` passed outside the sandbox: Quickshell emitted `Configuration Loaded` with no QML warnings/errors; exit code 124 was the expected timeout stopping the long-running shell.

## Manual UAT Outcomes

Interactive pointer UAT was not performed. Automated load and grep gates passed; live interaction checks remain for phase verification.

| Criterion | Outcome |
|-----------|---------|
| Music hidden with no MPRIS player | Not run - requires live media-session manipulation. |
| Music visible with artist/title | Not run - requires Spotify/mpv/playerctl source. |
| Click music toggles playback | Not run - pointer action not performed. |
| Music tooltip shows metadata lines | Not run - hover action not performed. |
| Long music title truncates at 30 chars | Not run visually; eager truncation and `Text.ElideRight` are present. |
| Tray SNI icons render at 21px | Not run visually; `quickshell` loaded with `SystemTray.items` binding. |
| Tray right-click opens native menu | Not run - pointer action not performed. |
| Outside-click dismisses menu without keyboard focus theft | Not run; `HyprlandFocusGrab` present and no `grabFocus`. |
| NeedsAttention tint observed | Not observed - requires an SNI app in NeedsAttention state. |
| Icon failure fallback observed | Not observed - requires a broken SNI icon source. |

## Decisions Made

- Kept the right BarGroup order specified by the plan: `MusicWidget`, `VolumeWidget`, `TrayWidget`.
- Used item-relative `QsMenuAnchor` positioning for tray menus. This preserves the intended below-icon menu placement and avoids the runtime warnings produced by assigning `anchor.window` from a proxied window.
- Treated the ModulePill and VolumeWidget runtime errors as Rule 3 blocking deviations because the final bar could not load with the planned widgets instantiated.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] ToolTip and HoverHandler made widgets fail when instantiated**
- **Found during:** Task 3 (BarContent wiring)
- **Issue:** `MusicWidget` and existing `VolumeWidget` used `ToolTip` without `QtQuick.Controls`; `HoverHandler` could not be assigned to `ModulePill`'s visual-only content alias.
- **Fix:** Added `QtQuick.Controls` where needed and switched tooltip hover state to `MouseArea.hoverEnabled` / `containsMouse`.
- **Files modified:** `.config/quickshell/widgets/MusicWidget.qml`, `.config/quickshell/widgets/VolumeWidget.qml`
- **Verification:** Quickshell load advanced past both ToolTip/HoverHandler errors; final load emitted `Configuration Loaded` with no warnings/errors.
- **Committed in:** `14bc5f8`

**2. [Rule 3 - Blocking] ModulePill rejected non-visual support objects**
- **Found during:** Task 3 (BarContent wiring)
- **Issue:** Planned widget children such as `Process`, `QsMenuAnchor`, and `HyprlandFocusGrab` are QObjects, but `ModulePill` only accepted `inner.children` QQuickItems.
- **Fix:** Changed `ModulePill`'s default property alias to `inner.data`; visual sizing still uses `childrenRect`.
- **Files modified:** `.config/quickshell/ModulePill.qml`
- **Verification:** Final `quickshell` smoke load succeeded with all Phase 13 widgets instantiated.
- **Committed in:** `14bc5f8`

**3. [Rule 3 - Blocking] Tray menu anchor.window produced runtime warnings**
- **Found during:** Task 2/3 Quickshell smoke load
- **Issue:** Assigning `anchor.window` from the component's proxied window produced warnings: "not a quickshell window."
- **Fix:** Switched right-click anchoring to `menuAnchor.anchor.item = trayItem` with a below-icon `anchor.rect`.
- **Files modified:** `.config/quickshell/widgets/TrayWidget.qml`
- **Verification:** Final `quickshell` smoke load emitted `Configuration Loaded` with no warnings/errors.
- **Committed in:** `96d5cda`

---

**Total deviations:** 3 auto-fixed (blocking runtime/load issues).
**Impact on plan:** All fixes were required for the planned widgets to load. No shell-script fallback or architecture change was introduced.

## Issues Encountered

- The first sandboxed Quickshell smoke check failed because the sandbox could not access `/run/user/1000` and the Wayland/X display. Rerunning with user-session access exposed real QML errors, which were fixed and revalidated.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 13 now has all three summaries and all six requirement IDs covered across Plans 13-01, 13-02, and 13-03. Phase 14 can consume the widget/service structure after phase verification, with live manual UAT still needed for pointer interactions and specific tray/media states.

## Self-Check: PASSED

- Found `.config/quickshell/widgets/MusicWidget.qml`.
- Found `.config/quickshell/widgets/TrayWidget.qml`.
- Found `.config/quickshell/BarContent.qml`.
- Found task commits `771743e`, `96d5cda`, `14bc5f8`, and `6095818`.
- Re-ran automated acceptance greps for all three tasks.
- Re-ran Quickshell load smoke test with final composition.

---
*Phase: 13-native-api-widgets*
*Completed: 2026-05-04*
