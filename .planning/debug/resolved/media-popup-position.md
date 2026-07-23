---
status: diagnosed
gap_id: G-02-11
phase: 02-core-bar-modules
created: 2026-07-22T04:38:23Z
---

# Debug: Media controls popup opens at old position

## Symptom

Clicking bar Media opens the media controls popup not under the Media module (now on the right). Position matches pre-rearrange center-left placement.

## Investigation

`Media.qml` only toggles global state:

```qml
GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
```

`MediaControls.qml` PanelWindow:

```qml
anchors {
    top: !Config.options.bar.bottom || Config.options.bar.vertical
    bottom: Config.options.bar.bottom && !Config.options.bar.vertical
    left: !(Config.options.bar.vertical && Config.options.bar.bottom)
    right: Config.options.bar.vertical && Config.options.bar.bottom
}
margins {
    top: ... Appearance.sizes.barHeight
    left: Config.options.bar.vertical
        ? Appearance.sizes.barHeight
        : ((panelWindow.screen.width / 2) - (osdWidth / 2) - widgetWidth)
}
```

Horizontal bar: `anchors.left: true` + left margin = center − osdWidth/2 − widgetWidth → popup sits left-of-center (legacy center-adjacent media).

After D-15, bar Media is on the **right** (before Battery/SysTray/Indicators).

## Root cause

Hard-coded center-left margin never updated when Media moved to the right module order.

## Fix direction

For horizontal bar:

1. Anchor popup toward the **right** (or compute left margin so widget sits under Media).
2. Preferred: `anchors.right: true` with `margins.right` ≈ gap + tray + indicators width, or map from a known right-side offset.
3. Simpler robust approach: right-align with `margins.right: Appearance.sizes.hyprlandGapsOut` (or similar) so popup hangs under the right cluster where Media lives.
4. Preserve vertical-bar positioning path.

## Files

- `.config/quickshell/modules/ii/mediaControls/MediaControls.qml`
- `.config/quickshell/modules/ii/bar/Media.qml` (reference only unless mapFromItem needed)
