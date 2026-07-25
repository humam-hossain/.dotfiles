---
phase: 03-system-audio-modules
plan: 03
subsystem: ui
tags: [quickshell, qml, resource-ring, dual-threshold, labelText, TextMetrics, bar-05, bar-06, bar-07]

requires:
  - phase: 03-system-audio-modules
    provides: dual-write threshold keys and Wave 0 assert (03-01/03-02)
provides:
  - Resource.qml dual-threshold color ladder (isError / isWarning)
  - Resource.qml labelText + TextMetrics capacity-aware width
  - Productized Resource ready for 03-06 CPU/RAM/Disk parent wiring
affects:
  - 03-06 (Resources strip wiring uses errorThreshold + labelText)
  - 03-08 (nyquist verification of BAR-05..07 ring UX)

tech-stack:
  added: []
  patterns:
    - "Dual-tier ring color: isError→colError, isWarning→colPrimary, else→colOnSecondaryContainer"
    - "labelText empty → percent+%; non-empty → as-is capacity string"
    - "TextMetrics text bound to displayed string (not fixed '100')"

key-files:
  created: []
  modified:
    - .config/quickshell/modules/ii/bar/Resource.qml

key-decisions:
  - "Warning tier uses Appearance.colors.colPrimary (no colWarning token exists)"
  - "errorThreshold default 100 keeps error tier off until parent sets lower"
  - "TextMetrics binds to labelText or '100%' so layout matches content"

patterns-established:
  - "Resource color ladder: isError > isWarning > normal via ternary bind on colPrimary"
  - "accountForLightBleeding disabled when either threshold tier active"
  - "Capacity parents set labelText; CPU parents leave empty for percent+% default"

requirements-completed: [BAR-05, BAR-06, BAR-07]

coverage:
  - id: D1
    description: "Resource rings support dual thresholds — warning (colPrimary) then error (colError)"
    requirement: BAR-05
    verification:
      - kind: other
        ref: "rg -n 'errorThreshold|isError|isWarning|colError|colPrimary|colOnSecondaryContainer' .config/quickshell/modules/ii/bar/Resource.qml"
        status: pass
    human_judgment: false
  - id: D2
    description: "Resource supports custom labelText and default percent-with-% via StyledText"
    requirement: BAR-06
    verification:
      - kind: other
        ref: "rg -n 'labelText|TextMetrics|%' .config/quickshell/modules/ii/bar/Resource.qml"
        status: pass
    human_judgment: false
  - id: D3
    description: "TextMetrics width accommodates capacity labels without fixed three-digit sample footgun"
    requirement: BAR-07
    verification:
      - kind: other
        ref: "rg -n 'labelText.length > 0 \\? root.labelText : \"100%\"' .config/quickshell/modules/ii/bar/Resource.qml"
        status: pass
      - kind: other
        ref: "timeout 4 quickshell → Configuration Loaded"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-07-23
status: complete
---

# Phase 3 Plan 03: Dual-threshold Resource Summary

**Resource.qml dual-threshold ring colors (warning→colPrimary, error→colError) plus labelText/TextMetrics for capacity strings and percent+% defaults.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-23T10:02:16Z
- **Completed:** 2026-07-23T10:04:00Z
- **Tasks:** 2/2
- **Files modified:** 1

## Accomplishments

- Added `errorThreshold` with `isError` / `isWarning` / `pct` dual-tier ladder on `ClippedFilledCircularProgress.colPrimary`
- Warning tier uses `Appearance.colors.colPrimary`; error uses `colError`; normal uses `colOnSecondaryContainer`
- Added `labelText` property — empty defaults to `Math.round(percentage*100)%`; non-empty shows capacity string as-is
- Fixed TextMetrics width footgun: metrics bind to `labelText` or `"100%"` instead of bare `"100"`
- MouseArea remains `acceptedButtons: Qt.NoButton` (no click productization on Resource)
- Smoke: `Configuration Loaded` with no Resource API hard errors (old Resources.qml call sites still compile)

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 03-03-01 | Dual-threshold color ladder on Resource ring | fd59b47 | `Resource.qml` |
| 03-03-02 | labelText + TextMetrics for capacity labels | 585838f | `Resource.qml` |

## Files Created/Modified

- `.config/quickshell/modules/ii/bar/Resource.qml` — dual thresholds, labelText, flexible TextMetrics

## Decisions Made

- Warning color token: `Appearance.colors.colPrimary` (no `colWarning` exists — RESEARCH A1 / D-07)
- `errorThreshold` default 100 means error tier off unless parent sets lower (D-13)
- Empty `labelText` → percent with trailing `%` for CPU (D-02); set labelText for RAM/Disk capacity (D-03, D-10)
- Prefer binding TextMetrics to actual displayed string over fixed wide sample when labelText empty

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None — Resource API is complete for parent wiring; parents still use old call sites until 03-06 (intentional, out of scope).

## Threat Flags

None beyond plan threat model. Thresholds remain local desktop metrics (T-03-01); labelText is capacity numbers only (T-03-05); no package installs (T-03-SC accept).

## Issues Encountered

None during plan work. Pre-existing `ToolbarTabBar.qml` TypeError warnings on quickshell smoke are unrelated dirty files (not staged).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Resource.qml productized for 03-06 Resources strip wiring (CPU %, RAM used/total, Disk free/total with dual thresholds)
- Parents must pass `errorThreshold`, `warningThreshold`, and optional `labelText` — defaults preserve pre-03-06 behavior

## Self-Check: PASSED

- FOUND: `.config/quickshell/modules/ii/bar/Resource.qml` (`errorThreshold`, `labelText`, `isError`, `isWarning`)
- FOUND: commit `fd59b47`
- FOUND: commit `585838f`
- FOUND: Configuration Loaded on quickshell smoke

---
*Phase: 03-system-audio-modules*
*Completed: 2026-07-23*
