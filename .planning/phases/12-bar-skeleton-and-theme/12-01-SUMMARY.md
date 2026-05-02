---
phase: 12-bar-skeleton-and-theme
plan: 01
subsystem: ui
tags: [quickshell, qml, theme, catppuccin, panelwindow, multi-monitor, wayland]

requires: []

provides:
  - "Colours.qml pragma Singleton with 26 Catppuccin Mocha hex values + 8 semantic aliases"
  - "theme/qmldir registering Colours as Singleton module for import qs.theme"
  - "BarGroup.qml pill-row container (default property alias children, Row spacing 8)"
  - "ModulePill.qml shared pill wrapper (radius 8, padding 6/14, Colours.moduleBg)"
  - "shell.qml entry point: Scope { Bar {} }"
  - "Bar.qml multi-monitor scope: Scope { Variants { model: Quickshell.screens } }"
  - "BarContent.qml PanelWindow with exclusive zone, no keyboard focus, drop shadow, three-section RowLayout"

affects: [13-workspaces-and-system-widgets, 14-script-backed-widgets, 15-popups, 16-animations-and-polish]

tech-stack:
  added: [quickshell, Qt5Compat.GraphicalEffects, QtQuick.Layouts]
  patterns:
    - "pragma Singleton QML theme via qmldir registration"
    - "Variants multi-monitor pattern for PanelWindow delegates"
    - "default property alias for transparent container components"
    - "RowLayout with Layout.fillWidth spacers for three-section bar layout"
    - "WlrLayershell.keyboardFocus: WlrKeyboardFocus.None on bar PanelWindow"

key-files:
  created:
    - ".config/quickshell/theme/Colours.qml"
    - ".config/quickshell/theme/qmldir"
    - ".config/quickshell/BarGroup.qml"
    - ".config/quickshell/ModulePill.qml"
    - ".config/quickshell/shell.qml"
    - ".config/quickshell/Bar.qml"
    - ".config/quickshell/BarContent.qml"
  modified: []

key-decisions:
  - "D-02: surface0 overridden to #000000 (pitch black) not canonical #313244 — matches Waybar screenshot aesthetic"
  - "D-04: PanelWindow is transparent; inner Rectangle holds the barBg color for correct compositing"
  - "D-05: Drop shadow via Qt5Compat.GraphicalEffects DropShadow layer.effect (verticalOffset 4, radius 6, rgba 0,0,0,0.3)"
  - "D-08: 8 semantic aliases (barBg, moduleBg, accent, textColor, subtextColor, warning, critical, success) in Colours.qml"
  - "D-12: exclusiveZone: height is dynamic and content-driven — no hardcoded bar height"
  - "D-13: Multi-monitor via Variants { model: Quickshell.screens } — identical bar on each screen"
  - "RowLayout chosen over Row for BarContent three-section layout (Quickshell docs recommend RowLayout for Layout.fillWidth)"
  - "P-16: WlrLayershell.keyboardFocus: WlrKeyboardFocus.None set unconditionally — bar cannot steal keyboard focus"

patterns-established:
  - "ModulePill contract: phases 13–16 wrap all widgets in ModulePill — single source of truth for pill shape"
  - "BarGroup contract: phases 13–16 place widgets inside BarGroup — behaves as native container"
  - "import qs.theme pattern: explicit import required in every QML file referencing Colours.*"
  - "No empty placeholder directories (D-21): phases 13–16 create dirs only when adding files"

requirements-completed: [BAR-01, BAR-02, BAR-03, BAR-04, BAR-06]

duration: 2min
completed: 2026-05-02
---

# Phase 12 Plan 01: Bar Skeleton and Theme Summary

**Quickshell QML bar skeleton: Catppuccin Mocha theme singleton, shared ModulePill/BarGroup components, multi-monitor Variants scope, and PanelWindow with three-section Left/Center/Right pill layout**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-02T17:53:54Z
- **Completed:** 2026-05-02T17:56:24Z
- **Tasks:** 2 completed, 1 awaiting human verification (Task 3: checkpoint:human-verify)
- **Files modified:** 7

## Accomplishments

- Full Catppuccin Mocha theme singleton (`Colours.qml`) with all 26 hex values and 8 semantic aliases, accessible via `import qs.theme`
- Shared `ModulePill.qml` and `BarGroup.qml` components establishing the pill/section API contract for all phases 13–16
- Multi-monitor `Bar.qml` using `Variants { model: Quickshell.screens }` for dynamic per-screen bar instances
- `BarContent.qml` PanelWindow with exclusive zone, keyboard focus disabled (P-16), drop shadow (D-05), and three-section RowLayout with placeholder pills

## Task Commits

Each task was committed atomically:

1. **Task 1: Author theme singleton and shared QML components** - `8bfdccd` (feat)
2. **Task 2: Author shell entry point, multi-monitor scope, and PanelWindow content** - `438a21a` (feat)
3. **Task 3: Human-verify bar renders correctly on Hyprland** - PENDING (checkpoint:human-verify)

## Files Created/Modified

- `.config/quickshell/theme/Colours.qml` - pragma Singleton with 26 Catppuccin Mocha hex values + 8 semantic aliases (barBg, moduleBg, accent, textColor, subtextColor, warning, critical, success)
- `.config/quickshell/theme/qmldir` - Singleton registration: `singleton Colours Colours.qml`
- `.config/quickshell/BarGroup.qml` - Pill-row container: `default property alias children: row.children`, Row spacing 8
- `.config/quickshell/ModulePill.qml` - Shared pill wrapper: Rectangle radius 8, padding 6/14, `default property alias content`
- `.config/quickshell/shell.qml` - Entry point: `Scope { Bar {} }`
- `.config/quickshell/Bar.qml` - Multi-monitor scope: `Variants { model: Quickshell.screens }` delegate to BarContent
- `.config/quickshell/BarContent.qml` - PanelWindow root with transparent bg, exclusiveZone: height, WlrKeyboardFocus.None, black Rectangle + DropShadow, three-section RowLayout

## Decisions Made

- Followed all locked CONTEXT.md decisions verbatim (D-01 through D-13, D-19 through D-21)
- Used RowLayout over Row for BarContent (Claude's Discretion item — Quickshell docs prefer RowLayout for Layout.fillWidth support)
- Honored D-05: Qt5Compat.GraphicalEffects DropShadow (not QtQuick.Effects RectangularShadow), as locked

## Deviations from Plan

None — plan executed exactly as written. All seven files match the verbatim QML specified in the plan. All acceptance criteria greps pass.

## Known Stubs

The placeholder Text labels ("Left", "Center", "Right") in BarContent.qml are intentional D-01 stubs — required to prevent QML from collapsing empty containers. Phase 13 replaces these with real widget components. These stubs are load-bearing for Task 3 visual verification and are expected at this phase.

## Threat Model Compliance

All four threat mitigations from the plan's threat model are implemented:

| Threat ID | Mitigation | Verification |
|-----------|------------|--------------|
| T-12-01 | `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None` set unconditionally | `grep -q "WlrKeyboardFocus.None" .config/quickshell/BarContent.qml` — PASS |
| T-12-02 | `theme/qmldir` registers Colours singleton | `grep -q "^singleton Colours Colours.qml$" .config/quickshell/theme/qmldir` — PASS |
| T-12-03 | NotificationServer absent from all QML files | `! grep -q "NotificationServer" .config/quickshell/BarContent.qml` — PASS |
| T-12-04 | grabFocus absent from all QML files | `! grep -q "grabFocus" .config/quickshell/BarContent.qml` — PASS |

## Human Verification Status

Task 3 (checkpoint:human-verify) is a blocking gate requiring the user to run `quickshell` on Hyprland and visually confirm:

1. Black bar at top of screen, no QML errors in stderr
2. Bar flush to screen top, pure black background (#000000), soft drop shadow visible
3. Three pills visible: "Left" (left edge), "Center" (horizontally centered), "Right" (right edge)
4. Each pill dark (#1e1e2e) with rounded corners, text light grey (#cdd6f4) in JetBrainsMono Nerd Font 14px bold
5. Exclusive zone active — tiling windows pushed below the bar (BAR-01)
6. Keyboard focus not stolen (P-16) — typing in terminal reaches terminal
7. Waybar still renders and functions in parallel (BAR-06)
8. Multi-monitor (BAR-02) — if second monitor available: connect/disconnect adds/removes bar without restart

**Prerequisite:** Plan 02 (`arch/quickshell.sh`) must complete first to install quickshell and create the `~/.config/quickshell` symlink.

## Next Phase Readiness

- All component contracts established: `ModulePill`, `BarGroup`, `Colours` singleton — phases 13–16 consume these unchanged
- Adding a new widget in Phase 13: create widget QML file, wrap in `ModulePill`, place inside `BarGroup` in `BarContent.qml`
- No `services/`, `widgets/`, `popups/` directories created (D-21) — Phase 13 creates those as needed
- Hyprland `exec-once` untouched (D-19) — Quickshell continues to be launched manually until Phase 16

---
*Phase: 12-bar-skeleton-and-theme*
*Completed: 2026-05-02*
