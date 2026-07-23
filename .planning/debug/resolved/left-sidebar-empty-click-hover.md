# Debug: Left sidebar opens on empty click / top-left hover

**Gap:** G-02-13  
**Severity:** major  
**Status:** diagnosed  
**Date:** 2026-07-23

## Symptoms

- Clicking empty space on the left half of the top bar opens the left sidebar
- Moving the mouse into the left top corner also opens the left sidebar
- Expected: left sidebar opens only when clicking the left-sidebar button (distro icon)

## Root Cause

Two independent open paths, neither is the LeftSidebarButton:

### 1. Empty-bar click — `BarContent.qml` `barLeftSideMouseArea`

```qml
// BarContent.qml ~65-68
onPressed: event => {
    if (event.button === Qt.LeftButton)
        GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
}
```

`barLeftSideMouseArea` is anchored from `parent.left` to `middleSection.left` (entire left half). Any left-click on empty space in that region toggles the left sidebar. `LeftSidebarButton` also toggles on its own `onPressed` — the region handler is redundant for intentional opens and wrong for empty clicks.

### 2. Top-left corner hover — `ScreenCorners.qml` + `clicklessCornerEnd`

Live config has:

- `sidebar.cornerOpen.enable: true`
- `sidebar.cornerOpen.clickless: false` (so plain `onEntered` does not open)
- `sidebar.cornerOpen.clicklessCornerEnd: true` ← this is the hover path
- `cornerRegionWidth: 250`, `cornerRegionHeight: 5`

```qml
// ScreenCorners.qml onPositionChanged
if (correctX && correctY)
    screenCorners.actionForCorner[cornerPanelWindow.corner]();
// TopLeft → GlobalStates.sidebarLeftOpen = !...
```

Moving the pointer into the extreme left edge of the top-left corner region (≤2px from left) fires the toggle without a click. That matches “hovering in the left top corner opens the left sidebar.”

Logs (`Anime.qml` / `AiChat.qml` `commandPrefix` null, `ToolbarTabBar` null `x`) are side effects of the sidebar loading AI/Anime panes — not the open trigger.

## Fix direction

1. **Bar empty click:** Remove the left-sidebar toggle from `barLeftSideMouseArea.onPressed`. Keep brightness scroll / ScrollHint. Opening stays on `LeftSidebarButton.onPressed` only.
2. **Corner hover:** Disable left-corner open for this setup — either:
   - set `sidebar.cornerOpen.enable: false` (disables all corner sidebar opens), or
   - set `clicklessCornerEnd: false` and leave click-to-open on corners if desired, or
   - remove/no-op TopLeft/BottomLeft entries in `actionForCorner` while keeping right corners.

Preferred for UAT intent (“only when I click on it” = the button): remove bar empty-click toggle + dual-write `cornerOpen.enable: false` (or `clicklessCornerEnd: false` + disable left corner actions). Simplest user-aligned fix: disable corner open entirely + strip left bar empty-click toggle.

## Artifacts

| Path | Issue |
|------|--------|
| `.config/quickshell/modules/ii/bar/BarContent.qml` | left half click toggles sidebar |
| `.config/quickshell/modules/ii/screenCorners/ScreenCorners.qml` | TopLeft/BottomLeft corner actions + clicklessCornerEnd hover |
| `~/.config/illogical-impulse/config.json` | `sidebar.cornerOpen.*` live values |
| `.config/quickshell/modules/common/Config.qml` | defaults for cornerOpen |

## Missing

- [ ] Strip `GlobalStates.sidebarLeftOpen` toggle from `barLeftSideMouseArea.onPressed`
- [ ] Disable corner-open path that opens left sidebar without button click (enable false and/or clicklessCornerEnd false + left actions)
- [ ] Dual-write Config + live JSON if changing cornerOpen defaults
- [ ] Leave `LeftSidebarButton` as sole open/close control for left sidebar
