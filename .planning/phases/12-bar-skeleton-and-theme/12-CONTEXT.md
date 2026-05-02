# Phase 12: Bar Skeleton and Theme - Context

**Gathered:** 2026-05-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a visible, correctly themed Quickshell bar docked at the top of all screens on Hyprland startup, with Waybar continuing to run in parallel. This phase establishes all foundational QML files — PanelWindow, multi-monitor support, Colours.qml theme, BarGroup/ModulePill component API, and the arch/quickshell.sh install script. No functional widgets are implemented; sections show placeholder text labels to verify layout and font rendering.

New capabilities (widgets, popups, animations) belong in phases 13–16.

</domain>

<decisions>
## Implementation Decisions

### Skeleton Placeholder Content
- **D-01:** Each BarGroup section (left, center, right) renders a static placeholder Text label ("Left" / "Center" / "Right") wrapped in ModulePill — QML collapses empty containers so placeholder content is required to verify pill rendering, font, and three-section layout. Labels are removed in Phase 13 as real widgets arrive.

### Bar Visuals
- **D-02:** `surface0` color override = `#000000` (pitch black), not canonical Catppuccin `#313244`. Matches existing Waybar screenshots. `Colours.barBg` alias maps to surface0.
- **D-03:** Bar dimensions match Waybar (from `.config/waybar/style.css`): `border-radius: 8px`, module `padding: 6px 14px`, inter-module spacing `8px` (4px each side from `margin: 6px 4px`), `font-size: 14px bold`, height is content-driven (no explicit height in Waybar CSS).
- **D-04:** PanelWindow background = transparent (`color: "transparent"`). BarContent contains a full-width `Rectangle { color: Colours.barBg }` background strip behind the BarGroups — matches Waybar's compositing model.
- **D-05:** Drop shadow via `layer.enabled: true` + `DropShadow` from `Qt5Compat.GraphicalEffects` on the background Rectangle. Values: `verticalOffset: 4`, `radius: 6`, `color: Qt.rgba(0,0,0,0.3)` — mirrors Waybar's `box-shadow: 0 4px 6px rgba(0,0,0,0.3)`.
- **D-06:** Module pill background = Catppuccin Mocha Base `#1e1e2e` (`Colours.moduleBg`).
- **D-07:** Individual pill per module (not one big pill per section). Each widget wraps itself in `ModulePill.qml`.

### Colours.qml — Full Semantic Aliases
- **D-08:** `Colours.qml` is `pragma Singleton`. Contains all 26 canonical Catppuccin Mocha hex values plus the following semantic aliases used across phases 12–16:
  - `barBg`       = `surface0` = `#000000`
  - `moduleBg`    = `base`     = `#1e1e2e`
  - `accent`      = `mauve`    = `#cba6f7`
  - `textColor`   = `text`     = `#cdd6f4`
  - `subtextColor`= `subtext1` = `#bac2de`
  - `warning`     = `yellow`   = `#f9e2af`
  - `critical`    = `red`      = `#f38ba8`
  - `success`     = `green`    = `#a6e3a1`

### Component API
- **D-09:** `BarGroup.qml` exposes `default property alias children: row.children` + `Row { id: row; spacing: 8 }`. Usage: `BarGroup { WorkspacesWidget {}; DiskWidget {} }`. Phases 13–16 place widgets directly inside BarGroup.
- **D-10:** `ModulePill.qml` is a shared pill wrapper (`Rectangle { radius: 8; color: Colours.moduleBg; padding: 6/14 }` with `default property alias content`). All widgets in phases 13–16 wrap themselves in ModulePill. Created in Phase 12.

### Bar Layout and Positioning
- **D-11:** Bar is flush to screen top edge — no floating margin. `anchors { top: true; left: true; right: true }` on PanelWindow.
- **D-12:** `exclusiveZone: height` (dynamic, content-driven). Auto-adjusts if bar height changes; standard Quickshell pattern.
- **D-13:** Multi-monitor via `Variants { model: Quickshell.screens }` — identical bar on each connected screen. All bars are uniform; no primary/secondary distinction.

### Install Script (arch/quickshell.sh)
- **D-14:** Script installs: `quickshell ddcutil i2c-tools` via `pacman -S`.
- **D-15:** i2c setup: `sudo modprobe i2c-dev`, `sudo usermod -aG i2c $USER`, write `i2c-dev` to `/etc/modules-load.d/i2c.conf` for persistence (matches pitfall P-13 prevention).
- **D-16:** Prints relog reminder after usermod: `"Log out and back in for i2c group to take effect (required for ddcutil)"`.
- **D-17:** Symlinks `$REPO_ROOT/.config/quickshell` → `~/.config/quickshell` (force overwrite: remove existing, recreate symlink). Follows `arch/waybar.sh` pattern for REPO_ROOT detection (`"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`).
- **D-18:** JetBrainsMono Nerd Font assumed pre-installed (via existing `fonts.sh`/`waybar.sh`). quickshell.sh does NOT install the font.

### Parallel Deploy
- **D-19:** Phase 12 does NOT modify Hyprland `exec-once`. Quickshell is launched manually from terminal during development (`quickshell` command). Waybar continues to autostart normally via existing Hyprland config.

### Scripts Placement
- **D-20:** All Quickshell-specific scripts go under `.config/quickshell/scripts/` (Phase 14 responsibility). Waybar's `.config/waybar/scripts/` stays completely untouched. No shared scripts directory.

### Directory Structure
- **D-21:** Phase 12 creates only what it needs — no empty `services/`, `widgets/`, `popups/` directories. Later phases create those dirs as they add files.

### Phase 12 Output Files
- `.config/quickshell/shell.qml` — entry point (`Scope { Bar {} }`)
- `.config/quickshell/Bar.qml` — outer Scope owning `Variants { model: Quickshell.screens }`
- `.config/quickshell/BarContent.qml` — PanelWindow content root; RowLayout left/center/right
- `.config/quickshell/BarGroup.qml` — reusable pill-row container (default alias + spacing)
- `.config/quickshell/ModulePill.qml` — shared pill wrapper (radius 8, padding 6/14, moduleBg)
- `.config/quickshell/theme/Colours.qml` — pragma Singleton; all 26 Catppuccin Mocha values + semantic aliases
- `arch/quickshell.sh` — install script

### Claude's Discretion
- Row vs RowLayout choice for BarContent's three-section layout — planner decides based on QML best practices for centering
- Exact QML import list per file
- Internal BarContent vertical alignment of BarGroups
- BarGroup's `row` ID and internal Row details

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Architecture and Patterns
- `.planning/research/ARCHITECTURE.md` — QML file structure, component diagram, service/widget split, all key patterns (PwObjectTracker, PopupWindow vs PanelWindow, Process pattern, multi-monitor Variants)
- `.planning/research/SUMMARY.md` — Stack additions, feature table stakes, watch-out list, architecture approach
- `.planning/research/PITFALLS.md` — Full pitfall table; P-02 (NotificationServer), P-07 (parallel deploy), P-13 (i2c setup), P-15 (Variants cleanup), P-16 (WlrKeyboardFocus), P-18 (Process deferred start) are all relevant to Phase 12

### Waybar Reference (dimensions and layout to match)
- `.config/waybar/style.css` — Exact CSS values: `border-radius: 8px`, `padding: 6px 14px`, `margin: 6px 4px`, `font-size: 14px bold`, `box-shadow: 0 4px 6px rgba(0,0,0,0.3)`
- `.config/waybar/config.jsonc` — Left/center/right module layout (modules-left, modules-center, modules-right) — reference for three-section structure

### Install Script Pattern
- `arch/waybar.sh` — Install script structure to follow: REPO_ROOT detection, `set -euo pipefail`, symlink approach

### Requirements
- `.planning/REQUIREMENTS.md` §BAR — BAR-01 through BAR-06 are the acceptance criteria for this phase

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `arch/waybar.sh`: Install script structure — REPO_ROOT detection, `set -euo pipefail`, pacman install array, symlink logic. quickshell.sh follows the same pattern.
- `.config/waybar/style.css`: Exact pixel dimensions (border-radius, padding, font-size, box-shadow) — read this before setting any QML style values.

### Established Patterns
- All arch install scripts use `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` for repo-relative paths.
- No existing QML anywhere in the repo — this is a greenfield Quickshell implementation.

### Integration Points
- `arch/quickshell.sh` is a peer to `arch/waybar.sh` — same directory, same pattern.
- `~/.config/quickshell/` symlinks to `.config/quickshell/` (created by install script). Quickshell reads from `~/.config/quickshell/shell.qml` by default.
- Hyprland config (`exec-once`) is NOT modified in this phase — Quickshell launched manually.

</code_context>

<specifics>
## Specific Ideas

- Catppuccin Mocha `surface0` override to `#000000` — intentionally deviates from canonical `#313244` to match the existing Waybar screenshot aesthetic (pitch-black bar background).
- Drop shadow values mirror Waybar's CSS exactly: `verticalOffset: 4`, `radius: 6`, `color: Qt.rgba(0,0,0,0.3)`.
- `BarGroup` uses `default property alias children` — downstream phases treat it like a native QML container. No explicit slot properties.
- `ModulePill.qml` is the single source of truth for pill shape across all 16+ widgets in phases 13–16. Changing radius/padding/background here changes all widgets.
- Placeholder labels ("Left" / "Center" / "Right") in ModulePill wrappers — Phase 13 replaces these by adding widget files, not by modifying BarContent.

</specifics>

<deferred>
## Deferred Ideas

- `services/`, `widgets/`, `popups/` directory structure — created by phases 13–16 as they add files
- `.config/quickshell/scripts/` directory and script copies — Phase 14 (script-backed widgets)
- Icon font size decisions (14px for text; icons may warrant 16px) — Phase 13 when first widgets with icons are added
- Font weight (`font.bold: true`) global vs per-widget — Phase 13
- Floating bar with margin variant — not requested; flush top chosen

</deferred>

---

*Phase: 12-bar-skeleton-and-theme*
*Context gathered: 2026-05-02*
