# Phase 48: Right-Zone Media Expansion & System Tray Empty State Gating - Context

**Gathered:** 2026-09-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Calibrate Right-Zone media player length dynamically using a responsive equation proportional to physical screen width across multi-monitor setups (Ultrawide `DP-1` at 3440px and secondary/rotated `HDMI-A-2`), ensure both track title and artist metadata are displayed with clear visual hierarchy without premature truncation, dynamically gate the system tray pill so it completely hides when no tray icons/apps are active (`SystemTray.items.values.length === 0`), and ensure smooth Right-Zone layout reflow with zero layout collisions.

</domain>

<decisions>
## Implementation Decisions

### Media Pill Responsive Width & Sizing Architecture

- **D-01 (Responsive Sizing Equation):** The media pill's maximum width is calculated dynamically as a clamped percentage of physical screen width: `Math.min(Math.max(screen.width * 0.12, 220), 450)` px on standard full-width screens (`useShortenedForm === 0`), yielding ~410px on 3440px ultrawide displays and ~230px on 1080p displays. — **Reversibility:** reversible
- **D-02 (Shortened Tier Width Scaling):** When `useShortenedForm === 1` (screens <= 1200px or vertical/compact displays), the maximum width is clamped between 140px and 180px using `Math.min(Math.max(screen.width * 0.10, 140), 180)` to prevent crowding adjacent Center or Right zone modules. — **Reversibility:** reversible
- **D-03 (Content-Fit Dynamic Hugging):** The media pill hugs the actual track text length dynamically (`implicitWidth`), expanding only as much as needed for the current song title up to the responsive maximum limit, keeping short song titles compact. — **Reversibility:** reversible
- **D-04 (Fluid M3 Width Resizing Animation):** Retain `BarGroup`'s standard 250ms Material 3 emphasized deceleration animation (`elementMoveFast`) on pill width changes, ensuring fluid visual transitions between songs and when playback starts or stops. — **Reversibility:** reversible

### Track & Artist Typography & Metadata Styling

- **D-05 (Visual Hierarchy):** Format track title in primary foreground color (`Appearance.colors.colOnLayer1`) and artist name in subtle muted tone (`Appearance.colors.colSubtext` or 70% opacity) separated by a clean bullet (`" • "`), making the song title immediately recognizable. — **Reversibility:** reversible
- **D-06 (Missing Artist Handling):** Preserve existing fallback behavior: render `cleanedTitle` cleanly without any trailing separator or placeholder when `activePlayer.trackArtist` is falsy or empty. — **Reversibility:** reversible
- **D-07 (Right Elision on Overflow):** When track title + artist metadata exceeds the maximum width limit (e.g. over 450px on ultrawide), truncate cleanly on the right with an ellipsis using `Text.ElideRight`. The popup remains untouched. — **Reversibility:** reversible
- **D-08 (Verbose Toggle Gating):** Respect `Config.options.bar.verbose` gating — show track and artist text when verbose is enabled (default), and collapse to the circular playback progress icon when verbose is toggled off. — **Reversibility:** reversible

### System Tray Empty-State Gating & Reflow

- **D-09 (BarGroup Reactive Visibility Gating):** Directly bind the visibility of `sysTrayGroup` in `BarContent.qml` to `visible: (root.useShortenedForm === 0) && (SystemTray.items.values.length > 0)`, keeping the D-Bus service hot while completely hiding the empty pill when 0 apps are running. — **Reversibility:** reversible
- **D-10 (Quickshell SNI Source of Truth):** Use `SystemTray.items.values.length > 0` directly as the canonical source of truth for active tray items, matching `SysTray.qml` line 154. — **Reversibility:** reversible
- **D-11 (Instant Layout Reflow):** Toggling `visible` on `sysTrayGroup` immediately removes or inserts the tray pill in `RowLayout` with standard 4px spacing, eliminating empty border artifacts or delayed layout jitter. — **Reversibility:** reversible
- **D-12 (Primary Screen Restriction):** Retain the restriction of the system tray to primary full-width screens (`root.useShortenedForm === 0`), preventing tray icons from crowding compact or rotated secondary screens. — **Reversibility:** reversible

### Media Popup Anchor Synchronization & Interaction Polish

- **D-13 (Full-Pill Click Mapping):** Retain existing muscle memory across the expanded pill surface: Left-click anywhere toggles the `MediaControls` popup, Middle-click toggles play/pause, Right/Forward-click skips to next track, and Back-click returns to previous track. — **Reversibility:** reversible
- **D-14 (Transparent Scroll Events):** Do not intercept mouse wheel events on the media pill, keeping bar-level scroll behavior consistent and utilizing the popup sliders for volume and seek. — **Reversibility:** reversible
- **D-15 (Continuous Popup Tracking):** Retain reactive coordinate tracking via `onWidthChanged` and `onXChanged` in `BarContent.qml` so that the `MediaControls` popup remains dynamically centered beneath the pill even during track change width animations. — **Reversibility:** reversible
- **D-16 (Complete Idle Auto-Collapse):** Maintain current complete idle auto-collapse (`active: (root.useShortenedForm < 2) && (MprisController.activePlayer != null && (MprisController.activePlayer.trackTitle?.length > 0))`), completely hiding the pill from the Right Zone when no media is playing. — **Reversibility:** reversible

### the agent's Discretion

- Precise rich-text or formatted text implementation in `Media.qml` to deliver the primary/subtext visual separation while preserving clean single-line elision.
- Automated assertion test cases verifying responsive equations and tray gating conditions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Shell UI Blueprints & Layout
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` — Top status bar container owning Right zone layout, mediaLoader, sysTrayGroup, and Phase 39 coordinate tracking
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/SysTray.qml` — System tray widget managing SNI tray items and overflow popup
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Media.qml` — Upstream media player pill (needs overlay or restow integration for artist styling)
- `restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml` — Dynamic media popup with coordinate anchoring and screen boundary clamping
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` — Status bar pill container providing M3 250ms emphasized deceleration width resizing

### Project Specifications & Roadmap
- `.planning/ROADMAP.md` §Phase 48 — Right-Zone Media Expansion & System Tray Empty State Gating goals and success criteria
- `.planning/REQUIREMENTS.md` — Project requirements and out-of-scope constraints
- `.planning/phases/39-dynamic-media-popup-anchoring/39-SUMMARY.md` — Phase 39 dynamic media popup anchoring architecture

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BarGroup`: Container for status bar pills with M3 fluid width resizing via `Behavior on implicitWidth`.
- `Appearance.sizes`: Sizing metrics including `barShortenScreenWidthThreshold` (1200) and `barHellaShortenScreenWidthThreshold` (1000).
- `Appearance.colors`: Semantic color tokens including `colOnLayer1` (primary text) and `colSubtext` (secondary text).
- `SystemTray.items`: Quickshell system tray service providing active SNI items list (`SystemTray.items.values`).
- `MprisController.activePlayer`: Active media player metadata singleton.

### Established Patterns
- Right Zone layout in `BarContent.qml` using `RowLayout { id: barRightSide; spacing: 4 }`.
- GNU Stow leaf symlink overlay topology under `restow/quickshell/` mapping to `~/.config/quickshell/ii/` without modifying upstream files.
- Coordinate bridge between status bar pills and popups using `GlobalStates` properties (`mediaPillCenterX`, `mediaPillCenterY`, `mediaPillScreen`).

### Integration Points
- `BarContent.qml`: Line 236 `Layout.maximumWidth` on `Media` within `mediaLoader` for responsive width equation.
- `BarContent.qml`: Line 270 `sysTrayGroup` for empty-state gating binding.
- `Media.qml`: Lines 75-86 `StyledText` formatting for track title and artist visual hierarchy.

</code_context>

<specifics>
## Specific Ideas

- The user specifically requested preserving current default behavior for missing artist: show `cleanedTitle` without trailing separator when artist is absent.
- The user confirmed no changes needed in the `MediaControls` popup; overflow handling should rely on standard right elision (`Text.ElideRight`) on the pill.
- The user confirmed retaining the current complete idle auto-collapse state when no active media player with a title is running.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 48-right-zone-media-expansion-system-tray-empty-state-gating*
*Context gathered: 2026-09-30*
