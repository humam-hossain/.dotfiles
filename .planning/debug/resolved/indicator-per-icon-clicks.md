---
status: diagnosed
gap_id: G-02-10
phase: 02-core-bar-modules
created: 2026-07-22T04:38:23Z
---

# Debug: Indicator icons need per-icon click actions

## Symptom

Clicking any indicator (or the whole pill) only opens the right sidebar. User wants:

- **Mute (volume)**: toggle output mute
- **Mic**: toggle input mute
- **Bluetooth / Network / Notif** (and xkb if present): open right sidebar as today

## Investigation

In `BarContent.qml` indicators pill:

```qml
RippleButton {
    id: rightSidebarButton
    onPressed: {
        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
    }
    RowLayout {
        // MaterialSymbol mute — display only
        // MaterialSymbol mic — display only
        // HyprlandXkbIndicator
        // MaterialSymbol bluetooth — display only
        // MaterialSymbol network — display only
        // NotificationUnreadCount
    }
}
```

Also `barRightSideMouseArea.onPressed` toggles sidebar on any left-click in the right half.

`Audio.qml` already exposes:

```qml
function toggleMute() { Audio.sink.audio.muted = !Audio.sink.audio.muted }
function toggleMicMute() { Audio.source.audio.muted = !Audio.source.audio.muted }
```

Used by quick toggles (`AudioToggle.qml`, `MicToggle.qml`) but not by bar indicators.

## Root cause

Icons are non-interactive decorations inside a single sidebar-toggle button. No per-icon MouseAreas; audio APIs unused on the bar strip.

## Fix direction

1. Replace display-only mute/mic symbols with clickable wrappers that call `Audio.toggleMute()` / `Audio.toggleMicMute()` and stop propagation so parent doesn't open sidebar.
2. Keep Bluetooth, Network, notif (and optionally xkb / empty pill chrome) opening right sidebar.
3. Ensure `barRightSideMouseArea` doesn't steal mute/mic clicks (child MouseAreas with `propagateComposedEvents` / `acceptedButtons` handling).

## Files

- `.config/quickshell/modules/ii/bar/BarContent.qml`
- `.config/quickshell/services/Audio.qml` (read-only API; no change expected)
