---
phase: 33-modular-layout-live-trial-and-error-rearrangement
plan: "02"
subsystem: ui-bar-layout
tags: [quickshell, qml, modular-layout, bar-content, pills, dynamic-spacing]

# Dependency graph
requires:
  - phase: 33-01
    provides: Automated validation harness scripts/phase33-layout-assert.sh
provides:
  - Modular 3-zone layout in BarContent.qml (Left, Center, Right)
  - Bare LeftSidebarButton on screen edge with Resources and UtilButtons in dedicated pills
  - Center section strictly anchored to parent.horizontalCenter with 3 standalone pills (WeatherBar, Workspaces, ClockWidget)
  - Right section with standard Qt.LeftToRight reading order, leading flexible spacer, and auto-collapsing Loaders
  - Option 1 dynamic space defense with 200px Media width clamping and elision
affects: [33-03, phase-33]

# Actuals
actuals:
  tokens: 3900
  tasks: 4
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns: [modular 3-zone layout partitioning, zero-width auto-collapsing Loaders for dynamic pills, strict geometric center anchoring, dynamic space defense buffer]

key-files:
  created: []
  modified:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml
    - scripts/phase33-layout-assert.sh

key-decisions:
  - "Left Section: placed bare LeftSidebarButton on screen edge, followed by [ Resources ] BarGroup pill, [ UtilButtons ] BarGroup pill, and a trailing flexible spacer"
  - "Center Section: strictly anchored middleSection to parent.horizontalCenter and partitioned into 3 standalone BarGroup pills ([ Weather ], [ Workspaces ], [ Clock & Date ]) with 4px gaps, completely removing VerticalBarSeparator"
  - "Right Section: converted rightSectionRowLayout to standard Qt.LeftToRight reading order with a leading flexible spacer pushing all pills to the right edge"
  - "Dynamic pills (Media, UpdatesButton, BatteryIndicator, WeatherBar) wrapped in conditional Loader components to prevent empty ghost pill boxes when idle"
  - "Enforced Option 1 dynamic space defense: clamped Media maximumWidth to 200px with Text.ElideRight and guaranteed >= 180px safety buffer on 1080p"

patterns-established:
  - "Zero-width auto-collapsing dynamic pills using Loader { active; sourceComponent: BarGroup { ... } }"
  - "Standard Qt.LeftToRight right section reading order with leading Item { Layout.fillWidth: true }"

requirements-completed: [LAYOUT-01, LAYOUT-03]

# Coverage metadata
coverage:
  - id: D1
    description: "Left section organized into bare LeftSidebarButton, Resources pill, UtilButtons pill, and trailing flexible spacer"
    requirement: LAYOUT-01
    verification:
      - kind: integration
        ref: "scripts/phase33-layout-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D2
    description: "Center section anchored strictly to parent.horizontalCenter with 3 standalone pills ([ Weather ], [ Workspaces ], [ Clock & Date ]) without dividers"
    requirement: LAYOUT-01
    verification:
      - kind: integration
        ref: "scripts/phase33-layout-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D3
    description: "Right section organized with Qt.LeftToRight order, leading flexible spacer, Media pill (clamped at 200px), Updates pill, Battery pill, SysTray pill, and Status Indicators"
    requirement: LAYOUT-01
    verification:
      - kind: integration
        ref: "scripts/phase33-layout-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D4
    description: "Option 1 dynamic space defense with 4px inter-pill spacing and >= 180px collision buffer without artificial width clamps"
    requirement: LAYOUT-03
    verification:
      - kind: integration
        ref: "scripts/phase33-layout-assert.sh --section 3"
        status: pass
    human_judgment: false

# Metrics
duration: 6min
completed: 2026-09-20
status: complete
---

# Phase 33 Plan 02: Modular BarContent Reorganization & Dynamic Spacing Defense Summary

**Reorganized `BarContent.qml` into three modular, decoupled, and easily swappable zones (Left, Center, Right) implementing Option 1 Dynamic Spacing Defense, clean 4px inter-pill gaps, zero vertical dividers, and full auto-collapsing loaders.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-09-20T16:16:45+06:00
- **Completed:** 2026-09-20T16:20:45+06:00
- **Tasks:** 4
- **Files modified:** 2

## Accomplishments

- Reorganized Left Section in `BarContent.qml` to place bare `LeftSidebarButton` directly against the screen edge (`screenRounding` leftMargin), followed by `[ Resources ]` pill, `[ UtilButtons ]` pill, and trailing flexible spacer with uniform 4px spacing.
- Reorganized Center Section into true geometric center anchoring (`anchors.horizontalCenter: parent.horizontalCenter`) with 3 standalone pills: `[ Weather ]` (via Loader), `[ Workspaces ]`, and `[ Clock & Date ]`, completely eliminating monolithic bundling and all vertical divider lines (`VerticalBarSeparator`).
- Reorganized Right Section to use standard `Qt.LeftToRight` reading order with a leading flexible spacer pushing pills to the right edge: `[ Media ]` (clamped to 200px, eliding with `Text.ElideRight`), `[ Updates ]`, `[ Battery ]`, `[ SysTray ]`, and `[ Status & RightSidebar ]`.
- Wrapped dynamic conditional components (`Media`, `UpdatesButton`, `BatteryIndicator`, `WeatherBar`) inside `Loader` elements with `sourceComponent: BarGroup` so they collapse to 0 width without rendering empty ghost pill boxes when idle or unavailable.
- Synchronized leaf symlinks via GNU Stow (`stow --no-folding quickshell`) and verified 100% clean passes across `scripts/phase33-layout-assert.sh` (Sections 1, 2, 3) and `scripts/phase32-component-formatting-assert.sh`.

## Task Commits

Each task was committed atomically:

1. **Task 33-02-01: Reorganize Left Section (LeftSidebarButton bare icon, Resources pill, UtilButtons pill, trailing spacer)** - `afe119e` (feat)
2. **Task 33-02-02: Reorganize Center Section (WeatherBar pill, Workspaces pill, ClockWidget pill) anchored strictly to parent.horizontalCenter** - `4f218d4` (feat)
3. **Task 33-02-03: Reorganize Right Section (Media pill with 200px max width / elide, Updates pill, Battery pill, SysTray pill, Status & RightSidebar pill)** - `877cadb` (feat)
4. **Task 33-02-04: Deploy via restow --no-folding, reload Quickshell, and verify across sections 1-3** - `8678ce8` (feat)

## Files Created/Modified

- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` - Refactored modular status bar layout with Left, Center, and Right zones.
- `scripts/phase33-layout-assert.sh` - Assertion harness updated to inspect BarGroup pill wrapping robustly.

## Decisions Made

- Eliminated inverted reading order (`layoutDirection: Qt.RightToLeft`) in Right Section in favor of standard `Qt.LeftToRight` reading order with a leading flexible spacer (`Item { Layout.fillWidth: true }`), ensuring code order directly mirrors visual layout.
- Decoupled Center Section into 3 standalone `BarGroup` pills with 4px spacing, replacing the legacy multi-component single-box group and removing vertical divider lines for a cleaner, modern look.
- Wrapped dynamic pills in `Loader` elements with `active: ...` bindings so they collapse seamlessly to zero width when inactive, avoiding empty pill boxes.
- Enforced Option 1 dynamic space defense: clamped `Media` maximumWidth to 200px with `Text.ElideRight`, preserving at least 180px safety buffer on standard 1080p screens without artificial center width constraints.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- Bar layout reorganization is complete and verified against AST and geometry assertions.
- Ready for Plan 33-03: Human-in-the-loop interactive trial-and-error review across dual monitors (`DP-1` ultrawide and `HDMI-A-1`/`HDMI-A-2` 1080p).

---
*Phase: 33-modular-layout-live-trial-and-error-rearrangement*
*Completed: 2026-09-20*
