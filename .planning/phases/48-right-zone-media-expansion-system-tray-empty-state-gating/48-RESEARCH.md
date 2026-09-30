# Phase 48: Right-Zone Media Expansion & System Tray Empty State Gating - Research

**Researched:** 2026-09-30  
**Domain:** Quickshell Status Bar Right-Zone Layout, Responsive Display Equations, Dynamic Media Pill Sizing, Track/Artist Typography Hierarchy, System Tray Empty-State Gating, and GNU Stow Overlay Integrity  
**Confidence:** HIGH  

---

<user_constraints>
## User Constraints

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
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| Requirement ID | Definition | Target Scope & Success Metric | Verification Trace |
|---|---|---|---|
| **RGHT-01** | Proportional Responsive Media Pill Length | Calculate media player pill maximum width dynamically via responsive screen width equations: `Math.min(Math.max((root.screen?.width ?? 1920) * 0.12, 220), 450)` on standard full screens (`useShortenedForm === 0`) and `Math.min(Math.max((root.screen?.width ?? 1200) * 0.10, 140), 180)` on shortened screens (`useShortenedForm === 1`). Media pill hugs content dynamically up to the clamp with 250ms M3 width animation. | `scripts/phase48-right-zone-assert.sh` Sections 2 & 4; [BarContent.qml:233-238](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml#L233-L238) |
| **RGHT-02** | Complete Media Track & Artist Metadata Display | Display both track title (in `Appearance.colors.colOnLayer1`) and artist (in `Appearance.colors.colSubtext`) with `" • "` separator in `Media.qml`. Clean fallback without separator when artist is falsy. Single-line right elision (`Text.ElideRight`) on overflow, `StringUtils.escapeHtml` protection, and `Config.options.bar.verbose` gating. | `scripts/phase48-right-zone-assert.sh` Section 3; [Media.qml:75-88](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml#L75-L88) |
| **RGHT-03** | System Tray Empty State Gating & Reflow | Gate `sysTrayGroup` in `BarContent.qml` with `visible: (root.useShortenedForm === 0) && ((SystemTray.items?.values?.length ?? 0) > 0)`. Completely hide empty pill when 0 apps are running; show instantly when apps register. Ensure smooth 4px RowLayout reflow with zero empty border artifacts and zero git churn. | `scripts/phase48-right-zone-assert.sh` Sections 1, 2, 4, 5; [BarContent.qml:269-281](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml#L269-L281) |
</phase_requirements>

---

## Executive Summary

Phase 48 refines and completes the Right Zone of the Quickshell top status bar across multi-monitor setups. Following the Left Zone telemetry pill integration (Phase 46) and Center Zone reorganization (Phase 47), the Right Zone hosts the media player pill, voice telemetry, updates, battery, system tray, and sidebar button.

Currently, the Right Zone suffers from two notable UX and visual shortcomings:
1. **Premature Media Truncation & Static Clamps:** In `BarContent.qml`, `Media` width is clamped to a static hardcoded `200px` (or `140px` on shortened displays). On wide displays—notably the user's primary 3440px Ultrawide (`DP-1`) monitor—this static 200px limit prematurely truncates song titles and completely hides or clips artist metadata despite having thousands of unused pixels available. Furthermore, `vendor/dots-hyprland` upstream `Media.qml` displays track and artist in identical monochrome foreground color without visual hierarchy.
2. **System Tray Empty-State Pill Artifact:** In `BarContent.qml`, `sysTrayGroup` is statically bound to `visible: root.useShortenedForm === 0`. When no background applications are running in the system tray (`SystemTray.items.values.length === 0`), `SysTray` has no visible children, but the enclosing `BarGroup` container still draws an empty pill background and padding, rendering an awkward blank box artifact on the status bar.

Phase 48 addresses these issues with zero git churn against `vendor/dots-hyprland`:
1. **Responsive Media Width Equation:** Upgrades `Layout.maximumWidth` in `BarContent.qml` to evaluate physical display width dynamically:
   - Full width (`useShortenedForm === 0`): `Math.min(Math.max((root.screen?.width ?? 1920) * 0.12, 220), 450)` px (~413px on 3440px ultrawide, ~230px on 1080p).
   - Shortened (`useShortenedForm === 1`): `Math.min(Math.max((root.screen?.width ?? 1200) * 0.10, 140), 180)` px.
   - Preserves content-driven dynamic hugging (`implicitWidth`) and fluid 250ms M3 emphasized deceleration animations (`BarGroup.qml`).
2. **Track Title & Artist Visual Hierarchy:** Introduces a leaf symlink overlay `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml` using `Text.StyledText` formatting. Track titles render in bold primary foreground (`Appearance.colors.colOnLayer1`) and artist names in subtle muted tone (`Appearance.colors.colSubtext`) joined by a clean bullet (`" • "`). When artist is absent, `cleanedTitle` renders cleanly without trailing artifacts. HTML tags are safely escaped with `StringUtils.escapeHtml`. Overflow elides cleanly on the right via `Text.ElideRight`.
3. **Reactive System Tray Gating & Layout Reflow:** Imports `Quickshell.Services.SystemTray` in `BarContent.qml` and binds `sysTrayGroup.visible: (root.useShortenedForm === 0) && ((SystemTray.items?.values?.length ?? 0) > 0)`. The empty pill is completely excluded from layout when 0 apps are running, eliminating border artifacts while keeping the D-Bus service hot.
4. **Dynamic Media Popup Synchronization:** Preserves Phase 39 coordinate tracking in `BarContent.qml` (`onWidthChanged` and `onXChanged`) so `MediaControls.qml` remains centered dynamically beneath the media pill across fluid width animations.

---

## Architectural Responsibility Map

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                              Quickshell Top Status Bar                                                 │
├───────────────────────────────────┬──────────────────────────────────────────┬─────────────────────────────────────────┤
│             LEFT ZONE             │               CENTER ZONE                │               RIGHT ZONE                │
│    [Storage/RAM] [CPU/GPU] [Net]  │       [Clock] [Workspaces] [Weather]     │        (rightSectionRowLayout)          │
├───────────────────────────────────┴──────────────────────────────────────────┴─────────────────────────────────────────┤
│                                                                                                                        │
│                                                RIGHT ZONE FLOW (RowLayout, spacing: 4)                                 │
│ ┌───────────────┐ ┌──────────────┐ ┌───────────────┐ ┌─────────────┐ ┌────────────────────────┐ ┌───────────────────┐  │
│ │ Leading       │ │ mediaLoader  │ │   voicePill   │ │  battery    │ │     sysTrayGroup       │ │ rightSidebarBtn   │  │
│ │ Elastic Space │ │ (BarGroup +  │ │  (VoicePill)  │ │  (Loader)   │ │  (BarGroup + SysTray)  │ │ (RippleButton)    │  │
│ │ (fillWidth)   │ │   Media)     │ │               │ │             │ │                        │ │                   │  │
│ └───────────────┘ └──────┬───────┘ └───────────────┘ └─────────────┘ └───────────┬────────────┘ └───────────────────┘  │
│                          │                                                       │                                     │
│                          ▼                                                       ▼                                     │
│            ┌───────────────────────────┐                           ┌───────────────────────────┐                       │
│            │ Responsive Width Clamp    │                           │ Reactive Tray Gating      │                       │
│            │  3440px UW -> ~413px max  │                           │ visible: useShortened==0  │                       │
│            │  1080p FHD -> ~230px max  │                           │   && trayItems.length > 0 │                       │
│            │ Dynamic Text Hugging      │                           │ When count == 0:          │                       │
│            │  implicitWidth < maxClamp │                           │   Completely collapsed    │                       │
│            │ M3 250ms Decel Animation  │                           │ When count > 0:           │                       │
│            │  Behavior on implicitWidth│                           │   Instant reflow + 4px    │                       │
│            │ Visual Hierarchy          │                           └───────────────────────────┘                       │
│            │  Title: colOnLayer1       │                                                                               │
│            │  Artist: colSubtext       │                                                                               │
│            │  Single-line ElideRight   │                                                                               │
│            └─────────────┬─────────────┘                                                                               │
│                          │                                                                                             │
│                          │ onWidthChanged / onXChanged                                                                 │
│                          ▼                                                                                             │
│            ┌───────────────────────────┐                                                                               │
│            │  GlobalStates Bridge      │                                                                               │
│            │  mediaPillCenterX/Y       │                                                                               │
│            │  mediaPillScreen          │                                                                               │
│            └─────────────┬─────────────┘                                                                               │
│                          │                                                                                             │
│                          ▼                                                                                             │
│            ┌───────────────────────────┐                                                                               │
│            │  MediaControls.qml Popup  │                                                                               │
│            │  Dynamically centered     │                                                                               │
│            │  beneath moving pill      │                                                                               │
│            └───────────────────────────┘                                                                               │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Standard Stack / Component Map

| Component / Item | File Path | Existing State | Phase 48 Target Architecture |
|---|---|---|---|
| `BarContent.qml` | `restow/quickshell/.../bar/BarContent.qml` [VERIFIED: lines 222-281] | Static media max width `(root.useShortenedForm === 1) ? 140 : 200`. `sysTrayGroup.visible: root.useShortenedForm === 0`. | Imports `Quickshell.Services.SystemTray`. Media `Layout.maximumWidth` dynamically bound to screen width equation. `sysTrayGroup.visible` bound to `(root.useShortenedForm === 0) && ((SystemTray.items?.values?.length ?? 0) > 0)`. |
| `Media.qml` | `vendor/dots-hyprland/.../bar/Media.qml` [VERIFIED: lines 1-90] (Upstream) | Monochrome track + artist string `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}` in `colOnLayer1`. Upstream regular file. | Overlay created under `restow/quickshell/.../bar/Media.qml`. Uses `textFormat: Text.StyledText` with `<span>` styling for title (`colOnLayer1`) and artist (`colSubtext`). Preserves clean right elision and escaping. |
| `SysTray.qml` | `restow/quickshell/.../bar/SysTray.qml` [VERIFIED: lines 1-158] | Handles SNI tray items, overflow popup, and separator line. Separator already uses `SystemTray.items.values.length > 0`. | No file modification needed; wrapped by `sysTrayGroup` in `BarContent.qml` which gates the outer pill container. |
| `BarGroup.qml` | `restow/quickshell/.../bar/BarGroup.qml` [VERIFIED: lines 1-51] | Container for status bar pills with M3 fluid width resizing via `Behavior on implicitWidth` (250ms `emphasizedDecel`). | Unchanged; provides fluid animated expansion/contraction when track title length changes. |
| `MediaControls.qml` | `restow/quickshell/.../mediaControls/MediaControls.qml` [VERIFIED: lines 120-137] | Popup anchored dynamically beneath pill via `GlobalStates.mediaPillCenterX` with horizontal boundary clamping. | Unchanged; automatically tracks pill center during responsive expansion via Phase 39 Connections in `BarContent.qml`. |
| `MprisController.qml` | `vendor/dots-hyprland/.../services/MprisController.qml` [VERIFIED: lines 15-22] | Singleton tracking active media player, playback status, trackTitle, trackArtist, trackArtUrl. | Unchanged; supplies `activePlayer.trackTitle` and `activePlayer.trackArtist` to `Media.qml`. |

---

## Architecture Patterns

### Pattern 1: Responsive Media Pill Maximum Width Equation & Dynamic Hugging (RGHT-01, D-01..D-04)

In `BarContent.qml`, `mediaLoader` instantiates `BarGroup` containing `Media`. `Media` is an item within `BarGroup`'s internal `GridLayout`.
Through empirical testing in `scratch/test_layout.qml`, `GridLayout.implicitWidth` respects `Layout.maximumWidth` of its child item while allowing smaller content to define `implicitWidth`:
- When child `implicitWidth` (80px) < `Layout.maximumWidth` (200px): `BarGroup.implicitWidth` = `80 + padding * 2 = 90px`. (Hugs content).
- When child `implicitWidth` (800px) > `Layout.maximumWidth` (200px): `BarGroup.implicitWidth` = `200 + padding * 2 = 210px`. (Clamps cleanly).

#### Mathematical Scaling Model
```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml:236
Layout.maximumWidth: (root.useShortenedForm === 1)
    ? Math.min(Math.max((root.screen?.width ?? 1200) * 0.10, 140), 180)
    : Math.min(Math.max((root.screen?.width ?? 1920) * 0.12, 220), 450)
```

| Screen Width (`screen.width`) | Display Type | Form Tier (`useShortenedForm`) | Formula Applied | Calculated Max Width | Effective Pill Max (`+10px` padding) |
|---|---|---|---|---|---|
| **3440 px** | UWQHD Ultrawide (`DP-1`) | Tier 0 (Full) | $\min(\max(3440 \times 0.12, 220), 450)$ | **412.8 px** | ~423 px |
| **2560 px** | QHD Standard | Tier 0 (Full) | $\min(\max(2560 \times 0.12, 220), 450)$ | **307.2 px** | ~317 px |
| **1920 px** | FHD 1080p Standard | Tier 0 (Full) | $\min(\max(1920 \times 0.12, 220), 450)$ | **230.4 px** | ~240 px |
| **1366 px** | Compact Laptop | Tier 0 (Full) | $\min(\max(1366 \times 0.12, 220), 450)$ | **220.0 px** (Floor) | ~230 px |
| **1200 px** | Shortened Threshold | Tier 1 (Shortened) | $\min(\max(1200 \times 0.10, 140), 180)$ | **140.0 px** (Floor) | ~150 px |
| **1080 px (portrait)** | Secondary Rotated (`HDMI-A-2`)| Tier 1 (Shortened) | $\min(\max(1080 \times 0.10, 140), 180)$ | **140.0 px** (Floor) | ~150 px |
| **1600 px (scaled/short)**| Shortened Wide | Tier 1 (Shortened) | $\min(\max(1600 \times 0.10, 140), 180)$ | **160.0 px** | ~170 px |
| **<= 1000 px** | Hella Shortened | Tier 2 (Hella Shortened) | Media inactive (`active: root.useShortenedForm < 2`) | **0 px** (Collapsed) | 0 px |

#### Fluid Width Animation & Dynamic Hugging
- `BarGroup.qml` contains:
  ```qml
  Behavior on implicitWidth {
      enabled: !root.vertical
      NumberAnimation {
          duration: 250
          easing.type: Easing.BezierSpline
          easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
      }
  }
  ```
  Whenever track metadata changes or playback starts/stops, `BarGroup` animates its width smoothly over 250ms using the Material 3 emphasized deceleration curve (`elementMoveFast`).

---

### Pattern 2: Media Track Title & Artist Visual Hierarchy with HTML Formatting & `Text.ElideRight` (RGHT-02, D-05..D-08)

#### Technical Breakthrough on QtQuick Text Elision
Qt documentation and empirical verification confirm:
- `Text.RichText`: Eliding is explicitly **disabled / unsupported** by Qt Quick.
- `Text.PlainText`: Eliding is supported, but cannot style individual substrings in different colors.
- `Text.StyledText`: Supports basic HTML styling (`<span>`, `<font color="...">`, `<b>`, `<i>`) **AND supports `elide: Text.ElideRight`**!
- In `scratch/test_layout.qml`, testing `<span style='color: ...'>Title</span><span style='color: ...'> • Artist</span>` with `textFormat: Text.StyledText` and `elide: Text.ElideRight` in a `RowLayout` yielded:
  - `paintedWidth: 169px` (cleanly fitting the 172px allocated space)
  - `truncated: true`
  - Clean ellipsis (`...`) rendered at the right edge without breaking font colors or clipping layout.

#### Implementation in `Media.qml`
```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml
        StyledText {
            id: mediaTrackInfoText
            visible: Config.options.bar.verbose
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true // Ensures the text takes up available space
            Layout.rightMargin: rowLayout.spacing
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight // Truncates the text on the right
            color: Appearance.colors.colOnLayer1
            textFormat: Text.StyledText
            text: {
                const escapedTitle = StringUtils.escapeHtml(cleanedTitle);
                const artist = activePlayer?.trackArtist;
                if (!artist) {
                    return `<span style="color: ${Appearance.colors.colOnLayer1};">${escapedTitle}</span>`;
                }
                const escapedArtist = StringUtils.escapeHtml(artist);
                return `<span style="color: ${Appearance.colors.colOnLayer1};">${escapedTitle}</span><span style="color: ${Appearance.colors.colSubtext};"> • ${escapedArtist}</span>`;
            }
        }
```
- **Artist Fallback (D-06):** If `activePlayer?.trackArtist` is null, empty string, or undefined, only `escapedTitle` is emitted in `colOnLayer1`. No trailing separator `" • "` is rendered.
- **XSS & XML Tag Safety:** `StringUtils.escapeHtml` (already part of `qs.modules.common.functions`) converts `&` to `&amp;`, `<` to `&lt;`, `>` to `&gt;`, and quotes to entity codes, preventing malformed song titles (e.g. `"Track <Remix>"`) from breaking the StyledText XML parser.
- **Redundant Width Removal:** The obsolete upstream line `width: rowLayout.width - (CircularProgress.size + rowLayout.spacing * 2)` is removed. In `RowLayout`, setting `width` on an item with `Layout.fillWidth: true` creates binding loop warnings; `RowLayout` automatically calculates item width.

---

### Pattern 3: Dynamic System Tray Empty-State Gating (`SystemTray.items.values.length > 0`) & Layout Reflow (RGHT-03, D-09..D-12)

#### The Problem
In `BarContent.qml`:
```qml
// Existing lines 269-280
            BarGroup {
                id: sysTrayGroup
                Layout.alignment: Qt.AlignVCenter
                visible: root.useShortenedForm === 0

                SysTray { ... }
            }
```
When no tray apps are active, `SysTray` has no visible delegate items. However, `sysTrayGroup` is an instantiated `BarGroup` item with `visible: true`. The `BarGroup` rectangle draws a background pill (`Appearance.colors.colLayer1`) with 5px padding, resulting in an empty, ghost rectangle (~10px wide) on the bar.

#### The Solution
```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml
import Quickshell.Services.SystemTray
...
            BarGroup {
                id: sysTrayGroup
                Layout.alignment: Qt.AlignVCenter
                visible: (root.useShortenedForm === 0) && ((SystemTray.items?.values?.length ?? 0) > 0)

                SysTray {
                    showSeparator: false
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    invertSide: Config?.options.bar.bottom
                }
            }
```
1. **D-Bus Hot Preservation (D-09):** The gating is placed on `sysTrayGroup.visible`, NOT inside a dynamic `Loader.active`. The `SysTray` and Quickshell `SystemTray` D-Bus listener stay resident in memory and continuously connected to `org.kde.StatusNotifierWatcher`.
2. **Instant RowLayout Reflow (D-11):** In Qt Quick `RowLayout`, any item whose `visible` is `false` takes up 0 width and 0 layout spacing. The gap between adjacent elements is exactly `rightSectionRowLayout.spacing` (4px), completely eliminating empty border artifacts. When an app starts and registers with SNI, `sysTrayGroup.visible` becomes `true` and the pill appears instantly.
3. **Primary Screen Guard (D-12):** Gated with `root.useShortenedForm === 0`, ensuring tray items never spill onto compact or rotated secondary monitors.

---

### Pattern 4: GNU Stow Leaf Symlink Topology & Upstream Integrity

To adhere strictly to repository architecture guidelines (INTG-02, D-09, zero vendor churn):
1. **Never modify `vendor/dots-hyprland` directly.**
2. `Media.qml` currently exists in `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Media.qml` and is present as an unclaimed upstream stub on the live system at `~/.config/quickshell/ii/modules/ii/bar/Media.qml`.
3. The personal overlay is created at:
   `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml`
4. The live file is deployed as a leaf symlink:
   - Live backup: `mv ~/.config/quickshell/ii/modules/ii/bar/Media.qml ~/.config/quickshell/ii/modules/ii/bar/Media.qml.bak`
   - Symlink: `ln -sf ../../../../../../github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml ~/.config/quickshell/ii/modules/ii/bar/Media.qml`
5. `./arch/dots-hyprland.sh verify --strict`:
   - Checks that `~/.config/quickshell/ii/modules/ii/bar/Media.qml` is a valid symlink to the repo (`[PASS] verified: ...`).
   - Identifies `Media.qml.bak` under Arm 6 as an allowed installer backup artifact (`[INFO] installer backup artifact: ...`), emitting zero findings.
   - Confirms `FAIL=0 FINDINGS=0`.

---

## Technical Pitfalls & Edge Cases

| # | Pitfall / Edge Case | Risk | Mitigation |
|---|---|---|---|
| **1** | `Text.RichText` elision failure | In Qt Quick, setting `textFormat: Text.RichText` completely disables `elide: Text.ElideRight`, causing text to clip awkwardly or overflow the pill. | Use `textFormat: Text.StyledText` exclusively. StyledText supports basic HTML styling while preserving single-line right elision with an ellipsis. [VERIFIED: `scratch/test_layout.qml`] |
| **2** | Song title HTML injection / malformed XML | Song titles containing `&`, `<`, `>`, `"`, or `'` (e.g. `"Simon & Garfunkel"`, `"Track <VIP Remix>"`) can break the StyledText XML parser, failing to render. | Always wrap dynamic strings in `StringUtils.escapeHtml(...)` before injecting into template literals. [VERIFIED: `StringUtils.qml:231-235`] |
| **3** | Binding loops on `StyledText.width` in `RowLayout` | Upstream `Media.qml` had `width: rowLayout.width - (CircularProgress.size + rowLayout.spacing * 2)`. Setting explicit `width` alongside `Layout.fillWidth: true` in `RowLayout` can cause binding loops. | Remove explicit `width:` property; let `RowLayout` allocate width dynamically based on `Layout.fillWidth: true`. [VERIFIED: empirical test in `scratch/test_layout.qml`] |
| **4** | `root.screen` nullish on cold startup | `root.screen?.width` may be null or undefined for the first render frame before window initialization. | Provide defensive defaults: `(root.screen?.width ?? 1920)` for Tier 0 and `(root.screen?.width ?? 1200)` for Tier 1 to prevent `NaN` calculations. |
| **5** | Missing `Quickshell.Services.SystemTray` import | Calling `SystemTray.items` in `BarContent.qml` without importing `Quickshell.Services.SystemTray` causes a QML ReferenceError. | Add `import Quickshell.Services.SystemTray` to the top of `BarContent.qml`. |
| **6** | Stow folding on directory creation | Using `stow` without `--no-folding` could fold parent directories into symlinks, breaking live configuration and failing `verify --strict`. | Follow repository leaf symlink pattern: ancestor directories remain physical directories; only individual `.qml` files are symlinked. |

---

## Validation Architecture

The phase validation architecture follows the established 5-section assertion harness pattern (exemplified by `scripts/phase47-center-layout-assert.sh` and `scripts/phase46-telemetry-assert.sh`).

### Test Harness: `scripts/phase48-right-zone-assert.sh`

```bash
# Usage:
./scripts/phase48-right-zone-assert.sh [OPTIONS] [1-5]

# Options:
#   -s, --section <1-5>    Execute only the specified section
#   -q, --quick            Run standalone checks (skip slow verify sweep)
#   -c, --syntax           Execute static AST and syntax checks only
#   -h, --help             Show help message
```

### Section Breakdown & Automated Assertions

#### Section 1: Stow Leaf Symlink Topology & Repository Integrity
- Assert `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml` exists and is tracked.
- Assert `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` exists and is tracked.
- Assert live `$HOME/.config/quickshell/ii/modules/ii/bar/Media.qml` is a valid symlink to `restow/quickshell/.../Media.qml`.
- Assert live `$HOME/.config/quickshell/ii/modules/ii/bar/BarContent.qml` is a valid symlink to `restow/quickshell/.../BarContent.qml`.
- Assert ancestor directories (`~/.config/quickshell`, `~/.config/quickshell/ii/modules/ii/bar`) are real physical directories (zero folding).
- Assert `vendor/dots-hyprland` submodule has 0 uncommitted changes.

#### Section 2: BarContent.qml Responsive Width Equation & Tray Gating AST
- Assert `import Quickshell.Services.SystemTray` is present in `BarContent.qml`.
- Assert `mediaLoader` `Layout.maximumWidth` contains responsive calculation:
  - `(root.screen?.width ?? 1200) * 0.10` with clamp [140, 180] for `useShortenedForm === 1`.
  - `(root.screen?.width ?? 1920) * 0.12` with clamp [220, 450] for `useShortenedForm === 0`.
- Assert `sysTrayGroup` visibility is bound to:
  `visible: (root.useShortenedForm === 0) && ((SystemTray.items?.values?.length ?? 0) > 0)` or equivalent safe nullish check.
- Assert `BarContent.qml` retains Phase 39 dynamic coordinate tracking:
  - `updateMediaPillCoords()` function present.
  - `GlobalStates.mediaPillCenterX = pt.x` present.
  - `Connections` on `mediaLoader.item` for `onWidthChanged` and `onXChanged` present.

#### Section 3: Media.qml Typography, Styling Hierarchy & Elision AST
- Assert `Media.qml` imports `qs.modules.common.functions` for `StringUtils`.
- Assert `StyledText` uses `textFormat: Text.StyledText`.
- Assert `StyledText` uses `elide: Text.ElideRight`.
- Assert `StyledText` binds `color: Appearance.colors.colOnLayer1`.
- Assert `text` binding applies `StringUtils.escapeHtml`.
- Assert `text` binding formats artist in `Appearance.colors.colSubtext` with separator `" • "`.
- Assert `text` binding cleanly omits separator when artist is absent.
- Assert `StyledText` visibility is gated by `Config.options.bar.verbose`.
- Assert `MouseArea` event bindings are preserved:
  - Left click toggles `GlobalStates.mediaControlsOpen`.
  - Middle click toggles play/pause (`activePlayer.togglePlaying()`).
  - Right / Forward click advances track (`activePlayer.next()`).
  - Back click returns to previous track (`activePlayer.previous()`).

#### Section 4: Mathematical Simulation & Logic Verification
- Evaluate responsive equation in node/python/bash across reference screen dimensions:
  - 3440px -> 412.8 px (clamped [220, 450] -> 412.8 px)
  - 2560px -> 307.2 px (clamped [220, 450] -> 307.2 px)
  - 1920px -> 230.4 px (clamped [220, 450] -> 230.4 px)
  - 1366px -> 163.9 px (clamped [220, 450] -> 220.0 px)
  - 1200px (shortened) -> 120.0 px (clamped [140, 180] -> 140.0 px)
  - 1080px (portrait) -> 108.0 px (clamped [140, 180] -> 140.0 px)
- Evaluate tray gating truth table:
  - `useShortenedForm: 0`, `trayCount: 0` -> `visible: false` (Pill hidden)
  - `useShortenedForm: 0`, `trayCount: 1` -> `visible: true` (Pill shown)
  - `useShortenedForm: 0`, `trayCount: 5` -> `visible: true` (Pill shown)
  - `useShortenedForm: 1`, `trayCount: 2` -> `visible: false` (Secondary screen hidden)
  - `useShortenedForm: 2`, `trayCount: 2` -> `visible: false` (Secondary screen hidden)

#### Section 5: Strict Repository Verification Orchestration
- Execute `./arch/dots-hyprland.sh verify --strict`.
- Enforce exit 0 with `FAIL=0 FINDINGS=0`.

---

## Provenance and Verification Claims

- [VERIFIED: `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml:222-281`] Current static `Layout.maximumWidth` clamp (200px) and static `sysTrayGroup.visible` binding.
- [VERIFIED: `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml:20-53`] Existing Phase 39 dynamic popup coordinate tracking via `updateMediaPillCoords()` and `Connections`.
- [VERIFIED: `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Media.qml:1-90`] Upstream media player layout, monochrome text string, mouse button bindings, and circular progress indicator.
- [VERIFIED: `restow/quickshell/.config/quickshell/ii/modules/ii/bar/SysTray.qml:1-158`] SNI item list model, overflow menu, and `SystemTray.items.values.length > 0` condition.
- [VERIFIED: `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/functions/StringUtils.qml:227-235`] Canonical `escapeHtml` utility for XML/HTML sanitization.
- [VERIFIED: empirical test in `scratch/test_layout.qml`] `Text.StyledText` in Qt Quick 6 natively supports `elide: Text.ElideRight` alongside HTML `<span>` coloring, and `GridLayout` clamps implicit width based on child `Layout.maximumWidth`.
- [VERIFIED: live execution `./arch/dots-hyprland.sh verify --strict`] Baseline passes with `FAIL=0 FINDINGS=0`.
