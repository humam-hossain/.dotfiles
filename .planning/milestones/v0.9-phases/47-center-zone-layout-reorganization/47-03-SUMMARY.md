---
phase: 47-center-zone-layout-reorganization
plan: 03
subsystem: ui
tags: [quickshell, qml, center-zone, clock, bargroup, layout, gap-closure]

requires:
  - phase: 47-center-zone-layout-reorganization
    provides: Center zone reorganization and 5-section assertion test harness
provides:
  - Simplified leftCenterGroup direct BarGroup component without obsolete MouseArea wrapper or sidebarRightOpen toggle
  - Updated Section 2 AST layout assertions validating direct BarGroup and absence of obsolete toggle
affects: [quickshell, status-bar, verification]

tech-stack:
  added: []
  patterns:
    - "Direct BarGroup hosting for leftCenterGroup matching middleCenterGroup and weatherGroup patterns"
    - "Elimination of redundant MouseArea wrapping and obsolete upstream click toggle handlers"

key-files:
  created: []
  modified:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml
    - scripts/phase47-center-layout-assert.sh

key-decisions:
  - "Eliminated obsolete leftCenterGroup MouseArea wrapper and GlobalStates.sidebarRightOpen toggle per UAT feedback ('it does not need to do anything when i click on it') and debug investigation findings (.planning/debug/sidebar-toggle.md)"
  - "Declared leftCenterGroup directly as a BarGroup component with native implicitWidth/implicitHeight and 250ms emphasizedDecel width animations"

patterns-established:
  - "BarGroup direct hosting pattern across center zone flanking widgets"

requirements-completed:
  - CNTR-01
  - CNTR-02
  - CNTR-03

coverage:
  - id: D-GAP-47-3
    description: "Remove obsolete MouseArea wrapper and sidebarRightOpen toggle from leftCenterGroup in BarContent.qml"
    requirement: CNTR-01
    verification:
      - kind: integration
        ref: "scripts/phase47-center-layout-assert.sh -s 2"
        status: pass
    human_judgment: false
    rationale: ""

  - id: D-ASSERT-47-3
    description: "Update Section 2 assertions in phase47-center-layout-assert.sh and pass full 5-section test suite"
    requirement: CNTR-03
    verification:
      - kind: integration
        ref: "scripts/phase47-center-layout-assert.sh"
        status: pass
      - kind: integration
        ref: "./arch/dots-hyprland.sh verify --strict"
        status: pass
    human_judgment: false
    rationale: ""

duration: 4 min
completed: 2026-09-29
status: complete
---

# Phase 47 Plan 03: Gap Closure G-47-3 Summary

**Simplified `leftCenterGroup` into a direct `BarGroup` without MouseArea wrapper or obsolete sidebar toggle, updating Section 2 AST assertions with 100% test pass rate.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-29T22:15:00+06:00
- **Completed:** 2026-09-29T22:19:00+06:00
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Resolved gap G-47-3 identified during UAT Test 3 and debug investigation `.planning/debug/sidebar-toggle.md`.
- Converted `leftCenterGroup` in `BarContent.qml` from an outer `MouseArea` wrapping `leftCenterGroupContent` to a direct `BarGroup`, matching the pattern established by `middleCenterGroup` and `weatherGroup`.
- Removed obsolete `GlobalStates.sidebarRightOpen` toggle and obsolete identifier `leftCenterGroupContent` while strictly preserving `anchors.right: middleCenterGroup.left`, `anchors.rightMargin: 4`, and `middleSection.anchors.left: leftCenterGroup.left`.
- Updated Section 2 in `scripts/phase47-center-layout-assert.sh` to validate the direct `BarGroup` declaration and absence of obsolete click toggles or nesting.
- Executed all 5 sections of `scripts/phase47-center-layout-assert.sh` passing cleanly with `Failures: 0, Findings: 0` (74+ assertions passing).
- Verified repository strict integrity via `./arch/dots-hyprland.sh verify --strict` with zero git churn in `vendor/dots-hyprland`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Simplify leftCenterGroup to Direct BarGroup in BarContent.qml (CNTR-01, CNTR-03, G-47-3)** - `ebc263ac` (fix)
2. **Task 2: Update Section 2 AST Assertions in phase47-center-layout-assert.sh and Verify Full Test Suite (CNTR-01, CNTR-02, CNTR-03, G-47-3)** - `5799c02f` (test)

## Files Created/Modified

- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` - Converted `leftCenterGroup` to direct `BarGroup` and eliminated obsolete click toggle.
- `scripts/phase47-center-layout-assert.sh` - Updated Section 2 assertions for direct `BarGroup` layout.

## Decisions Made

- Eliminated the obsolete click toggle rather than attempting to pass through clicks to ancestor items, honoring the user's explicit UAT feedback ("it does not need to do anything when i click on it") and correcting an upstream layout legacy where the clock previously resided on the right side of the status bar.
- Leveraged `BarGroup` native implicit dimension calculations and built-in 250ms `emphasizedDecel` width animations.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Gap G-47-3 is resolved.
- Center-zone layout reorganization in Phase 47 is complete with all automated assertions passing.
- Ready for post-gap verification and milestone progression.

---
*Phase: 47-center-zone-layout-reorganization*
*Completed: 2026-09-29*
