---
phase: 02-core-bar-modules
plan: 06
subsystem: ui
tags: [clock, popup, StyledPopup, forceActive, BAR-02, gap-closure, G-02-4]

requires:
  - phase: 02-core-bar-modules
    provides: ClockWidget + ClockWidgetPopup on bar; hover-only StyledPopup
provides:
  - forceActive pin on StyledPopup for click-to-hold popup
  - ClockWidget onClicked toggles clock popup pin (hover preserved)
affects: [verify-work, UAT G-02-4]

tech-stack:
  added: []
  patterns: [optional forceActive pin on LazyLoader popups; default false for other consumers]

key-files:
  created: []
  modified:
    - .config/quickshell/modules/ii/bar/StyledPopup.qml
    - .config/quickshell/modules/ii/bar/ClockWidget.qml

key-decisions:
  - "forceActive defaults false so Battery/Resources/Weather stay hover-only"
  - "Click toggles pin; second click unpins; hover still uses containsMouse when unpinned"

patterns-established:
  - "Pattern: click-to-pin via forceActive on StyledPopup without removing hover"

requirements-completed: [BAR-02]

coverage:
  - id: D1
    description: Clicking the bar clock opens/pins ClockWidgetPopup (date/uptime/todos)
    requirement: BAR-02
    verification:
      - kind: other
        ref: "rg forceActive|onClicked StyledPopup.qml ClockWidget.qml"
        status: pass
      - kind: other
        ref: "timeout 4 quickshell Configuration Loaded"
        status: pass
    human_judgment: true
    rationale: "Visual click-to-open and pin behavior needs human UAT confirmation"
  - id: D2
    description: Hover path preserved; no Google Calendar URL
    requirement: BAR-02
    verification:
      - kind: other
        ref: "rg hoverTarget: mouseArea ClockWidget.qml; no calendar.google"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-07-22
status: complete
---

# Phase 02: Plan 06 Summary

**Clock click pins ClockWidgetPopup via StyledPopup.forceActive; hover still works when unpinned (G-02-4).**

## Performance

- **Tasks:** 2/2
- **Files modified:** 2
- **Recovery:** Production commits landed before rate-limit killed executor; SUMMARY closed out by orchestrator (no re-dispatch)

## Accomplishments

- Added `property bool forceActive: false` on StyledPopup; `active` is `forceActive || hover`
- ClockWidgetPopup id `clockPopup`; MouseArea `onClicked` toggles `forceActive`
- hoverTarget remains mouseArea; Battery/Resources/Weather unchanged at default false
- Smoke: `Configuration Loaded`

## Task Commits

1. **Task 1: Add forceActive pin to StyledPopup** - `3a852d3` (feat)
2. **Task 2: Wire ClockWidget click to toggle popup pin** - `14eea6e` (feat)

## Files Created/Modified

- `.config/quickshell/modules/ii/bar/StyledPopup.qml` - optional pin path
- `.config/quickshell/modules/ii/bar/ClockWidget.qml` - onClicked toggle

## Decisions Made

- Default `forceActive: false` preserves other StyledPopup consumers
- Toggle on click (not one-shot open) so second click closes pin

## Deviations from Plan

None - plan executed exactly as written

## Issues Encountered

- gsd-executor hit free-usage rate limit after production commits; SUMMARY written in close-out (safe_resume partial state)

## User Setup Required

None

## Next Phase Readiness

- G-02-4 code path ready for human UAT re-check
- Remaining gap plans: 02-07 (ActiveWindow), 02-08 (indicators strip)

---
*Phase: 02-core-bar-modules*
*Completed: 2026-07-22*
