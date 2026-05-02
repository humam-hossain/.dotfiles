# Phase 12: Bar Skeleton and Theme - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-02
**Phase:** 12-bar-skeleton-and-theme
**Areas discussed:** Skeleton content, Bar visuals, Autostart strategy, Install script scope, Module pill style, Font, Bar position, Pill background color, Colours.qml aliases, Drop shadow, Exclusive zone, PanelWindow background, BarGroup API, i2c relog reminder, Directory structure, Scripts placement, BarGroup empty state, ModulePill wrapper

---

## Skeleton Content

| Option | Description | Selected |
|--------|-------------|----------|
| Empty pill rows | BarGroups render as styled containers with no content | |
| Static text labels | Each section shows placeholder text ("Left" / "Center" / "Right") | ✓ |
| Static clock only | Center section renders a working clock, rest empty | |

**User's choice:** Static text labels per section, wrapped in ModulePill
**Notes:** User initially chose "empty pill rows" but updated after learning QML collapses empty containers — placeholder text is required to verify layout and font rendering.

---

## Bar Visuals — surface0 Color

| Option | Description | Selected |
|--------|-------------|----------|
| #000000 override | Pitch black, matches existing Waybar screenshots | ✓ |
| Canonical #313244 | Standard Catppuccin Mocha surface0 | |

**User's choice:** #000000 override

---

## Bar Visuals — Height and Pill Dimensions

| Option | Description | Selected |
|--------|-------------|----------|
| Match Waybar | Read style.css for exact values | ✓ |
| 32px height, 8px radius | Common Catppuccin community dimensions | |
| Claude's discretion | Pick reasonable defaults | |

**User's choice:** Match Waybar
**Notes:** From .config/waybar/style.css: border-radius 8px, padding 6px 14px, margin 6px 4px, font-size 14px bold, height content-driven.

---

## Autostart Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Add to exec-once | Modify Hyprland config to start Quickshell with Waybar | |
| Manual launch only | Don't touch Hyprland config — run quickshell from terminal | ✓ |
| Claude's discretion | Planner decides | |

**User's choice:** Manual launch only — Hyprland config untouched

---

## Install Script Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Packages + i2c + symlink | Follow waybar.sh pattern; also symlink config dir | ✓ |
| Packages + i2c only | BAR-05 requirements only; user symlinks config separately | |

**User's choice:** Packages + i2c + symlink (force overwrite if ~/.config/quickshell exists)

---

## Install Script — Existing Config Conflict

| Option | Description | Selected |
|--------|-------------|----------|
| Backup and replace | Move existing to .bak, create symlink | |
| Skip if exists | Idempotent, don't touch existing | |
| Force overwrite | Remove existing, recreate symlink | ✓ |

**User's choice:** Force overwrite

---

## Module Pill Style

| Option | Description | Selected |
|--------|-------------|----------|
| Individual pills per module | Each widget = one pill; matches Waybar visual | ✓ |
| One pill per section | BarGroup itself is the pill | |

**User's choice:** Individual pills — consistent with existing Waybar appearance

---

## Font

| Option | Description | Selected |
|--------|-------------|----------|
| Assume pre-installed | Font already installed via fonts.sh/waybar.sh | ✓ |
| Add to quickshell.sh | Install font in quickshell.sh for self-containment | |

**User's choice:** Assume pre-installed

---

## Bar Position

| Option | Description | Selected |
|--------|-------------|----------|
| Flush top | Anchors directly to screen top edge | ✓ |
| Floating with gap | Small top/side margin | |

**User's choice:** Flush top

---

## Pill Background Color

| Option | Description | Selected |
|--------|-------------|----------|
| Base #1e1e2e | Dark navy pill on black bar | ✓ |
| Surface1 #45475a | Higher contrast gray pill | |
| Transparent | No pill background | |

**User's choice:** Base #1e1e2e

---

## Colours.qml Semantic Aliases

| Option | Description | Selected |
|--------|-------------|----------|
| Full semantic aliases | barBg, moduleBg, accent, textColor, subtextColor, warning, critical, success | ✓ |
| Minimal aliases only | Just barBg, moduleBg, accent | |
| Claude's discretion | Planner defines | |

**User's choice:** Full set — all phases 13–16 reference these names

---

## Bar Border / Shadow

| Option | Description | Selected |
|--------|-------------|----------|
| No border, no shadow | Exclusive zone creates visual separation | |
| Drop shadow | Qt DropShadow effect (verticalOffset 4, radius 6) | ✓ |
| Bottom border 1px | surface1 line at bar bottom | |

**User's choice:** Qt DropShadow — mirrors Waybar's box-shadow

---

## Exclusive Zone

| Option | Description | Selected |
|--------|-------------|----------|
| Dynamic: exclusiveZone: height | Auto-adjusts to content | ✓ |
| Fixed pixel value | Hardcoded height | |

**User's choice:** Dynamic

---

## PanelWindow Background

| Option | Description | Selected |
|--------|-------------|----------|
| Transparent + row bg strip | PanelWindow transparent; Rectangle with barBg in BarContent | ✓ |
| PanelWindow color = surface0 | Simpler but bypasses compositor transparency layer | |

**User's choice:** Transparent + background strip

---

## Scripts Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Keep in .config/waybar/scripts/ | Reference existing scripts from their current location | |
| Move to .config/scripts/ | Shared location (rejected — would require updating Waybar refs) | |
| Quickshell-only under .config/quickshell/ | Each component stays fully self-contained | ✓ |

**User's choice:** Scripts go under .config/quickshell/scripts/ (Phase 14). Waybar scripts completely untouched.
**Notes:** User clarified: "waybar config whatever is present should be untouched. quickshell stuff should be all under .config/quickshell/ folder"

---

## BarGroup API

| Option | Description | Selected |
|--------|-------------|----------|
| default alias + spacing only | Thin Row wrapper: default alias children + spacing: 8 | ✓ |
| Explicit slot properties | Typed left/center/right properties | |
| Claude's discretion | Planner decides | |

**User's choice:** default property alias — clean, idiomatic QML

---

## i2c Relog Reminder

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, print reminder | Echo relog instruction after usermod | ✓ |
| No reminder | Silent | |

**User's choice:** Print reminder

---

## Directory Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Full structure now | Create services/, widgets/, popups/ with .gitkeep | |
| Only what Phase 12 needs | Minimal: 6 QML files + install script only | ✓ |

**User's choice:** Minimal — later phases create dirs as needed

---

## BarGroup Empty State / Skeleton Visibility

| Option | Description | Selected |
|--------|-------------|----------|
| Placeholder text per section | Static "Left" / "Center" / "Right" in ModulePill | ✓ |
| Fixed minimum width | implicitWidth: 200 on empty BarGroups | |
| Just the black strip | Only bar background visible | |

**User's choice:** Placeholder text — confirms font, color, and pill rendering

---

## ModulePill Wrapper

| Option | Description | Selected |
|--------|-------------|----------|
| Shared ModulePill.qml | Single pill component; all widgets wrap themselves in it | ✓ |
| Each widget owns its pill style | Per-widget Rectangle with radius/color | |

**User's choice:** Shared ModulePill.qml created in Phase 12

---

## Claude's Discretion

- RowLayout vs Row for BarContent three-section layout
- Exact QML import list per file
- BarGroup internal Row id and details
- BarContent vertical alignment of BarGroups

## Deferred Ideas

- `services/`, `widgets/`, `popups/` dirs — created by phases 13–16
- Script copies to `.config/quickshell/scripts/` — Phase 14
- Icon font size — Phase 13
- Font weight — Phase 13
- Floating bar variant — not requested
