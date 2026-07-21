---
phase: 02-core-bar-modules
plan: 04
subsystem: ui
tags: [BarContent, systray, network, indicators, D-15, D-19, BAR-03, BAR-04]

requires:
  - phase: 02-core-bar-modules
    provides: left/center rewire; Media/Battery on right
provides:
  - Right LTR Media → Battery → SysTray → Indicators
  - D-19 indicators order with Network.materialSymbol icon-only
affects: [02-05, UAT]

tech-stack:
  added: []
  patterns: [LTR right section + leading fill Item; single-pill sidebar toggle]

key-files:
  created: []
  modified:
    - .config/quickshell/modules/ii/bar/BarContent.qml

key-decisions:
  - "Right section uses LeftToRight (default) with leading fill Item instead of RTL reverse-declare"
  - "Indicators: mute → mic → xkb → Bluetooth → Network → notif (D-19)"
  - "Network remains MaterialSymbol bind only; whole pill toggles sidebar (D-11)"
  - "Weather Loader stays config-gated (D-16)"

requirements-completed: [BAR-03, BAR-04]

coverage:
  - id: D1
    description: Right module order Media Battery SysTray Indicators
    requirement: BAR-03
    verification:
      - kind: other
        ref: "rg Media|BatteryIndicator|SysTray|rightSidebarButton BarContent.qml"
        status: pass
    human_judgment: false
  - id: D2
    description: Network.materialSymbol icon-only + D-19 indicator order
    requirement: BAR-04
    verification:
      - kind: other
        ref: "rg Network.materialSymbol|volume_off|bluetooth BarContent.qml; smoke"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-21
status: complete
---

# Phase 02: Plan 04 Summary

**Finalized right bar LTR order and D-19 indicators with network icon-only on the sidebar pill.**

## Accomplishments

- rightSectionRowLayout: fill Item → Media → Battery → SysTray → Indicators → Weather Loader
- Removed Qt.RightToLeft
- Indicators reorder: mute, mic, xkb, Bluetooth, Network.materialSymbol, notif
- sidebarRightOpen toggle retained on rightSidebarButton
- Weather still gated by Config.options.bar.weather.enable
- Network.qml untouched; no SSID text on bar
- Configuration Loaded smoke green

## Self-Check: PASSED

Note: BarContent right-region edits co-landed with plan 02-03 in the same commit tree because left/center/right share one component.
