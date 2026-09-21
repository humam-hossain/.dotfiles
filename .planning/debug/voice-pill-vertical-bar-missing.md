# DEBUG: VoicePill missing when bar orientation is left or right (G-37-2)

**Status:** root_cause_found  
**Phase:** 37-bar-layout-integration-dual-monitor-verification-strict-pack  
**Gap:** G-37-2  
**Discovered:** UAT test 2

## Symptoms

- expected: VoicePill renders and maintains proper visibility/suppression behavior across all bar configurations (including left or right vertical bar placement).
- actual: User reported: "so when bar is set to left or right it does not show up"
- reproduction: Open bar settings, set bar position/orientation to left or right. Observe right/bottom status area where VoicePill should be.

## Root Cause

`VoicePill` was only integrated into `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` (which handles horizontal top/bottom bars). Quickshell maintains a separate module for vertical bar layouts in `modules/ii/verticalBar/VerticalBarContent.qml`. `VerticalBarContent.qml` does not import or instantiate `VoicePill` anywhere in its layout hierarchy (`bottomSectionColumnLayout`).

Although `VoicePill.qml` already contains properties anticipating vertical layout (`vertical: false`, `implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : ...`), it was never mounted into `VerticalBarContent.qml`.

## Evidence

- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` L206-210:
  `VoicePill { id: voicePill; Layout.alignment: Qt.AlignVCenter; useShortenedForm: root.useShortenedForm }`
- `~/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml`:
  Grep for `VoicePill` returns 0 results.
- `VoicePill.qml` L62: `readonly property bool isExpanded: effectiveState !== "idle" && useShortenedForm < 2 && !vertical`

## Files Involved

- `restow/quickshell/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml`: Needs `VoicePill` added to `bottomSectionColumnLayout` (or appropriate vertical section) with `vertical: true`.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml`: Ensure vertical layout renders properly (icon centered, appropriate height/width).

## Suggested Fix Direction

1. Add `VoicePill` into `VerticalBarContent.qml` in the bottom status section above or adjacent to `SysTray` with `vertical: true`.
2. Ensure `VoicePill.qml` correctly binds vertical orientation styling and dimensions when hosted in `VerticalBarContent`.
3. Restow quickshell dotfiles to update `~/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml`.
