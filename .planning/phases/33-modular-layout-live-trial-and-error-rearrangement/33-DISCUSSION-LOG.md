# Phase 33: Modular Layout & Live Trial-and-Error Rearrangement - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-20
**Phase:** 33-modular-layout-live-trial-and-error-rearrangement
**Areas discussed:** Component Distribution, Pill Grouping & Boundaries, Multi-Monitor Behavior, Center Alignment & Space Clamping

---

## Component Distribution

| Option | Description | Selected |
|--------|-------------|----------|
| User explicit custom mapping | Left: 1, 4, 7; Center: 6, 2, 3; Right: 5, 9, 8, 10, 11 | ✓ |

**User's choice:** `right Section: 5, 9, 8, 10, 11; left: 1, 4, 7; center: 6, 2, 3`
**Notes:** User requested full inventory of 11 components and explicitly specified mapping across the 3 sections:
- **Left:** [1] LeftSidebarButton, [4] Resources (CPU, RAM, Swap), [7] UtilButtons (Screen snip, record, color picker, mic/profile toggles)
- **Center:** [6] Weather, [2] Workspaces, [3] Clock & Date
- **Right:** [5] Media, [9] Updates, [8] Battery, [10] SysTray, [11] Status Indicators & Right Sidebar

---

## Pill Grouping & Boundaries

### Center Section Pill Grouping
| Option | Description | Selected |
|--------|-------------|----------|
| 3 standalone pills | [ Weather ]  [ Workspaces ]  [ Clock & Date ] | ✓ |
| Single unified pill | [ Weather \| Workspaces \| Clock & Date ] | |
| Hybrid | [ Weather ] standalone, [ Workspaces \| Clock & Date ] shared | |

**User's choice:** 3 standalone pills
**Notes:** Cleanest visual separation, preserving dots-hyprland rounded pill aesthetics for each widget.

### Left Section Pill Grouping
| Option | Description | Selected |
|--------|-------------|----------|
| Separate pills | [ LeftSidebar ]  [ Resources ]  [ UtilButtons ] | ✓ |
| Unified pill | [ LeftSidebar ]  [ Resources \| UtilButtons ] | |
| You decide | Builder selects cleanest visual balance | |

**User's choice:** Separate pills
**Notes:** Keeps dynamic RAM/CPU expansion isolated from static utility shortcut buttons.

### Right Section Pill Grouping
| Option | Description | Selected |
|--------|-------------|----------|
| Standalone Media + Separate SysTray & Status | [ Media ] (auto-collapses)  [ Updates ]  [ SysTray ]  [ Status & RightSidebar ] | ✓ |
| Unified Tray & Status | [ Media ] (standalone)  [ Updates ]  [ SysTray \| Status & RightSidebar ] | |
| You decide | Builder chooses cleanest styling | |

**User's choice:** Standalone Media pill + Separate SysTray & Status pills
**Notes:** Media player auto-collapses when idle; Updates pill auto-collapses when 0; SysTray and Status clusters each have dedicated pill containers.

### Inter-Pill Spacing & Dividers
| Option | Description | Selected |
|--------|-------------|----------|
| Clean gap spacing only | 4–6px spacing between pills, no vertical line dividers | |
| Subtle vertical divider lines | Upstream VerticalBarSeparator styling | |
| Match dots-hyprland gap spacing | dots-hyprland spacing (spacing: 4) | ✓ |

**User's choice:** Match dots-hyprland gap spacing
**Notes:** Retains standard 4px gaps between pills without line dividers.

### Left Sidebar Button Enclosure
| Option | Description | Selected |
|--------|-------------|----------|
| Bare icon button | Retain upstream style where button sits on bar edge without pill | ✓ |
| Enclosed in BarGroup pill | Wrap button in a pill container with colLayer1 background | |
| You decide | Builder ensures visual symmetry | |

**User's choice:** Bare icon button
**Notes:** Upstream style preserved on the left edge.

### Media Player Width Cap
| Option | Description | Selected |
|--------|-------------|----------|
| Capped width with eliding | 200–250px max width with ellipsis | |
| Uncapped dynamic expansion | Pill expands as wide as track title requires | |
| Compact width | 150px max width | |
| Keep upstream default | Upstream Layout.maximumWidth: (useShortenedForm === 1) ? 140 : 200 | ✓ |

**User's choice:** Keep upstream default
**Notes:** Upstream default width cap with text eliding.

### Clock & Date Internal Layout
| Option | Description | Selected |
|--------|-------------|----------|
| Horizontal side-by-side | Retain Phase 32 format [ hh:mm:ss AP   ddd, dd-MM-yyyy ] with subtle spacer | ✓ |
| Compact stacked | Time on top line, Date below in smaller font | |
| Responsive toggle | Always show time; date only when screen width allows | |

**User's choice:** Horizontal side-by-side
**Notes:** Carries forward Phase 32 Clock formatting decision.

### Utility Buttons Layout
| Option | Description | Selected |
|--------|-------------|----------|
| Single horizontal row | All 6 utility buttons laid out horizontally with 4px spacing | |
| Collapsible utility pill | Primary actions with expandable chevron | |
| Keep upstream default | Upstream horizontal row layout | ✓ |

**User's choice:** Keep upstream default
**Notes:** Upstream horizontal ripple button layout retained.

---

## Multi-Monitor Behavior

### Bar Parity across Monitors
| Option | Description | Selected |
|--------|-------------|----------|
| Full layout on both monitors | DP-1 and HDMI-A-1 both display Left, Center, and Right sections | ✓ |
| Streamlined secondary bar | Secondary monitor shows minimal layout (Workspaces + Clock only) | |
| Primary-only Tray & Media | Full layout on both, but SysTray and Media on DP-1 only | |

**User's choice:** Full layout on both monitors
**Notes:** Both screens render identical modular structure with responsive scaling.

### Workspaces Multi-Monitor Filtering
| Option | Description | Selected |
|--------|-------------|----------|
| Keep upstream dots-hyprland default | Adhere to native dots-hyprland workspace display and monitor filtering | ✓ |
| Monitor-aware workspaces | Each monitor's bar displays only its own workspaces | |
| Global workspaces | Both monitors display all active workspaces | |

**User's choice:** Keep upstream dots-hyprland default
**Notes:** Retains upstream workspace management.

### Responsive Width Thresholds
| Option | Description | Selected |
|--------|-------------|----------|
| Keep upstream thresholds (1200px / 900px) | DP-1 (3440px) and HDMI-A-1 (1920px) render full uncompromised layouts | ✓ |
| Adjust shortening thresholds | Raise threshold if secondary feels dense | |
| You decide | Builder ensures zero clipping | |

**User's choice:** Keep upstream thresholds (1200px / 900px)
**Notes:** Both displays remain in full form (`useShortenedForm === 0`).

### Verification & Testing Loop
| Option | Description | Selected |
|--------|-------------|----------|
| Live reload with automated assertion script | Ctrl+Super+R live reloads backed by scripts/phase33-layout-assert.sh | ✓ |
| Pure interactive visual review | Direct visual trial-and-error feedback after each tweak | |
| You decide | Builder combines live reloads with assertions | |

**User's choice:** Live reload with automated assertion script
**Notes:** Combines interactive visual evaluation with automated sanity assertions.

---

## Center Alignment & Space Clamping

### Center Section Alignment
| Option | Description | Selected |
|--------|-------------|----------|
| True geometric screen center | Keep middleSection anchored to parent.horizontalCenter | ✓ |
| Flexible three-column flow | 3-column layout shifting dynamically | |
| You decide | Builder enforces strict geometric center | |

**User's choice:** Keep default dots-hyprland behavior (True geometric screen center)
**Notes:** Center section locked to physical midpoint of the display.

### Space Collision Defense
| Option | Description | Selected |
|--------|-------------|----------|
| Option 1: Minimum spacing margins with flexible media eliding | Dynamic content defense preserving clean buffer margins between sections | ✓ |
| Option 2: Strict percentage width clamping | 35% Left / 30% Center / 35% Right hard caps | |
| Option 3: Upstream dots-hyprland natural layout | Native anchor geometry with default bounds | |

**User's choice:** Option 1 (Minimum spacing margins with flexible media eliding)
**Notes:** User requested full elaboration of all three options, then selected Option 1 to protect section margins dynamically.

---

## the agent's Discretion
- Concrete QML container architecture in `BarContent.qml` (Row vs RowLayout vs explicit anchors) ensuring modular swappability.
- Section assertion implementation in `scripts/phase33-layout-assert.sh`.

## Deferred Ideas
- Phase 34: Dynamic Material You wallpaper palette switching (`switchwall.sh`), strict repository verification (`arch/dots-hyprland.sh verify --strict`), and `./bootstrap.sh` bootstrap testing.
