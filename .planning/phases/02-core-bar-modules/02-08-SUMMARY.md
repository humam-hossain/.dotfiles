---
phase: 02-core-bar-modules
plan: 08
subsystem: ui
tags: [indicators, D-19, Bluetooth, Network, notifications, BAR-04, gap-closure, G-02-7b, G-02-8]

requires:
  - phase: 02-core-bar-modules
    provides: D-19 indicators order with Revealer-gated mute/mic/notif
provides:
  - Always-visible mute/mic/BT/Network/notif strip with state glyphs
  - Clean RowLayout spacing (no orphan margin after Network)
affects: [verify-work, UAT G-02-7b, UAT G-02-8]

tech-stack:
  added: []
  patterns: [always-visible state icons vs hide-when-idle Revealers for bar indicators]

key-files:
  created: []
  modified:
    - .config/quickshell/modules/ii/bar/BarContent.qml

key-decisions:
  - "Mute/mic use state-dependent glyphs (volume_off/up, mic_off/mic) always shown"
  - "Bluetooth always shown; bluetooth_disabled when !available"
  - "xkb stays multi-layout-only (zero width when single layout)"
  - "spacing: realSpacing replaces per-child Layout.rightMargin"

patterns-established:
  - "Pattern: UAT full indicator strip = always-visible MaterialSymbols + layout spacing"

requirements-completed: [BAR-04]

coverage:
  - id: D1
    description: Always-visible mute, mic, Bluetooth, Network, notif in D-19 order
    requirement: BAR-04
    verification:
      - kind: other
        ref: "rg volume_off|volume_up|mic_off|bluetooth|Network.materialSymbol|NotificationUnreadCount BarContent.qml"
        status: pass
      - kind: other
        ref: "timeout 4 quickshell Configuration Loaded"
        status: pass
    human_judgment: true
    rationale: "Visual full strip vs network-only needs human confirmation on live bar"
  - id: D2
    description: No orphan empty gap after Network; pill still toggles sidebarRightOpen; Network icon-only
    requirement: BAR-04
    verification:
      - kind: other
        ref: "rg spacing: realSpacing; GlobalStates.sidebarRightOpen; Network.materialSymbol"
        status: pass
    human_judgment: true
    rationale: "Spacing and pill click feel require visual UAT"

duration: 8min
completed: 2026-07-22
status: complete
---

# Phase 02: Plan 08 Summary

**Always-visible D-19 indicator strip (mute → mic → xkb → BT → Network → notif); no network-only empty pill (G-02-7b, G-02-8).**

## Performance

- **Tasks:** 1/1
- **Files modified:** 1

## Accomplishments

- Replaced mute/mic Revealers with always-visible MaterialSymbols + state glyphs
- Bluetooth always shown (`bluetooth_disabled` when adapters unavailable)
- NotificationUnreadCount always mounted (no idle collapse Revealer)
- RowLayout `spacing: realSpacing` — removed orphan Network rightMargin
- rightSidebarButton still toggles `GlobalStates.sidebarRightOpen`
- Network remains `Network.materialSymbol` (icon-only)
- Smoke: Configuration Loaded

## Task Commits

1. **Task 1: Always-visible mute/mic/Bluetooth/Network/notif with clean spacing** - `71022b9` (feat)

## Files Created/Modified

- `.config/quickshell/modules/ii/bar/BarContent.qml` - indicatorsRowLayout rewrite

## Decisions Made

- Keep HyprlandXkbIndicator multi-layout-only (plan preferred)
- Prefer layout spacing over per-child margins to avoid trailing blank after last visible icon

## Deviations from Plan

None - plan executed exactly as written

## Issues Encountered

None (bluez DBus warning still appears at smoke — expected; disabled glyph still shown)

## User Setup Required

None

## Next Phase Readiness

- All Phase 2 gap-closure plans (02-06..02-08) code-complete
- Ready for `/gsd-verify-work` re-UAT of G-02-4, G-02-7a, G-02-7b, G-02-8

---
*Phase: 02-core-bar-modules*
*Completed: 2026-07-22*
