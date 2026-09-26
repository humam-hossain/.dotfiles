# Phase 43: CPU & GPU Component (Pill & Popup) - Pattern Map

**Generated:** 2026-09-26  
**Domain:** Quickshell QML status bar components, overlay inspector popups, hardware telemetry integration, and Material You / Material 3 styling.  
**Consumes:** `43-CONTEXT.md`, `43-RESEARCH.md`  
**Produces:** Pattern specifications and concrete code templates for Phase 43 execution.

---

## 1. File Role & Classification Matrix

| Target File | Role | Closest Analog in Codebase | Key Patterns to Emulate |
|-------------|------|----------------------------|-------------------------|
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` | Top bar telemetry status pill | `restow/.../bar/VoicePill.qml`<br>`restow/.../bar/BarGroup.qml` | `BarGroup` root inheritance, M3 250ms `emphasizedDecel` width resizing, re-parented inert `MouseArea`, two-tier alert thresholds, breathing pulse animation with state reset, responsive `useShortenedForm`. |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` | Interactive telemetry inspector overlay | `vendor/.../bar/ResourcesPopup.qml`<br>`vendor/.../bar/StyledPopupHeaderRow.qml`<br>`vendor/.../bar/StyledPopupValueRow.qml`<br>`vendor/.../common/widgets/StyledProgressBar.qml` | `StyledPopup` root container, fast-polling reference count lifecycle boost, dual-column right-split layout, segregated P/E-core progress rows, unprivileged power fallback row. |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml` | Restow overlay enhancement for base popup | `vendor/.../bar/StyledPopup.qml`<br>`restow/.../ii/mediaControls/MediaControls.qml` | Upstream overlay replacement, 200ms close debounce hover bridge (`D-18`), screen boundary horizontal clamping (`D-19`), 150ms M3 entrance transition crossfade + slide (`D-20`). |
| `scripts/phase43-cpu-gpu-assert.sh` | Automated verification assert harness | `scripts/phase42-telemetry-services-assert.sh`<br>`scripts/phase39-media-popup-assert.sh`<br>`scripts/phase37-voice-pill-assert.sh` | 5-section CLI runner (`--section`, `--quick`, `--syntax`), AST grep asserts, QML syntax validation, git porcelain cleanliness, stow symlink verification, headless test runner. |

---

## 2. Component Pattern Mappings & Concrete Excerpts

### Component 1: `CpuGpuPill.qml`

#### Analog Reference
- Primary: `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml`
- Secondary: `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml`

#### Component Structure & Required Imports
```qml
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

BarGroup {
    id: root

    property real useShortenedForm: 0

    // Public alias for popup anchoring (D-17)
    readonly property alias hoverArea: inertMouseArea
...
```

#### Alert Color Thresholds & Dynamic Material You Palette (D-09, D-10, D-11)
Analog: `VoicePill.qml:37-47`
```qml
    // Two-tier alert state thresholds (D-10)
    // Warning: >= 70% load or >= 75°C; Critical: >= 90% load or >= 85°C
    readonly property bool cpuCritical: HardwareTelemetry.overallCpuLoad >= 0.90 || HardwareTelemetry.packageTemp >= 85
    readonly property bool cpuWarning: !cpuCritical && (HardwareTelemetry.overallCpuLoad >= 0.70 || HardwareTelemetry.packageTemp >= 75)

    readonly property bool tempCritical: HardwareTelemetry.packageTemp >= 85
    readonly property bool tempWarning: !tempCritical && HardwareTelemetry.packageTemp >= 75

    readonly property bool gpuCritical: HardwareTelemetry.gpuLoad >= 0.90
    readonly property bool gpuWarning: !gpuCritical && HardwareTelemetry.gpuLoad >= 0.70

    // Dynamic Material You token resolution (zero hardcoded hex colors per D-11)
    readonly property color cpuColor: cpuCritical ? Appearance.colors.colError : (cpuWarning ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer1)
    readonly property color tempColor: tempCritical ? Appearance.colors.colError : (tempWarning ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer1)
    readonly property color gpuColor: gpuCritical ? Appearance.colors.colError : (gpuWarning ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer1)
```

#### Re-parented Inert MouseArea Pattern (D-17, Pitfall 1)
Analog: `VoicePill.qml:104-112`
`BarGroup.qml` declares `default property alias items: gridLayout.children`. Any child without explicit re-parenting gets appended into `gridLayout`, creating a phantom cell. To prevent this, re-parent to `root`:
```qml
    MouseArea {
        id: inertMouseArea
        parent: root
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        cursorShape: Qt.ArrowCursor
        hoverEnabled: true
        onPressed: event => event.accepted = true
        onClicked: event => event.accepted = true
    }
```

#### Telemetry Arrangement & Responsive Form Factor (D-01..D-08)
Items placed inside `BarGroup` automatically flow into its internal `GridLayout` (`columns: root.vertical ? 1 : -1`, `columnSpacing: 4`).
```qml
    // --- CPU Section ---
    MaterialSymbol {
        id: cpuIcon
        text: "planner_review"
        iconSize: Appearance.font.pixelSize.normal
        color: root.cpuColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }

        // Breathing pulse animation on critical red (D-12)
        SequentialAnimation {
            id: cpuPulseAnimation
            running: root.cpuCritical
            loops: Animation.Infinite
            onRunningChanged: {
                if (!running) cpuIcon.opacity = 1.0;
            }
            NumberAnimation {
                target: cpuIcon
                property: "opacity"
                to: 0.6
                duration: 600
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: cpuIcon
                property: "opacity"
                to: 1.0
                duration: 600
                easing.type: Easing.InOutSine
            }
        }
    }

    StyledText {
        id: cpuText
        text: `${Math.round(HardwareTelemetry.overallCpuLoad * 100)}%`
        font.pixelSize: Appearance.font.pixelSize.small
        color: root.cpuColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }
    }

    // Single thermal metric: CPU Package Temp (D-01, D-06)
    // Drops when useShortenedForm > 0 (D-03)
    StyledText {
        id: tempText
        visible: root.useShortenedForm === 0
        text: `${HardwareTelemetry.packageTemp}°C`
        font.pixelSize: Appearance.font.pixelSize.small
        color: root.tempColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }
    }

    // --- GPU Section ---
    MaterialSymbol {
        id: gpuIcon
        text: "speed"
        iconSize: Appearance.font.pixelSize.normal
        color: root.gpuColor
        Layout.leftMargin: root.vertical ? 0 : 6 // Visual cluster separation per D-02

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }

        // Breathing pulse animation on critical red (D-12)
        SequentialAnimation {
            id: gpuPulseAnimation
            running: root.gpuCritical
            loops: Animation.Infinite
            onRunningChanged: {
                if (!running) gpuIcon.opacity = 1.0;
            }
            NumberAnimation {
                target: gpuIcon
                property: "opacity"
                to: 0.6
                duration: 600
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: gpuIcon
                property: "opacity"
                to: 1.0
                duration: 600
                easing.type: Easing.InOutSine
            }
        }
    }

    StyledText {
        id: gpuText
        text: `${Math.round(HardwareTelemetry.gpuLoad * 100)}%`
        font.pixelSize: Appearance.font.pixelSize.small
        color: root.gpuColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }
    }
```

---

### Component 2: `CpuGpuPopup.qml`

#### Analog Reference
- Base: `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/ResourcesPopup.qml`
- Section Headers: `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/StyledPopupHeaderRow.qml`
- Key-Value Rows: `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/StyledPopupValueRow.qml`
- Meter Progress Bars: `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/StyledProgressBar.qml`

#### Root Declaration & Fast Polling Lifecycle Boost
```qml
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

StyledPopup {
    id: root

    // Reactive fast-polling lifecycle boost (1000ms active / 3000ms idle)
    // Guarantees zero reference count leaks (Pitfall 5)
    onActiveChanged: {
        if (active) {
            HardwareTelemetry.fastPollingRequests++;
        } else {
            HardwareTelemetry.fastPollingRequests--;
        }
    }

    Component.onDestruction: {
        if (active) {
            HardwareTelemetry.fastPollingRequests--;
        }
    }
...
```

#### Reusable Multi-Attribute Progress Meter Sub-Component
```qml
    component MetricProgressRow: ColumnLayout {
        id: meterRow
        property string title: ""
        property string subtitle: ""
        property real value: 0.0
        property color barColor: Appearance.colors.colPrimary
        spacing: 2
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: meterRow.title
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: meterRow.subtitle
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
            StyledText {
                text: `${Math.round(meterRow.value * 100)}%`
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: meterRow.barColor
            }
        }

        StyledProgressBar {
            Layout.fillWidth: true
            value: Math.max(0.0, Math.min(1.0, meterRow.value))
            highlightColor: meterRow.barColor
        }
    }
```

#### Dual-Column Layout Architecture (D-13)
```qml
    RowLayout {
        spacing: 16

        // =====================================================================
        // Left Column: CPU Section (CPUGPU-02, D-13, D-14)
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 230
            spacing: 8

            StyledPopupHeaderRow {
                icon: "planner_review"
                label: "CPU (i5-13500)"
            }

            // Overall CPU Load
            MetricProgressRow {
                title: "Overall Load"
                value: HardwareTelemetry.overallCpuLoad
                barColor: root.cpuLoadColor
            }

            // Segregated P-Cores (12T) (CPUs 0-11)
            MetricProgressRow {
                title: "P-Cores (12T)"
                subtitle: `${Math.round(HardwareTelemetry.pCoreFrequencyMhz)} MHz`
                value: HardwareTelemetry.pCoreLoad
                barColor: root.cpuLoadColor
            }

            // Segregated E-Cores (8T) (CPUs 12-19)
            MetricProgressRow {
                title: "E-Cores (8T)"
                subtitle: `${Math.round(HardwareTelemetry.eCoreFrequencyMhz)} MHz`
                value: HardwareTelemetry.eCoreLoad
                barColor: root.cpuLoadColor
            }

            // Telemetry Value Rows
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "device_thermostat"
                label: "Package Temp:"
                value: `${HardwareTelemetry.packageTemp}°C`
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "tune"
                label: "Governor:"
                value: HardwareTelemetry.scalingGovernor
            }

            // Unprivileged Power Fallback (D-05 Platypus mitigation)
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "bolt"
                label: "Power Draw:"
                value: "N/A (unprivileged)"
            }
        }

        // Vertical Separator
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: 1
            color: Appearance.colors.colLayer0Border
        }

        // =====================================================================
        // Right Column: GPU Top + Motherboard Bottom (CPUGPU-03, D-13, D-15, D-16)
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 230
            spacing: 8

            // --- GPU Section (Top) ---
            StyledPopupHeaderRow {
                icon: "speed"
                label: "GPU (Intel UHD 770)"
            }

            MetricProgressRow {
                title: "iGPU Load"
                value: HardwareTelemetry.gpuLoad
                barColor: root.gpuLoadColor
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "speed"
                label: "Render Clock:"
                value: `${Math.round(HardwareTelemetry.gpuClockMhz)} MHz`
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "warning"
                label: "Thermal Throttle:"
                value: HardwareTelemetry.gpuThrottled ? "Throttling" : "Normal"
            }

            // Horizontal Separator
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Appearance.colors.colLayer0Border
            }

            // --- Motherboard & Platform Telemetry (Bottom) ---
            StyledPopupHeaderRow {
                icon: "developer_board"
                label: "Platform (B760)"
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "device_thermostat"
                label: "VRM Temp:"
                value: `${HardwareTelemetry.vrmTemp}°C`
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "energy_program_saving"
                label: "EPP:"
                value: HardwareTelemetry.energyPerformancePreference
            }
        }
    }
```

---

### Component 3: `StyledPopup.qml` (Restow Overlay Base Container)

#### Upstream Analog & Limitations Addressed
- Base upstream: `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml`
- Upstream limitation 1: Instant destruction when mouse leaves pill toward popup window (violates D-18).
- Upstream limitation 2: Negative unclamped `margins.left` on left-anchored pills causing screen overflow (violates D-19).
- Upstream limitation 3: Instant 0ms entrance without animation (violates D-20).

#### Complete Restow Implementation Pattern
```qml
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

LazyLoader {
    id: root

    property Item hoverTarget
    default property Item contentItem
    property real popupBackgroundMargin: 0

    // Seamless cursor tracking (D-18, Pitfall 2)
    property bool popupHovered: false
    readonly property bool hovered: (hoverTarget && hoverTarget.containsMouse) || popupHovered
    property bool shouldBeActive: false

    Timer {
        id: closeTimer
        interval: 200 // 200ms grace period across window bounds
        repeat: false
        onTriggered: {
            if (!root.hovered) {
                root.shouldBeActive = false;
            }
        }
    }

    onHoveredChanged: {
        if (hovered) {
            closeTimer.stop();
            shouldBeActive = true;
        } else {
            closeTimer.restart();
        }
    }

    active: shouldBeActive

    component: PanelWindow {
        id: popupWindow
        color: "transparent"

        anchors.left: !Config.options.bar.vertical || (Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.right: Config.options.bar.vertical && Config.options.bar.bottom
        anchors.top: Config.options.bar.vertical || (!Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.bottom: !Config.options.bar.vertical && Config.options.bar.bottom

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin

        mask: Region {
            item: popupBackground
        }

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        // Screen Boundary Clamping Math (D-19, Pitfall 4)
        margins {
            left: {
                if (!Config.options.bar.vertical) {
                    const screenWidth = root.QsWindow?.screen?.width ?? 1920;
                    const targetX = root.QsWindow?.mapFromItem(
                        root.hoverTarget, 
                        (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0
                    ).x ?? 0;
                    const gap = Appearance.sizes.hyprlandGapsOut;
                    const minX = gap;
                    const maxX = screenWidth - popupBackground.implicitWidth - gap;
                    if (maxX < minX) return minX;
                    return Math.round(Math.max(minX, Math.min(targetX, maxX)));
                }
                return Appearance.sizes.verticalBarWidth;
            }
            top: {
                if (!Config.options.bar.vertical) return Appearance.sizes.barHeight;
                const screenHeight = root.QsWindow?.screen?.height ?? 1080;
                const targetY = root.QsWindow?.mapFromItem(
                    root.hoverTarget, 
                    0, (root.hoverTarget.height - popupBackground.implicitHeight) / 2
                ).y ?? 0;
                const gap = Appearance.sizes.hyprlandGapsOut;
                const minY = gap;
                const maxY = screenHeight - popupBackground.implicitHeight - gap;
                if (maxY < minY) return minY;
                return Math.round(Math.max(minY, Math.min(targetY, maxY)));
            }
            right: Appearance.sizes.verticalBarWidth
            bottom: Appearance.sizes.barHeight
        }

        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        // Track hover inside the popup window to bridge cursor across gap (D-18)
        HoverHandler {
            id: windowHoverHandler
            onHoveredChanged: {
                root.popupHovered = hovered;
            }
        }

        StyledRectangularShadow {
            target: popupBackground
        }

        Rectangle {
            id: popupBackground
            readonly property real margin: 10
            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.left)
                rightMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.right)
                topMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.top)
                bottomMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.bottom)
            }
            implicitWidth: root.contentItem.implicitWidth + margin * 2
            implicitHeight: root.contentItem.implicitHeight + margin * 2
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.small
            children: [root.contentItem]

            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            transform: Translate {
                id: entranceTranslate
                y: 0
            }

            // Material 3 Expressive Entrance Transition (D-20)
            ParallelAnimation {
                running: true
                NumberAnimation {
                    target: popupBackground
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: 150
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
                NumberAnimation {
                    target: entranceTranslate
                    property: "y"
                    from: -4
                    to: 0
                    duration: 150
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
            }
        }
    }
}
```

---

### Component 4: `scripts/phase43-cpu-gpu-assert.sh`

#### Analog Reference
- Primary: `scripts/phase42-telemetry-services-assert.sh`
- Secondary: `scripts/phase39-media-popup-assert.sh`
- Headless Runner: `scripts/phase37-voice-pill-assert.sh:98-118`

#### Structure & CLI Harness Pattern
```bash
#!/usr/bin/env bash
# ===========================================================================
# Phase 43: CPU & GPU Component (Pill & Popup) Assert Harness
# Enforces: CPUGPU-01..04, D-01 through D-20
#
# Usage (from REPO_ROOT):
#   ./scripts/phase43-cpu-gpu-assert.sh [--section <1-5>] [-s <1-5>] [--quick] [--syntax]
#
# Exit 0 if all asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if run as root
[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
cleanup() {
  if [[ ${#TMP_FILES[@]} -gt 0 ]]; then
    rm -f "${TMP_FILES[@]}" 2>/dev/null || true
  fi
  return 0
}
trap cleanup EXIT INT TERM

RUN_SECTION=0
QUICK_MODE=0
SYNTAX_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    1|2|3|4|5)
      RUN_SECTION="$1"
      shift
      ;;
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    --quick|-q)
      QUICK_MODE=1
      shift
      ;;
    --syntax|-c)
      SYNTAX_ONLY=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [1-5] [OPTIONS]"
      echo "Options:"
      echo "  [1-5]                 Positional section selector"
      echo "  -s, --section <1-5>   Execute only the specified section (1-5)"
      echo "  -q, --quick           Execute static / quick checks only"
      echo "  -c, --syntax          Execute syntax checks only"
      echo "  -h, --help            Show this help message"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done
```

#### Section Breakdown:
1. **Section 1: Static AST & Syntax Verification:**
   - Verifies target files exist under `restow/quickshell/.../ii/bar/`.
   - Asserts `pragma ComponentBehavior: Bound` on all `.qml` files.
   - Asserts presence of `planner_review` and `speed` Material Symbols.
   - Verifies zero hardcoded hex alert colors (`#FFA000`, `#FF5252`, `#F44336`, etc.).
2. **Section 2: `CpuGpuPill.qml` Component Logic:**
   - Root is `BarGroup`.
   - Binds to `HardwareTelemetry.overallCpuLoad`, `HardwareTelemetry.gpuLoad`, `HardwareTelemetry.packageTemp`.
   - Responsive `useShortenedForm` drops temperature text.
   - Independent threshold properties (`cpuCritical`, `cpuWarning`, `gpuCritical`, `gpuWarning`, `tempCritical`, `tempWarning`).
   - Material 3 colors (`colError`, `colTertiary`, `colOnLayer1`).
   - Breathing pulse `SequentialAnimation` with `onRunningChanged` reset.
   - Inert `MouseArea` with `acceptedButtons: Qt.AllButtons`.
3. **Section 3: `CpuGpuPopup.qml` Layout & Telemetry Bindings:**
   - Root is `StyledPopup`.
   - Adaptive fast polling refcount handling on `active` and `Component.onDestruction`.
   - Segregated P-Cores (12T) and E-Cores (8T) progress meters and frequencies.
   - UHD 770 iGPU load, render clock MHz, throttle status badge.
   - Motherboard VRM temp and EPP bindings.
   - Unprivileged power fallback placeholder `"N/A (unprivileged)"`.
4. **Section 4: `StyledPopup.qml` Geometry & Transition Logic:**
   - 200ms close debounce timer for cursor tracking bridge (`D-18`).
   - Horizontal screen boundary clamping math (`minX` to `maxX`) with `hyprlandGapsOut` (`D-19`).
   - 150ms M3 entrance transition crossfade + 4px downward slide (`D-20`).
5. **Section 5: Stow & Packaging Integrity (INTG-02):**
   - Leaf symlinks in `~/.config/quickshell/ii/modules/ii/bar/` resolve to `restow/quickshell/...`.
   - Runs `./arch/dots-hyprland.sh verify --strict` returning `FAIL=0 FINDINGS=0`.
   - Submodule `vendor/dots-hyprland` working tree is clean.

---

## 3. Restow Deployment Discipline (INTG-01, INTG-02)

To avoid GNU Stow collision errors:
```bash
# 1. Back up existing plain files if not already symlinks
LIVE_DIR="$HOME/.config/quickshell/ii/modules/ii/bar"
if [[ -f "$LIVE_DIR/StyledPopup.qml" && ! -L "$LIVE_DIR/StyledPopup.qml" ]]; then
    mv "$LIVE_DIR/StyledPopup.qml" "$LIVE_DIR/StyledPopup.qml.bak"
fi

# 2. Re-stow quickshell overlay with --no-folding
cd "$REPO_ROOT/restow"
stow --no-folding -t ~ quickshell

# 3. Verify symlinks
readlink -f "$LIVE_DIR/CpuGpuPill.qml"
readlink -f "$LIVE_DIR/CpuGpuPopup.qml"
readlink -f "$LIVE_DIR/StyledPopup.qml"
```

---

## 4. Key Gotchas & Anti-Patterns to Prevent

1. **Unparented MouseArea in `BarGroup`:**
   - *Never* declare `MouseArea { ... }` directly inside `BarGroup` without `parent: root`. `BarGroup`'s default property is `items: gridLayout.children`, which turns the MouseArea into an invisible grid cell that shifts all bar pill contents.
2. **Hardcoded Color Hex Values:**
   - *Never* write `#ff5555` or `#e5c07b`. Always resolve dynamically via `Appearance.colors.colError` and `Appearance.colors.colTertiary`.
3. **Stuck Pulse Opacity:**
   - *Always* reset `target.opacity = 1.0` inside `onRunningChanged` on breathing pulse animations so an alert clearing mid-cycle doesn't leave the icon stuck at 0.6 opacity.
4. **Fast Polling Reference Count Leaks:**
   - *Always* decrement `fastPollingRequests` in both `onActiveChanged` (when `!active`) *and* `Component.onDestruction` (if `active`).
5. **RAPL / Watts Sysfs Reads:**
   - *Never* attempt to read privileged powercap energy files in user-space. Render the standard unprivileged fallback string `"N/A (unprivileged)"`.
