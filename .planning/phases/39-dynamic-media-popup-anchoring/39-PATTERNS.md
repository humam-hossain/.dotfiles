# Phase 39: Dynamic Media Popup Anchoring - Pattern Map

**Mapped:** 2026-09-23
**Files analyzed:** 5 (3 modified, 2 new)
**Analogs found:** 5 / 5 (100% coverage)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `restow/quickshell/.config/quickshell/ii/GlobalStates.qml` | store / singleton | pub-sub / state | `vendor/dots-hyprland/dots/.config/quickshell/ii/GlobalStates.qml` | exact |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` | component | event-driven / transform | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` & `vendor/.../bar/StyledPopup.qml` | exact |
| `restow/quickshell/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml` | component | event-driven / transform | `restow/quickshell/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml` | exact |
| `restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml` | component / panel | reactive / request-response | `vendor/.../mediaControls/MediaControls.qml` & `vendor/.../bar/StyledPopup.qml` | exact |
| `scripts/phase39-media-popup-assert.sh` | test | batch / request-response | `scripts/phase38-power-profiles-assert.sh` & `scripts/phase37-voice-pill-assert.sh` | role-match |

---

## Pattern Assignments

### 1. `restow/quickshell/.config/quickshell/ii/GlobalStates.qml` (store / singleton, state)

**Analog:** `vendor/dots-hyprland/dots/.config/quickshell/ii/GlobalStates.qml` (lines 10-33)

**Singleton Property Pattern** (`GlobalStates.qml` lines 10-20):
```qml
Singleton {
    id: root
    property bool barOpen: true
    property bool crosshairOpen: false
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool mediaControlsOpen: false
```

**Pattern Application for Phase 39:**
Seed `restow/quickshell/.config/quickshell/ii/GlobalStates.qml` from upstream and append state bridge properties for coordinate sharing:
```qml
    // Phase 39: Dynamic Media Popup Anchoring Bridge
    property real mediaPillCenterX: -1
    property real mediaPillCenterY: -1
    property var mediaPillScreen: null
```

---

### 2. `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` (component, event-driven)

**Analog 1 (Existing Loader):** `restow/quickshell/.../bar/BarContent.qml` (lines 191-205)
**Analog 2 (Coordinate Conversion):** `vendor/.../bar/StyledPopup.qml` (lines 36-53)

**Existing Media Loader** (`BarContent.qml` lines 191-204):
```qml
            Loader {
                id: mediaLoader
                Layout.alignment: Qt.AlignVCenter
                active: (root.useShortenedForm < 2) && (MprisController.activePlayer != null && (MprisController.activePlayer.trackTitle?.length > 0))
                visible: active

                sourceComponent: BarGroup {
                    Media {
                        visible: root.useShortenedForm < 2
                        Layout.fillWidth: true
                        Layout.maximumWidth: (root.useShortenedForm === 1) ? 140 : 200
                    }
                }
            }
```

**Coordinate Mapping Pattern** (`StyledPopup.qml` lines 38-41):
```qml
root.QsWindow?.mapFromItem(
    root.hoverTarget, 
    (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0
).x;
```

**Pattern Application for Phase 39:**
Attach a `HoverHandler` to `mediaLoader` to disambiguate which monitor's bar was hovered during the click. On toggle or item geometry change (`onWidthChanged`, `onXChanged`), map pill center coordinates to the root window using `mediaLoader.item.mapToItem(null, mediaLoader.item.width / 2, mediaLoader.item.height / 2)` and update `GlobalStates.mediaPillCenterX`, `mediaPillCenterY`, and `mediaPillScreen = root.screen`. On dismissal, reset to sentinel `-1` and `null`.

---

### 3. `restow/quickshell/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml` (component, event-driven)

**Analog:** `restow/quickshell/.../verticalBar/VerticalBarContent.qml` (lines 135-155)

**Pattern Application for Phase 39:**
Equip vertical bar's `verticalMedia` container with a similar hover and coordinate update method mapping `mediaPillCenterY` and `mediaPillScreen` when active.

---

### 4. `restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml` (component / panel, reactive)

**Analog 1 (Upstream MediaControls PanelWindow):** `vendor/.../mediaControls/MediaControls.qml` (lines 83-106)
**Analog 2 (Popup Boundaries & Gaps):** `vendor/.../common/Appearance.qml` (lines 40-75)

**Upstream PanelWindow Margins Block** (`MediaControls.qml` lines 83-105):
```qml
        sourceComponent: PanelWindow {
            id: panelWindow
            visible: true

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
                top: Config.options.bar.vertical ? ((panelWindow.screen.height / 2) - widgetHeight * 1.5) : Appearance.sizes.barHeight
                bottom: Appearance.sizes.barHeight
                left: Config.options.bar.vertical ? Appearance.sizes.barHeight : ((panelWindow.screen.width / 2) - (osdWidth / 2) - widgetWidth)
                right: Appearance.sizes.barHeight
            }
```

**Pattern Application for Phase 39 (Minimal 4-Line Override + Screen Binding):**
1. In `PanelWindow`, bind `screen: GlobalStates.mediaPillScreen ?? null`.
2. Replace horizontal left margin calculation with dynamic clamped formula:
```qml
            margins {
                top: Config.options.bar.vertical ? {
                    if (GlobalStates.mediaPillCenterY > 0) {
                        const gap = Appearance.sizes.hyprlandGapsOut;
                        const targetY = GlobalStates.mediaPillCenterY - (root.widgetHeight / 2);
                        const minY = gap;
                        const maxY = (panelWindow.screen ? panelWindow.screen.height : 1080) - root.widgetHeight - gap;
                        return Math.round(Math.max(minY, Math.min(targetY, maxY)));
                    }
                    return ((panelWindow.screen.height / 2) - widgetHeight * 1.5);
                } : Appearance.sizes.barHeight
                bottom: Appearance.sizes.barHeight
                left: Config.options.bar.vertical ? Appearance.sizes.barHeight : {
                    if (GlobalStates.mediaPillCenterX > 0) {
                        const gap = Appearance.sizes.hyprlandGapsOut;
                        const targetX = GlobalStates.mediaPillCenterX - (root.widgetWidth / 2);
                        const minX = gap;
                        const sWidth = panelWindow.screen ? panelWindow.screen.width : 1920;
                        const maxX = sWidth - root.widgetWidth - gap;
                        const clampedX = (maxX < minX) ? minX : Math.max(minX, Math.min(targetX, maxX));
                        return Math.round(clampedX);
                    }
                    return ((panelWindow.screen.width / 2) - (osdWidth / 2) - widgetWidth);
                }
                right: Appearance.sizes.barHeight
            }
```

---

### 5. `scripts/phase39-media-popup-assert.sh` (test harness, batch / request-response)

**Analog:** `scripts/phase38-power-profiles-assert.sh` (lines 1-120)

**5-Section Test Harness Pattern:**
```bash
#!/usr/bin/env bash
# scripts/phase39-media-popup-assert.sh — Phase 39 Dynamic Media Popup Anchoring assertion harness
set -euo pipefail

SECTION="${1:-all}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_section_1() {
  echo "=== [Section 1] Symlink & Packaging Integrity ==="
  # Verify restow symlinks, no directory folding, vendor clean
}

run_section_2() {
  echo "=== [Section 2] QML Property & Clamping Math Static AST ==="
  # Verify property declarations, update functions, screen bindings
}

run_section_3() {
  echo "=== [Section 3] Coordinate Mapping & Clamping Math Execution ==="
  # Test headless math for 1920x1080, 3440x1440, 400px, and fallback
}

run_section_4() {
  echo "=== [Section 4] Multi-Monitor Screen Binding & State Reset Lifecycle ==="
  # Test state transitions and dismissal cleanup
}

run_section_5() {
  echo "=== [Section 5] Repository Integrity & Strict Verification ==="
  "$REPO_ROOT/arch/dots-hyprland.sh" verify --strict
}
```

---

## Shared Patterns

### Leaf Symlink Restow Deployment
**Source:** `restow/quickshell/`
**Apply to:** All quickshell customizations
All files in `restow/quickshell/.config/quickshell/ii/` are stowed into `~/.config/quickshell/ii/` as individual leaf file symlinks, preserving parent directory structures and leaving `vendor/dots-hyprland` completely untouched.

### Reactive Clamping Math
**Source:** `Appearance.sizes.hyprlandGapsOut`
**Formula:** `Math.max(minGap, Math.min(target - (width / 2), screenWidth - width - minGap))`
Applied across horizontal and vertical dimensions to ensure zero window clipping on any resolution.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| *None* | — | — | All files have direct in-repo analogs. |

---

## Metadata

**Analog search scope:** `vendor/dots-hyprland/dots/.config/quickshell/ii/`, `restow/quickshell/`, `scripts/`
**Files scanned:** 5
**Pattern extraction date:** 2026-09-23
