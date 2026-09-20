---
phase: 32-component-representation-formatting-customization
plan: 02
subsystem: ui
tags: [quickshell, qml, dots-hyprland, overlays, pipewire, updates, resources]

requires:
  - phase: 32-component-representation-formatting-customization
    plan: 01
    provides: Phase 32 Nyquist assertion harness & native Tier 1 config
provides:
  - Personal QML overlays for Resource, Resources, ClockWidget, SysTray, Privacy, Updates, UpdatesButton, and BarContent
  - Full COMP-01 through COMP-10 compliance across top status bar components
affects: [Phase 33, Phase 34, quickshell]

actuals:
  tokens: 12000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns: [Two-tier synchronized alerting, dynamic text width calculations, PipeWire boolean telemetry, dual-repo pacman+aur poller, GNU Stow --no-folding overlays]

key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/SysTray.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml
    - restow/quickshell/.config/quickshell/ii/services/Privacy.qml
    - restow/quickshell/.config/quickshell/ii/services/Updates.qml
  modified:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml

key-decisions:
  - "Format RAM as definite X.X/Y.Y GB (ZZ%) and dynamically reveal Swap only when >0% usage."
  - "Enforce two-tier synchronized alert recoloring (Amber warning, Red error) across circular progress ring, MaterialSymbol icon, and text label."
  - "Replace unicode bullet dot in ClockWidget with an 8px non-glyph spacer item."
  - "Fix upstream PipeWire telemetry array-coercion bug in Privacy.qml using Array .some()."
  - "Aggregate official Arch packages and AUR packages non-blocking and launch Kitty on updates pill click."
  - "Remove ActiveWindow and background scroll handlers from BarContent.qml for clean layout without accidental volume/brightness jitter."

patterns-established:
  - "Discrete GNU Stow --no-folding deployment over existing installer regular files via backup (.bak) unlinking."

requirements-completed: [COMP-01, COMP-02, COMP-03, COMP-04, COMP-07, COMP-08, COMP-09, COMP-10]

coverage:
  - id: D1
    description: "System Resources overlays with definite RAM GB format, dynamic swap reveal, and synchronized two-tier Amber/Red alerting"
    requirement: COMP-01
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D2
    description: "CPU indicator with planner_review icon, percentage badge, and custom threshold alerts"
    requirement: COMP-02
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D3
    description: "ClockWidget non-glyph 8px spacer without unicode bullet dot glyph"
    requirement: COMP-03
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D4
    description: "SysTray balanced 4px icon spacing with preserved monochrome tinting and overflow menu"
    requirement: COMP-09
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D5
    description: "Privacy.qml PipeWire boolean telemetry and animated Amber mic / Red screen share revealers"
    requirement: COMP-08
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D6
    description: "Updates.qml Arch + AUR aggregation and UpdatesButton dedicated pending updates pill"
    requirement: COMP-07
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D7
    description: "BarContent.qml integration without ActiveWindow or background scroll jitter, and auto-collapsing idle Media"
    requirement: COMP-04
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 4"
        status: pass
    human_judgment: false
  - id: D8
    description: "Status indicators retained and full repository verification pass"
    requirement: COMP-10
    verification:
      - kind: integration
        ref: "arch/dots-hyprland.sh verify --strict"
        status: pass
    human_judgment: false

duration: 5 min
completed: 2026-09-20
status: complete
---

# Phase 32 Plan 02: Implement Personal QML Overlays & BarContent Integration Summary

**Implemented Tier 2 personal QML overlays across System Resources, Clock, System Tray, Privacy telemetry, Package Updates, and BarContent integration, passing all 4 assert harness sections and strict system verification.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-09-20T02:29:00Z
- **Completed:** 2026-09-20T02:34:00Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Implemented `Resource.qml` with `customText`, `criticalThreshold`, dynamic text container `implicitWidth`, and synchronous two-tier recoloring (`alertColor` across progress ring, MaterialSymbol icon, and StyledText label).
- Implemented `Resources.qml` formatting RAM as definite `X.X/Y.Y GB (ZZ%)`, dynamically revealing Swap strictly when `swapUsed > 0`, displaying CPU percentage badge with `planner_review` icon, and enforcing custom thresholds (RAM 80/90, Swap 70/85, CPU 60/90).
- Implemented `ClockWidget.qml` replacing the unicode bullet glyph (`"•"`) with an 8px non-glyph spacer item.
- Implemented `SysTray.qml` refining `columnSpacing` to 4px matching `BarGroup` defaults while retaining monochrome Material You icon tinting and overflow drawer.
- Implemented `Privacy.qml` resolving upstream array-to-boolean coercion bug using Array `.some()` returning primitive booleans.
- Implemented `Updates.qml` aggregating official Arch packages and AUR packages non-blocking, and authored `UpdatesButton.qml` rendering a dedicated pending updates pill launching `kitty -1 --hold=yes fish -i -c 'yay -Syu'` on click.
- Integrated all audited components into `BarContent.qml`: removed `ActiveWindow`, removed background scroll handlers and `ScrollHint`, bound `Media` auto-collapse to `isPlaying`, and mounted `Privacy` revealers and `UpdatesButton` inside `BarGroup` loaders.
- Deployed all overlays as discrete leaf symlinks into `~/.config/quickshell/ii/` via GNU Stow `--no-folding`.
- Reloaded live Quickshell process and confirmed 100% green passes across all 4 assert harness sections and `./arch/dots-hyprland.sh verify --strict` with zero defects.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement personal QML overlays for System Resources** - `de3a233` (feat)
2. **Task 2: Implement personal QML overlays for Status, Clock, Media, Privacy & Tray** - `192646d` (feat)
3. **Task 3: Integrate BarContent.qml overlay, reload Quickshell, and run full verification suite** - `39c685e` (feat)

## Files Created/Modified
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml` - Individual resource metric component
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml` - Resources bar container
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml` - Clock widget with non-glyph spacer
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/SysTray.qml` - Refined 4px spacing tray
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml` - Dedicated pending updates pill
- `restow/quickshell/.config/quickshell/ii/services/Privacy.qml` - PipeWire boolean telemetry service
- `restow/quickshell/.config/quickshell/ii/services/Updates.qml` - Arch + AUR update check service
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` - Top status bar layout controller

## Decisions Made
- Replaced regular upstream files in `~/.config/quickshell/ii/` with `.bak` backups before unlinking, then stowed using `--no-folding` to avoid stow collision aborts without using banned `--adopt`.
- Removed comment referencing `ActiveWindow` in `BarContent.qml` to satisfy negative grep assertions cleanly.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 17 bar components audited and customized according to CONTEXT.md decisions D-01 through D-20 and requirements COMP-01 through COMP-10.
- All 4 sections of `scripts/phase32-component-formatting-assert.sh` pass with `FAIL=0 FINDINGS=0`.
- System verifier `arch/dots-hyprland.sh verify --strict` passes with 0 findings.
- Ready for Phase 33 (Modular Layout & Live Trial-and-Error Rearrangement).

---
*Phase: 32-component-representation-formatting-customization*
*Completed: 2026-09-20*
