# Phase 33: Modular Layout & Live Trial-and-Error Rearrangement - Context

**Gathered:** 2026-09-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Reorganize `BarContent.qml` into modular Left, Center, and Right sections; conduct live interactive trial-and-error visual testing with the user across dual monitors (`DP-1` and `HDMI-A-1`):

1. **Component Distribution (LAYOUT-01):** Modularly map and order components across the three bar sections:
   - **Left Section:** `LeftSidebarButton` (1), `Resources` (4: CPU, RAM, Swap), `UtilButtons` (7: Screen snip, record, color picker, mic/profile toggles).
   - **Center Section:** `WeatherBar` (6), `Workspaces` (2), `ClockWidget` (3: 12h time + date).
   - **Right Section:** `Media` (5), `UpdatesButton` (9), `BatteryIndicator` (8: auto-hidden on desktop), `SysTray` (10), `Status Indicators & Right Sidebar Button` (11).
2. **Pill Grouping & Boundaries:**
   - Center: 3 standalone pills `[ Weather ]` `[ Workspaces ]` `[ Clock & Date ]`.
   - Left: Bare `LeftSidebarButton` sitting directly on the bar edge, followed by 2 separate pills `[ Resources ]` `[ UtilButtons ]`.
   - Right: Standalone `[ Media ]` pill (auto-collapsing when idle), standalone `[ Updates ]` pill (auto-collapsing when 0), standalone `[ SysTray ]` pill, and `[ Status Indicators & RightSidebar ]` pill.
   - Spacing: Retain dots-hyprland gap spacing (`spacing: 4` between pills, clean gaps without vertical divider lines).
   - Media sizing: Upstream default width cap (`Layout.maximumWidth: (root.useShortenedForm === 1) ? 140 : 200` with `Text.ElideRight`).
   - ClockWidget layout: Retain Phase 32 horizontal side-by-side format `[ hh:mm:ss AP   ddd, dd-MM-yyyy ]` with subtle spacer.
   - UtilButtons layout: Retain upstream horizontal row layout with standard 4px spacing.
3. **Multi-Monitor Behavior (LAYOUT-02, LAYOUT-03):**
   - Full layout rendered identically across dual monitors (`DP-1` 3440x1440 ultrawide and `HDMI-A-1` 1920x1080).
   - Workspaces widget: Retain upstream dots-hyprland default display and monitor filtering.
   - Responsive scaling: Retain upstream thresholds (1200px / 900px) — both 3440px and 1920px display full uncompromised layouts with zero clipping or text overflow.
   - Verification loop: Live reload with `Ctrl+Super+R` during trial-and-error visual testing, backed by automated assertion test script `scripts/phase33-layout-assert.sh`.
4. **Center Alignment & Space Clamping:**
   - Middle section remains anchored to true geometric screen center (`anchors.horizontalCenter: parent.horizontalCenter`).
   - Space collision defense: Option 1 — Minimum spacing margins with flexible media eliding (dynamic content defense preserving clean buffer margins between Left/Right and Center, eliding media title if space ever constricts).

Out of scope:
- Full milestone verification, dynamic wallpaper palette switch tests (`switchwall.sh`), repository strict verification pass, and `./bootstrap.sh` fresh-machine deployment (Phase 34 owns this).
- Altering internal component formatting or telemetry daemons established in Phase 32.

</domain>

<decisions>
## Implementation Decisions

### Component Distribution & Section Ordering
- **D-01 (Explicit Component Distribution):** In `BarContent.qml`, reorganize components across three distinct zones:
  - **Left Section:** `[1] LeftSidebarButton` -> `[4] Resources` -> `[7] UtilButtons`
  - **Center Section:** `[6] WeatherBar` -> `[2] Workspaces` -> `[3] ClockWidget`
  - **Right Section:** `[5] Media` -> `[9] UpdatesButton` -> `[8] BatteryIndicator` -> `[10] SysTray` -> `[11] Status Indicators & RightSidebarButton`
- **D-02 (Center Section Pill Grouping):** Weather, Workspaces, and Clock & Date are partitioned into 3 standalone `BarGroup` pills: `[ Weather ]`  `[ Workspaces ]`  `[ Clock & Date ]`.
- **D-03 (Left Section Pill Grouping):** `LeftSidebarButton` sits directly on the bar edge as a bare icon button (no enclosing pill). `Resources` and `UtilButtons` are partitioned into 2 separate `BarGroup` pills: `[ Resources ]`  `[ UtilButtons ]`.
- **D-04 (Right Section Pill Grouping):** Partition the right section into distinct functional pills: `[ Media ]` (standalone, auto-collapsing when idle) -> `[ Updates ]` (standalone, auto-collapsing when 0 updates) -> `[ SysTray ]` (standalone) -> `[ Status & RightSidebar ]` (`RippleButton` with `indicatorsRowLayout`).

### Pill Styling & Internal Geometries
- **D-05 (Inter-Pill Spacing):** Match dots-hyprland upstream gap spacing (`spacing: 4` between pills, clean gaps without vertical divider lines).
- **D-06 (Media Player Width Cap):** Keep upstream default width constraint (`Layout.maximumWidth: (root.useShortenedForm === 1) ? 140 : 200` with `Text.ElideRight`) ensuring long track titles elide smoothly and never encroach on neighboring pills.
- **D-07 (Clock & Date Internal Layout):** Retain Phase 32 horizontal side-by-side format `[ hh:mm:ss AP   ddd, dd-MM-yyyy ]` with subtle spacer inside the Center Clock pill.
- **D-08 (Utility Buttons Internal Layout):** Retain upstream horizontal row layout with standard 4px spacing inside the Left UtilButtons pill.

### Multi-Monitor Behavior & Responsive Scaling
- **D-09 (Full Dual-Monitor Parity):** Render the full, uncompromised bar layout across both active monitors (`DP-1` 3440x1440 ultrawide and `HDMI-A-1` 1920x1080).
- **D-10 (Workspaces Monitor Filtering):** Adhere to upstream dots-hyprland native workspace display and monitor filtering.
- **D-11 (Screen Width Thresholds):** Maintain upstream responsive thresholds (`barShortenScreenWidthThreshold`: 1200px, `barHellaShortenScreenWidthThreshold`: 900px). Both 3440px and 1920px remain in full form (`useShortenedForm === 0`).
- **D-12 (Verification Loop & Assertion Harness):** Interactive visual trial-and-error testing performed live via `Ctrl+Super+R` reloads, verified by an automated test script (`scripts/phase33-layout-assert.sh`) checking QML syntax, restow symlinks, and layout geometry.

### Center Alignment & Space Defense
- **D-13 (True Geometric Screen Center):** Anchor the Center section strictly to `anchors.horizontalCenter: parent.horizontalCenter` so Workspaces, Weather, and Clock remain centered on the physical monitor.
- **D-14 (Dynamic Content Spacing Defense):** Implement Option 1 (minimum spacing margins with flexible media eliding) to prevent any overlap between expanding side sections and the centered section.

### the agent's Discretion
- Exact QML layout container architecture in `BarContent.qml` (Row / RowLayout / Anchors) ensuring clean modular swappability of sections.
- Test section breakdown in `scripts/phase33-layout-assert.sh`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and Requirements
- `.planning/ROADMAP.md` §Phase 33 — Modular Layout & Live Trial-and-Error Rearrangement goal and success criteria
- `.planning/REQUIREMENTS.md` lines 29–33 — LAYOUT-01, LAYOUT-02, LAYOUT-03 specifications
- `.planning/STATE.md` §Milestone v0.6 — Current project status and decisions log

### Prior Phase Contexts
- `.planning/phases/31-overlay-infrastructure-pill-geometry-foundation/31-CONTEXT.md` — Pill geometry foundation, dynamic width sizing, and restow overlay rules
- `.planning/phases/32-component-representation-formatting-customization/32-CONTEXT.md` — RAM GB formatting, Clock 12h+seconds, Media auto-collapse, Updates pill, Privacy alerts

### Active Quickshell Layout Modules
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` — Live bar layout and component mounting
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` — Pill container and smooth width animation
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Bar.qml` — Multi-screen window definition and layer shell settings
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` — Color tokens, sizes, and animation curves

### Keybindings & Workflows
- `~/.config/hypr/hyprland/keybinds.lua` line 56 — `Ctrl+Super+R` live reload shortcut

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BarGroup.qml`: Foundational pill container with dynamic content-driven `implicitWidth` and smooth `emphasizedDecel` animation from Phase 31.
- `BarContent.qml`: Already stowed in `restow/quickshell/`, contains mounts for all 11 audited components from Phase 32.
- `WeatherBar.qml`, `Workspaces.qml`, `ClockWidget.qml`: Fully configured and ready to be rearranged into modular Center pills.

### Established Patterns
- Modular QML layout: Breaking sections into clear, independently swappable `RowLayout` or `Row` items.
- Restow `--no-folding` symlink deployment into `~/.config/quickshell/ii/modules/ii/bar/`.
- Hot-reload cycle: Instant verification via `Ctrl+Super+R` without tearing down compositor state.

### Integration Points
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`: Primary file modified to realize the modular Left, Center, and Right reorganization.
- `scripts/phase33-layout-assert.sh`: Verification script exercising modularity, syntax, symlinks, and dual-monitor layout stability.

</code_context>

<specifics>
## Specific Ideas

- **Component Mapping Directive:**
  - Left Section: `1, 4, 7` (`LeftSidebarButton`, `Resources`, `UtilButtons`)
  - Center Section: `6, 2, 3` (`Weather`, `Workspaces`, `Clock & Date`)
  - Right Section: `5, 9, 8, 10, 11` (`Media`, `Updates`, `Battery`, `SysTray`, `Status & RightSidebar`)
- **Pill Aesthetics:**
  - Center partitioned into 3 standalone pills: `[ Weather ]  [ Workspaces ]  [ Clock & Date ]`
  - Spacing matches dots-hyprland gap spacing (`spacing: 4`)
  - LeftSidebarButton stays bare on the edge
  - Media player capped at upstream default (200px) with `Text.ElideRight`
  - Option 1 chosen for space defense: dynamic content defense with clear buffer margins between sections.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 34 (Verification, Zero Drift & Bootstrap Integration):** Dynamic Material You wallpaper palette adaptation tests (`switchwall.sh`), `arch/dots-hyprland.sh verify --strict` 0-findings gate, and `./bootstrap.sh` fresh-machine deployment.

</deferred>

---

*Phase: 33-modular-layout-live-trial-and-error-rearrangement*
*Context gathered: 2026-09-20*
