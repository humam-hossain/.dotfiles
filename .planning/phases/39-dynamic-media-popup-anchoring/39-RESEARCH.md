# Phase 39: Dynamic Media Popup Anchoring - Research

**Researched:** 2026-09-23  
**Status:** Complete  
**Confidence:** HIGH  

---

<user_constraints>
## Decisions

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

## Claude's Discretion
- Exact variable naming for internal clamping helpers in `MediaControls.qml`.
- Specific test harness assertion scripts in `scripts/` validating coordinate clamping and multi-monitor fallback.

## Deferred Ideas
- None — discussion stayed strictly within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| Requirement ID | Description | Research Support Summary |
|---|---|---|
| **MEDIA-01** | `MediaControls.qml` popup dynamically anchors directly beneath the top status bar's `Media` pill across active monitors. | Supported via `BarContent.qml` coordinate capture (`mediaLoader.item.mapToItem(null, ...)`), `GlobalStates.qml` bridge properties (`mediaPillCenterX`, `mediaPillCenterY`, `mediaPillScreen`), and `MediaControls.qml` `PanelWindow.screen` binding (`GlobalStates.mediaPillScreen ?? null`) with `margins.left` anchoring formula. |
| **MEDIA-02** | `MediaControls.qml` popup enforces horizontal boundary clamping (`Math.min` / `Math.max`) to prevent off-screen clipping. | Supported via D-10 clamping formula enforcing `Appearance.sizes.hyprlandGapsOut` [VERIFIED: `Appearance.qml:399`: `property real hyprlandGapsOut: 5`] minimum edge margin across 1920x1080 standard, 3440x1440 ultrawide, and narrow displays, with fallback to upstream center offset when `mediaPillCenterX <= 0`. |
| **INTG-01** | All QML modifications deployed via `restow/quickshell/` leaf symlinks without modifying `vendor/dots-hyprland`. | Supported via `restow/quickshell/` overlay tree deployment (`GlobalStates.qml`, `MediaControls.qml`, `BarContent.qml`, `VerticalBarContent.qml`) via GNU Stow (`stow --verbose=5 --no-folding -t ~ quickshell`). |
| **INTG-02** | Automated assertion test harness validates media popup positioning. | Supported via `scripts/phase39-media-popup-assert.sh` covering AST checks, headless Quickshell coordinate conversion tests, clamping math execution across screen sizes, and porcelain integrity. |
| **INTG-03** | `arch/dots-hyprland.sh verify --strict` passes with 0 findings and zero git working-tree churn. | Supported via strict verification audit ensuring leaf symlinks, no directory folding, and clean upstream submodule. |
</phase_requirements>

---

## Architectural Responsibility Map

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             Bar Window (Bar.qml)                                 │
│  PanelWindow (screen: modelData, anchors: left=true, right=true)                 │
│  ┌────────────────────────────────────────────────────────────────────────────┐  │
│  │ BarContent.qml (restow overlay)                                            │  │
│  │  - mediaLoader (Loader hosting BarGroup { Media {} })                      │  │
│  │  - mediaHoverHandler (HoverHandler detecting cursor on pill)               │  │
│  │  - On click / toggle: maps mediaLoader.item center to root (0,0) screen    │  │
│  │    pt = mediaLoader.item.mapToItem(null, width/2, height/2)               │  │
│  │  - On title shift: reactive Connections updates coords dynamically         │  │
│  └──────────────────────────────────────┬─────────────────────────────────────┘  │
└─────────────────────────────────────────┼────────────────────────────────────────┘
                                          │ sets coords + screen
                                          ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│ GlobalStates.qml (restow overlay singleton)                                      │
│  - mediaControlsOpen: bool                                                       │
│  - mediaPillCenterX: real (-1 fallback sentinel)                                 │
│  - mediaPillCenterY: real (-1 fallback sentinel)                                 │
│  - mediaPillScreen: ShellScreen / var (null fallback)                            │
└─────────────────────────────────────────┬────────────────────────────────────────┘
                                          │ reactive property bindings
                                          ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│ MediaControls.qml (restow overlay PanelWindow)                                   │
│  - screen: GlobalStates.mediaPillScreen ?? null                                  │
│  - margins.top: Appearance.sizes.barHeight (or clamped Y if vertical)            │
│  - margins.left: clampedX formula (gap <= targetX <= screen.width - width - gap) │
│    or fallback: (screen.width/2) - (osdWidth/2) - widgetWidth                    │
└──────────────────────────────────────────────────────────────────────────────────┘
```

| Component | Repository Path | Responsibility |
|---|---|---|
| **State Bridge** | `restow/quickshell/.config/quickshell/ii/GlobalStates.qml` | Declares `mediaPillCenterX`, `mediaPillCenterY`, and `mediaPillScreen` on the global desktop shell singleton. |
| **Horizontal Bar Capture** | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` | Captures pill center X/Y using `mediaLoader.item.mapToItem(null, ...)` when `mediaHoverHandler.hovered` is true; updates `GlobalStates`; resets coordinates to `-1`/`null` on close; reactively re-evaluates coordinates on layout width shifts. |
| **Vertical Bar Capture** | `restow/quickshell/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml` | Captures vertical pill center Y using `verticalMedia.mapToItem(null, ...)` when `verticalMediaHoverHandler.hovered` is true; updates `GlobalStates`; resets coordinates on close. |
| **Popup Window** | `restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml` | Binds `screen: GlobalStates.mediaPillScreen ?? null`; calculates clamped `margins.left` (and clamped `margins.top` in vertical mode); falls back to upstream center position when `mediaPillCenterX <= 0`. |
| **Validation Harness** | `scripts/phase39-media-popup-assert.sh` | Executes static AST checks, headless Quickshell QML coordinate calculations, edge clamping boundary checks, and runs `./arch/dots-hyprland.sh verify --strict`. |

---

## Standard Stack

| Technology | In-Repo Version / Path | Purpose & Role |
|---|---|---|
| **Quickshell** | `Quickshell 0.2.1 (revision 7511545ee...)` [VERIFIED: `quickshell --version`] | Wayland desktop shell runtime providing `PanelWindow`, `WlrLayershell`, `Scope`, `Loader`, `Singleton`, `Quickshell.screens`. |
| **Qt Quick / QML** | Qt 6.8+ (Linux x86_64) | UI declarative engine providing `Item.mapToItem()`, `HoverHandler`, `Connections`, `Math` primitives. |
| **Hyprland** | `Hyprland 0.47.0+` (Wayland compositor) | Window manager; provides `Hyprland.focusedMonitor` and layer-shell surface placement. |
| **GNU Stow** | 2.4.1 [VERIFIED: `arch/pkglist-native.txt:164`] | Symlink farm manager deploying leaf symlinks from `restow/quickshell/` to `~/.config/quickshell/`. |
| **Appearance Constants** | `vendor/.../Appearance.qml` [VERIFIED: `Appearance.qml:387-415`] | Central design system sizes (`hyprlandGapsOut: 5`, `barHeight: 40`, `mediaControlsWidth: 440`, `mediaControlsHeight: 160`, `osdWidth: 180`). |

---

## In-Repo Discrete Value Provenance

The following discrete values are quoted verbatim from source files in accordance with repository provenance rules:

| Property / Discrete Value | Source File | Line Number(s) | Verbatim Code Quote |
|---|---|---|---|
| `baseBarHeight` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` | 388 | `property real baseBarHeight: 40` |
| `barHeight` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` | 389-390 | `property real barHeight: Config.options.bar.cornerStyle === 1 ?` <br> `(baseBarHeight + root.sizes.hyprlandGapsOut * 2) : baseBarHeight` |
| `hyprlandGapsOut` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` | 399 | `property real hyprlandGapsOut: 5` |
| `mediaControlsWidth` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` | 400 | `property real mediaControlsWidth: 440` |
| `mediaControlsHeight` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` | 401 | `property real mediaControlsHeight: 160` |
| `osdWidth` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` | 403 | `property real osdWidth: 180` |
| `baseVerticalBarWidth` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` | 408 | `property real baseVerticalBarWidth: 46` |
| `verticalBarWidth` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` | 409-410 | `property real verticalBarWidth: Config.options.bar.cornerStyle === 1 ?` <br> `(baseVerticalBarWidth + root.sizes.hyprlandGapsOut * 2) : baseVerticalBarWidth` |
| `mediaControlsOpen` | `vendor/dots-hyprland/dots/.config/quickshell/ii/GlobalStates.qml` | 16 | `property bool mediaControlsOpen: false` |
| `screen` binding in BarContent | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` | 15 | `property var screen: root.QsWindow.window?.screen` |
| `mediaLoader` active condition | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` | 194 | `active: (root.useShortenedForm < 2) && (MprisController.activePlayer != null && (MprisController.activePlayer.trackTitle?.length > 0))` |
| Upstream `MediaControls.qml` margins | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml` | 100-105 | ```qml<br>margins {<br>    top: Config.options.bar.vertical ? ((panelWindow.screen.height / 2) - widgetHeight * 1.5) : Appearance.sizes.barHeight<br>    bottom: Appearance.sizes.barHeight<br>    left: Config.options.bar.vertical ? Appearance.sizes.barHeight : ((panelWindow.screen.width / 2) - (osdWidth / 2) - widgetWidth)<br>    right: Appearance.sizes.barHeight<br>}``` |
| Upstream `StyledPopup.qml` positioning | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml` | 38-41 | ```qml<br>left: {<br>    if (!Config.options.bar.vertical) return root.QsWindow?.mapFromItem(<br>        root.hoverTarget, <br>        (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0<br>    ).x;<br>    return Appearance.sizes.verticalBarWidth<br>}``` |

---

## Architecture Patterns

### 1. Scene Coordinate Conversion (`Item.mapToItem(null, ...)`)

In Qt Quick, `item.mapToItem(null, x, y)` maps local coordinates within `item` to the root item of the window [VERIFIED: QtQuick API & tested in headless Quickshell]. Because `Bar.qml`'s `PanelWindow` has `anchors.left: true, anchors.right: true` [VERIFIED: `Bar.qml:69-70`], the root item's horizontal origin `x = 0` corresponds exactly to the monitor's left edge (`x = 0`).

```qml
// In BarContent.qml:
function updateMediaPillCoords() {
    if (!mediaLoader.item) return;
    const pt = mediaLoader.item.mapToItem(null, mediaLoader.item.width / 2, mediaLoader.item.height / 2);
    GlobalStates.mediaPillCenterX = pt.x;
    GlobalStates.mediaPillCenterY = pt.y;
    GlobalStates.mediaPillScreen = root.screen;
}
```

### 2. Multi-Monitor Disambiguation via HoverHandler

In multi-monitor environments, `BarContent.qml` is instantiated once per active monitor inside `Bar.qml`'s `Variants` [VERIFIED: `Bar.qml:17-32`]. When a user clicks the `Media` pill, `GlobalStates.mediaControlsOpen` toggles globally.
To ensure only the monitor where the click occurred updates `GlobalStates.mediaPillScreen` and coordinates, a `HoverHandler` is attached to `mediaLoader`. When the user clicks the pill, the cursor is over `mediaLoader` on that monitor, meaning `mediaHoverHandler.hovered` is true on that monitor and false on all other monitors.

```qml
// Inside mediaLoader in BarContent.qml:
HoverHandler {
    id: mediaHoverHandler
}

Connections {
    target: GlobalStates
    function onMediaControlsOpenChanged() {
        if (GlobalStates.mediaControlsOpen) {
            if (mediaHoverHandler.hovered && mediaLoader.item) {
                root.updateMediaPillCoords();
            }
        } else {
            if (GlobalStates.mediaPillScreen === root.screen) {
                GlobalStates.mediaPillCenterX = -1;
                GlobalStates.mediaPillCenterY = -1;
                GlobalStates.mediaPillScreen = null;
            }
        }
    }
}
```

### 3. Reactive Dynamic Tracking on Pill Layout Shifts (D-04)

When track titles change, MPRIS updates cause `Media.qml`'s `StyledText` width to change [VERIFIED: `Media.qml:75-86`]. This causes `mediaLoader.item` (`BarGroup`) width and position to shift. A reactive connection updates coordinates while the popup remains open:

```qml
Connections {
    target: (GlobalStates.mediaControlsOpen && GlobalStates.mediaPillScreen === root.screen) ? mediaLoader.item : null
    function onWidthChanged() { root.updateMediaPillCoords(); }
    function onXChanged() { root.updateMediaPillCoords(); }
}
```

### 4. Edge Clamping Formula with Subpixel Rounding (D-09, D-10)

The popup center is aligned with `GlobalStates.mediaPillCenterX`. The left margin is clamped such that the popup never comes closer than `Appearance.sizes.hyprlandGapsOut` (5px) to either screen edge.

```javascript
// Clamping calculation in MediaControls.qml:
left: {
    if (Config.options.bar.vertical) {
        return Appearance.sizes.barHeight;
    }
    if (GlobalStates.mediaPillCenterX <= 0 || !panelWindow.screen) {
        // Fallback to upstream center calculation (D-08)
        return (panelWindow.screen?.width / 2) - (root.osdWidth / 2) - root.widgetWidth;
    }
    const gap = Appearance.sizes.hyprlandGapsOut;
    const targetX = GlobalStates.mediaPillCenterX - (root.widgetWidth / 2);
    const minX = gap;
    const maxX = panelWindow.screen.width - root.widgetWidth - gap;
    const clampedX = (maxX < minX) ? minX : Math.max(minX, Math.min(targetX, maxX));
    return Math.round(clampedX);
}
```

### 5. Multi-Monitor Screen Binding (D-07)

On `PanelWindow` in `MediaControls.qml`:
```qml
sourceComponent: PanelWindow {
    id: panelWindow
    visible: true
    screen: GlobalStates.mediaPillScreen ?? null
```
When `mediaPillScreen` is set, `PanelWindow` displays on that monitor. When `null` (e.g. keyboard shortcut), it defaults to the primary monitor or focused monitor.

---

## Don't Hand-Roll

| Problem | Built-in / Standard Mechanism | Why Hand-Rolling Fails |
|---|---|---|
| Screen Coordinate Mapping | `Item.mapToItem(null, x, y)` | Manually walking `parent` items to sum offsets fails when layers, margins, and transforms are involved. `mapToItem` is built into QtQuick and accounts for all parent hierarchy transforms. |
| Pointer Detection on Pill | `HoverHandler` | Adding an outer `MouseArea` breaks click handling of inner buttons (`activePlayer.togglePlaying()`, previous/next) in `Media.qml`. `HoverHandler` observes hover events non-intrusively. |
| Clamping Boundaries | `Math.max(minX, Math.min(targetX, maxX))` | Writing bespoke if/else chains risks boundary inversion on narrow screens (`maxX < minX`). The ternary guard `(maxX < minX) ? minX : ...` safely handles any screen width. |
| Deploying Overlays | GNU Stow (`cd restow && stow -t ~ quickshell`) | Manual symlinking or copying risks directory folding, missing live backups, or breaking `arch/dots-hyprland.sh verify --strict`. |

---

## Common Pitfalls

### Pitfall 1: Calling `mapToItem` When `mediaLoader.item` Is Null
**Risk:** When MPRIS has no active player, `mediaLoader.active` is `false`, so `mediaLoader.item` is `null` [VERIFIED: `BarContent.qml:194`]. Calling `mediaLoader.item.mapToItem` directly causes `TypeError: Cannot read property 'mapToItem' of null`.  
**Mitigation:** Guard all calls with `if (!mediaLoader.item) return;` or optional chaining `mediaLoader.item?.mapToItem(...)`.

### Pitfall 2: PanelWindow Screen Null Reference During Init
**Risk:** When `PanelWindow` is first constructed, `panelWindow.screen` may momentarily evaluate to `null` before Wayland output assignment occurs. Accessing `panelWindow.screen.width` directly causes runtime QML error: `TypeError: Cannot read property 'width' of null`.  
**Mitigation:** Use safe navigation or fallback: `(panelWindow.screen?.width ?? 1920)`. If `panelWindow.screen` is null, trigger the fallback center calculation.

### Pitfall 3: Multi-Monitor Coordinate Crosstalk
**Risk:** If both `BarContent` instances react to `onMediaControlsOpenChanged` unconditionally, Monitor 2 will overwrite Monitor 1's coordinates even if the user clicked the pill on Monitor 1.  
**Mitigation:** Filter by `mediaHoverHandler.hovered`. Only the bar instance with the mouse cursor currently hovering the pill updates `GlobalStates`.

### Pitfall 4: Submodule Working Tree Churn (INTG-01, INTG-03)
**Risk:** Editing `vendor/dots-hyprland/dots/.config/quickshell/ii/GlobalStates.qml` or `MediaControls.qml` directly dirties git submodule tracking and causes `./arch/dots-hyprland.sh verify --strict` to fail.  
**Mitigation:** Submodule `vendor/dots-hyprland` must remain 100% untouched. All changes must be created in `restow/quickshell/` and stowed as leaf symlinks.

### Pitfall 5: Directory Folding During Stow
**Risk:** If a parent directory like `~/.config/quickshell/ii/modules/ii/mediaControls` does not exist as a real directory, running `stow` without `--no-folding` could symlink the entire directory instead of creating a leaf file symlink, violating repository architecture rules.  
**Mitigation:** Ensure parent directory exists as a real directory in `$HOME/.config/quickshell/...` and always invoke stow with `--no-folding`: `cd "$REPO_ROOT/restow" && stow --verbose=5 --no-folding -t ~ quickshell`.

### Pitfall 6: Subpixel Blur on Wayland Layershell
**Risk:** Floating-point division (`widgetWidth / 2` or `pillWidth / 2`) can produce non-integer margin values (e.g. `1280.5`), causing subpixel text blur or blurry window borders under Wayland scaling.  
**Mitigation:** Wrap the final clamped value in `Math.round(clampedX)` (Decision D-10).

---

## Code Examples

### 1. `restow/quickshell/.config/quickshell/ii/GlobalStates.qml`

Added bridge properties per D-05:

```qml
// In GlobalStates.qml:
Singleton {
    id: root
    property bool barOpen: true
    property bool crosshairOpen: false
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool mediaControlsOpen: false
    property real mediaPillCenterX: -1
    property real mediaPillCenterY: -1
    property var mediaPillScreen: null
    // ... rest of upstream properties ...
```

### 2. `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`

Hover detection, coordinate mapping, and lifecycle reset:

```qml
// Inside BarContent.qml root:
function updateMediaPillCoords() {
    if (!mediaLoader.item) return;
    const pt = mediaLoader.item.mapToItem(null, mediaLoader.item.width / 2, mediaLoader.item.height / 2);
    GlobalStates.mediaPillCenterX = pt.x;
    GlobalStates.mediaPillCenterY = pt.y;
    GlobalStates.mediaPillScreen = root.screen;
}

Connections {
    target: GlobalStates
    function onMediaControlsOpenChanged() {
        if (GlobalStates.mediaControlsOpen) {
            if (mediaHoverHandler.hovered && mediaLoader.item) {
                root.updateMediaPillCoords();
            }
        } else {
            if (GlobalStates.mediaPillScreen === root.screen) {
                GlobalStates.mediaPillCenterX = -1;
                GlobalStates.mediaPillCenterY = -1;
                GlobalStates.mediaPillScreen = null;
            }
        }
    }
}

Connections {
    target: (GlobalStates.mediaControlsOpen && GlobalStates.mediaPillScreen === root.screen) ? mediaLoader.item : null
    function onWidthChanged() { root.updateMediaPillCoords(); }
    function onXChanged() { root.updateMediaPillCoords(); }
}

// Inside RowLayout -> mediaLoader:
Loader {
    id: mediaLoader
    Layout.alignment: Qt.AlignVCenter
    active: (root.useShortenedForm < 2) && (MprisController.activePlayer != null && (MprisController.activePlayer.trackTitle?.length > 0))
    visible: active

    HoverHandler {
        id: mediaHoverHandler
    }

    sourceComponent: BarGroup {
        Media {
            visible: root.useShortenedForm < 2
            Layout.fillWidth: true
            Layout.maximumWidth: (root.useShortenedForm === 1) ? 140 : 200
        }
    }
}
```

### 3. `restow/quickshell/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml`

Vertical coordinate capture:

```qml
// Inside VerticalBarContent.qml root:
function updateVerticalMediaPillCoords() {
    if (!verticalMedia) return;
    const pt = verticalMedia.mapToItem(null, verticalMedia.width / 2, verticalMedia.height / 2);
    GlobalStates.mediaPillCenterX = pt.x;
    GlobalStates.mediaPillCenterY = pt.y;
    GlobalStates.mediaPillScreen = root.screen;
}

Connections {
    target: GlobalStates
    function onMediaControlsOpenChanged() {
        if (GlobalStates.mediaControlsOpen) {
            if (verticalMediaHoverHandler.hovered) {
                root.updateVerticalMediaPillCoords();
            }
        } else {
            if (GlobalStates.mediaPillScreen === root.screen) {
                GlobalStates.mediaPillCenterX = -1;
                GlobalStates.mediaPillCenterY = -1;
                GlobalStates.mediaPillScreen = null;
            }
        }
    }
}

Connections {
    target: (GlobalStates.mediaControlsOpen && GlobalStates.mediaPillScreen === root.screen) ? verticalMedia : null
    function onYChanged() { root.updateVerticalMediaPillCoords(); }
    function onHeightChanged() { root.updateVerticalMediaPillCoords(); }
}

// Inside BarGroup -> verticalMedia:
VerticalMedia {
    id: verticalMedia
    Layout.fillWidth: true
    Layout.fillHeight: false

    HoverHandler {
        id: verticalMediaHoverHandler
    }
}
```

### 4. `restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml`

Screen binding and clamped margins override:

```qml
// Inside MediaControls.qml Loader:
sourceComponent: PanelWindow {
    id: panelWindow
    visible: true
    screen: GlobalStates.mediaPillScreen ?? null

    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    implicitWidth: root.widgetWidth
    implicitHeight: playerColumnLayout.implicitHeight
    color: "transparent"
    WlrLayershell.namespace: "quickshell:mediaControls"

    anchors {
        top: !Config.options.bar.bottom || Config.options.bar.vertical
        bottom: Config.options.bar.bottom && !Config.options.bar.vertical
        left: !(Config.options.bar.vertical && Config.options.bar.bottom)
        right: Config.options.bar.vertical && Config.options.bar.bottom
    }
    margins {
        top: {
            if (Config.options.bar.vertical) {
                if (GlobalStates.mediaPillCenterY <= 0 || !panelWindow.screen) {
                    return (panelWindow.screen?.height / 2) - (root.widgetHeight * 1.5);
                }
                const gap = Appearance.sizes.hyprlandGapsOut;
                const targetY = GlobalStates.mediaPillCenterY - (root.widgetHeight / 2);
                const minY = gap;
                const maxY = panelWindow.screen.height - root.widgetHeight - gap;
                const clampedY = (maxY < minY) ? minY : Math.max(minY, Math.min(targetY, maxY));
                return Math.round(clampedY);
            }
            return Appearance.sizes.barHeight;
        }
        bottom: Appearance.sizes.barHeight
        left: {
            if (Config.options.bar.vertical) {
                return Appearance.sizes.barHeight;
            }
            if (GlobalStates.mediaPillCenterX <= 0 || !panelWindow.screen) {
                return (panelWindow.screen?.width / 2) - (root.osdWidth / 2) - root.widgetWidth;
            }
            const gap = Appearance.sizes.hyprlandGapsOut;
            const targetX = GlobalStates.mediaPillCenterX - (root.widgetWidth / 2);
            const minX = gap;
            const maxX = panelWindow.screen.width - root.widgetWidth - gap;
            const clampedX = (maxX < minX) ? minX : Math.max(minX, Math.min(targetX, maxX));
            return Math.round(clampedX);
        }
        right: Appearance.sizes.barHeight
    }
```

---

## Assumptions Log

| # | Assumption | Confidence | Validation Method |
|---|---|---|---|
| A-01 | `Item.mapToItem(null, x, y)` in QtQuick / Quickshell maps coordinates relative to the root item of the window. | HIGH | Tested and confirmed via headless `quickshell -p` snippet (`DEBUG qml: Mapped center: 575 20`). |
| A-02 | `Bar.qml` spans the full screen width from `x=0` to `x=screen.width`. | HIGH | Verified in `Bar.qml:69-70` (`anchors.left: true, anchors.right: true`). |
| A-03 | Attaching `HoverHandler` to `mediaLoader` does not consume or intercept mouse clicks intended for inner `MouseArea` in `Media.qml`. | HIGH | Tested in headless Quickshell (`test_loader_hover.qml`); `HoverHandler` is a passive pointer event handler in QtQuick. |
| A-04 | When `GlobalStates.mediaPillScreen` is assigned to `PanelWindow.screen`, Quickshell renders the window on that monitor. | HIGH | Tested and confirmed via headless `test_screen_binding.qml`. |
| A-05 | `PanelWindow` margins can be reactively updated via property bindings without causing layer-shell surface recreation. | HIGH | Verified against upstream `StyledPopup.qml:36-53` which uses reactive `margins.left` property bindings. |
| A-06 | Resetting coordinates on popup dismissal (`mediaPillCenterX = -1`) guarantees clean fallback when subsequently opened via keybind. | HIGH | Verified against D-08 logic: sentinel `< 0` directs formula to upstream center calculation. |

---

## Open Questions

- **None.** All technical aspects regarding coordinate conversion, multi-monitor disambiguation, clamping mathematics, Stow symlink strategy, and assertion harness design have been investigated and verified.

---

## Environment Availability

| Tool / Resource | Availability Status | Notes / Location |
|---|---|---|
| `quickshell` | Available | `Quickshell 0.2.1` (`/usr/bin/quickshell`) [VERIFIED: `quickshell --version`] |
| `hyprland` | Available | Active compositor running on system [VERIFIED: `hyprctl monitors`] |
| Active Monitors | Available | Primary monitor `DP-1` (3440x1440@60Hz ultrawide) [VERIFIED: `hyprctl monitors`] |
| `stow` | Available | `GNU Stow 2.4.1` (`/usr/bin/stow`) [VERIFIED: `which stow`] |
| `qmllint` | Available | `/usr/bin/qmllint` |
| Verification Engine | Available | `./arch/dots-hyprland.sh verify --strict` passes with `FAIL=0 FINDINGS=0` [VERIFIED] |
| Git Submodule | Clean | `vendor/dots-hyprland` working tree is 100% clean [VERIFIED: `git status --porcelain`] |

---

## Validation Architecture

### Test Harness Architecture: `scripts/phase39-media-popup-assert.sh`

Following the proven architecture from `scripts/phase38-power-profiles-assert.sh` and `scripts/phase37-voice-pill-assert.sh`:

```
scripts/phase39-media-popup-assert.sh
├── Section 1: Symlink & Packaging Integrity (INTG-01, D-05, D-13)
│   ├── Target files in ~/.config/quickshell/ii/ are symlinks into restow/quickshell/
│   ├── Parent directories are real directories (no folding)
│   └── Submodule vendor/dots-hyprland is 100% clean (zero git churn)
├── Section 2: QML Property & Clamping Math Static AST (MEDIA-01, MEDIA-02, D-01, D-08, D-10)
│   ├── GlobalStates.qml defines mediaPillCenterX, mediaPillCenterY, mediaPillScreen
│   ├── BarContent.qml defines mediaHoverHandler and updateMediaPillCoords
│   ├── VerticalBarContent.qml defines verticalMediaHoverHandler and updateVerticalMediaPillCoords
│   └── MediaControls.qml binds screen and implements clamped margins
├── Section 3: Headless Quickshell Coordinate Mapping & Clamping Execution (MEDIA-01, MEDIA-02)
│   ├── Clamping math on 1920x1080 standard display (normal center, left clamp, right clamp)
│   ├── Clamping math on 3440x1440 ultrawide display
│   ├── Clamping math on 400px ultra-narrow display (minX fallback guard)
│   └── Fallback math when mediaPillCenterX <= 0 (matches upstream exact center)
├── Section 4: Multi-Monitor Screen Binding & State Reset Lifecycle (MEDIA-01, D-06, D-07, D-08)
│   ├── Headless Scope verification: setting/resetting GlobalStates properties
│   └── Dismissal resets coordinates to sentinel -1 / null
└── Section 5: Repository Integrity & Strict Verification (INTG-02, INTG-03)
    ├── ./arch/dots-hyprland.sh verify --strict passes with FAIL=0 FINDINGS=0
    └── Git working-tree porcelain snapshot check (zero unexpected diff)
```

### REQ-ID to Validation Mapping

| Requirement ID | Assert Harness Section | Verification Method |
|---|---|---|
| **MEDIA-01** | Section 2, Section 3, Section 4 | Static AST verifies `mapToItem` call and `screen` binding; headless runner executes coordinate mapping and screen assignment; validates popup center alignment. |
| **MEDIA-02** | Section 2, Section 3 | Static AST verifies `Math.min` / `Math.max` clamping logic with `Appearance.sizes.hyprlandGapsOut`; headless runner asserts calculated X values on 1920x1080 (1280, 1475, 5), 3440x1440 (2980, 2995), and 400px (5). |
| **INTG-01** | Section 1 | Validates that `GlobalStates.qml`, `MediaControls.qml`, `BarContent.qml`, and `VerticalBarContent.qml` are deployed via `restow/quickshell/` leaf symlinks without folding. |
| **INTG-02** | Sections 1–5 | Full execution of `scripts/phase39-media-popup-assert.sh` exits 0 with `FAIL=0 FINDINGS=0`. |
| **INTG-03** | Section 5 | `./arch/dots-hyprland.sh verify --strict` runs and outputs `FAIL=0 FINDINGS=0`. |

### Wave 0 Gaps
Before running the assertion harness, the following files must be created:
1. `scripts/phase39-media-popup-assert.sh` (executable test harness with `--section` and `--syntax` flags).
2. `restow/quickshell/.config/quickshell/ii/GlobalStates.qml` (seeding from upstream + bridge properties).
3. `restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml` (seeding from upstream + screen & margins modifications).

---

## Security Domain

- **Layer-Shell Surface Positioning:** Positioning math is purely visual geometry calculation within Quickshell. It does not introduce new external inputs, IPC commands, or privilege escalation paths.
- **Process Boundaries:** Cava visualizer and MPRIS player interactions remain unchanged from upstream [VERIFIED: `MediaControls.qml:56-72`].
- **Idempotency:** State resets on dismissal ensure no stale coordinates or screen references leak across shell sessions or desktop locks.
