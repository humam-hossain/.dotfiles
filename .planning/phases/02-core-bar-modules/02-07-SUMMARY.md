---
phase: 02-core-bar-modules
plan: 07
subsystem: ui
tags: [bar, ActiveWindow, workspaces, BAR-01, gap-closure, G-02-7a]

requires:
  - phase: 02-core-bar-modules
    provides: D-15 left layout with ActiveWindow before Workspaces
provides:
  - Left bar without ActiveWindow (sidebar → workspaces → resources)
affects: [verify-work, UAT G-02-7a]

tech-stack:
  added: []
  patterns: [UAT-driven drop of non-essential left modules for workspace room]

key-files:
  created: []
  modified:
    - .config/quickshell/modules/ii/bar/BarContent.qml

key-decisions:
  - "ActiveWindow.qml left on disk; only removed from leftSectionRowLayout instantiation"
  - "Workspaces get Layout.leftMargin: 10 after sidebar for sensible spacing"

patterns-established:
  - "Pattern: comment mark intentional UAT removals (G-02-7a) so reintro is conscious"

requirements-completed: [BAR-01]

coverage:
  - id: D1
    description: Left bar has no ActiveWindow; order LeftSidebarButton → Workspaces → Resources
    requirement: BAR-01
    verification:
      - kind: other
        ref: "rg ActiveWindow BarContent.qml (comment only)"
        status: pass
      - kind: other
        ref: "timeout 4 quickshell Configuration Loaded"
        status: pass
    human_judgment: true
    rationale: "Visual workspace room and click/wheel still need human UAT"

duration: 5min
completed: 2026-07-22
status: complete
---

# Phase 02: Plan 07 Summary

**Removed ActiveWindow from left bar so workspaces have room (G-02-7a); sidebar → workspaces → resources.**

## Performance

- **Tasks:** 1/1
- **Files modified:** 1

## Accomplishments

- Deleted ActiveWindow instantiation from leftSectionRowLayout
- Left intentional comment: UAT G-02-7a
- Workspaces retain right-click overview MouseArea; Resources unchanged
- Smoke: Configuration Loaded

## Task Commits

1. **Task 1: Remove ActiveWindow from leftSectionRowLayout** - `113b10a` (feat)

## Files Created/Modified

- `.config/quickshell/modules/ii/bar/BarContent.qml` - left region without ActiveWindow

## Decisions Made

- Did not delete ActiveWindow.qml from disk
- Added Layout.leftMargin on Workspaces to replace spacing previously from ActiveWindow

## Deviations from Plan

None - plan executed exactly as written

## Issues Encountered

None

## User Setup Required

None

## Next Phase Readiness

- G-02-7a ready for human UAT re-check
- Plan 02-08 closes remaining indicator gaps

---
*Phase: 02-core-bar-modules*
*Completed: 2026-07-22*
