# Phase 39: Dynamic Media Popup Anchoring - Context

**Gathered:** 2026-09-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Dynamically position `MediaControls.qml` directly beneath the top status bar's `Media` pill across active displays with horizontal and vertical boundary clamping.

**In Scope:**
- Replace static center offset in `MediaControls.qml` with dynamic anchoring relative to the `Media` pill.
- Boundary clamping (`Math.max` / `Math.min`) enforcing `Appearance.sizes.hyprlandGapsOut` margins against monitor boundaries across standard, ultrawide, and narrow displays.
- Cross-window coordinate sharing via `GlobalStates` singleton (`mediaPillCenterX`, `mediaPillCenterY`, `mediaPillScreen`).
- Multi-monitor target display alignment so the popup reliably appears on the monitor where the pill was activated.
- Vertical bar support with top/bottom boundary clamping.
- Fallback to upstream center position when opened via keyboard shortcut (`GlobalShortcut`) or IPC without a clicked pill.
- Deployment strictly via `restow/quickshell/` leaf symlinks without modifying `vendor/dots-hyprland`.

**Out of Scope:**
- Changing popup visual styling, dimensions, or player controls (keeps upstream `widgetWidth: 440`, `widgetHeight: 160`).
- Adding visual clamping indicators (e.g. arrows/callouts) — silent clamping only.
- Modifying `Media.qml` in `vendor/` or creating unnecessary `Media.qml` overlays when `BarContent.qml` already owns `mediaLoader`.

</domain>

<decisions>
## Implementation Decisions

### Popup-to-Pill Alignment & Sizing
- **D-01 (Center-Alignment under Pill):** Horizontally align the center of `MediaControls.qml` with the center of the `Media` pill (`targetLeft = mediaPillCenterX - widgetWidth / 2`).
- **D-02 (Upstream Dimensions Preserved):** Keep upstream popup dimensions (`widgetWidth: 440`, `widgetHeight: 160` from `Appearance.sizes`). Only positioning math is altered.
- **D-03 (Vertical Bar Parity):** When the bar is in vertical mode (`Config.options.bar.vertical === true`), anchor vertically relative to `GlobalStates.mediaPillCenterY` with top/bottom boundary clamping.
- **D-04 (Reactive Position Tracking):** Use reactive QML property bindings for margins so any layout shifts (e.g., song title changes expanding the pill while the popup is open) update the popup position immediately without Wayland layer-shell animation jitter.

### Position Communication & Multi-Monitor Architecture
- **D-05 (GlobalStates State Bridge):** Add three properties to `GlobalStates.qml` via restow overlay:
  - `property real mediaPillCenterX: -1`
  - `property real mediaPillCenterY: -1`
  - `property var mediaPillScreen: null`
- **D-06 (BarContent Capture Point):** In `BarContent.qml` (already an overlay in `restow/quickshell/`), observe `GlobalStates.mediaControlsOpen` and calculate the pill's window-relative coordinates using `mediaLoader.item.mapToItem(null, mediaLoader.item.width / 2, mediaLoader.item.height / 2)`. This avoids touching `Media.qml` in `vendor/` and avoids creating an unnecessary extra file in `restow/`.
- **D-07 (Multi-Monitor Screen Binding):** Set `screen: GlobalStates.mediaPillScreen ?? null` on `PanelWindow` in `MediaControls.qml`. This resolves an upstream bug where popups always defaulted to the primary screen regardless of which monitor's bar was clicked.
- **D-08 (Shortcut & IPC Fallback):** If `GlobalStates.mediaPillCenterX <= 0` (e.g., opened via keybinding or CLI before a pill click, or when the pill is hidden on ultra-small screens), fallback to upstream default center margin: `(panelWindow.screen.width / 2) - (osdWidth / 2) - widgetWidth`.

### Edge Clamping Margins
- **D-09 (Symmetrical Hyprland Gap Margins):** Clamp popup boundaries using `Appearance.sizes.hyprlandGapsOut` (5px) as the minimum distance from all monitor edges.
- **D-10 (Clamping Formula with Subpixel Rounding):**
  ```javascript
  const gap = Appearance.sizes.hyprlandGapsOut;
  const targetX = GlobalStates.mediaPillCenterX - (widgetWidth / 2);
  const minX = gap;
  const maxX = panelWindow.screen.width - widgetWidth - gap;
  const clampedX = (maxX < minX) ? minX : Math.max(minX, Math.min(targetX, maxX));
  return Math.round(clampedX);
  ```
- **D-11 (Vertical Distance from Bar):** Match upstream vertical margin (`Appearance.sizes.barHeight`) for both top and bottom bar placements.
- **D-12 (Silent Clamping):** Do not render pointer arrows or offset indicators when clamped; silently pin to the boundary margin.

### Minimal Overlay Strategy
- **D-13 (Minimal 4-Line MediaControls Override):** Copy `MediaControls.qml` into `restow/quickshell/.../modules/ii/mediaControls/MediaControls.qml`, modifying strictly the `screen` property and lines 101–104 (`margins` block). All internal controls, MPRIS logic, cava visualizer, and shortcuts remain byte-identical to upstream for effortless submodule re-syncing.

### the agent's Discretion
- Exact variable naming for internal clamping helpers in `MediaControls.qml`.
- Specific test harness assertion scripts in `scripts/` validating coordinate clamping and multi-monitor fallback.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §Phase 39 — Goal, success criteria, and requirements.
- `.planning/REQUIREMENTS.md` §Media Popup Anchoring — `MEDIA-01`, `MEDIA-02`.

### Upstream Components & Patterns
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml` — Upstream media controls panel and margins block.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml` — Upstream reference pattern for `mapFromItem` / `mapToItem` positioning.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` — Authoritative dimensions (`hyprlandGapsOut`, `barHeight`, `mediaControlsWidth`, `mediaControlsHeight`).
- `vendor/dots-hyprland/dots/.config/quickshell/ii/GlobalStates.qml` — Upstream singleton for desktop shell state.

### Personal Overlays (Restow)
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` — Personal bar layout with `mediaLoader`.
- `restow/quickshell/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml` — Personal vertical bar layout with `VerticalMedia`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Appearance.sizes`: Provides `hyprlandGapsOut` (5), `barHeight` (40 or 50), `mediaControlsWidth` (440), and `mediaControlsHeight` (160).
- `BarContent.qml` `mediaLoader`: The existing Loader hosting the `Media` pill in the bar's right section.
- `QsWindow.window`: Window reference available on root bar items for screen coordinate calculations.

### Established Patterns
- **Three-Tree Overlay Model:** Personal QML overrides live in `restow/quickshell/` and are stowed as leaf symlinks into `~/.config/quickshell/ii/` without modifying `vendor/dots-hyprland`.
- **GlobalStates Bridge:** Used across all panel modules for toggles (`barOpen`, `sidebarRightOpen`, `mediaControlsOpen`).

### Integration Points
- `GlobalStates.qml`: Exposes `mediaPillCenterX`, `mediaPillCenterY`, and `mediaPillScreen`.
- `BarContent.qml`: Updates `GlobalStates` when `mediaControlsOpen` becomes active or when the pill layout shifts.
- `VerticalBarContent.qml`: Updates `mediaPillCenterY` when vertical bar is active.
- `MediaControls.qml`: Consumes coordinates and screen binding inside `PanelWindow`.

</code_context>

<specifics>
## Specific Ideas

- **User Directives:**
  - *"make sure it clamps it like you have to clamp it based on the top bar position like bar position, status bar position if it's in top, it's in the left, it's in the right the bottom don't do necessarily clamping so that the boundary doesn't go beyond the window screen dimensions so let's make sure of that"*
  - Center-align popup under the pill's center.
  - Symmetrical clamping using `Appearance.sizes.hyprlandGapsOut`.
  - Match upstream default vertical spacing and silent clamp.
  - Minimal restow override of `MediaControls.qml` changing only the margins block and screen target.

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed strictly within phase scope.

</deferred>

---

*Phase: 39-Dynamic Media Popup Anchoring*
*Context gathered: 2026-09-23*
