---
phase: 02-core-bar-modules
plan: 03
subsystem: ui
tags: [BarContent, workspaces, clock, D-15, BAR-01, BAR-02]

requires:
  - phase: 02-core-bar-modules
    provides: dual-written clock format + secondPrecision
provides:
  - Left region D-15 order with stock Workspaces
  - Center ClockWidget showDate false + UtilButtons
affects: [02-04, 02-05, UAT]

tech-stack:
  added: []
  patterns: [reparent stock ii widgets; no rebuild]

key-files:
  created: []
  modified:
    - .config/quickshell/modules/ii/bar/BarContent.qml

key-decisions:
  - "Workspaces reparented to left after ActiveWindow (BAR-01 placement)"
  - "showDate: false so format string is not duplicated (D-08)"
  - "Media/Battery moved to right (not stripped) for 02-04 LTR finalize"

requirements-completed: [BAR-01, BAR-02]

coverage:
  - id: D1
    description: Left L→R LeftSidebar ActiveWindow Workspaces Resources
    requirement: BAR-01
    verification:
      - kind: other
        ref: "rg LeftSidebarButton|ActiveWindow|Workspaces|Resources BarContent.qml"
        status: pass
    human_judgment: false
  - id: D2
    description: Center clock with showDate false + UtilButtons
    requirement: BAR-02
    verification:
      - kind: other
        ref: "rg 'showDate: false' BarContent.qml; smoke Configuration Loaded"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-21
status: complete
---

# Phase 02: Plan 03 Summary

**Rewired left and center bar regions to D-15: workspaces on left, clock+utils center with showDate false.**

## Accomplishments

- leftSectionRowLayout: LeftSidebarButton → ActiveWindow → Workspaces → Resources
- Single Workspaces + Resources instances (no duplicates)
- Center: ClockWidget { showDate: false } + UtilButtons only
- Media/Battery preserved on right (not stripped — D-17)
- quickshell smoke: Configuration Loaded

## Self-Check: PASSED
