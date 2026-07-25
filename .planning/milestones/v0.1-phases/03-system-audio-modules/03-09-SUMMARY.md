---
phase: 03-system-audio-modules
plan: 09
subsystem: ui
tags: [qml, quickshell, resource-monitor, theming, bar]

requires:
  - phase: 03-system-audio-modules
    provides: "Resource rings, dual thresholds, ResourceUsage service, Appearance theme"
provides:
  - "colWarning amber token in Appearance.colors"
  - "Single-unit used/total labels via formatPair helper"
  - "Dynamic ring↔label spacing for capacity modules"
affects: [bar-visual, uat-gaps]

tech-stack:
  added: []
  patterns:
    - "formatPair() shared-unit label pattern for byte pairs"

key-files:
  created: []
  modified:
    - .config/quickshell/modules/common/Appearance.qml
    - .config/quickshell/modules/ii/bar/Resource.qml
    - .config/quickshell/services/ResourceUsage.qml

key-decisions:
  - "colWarning #FFB74D (Material amber-300) — M3 tokens lack a warning/amber equivalent; fixed hex chosen for clear two-tier visual feedback distinct from both colPrimary (lavender) and colError (red)"
  - "formatPair determines unit (TB/GB) from the larger value, applies once to both numbers"
  - "Dynamic spacing: 4px for capacity labels, 2px for CPU % — keeps short CPU labels tight while giving breathing room to longer used/total strings"

patterns-established:
  - "Shared-unit formatPair(bytesA, bytesB) for compact capacity labels"
  - "Dynamic RowLayout spacing based on labelText presence"

requirements-completed:
  - BAR-05
  - BAR-06

coverage:
  - id: D1
    description: "Warning tier ring uses distinct amber colWarning (#FFB74D) not colPrimary"
    requirement: "BAR-05"
    verification:
      - kind: manual_procedural
        ref: "rg colWarning Appearance.qml Resource.qml — definition + bind confirmed"
        status: pass
    human_judgment: true
    rationale: "Visual distinctness of warning vs default ring color requires human UAT confirmation on live bar"
  - id: D2
    description: "RAM/disk labels read as used/total UNIT with single suffix (e.g. 12.3/31.2 GB)"
    requirement: "BAR-06"
    verification:
      - kind: manual_procedural
        ref: "rg formatPair ResourceUsage.qml — no double-unit formatBytes+formatBytes concatenation"
        status: pass
    human_judgment: true
    rationale: "Label readability on bar needs visual confirmation at runtime"
  - id: D3
    description: "Ring↔label spacing for RAM/disk matches CPU visual rhythm (4px vs 2px)"
    verification:
      - kind: manual_procedural
        ref: "rg spacing Resource.qml — dynamic 4/2 confirmed"
        status: pass
    human_judgment: true
    rationale: "Spacing rhythm is a visual judgment requiring live bar inspection"

duration: 1min
completed: 2026-07-23
status: complete
---

# Phase 03 Plan 09: UAT Gap Closure — Warning Color + Capacity Labels Summary

**Distinct amber warning ring color (colWarning #FFB74D), single-unit capacity labels via formatPair, and dynamic ring↔label spacing for RAM/disk modules**

## Performance

- **Duration:** 1 min
- **Started:** 2026-07-23T14:57:52Z
- **Completed:** 2026-07-23T14:59:34Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Added `colWarning` (#FFB74D amber) token to Appearance.colors — visually distinct from colPrimary (lavender) and colError (red) for clear two-tier ring feedback
- Changed Resource.qml isWarning branch to bind colWarning instead of colPrimary
- Added `formatPair()` helper to ResourceUsage that formats byte pairs with a single shared unit suffix (e.g. `12.3/31.2 GB`)
- Updated memoryUsedTotalString and diskFreeTotalString to use formatPair
- Dynamic ring↔text spacing: 4px for capacity labels, 2px for CPU — matching CPU visual rhythm

## Task Commits

Each task was committed atomically:

1. **Task 1: Distinct warning color token + Resource bind** - `d776ed0` (feat)
2. **Task 2: Single-unit capacity labels** - `9092da8` (feat)
3. **Task 3: Ring↔label spacing for capacity modules** - `2e61f2e` (feat)

## Files Created/Modified
- `.config/quickshell/modules/common/Appearance.qml` - Added colWarning amber token
- `.config/quickshell/modules/ii/bar/Resource.qml` - isWarning → colWarning; dynamic spacing 4/2
- `.config/quickshell/services/ResourceUsage.qml` - formatPair() helper; single-unit label strings

## Decisions Made
- colWarning #FFB74D chosen as Material amber-300 equivalent — M3 tokens lack a warning token, and the warm amber reads clearly on the dark bar distinct from both default and error colors
- formatPair uses the larger of two byte values to determine TB vs GB, then formats both with one trailing unit
- Spacing 4px for capacity (long labels) vs 2px for CPU (short %) — avoids cramped capacity text without affecting CPU layout

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- GAPs G-03-1 and G-03-2 closed
- All Phase 03 plans (01–09) complete; ready for Phase 03 verification/UAT

---
*Phase: 03-system-audio-modules*
*Completed: 2026-07-23*
