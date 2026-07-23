---
phase: "02"
plan: "12"
status: complete
gap_closure: true
gap_ids: ["G-02-13"]
started: 2026-07-23T10:36:00+06:00
completed: 2026-07-23T10:37:00+06:00
---

## Summary

Closed gap G-02-13: left sidebar now opens only via `LeftSidebarButton`.

1. **Empty bar click** — Removed `barLeftSideMouseArea.onPressed` toggle of `GlobalStates.sidebarLeftOpen` from `BarContent.qml`. Brightness scroll and ScrollHint unchanged.
2. **Top-left corner hover** — Dual-wrote `sidebar.cornerOpen.enable: false` in `Config.qml` and live `~/.config/illogical-impulse/config.json`. `ScreenCorners.qml` already gates the interaction Loader on that flag, so TopLeft/BottomLeft corner open no longer fires.

`LeftSidebarButton.onPressed` remains the sole bar open/close path for the left sidebar.

## Self-Check: PASSED

- [x] No left-half empty-click toggle in BarContent
- [x] cornerOpen.enable false in Config defaults
- [x] cornerOpen.enable false in live config
- [x] LeftSidebarButton still toggles sidebarLeftOpen
- [x] ScreenCorners Loader still gated on cornerOpen.enable

## Key Files

### Modified
- `.config/quickshell/modules/ii/bar/BarContent.qml` — removed empty left-bar sidebar toggle
- `.config/quickshell/modules/common/Config.qml` — `sidebar.cornerOpen.enable: false`
- `~/.config/illogical-impulse/config.json` — live dual-write (not in repo)

## Deviations

None.
